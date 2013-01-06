package DB;
use warnings; no warnings 'redefine';
use English qw( -no_match_vars );

=pod

=head2 backtrace(skip[,count,scan_for_DB])

Collect the traceback information available via C<caller()>.  Some
filtering and cleanup of the data is done.

C<skip> defines the number of stack frames to be skipped, working
backwards from the most current frame before the call the debugger
DB::DB call if scan_for_DB is set, or the most-current frame.

C<count> determines the total number of call frames to be returned; all of
them (well, the first 10^9) are returned if C<count> is omitted.

This routine returns a list of hashes, from most-recent to least-recent
stack frame. Each has the following keys and values:
    
=over 4

=item * 

C<wantarray> - C<.> (null), C<$> (scalar), or C<@> (array)

=item * 

C<fn>   - subroutine name, or C<eval> information

=item * 

C<args> - undef, or a reference to an array of arguments

=item * 

C<file> - the file in which this item was defined (if any)

=item * 

C<line> - the line on which it was defined

=item * 

C<evaltext> - eval text if we are in an eval.

=back

=cut

# NOTE: this routine needs to be in package DB for us to be able to pick up the
# subroutine args.
sub backtrace($;$$$) {
    my ($self, $skip, $count, $scan_for_DB_sub) = @_;
    $skip = 0 unless defined($skip);  
    $count = 1e9 unless defined($count);

    $scan_for_DB_sub ||= 1;
    # print "scan: $scan_for_DB_sub\n";

    # These variables are used to capture output from caller();
    my ( $pkg, $file, $line, $fn, $hasargs, $wantarray, $evaltext, $is_require );

    my $i=0;
    if ($scan_for_DB_sub) {
        my $db_fn = ($event eq 'post-mortem') ? 'catch' : 'DB'; 
        while (my ($pkg, $file, $line, $fn) = caller($i++)) {
            if ("DB::$db_fn" eq $fn or ('DB' eq $pkg && $db_fn eq $fn)) {
                $i--;
                last ;
            }
        }
    }

    # print "++count: $count, i $iline\n";
    $count += $i;

    my ( @a, $args_ary );
    my @callstack = ();

    # # XXX Okay... why'd we do that?
    my $nothard = not $DB::frame & 8;
    local $DB::frame = 0;

    # Start out at the skip count, $i.
    # If we haven't reached the number of frames requested, and caller() is
    # still returning something, stay in the loop. (If we pass the requested
    # number of stack frames, or we run out - caller() returns nothing - we
    # quit.
    # Up the stack frame index to go back one more level each time.
    while ($i <= $count and 
           ($pkg, $file, $line, $fn, $hasargs, $wantarray, $evaltext, $is_require) = caller($i)) {
        next if $pkg eq 'DB' && 'fn' eq 'sub';
        # print "++file: $file, line $line $fn\n";
        $i++;
        # Go through the arguments and save them for later.
        @a = ();
        for my $arg (@DB::args) {
            my $type;
            if ( not defined $arg ) {    # undefined parameter
                push @a, "undef";
            }
            
            elsif ( $nothard and tied $arg ) {    # tied parameter
                push @a, "tied";
            }
            elsif ( $nothard and $type = ref $arg ) {    # reference
                push @a, "ref($type)";
            }
            else {                                       # can be stringified
                local $_ =
                    "$arg";    # Safe to stringify now - should not call f().
                
                # Backslash any single-quotes or backslashes.
                s/([\'\\])/\\$1/g;
                
                # Single-quote it unless it's a number or a colon-separated
                # name.
                s/(.*)/'$1'/s
                    unless /^(?: -?[\d.]+ | \*[\w:]* )$/x;
                
                # Turn high-bit characters into meta-whatever.
                s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
                
                # Turn control characters into ^-whatever.
                s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
                
                push( @a, $_ );
            } ## end else [ if (not defined $arg)
        } ## end for $arg (@args)
        
        # If $wantarray is true, this is array (@)context.
        # If $wantarray is false, this is scalar ($) context.
        # If neither, $wantarray isn't defined. (This is apparently a 'can't
        # happen' trap.)
        $wantarray = $wantarray ? '@' : ( defined $wantarray ? "\$" : '.' );
        
        # if the sub has args ($hasargs true), make an anonymous array of the
        # dumped args.
        $args_ary = $hasargs ? [@a] : undef;
        
        # remove trailing newline-whitespace-semicolon-end of line sequence
        # from the eval text, if any.
        $evaltext =~ s/\n\s*\;\s*\Z// if $evaltext;
        
        # Escape backslashed single-quotes again if necessary.
        $evaltext =~ s/([\\\'])/\\$1/g if $evaltext;
        
        # if the require flag is true, the eval text is from a require.
        if ($is_require) {
            $fn = "require '$evaltext'";
        }
        
        # if it's false, the eval text is really from an eval.
        elsif ( defined $is_require ) {
            $fn = "eval '$evaltext'";
        }
        
        # If the sub is '(eval)', this is a block eval, meaning we don't
        # know what the eval'ed text actually was.
        elsif ( $fn eq '(eval)' ) {
            $fn = "eval {...}";
        }
        
        # Stick the collected information into @callstack a hash reference.
        push(@callstack,
             {
                 args      => $args_ary,
                 evaltext  => $evaltext,
                 file      => $file,
                 fn        => $fn,
                 line      => $line,
                 pkg       => $pkg,
                 wantarray => $wantarray,
             }
            );
        
        # Stop processing frames if the user hit control-C.
        # last if $signal;
    } ## end for ($i = $skip ; $i < ...

    # The function and args for the stopped line is DB:DB, 
    # but we want it to be the function and args of the last call.
    # And the function and args for the file and line that called us
    # should also be the prior function and args.
    if ($scan_for_DB_sub) {
        for (my $i=1; $i <= $#callstack; $i++) {
            $callstack[$i-1]->{args} = $callstack[$i]->{args};
            $callstack[$i-1]->{fn} = $callstack[$i]->{fn};
        }
        $callstack[$i]{args} = undef;
        $callstack[$i]{fn}   = undef;
    }

    @callstack;
}

unless (caller) {
    require Data::Dumper;
    import Data::Dumper;
    $DB::frame = 0;
    our @callstack = backtrace(undef,undef,undef,0);
    our $sep = '-' x 20 . "\n";
    # print Dumper(@callstack), "\n";
    # print $sep;
    sub five {
        @callstack = backtrace(undef,undef,undef,0);
        print Dumper(@callstack), "\n";
        print $sep;
        @callstack = backtrace(undef,1,undef,0);
        print Dumper(@callstack), "\n";
        print $sep;
        @callstack = backtrace(1,0,undef,0);
        print Dumper(@callstack), "\n";
        print $sep;
        5;
    }
    my $five = five();
    # $five = eval "@callstack = backtrace(undef, undef, undef, 0)";
    # print Dumper(@callstack), "\n";
    print $sep;
    $five = eval "five";
    print Dumper(@callstack), "\n";
}

1;
