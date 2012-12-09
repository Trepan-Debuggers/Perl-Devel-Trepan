# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::BWProcessor::Command::Quit;
use if !@ISA, Devel::Trepan::BWProcessor::Command ;

use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();

# This method runs the command
sub run($$)
{
    my ($self, $cmd) = @_;
    my $proc = $self->{proc};
    my $response = { 
	'name'  => $NAME,
    };

    my $exitrc = 0;
    if ($cmd->{'exit_code'}) {
        if ($cmd->{exit_code} =~ /\d+/) {
            $exitrc = $cmd->{exit_code};
        } else {
            $self->errmsg("Bad an Integer return type \"$cmd->{exit_code}\"");
            return;
        }
    }
    no warnings 'once';
    $DB::single = 0;
    $DB::fall_off_on_end = 1;
    $proc->terminated('quit', $exitrc);
    $proc->{interface} = [];
    # No graceful way to stop threads...
    exit $exitrc;
}

unless (caller) {
    require Devel::Trepan::BWProcessor;
    my $proc = Devel::Trepan::BWProcessor->new;
    my $cmd = __PACKAGE__->new($proc);
    my $child_pid = fork;
    if ($child_pid == 0) { 
        $cmd->run({'cmd_name' => $NAME, exit_code => 'foo'});
        $cmd->run({'cmd_name' => $NAME});
    } else {
        wait;
    }
    $cmd->run({'cmd_name' => $NAME, exit_code => 5});
}

1;
