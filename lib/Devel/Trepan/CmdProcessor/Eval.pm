# -*- coding: utf-8 -*-                                                         
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>                           
use warnings;
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
use Devel::Trepan::Util qw(hash_merge uniq_abbrev);
use PadWalker qw(peek_my peek_our);
use strict;

use vars qw($HAVE_EVAL_WITH_LEXICALS);                                          
BEGIN {                                                                         
    $HAVE_EVAL_WITH_LEXICALS = eval("use Eval::WithLexicals; 1") ? 1 : 0;     
}  

my $given_eval_warning = 0;

sub eval($$$$$) {
    my ($self, $code_to_eval, $opts, $correction) = @_;
    no warnings 'once';
    if (0 == $self->{frame_index} || !$HAVE_EVAL_WITH_LEXICALS) {
        unless (0 == $self->{frame_index}) {
            $self->msg("Evaluation occurs in top-most frame not this one");
        }
	$DB::eval_str = $self->{dbgr}->evalcode($code_to_eval);
	$DB::eval_opts = $opts;
	$DB::result_opts = $opts;
	$self->{DB_running} = 2;
	$self->{leave_cmd_loop} = 1;
    } else {
	# Have to use Eval::WithLexicals which, unfortunately,
	# loses on 'local' variables.

	my $i = 0;
	while (my ($pkg, $file, $line, $fn) = caller($i++)) { ; };
	my $diff = $i - $DB::stack_depth;

	my $my_hash  = peek_my($diff + $self->{frame_index} + $correction);
	my $our_hash = peek_our($diff + $self->{frame_index} + $correction);
	my $var_hash = hash_merge($my_hash, $our_hash);

	unless ($given_eval_warning) {
	    $self->msg("Evaluation in this frame may not find local values");
	    $given_eval_warning = 0 # 1;
	}

	my $context = 'scalar';
	my $return_type = $opts->{return_type};
	$return_type = '$' unless defined($return_type);
	if ('@' eq $return_type) {
	    $context = 'list';
	    $code_to_eval = "\@DB::eval_result = $code_to_eval";
	} else {
	    ## FIXME do fixup for hash.
	    $context = 'scalar';
	    $code_to_eval = "\$DB::eval_result = $code_to_eval";
	}
	my $eval = Eval::WithLexicals->new(
	    lexicals => $var_hash, 
	    in_package => $self->{frame}{pkg},
	    context => $context, 
	    # prelude => 'use warnings',  # default 'use strictures 1'
         );
	$eval->eval($code_to_eval);
	if ('@' eq $return_type) {
	    return @DB::eval_result;
	} else {
	    return $DB::eval_result;
	}
    }
}


unless (caller) {
}
scalar "Just one part of the larger Devel::Trepan::CmdProcessor";
