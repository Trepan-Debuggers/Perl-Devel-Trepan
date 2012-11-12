# Perl's Core DB.pm library with some corrections, additions,
# modifications and code merged from perl5db.pl
#
# Documentation is at the __END__
#

use rlib '../..';

=pod

=head1 C<DB>

Devel::Trepan customized DB package. Down the line this should be split off
and merged with DB that perl5db.pl and other use

=cut

package DB;
use warnings; no warnings 'redefine';
use English qw( -no_match_vars );

use vars qw($running $caller
            $event @ret $ret $return_value @return_value
            $eval_opts $eval_str
            $fall_off_on_end
            $stop @clients $ready $tid @saved
            $init_dollar0 $OS_STARTUP_DIR
            $OP_addr
            %HAVE_MODULE);

use Devel::Trepan::DB::Backtrace;
use Devel::Trepan::DB::Breakpoint;
use Devel::Trepan::DB::Eval;
use Devel::Trepan::DB::Sub;
use Devel::Trepan::Terminated;

# "private" globals
my ($deep, @saved, @skippkg);

my $ineval = {};

####
#
# Globals - must be defined at startup so that clients can refer to 
# them right after a C<use Devel::Trepan::DB;>
#
####

use Cwd;
BEGIN {
    no warnings 'once';
    $ini_warn = $WARNING;

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
    $DB::level = 0;       # Level of nested debugging


    $DB::lineno = '';     # current line number
    $DB::subroutine = '';
    $DB::hasargs = '';
    $DB::wantarray = '';
    $DB::evaltext = '';
    $DB::is_require = '';
    $DB::hints = '';
    $DB::bitmask = '';
    $DB::hinthash = '';
    $DB::caller = [];

    $DB::event = undef;  # The reason we have entered the debugger
    
    $DB::VERSION = '1.04';
    
    # initialize private globals to avoid warnings
    
    $running = 1;         # are we running, or are we stopped?
    $in_debugger = 0;
    @clients = ();
    $ready = 0;
    @saved = ();
    @skippkg = ();
    
    # ensure we can share our non-threaded variables or no-op
    if ($ENV{PERL5DB_THREADED}) {
        require threads;
        require threads::shared;
        import threads::shared qw(share);
        no strict; no warnings;
        $DBGR;
        share(\$DBGR);
        lock($DBGR);
        use strict; use warnings;
        print "Thread support enabled\n";
    } else {
        *lock  = sub(*) {};
        *share = sub(*) {};
    }

    # Don't print return values on exiting a subroutine.
    $doret = -2;

    # "Triggers bug (?) in perl if we postpone this until runtime."
    # XXX No details on this yet, or whether we should fix the bug instead
    # of work around it. Stay tuned.
    @postponed = @stack = (0);

    # No extry/exit tracing.
    $frame = 0;

    $HAVE_MODULE{'Devel::Callsite'} = eval("use Devel::Callsite; 1") ? 1 : 0;

}

END {
    unless ($DB::fall_off_on_end) {
        $DB::single = 1;
        Devel::Trepan::Terminated::at_exit();
    }
    $DB::ready = 0;
} 

sub save_vars();

####
# this is called by Perl for every statement
#
sub DB {

    # print "+++ in DB single: ${DB::single}\n";
    # lock the debugger and get the thread id for the prompt
    lock($DBGR);

    if ($ENV{PERL5DB_THREADED}) {
        $tid = eval { "[".threads->tid."]" };
    }

    return unless $ready && !$in_debugger;
    local $in_debugger = 1;
    @DB::_ = @_;
    save_vars();

    # Since DB::DB gets called after every line, we can use caller() to
    # figure out where we last were executing. Sneaky, eh? This works because
    # caller is returning all the extra information when called from the
    # debugger.
    $DB::caller = [caller];
    ($DB::package, $DB::filename, $DB::lineno, $DB::subroutine, $DB::hasargs,
     $DB::wantarray, $DB::evaltext, $DB::is_require, $DB::hints, $DB::bitmask,
     $DB::hinthash
    ) = @{$DB::caller};

    local $filename_ini = $filename;

    local $OP_addr = ($HAVE_MODULE{'Devel::Callsite'})
        ? Devel::Callsite::callsite() : undef; 

    return if @skippkg and grep { $_ eq $DB::package } @skippkg;

    # Set package namespace for running eval's in the user context. 
    # However this won't let them modify lexical variables, alas.
    # This has to be 'local' rather than 'my' to allow recursive
    # debugging ("debug" command).
    local $namespace_package = "package $DB::package;";
    
    local(*DB::dbline) = "::_<$DB::filename";

    # we need to check for pseudofiles on Mac OS (these are files
    # not attached to a filename, but instead stored in Dev:Pseudo)
    if ( $OSNAME eq 'MacOS' && $#dbline < 0 ) {
        $filename_ini = $filename = 'Dev:Pseudo';
        *dbline = $main::{ '_<' . $filename };
    }
    $DB::brkpt = undef;

    # Increment debugger nesting level.
    local $DB::level = $DB::level + 1;

    # Test watch expressions;
    my $watch_triggered = undef;
    for my $c (@clients) {
        my $n = 0;
        my @list= @{$c->{watch}->{list}};
        for my $wp (@list) {
            next unless $wp->enabled;
            my $opts = {return_type => '$', 
                        namespace_package => $namespace_package,
                        fix_file_and_line => 1,
                        hide_position     => 0};
            my $new_val = &DB::eval_with_return($wp->expr, $opts, @saved);
            my $old_val = $wp->old_value;
            no warnings 'once';
            next if !defined($old_value) and !defined($new_val);
            my $not_same = !defined($old_val) || !defined($new_val);
            if ( $not_same || $new_val ne $wp->old_value ) {
                # Yep! Record change.
                $wp->current_val($new_val);
                $wp->hits($wp->hits+1);
                $watch_triggered = $wp;
                last;
            }
        }
    }

    # Test for breakpoints and action events.
    my @action = ();
    if (exists $DB::dbline{$DB::lineno} and 
        my $brkpts = $DB::dbline{$DB::lineno}) {
        for (my $i=0; $i < @$brkpts; $i++) {
            my $brkpt = $brkpts->[$i];
            next unless defined $brkpt;
            if ($brkpt->type eq 'action') {
                push @action, $brkpt;
                next ;
            }
            $stop = 0;
            if ($brkpt->condition eq '1') {
                # A cheap and simple test for unconditional.
                $stop = 1;
            } else  {
                my $eval_str = sprintf("\$DB::stop = do { %s; }", 
                                       $brkpt->condition);
                my $opts = {return_type => ';',  # ignore return
                            namespace_package => $namespace_package,
                            fix_file_and_line => 1,
                            hide_position     => 0};
                &DB::eval_with_return($eval_str, $opts, @saved);
            }
            if ($stop && $brkpt->enabled && !($DB::single & RETURN_EVENT)) {
                $DB::signal |= 1;
                $DB::brkpt = $brkpt;
                $event = $brkpt->type;
                if ($event eq 'tbrkpt') {
                    # breakpoint is temporary and remove it.
                    undef $brkpts->[$i];
                } else {
                    my $hits = $brkpt->hits + 1;
                    $brkpt->hits($hits);
                }
                last;
            }
        }
    }
    if ($watch_triggered) {
        $event = 'watch';
    } elsif ($DB::signal) {
        $event ||= 'signal';
    } elsif ($DB::single & RETURN_EVENT) {
        $event = 'return';
    } elsif ($DB::trace ) {
        $event ||= 'trace';
    } elsif ($DB::single & (SINGLE_STEPPING_EVENT | NEXT_STEPPING_EVENT)) {
        $event ||= 'line';
    } elsif ($DB::single & DEEP_RECURSION_EVENT) {
        $event ||= 'recurse overflow';
    } else {
        $event = 'unknown';
    }
    
    if ($DB::single || $DB::trace || $DB::signal || $event eq 'watch') {
        $DB::subname = ($DB::sub =~ /\'|::/) ? $DB::sub : "${DB::package}::$DB::sub"; #';
        loadfile($DB::filename, $DB::lineno);
    }

    for my $action (@action) {
        &DB::eval_with_return($action->condition, {return_type => '$'},
			      @saved) 
            if $action->enabled;
        my $hits = $action->hits + 1;
        $action->hits($hits);
    }
    if ($DB::single || $DB::signal || $watch_triggered) {
        _warnall($#stack . " levels deep in subroutine calls.\n") if $DB::single & 4;
        $DB::single = 0;
        $DB::signal = 0;
        $running = 0;
        
        for my $c (@clients) {
            # Now sit in an event loop until something sets $running
            my $after_eval = 0;
            do {
                # Show display expresions
                my $display_aref = $c->display_lists;
                for my $disp (@$display_aref) {
                    next unless $disp && $disp->enabled;
                    my $opts = {return_type => $disp->return_type,
                                namespace_package => $namespace_package,
                                fix_file_and_line => 1,
                                hide_position     => 0};
                    # FIXME: allow more than just scalar contexts.
                    my $eval_result =  
                        &DB::eval_with_return($disp->arg, $opts, @saved);
                    my $mess = sprintf("%d: $eval_result", $disp->number);
                    $c->output($mess);
                }

                if (1 == $after_eval ) {
                    $event = 'after_eval';
                } elsif (2 == $after_eval) {
                    $event = 'after_nest'
                }

                # call client event loop; must not block
                $c->idle($event, $watch_triggered);
                $after_eval = 0;
                if ($running == 2 && defined($eval_str)) { 
                    # client wants something eval-ed
                    # FIXME: turn into subroutine.

                    local $nest = $eval_opts->{nest};
                    my $return_type = $eval_opts->{return_type};
                    $return_type = '' unless defined $return_type;
                    my $opts = $eval_opts;
                    $opts->{namespace_package} = $namespace_package;

                    if ('@' eq $return_type) {
                        &DB::eval_with_return($eval_str, $opts, @saved);
                    } elsif ('%' eq $return_type) {
                        &DB::eval_with_return($eval_str, $opts, @saved);
                    } else {
                        $eval_result = 
                            &DB::eval_with_return($eval_str, $opts, @saved);
                    }

                    if ($nest) {
                        $DB::in_debugger = 1;
                        $after_eval = 2;
                    } else {
                        $after_eval = 1;
                    }
                    $running = 0;
                }
            } until $running;
        }
    }
    $DB::event = undef;
    ($EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
     $OUTPUT_FIELD_SEPARATOR, 
     $INPUT_RECORD_SEPARATOR, 
     $OUTPUT_RECORD_SEPARATOR, $WARNING) = @saved;
    ();
}

=head1 RESTART SUPPORT

These routines are used to store (and restore) lists of items in environment 
variables during a restart.

=head2 set_list

Set_list packages up items to be stored in a set of environment variables
(VAR_n, containing the number of items, and VAR_0, VAR_1, etc., containing
the values). Values outside the standard ASCII charset are stored by encoding
then as hexadecimal values.

=cut

sub set_list {
    my ( $stem, @list ) = @_;
    my $val;

    # VAR_n: how many we have. Scalar assignment gets the number of items.
    $ENV{"${stem}_n"} = @list;

    # Grab each item in the list, escape the backslashes, encode the non-ASCII
    # as hex, and then save in the appropriate VAR_0, VAR_1, etc.
    for $i ( 0 .. $#list ) {
        $val = $list[$i];
        $val =~ s/\\/\\\\/g;
        $val =~ s/([\0-\37\177\200-\377])/"\\0x" . unpack('H2',$1)/eg;
        $ENV{"${stem}_$i"} = $val;
    } ## end for $i (0 .. $#list)
} ## end sub set_list

=head2 get_list

Reverse the set_list operation: grab VAR_n to see how many we should be getting
back, and then pull VAR_0, VAR_1. etc. back out.

=cut 

sub get_list {
    my $stem = shift;
    my @list;
    my $n = delete $ENV{"${stem}_n"};
    my $val;
    for $i ( 0 .. $n - 1 ) {
        $val = delete $ENV{"${stem}_$i"};
        $val =~ s/\\((\\)|0x(..))/ $2 ? $2 : pack('H2', $3) /ge;
        push @list, $val;
    }
    @list;
} ## end sub get_list

###############################################################################
#         no compile-time subroutine call allowed before this point           #
###############################################################################

# this can run only after DB() and sub() are defined
use strict;

# Need this until we replace "save" with "save_vars" in Enbugger/trepan.pm
sub save { die "Remember to update Enbugger/trepan.pm" };

# Like DB::save from perl5db.pl, but want to use another name to
# reduce prototype conflict of save $ vs none if we use perl5db.pl to
# debug Devel::Trepan.
sub save_vars() {
  @saved = ( $EVAL_ERROR, $ERRNO, $EXTENDED_OS_ERROR, 
             $OUTPUT_FIELD_SEPARATOR, 
             $INPUT_RECORD_SEPARATOR, 
             $OUTPUT_RECORD_SEPARATOR, $WARNING );

  $OUTPUT_FIELD_SEPARATOR  = ""; 
  $INPUT_RECORD_SEPARATOR  = "\n";
  $OUTPUT_RECORD_SEPARATOR = "";  
  $WARNING = 0;       # warnings off
}

sub catch {
    @DB::_ = @_;
    $DB::caller = [caller];
    ($DB::package, $DB::filename, $DB::lineno, $DB::subroutine, $DB::hasargs,
     $DB::wantarray, $DB::evaltext, $DB::is_require, $DB::hints, $DB::bitmask,
     $DB::hinthash
    ) = @{$DB::caller};

    # Set package namespace for running eval's in the user context. 
    # However this won't let them modify lexical variables, alas.
    my $namespace_package = "package $DB::package;";

    $event = 'post-mortem';
    $running = 0;
    for my $c (@clients) {
        # Now sit in an event loop until something sets $running
        my $after_eval = 0;
        do {
            # Show display expresions
            my $display_aref = $c->display_lists;
            for my $disp (@$display_aref) {
                next unless $disp && $disp->enabled;
                my $opts = {
                    return_type       => $disp->return_type, 
                    namespace_package => $namespace_package,
                    fix_file_and_line => 1,
                    hide_position     => 0};
                my $eval_result = &DB::eval_with_return($disp->arg, $opts, 
                                                        @saved);
                my $mess = sprintf("%d: $eval_result", $disp->number);
                $c->output($mess);
            }

            if (1 == $after_eval ) {
                $event = 'after_eval';
            } elsif (2 == $after_eval) {
                $event = 'after_nest'
            }
            
            # call client event loop; must not block
            $c->idle($event, 0);
            $after_eval = 0;
            if ($running == 2 && defined($eval_str)) { 
                # client wants something eval-ed
                # FIXME: turn into subroutine.
                
                my $opts = $eval_opts;
                $opts->{namespace_package} = $namespace_package;

                if ('@' eq $opts->{return_type}) {
                    &DB::eval_with_return($eval_str, $opts, @saved);
                } elsif ('%' eq $opts->{return_type}) {
                        &DB::eval_with_return($eval_str, $opts, @saved);
                } else {
                    $eval_result = 
                        &DB::eval_with_return($eval_str, $opts, @saved);
                }

                $after_eval = 1;
                $running = 0;
            }
        } until $running;
    }
}

####
#
# Client callable (read inheritable) methods defined after this point
#
####

sub register {
  my $s = shift;
  # $s = _clientname($s) if ref($s);
  push @clients, $s;
}

sub done {
  my $s = shift;
  $s = _clientname($s) if ref($s);
  @clients = grep {$_ ne $s} @clients;
  $s->cleanup;
#  $running = 3 unless @clients;
  exit(0) unless @clients;
}

sub _clientname {
    my $name = shift;
    "$name" =~ /^(.+)=[A-Z]+\(.+\)$/;
    return $1;
}

sub step {
    my $s = shift;
    $DB::single  = SINGLE_STEPPING_EVENT;
    $DB::running = 1;
}

# cont 
# cont fn_or_line
# cont file line
#
sub cont {
    my $s = shift;
    if (scalar @_ > 0) {
        my ($file, $line);
        if (2 == scalar @_) {
            print @_, "\n";
            ($file, $line) =  @_;
        } else {
            ($file, $line) = ($DB::filename, $_[0]);
        }
        my $brkpt = $s->set_tbreak($file, $line);
        return 0 unless $brkpt;
    }
    for (my $i = 0; $i <= $#stack;) {
        if (defined $stack[$i]) {
            $stack[$i++] &= ~1 ;
        } else {
            # If Enbugger is used $stack[$i] might not be defined
            $stack[$i++] = 0;
        }
    }
    $DB::single = 0;
    return $DB::running = 1;
}

# stop before finishing the current subroutine
sub finish($;$$) {
    my $s = shift;
    # how many levels to get to DB sub?
    my $count = scalar @_ >= 1 ?  shift : 1;
    my $scan_for_DB_sub = scalar @_ >= 1 ?  shift : 1;

    if ($scan_for_DB_sub) {
        my $i = 0;
        while (my ($pkg, $file, $line, $fn) = caller($i++)) {
            if ('DB::DB' eq $fn or ('DB' eq $pkg && 'DB' eq $fn)) {
                # FIXME: This is hoaky. 4 is somehow how far off
                # @stack is from caller. 
                $i -= 4;
                last;
            }
        }
        $count += $i;
    }

    my $index = $#stack-$count;
    $index = 0 if $index < 0;
    $stack[$index] |= RETURN_EVENT;
    $DB::single = RETURN_EVENT;
    $DB::running = 1;
}

sub return_value($) 
{
    if ('undef' eq $DB::return_type) {
        return undef;
    } elsif ('array' eq $DB::return_type) {
        return @DB::return_value;
    } else {
        return $DB::return_value;
    }
}

sub return_type($) 
{
    $DB::return_type;
}

sub _outputall {
  my $c;
  for $c (@clients) {
    $c->output(@_);
  }
}

sub _warnall {
  my $c;
  for $c (@clients) {
    $c->warning(@_);
  }
}

sub trace_toggle {
  my $s = shift;
  $DB::trace = !$DB::trace;
}


####
# first argument is a filename whose subs will be returned
# if a filename is not supplied, all subs in the current
# filename are returned.
#
sub filesubs {
  my $s = shift;
  my $fname = shift;
  $fname = $DB::filename unless $fname;
  return grep { $DB::sub{$_} =~ /^$fname/ } keys %DB::sub;
}

####
# returns a list of all filenames that DB knows about
#
sub files {
  my $s = shift;
  my(@f) = grep(m|^_<|, keys %main::);
  return map { substr($_,2) } @f;
}

####
# loadfile($file, $line)
#
sub loadfile {
  my($file, $line) = @_;
  if (!defined $main::{'_<' . $file}) {
    my $try;
    if (($try) = grep(m|^_<.*$file|, keys %main::)) {  
      $file = substr($try,2);
    }
  }
  if (defined($main::{'_<' . $file})) {
    my $c;
#    _outputall("Loading file $file..");
    *DB::dbline = "::_<$file";
    $DB::filename = $file;
    for $c (@clients) {
#      print "2 ", $file, '|', $line, "\n";
      $c->showfile($file, $line);
    }
    return $file;
  }
  return undef;
}

#
# "pure virtual" methods
#

sub skippkg {
  my $s = shift;
  push @skippkg, @_ if @_;
}

sub evalcode {
    my ($client, $expr) = @_;
    if (defined $expr) {
        $DB::running = 2;    # hand over to DB() to evaluate in its context
        $ineval->{$client} = $expr;
    }
    return $ineval->{$client};
}

sub ready {
    my $s = shift;
    return $ready = 1;
}

sub idle {}
sub cleanup {}
sub output {}
sub warning {}
sub showfile {}

$SIG{'INT'} = \&DB::catch;

1;
__END__

=head1 NAME

DB - programmatic interface to the Perl debugging API

=head1 SYNOPSIS

    package CLIENT;
    use DB;
    @ISA = qw(DB);

    # these (inherited) methods can be called by the client

    CLIENT->register()      # register a client package name
    CLIENT->done()          # de-register from the debugging API
    CLIENT->skippkg('hide::hide')  # ask DB not to stop in this package
    CLIENT->cont([WHERE])       # run some more (until BREAK or another breakpt)
    CLIENT->step()              # single step
    CLIENT->next()              # step over
    CLIENT->finish()            # stop before finishing the current subroutine
    CLIENT->ready()             # call when client setup is done
    CLIENT->trace_toggle()      # toggle subroutine call trace mode
    CLIENT->subs([SUBS])        # return subroutine information
    CLIENT->files()             # return list of all files known to DB
    CLIENT->loadfile(FILE,LINE) # load a file and let other clients know
    CLIENT->set_break([WHERE],[COND])
    CLIENT->set_tbreak([WHERE])
    CLIENT->clr_breaks([LIST])
    CLIENT->set_action(WHERE,ACTION)
    CLIENT->clr_actions([LIST])
    CLIENT->evalcode(STRING)  # eval STRING in executing code's context

    # These methods you should define; They will be called by the DB
    # when appropriate. The stub versions provided do nothing. You should
    # Write your routine so that it doesn't block.

    CLIENT->init()          # called when debug API inits itself
    CLIENT->idle(BOOL, EVENT, ARGS)  # while stopped (can be a client event loop)
    CLIENT->cleanup()       # just before exit
    CLIENT->output(STRING)   # called to print any output that API must show
    CLIENT->warning(STRING) # called to print any warning output that API 
                            # must show
    CLIENT->showfile(FILE,LINE) # called to show file and line before idling

=head1 DESCRIPTION

Perl debug information is frequently required not just by debuggers,
but also by modules that need some "special" information to do their
job properly, like profilers.

This module abstracts and provides all of the hooks into Perl internal
debugging functionality, so that various implementations of Perl debuggers
(or packages that want to simply get at the "privileged" debugging data)
can all benefit from the development of this common code.  Currently used
by Swat, the perl/Tk GUI debugger.

Note that multiple "front-ends" can latch into this debugging API
simultaneously.  This is intended to facilitate things like
debugging with a command line and GUI at the same time, debugging 
debuggers etc.  [Sounds nice, but this needs some serious support -- GSAR]

In particular, this API does B<not> provide the following functions:

=over 4

=item *

data display

=item *

command processing

=item *

command alias management

=item *

user interface (tty or graphical)

=back

These are intended to be services performed by the clients of this API.

This module attempts to be squeaky clean w.r.t C<use strict;> and when
warnings are enabled.


=head2 Global Variables

The following "public" global names can be read by clients of this API.
Beware that these should be considered "readonly".

=over 8

=item  $DB::sub

Name of current executing subroutine.

=item  %DB::sub

The keys of this hash are the names of all the known subroutines.  Each value
is an encoded string that has the sprintf(3) format 
C<("%s:%d-%d", filename, fromline, toline)>.

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

=head2 API Methods

The following are methods in the DB base class.  A client must
access these methods by inheritance (*not* by calling them directly),
since the API keeps track of clients through the inheritance
mechanism.

=over 8

=item CLIENT->register()

register a client object/package

=item CLIENT->evalcode(STRING)

eval STRING in executing code context

=item CLIENT->skippkg('D::hide')

ask DB not to stop in these packages

=item CLIENT->cont()

continue some more (until a breakpoint is reached)

=item CLIENT->step()

single step

=item CLIENT->next()

step over

=item CLIENT->done()

de-register from the debugging API

=back

=head2 Client Callback Methods

The following "virtual" methods can be defined by the client.  They will
be called by the API at appropriate points.  Note that unless specified
otherwise, the debug API only defines empty, non-functional default versions
of these methods.

=over 8

=item CLIENT->init()

Called after debug API inits itself.

=item CLIENT->idle(BOOLEAN, EVENT, ARGS)

Called while stopped (can be a client event loop or REPL). If called
after the idle program requested an eval to be performed, BOOLEAN will be
true. False otherwise. See evalcode below. ARGS are any 

=item CLIENT->evalcode(STRING)

Usually inherited from DB package. Ask for a STRING to be C<eval>-ed
in executing code context. 

In order to evaluate properly, control has to be passed back to the DB
subroutine. Suppose you would like your C<idle> program to do this:

    until $done {
        $command = read input
        if $command is a valid debugger command, 
           run it
        else 
           evaluate it via CLIENT->evalcode($command) and print
           the results.
    }

Due to the limitation of Perl, the above is not sufficient. You have to 
break out of the B<until> to get back to C<DB::sub> to have the eval run.
After that's done, C<DB::sub> will call idle again, from which you can
then retrieve the results.

One other important item to note is that one can only evaluation reliably
current (most recent) frame and not frames further down the stack.

That's probably why the stock Perl debugger doesn't have
frame-switching commands.

=item CLIENT->cleanup()

Called just before exit.

=item CLIENT->output(LIST)

Called when API must show a message (warnings, errors etc.).


=back


=head1 BUGS

The interface defined by this module is missing a number of Perl's
debugging functionality.  As such, this interface is subject to
(possibly incompatible) change.

=head1 AUTHOR

Gurusamy Sarathy        gsar@activestate.com

This code heavily adapted from an early version of perl5db.pl attributable
to Larry Wall and the Perl Porters.

Further modifications by R. Bernstein rocky@cpan.org

=cut
