# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';

package Devel::Trepan::CmdProcessor::Command::Set::Auto::List;

BEGIN {
    my @OLD_INC = @INC;
    use rlib '../../../../../..';
    use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
    @INC = @OLD_INC
};

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

our $IN_LIST      = 1;
our $HELP         = <<'HELP';
=pod

B<set auto list> [B<on>|B<off>]

Set to run a C<list> command each time we enter the debugger.
=cut
HELP

our $MIN_ABBREV   = length('li');
use constant MAX_ARGS => 1;
our $SHORT_HELP   = "Set to run a 'list' command each time we enter the debugger";

sub run($$)
{
    my ($self, $args) = @_;
    $self->SUPER::run($args);
    my $proc = $self->{proc};
    if ( $proc->{settings}{autolist} ) {
        $proc->{cmdloop_prehooks}->insert_if_new(10, $proc->{autolist_hook}[0],
                                                 $proc->{autolist_hook}[1]);
    } else {
        $proc->{cmdloop_prehooks}->delete_by_name('autolist');
    }
}

unless (caller) {
  # Demo it.
  # require_relative '../../../mock'
  # name = File.basename(__FILE__, '.rb')

  # dbgr, set_cmd = MockDebugger::setup('set')
  # max_cmd       = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor,
  #                                                     set_cmd)
  # cmd_ary       = Trepan::SubSubcommand::SetMaxList::PREFIX
  # cmd_name      = cmd_ary.join(' ')
  # subcmd        = Trepan::SubSubcommand::SetMaxList.new(set_cmd.proc,
    #                                                        max_cmd,
  #                                                        cmd_name)
  # prefix_run = cmd_ary[1..-1]
  # subcmd.run(prefix_run)
  # subcmd.run(prefix_run + %w(0))
  # subcmd.run(prefix_run + %w(20))
  # name = File.basename(__FILE__, '.rb')
  # subcmd.summary_help(name)
  # puts
  # puts '-' * 20
  # puts subcmd.save_command
}

1;
