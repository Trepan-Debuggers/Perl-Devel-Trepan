# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';
use Data::Dumper;

package Devel::Trepan::CmdProcessor::Command::Info::Variables::My;
use vars qw(@ISA @SUBCMD_VARS);
unless (@ISA) {
    eval <<'EOE';
    use constant MAX_ARGS => undef;
    use constant NEED_STACK => 1;
EOE
}
use strict;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;
use PadWalker qw(peek_my);
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

our $CMD = "info variables my";
our @CMD = split(/ /, $CMD);
our $MIN_ABBREV = length('m');
our $HELP   = <<'HELP';
=pod

info variables my

info variables my -v

info variables my I<var1> [I<var2>...]

Lists C<my> variables at the current frame. Use the frame changing
commands like C<up>, C<down> or C<frame> set the current frame.

In the first form, give a list of C<my> variable names only.  In the
second form, list variable names and values In the third form, list
variable names and values of VAR1, etc.

See also C<set variable>, and frame changing commands.
=cut
HELP
our $SHORT_HELP   = "Information about 'my' variables.";

@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);

sub show_var($$$) 
{
    my ($proc, $var_name, $ref) = @_;
    my $dumper;
    my $type = substr($var_name, 0, 1);
    if ('$' eq $type) {
        $dumper = Data::Dumper->new([${$ref}]);
        $dumper->Useqq(0);
        $dumper->Terse(1);
        $dumper->Indent(0);
        $proc->msg("$var_name = ".  $dumper->Dump);
    } elsif ('@' eq $type) { 
        $dumper = Data::Dumper->new([$ref]); 
        $dumper->Useqq(0);
        $dumper->Terse(1);
        $dumper->Indent(0);
        $proc->msg("$var_name = ".  $dumper->Dump);
    } elsif ('%' eq $type) { 
        $dumper = Data::Dumper->new([$ref], [$var_name]);
        $dumper->Useqq(0);
        $dumper->Terse(0);
        $dumper->Indent(0);
        $proc->msg($dumper->Dump);
    } else {
        $dumper = Data::Dumper->new([$ref], [$var_name]); 
        $dumper->Useqq(0);
        $dumper->Terse(1);
        $dumper->Indent(0);
        $proc->msg($dumper->Dump);
    };
}


sub process_args($$$$) {
    my ($self, $args, $hash_ref, $lex_type) = @_;
    my $proc = $self->{proc};
    my @ARGS = @{$args};
    my @names = sort keys %{$hash_ref};

    if (0 == scalar @ARGS) {
        if (scalar @names) {
            $proc->section("$lex_type variables");
            $proc->msg($self->{parent}{parent}->columnize_commands(\@names));
        } else {
            $proc->msg("No '$lex_type' variables at this level");
        }
    } else {
        if ($ARGS[0] eq '-v') {
            if (scalar @names) {
                $proc->section("$lex_type variables");
                for my $name (@names) {
                    show_var($proc, $name, $hash_ref->{$name});
                }
            } else {
                $proc->msg("No '$lex_type' variables at this level");
            }
        } else {
            for my $name (@ARGS) {
                if (exists($hash_ref->{$name})) {
                    show_var($proc, $name, $hash_ref->{$name});
                } else {
                    $proc->errmsg("No '$lex_type' variable $name found at this level");
                }
            }
        }
    }
}

sub run($$)
{
    my ($self, $args) = @_;
    # FIXME: combine with My.pm
    my $i = 0;
    while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
    my $diff = $i - $DB::stack_depth;

    # FIXME: 4 is a magic fixup constant, also found in DB::finish.
    # Remove it.
    my $var_hash = peek_my($diff + $self->{proc}{frame_index} + 4);
    my @ARGS = splice(@{$args}, scalar(@CMD));
    $self->process_args(\@ARGS, $var_hash, 'my');
}

unless (caller) { 
    # Demo it.
    require Devel::Trepan;
    # require_relative '../../mock'
    # dbgr, parent_cmd = MockDebugger::setup('set', false)
    # cmd              = Trepan::SubSubcommand::SetMax.new(dbgr.core.processor, 
    #                                                      parent_cmd)
    # cmd.run(cmd.prefix + ['string', '30'])
    
    # %w(s lis foo).each do |prefix|
    #   p [prefix, cmd.complete(prefix)]
    # end
}

1;
