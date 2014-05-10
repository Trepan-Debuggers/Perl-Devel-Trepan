# Copied from perl5db.pl
# FIXME: Not hooked in yet.

package Devel::Trepan::DB::Sig;

=head1 DIE AND WARN MANAGEMENT

=head2 C<diesignal>

C<diesignal> is a just-drop-dead C<die> handler. It's most useful when trying
to debug a debugger problem.

It does its best to report the error that occurred, and then forces the
program, debugger, and everything to die.

=cut

sub diesignal {

    # No entry/exit messages.
    local $frame = 0;

    # No return value prints.
    local $doret = -2;

    # set the abort signal handling to the default (just terminate).
    $SIG{'ABRT'} = 'DEFAULT';

    # If we enter the signal handler recursively, kill myself with an
    # abort signal (so we just terminate).
    kill 'ABRT', $$ if $panic++;

    # If we can show detailed info, do so.
    if ( defined &Carp::longmess ) {

        # Don't recursively enter the warn handler, since we're carping.
        local $SIG{__WARN__} = '';

        # Skip two levels before reporting traceback: we're skipping
        # mydie and confess.
        local $Carp::CarpLevel = 2;    # mydie + confess

        # Tell us all about it.
        &warn( Carp::longmess("Signal @_") );
    }

    # No Carp. Tell us about the signal as best we can.
    else {
        local $\ = '';
        print $DB::OUT "Got signal @_\n";
    }

    # Drop dead.
    kill 'ABRT', $$;
} ## end sub diesignal

=head2 C<dbwarn>

The debugger's own default C<$SIG{__WARN__}> handler. We load C<Carp> to
be able to get a stack trace, and output the warning message vi C<DB::dbwarn()>.

=cut

sub dbwarn {

    # No entry/exit trace.
    local $frame = 0;

    # No return value printing.
    local $doret = -2;

    # Turn off warn and die handling to prevent recursive entries to this
    # routine.
    local $SIG{__WARN__} = '';
    local $SIG{__DIE__}  = '';

    # Load Carp if we can. If $^S is false (current thing being compiled isn't
    # done yet), we may not be able to do a require.
    eval { require Carp }
      if defined $^S;    # If error/warning during compilation,
                         # require may be broken.

    # Use the core warn() unless Carp loaded OK.
    CORE::warn( @_,
        "\nCannot print stack trace, load with -MCarp option to see stack" ),
      return
      unless defined &Carp::longmess;

    # Save the current values of $single and $trace, and then turn them off.
    my ( $mysingle, $mytrace ) = ( $single, $trace );
    $single = 0;
    $trace  = 0;

    # We can call Carp::longmess without its being "debugged" (which we
    # don't want - we just want to use it!). Capture this for later.
    my $mess = Carp::longmess(@_);

    # Restore $single and $trace to their original values.
    ( $single, $trace ) = ( $mysingle, $mytrace );

    # Use the debugger's own special way of printing warnings to print
    # the stack trace message.
    &warn($mess);
} ## end sub dbwarn

=head2 C<dbdie>

The debugger's own C<$SIG{__DIE__}> handler. Handles providing a stack trace
by loading C<Carp> and calling C<Carp::longmess()> to get it. We turn off
single stepping and tracing during the call to C<Carp::longmess> to avoid
debugging it - we just want to use it.

If C<dieLevel> is zero, we let the program being debugged handle the
exceptions. If it's 1, you get backtraces for any exception. If it's 2,
the debugger takes over all exception handling, printing a backtrace and
displaying the exception via its C<dbwarn()> routine.

=cut

sub dbdie {
    local $frame         = 0;
    local $doret         = -2;
    local $SIG{__DIE__}  = '';
    local $SIG{__WARN__} = '';
    my $i      = 0;
    my $ineval = 0;
    my $sub;
    if ( $dieLevel > 2 ) {
        local $SIG{__WARN__} = \&dbwarn;
        &warn(@_);    # Yell no matter what
        return;
    }
    if ( $dieLevel < 2 ) {
        die @_ if $^S;    # in eval propagate
    }

    # The code used to check $^S to see if compilation of the current thing
    # hadn't finished. We don't do it anymore, figuring eval is pretty stable.
    eval { require Carp };

    die( @_,
        "\nCannot print stack trace, load with -MCarp option to see stack" )
      unless defined &Carp::longmess;

    # We do not want to debug this chunk (automatic disabling works
    # inside DB::DB, but not in Carp). Save $single and $trace, turn them off,
    # get the stack trace from Carp::longmess (if possible), restore $signal
    # and $trace, and then die with the stack trace.
    my ( $mysingle, $mytrace ) = ( $single, $trace );
    $single = 0;
    $trace  = 0;
    my $mess = "@_";
    {

        package # hide me from PAUSE
	    Carp;    # Do not include us in the list
        eval { $mess = Carp::longmess(@_); };
    }
    ( $single, $trace ) = ( $mysingle, $mytrace );
    die $mess;
} ## end sub dbdie

=head2 C<warnlevel()>

Set the C<$DB::warnLevel> variable that stores the value of the
C<warnLevel> option. Calling C<warnLevel()> with a positive value
results in the debugger taking over all warning handlers. Setting
C<warnLevel> to zero leaves any warning handlers set up by the program
being debugged in place.

=cut

sub warnLevel {
    if (@_) {
        $prevwarn = $SIG{__WARN__} unless $warnLevel;
        $warnLevel = shift;
        if ($warnLevel) {
            $SIG{__WARN__} = \&DB::dbwarn;
        }
        elsif ($prevwarn) {
            $SIG{__WARN__} = $prevwarn;
        } else {
            undef $SIG{__WARN__};
        }
    } ## end if (@_)
    $warnLevel;
} ## end sub warnLevel

=head2 C<dielevel>

Similar to C<warnLevel>. Non-zero values for C<dieLevel> result in the
C<DB::dbdie()> function overriding any other C<die()> handler. Setting it to
zero lets you use your own C<die()> handler.

=cut

sub dieLevel {
    local $\ = '';
    if (@_) {
        $prevdie = $SIG{__DIE__} unless $dieLevel;
        $dieLevel = shift;
        if ($dieLevel) {

            # Always set it to dbdie() for non-zero values.
            $SIG{__DIE__} = \&DB::dbdie;    # if $dieLevel < 2;

            # No longer exists, so don't try  to use it.
            #$SIG{__DIE__} = \&DB::diehard if $dieLevel >= 2;

            # If we've finished initialization, mention that stack dumps
            # are enabled, If dieLevel is 1, we won't stack dump if we die
            # in an eval().
            print $OUT "Stack dump during die enabled",
              ( $dieLevel == 1 ? " outside of evals" : "" ), ".\n"
              if $I_m_init;

            # XXX This is probably obsolete, given that diehard() is gone.
            print $OUT "Dump printed too.\n" if $dieLevel > 2;
        } ## end if ($dieLevel)

        # Put the old one back if there was one.
        elsif ($prevdie) {
            $SIG{__DIE__} = $prevdie;
            print $OUT "Default die handler restored.\n";
        } else {
            undef $SIG{__DIE__};
            print $OUT "Die handler removed.\n";
        }
    } ## end if (@_)
    $dieLevel;
} ## end sub dieLevel

=head2 C<signalLevel>

Number three in a series: set C<signalLevel> to zero to keep your own
signal handler for C<SIGSEGV> and/or C<SIGBUS>. Otherwise, the debugger
takes over and handles them with C<DB::diesignal()>.

=cut

sub signalLevel {
    if (@_) {
        $prevsegv = $SIG{SEGV} unless $signalLevel;
        $prevbus  = $SIG{BUS}  unless $signalLevel;
        $signalLevel = shift;
        if ($signalLevel) {
            $SIG{SEGV} = \&DB::diesignal;
            $SIG{BUS}  = \&DB::diesignal;
        }
        else {
            $SIG{SEGV} = $prevsegv;
            $SIG{BUS}  = $prevbus;
        }
    } ## end if (@_)
    $signalLevel;
} ## end sub signalLevel

1;
