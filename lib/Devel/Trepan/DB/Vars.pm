package DB;

# Documentation is after __END__

use vars qw(
            $OP_addr
            $OS_STARTUP_DIR
            $caller
            $eval_opts
            $eval_str
            $event
            $fall_off_on_end
            $init_dollar0
            $ready $tid
            $ret
            $running
            $stop
            $bt_truncated
            %HAVE_MODULE
            @clients
            @ret
            @saved);

use Cwd;
BEGIN {
    no warnings 'once';
    # these are hardcoded in perl source (some are magical)

    $DB::sub      = '';    # name of current subroutine
    $DB::single   = 0;     # single-step flags. See constants at the
                           # top of DB/Sub.pm
    $DB::signal   = 0;     # signal flag (will cause a stop at the next line)
    $DB::stop     = 0;     # value of last breakpoint condition evaluation

    @DB::dbline   = ();    # list of lines in currently loaded file
    %DB::dbline   = ();    # actions in current file (keyed by line number)

    # other "public" globals

    @ini_INC        = @INC; # Save the contents of @INC before they are
                            # modified elsewhere.
    @ini_ARGV       = @ARGV;
    $ini_dollar0    = $0;
    $OS_STARTUP_DIR = getcwd;

    @DB::args     = ();    # arguments of current subroutine or @ARGV array
    $DB::fall_off_on_end = 0;
    @DB::clients  = ();
    $eval_opts    = {};    # Options controlling how the client wants the
                           # eval to take place
    $DB::tid      = undef; # Thread id

    $DB::eval_str = '';    # Client wants to eval this string

    $DB::package  = '';    # current package space
    $DB::filename = '';    # current filename
    $DB::subname  = '';    # currently executing sub (fully qualified name)

    # This variable records how many levels we're nested in debugging. Used
    # Used in the debugger prompt, and in determining whether it's all over or
    # not.
    $DB::level         =  0;     # Level of nested debugging

    $DB::bitmask       = '';
    $DB::caller        = [];
    $DB::evaltext      = '';
    $DB::hasargs       = '';
    $DB::hinthash      = '';
    $DB::hints         = '';
    $DB::is_require    = '';
    $DB::lineno        = '';     # current line number
    $DB::subroutine    = '';
    $DB::wantarray     = '';

    $DB::event         = undef;  # The reason we have entered the debugger

    $DB::VERSION = '1.05';

    # initialize private globals to avoid warnings

    $DB::running = 1;         # are we running, or are we stopped?
}

1;

__END__

=head2 Global Variables

The following "public" global names can be read by clients of this API.
Beware that these should be considered "readonly".

=over 8

=item  $DB::sub

Name of current executing subroutine.

=item  %DB::sub

The keys of this hash are the names of all the known subroutines.
Each value is an encoded string that has the sprintf(3) format
C<("%s:%d-%d", filename, fromline, toline)>.

This hash is maintained by Perl.  I<filename> has the form (eval 34) for
subroutines defined inside evals.

=item  $DB::single

Single-step flag.  Will be true if the API will stop at the next statement.

=item  $DB::signal

Signal flag. Will be set to a true value if a signal was caught.  Clients may
check for this flag to abort time-consuming operations.

=item  $DB::trace

This flag is set to true if the API is tracing through subroutine calls.

=item  @DB::args

Contains the arguments of current subroutine, or the C<@ARGV> array if in the
toplevel context.

=item  @DB::dbline

List of lines in currently loaded file.

=item  %DB::dbline

Actions in current file (keys are line numbers).  The values are strings that
have the sprintf(3) format C<("%s\000%s", breakcondition, actioncode)>.

=item  $DB::package

Package namespace of currently executing code.

=item  $DB::filename

Currently loaded filename.

=item  $DB::subname

Fully qualified name of currently executing subroutine.

=item  $DB::lineno

Line number that will be executed next.

=back

=cut
