# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Set::Variable;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;
use PadWalker qw(peek_our peek_my);

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD = "set variable";

=pod

=head2 Synopsis:

=cut
our $HELP   = <<'HELP';
=pod

B<set variable> I<variable-name> I<value>

Set a I<my> or I<our> variable; I<value> must be a constant.

=head2 Examples:

  set variable $foo 20
  set variable @ARY = (1,2,3)

=head2 See also:

L<C<eval>|Devel::Trepan::CmdProcessor::Command::Eval>

=cut
HELP

our $SHORT_HELP   = "Set a 'my' or 'our' variable";

unless (@ISA) {
    eval <<"EOE";
use constant MIN_ARGS   => 2;
use constant MAX_ARGS   => undef;
use constant NEED_STACK => 1;
EOE
}

our $MIN_ABBREV = length('var');

sub set_var($$$)
{
    my ($var_name, $ref, $value) = @_;
    my $type = substr($var_name, 1, 1);
    if ('$' eq $type) {
        ${$ref->{$var_name}}  = $value;
    } elsif ('@' eq $type) {
        @{$ref->{$var_name}}  = @{$value};
    } elsif ('%' eq $type) {
        %{$ref->{$var_name}}  = %{$value};
    } else {
        ${$ref->{$var_name}}  = $value;
    }
}

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my @args = @$args;
    shift @args; shift @args;

    my $var_name = shift @args;
    shift @args if $args[0] eq '=';
    my $value = join(' ', @args);

    my $i;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    no warnings 'once';
    my $diff = $i - $DB::stack_depth;
    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $our_hash = peek_our($diff + $proc->{frame_index} + 4);
    my $my_hash  = peek_my($diff + $proc->{frame_index} + 4);

    if (exists($my_hash->{$var_name})) {
        set_var($var_name, $my_hash, $value);
    } elsif (exists($our_hash->{$var_name})) {
        set_var($var_name, $my_hash, $value);
    } else {
        $proc->errmsg("Can't find $var_name as a 'my' or 'our' variable");
    }
}

unless (caller) {
    require Devel::Trepan;
    # Demo it.
    # require_relative '../../mock'
    # my($dbgr, $parent_cmd) = MockDebugger::setup('show');
    # $cmd = __PACKAGE__->new(parent_cmd);
    # $cmd->run(@$cmd->prefix);
}

# Suppress a "used-once" warning;
$HELP || scalar @SUBCMD_VARS;
