# -*- coding: utf-8 -*-
# Copyright (C) 2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Show::Display;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('au');
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"EOH";
=pod

B<show display> [I<show-display sub-commmand> ...]

Show display-related controls

=head2 See also:

L<C<set display>|Devel::Trepan::CmdProcessor::Command::Set::Display>
=cut
EOH
our $SHORT_HELP  = 'Show display-related controls';
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SubsubcmdMgr);


# sub run($$)
# {
#     my ($self, $args) = @_;
#     $self->SUPER;
# }

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false);
    # $cmd              = __PACKAGE__->new(dbgr.core.processor,
    #                                     parent_cmd);
    # $cmd->run(($cmd->prefix  ('string', '30'));

    # for my $prefix qw(s lis foo) {
    #   p [prefix, cmd.complete(prefix)];
    # }
}

1;
