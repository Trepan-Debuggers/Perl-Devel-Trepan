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

# Manages Signal Handling information for the debugger
package Devel::Trepan::SigMgr;

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

#     Parameter dbgr is a Debugger object. ignore is a list of
#     signals to ignore. If you want no signals, use [] as None uses the
#     default set. Parameter default_print specifies whether or not we
#     print receiving a signals that is not ignored.

#     All the methods which change these attributes return None on error, or
#     True/False if we have set the action (pass/print/stop) for a signal
#     handler.


sub new($$)
{
    my ($class, $print_fn, $ignore_list) = @_;
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
        ## $self->action($signame, 'SIGINT stop print nostack nopass');
    }
    $self;
}

sub initialize_handler($$)
{
    my ($self, $sig) = @_;
    my $signame = canonic_signame($sig);
    return 0 unless defined($signame);
    return 0 unless exists($FATAL_SIGNALS{$signame});
        
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

#     def set_signal_replacement(self, signum, handle):
#         '''A replacement for signal.signal which chains the signal behind
#         the debugger's handler'''
#         signame = lookup_signame(signum)
#         if signame is None:
#             self.dbgr.intf[-1].errmsg(("%s is not a signal number" +
#                                        " I know about.")  % signum)
#             return False
#         # Since the intent is to set a handler, we should pass this
#         # signal on to the handler
#         self.sigs[signame].pass_along = True
#         if self.check_and_adjust_sighandler(signame, self.sigs):
#             self.sigs[signame].old_handler = handle
#             return True
#         return False
            
#     def check_and_adjust_sighandler(self, signame, sigs):
#         """Check to see if a single signal handler that we are interested in
#         has changed or has not been set initially. On return self.sigs[signame]
#         should have our signal handler. True is returned if the same or adjusted,
#         False or None if error or not found."""
#         signum = lookup_signum(signame)
#         try:
#             old_handler = signal.getsignal(signum)
#         except ValueError:
#             # On some OS's (Redhat 8), SIGNUM's are listed (like
#             # SIGRTMAX) that getsignal can't handle.
#             if signame in self.sigs:
#                 sigs.pop(signame)
#                 pass
#             return None
#         if old_handler != self.sigs[signame].handle:
#             if old_handler not in [signal.SIG_IGN, signal.SIG_DFL]:
#                 # save the program's signal handler
#                 sigs[signame].old_handler = old_handler
#                 pass
#             # set/restore _our_ signal handler
#             try:
# #                signal.signal(signum, self.sigs[signame].handle)
#                self._orig_set_signal(signum, self.sigs[signame].handle)
#             except ValueError:
#                 # Probably not in main thread
#                 return False
#             pass
#         return True

#     def check_and_adjust_sighandlers(self):
#         """Check to see if any of the signal handlers we are interested in have
#         changed or is not initially set. Change any that are not right. """
#         for signame in self.sigs.keys():
#             if not self.check_and_adjust_sighandler(signame, self.sigs):
#                 break
#             pass
#         return

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
		       bool2YN($sig_obj->{print_method}),
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
    my $signame = $args->[0];
    if ($signame eq  'handle' or $signame eq 'signal') {
	# This has come from dbgr's info command
	if (scalar @args == 1) {
	    # Show all signal handlers
	    $print_fn->($self->{header});
	    for my $sn (@$self->{siglist}) {
		$self->print_info_signal_entry($signame);
	    }
	    return 1;
	} else {
	    $signame = $args->[1];
	}
    }

    $signame = canonic_signame($signame);
    $print_fn->($self->{header});
    $self->print_info_signal_entry($signame);
    return 1;
}

#     def action(self, arg):
#         """Delegate the actions specified in 'arg' to another
#         method.
#         """
#         if not arg:
#             self.info_signal(['handle'])
#             return True
#         args = arg.split()
#         signame = args[0]
#         signame = canonic_signame($args[0]);
#         if not signame: return

#         if len(args) == 1:
#             self.info_signal([signame])
#             return True
#         # We can display information about 'fatal' signals, but not
#         # change their actions.
#         if signame in fatal_signals:
#             return None

#         if signame not in self.sigs.keys():
#             if not self.initialize_handler(signame): return None
#             pass

#         # multiple commands might be specified, i.e. 'nopass nostop'
#         for attr in args[1:]:
#             if attr.startswith('no'):
#                 on = False
#                 attr = attr[2:]
#             else:
#                 on = True
#             if 'stop'.startswith(attr):
#                 self.handle_stop(signame, on)
#             elif 'print'.startswith(attr) and len(attr) >= 2:
#                 self.handle_print(signame, on)
#             elif 'pass'.startswith(attr):
#                 self.handle_pass(signame, on)
#             elif 'ignore'.startswith(attr):
#                 self.handle_ignore(signame, on)
#             elif 'stack'.startswith(attr):
#                 self.handle_print_stack(signame, on)
#             else:
#                 self.dbgr.intf[-1].errmsg('Invalid arguments')
#                 pass
#             pass
#         return self.check_and_adjust_sighandler(signame, self.sigs)

#     def handle_print_stack(self, signame, print_stack):
#         """Set whether we stop or not when this signal is caught.
#         If 'set_stop' is True your program will stop when this signal
#         happens."""
#         self.sigs[signame].print_stack = print_stack
#         return print_stack

#     def handle_stop(self, signame, set_stop):
#         """Set whether we stop or not when this signal is caught.
#         If 'set_stop' is True your program will stop when this signal
#         happens."""
#         if set_stop:
#             self.sigs[signame].b_stop       = True
#             # stop keyword implies print AND nopass
#             self.sigs[signame].print_method = self.dbgr.intf[-1].msg
#             self.sigs[signame].pass_along   = False
#         else:
#             self.sigs[signame].b_stop       = False
#             pass
#         return set_stop

#     def handle_pass(self, signame, set_pass):
#         """Set whether we pass this signal to the program (or not)
#         when this signal is caught. If set_pass is True, Dbgr should allow
#         your program to see this signal.
#         """
#         self.sigs[signame].pass_along = set_pass
#         if set_pass:
#             # Pass implies nostop
#             self.sigs[signame].b_stop = False
#             pass
#         return set_pass

#     def handle_ignore(self, signame, set_ignore):
#         """'pass' and 'noignore' are synonyms. 'nopass and 'ignore' are
#         synonyms."""
#         self.handle_pass(signame, not set_ignore)
#         return set_ignore

#     def handle_print(self, signame, set_print):
#         """Set whether we print or not when this signal is caught."""
#         if set_print:
#             self.sigs[signame].print_method = self.dbgr.intf[-1].msg
#         else:
#             self.sigs[signame].print_method = None
#             pass
#         return set_print
#     pass

#     Store information about what we do when we handle a signal,
#
#     - Do we print/not print when signal is caught
#     - Do we pass/not pass the signal to the program
#     - Do we stop/not stop when signal is caught
#
#     Parameters:
#        signame : name of signal (e.g. SIGUSR1 or USR1)
#        print_method routine to use for "print"
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
    if ($self->{print_method}) {
	my $msg = sprintf('\nProgram received signal %s.', 
			  $self->{signame});
	$self->{print_method}->($msg);
    }
    # if ($self->{print_stack}) {
    # 	import traceback;
    # 	my @strings = traceback.format_stack(frame);
    # 	for my $s (@strings) {
    # 	    chomp $s;
    # 	    $self->{print_method}->($s);
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
    # for signum in range(signal.NSIG):
    #     signame = lookup_signame(signum)
    #     if signame is not None:
    #         assert(signum == lookup_signum(signame))
    #         # Try without the SIG prefix
    #         assert(signum == lookup_signum(signame[3:]))
    #         pass
    #     pass

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
    
    # from import_relative import import_relative
    # Mdebugger = import_relative('debugger', '..', 'pydbgr')
    # dbgr = Mdebugger.Debugger()
    eval 'sub myprint($) { my $msg = shift; print "$msg\n";  }';

    my $h = Devel::Trepan::SigMgr->new(\&myprint);
    $h->info_signal(["TRAP"]);
    # Set to known value
    # h.action('SIGUSR1')
    # h.action('usr1 print pass stop')
    $h->info_signal(['USR1']);
    # # noprint implies no stop
    # h.action('SIGUSR1 noprint')
    # h.info_signal(['USR1'])
    # h.action('foo nostop')
    # # stop keyword implies print
    # h.action('SIGUSR1 stop')
    # h.info_signal(['SIGUSR1'])
    # h.action('SIGUSR1 noprint')
    # h.info_signal(['SIGUSR1'])
    # h.action('SIGUSR1 nopass stack')
    # h.info_signal(['SIGUSR1'])
}