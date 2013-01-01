# -*- coding: utf-8 -*-                                                         
# Copyright (C) 2012-2013 Rocky Bernstein <rocky@cpan.org>                           
use warnings;
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
use Devel::Trepan::Util qw(hash_merge uniq_abbrev);
use PadWalker qw(peek_my peek_our);
use strict;

# Note DB::Eval uses and sets its own variables.

use vars qw($HAVE_EVAL_WITH_LEXICALS);                                          
BEGIN {                                                                         
    $HAVE_EVAL_WITH_LEXICALS = eval("use Eval::WithLexicals; 1") ? 1 : 0;     
}  

my $given_eval_warning = 0;

sub eval($$$$$) {
    my ($self, $code_to_eval, $opts, $correction) = @_;
    no warnings 'once';
    my $return_type = $opts->{return_type};
    if (0 == $self->{frame_index} || !$HAVE_EVAL_WITH_LEXICALS) {
        unless (0 == $self->{frame_index}) {
            $self->msg("Evaluation occurs in top-most frame not this one");
        }
        $DB::eval_str = $self->{dbgr}->evalcode($code_to_eval);
        $DB::eval_opts = $opts;
        $DB::result_opts = $opts;

        ## This doesn't work because it doesn't pick up "my" variables
        # DB::eval_with_return($code_to_eval, $opts, @DB::saved);
        # $self->process_after_eval();
        
        # All the way back to DB seems to work here.
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
    }
    if ('@' eq $return_type) {
        return @DB::eval_result;
    } else {
        return $DB::eval_result;
    }
}

# FIXME: have a way to customize Data::Dumper, PerlTidy etc.
require Data::Dumper;
# FIXME: remove this when converted to OO forms of Data::Dumper
$Data::Dumper::Terse = 1; 

my $last_eval_value = 0;

sub handle_eval_result($) {
    my ($self) = @_;
    my $val_str;
    my $prefix="\$DB::D[$last_eval_value] =";
    
    # Perltidy::Dumper uses Tidy which looks at @ARGV for filenames.
    # Having a non-empty @ARGV will cause Tidy to croak.
    local @ARGV=();

    my $fn;
    my $print_properties = {};
    my $evdisp = $self->{settings}{displayeval};

    # FIXME: switch over entirely to the OO way of using Data::Dumper
    # than set this global.
    my $old_terse = $Data::Dumper::Terse;
    $Data::Dumper::Terse = 1; 


    # FIXME: this is way ugly. We could probably use closures 
    # (anonymous subroutines) to combine this and the if code below
    if ('tidy' eq $evdisp) {
        $fn = \&Data::Dumper::Perltidy::Dumper;
    } elsif ('dprint' eq $evdisp) {
        $print_properties = {
            colored => $self->{settings}{highlight},
        };
        $fn = \&Data::Printer::p;
    } else {
        $fn = \&Data::Dumper::Dumper;
    }
    my $return_type = $DB::eval_opts->{return_type};
    $return_type = '' unless defined $return_type;
    if ('$' eq $return_type) {
            if (defined $DB::eval_result) {
                $DB::D[$last_eval_value++] = $DB::eval_result;
                if ('dprint' eq $evdisp) {
                    $val_str = 
                        $fn->(\$DB::eval_result, %$print_properties);
                } else {
                    $val_str = $fn->($DB::eval_result);
                }
                chomp $val_str;
            } else {
                $DB::eval_result = '<undef>' ;
            }
            $self->msg("$prefix $DB::eval_result");
    } elsif ('@' eq $return_type) {
            if (@DB::eval_result) {
                $val_str = $fn->(\@DB::eval_result, %$print_properties);
                chomp $val_str;
                @{$DB::D[$last_eval_value++]} = @DB::eval_result;
            } else {
                $val_str = '<undef>'
            }
            $self->msg("$prefix\n\@\{$val_str}");
    } elsif ('%' eq $return_type) {
            if (%DB::eval_result) {
                if ('dumper' eq $evdisp) {
                    my $d = Data::Dumper->new([\%DB::eval_result]);
                    $d->Terse(1)->Sortkeys(1);
                    $val_str = $d->Dump()
                } elsif ('dprint' eq $evdisp) {
                    $val_str = $fn->(\%DB::eval_result, %$print_properties);
                } else {
                    $val_str = $fn->(\%DB::eval_result);
                }
                chomp $val_str;
                @{$DB::D[$last_eval_value++]} = %DB::eval_result;
            } else {
                $val_str = '<undef>'
            }
            $self->msg("$prefix\n\@\{$val_str}");
    } elsif ('>' eq $return_type || '2>' eq $return_type ) {
        $self->msg($DB::eval_result);
    }  else {
            if (defined $DB::eval_result) {
                if ('dprint' eq $evdisp) {
                    $val_str = $DB::D[$last_eval_value++] = 
                        $fn->(\$DB::eval_result, %$print_properties);
                } else {
                    $val_str = $DB::D[$last_eval_value++] = 
                        $fn->($DB::eval_result);
                }
                chomp $val_str;
            } else {
                $val_str = '<undef>'
            }
            $self->msg("$prefix ${val_str}");
    }
    
    if (defined($self->{set_wp})) {
            $self->{set_wp}->old_value($DB::eval_result);
            $self->{set_wp} = undef;
    }
    
    $DB::eval_opts = {
            return_type => '',
    };
    $DB::eval_result = undef;
    @DB::eval_result = undef;

    $Data::Dumper::Terse = $old_terse; 

}

unless (caller) {
}
scalar "Just one part of the larger Devel::Trepan::CmdProcessor";
