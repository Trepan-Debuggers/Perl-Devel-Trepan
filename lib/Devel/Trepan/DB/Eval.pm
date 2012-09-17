# Eval part of Perl's Core DB.pm library and perl5db.pl with modification.

package DB;
use warnings; use strict;
use English qw( -no_match_vars );

# FIXME: remove these
use vars qw($eval_result @eval_result);

# This is the flag that says "a debugger is running, please call
# DB::DB and DB::sub". We will turn it on forcibly before we try to
# execute anything in the user's context, because we always want to
# get control back.
use constant db_stop => 1 << 30;

BEGIN {
    # When we want to evaluate a string in the context of the running
    # program we use these:
    $DB::eval_result = undef;   # Place for result if scalar;
    @DB::eval_result = ();      # place for result if array
    %DB::eval_result = ();      # place for result if hash
}    

# evaluate $eval_str in the context of $package_namespace (a package name).
# @saved contains an ordered list of saved global variables.
# $return_type indicates the return context: 
#  @ for array context, 
#  $ for scalar context,
#  % save result in a hash variable
#  
sub eval_with_return {
    my ($eval_str, $opts, @saved) = @_;
    no strict;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;

    {
        no warnings 'once';
        # Try to keep the user code from messing with us. Save these so that
        # even if the eval'ed code changes them, we can put them back again.
        # Needed because the user could refer directly to the debugger's
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        local $otrace  = $DB::trace;
        local $osingle = $DB::single;
        local $od      = $DEBUGGING;

        # Set package namespace for running eval's in the namespace
        # of the debugged program.
        my $eval_setup = $opts->{namespace_package} || $DB::namespace_package;
        $eval_setup   .= "\n\@_ = \@DB::_;";

        # Make sure __FILE__ and __LINE__ are set correctly
        if( $opts->{fix_file_and_line}) {
            my $position_str = "\n# line $DB::lineno \"$DB::filename\"\n";
            $eval_setup .= $position_str ;
        }

        my $return_type = $opts->{return_type};
        if ('$' eq $return_type) {
            eval "$eval_setup \$DB::eval_result=$eval_str\n";
        } elsif ('@' eq $return_type) {
            eval "$eval_setup \@DB::eval_result=$eval_str\n";
        } elsif ('%' eq $return_type) {
            eval "$eval_setup \%DB::eval_result=$eval_str\n";
        # } elsif ('>' eq $return_type) {
        #     ($eval_result, $stderr, @result) = capture {
        #       eval "$eval_setup $eval_str\n";
        #     };
        # } elsif ('2>&1' eq $return_type) {
        #     $eval_result = capture_merged {
        #       eval "$eval_setup $eval_str\n";
        } else {
            $eval_result = eval "$eval_setup $eval_str\n";
        };
        
        # Restore those old values.
        $DB::trace  = $otrace;
        $DB::single = $osingle;
        $DEBUGGING  = $od;

        my $msg = $EVAL_ERROR;
        if ($msg) {
            chomp $msg;
            if ($opts->{hide_position}) {
                $msg =~ s/ at .* line \d+[.,]//;
                $msg =~ s/ line \d+,//;
                $msg =~ s/ at EOF$/ at end of string/;
            }
            _warnall($msg);
            $eval_str = '';
            return undef;
        } else {
            if ('@' eq $return_type) {
                return @eval_result;
            }  else {
                return $eval_result;
            }
        }
    }
}

# Evaluate the argument and return 0 if there's no error.
# If there is an error we return the error message.
sub eval_not_ok ($) 
{
    my $code = shift;
    my $wrapped = "$DB::namespace_package; sub { $code }";
    no strict;
    eval $wrapped;
    if ($@) {
        my $msg = $@;
        $msg =~ s/ at .* line \d+[.,]//g;
        $msg =~ s/ at EOF$/ at end of string/;
        return $msg;
    } else {
        return 0;
    }
}

unless (caller) {
    eval {
        sub doit($) {
            my $code = shift;
            my $msg = eval_not_ok($code);
            print "code: $code\n";
            if ($msg) {
                print "$msg";
            } else {
                print "code ok\n";
            }
        }
    };

    $DB::namespace_package = 'package DB;';
    doit  'doit(1,2,3)';
    doit "1+";
    doit '$x+2';
    doit "foo(";
    doit  '$foo =';
    doit  'BEGIN  { $x = 1; ';
    doit  'package foo; 1';

}

# doit  '$x = 1; __END__ $y=';


1;
