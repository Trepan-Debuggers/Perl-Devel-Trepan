# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Highlight;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use Devel::Trepan::DB::LineCache;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = 'Set whether we use terminal highlighting';
our $MIN_ABBREV = length('hi');
=pod

=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<set highlight> [B<on>|B<off>|B<reset>]

Set whether we use terminal highlighting; "on" and "off" are
self-explanitory. Use "reset" to set highlighting on and force a redo
of syntax highlighting of already cached files. This may be needed if
the debugger was started without syntax higlighting initially.

If "on", "off" or "reset" is not given, "on" is assumed.

=head2 See also:

L<C<show highlight>|Devel::Trepan::CmdProcessor::Command::Show::Highlight>

=cut
HELP

sub complete($$)
{
    my ($self, $prefix) = @_;
    Devel::Trepan::Complete::complete_token(['on', 'off', 'reset'],
					    $prefix);
}

sub run($$)
{
    my ($self, $args) = @_;
    if (scalar @$args == 3 && 'reset' eq $args->[2]) {
        clear_file_format_cache;
        $self->{proc}{settings}{highlight} = 'term';
    } else {
        $self->SUPER::run($args);
        $self->{proc}{settings}{highlight} = 'term' if
            $self->{proc}{settings}{highlight};
    }
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my $cmd =
  #   Devel::Trepan::MockDebugger::sub_setup(__PACKAGE__, 0);
  # $cmd->run(@$cmd->prefix + ('off'));
  # $cmd->run(@$cmd->prefix + ('ofn'));
  # $cmd->run(@$cmd->prefix);
  # print $cmd->save_command(), "\n";

}

1;
