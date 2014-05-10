# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';
package Devel::Trepan::CmdProcessor::Command::Info::Variables::Our;

use vars qw(@ISA @SUBCMD_VARS);
use strict;
use Devel::Trepan::CmdProcessor::Command::Info_Subcmd::Variables_Subcmd::My;
use PadWalker qw(peek_our);

our $CMD = "info variables our";
our  @CMD = split(/ /, $CMD);
use constant MAX_ARGS => undef;
use constant NEED_STACK => 1;
=pod

=head2 Synopsis:

=cut
our $MIN_ABBREV = length('o');
our $HELP   = <<'HELP';
=pod

B<info variables our>

B<info variables our -v>

B<info variables our> I<var1> [I<var2>...]

List C<our> variables at the current stack level. Use the
frame changing commands like C<up>, C<down> or C<frame> set the
current frame.

In the first form, give a list of C<our> variable names only.
In the second form, list variable names and values In the third form,
list variable names and values of I<var1>, etc.

=head2 See also:

L<C<info variables
lexicals>|Devel::Trepan::CmdProcessor::Command::Info::Variables::Lexicals>,
L<C<info variables
my>|Devel::Trepan::CmdProcessor::Command::Info::Variables::My>, and
frame-changing commands

=cut
HELP
our $SHORT_HELP   = "Information about 'our' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Info::Variables::My);

sub get_var_hash($;$)
{
    my ($self, $fixup_num) = @_;
    # FIXME: combine with My.pm
    my $i = 0;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;

    # FIXME: 5 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    $fixup_num = 5 unless defined($fixup_num);
    peek_our($diff + $self->{proc}{frame_index} + $fixup_num);
}

unless (caller) {
    # Demo it.
    require Devel::Trepan;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $grandparent =
	Devel::Trepan::CmdProcessor::Command::Info->new($proc, 'info');
    my $parent =
	Devel::Trepan::CmdProcessor::Command::Info::Variables->new($grandparent,
								   'variables');
    my $cmd = __PACKAGE__->new($parent, 'our');

    eval {
        sub create_frame() {
            my ($pkg, $file, $line, $fn) = caller(0);
            $DB::package = $pkg;
            return [
                {
                    file      => $file,
                    fn        => $fn,
                    line      => $line,
                    pkg       => $pkg,
                }];
        }
    };
    my $frame_ary = create_frame();
    $proc->frame_setup($frame_ary);

    $cmd->run($cmd->{prefix}, -2);
    my @args = @{$cmd->{prefix}};
    push @args, '$args';
    print '-' x 40, "\n";
    push @args, '@CMD';
    print '-' x 40, "\n";
    $cmd->run(\@args, -2);
    print '-' x 40, "\n";
    $cmd->run($cmd->{prefix}, -1);
    print '-' x 40, "\n";
    my @complete = $cmd->complete('', -1);
    print join(', ', @complete), "\n";
    print '-' x 40, "\n";
    @complete = $cmd->complete('$p', -1);
    print join(', ', @complete), "\n";
}

1;
