# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
# Interface when communicating with the user.

use warnings; no warnings 'redefine';
use Exporter;

use rlib '../../..';

package Devel::Trepan::Interface::User;
use vars qw(@EXPORT @ISA);

use if !@ISA, Devel::Trepan::Util; # qw(hash_merge YN);
use if !@ISA, Devel::Trepan::IO::Input;
use if !@ISA, Devel::Trepan::Interface;

@ISA = qw(Devel::Trepan::Interface Exporter);
use strict; 
# Interface when communicating with the user.

use constant DEFAULT_USER_OPTS => {

    readline   =>                       # Try to use Term::ReadLine?
        $Devel::Trepan::IO::Input::HAVE_TERM_READLINE, 
    
    # The below are only used if we want and have readline support.
    # See method Trepan::term_readline below.
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
    if ($self->{input}{term_readline}) {
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
    $which = -1 unless defined($which);
    return unless ($self->{input}{readline});
    if ($self->{input}{readline}->can("where_history")) {
        my $where_history = $self->{input}{readline}->where_history();
        $which = $where_history unless defined $which;
    }
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
        last if grep(/^${response}$/, @Devel::Trepan::Util::YN);
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
    my $histsize = $ENV{'HISTSIZE'} ? $ENV{'HISTSIZE'} : $opts{histsize};
    $self->{histsize} = $histsize unless defined $self->{histsize};
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
    if ($self->{histfile} && $self->{opts}{history_save} && 
        $self->want_term_readline &&
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
#     if ($self->want_term_readline) {
#       $self->save_history;
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
    $self->{input}{term_readline};
}

sub want_term_readline($)
{
    my $self = shift;
    defined($self->{opts}{readline}) && $self->{input}{term_readline};
}

# read a debugger command
sub read_command($;$) {
    my($self, $prompt)  = @_;
    $prompt = '(trepanpl) ' unless defined $prompt;
    my $last = $self->readline($prompt);
    my $line = '';
    $prompt .= '>> '; # continuation
    $last ||= '';
    while ($last && '\\' eq substr($last, -1)) { 
        $line .= substr($last, 0, -1) . "\n";
        $last = $self->readline($prompt);
    }
    $line .= $last if defined $last;
    return $line;
}

sub readline($;$) {
    my($self, $prompt)  = @_;
    $self->{output}->flush;
    if ($self->want_term_readline) {
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
           $intf->msg("No input, got EOF\n");
       } else {
           $intf->msg("You typed: $line");
       }
       $intf->msg(sprintf "input EOF is now: %d", $intf->{input}->is_eof);
       unless ($intf->{input}->is_eof) {
           $intf->msg("Now we in read a command");
           my $line = $intf->read_command("Type a command something: ");
           if ($intf->is_input_eof) {
               $intf->msg("No input, got EOF");
           } else {
               $intf->msg("You typed: $line");
           }
           unless ($intf->is_input_eof) {
               $line = $intf->confirm("Are you sure", 0);
               chomp($line);
               $intf->msg("you typed: ${line}");
               $intf->msg(sprintf "eof is now: %d",  $intf->{input}->is_eof);
               $line = $intf->confirm("Really sure", 0);
               $intf->msg("you typed: $line");
               $intf->msg(sprintf "eof is now: %d", $intf->{input}->is_eof);
           }
       }
   }
   printf "User interface closed?: %d\n", $intf->is_closed;
   $intf->close;
   # Note STDOUT is closed
   printf STDERR "User interface closed?: %d\n", $intf->is_closed;
}

1;
