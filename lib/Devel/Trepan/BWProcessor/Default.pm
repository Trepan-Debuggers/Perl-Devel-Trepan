# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use Exporter;
use warnings;

use rlib '../../..';

package Devel::Trepan::BWProcessor;

use if !@ISA, Devel::Trepan::Options;
use vars qw(@EXPORT);
@EXPORT = qw();

use strict;

our @ISA;

use constant DEFAULT_SETTINGS => {
    autolist      => 0,      # Run 'list' before entering command loop? 
    basename      => 0,      # Show basename of filenames only
    confirm       => 0,      # Confirm potentially dangerous operations?
    cmddir        => [],     # Additional directories to load commands
                             # from
    different     => 0,      # stop *only* when  different position? 
    debugdbgr     => 0,      # Debugging the debugger
    debugexcept   => 1,      # Internal debugging of command exceptions
    debugmacro    => 0,      # debugging macros
    debugskip     => 0,      # Internal debugging of step/next skipping
    directory     =>         # last-resort path-search for files
    '$cdir:$cwd',            # that are not fully qualified.
    
    hidestack     => -1,     # Fixnum. How many hidden outer
                             # debugger stack frames to hide?
                             # -1 means compute value. 0
                             # means hide none. Less than 0 means show
                             # all stack entries.

    maxlist       => 10,     # Number of source lines to list 
    maxstack      => 10,     # backtrace limit
    maxstring     => 150,    # Strings which are larger than this
                             # will be truncated to this length when
                             # printed
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
}

1;
