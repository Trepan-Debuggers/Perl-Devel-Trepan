# Eval part of Perl's Core DB.pm library and perl5db.pl with modification.

package DB;
use warnings; use strict;
use English qw( -no_match_vars );
use feature 'switch';
use vars qw($eval_result @eval_result %eval_result
            $eval_str $eval_opts $event $return_type );

BEGIN {
    # When we want to evaluate a string in the context of the running
    # program we use these:
    $eval_str = '';             # The string to eval
    $eval_opts = {};            # Options controlling how we want the
				# eval to take place
    $DB::eval_result = undef;   # Place for result if scalar;
    @DB::eval_result = ();      # place for result if array
    %DB::eval_result = ();      # place for result if hash.
}    

#
# evaluate $eval_str in the context of $user_context (a package name).
# @saved contains an ordered list of saved global variables.
#    
sub eval {
    my ($user_context, $eval_str, @saved) = @_;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;
    no strict; no warnings;
    eval "$user_context $eval_str; &DB::save\n"; # '\n' for nice recursive debug
    _warnall($@) if $@;
}


# evaluate global $eval_str in the context of $user_context (a package name).
# @saved contains an ordered list of saved global variables.
# global $eval_opts->{return_type} indicates the return context.
sub eval_with_return {
    ## FIXME: $eval_opts should be a parameter rather than a global.
    my ($user_context, $eval_str, @saved) = @_;
    no strict;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;
    use strict;
    given ($eval_opts->{return_type}) {
	when ('$') {
	    eval "$user_context \$DB::eval_result=$eval_str";
	    $eval_result = eval "$user_context $eval_str";
	}
	when ('@') {
	    eval "$user_context \@DB::eval_result=$eval_str\n";
	}
	when ('%') {
	    eval "$user_context \%DB::eval_result=$eval_str\n";
	} 
	default {
	    $eval_result = eval "$user_context $eval_str\n";
	}
    }

    my $EVAL_ERROR_SAVE = $EVAL_ERROR;
    eval "$user_context &DB::save\n"; # '\n' for nice recursive debug
    if ($EVAL_ERROR_SAVE) {
	_warnall($EVAL_ERROR_SAVE);
	$eval_str = '';
	return undef;
    } else {
	given ($eval_opts->{return_type}) {
	    when ('$') {
		return $eval_result;
	    }
	    when ('$') {
		return @eval_result;
	    }
	    when ('%') {
		return %eval_result;
	    } 
	    default {
		return $eval_result;
	    }
	}
    }
}

1;
