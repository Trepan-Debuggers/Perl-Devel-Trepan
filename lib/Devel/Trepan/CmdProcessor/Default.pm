# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use Exporter;
use warnings;

use rlib '../../..';

package Devel::Trepan::CmdProcessor;

use if !@ISA, Devel::Trepan::Options;
use vars qw(@EXPORT $HAVE_DATA_PRINT $HAVE_PERLTIDY @DISPLAY_TYPES);
@EXPORT = qw(default_eval_display  $HAVE_DATA_PRINT $HAVE_PERLTIDY
            @DISPLAY_TYPES);

use strict;

our @ISA;

BEGIN {
    $HAVE_DATA_PRINT = 
        eval("use Data::Printer { colored => 1}; 1") ? 
        1 : 0;
    $HAVE_PERLTIDY   = eval {
        require Data::Dumper::Perltidy; 
    } ? 1 : 0;
    @DISPLAY_TYPES = ('dumper');
    push @DISPLAY_TYPES, 'dprint' if $HAVE_DATA_PRINT;
    push @DISPLAY_TYPES, 'tidy'   if $HAVE_PERLTIDY;
}

# Return what to use for evaluation display
sub default_eval_display() {
    if ($HAVE_DATA_PRINT) {
        return 'dprint';
    } elsif ($HAVE_PERLTIDY) {
        return 'tidy';
    } else {
       return 'dumper';
    }
}


use constant DEFAULT_SETTINGS => {
    abbrev        => 1,      # Allow abbreviations of debugger commands?
    autoeval      => 1,      # Perl eval non-debugger commands
    autoirb       => 0,      # Go into IRB in debugger command loop
    autolist      => 0,      # Run 'list' before entering command loop? 
    
    basename      => 0,      # Show basename of filenames only
    confirm       => 1,      # Confirm potentially dangerous operations?
    cmddir        => [],     # Additional directories to load commands
                             # from
    different     => 0,      # stop *only* when  different position? 
    displayop     => 0,      # If set, show OP address in location
    debugdbgr     => 0,      # Debugging the debugger
    debugexcept   => 1,      # Internal debugging of command exceptions
    debugmacro    => 0,      # debugging macros
    debugskip     => 0,      # Internal debugging of step/next skipping
    directory     =>         # last-resort path-search for files
    '$cdir:$cwd',            # that are not fully qualified.
    
    displayeval   => default_eval_display(),
                             # use Data::Dumper (dumper) or
                             # Data::Dumper::Perltidy::dumper (tidy) ?
    hidestack     => -1,     # Fixnum. How many hidden outer
                             # debugger stack frames to hide?
                             # -1 means compute value. 0
                             # means hide none. Less than 0 means show
                             # all stack entries.

    highlight     => Devel::Trepan::Options::default_term(), 
                             # Use terminal highlight? 0 or undef if off.
      
    maxlist       => 10,     # Number of source lines to list 
    maxstack      => 10,     # backtrace limit
    maxstring     => 150,    # Strings which are larger than this
                             # will be truncated to this length when
                             # printed
    maxwidth      => ($ENV{'COLUMNS'} || 80),
    prompt        => 'trepanpl', # core part of prompt. Additional info like
                             # debug nesting and thread added later
    reload        => 0,      # Reread source file if we determine
                             # it has changed?
    save_cmdfile  => 0,      # If set, debugger command file to be
                             # used on restart
    timer         => 0,      # show elapsed time between events
    traceprint    => 0,      # event tracing printing
    tracebuffer   => 0,      # save events to a trace buffer.
##    user_cmd_dir  => File.join(%W(#{Trepan::HOME_DIR} trepan command)),
##                                 # User command directory
};

unless (caller) {
    # Show it:
    require Data::Dumper;
    print Data::Dumper::Dumper(DEFAULT_SETTINGS), "\n";
    print '-' x 20, "\n";
    print join(', ', @DISPLAY_TYPES), "\n";
}

1;
