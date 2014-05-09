# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Interactive;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

=pod

=head2 Synopsis:

=cut

our $HELP = <<"EOH";
=pod

B<show interactive>

Show whether debugger input is a terminal.
=cut
EOH
our $SHORT_HELP = "Show whether debugger input is a terminal";
our $MIN_ABBREV = length('inter');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $intf = $proc->{interfaces}->[-1];
    my $bool =  $intf->is_interactive();
    my $msg = sprintf("Debugger's interactive mode is %s.",
                      $self->show_onoff($bool));
    $proc->msg($msg);
    if ($bool) {
        $bool = $intf->{input}->can("have_term_readline") &&
            $intf->{input}->have_term_readline();
        $msg = sprintf("Terminal Readline capability is %s.",
                       $self->show_onoff(!!$bool));
        $proc->msg($msg);
    }
}

unless (caller) {
  # Demo it.
  # require_relative '../../mock'

  # # FIXME: DRY the below code
  # my ($dbgr, $cmd) = MockDebugger::setup('show');
  # $subcommand = __PACKAGE__->new(cmd);
  # $testcmdMgr = Trepan::Subcmd->new(subcommand);

  # $subcommand->run_show_bool();
  # $subcommand->summary_help($NAME);
}

1;
