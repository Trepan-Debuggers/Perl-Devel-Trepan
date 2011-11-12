# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# use feature ":5.10";  # Includes "state" feature.
use warnings; no warnings 'redefine'; 

use rlib '../../../..';
use Psh;

package Devel::Trepan::CmdProcessor::Command::Shell;
use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use if !defined @ISA, Devel::Trepan::Psh ;

unless (defined(@ISA)) {
    eval "use constant ALIASES    => qw(psh)";
    eval "use constant CATEGORY   => 'support'";
    eval "use constant NEED_STACK => 0;";
    eval "use constant SHORT_HELP => 'Run psh as a command shell'";
}

use vars qw(@ISA); @ISA = @CMD_ISA; 
use strict; 
use vars @CMD_VARS;  # Value inherited from parent
our $MIN_ARGS     = 0;  # Need at most this many
our $MAX_ARGS     = 0;  # Need at most this many

our $NAME = set_name();
our $HELP = <<"HELP";
${NAME} [-d]
Start an Interactive Perl shell session via psh
HELP

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    unless (require Psh::Locale) {
	$self->{proc}->errmsg("No psh support available. Did you install psh?");
    }
#    state $first_time = 1;
#    if ($first_time) {
	$self->{proc}->msg("To return to the debugger, set: \$Psh::quit = 1");
#	$first_time = 0;
#    }
    require Psh::Util;
    Psh::minimal_initialize;
    Psh::finish_initialize;
    Psh::initialize_interactive_mode;
    Psh::Options::set_option('ps1', "trepanpl \$ ");
    $Psh::quit = 0;
    until ($Psh::quit) {
	eval { Psh::main_loop(); };
	Psh::handle_message($@,'main_loop');
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    my $child_pid = fork;
    if ($child_pid == 0) {
	$cmd->run([$NAME]);
    } else {
	waitpid($child_pid, 0);
    }
}

1;
