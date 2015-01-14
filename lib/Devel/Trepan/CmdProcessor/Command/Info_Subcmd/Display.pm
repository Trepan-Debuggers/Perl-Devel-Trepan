# -*- coding: utf-8 -*-
# Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
use warnings; use utf8;
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Info::Display;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $SHORT_HELP = 'List display information';

## FIXME: do automatically.
our $CMD = "info display";

our $HELP = <<'HELP';
=pod

B<info display> [I<num1> ...] [B<verbose>]

Show status of user-settable display. If no display numbers are
given, the show all displays. Otherwise only those displays
listed are shown and the order given. If B<verbose> is given, more
information provided about each breakpoint.

=head2 Examples:

  trepanpl: info display
  Num Type          Disp Enb Where
  1   breakpoint    keep y   at gcd.pl:8
 	breakpoint already hit 1 time
  No actions.
  No watch expressions defined.

The I<Disp> column contains one of I<keep>, I<del>, the disposition of
the breakpoint after it gets hit.

The I<Enb> column indicates whether the breakpoint is enabled.

The I<Where> column indicates where the breakpoint is located.

=head2 See also:

L<C<display>|Devel::Trepan::CmdProcessor::Command::Display>, and
L<C<undisplay>|Devel::Trepan::CmdProcessor::Command::Undisplay>

=cut
HELP

our $MIN_ABBREV  = length('di');

no warnings 'redefine';
sub complete($$)
{
    my ($self, $prefix) = @_;
    my @displays = @{$self->{proc}{displays}{list}};
    my @completions = map $_->number,  @displays;
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub display_print($$)
{
    my ($self, $display) = @_;
    my $proc = $self->{proc};

    my $rt  = defined($display->return_type) ? $display->return_type : '?';
    my $fmt = defined($display->fmt) ? $display->fmt : '?';
    my $enabled .= $display->enabled ? 'y  '   : 'n  ';
    my $mess = sprintf("%-3d: %s    %s   %s %s", $display->number,
		       $rt, $fmt, $enabled, $display->arg);
    $proc->msg($mess);
}

# sub save_command($)
# {
#     my $self = shift;
#     my $proc = $self->{proc};
#     my $displays = $proc->{displays};
#     my @res = ();
#     for my $display ($display->list) {
#       push @res, "break ${loc}";
#     }
#    return @res;
# }

sub run($$) {
    my ($self, $args) = @_;
    my $verbose = 0;
    my $proc = $self->{proc};
    my @args = ();
    if (scalar @{$args} > 2) {
        @args = splice(@{$args}, 2);
        @args = $proc->get_int_list(\@args);
    }

    my @displays = @{$proc->{displays}{list}};
    if (0 == scalar @displays) {
        $proc->msg('No Displays.');
    } else {
        # There's at least one
        $proc->section("Num  Type Fmt En? Value");
        if (scalar(@args) == 0) {
            for my $display (@displays) {
                $self->display_print($display);
            }
        } else  {
            my @not_found = ();
            for my $display_num (@args)  {
                my $display = $proc->{displays}->find($display_num);
                if (defined($display)) {
                    $self->display_print($display, $verbose);
                } else {
                    push @not_found, $display_num;
                }
            }
            if (scalar @not_found) {
                my $msg = sprintf("No display number(s) %s.\n",
                                  join(', ', @not_found));
                $proc->errmsg($msg);
            }
        }
    }
}

if (caller) {
  # Demo it.
  # use rlib '../../mock'
  # name = File.basename(__FILE__, '.rb')
  # dbgr, cmd = MockDebugger::setup('info')
  # subcommand = Trepan::Subcommand::InfoBreakpoints.new(cmd)

  # print '-' * 20
  # subcommand.run(%w(info break))
  # print '-' * 20
  # subcommand.summary_help(name)
  # print
  # print '-' * 20

  # require 'thread_frame'
  # tf = RubyVM::ThreadFrame.current
  # pc_offset = tf.pc_offset
  # sub foo
  #   5
  # end

  # brk_cmd = dbgr.core.processor.commands['break']
  # brk_cmd.run(['break', "O${pc_offset}"])
  # cmd.run(%w(info break))
  # print '-' * 20
  # brk_cmd.run(['break', 'foo'])
  # subcommand.run(%w(info break))
  # print '-' * 20
  # print subcommand.save_command
}

1;
