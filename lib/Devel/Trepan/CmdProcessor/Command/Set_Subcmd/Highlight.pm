# -*- coding: utf-8 -*-
# Copyright (C) 2011-2015 Rocky Bernstein <rocky@cpan.org>
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

B<set highlight> [B<reset> | B<plain> | B<light> | B<dark> | B<off>]

Set whether we use terminal highlighting; Permissable values are:

=over

=item plain

no terminal highlighting

=item off

same as plain

=item light

light

terminal background is light (the default)

=item dark

terminal background is darkon" and "off" are

=back

If the first argument is *reset*, we clear any existing color formatting
and recolor all source code output.

=head2 Examples:

    set highlight off   # no highlight
    set highlight plain # same as above
    set highlight       # same as above
    set highlight dark  # terminal has dark background
    set highlight light # terminal has light background
    set highlight reset light # clear source-code cache and
                              # set for light background
    set highlight reset # clear source-code cache

=head2 See also:

L<C<show highlight>|Devel::Trepan::CmdProcessor::Command::Show::Highlight>

=cut
HELP

my @choices = qw(reset plain light dark off);
sub complete($$)
{
    my ($self, $prefix) = @_;
    Devel::Trepan::Complete::complete_token(\@choices, $prefix);
}

sub get_highlight_type($$)
{
    my ($self, $arg) = @_;
    return 'light' unless $arg;
    if (grep {$arg eq $_} @choices) {
	return $arg;
    } else {
	my $proc = $self->{proc};
	my $msg = sprintf('Expecting one of: %s; got "%s"',
			  join(', ', @choices), $arg);
	$proc->errmsg($msg);
	return undef;
    }
}

sub run($$)
{
    my ($self, $args) = @_;

    my $proc = $self->{proc};
    my $highlight_type = 'light';
    if ((scalar @$args >= 3) && ('reset' eq $args->[2])) {
	if (scalar @$args > 3) {
	    $highlight_type = $self->get_highlight_type($args->[3]);
	} else  {
	    $highlight_type = $proc->{settings}{'highlight'};
            return unless $highlight_type;
            clear_file_format_cache();
        }
    } elsif (scalar @$args == 2) {
	$highlight_type = 'off';
    } else {
	$highlight_type = $self->get_highlight_type($args->[2]);
	return unless $highlight_type;
    }
    if ($highlight_type eq 'plain' || $highlight_type eq 'off') {
	$highlight_type = undef ;
    } else {
	Devel::Trepan::DB::LineCache::color_setup($highlight_type);
    }
    $proc->{settings}{'highlight'} = $highlight_type;
    $proc->set_prompt();
    my $show_cmd = $proc->{commands}->{'show'};
    $show_cmd->run(['show', 'highlight']);
}

unless (caller) {
  # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Set->new($proc, 'set');
    my $cmd = __PACKAGE__->new($parent, 'highlight');
    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";
    print $cmd->run(['set', 'highlight', 'off']);

    for my $arg ('', 're', 'foo') {
	# use Enbugger('trepan'); Enbugger->stop();
        my @aref = $cmd->complete($arg);
        printf "complete '%s': %s\n", $arg, join(', ', @aref);
    }
}

1;
