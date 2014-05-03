# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../..';

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
our $HELP   = <<"HELP";
=pod

B<set display eval> {I<concise>|I<dprint>|I<dumper>|I<tidy>}

Set how you want evaluation results to be shown.


Devel::Trepan relegates how Perl the contents of expressions variables
are displayed to one of the many Perl modules designed for this
purpose. Below is a list of the option name and the corresponding Perl
module that gets used for that option. I<Note: the order given is the
order tried by default on startup.>

=over

=item *
C<dprint> E<mdash> L<Data::Printer>

=item *
C<tidy> E<mdash> L<Data::Dumper::Perltidy>

=item *
C<concise> E<mdash> L<Data::Dumper::Concise>

=item *
C<dumper> E<mdash> L<Data::Dumper>

=back

See the respective display manual pages for how to influence display
for a given module.

See also: C<show display eval>, C<eval>, and C<set autoeval>.
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
    my $evaltype = $args->[3];
    my @result = grep($_ eq $evaltype, @DISPLAY_TYPES);
    if (1 == scalar @result) {
        my $key = $self->{subcmd_setting_key};
        $proc->{settings}{$key} = $evaltype;
    } else {
        my $or_list = join(', or ', map{"'$_'"} @DISPLAY_TYPES);
        $proc->errmsg("Expecting either $or_list; got ${evaltype}");
        return;
    }
    $proc->{commands}{show}->run(['show', 'display', 'eval']);
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
