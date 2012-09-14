# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Complete;

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

unless (@ISA) {
    eval <<'EOE';
    use constant CATEGORY   => 'support';
    use constant SHORT_HELP => 'List the completions for the rest of the line as a command';
    use constant MAX_ARGS   => undef;  # Need at most this many - 
                                       # undef -> unlimited
    use constant NEED_STACK => 0;
EOE
}

use strict;
use vars qw(@ISA);
@ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<"HELP";
=pod 

complete I<comamand-prefix>

List the command completions of I<command-prefix>.
=cut
HELP

# This method runs the command
sub run($$) {
    my ($self, $args) = @_;
    my @args = @{$args}; shift @args; # remove "complete".
    my $proc = $self->{proc};
    my $cmd_argstr = $proc->{cmd_argstr};
    my $last_arg = (' ' eq substr($cmd_argstr, -1)) ? '' : $args[-1];
    $last_arg = '' unless defined $last_arg;
    for my $match ($proc->complete($cmd_argstr, $cmd_argstr,
                   0, length($cmd_argstr))) {
        $proc->msg($match);
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $cmd = __PACKAGE__->new($proc);
    for my $prefix (qw(d b bt)) {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }
    for my $prefix ('set a') {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }
    for my $prefix ('help syntax c') {
        $cmd->{proc}{cmd_argstr} = $prefix;
        $cmd->run([$cmd->name, $prefix]);
        print '=' x 40, "\n";
    }
    # $cmd->run([$cmd->name, 'fdafsasfda']);
}

1;
