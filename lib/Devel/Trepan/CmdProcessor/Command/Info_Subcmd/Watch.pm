# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014, 2018 Rocky Bernstein <rocky@cpan.org>

use warnings; use utf8;

package Devel::Trepan::CmdProcessor::Command::Info::Watch;

use rlib '../../../../..';

use if !@ISA, Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

unless (@ISA) {
    eval <<"EOE";
use constant MAX_ARGS => undef;  # Need at most this many - undef -> unlimited.
EOE
}

use strict; use types;

our @ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

our $CMD = 'info watch';
=pod

=head2 Synopsis:

=cut

our $HELP = <<'HELP';
=pod

B<info watch> [I<watchpoint1> I<watchpoint2> ...]

List watch information. If watchpoints are specified, only information
about them is shown. If no watchpoints are specified, show information
about all watchpoints.

=head2 See also:

L<C<watch>|<Devel::Trepan::CmdProcessor::Command::Watch>

=cut
HELP

our $MIN_ABBREV = length('wa');
our $SHORT_HELP = "Show watchpoint information";

no warnings 'redefine';
# sub complete($self, $prefix) {
# {
#     my @cmds = sort keys %{$proc->{macros}};
#     Trepan::Complete.complete_token(@cmds, $prefix);
# }

# sub save_command($self)
# {
#     my $proc = $self->{proc};
#     my $wpmgr = $proc->{dbgr}{watch};
#     my @res = ();
#     for my $bp ($wpmgr->list) {
#       push @res, "watch ${loc}";
#     }
#     return @res;
# }

sub wpprint
{
    my ($self, $wp, $verbose) = @_;
    my $proc = $self->{proc};
    my $disp = $wp->enabled ? 'y  '   : 'n  ';

    my $mess = sprintf('%-4dwatchpoint %s %s', $wp->id, $disp, $wp->expr);
    $proc->msg($mess);

    if ($wp->hits > 0) {
        my $ss = ($wp->hits > 1) ? 's' : '';
        my $msg = sprintf("\twatchpoint already hit %d time%s",
                          $wp->hits, $ss);
        $proc->msg($msg);
    }
}

sub run($self, $args) {
    my $proc = $self->{proc};
    my $watchmgr = $proc->{dbgr}{watch};
    my @args = @$args;
    if (scalar(@args) > 2) {
        shift @args; shift @args;
        for my $wp_name (@args) {
            if ($watchmgr->find_by_name({$wp_name})) {
                $self->wpprint($wp_name);
            } else {
                $proc->msg("$wp_name is not a defined watchpoint");
            }
        }
    } else {
        my @watchpoints = $watchmgr->list;
        if (scalar @watchpoints == 0) {
            $proc->msg("No watch expressions defined.");
        } else {
            # There's at least one
            $proc->section("Num Type       Enb Expression");
            for my $wp (@watchpoints) {
                $self->wpprint($wp);
            }
        }
   }
}

unless(caller) {
    # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Info->new($proc, 'info');
    my $cmd = __PACKAGE__->new($parent, 'watch');
    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";

    # print join(' ', @{$cmd->{prefix}}), "\n";
    # print '-' x 30, "\n";
    # $cmd->run($cmd->{prefix});
}

1;
