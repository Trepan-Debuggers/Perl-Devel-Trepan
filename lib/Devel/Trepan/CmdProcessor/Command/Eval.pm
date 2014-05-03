# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; use utf8;
use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Eval;
use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => qw(eval? eval@ eval% eval$ eval@? @ % $ p);
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Run code in the current context';
use constant NEED_STACK => 0;
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
EOE
}
use strict;
use Devel::Trepan::Util;

use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod

B<eval>[B<@$>][B<?>] [I<Perl-code>]

Run I<Perl-code> in the context of the current frame.

If no string is given after the command "eval", we run the string from
the current source code about to be run. If the command ends ? (via an
alias) and no string is given we will the perform the translations:

 {if|elsif|unless} (expr) [{]  => expr
 {until|while} (expr) [{]      => expr
 return expr [;]               => expr
 {my|local|our} (expr1, expr2) = (v1,v2);
                               => (expr1, expr2) = (v1,v2)
 {my|local|our} var = expr ;   => expr
 given expr                    => expr
 sub fn(params)                => (params)
 var = expr                    => expr

The above is done via regular expression. No fancy parsing is done, say,
to look to see if expr is split across a line or whether var an assigment
might have multiple variables on the left-hand side.

The value of the expression is stored into global array I<@DB:D> so it
may be used again easily.

Normally eval assumes you are typing a statement, not an expression;
the result is a scalar value. However you can force the type of the result
by adding the appropriate sigil C<@>, C<%>, or C<$>.

=head2 Examples:

 eval 1+2 # 3
 eval$ 3   # Same as above, but the return type is explicit
 $ 3       # Probably same as above if $ alias is around
 eval $^X  # Possibly /usr/bin/perl
 eval      # Run current source-code line
 eval?     # but strips off leading 'if', 'while', ..
           # from command
 eval@ @ARGV  # Make sure the result printed and saved as an array rather
              # than as an array converted to a scalar.
 @ @ARG       # Same as above if @ alias is around
 eval% %ENV   # Make sure the result printed/saved as a hash
 use English  # Note this is a statement, not an expression
 use English; # Same as above
 eval$ use English # Error because this is not a valid expression

=head2 See also:

L<C<set auto eval>|Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval>.
=cut
HELP

no warnings 'redefine';
sub complete($$)
{
    my ($self, $prefix) = @_;
    if (!$prefix) {
        if (0 == index($self->{proc}{leading_str}, 'eval?')) {
            Devel::Trepan::Util::extract_expression(
                $self->{proc}->current_source_text());
        } else {
            $self->{proc}->current_source_text();
        }
    } else {
        $prefix;
    }
}

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $code_to_eval;
    my $cmd_name = $args->[0];
    my $eval_lead_word;
    my $hide_position = 1;

    if (1 == scalar @$args) {
        if ($proc->{terminated}) {
            $proc->msg_need_running("implicit eval source code");
            return;
        }
        # No string passed to eval. Pick up string to eval from
        # current source text.
        $code_to_eval  = $proc->current_source_text();
        $hide_position = 0;
        if ('?' eq substr($cmd_name, -1)) {
            $cmd_name = substr($cmd_name, 0, length($cmd_name)-1);
            $code_to_eval =
                Devel::Trepan::Util::extract_expression($code_to_eval);
            $proc->msg("eval: ${code_to_eval}");
            my @eval_args = split /\s+/, $code_to_eval;
            $eval_lead_word = $eval_args[0];
        } else {
            my @eval_args = split /\s+/, $code_to_eval;
            $eval_lead_word = $eval_args[0];
        }
    } else {
        # Use cmd_argstr to ensure we do not try tokenize what was typed.
        # But for purposes of sigil checking below, tokenization of the
        # leading word is okay.
        $code_to_eval = $proc->{cmd_argstr};
        $eval_lead_word = $args->[1];
    }
    {
        my $return_type = parse_eval_suffix($cmd_name);
        $return_type = parse_eval_sigil($eval_lead_word) unless $return_type;
        my $opts = {return_type       => $return_type,
                    hide_position     => $hide_position,
                    fix_file_and_line => 1,
        };
        no warnings 'once';
        $proc->eval($code_to_eval, $opts);
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $arg_str = '1 + 2';
    $proc->{cmd_argstr} = $arg_str;
    # print "eval ${arg_str} is: $cmd->run([$NAME, $arg_str])}\n";
    $arg_str = 'return "foo"';
    # # sub cmd.proc.current_source_text
    # # {
    # #   'return "foo"';
    # # }
    # $proc->{cmd_argstr} = $arg_str;
    # print "eval? ${arg_str} is: ", $cmd->run([$NAME . '?'])";
}

1;
