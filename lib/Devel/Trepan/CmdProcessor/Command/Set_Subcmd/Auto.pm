# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Set::Auto;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('au');
our $HELP   = <<'HELP';
=pod

Set controls for things with some sort of automatic default behavior.

See C<help set auto *> for a list of subcommands or C<help set auto I<name>>
for help on a particular trace subcommand.
=cut
HELP
our $SHORT_HELP = 
"Set controls for some \"automatic\" default behaviors";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);


# sub run($$)
# {
#     my ($self, $args) = @_;
#     $self->SUPER;
# }

unless (caller) { 
    # Demo it.
    # FIXME: DRY with other subcommand manager demo code.
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Set->new($proc, 'set');
    my $cmd = __PACKAGE__->new($parent, 'auto');
    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";
    for my $arg ('e', 'lis', 'foo') {
        my @aref = $cmd->complete_token_with_next($arg);
        printf "%s\n", @aref ? $aref[0]->[0]: 'undef';
    }

    print join(' ', @{$cmd->{prefix}}), "\n"; 
    $cmd->run($cmd->{prefix});
    # $cmd->run($cmd->{prefix}, ('string', '30'));
    
}

1;
