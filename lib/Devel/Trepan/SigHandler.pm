# -*- coding: utf-8 -*-
#   Copyright (C) 2011 Rocky Bernstein <rocky@gnu.org>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

#TODO:
#  - Doublecheck handle_pass and other routines.
#  - can remove signal handler altogether when
#         ignore=True, print=False, pass=True
#     
#
use rlib '../..'; 

# Manages Signal Handling information for the debugger
package Devel::Trepan::SigMgr;
use Devel::Trepan::Util;
use Exporter;
use vars qw(@EXPORT);
@EXPORT    = qw( lookup_signum lookup_signame );
@ISA = qw(Exporter);

use warnings; use strict;

my %signo;
my @signame;

use Config;

my $i=0;
for my $name (split(' ', $Config{sig_name})) {
    $signo{$name} = $i;
    $signame[$i] = $name;
    $i++;
}


# Find the corresponding signal name for 'num'. Return undef
# if 'num' is invalid.
sub lookup_signame($)
{
    my $num = shift;
    $num = abs($num);
    return undef unless $num < scalar @signame;
    return $signame[$num];
}

# Find the corresponding signal number for 'name'. Return under
#  if 'name' is invalid.
sub lookup_signum($)
{
    my $name = shift;
    my $uname = uc $name;
    $uname = substr($uname, 3) if 0 == index($uname, 'SIG');
    return $signo{$uname} if exists $signo{$uname};
    return undef;
}

# Return a signal name for a signal name or signal
# number.  Return undef is $name_num is an int but not a valid signal
# number and undef if $name_num is a not number. If $name_num is a
# signal name or signal number, the canonic if name is returned.
sub canonic_signame($)
{
    my $name_num = shift;
    my $signum = lookup_signum($name_num);
    my $signame;
    unless (defined $signum) {
        # Maybe signame is a number?
	if ($name_num =~ /^[+-]?[0-9]+$/) {
	    $signame = lookup_signame($name_num);
            return undef unless defined($signame);
        } else {
            return undef;
	}
        return $signame
    }
    
    $signame = uc $name_num;
    return substr($signame, 3) if 0 == index($signame, 'SIG');
    return $signame;
}

my %FATAL_SIGNALS = ('KILL' => 1, 'STOP' => 1);

# I copied these from GDB source code.
my %SIGNAL_DESCRIPTION = (
  "HUP"    => "Hangup",
  "INT"    => "Interrupt",
  "QUIT"   => "Quit",
  "ILL"    => "Illegal instruction",
  "TRAP"   => "Trace/breakpoint trap",
  "ABRT"   => "Aborted",
  "EMT"    => "Emulation trap",
  "FPE"    => "Arithmetic exception",
  "KILL"   => "Killed",
  "BUS"    => "Bus error",
  "SEGV"   => "Segmentation fault",
  "SYS"    => "Bad system call",
  "PIPE"   => "Broken pipe",
  "ALRM"   => "Alarm clock",
  "TERM"   => "Terminated",
  "URG"    => "Urgent I/O condition",
  "STOP"   => "Stopped (signal)",
  "TSTP"   => "Stopped (user)",
  "CONT"   => "Continued",
  "CHLD"   => "Child status changed",
  "TTIN"   => "Stopped (tty input)",
  "TTOU"   => "Stopped (tty output)",
  "IO"     => "I/O possible",
  "XCPU"   => "CPU time limit exceeded",
  "XFSZ"   => "File size limit exceeded",
  "VTALRM" => "Virtual timer expired",
  "PROF"   => "Profiling timer expired",
  "WINCH"  => "Window size changed",
  "LOST"   => "Resource lost",
  "USR1"   => "User-defined signal 1",
  "USR2"   => "User-defined signal 2",
  "PWR"    => "Power fail/restart",
  "POLL"   => "Pollable event occurred",
  "WIND"   => "WIND",
  "PHONE"  => "PHONE",
  "WAITING"=> "Process's LWPs are blocked",
  "LWP"    => "Signal LWP",
  "DANGER" => "Swap space dangerously low",
  "GRANT"  => "Monitor mode granted",
  "RETRACT"=> "Need to relinquish monitor mode",
  "MSG"    => "Monitor mode data available",
  "SOUND"  => "Sound completed",
  "SAK"    => "Secure attention"
);


# Signal Handling information Object for the debugger
#     - Do we print/not print when signal is caught
#     - Do we pass/not pass the signal to the program
#     - Do we stop/not stop when signal is caught
#
#     Parameter dbgr is a Debugger object. ignore is a list of
#     signals to ignore. If you want no signals, use [] as None uses the
#     default set. Parameter default_print specifies whether or not we
#     print receiving a signals that is not ignored.
#
#     All the methods which change these attributes return None on error, or
#     True/False if we have set the action (pass/print/stop) for a signal
#     handler.
sub new($$$$$)
{
    my ($class, $print_fn, $errprint_fn, $secprint_fn, $ignore_list) = @_;
    # Ignore signal handling initially for these known signals.
    unless (defined($ignore_list)) {
	$ignore_list = {
	    'ALRM'    => 1,    
	    'CHLD'    => 1,  
	    'URG'     => 1,
	    'IO'      => 1, 
	    'CLD'     => 1,
	    'VTALRM'  => 1,  
	    'PROF'    => 1,  
	    'WINCH'   => 1,  
	    'POLL'    => 1,
	    'WAITING' => 1, 
	    'LWP'     => 1,
	    'CANCEL'  => 1, 
	    'TRAP'    => 1,
	    'TERM'    => 1,
	    'QUIT'    => 1,
	    'ILL'     => 1
	};
    };

    my $self = {
	print_fn    => $print_fn,
	errprint_fn => $errprint_fn // $print_fn,
	secprint_fn => $secprint_fn // $print_fn,
        sigs        => {},
        siglist     => @signame,
	ignore_list => $ignore_list,
	orig_set_signal  => \%SIG,
	info_fmt => "%-14s%-4s\t%-4s\t%-5s\t%-4s\t%s",
    };

    bless $self, $class;
    
    $self->{header} = sprintf($self->{info_fmt}, 'Signal', 'Stop', 'Print',
			      'Stack', 'Pass', 'Description');

    # signal.signal = self.set_signal_replacement

    for my $signame (keys %SIG) {
	initialize_handler($self, $signame);
        $self->action($signame, 'SIGINT stop print nostack nopass');
    }
    $self;
}

sub initialize_handler($$)
{
    my ($self, $sig) = @_;
    my $signame = canonic_signame($sig);
    return 0 unless defined($signame);
    return 0 if exists($FATAL_SIGNALS{$signame});
        
    # try:
    my $old_handler = $SIG{$signame};
    # except ValueError:
    # On some OS's (Redhat 8), SIGNUM's are listed (like
    # SIGRTMAX) that getsignal can't handle.
    # if (exists($self->{sigs}{$signame})) {
    # 	$self->{sigs}->pop($signame);
    # }

    my $signum = lookup_signum($signame);
    my $print_fn = $self->{print_fn};
    if (exists($self->{ignore_list}{$signame})) {
	$self->{sigs}{$signame} = 
	    Devel::Trepan::SigHandler->new($print_fn, $signame, $signum, 
					   \&old_handler,
					   0,  0, 1);
    } else {
	$self->{sigs}{$signame} = 
	    Devel::Trepan::SigHandler->new($print_fn, $signame, $signum, 
					   \&old_handler,
					   1, 0, 0);
    }
    return 1;
}

# A replacement for signal.signal which chains the signal behind
# the debugger's handler
sub set_signal_replacement($$$)
{
    my ($self, $signum, $handle) = @_;
    my $signame = lookup_signame($signum);
    unless(defined $signame) {
	my $msg = sprintf "%d is not a signal number I know about.", $signum;
	$self->{errprint}->($msg);
	return 0;
    }
    # Since the intent is to set a handler, we should pass this
    # signal on to the handler
    $self->{sigs}{$signame}->pass_along = 1;
    if ($self->check_and_adjust_sighandler($signame)) {
	$self->{sigs}{$signame}{old_handler} = $handle;
	return 1;
    }
    return 0;
}
            
# Check to see if a single signal handler that we are interested in
# has changed or has not been set initially. On return self->{sigs}{$signame}
# should have our signal handler. True is returned if the same or adjusted,
# False or undef if error or not found.
sub check_and_adjust_sighandler($$)
{
    my ($self, $signame) = @_;
    my $sigs = $self->{sigs};
    # try:
    my $old_handler = $SIG{$signame};
    # except ValueError:
    # On some OS's (Redhat 8), SIGNUM's are listed (like
    # SIGRTMAX) that getsignal can't handle.
    #if signame in self.sigs:
    # sigs.pop(signame)
    #        pass
    #    return None
    if (defined($old_handler) && $old_handler ne $sigs->{$signame}) {
	# if old_handler not in [signal.SIG_IGN, signal.SIG_DFL]:
        # save the program's signal handler
	$sigs->{$signame}{old_handler} = $old_handler;
	# set/restore _our_ signal handler
        #
	$SIG{$signame} = $sigs->{$signame};
    }
    return 1;
}

# Check to see if any of the signal handlers we are interested in have
# changed or is not initially set. Change any that are not right.
sub check_and_adjust_sighandlers($)
{
    my $self = shift;
    for my $signame (keys %{$self->{sigs}}) {
	last unless ($self->check_and_adjust_sighandler($signame));
    }
}

# Print status for a single signal name (signame)
sub print_info_signal_entry($$)
{
    my ($self, $signame) = @_;
    my $description = (exists $SIGNAL_DESCRIPTION{$signame}) ? 
	$SIGNAL_DESCRIPTION{$signame} : '';
    my $msg;
    my $sig_obj = $self->{sigs}{$signame};
    if (exists $self->{sigs}{$signame}) {
	$msg = sprintf($self->{info_fmt}, $signame, 
		       bool2YN($sig_obj->{b_stop}),
		       bool2YN($sig_obj->{print_fn}),
		       bool2YN($sig_obj->{print_stack}),
		       bool2YN($sig_obj->{pass_along}),
		       $description); 
    } else {
	# Fake up an entry as though signame were in sigs.
	$msg = sprintf($self->{info_fmt}, $signame, 
		       'No', 'No', 'No', 'Yes', $description); 
    }
    $self->{print_fn}->($msg);
}

# Print information about a signal
sub info_signal($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    return undef unless scalar @args;
    my $print_fn = $self->{print_fn};
    my $secprint_fn = $self->{secprint_fn};
    my $signame = $args->[0];
    if ($signame eq  'handle' or $signame eq 'signal') {
	# This has come from dbgr's info command
	if (scalar @args == 1) {
	    # Show all signal handlers
	    $secprint_fn->($self->{header});
	    for my $sn (@$self->{siglist}) {
		$self->print_info_signal_entry($signame);
	    }
	    return 1;
	} else {
	    $signame = $args->[1];
	}
    }

    $signame = canonic_signame($signame);
    $secprint_fn->($self->{header});
    $self->print_info_signal_entry($signame);
    return 1;
}

# Delegate the actions specified in string $arg to another
# method.
sub action($$)
{
    my ($self, $arg) = @_;
    if (!defined($arg)) {
	$self->info_signal(['handle']);
	return 1;
    }
    my @args = split ' ', $arg;
    my $signame = canonic_signame(shift @args);
    return unless defined $signame;

    if (scalar @args == 0) { 
	$self->info_signal([$signame]);
	return 1;
    }

    # We can display information about 'fatal' signals, but not
    # change their actions.
    return 0 if (exists $FATAL_SIGNALS{$signame});

    unless (exists $self->{sigs}{$signame}) {
	return 0 unless $self->initialize_handler($signame);
    }

    # multiple commands might be specified, i.e. 'nopass nostop'
    for my $attr (@args) {
	my $on = 1;
	if (0 == index($attr, 'no')) {
	    $on = 0;
	    $attr = substr($attr, 2);
	}
	if (0 == index($attr, 'stop')) {
	    $self->handle_stop($signame, $on);
	} elsif (0 == index($attr, 'print')) {
	    $self->handle_print($signame, $on);
	} elsif (0 == index($attr, 'pass')) {
	    $self->handle_pass($signame, $on);
	} elsif (0 == index($attr, 'ignore')) {
	    $self->handle_ignore($signame, $on);
	} elsif (0 == index($attr, 'stack')) {
	    $self->handle_print_stack($signame, $on);
	} else {
	    $self->{errprt_fn}->('Invalid arguments')
	}
    }
    return $self->check_and_adjust_sighandler($signame);
}

# Set whether we stop or not when this signal is caught.
# If 'set_stop' is True your program will stop when this signal
# happens.
sub handle_print_stack($$$) 
{
    my ($self, $signame, $print_stack) = @_;
    $self->{sigs}{$signame}{print_stack} = $print_stack;
}

# Set whether we stop or not when this signal is caught.
# If 'set_stop' is True your program will stop when this signal
# happens.
sub handle_stop($$$)
{
    my ($self, $signame, $set_stop) = @_;
    if ($set_stop) {
	$self->{sigs}{signame}{b_stop} = 1;
	# stop keyword implies print AND nopass
	$self->{sigs}{$signame}{print_fn} = $self->{print_fn};
	$self->{sigs}{$signame}{pass_along} = 0;
    } else {
	$self->{sigs}{$signame}{b_stop} = 0;
    }
}

# Set whether we pass this signal to the program (or not)
# when this signal is caught. If set_pass is True, Dbgr should allow
# your program to see this signal.
sub handle_pass($$$)
{
    my ($self, $signame, $set_pass) = @_;
    $self->{sigs}{$signame}{pass_along} = $set_pass;
    if ($set_pass) {
	# Pass implies nostop
	$self->{sigs}{$signame}{b_stop} = 0;
    }
}    

# 'pass' and 'noignore' are synonyms. 'nopass and 'ignore' are
# synonyms.
sub handle_ignore($$$)
{
    my ($self, $signame, $set_ignore) = @_;
    $self->handle_pass($signame, !$set_ignore);
}

# Set whether we print or not when this signal is caught.
sub handle_print($$$)
{
    my ($self, $signame, $set_print) = @_;
    if ($set_print) {
	$self->{sigs}{$signame}{print_fn} = $self->{print_fn};
    } else {
	$self->{sigs}{$signame}{print_fn} = undef;
    }
}


#     Store information about what we do when we handle a signal,
#
#     - Do we print/not print when signal is caught
#     - Do we pass/not pass the signal to the program
#     - Do we stop/not stop when signal is caught
#
#     Parameters:
#        signame : name of signal (e.g. SIGUSR1 or USR1)
#        print_fn routine to use for "print"
#        stop routine to call to invoke debugger when stopping
#        pass_along: True is signal is to be passed to user's handler
package Devel::Trepan::SigHandler;

sub new($$$$$$;$$)
{
    my($class, $print_fn, $signame, $signum, $old_handler,
       $b_stop, $print_stack, $pass_along) = @_;

    $print_stack //= 0, $pass_along //= 1;

    my $self = {
	print_fn     => $print_fn,
        old_handler  => $old_handler,
	pass_along   => $pass_along,
        print_stack  => $print_stack,
        signame      => $signame,
        signum       => $signum,
        b_stop       => $b_stop
    };
    bless $self, $class;
    $self;
}

# This method is called when a signal is received.
sub handle($$$)
{
    my ($self, $signum, $frame) = @_;
    if ($self->{print_fn}) {
	my $msg = sprintf('\nProgram received signal %s.', 
			  $self->{signame});
	$self->{print_fn}->($msg);
    }
    # if ($self->{print_stack}) {
    # 	import traceback;
    # 	my @strings = traceback.format_stack(frame);
    # 	for my $s (@strings) {
    # 	    chomp $s;
    # 	    $self->{print_fn}->($s);
    # 	}
    # }
    # if ($self->{b_stop}) {
    # 	core = self.dbgr.core;
    # 	old_trace_hook_suspend = core.trace_hook_suspend;
    # 	core.trace_hook_suspend = 1;
    # 	core.stop_reason = ('intercepting signal %s (%d)' % 
    # 			    (self.signame, signum));
    # 	core.processor.event_processor(frame, 'signal', signum);
    # 	core.trace_hook_suspend = old_trace_hook_suspend;
    # }
    if ($self->{pass_along}) {
	# pass the signal to the program 
	if ($self->{old_handler}) {
	    $self->{old_handler}->($signum, $frame);
	}
    }
}


# When invoked as main program, do some basic tests of a couple of functions
unless (caller) {
    for my $i (15, -15, 300) {
        printf("lookup_signame(%d) => %s\n", $i, 
	       Devel::Trepan::SigMgr::lookup_signame($i) // 'undef');
    }
    
    for my $sig ('term', 'TERM', 'NotThere') {
        printf("lookup_signum(%s) => %s\n", $sig, 
	       Devel::Trepan::SigMgr::lookup_signum($sig) // 'undef');
    }
    
    for my $i ('15', '-15', 'term', 'sigterm', 'TERM', '300', 'bogus') {
        printf("canonic_signame(%s) => %s\n", $i, 
	       Devel::Trepan::SigMgr::canonic_signame($i) // 'undef');
    }
    
    eval <<'EOE';  # Have to eval else fns defined when caller() is false
    sub doit($$) {
	my ($h, $arg) = @_; 
	print "$arg\n"; 
	$h->action($arg);
    }
    sub myprint($) { 
	my $msg = shift; 
	print "$msg\n";  
    }
EOE

    my $h = Devel::Trepan::SigMgr->new(\&myprint);
    $h->info_signal(["TRAP"]);
    # USR1 is set to known value
    $h->action('SIGUSR1');

    doit($h, 'usr1 print pass');
    $h->info_signal(["USR1"]);
    # noprint implies no stop
    doit($h, 'usr1 noprint');
    $h->info_signal(["USR1"]);
    doit($h, 'foo nostop');
    # # stop keyword implies print
    # h.action('SIGUSR1 stop')
    # h.info_signal(['SIGUSR1'])
    # h.action('SIGUSR1 noprint')
    # h.info_signal(['SIGUSR1'])
    # h.action('SIGUSR1 nopass stack')
    # h.info_signal(['SIGUSR1'])
}
