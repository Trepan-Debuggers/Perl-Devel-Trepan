# -*- coding: utf-8 -*-
# Copyright (C) 2011-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

# eval "use Data::Dumper::Perltidy";

package Devel::Trepan::CmdProcessor::Command::Set::Display::Eval;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
# Values inherited from parent

use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;
our $CMD = 'set display eval';
my @DISPLAY_TYPES = @Devel::Trepan::CmdProcessor::DISPLAY_TYPES;
my $param = join('|', @DISPLAY_TYPES);
=pod

=head2 Synopsis:

=cut

our $HELP   = <<"HELP";
=pod

B<set display eval> {B<concise>|B<ddp>|B<dumper>|B<tidy> [printer options]}

Set how you want evaluation results to be shown.

Devel::Trepan relegates how Perl the contents of expressions variables
are displayed to one of the many Perl modules designed for this
purpose. Below is a list of the option name and the corresponding Perl
module that gets used for that option. I<Note: the order given is the
order tried by default on startup.>

=over

=item *
C<ddp> E<mdash> L<Data::Printer>

=item *
C<tidy> E<mdash> L<Data::Dumper::Perltidy>

=item *
C<concise> E<mdash> L<Data::Dumper::Concise>

=item *
C<dumper> E<mdash> L<Data::Dumper>

=back

See the respective display manual pages for how to influence display
for a given module.

=head2 Examples:

    set display eval dumper
    set display eval ddp  # works only if Data::Printer is around
    set display eval ddp { colored => 0 }
    set display eval tidy    # works if Data::Dumper::Perltidy is around
    set display eval tidy -nst -mbl=2 -pt=0 -nola

=head2 See also:

L<C<show display eval>|Devel::Trepan::CmdProcessor::Command::Show::Display::Eval>,
L<C<eval>|Devel::Trepan::CmdProcessor::Command::Eval>,
L<C<set auto eval>|Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval>,
L<Data::Dumper::Perltidy>, and
L<Data::Printer>.

=cut
HELP

our $MIN_ABBREV = length('ev');
use constant MIN_ARGS => 1;
use constant MAX_ARGS => 1;
our $SHORT_HELP = 'Set how you want the evaluation results shown';

sub complete($$)
{
    my ($self, $prefix) = @_;
    Devel::Trepan::Complete::complete_token(\@DISPLAY_TYPES, $prefix);
}

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @{$args};
    my $evaltype = $args[3];
    my @result = grep($_ eq $evaltype, @DISPLAY_TYPES);
    if (1 == scalar @result) {
        my $key = $self->{subcmd_setting_key};
        $proc->{settings}{$key} = $evaltype;
	my $argc = scalar @args;
	if ($argc > 4) {
	    my $dp_args = join(' ', @{$args[4..$argc-1]});
	    if ($evaltype eq 'ddp') {
		eval("use Data::Printer $dp_args");
	    } elsif ($evaltype eq 'tidy') {
		eval "$Data::Dumper::Perltidy::ARGV = '$dp_args'";
	    }
	}
    } else {
        my $or_list = join(', or ', map{"'$_'"} @DISPLAY_TYPES);
        $proc->errmsg("Expecting either $or_list; got ${evaltype}");
        return;
    }
    $proc->{commands}{show}->run(['show', 'display', 'eval']);
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Set->new($cmdproc, 'set');
    my $parent_cmd =  Devel::Trepan::CmdProcessor::Command::Set::Display->new($subcmd, 'display');
    my $cmd   =  __PACKAGE__->new($parent_cmd, 'eval');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    my @args = qw(set display eval dumper);
    $cmd->run(\@args);
    @args = qw(set display eval concise);
    $cmd->run(\@args);
}

1;
