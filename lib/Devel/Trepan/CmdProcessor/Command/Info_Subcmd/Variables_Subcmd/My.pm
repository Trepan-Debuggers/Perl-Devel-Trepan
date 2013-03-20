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
my  @CMD = split(/ /, $CMD);
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
    my $ref = peek_my($diff + $self->{proc}{frame_index} + $fixup_num);
    return $ref;
}

sub complete($$;$)
{ 
    my ($self, $prefix, $fixup_num) = @_;
    
    # This is really hacky
    unless ($fixup_num) {
	my $i = 0;
	while (my ($pkg, $file, $line, $fn) = caller($i++)) { 
	    last if $pkg eq 'Devel::Trepan::CmdProcessor' && $fn eq '(eval)';
	    last if $pkg eq 'Devel::Trepan::Core' && 
		$fn eq 'Devel::Trepan::CmdProcessor::process_commands';
	};
	
	$fixup_num = $i;
    }

    # print "FIXUP_NUM is $fixup_num\n";

    my $var_hash = $self->get_var_hash($fixup_num);
    my @vars = sort keys %$var_hash;
    Devel::Trepan::Complete::complete_token(\@vars, $prefix) ;
}


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


sub process_args($$$) {
    my ($self, $args, $hash_ref) = @_;
    my $lex_type = $self->{prefix}[-1];
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

sub run($$;$)
{
    my ($self, $args, $fixup_num) = @_;
    my $var_hash = $self->get_var_hash($fixup_num);
    my @ARGS = splice(@{$args}, scalar(@CMD));
    $self->process_args(\@ARGS, $var_hash);
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
    my $cmd = __PACKAGE__->new($parent, 'my');

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
    $cmd->run(\@args, -2);
    print '-' x 40, "\n";
    $cmd->run($cmd->{prefix}, -1);
    print '-' x 40, "\n";
    my @complete = $cmd->complete('', -2);
    print join(', ', @complete), "\n";
    print '-' x 40, "\n";
    @complete = $cmd->complete('$p', -2);
    print join(', ', @complete), "\n";

}

1;
