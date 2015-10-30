# -*- coding: utf-8 -*-
# Copyright (C) 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';
use English qw( -no_match_vars );
use rlib '../../../..';
use B::Deparse;

# require_relative '../../app/condition'

package Devel::Trepan::CmdProcessor::Command::Deparse;
use English qw( -no_match_vars );
use Devel::Trepan::DB::LineCache;
use Devel::Trepan::CmdProcessor::Validate;
use if !@ISA, Devel::Trepan::CmdProcessor::Command;
use Getopt::Long qw(GetOptionsFromArray);

unless (@ISA) {
    eval <<'EOE';
    use constant CATEGORY   => 'files';
    use constant SHORT_HELP => 'Deparse source code';
    use constant MIN_ARGS   => 0; # Need at least this many
    use constant MAX_ARGS   => undef;
    use constant NEED_STACK => 0;
EOE
}

use strict; use vars qw(@ISA); @ISA = @CMD_ISA;
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<deparse> [I<B::Deparse-options>] [I<filename> | I<subroutine>]

B::Deparse options:

    -d  Output data values using Data::Dumper
    -l  Add '#line' declaration
    -P  Disable prototype checking
    -q  Expand double-quoted strings

Deparse Perl source code using L<B::Deparse>.

Without arguments, prints the current subroutine if there is one.

=head2 Examples:

  deparse            # deparse current subroutine or main file
  deparse file.pm
  deparse -l file.pm

=head2 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>, and
L<B::Deparse> for more information on deparse options.

=cut
HELP

# FIXME: Should we include all files?
# Combine with BREAK completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    # For line numbers we'll use stoppable line number even though one
    # can enter line numbers that don't have breakpoints associated with them
    my @completions = sort(file_list, DB::subs());
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub parse_options($$)
{
    my ($self, $args) = @_;
    my @opts = ();
    my $result =
	&GetOptionsFromArray($args,
			     '-d'  => sub {push(@opts, '-d') },
			     '-l'  => sub {push(@opts, '-l') },
			     '-P'  => sub {push(@opts, '-P') },
			     '-q'  => sub {push(@opts, '-q') }
        );
    @opts;
}

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @args     = @$args;
    @args = splice(@args, 1, scalar(@args), -2);
    my @options = parse_options($self, \@args);
    my $proc     = $self->{proc};
    my $filename = $proc->{list_filename};
    my $frame    = $proc->{frame};
    my $funcname = $proc->{frame}{fn};
    my $have_func;
    if (scalar @args == 0) {
	# Use function if there is one. Otherwise use
	# the current file.
	$have_func = 1 if $proc->{stack_size} > 0 && $funcname;
    } elsif (scalar @args == 1) {
	$filename = $args[0];
	my $subname = $filename;
	$subname = "main::$subname" if index($subname, '::') == -1;
	my @matches = $self->{dbgr}->subs($subname);
	if (scalar(@matches) >= 1) {
	    $funcname = $subname;
	    $have_func = 1;
	} else {
	    my $canonic_name = map_file($filename);
	    if (is_cached($canonic_name)) {
		$filename = $canonic_name;
	    }
	}
    } else {
	$proc->errmsg('Expecting exactly one file or function name');
	return;
    }

    my $text;
    # FIXME: we assume func below, add parse options like filename, and
    if ($have_func) {
	if (scalar @args == 0 && $proc->{op_addr}) {
	    my $deparse = B::Deparse->new("-p", "-l", "-sC");
	    my $coderef = \&$funcname;
	    my $cv = B::svref_2object($coderef);
	    my $cop_addr = find_op_addr($cv, $proc->{op_addr});
	    if (!$cop_addr) {
		$proc->errmsg("Can't find COP for address 0x%x", $proc->{op_addr});
		return;
	    }
	    my @exprs = $deparse->coderef2list($coderef);
	    for (my $i = 0; $i < scalar @exprs; $i++) {
		my $tuple_ref = $exprs[$i];
		my $addr = hex($tuple_ref->[0]);
		if ($addr == $cop_addr) {
		    $text = $tuple_ref->[1];
		    if ($i+1 < scalar @exprs) {
			$text .= ("\n" . $exprs[$i+1][1]);
		    }
		    goto DONE;
		}
	    }
	    return;
	} else {
	    my $deparse = B::Deparse->new('-p', '-l',  @options);
	    my @package_parts = split(/::/, $funcname);
	    my $prefix = '';
	    $prefix = join('::', @package_parts[0..scalar(@package_parts) - 1])
		if @package_parts;
	    my $short_func = $package_parts[-1];

	    $text = "package $prefix;\nsub $short_func" . $deparse->coderef2text(\&$funcname);
	}
    } else  {
	my $options = join(',', @options);
	my $cmd="$EXECUTABLE_NAME  -MO=Deparse,$options $filename";
	$text = `$cmd 2>&1`;
	if ($? >> 8 != 0) {
	    $proc->msg($text);
	    return;
	}
    };
  DONE:
    $text = Devel::Trepan::DB::LineCache::highlight_string($text) if $proc->{settings}{highlight};
    $proc->msg($text);

}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    require Devel::Trepan::DB::Sub;
    require Devel::Trepan::DB::LineCache;
    cache_file(__FILE__);
    my $frame_ary = Devel::Trepan::CmdProcessor::Mock::create_frame();
    $proc->frame_setup($frame_ary);
    $proc->{settings}{highlight} = undef;
    $cmd->run([$NAME]);
    print '-' x 30, "\n";
    $cmd->run([$NAME, '-l']);
    print '-' x 30, "\n";
    $proc->{frame}{fn} = 'run';
    $proc->{settings}{highlight} = 'dark';
    $cmd->run([$NAME]);
}

1;

sub B::OP::check_op($) {
    my $op = shift;
    no strict;
    if ($op->name eq 'dbstate') {
	# printf "setting cop 0x%s\n", $$op;
	$last_cop = $op;
    }
    if ($$op == $find_addr) {
	$found_op = $op;
	$found_cop = $last_cop;
	# printf "WOOT 0x%x 0x%x\n", $$found_op, $$found_cop;
    }
}

sub find_op($$) {
    my ($cv, $addr) = @_;
    no strict;
    local ($find_addr, $found_op, $found_cop, $last_cop);
    $find_addr = $addr;
    # require B::Debug;
    # B::walkoptree($cv->ROOT, "debug");
    B::walkoptree($cv->ROOT, 'check_op');
    return $found_cop;
}

sub find_op_addr($$) {
    my ($cv, $addr) = @_;
    my $cop = find_op($cv, $addr);
    return $cop ? $$cop : undef;
}

package B::Deparse;

sub coderef2list {
    my ($self, $coderef) = @_;
    croak "Usage: ->coderef2list(CODEREF)" unless UNIVERSAL::isa($coderef, "CODE");
    $self->init();
    return $self->deparse_sub_list(svref_2object($coderef));
}

sub walk_lineseq {
    my ($self, $op, $kids, $callback) = @_;
    my @kids = @$kids;
    for (my $i = 0; $i < @kids; $i++) {
	my $expr = "";
	if (is_state $kids[$i]) {
	    $expr = $self->deparse($kids[$i++], 0);
	    if ($i > $#kids) {
		$callback->($expr, $i);
		last;
	    }
	}
	if (is_for_loop($kids[$i])) {
	    $callback->($expr . $self->for_loop($kids[$i], 0),
		$i += $kids[$i]->sibling->name eq "unstack" ? 2 : 1);
	    next;
	}
	$expr .= $self->deparse($kids[$i], (@kids != 1)/2);
	$expr =~ s/;\n?\z//;
	$expr =~ s/\((.+)\)$/$1/;
	$callback->($expr, $i);
    }
}

sub walk_lineseq_list {
    my ($self, $op, $kids, $callback) = @_;
    my @kids = @$kids;
    my @exprs = ();
    my $expr;
    for (my $i = 0; $i < @kids; $i++) {
	if (is_state $kids[$i]) {
	    $expr = ($self->deparse($kids[$i], 0));
	    $callback->(\@exprs, $i, $expr);
	    $i++;
	    if ($i > $#kids) {
		last;
	    }
	}
	if (is_for_loop($kids[$i])) {
	    my $loop_expr = $self->for_loop($kids[$i], 0);
	    $callback->(\@exprs,
			$i += $kids[$i]->sibling->name eq "unstack" ? 2 : 1,
			$loop_expr);
	    next;
	}
	$expr = $self->deparse($kids[$i], (@kids != 1)/2);
	$callback->(\@exprs, $i, $expr);
    }
    return @exprs;
}

sub deparse_sub_list {
    my ($self, $cv) = @_;
    my $proto = "";
    Carp::confess("NULL in deparse_sub_list") if !defined($cv) || $cv->isa("B::NULL");
    Carp::confess("SPECIAL in deparse_sub_list") if $cv->isa("B::SPECIAL");
    local $self->{'curcop'} = $self->{'curcop'};
    if ($cv->FLAGS & SVf_POK) {
	$proto = "(". $cv->PV . ") ";
    }
    if ($cv->CvFLAGS & (CVf_METHOD|CVf_LOCKED|CVf_LVALUE)) {
        $proto .= ": ";
        $proto .= "lvalue " if $cv->CvFLAGS & CVf_LVALUE;
        $proto .= "locked " if $cv->CvFLAGS & CVf_LOCKED;
        $proto .= "method " if $cv->CvFLAGS & CVf_METHOD;
    }

    local($self->{'curcv'}) = $cv;
    local($self->{'curcvlex'});
    local(@$self{qw'curstash warnings hints hinthash'})
		= @$self{qw'curstash warnings hints hinthash'};
    my @body = ([sprintf("0x%x", $$cv), $proto]);
    my $root = $cv->ROOT;
    local $B::overlay = {};
    if (not null $root) {
	$self->pessimise($root, $cv->START);
	my $lineseq = $root->first;
	if ($lineseq->name eq "lineseq") {
	    my @ops;
	    for(my$o=$lineseq->first; $$o; $o=$o->sibling) {
		push @ops, $o;
	    }
	    push @body, $self->lineseq_list(undef, 0, @ops);
	    my $scope_en = $self->find_scope_en($lineseq);
	}
	else {
	    push @body, $self->deparse($root->first, 0);
	}
    }
    else {
	my $sv = $cv->const_sv;
	if ($$sv) {
	    # uh-oh. inlinable sub... format it differently
	    return ($proto . "{ " . $self->const($sv, 0) . ") }");
	} else { # XSUB? (or just a declaration)
	    return ("$proto");
	}
    }
    return @body;
}

sub lineseq_list {
    my($self, $root, $cx, @ops) = @_;

    my $out_cop = $self->{'curcop'};
    my $out_seq = defined($out_cop) ? $out_cop->cop_seq : undef;
    my $limit_seq;
    if (defined $root) {
	$limit_seq = $out_seq;
	my $nseq;
	$nseq = $self->find_scope_st($root->sibling) if ${$root->sibling};
	$limit_seq = $nseq if !defined($limit_seq)
			   or defined($nseq) && $nseq < $limit_seq;
    }
    $limit_seq = $self->{'limit_seq'}
	if defined($self->{'limit_seq'})
	&& (!defined($limit_seq) || $self->{'limit_seq'} < $limit_seq);
    local $self->{'limit_seq'} = $limit_seq;

    my $fn = sub {
	my ($exprs, $i, $text) = @_;
	$text =~ s/\f//;
	$text =~ s/\n$//;
	$text =~ s/;\n?\z//;
	$text =~ s/^\((.+)\)$/$1/;
	my $op = $ops[$i];
	push @$exprs, [sprintf("0x%x", $$op), $text];
    };
    return $self->walk_lineseq_list($root, \@ops, $fn);
    # $self->walk_lineseq($root, \@ops,
    # 		       sub { push @exprs, $_[0]} );
}

# Notice how subs and formats are inserted between statements here;
# also $[ assignments and pragmas.
sub pp_nextstate {
    my $self = shift;
    my($op, $cx) = @_;
    $self->{'curcop'} = $op;
    my @text;
    push @text, $self->cop_subs($op);
    my $stash = $op->stashpv;
    if ($stash ne $self->{'curstash'}) {
	push @text, "package $stash;\n";
	$self->{'curstash'} = $stash;
    }

    if (OPpCONST_ARYBASE && $self->{'arybase'} != $op->arybase) {
	push @text, '$[ = '. $op->arybase .";\n";
	$self->{'arybase'} = $op->arybase;
    }

    my $warnings = $op->warnings;
    my $warning_bits;
    if ($warnings->isa("B::SPECIAL") && $$warnings == 4) {
	$warning_bits = $warnings::Bits{"all"} & WARN_MASK;
    }
    elsif ($warnings->isa("B::SPECIAL") && $$warnings == 5) {
        $warning_bits = $warnings::NONE;
    }
    elsif ($warnings->isa("B::SPECIAL")) {
	$warning_bits = undef;
    }
    else {
	$warning_bits = $warnings->PV & WARN_MASK;
    }

    if (defined ($warning_bits) and
       !defined($self->{warnings}) || $self->{'warnings'} ne $warning_bits) {
	push @text, declare_warnings($self->{'warnings'}, $warning_bits);
	$self->{'warnings'} = $warning_bits;
    }

    my $hints = $] < 5.008009 ? $op->private : $op->hints;
    my $old_hints = $self->{'hints'};
    if ($self->{'hints'} != $hints) {
	push @text, declare_hints($self->{'hints'}, $hints);
	$self->{'hints'} = $hints;
    }

    my $newhh;
    if ($] > 5.009) {
	$newhh = $op->hints_hash->HASH;
    }

    if ($] >= 5.015006) {
	# feature bundle hints
	my $from = $old_hints & $feature::hint_mask;
	my $to   = $    hints & $feature::hint_mask;
	if ($from != $to) {
	    if ($to == $feature::hint_mask) {
		if ($self->{'hinthash'}) {
		    delete $self->{'hinthash'}{$_}
			for grep /^feature_/, keys %{$self->{'hinthash'}};
		}
		else { $self->{'hinthash'} = {} }
		$self->{'hinthash'}
		    = _features_from_bundle($from, $self->{'hinthash'});
	    }
	    else {
		my $bundle =
		    $feature::hint_bundles[$to >> $feature::hint_shift];
		$bundle =~ s/(\d[13579])\z/$1+1/e; # 5.11 => 5.12
		push @text, "no feature;\n",
			    "use feature ':$bundle';\n";
	    }
	}
    }

    if ($] > 5.009) {
	push @text, declare_hinthash(
	    $self->{'hinthash'}, $newhh,
	    $self->{indent_size}, $self->{hints},
	);
	$self->{'hinthash'} = $newhh;
    }

    # This should go after of any branches that add statements, to
    # increase the chances that it refers to the same line it did in
    # the original program.
    if ($self->{'linenums'}) {
	my $line = sprintf("# line %s '%s' 0x%x\n",
			   $op->line, $op->file, $$op);
	push @text, $line;
    }

    push @text, $op->label . ": " if $op->label;

    return join("", @text);
}

1;
