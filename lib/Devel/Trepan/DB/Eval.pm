# Eval part of Perl's Core DB.pm library and perl5db.pl with modification.

package DB;
use warnings; use strict;
use English qw( -no_match_vars );
use vars qw($eval_result @eval_result %eval_result $fix_file_and_line
            $eval_str $eval_opts $event $return_type );

# This is the flag that says "a debugger is running, please call
# DB::DB and DB::sub". We will turn it on forcibly before we try to
# execute anything in the user's context, because we always want to
# get control back.
use constant db_stop => 1 << 30;

BEGIN {
    # When we want to evaluate a string in the context of the running
    # program we use these:
    $eval_str = '';             # The string to eval
    $eval_opts = {};            # Options controlling how we want the
                                # eval to take place
    $DB::eval_result = undef;   # Place for result if scalar;
    @DB::eval_result = ();      # place for result if array
    %DB::eval_result = ();      # place for result if hash.
    $DB::fix_file_and_line = 1; # Should we fix __FILE__ and __LINE__ ? 
                                # This value is reset after each eval.
                                 
}    

#
# evaluate $eval_str in the context of $user_context (a package name).
# @saved contains an ordered list of saved global variables.
#    
sub eval {
    my ($user_context, $eval_str, @saved) = @_;
    no strict;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;

    # 'my' would make it visible from user code
    #    but so does local! --tchrist
    # Remember: this localizes @DB::res, not @main::res.
    local @res;
    {
        # Try to keep the user code from messing  with us. Save these so that
        # even if the eval'ed code changes them, we can put them back again.
        # Needed because the user could refer directly to the debugger's
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        local $otrace  = $DB::trace;
        local $osingle = $DB::single;
        local $od      = $DEBUGGING;

        # Make sure __FILE__ and __LINE__ are set correctly
        my $eval_setup = $user_context;
        my $position_str = "\n# line $DB::lineno \"$DB::filename\"\n";
        $eval_setup .= $position_str if $DB::fix_file_and_line;

        @res = eval "$eval_setup $eval_str;\n&DB::save\n"; # '\n' for nice recursive debug
        _warnall($@) if $@;

        # Restore those old values.
        $DB::trace  = $otrace;
        $DB::single = $osingle;
        $DB::fix_file_and_line = 1;
        $DEBUGGING  = $od;
    }
}


# evaluate global $eval_str in the context of $user_context (a package name).
# @saved contains an ordered list of saved global variables.
# global $eval_opts->{return_type} indicates the return context.
## FIXME: pass $return_type rather than use global $eval_opts;
sub eval_with_return {
    my ($user_context, $eval_str, $return_type, @saved) = @_;
    no strict;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;

    {
        # Try to keep the user code from messing with us. Save these so that
        # even if the eval'ed code changes them, we can put them back again.
        # Needed because the user could refer directly to the debugger's
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        local $otrace  = $DB::trace;
        local $osingle = $DB::single;
        local $od      = $DEBUGGING;

        # Make sure __FILE__ and __LINE__ are set correctly
        my $eval_setup = $user_context;
        my $position_str = "\n# line $DB::lineno \"$DB::filename\"\n";
        $eval_setup .= $position_str if $DB::fix_file_and_line;

        if ('$' eq $return_type) {
            eval "$eval_setup \$DB::eval_result=$eval_str\n";
        } elsif ('@' eq $return_type) {
            eval "$eval_setup \@DB::eval_result=$eval_str\n";
        } elsif ('%' eq $return_type) {
            eval "$eval_setup \%DB::eval_result=$eval_str\n";
        } else {
            $eval_result = eval "$eval_setup $eval_str";
        }
        
        # Restore those old values.
        $DB::trace  = $otrace;
        $DB::single = $osingle;
        $DB::fix_file_and_line = 1;
        $DEBUGGING  = $od;

        my $EVAL_ERROR_SAVE = $EVAL_ERROR;
        if ($EVAL_ERROR_SAVE) {
            _warnall($EVAL_ERROR_SAVE);
            $eval_str = '';
            return undef;
        } else {
            if ('$' eq $return_type) {
                return $eval_result;
            } elsif ('@' eq $return_type) {
                return @eval_result;
            } elsif ('%' eq $return_type) {
                return %eval_result;
            }  else {
                return $eval_result;
            }
        }
    }
}
1;
