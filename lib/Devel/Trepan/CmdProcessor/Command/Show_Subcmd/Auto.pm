# -*- coding: utf-8 -*-
# Copyright (C) 2011,2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';
use strict;
use vars qw(@ISA @SUBCMD_VARS);

package Devel::Trepan::CmdProcessor::Command::Show::Auto;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::CmdProcessor::Command::Subcmd::SubsubMgr;
use vars qw(@ISA @SUBCMD_VARS);
our $MIN_ABBREV = length('au');
=pod

=head2 Synopsis:

=cut
our $HELP   = <<"EOH";
=pod

B<show auto> [I<show-auto sub-commmand> ...]

Show controls for things with some sort of "automatic" default behavior.

=head2 See also:

L<C<set auto>|Devel::Trepan::CmdProcessor::Command::Set::auto>
=cut
EOH

our $SHORT_HELP =
    'Show "automatic" default behavior controls';

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
