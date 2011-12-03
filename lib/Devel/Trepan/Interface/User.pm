# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Interface when communicating with the user.

use warnings; no warnings 'redefine';
use Exporter;

use rlib '../../..';

package Devel::Trepan::Interface::User;
use vars qw(@EXPORT @ISA);

use if !defined(@ISA), Devel::Trepan::Util; # qw(hash_merge);
use if !defined(@ISA), Devel::Trepan::IO::Input;
use if !defined(@ISA), Devel::Trepan::Interface; # qw(YES NO @YN);

@ISA = qw(Devel::Trepan::Interface Exporter);
use strict; 
# Interface when communicating with the user.

use constant DEFAULT_USER_OPTS => {

    readline   =>                       # Try to use GNU Readline?
	$Devel::Trepan::IO::Input::HAVE_GNU_READLINE, 
    
    # The below are only used if we want and have readline support.
    # See method Trepan::GNU_readline? below.
    histsize => 256,                     # Use gdb's default setting
    file_history   => '.trepanpl_hist',  # where history file lives
                                         # Note a directory will 
                                         # be appended
    history_save   => 1                  # do we save the history?
  };

sub new 
{
    my($class, $inp, $out, $opts)  = @_;
    $opts = hash_merge($opts, DEFAULT_USER_OPTS);
    my $self = Devel::Trepan::Interface->new($inp, $out, $opts);
    $self->{opts} = $opts;
    bless $self, $class;
    if ($inp && $inp->isa('Devel::Trepan::IO:InputBase')) {
	$self->{input} = $inp;
    } else {
	$self->{input} = Devel::Trepan::IO::Input->new($inp, 
						       {readline => $opts->{readline}})
    }
    if ($self->{input}{gnu_readline}) {
	if ($self->{opts}{complete}) {
	    my $attribs = $inp->{readline}->Attribs;
	    $attribs->{attempted_completion_function} = $self->{opts}{complete};
	}
	$self->read_history;
    }
    return $self;
}

sub add_history($$)
{
    my ($self, $command) = @_;
    return unless ($self->{input}{readline});
    $self->{input}{readline}->add_history($command) ;
    my $now = localtime;
    $self->{input}{readline}->add_history_time($now);
}

sub remove_history($;$)
{
    my ($self, $which) = @_;
    return unless ($self->{input}{readline});
    $which //= $self->{input}{readline}->where_history() if 
	$self->{input}{readline}->can("where_history");
    $self->{input}{readline}->remove_history($which) if
	$self->{input}{readline}->can("remove_history");
}

sub is_closed($) 
{
    my($self)  = shift;
    $self->{input}->is_eof && $self->{output}->is_eof;
}

# Called when a dangerous action is about to be done, to make
# sure it's okay. Expect a yes/no answer to `prompt' which is printed,
# suffixed with a question mark and the default value.  The user
# response converted to a boolean is returned.
# FIXME: make common routine for this and server.rb
sub confirm($$$) {
    my($self, $prompt, $default)  = @_;
    my $default_str = $default ? 'Y/n' : 'N/y';
    my $response;
    while (1) {
        $response = $self->readline(sprintf '%s (%s) ', $prompt, $default_str);
	return $default if $self->{input}->is_eof;
	chomp($response);
	return $default if $response eq '';
	($response = lc(unpack("A*", $response))) =~ s/^\s+//;
	# We don't catch "Yes, I'm sure" or "NO!", but I leave that 
	# as an exercise for the reader.
	last if grep(/^${response}$/, @YN);
	$self->msg( "Please answer 'yes' or 'no'. Try again.");
    }
    $self->remove_history;
    return grep(/^${response}$/, YES);
}

use File::Spec;

# Read a saved Readline history file into Readline. The history
# file will be created if it doesn't already exist.
# Much of this code follows what's done in ruby-debug.
sub read_history($)
{
    my $self = shift;
    my %opts = %{$self->{opts}};
    unless ($self->{histfile}) {
	my $dirname = $ENV{'HOME'} || $ENV{'HOMEPATH'} || glob('~');
	$self->{histfile} = File::Spec->catfile($dirname, $opts{file_history});
    }
    $self->{histsize} //= ($ENV{'HISTSIZE'} ? $ENV{'HISTSIZE'} : $opts{histsize});
    if ( -f $self->{histfile} ) {
	$self->{input}{readline}->StifleHistory($self->{histsize}) if
	    $self->{input}{readline}->can("StifleHistory");
	$self->{input}{readline}->ReadHistory($self->{histfile}) if
	    $self->{input}{readline}->can("ReadHistory");
    }
}

sub save_history($)
{
    my $self = shift;
    if ($self->{histfile} && $self->{opts}{history_save} && $self->want_gnu_readline &&
	$self->{input}{readline}) {
	$self->{input}{readline}->StifleHistory($self->{histsize}) if
	    $self->{input}{readline}->can("StifleHistory");
	$self->{input}{readline}->WriteHistory($self->{histfile}) if
	    $self->{input}{readline}->can("WriteHistory");
    }
}

# sub DESTROY($) 
# {
#     my $self = shift;
#     if ($self->want_gnu_readline) {
#     	$self->save_history;
#     }
#     Devel::Trepan::Interface::DESTROY($self);
# }

sub is_interactive($)
{
    my $self = shift;
    $self->{input}->is_interactive;
}

sub has_completion($)
{
    my $self = shift;
    $self->{input}{gnu_readline};
}

sub want_gnu_readline($)
{
    my $self = shift;
    defined($self->{opts}{readline}) && $self->{input}{gnu_readline};
}

sub read_command($;$) {
    my($self, $prompt)  = @_;
    $prompt //= '(trepanpl) ';
    $self->readline($prompt);
}

sub readline($;$) {
    my($self, $prompt)  = @_;
    $self->{output}->flush;
    if ($self->want_gnu_readline) {
	$self->{input}->readline($prompt);
    } else { 
	$self->{output}->write($prompt) if defined($prompt) && $prompt;
	$self->{input}->readline;
    }
}

sub set_completion($$)
{
    my ($self, $completion_fn, $list_completion_fn) = @_;
    return unless $self->has_completion;
    my $attribs = $self->{input}{readline}->Attribs;

    # Silence "used only once warnings" inside ReadLine::Term::Perl.
    $readline::rl_completion_entry_function = undef;
    $readline::rl_attempted_completion_function = undef;

    $attribs->{completion_entry_function} = $list_completion_fn;

    # For Term:ReadLine::Gnu
    $attribs->{attempted_completion_function} = $completion_fn;

    # For Term::ReadLine::Perl
    $readline::rl_completion_function = undef;
    $attribs->{completion_function} = $completion_fn;
}

# Demo
unless (caller) {
   my $intf = Devel::Trepan::Interface::User->new;
   $intf->msg("Hi, there!");
   $intf->errmsg("Houston, we have a problem here!");
   $intf->errmsg(['Two', 'lines']);
   printf "Is interactive: %s\n", ($intf->is_interactive ? "yes" : "no");
   printf "Has completion: %s\n", ($intf->has_completion ? "yes" : "no");
   if (scalar(@ARGV) > 0 && $intf->is_interactive) {
       my $line = $intf->readline("Type something: ");
       if ($intf->is_input_eof) {
	   print "No input, got EOF\n";
       } else {
	   print "You typed: ${line}";
       }
       printf "EOF is now: %d\n", $intf->{input}->is_eof;
       unless ($intf->{input}->is_eof) {
	   my $line = $intf->confirm("Are you sure", 0);
	   chomp($line);
	   print "you typed: ${line}\n";
	   printf "eof is now: %d\n",  $intf->{input}->is_eof;
	   $line = $intf->confirm("Really sure", 0);
	   print "you typed: ${line}\n";
	   printf "eof is now: %d\n", $intf->{input}->is_eof;
       }
   }
   printf "User interface closed?: %d\n", $intf->is_closed;
   $intf->close;
   # Note STDOUT is closed
   printf STDERR "User interface closed?: %d\n", $intf->is_closed;
}

1;
