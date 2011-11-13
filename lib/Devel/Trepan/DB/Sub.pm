# Derived from perl5db.pl
# Tracks calls and returns and stores some stack frame
# information.
package DB;
use warnings; no warnings 'redefine';
no warnings 'once';
use English qw( -no_match_vars );

use constant SINGLE_STEPPING_EVENT =>  1;
use constant DEEP_RECURSION_EVENT  =>  4;
use constant RETURN_EVENT          => 32;

use vars qw($return_value @return_value @stack);

my ($deep);

BEGIN {
    @DB::ret = ();    # return value of last sub executed in list context
    $DB::ret = '';    # return value of last sub executed in scalar context
    $DB::return_type = 'undef';
    $deep = 70;      # Max stack depth before we complain.

    # $stack_depth is to track the current stack depth using the
    # auto-stacked-variable trick. It is 'local'ized repeatedly as
    # a simple way to keep track of #stack.
    $stack_depth = 0;
    @stack = (0);     # Per-frame debugger flags
}

####
# entry point for all subroutine calls
#
sub sub {
    # Do not use a regex in this subroutine -> results in corrupted
    # memory See: [perl #66110]

    # lock ourselves under threads
    lock($DBGR);

    # Whether or not the autoloader was running, a scalar to put the
    # sub's return value in (if needed), and an array to put the sub's
    # return value in (if needed).
    my ( $al, $ret, @ret ) = "";
    if ($sub eq 'threads::new' && $ENV{PERL5DB_THREADED}) {
	print "creating new thread\n"; 
    }
    
    # If the last ten characters are '::AUTOLOAD', note we've traced
    # into AUTOLOAD for $sub.
    if ( length($sub) > 10 && substr( $sub, -10, 10 ) eq '::AUTOLOAD' ) {
        $al = " for $$sub" if defined $$sub;
    }
    
    # We stack the stack pointer and then increment it to protect us
    # from a situation that might unwind a whole bunch of call frames
    # at once. Localizing the stack pointer means that it will automatically
    # unwind the same amount when multiple stack frames are unwound.
    local $stack_depth = $stack_depth + 1;    # Protect from non-local exits

    # Expand @stack.
    $#stack = $stack_depth;

    # Save current single-step setting.
    $stack[-1] = $single;

    # printf "\$DB::single for $sub: 0%x\n", $DB::single if $DB::single;
    # Turn off all flags except single-stepping or return event.
    $DB::single &= SINGLE_STEPPING_EVENT;

    # If we've gotten really deeply recursed, turn on the flag that will
    # make us stop with the 'deep recursion' message.
    $DB::single |= DEEP_RECURSION_EVENT if $#stack == $deep;

    if ($DB::sub eq 'DESTROY' or
	substr($DB::sub, -9) eq '::DESTROY' or not defined wantarray) {
	&$DB::sub;
	$DB::single |= pop(@stack);
	$DB::ret = undef;
    }
    elsif (wantarray) {
        # Called in array context. call sub and capture output.
        # DB::DB will recursively get control again if appropriate; we'll come
        # back here when the sub is finished.
	@ret = &$sub;

        # Pop the single-step value back off the stack.
        $single |= $stack[ $stack_depth-- ];
	if ($single & RETURN_EVENT) {
	    $DB::return_type = 'array';
	    @DB::return_value = @ret;
	    DB::DB() ;
	    return @DB::return_value;
	}
	@ret;
    }
    else {
	if ( defined wantarray ) {
	    # Save the value if it's wanted at all.
	    $ret = &$sub;
	}
	else {
	    # Void return, explicitly.
	    &$sub;
	    undef $ret;
	}

        # Pop the single-step value back off the stack.
        $single |= $stack[ $stack_depth-- ];
	if ($single & RETURN_EVENT) {
	    $DB::return_type = defined $ret ? 'scalar' : 'undef';
	    $DB::return_value = $ret;
	    DB::DB() ;
	    return $DB::return_value;
	}

        # Return the appropriate scalar value.
	$ret;
    }
}

sub lsub : lvalue {

    # lock ourselves under threads
    lock($DBGR);
    
    # Whether or not the autoloader was running, a scalar to put the
    # sub's return value in (if needed), and an array to put the sub's
    # return value in (if needed).
    my ( $al, $ret, @ret ) = "";
    if ($sub =~ /^threads::new$/ && $ENV{PERL5DB_THREADED}) {
	print "creating new thread\n";
    }
    
    # If the last ten characters are C'::AUTOLOAD', note we've traced
    # into AUTOLOAD for $sub.
    if ( length($sub) > 10 && substr( $sub, -10, 10 ) eq '::AUTOLOAD' ) {
        $al = " for $$sub";
    }
    
    # We stack the stack pointer and then increment it to protect us
    # from a situation that might unwind a whole bunch of call frames
    # at once. Localizing the stack pointer means that it will automatically
    # unwind the same amount when multiple stack frames are unwound.
    local $stack_depth = $stack_depth + 1;    # Protect from non-local exits
    
    # Expand @stack.
    $#stack = $stack_depth;
    
    # Save current single-step setting.
    $stack[-1] = $single;
    
    # Turn off all flags except single-stepping.
    $single &= SINGLE_STEPPING_EVENT;
    
    # If we've gotten really deeply recursed, turn on the flag that will
    # make us stop with the 'deep recursion' message.
    $single |= DEEP_RECURSION_EVENT if $stack_depth == $deep;
    
    # Pop the single-step value back off the stack.
    $single |= $stack[ $stack_depth-- ];
    
    # call the original lvalue sub.
    &$sub;
}

####
# without args: returns all defined subroutine names
# with subname args: returns a listref [file, start, end]
#
sub subs {
  my $s = shift;
  if (@_) {
    my(@ret) = ();
    while (@_) {
      my $name = shift;
      push @ret, [$DB::sub{$name} =~ /^(.*)\:(\d+)-(\d+)$/] 
	if exists $DB::sub{$name};
    }
    return @ret;
  }
  return keys %DB::sub;
}

1;
