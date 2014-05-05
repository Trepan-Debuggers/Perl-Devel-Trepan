[![Build Status](https://travis-ci.org/rocky/Perl-Devel-Trepan.png)](https://travis-ci.org/rocky/Perl-Devel-Trepan)

Devel::Trepan -- A new Perl debugger
====================================

A modular, testable debugger in the family of the Ruby ["Trepanning"](https://github.com/rocky/rb-trepanning/wiki) [debuggers](https://github.com/rocky/rb-trepanning/wiki). The command set is modeled off of _gdb_, but other command sets are possible.

Features:
* has extensive online-help,
* syntax highlighting of Perl code
* context-sensitive command completion
* out-of-process and remote debugging
* interactive shell support
* code disassembly
* gdb syntax
* easy extensibility at several levels
    * command aliases
    * a user-supplied command directory
    * Perl Plugin module such as [Trepan::Devel::Disassemble](https://github.com/rocky/Perl-Devel-Trepan-Disassemble)
* is more modular
* comes with extensive tests
* is not as ugly as _perl5db_

SYNOPSIS
--------

From a shell:

    $ trepan.pl [trepan-opts] [--] perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

    $ perl -d:Trepan perl-program [perl-program-opts]

The problem with the above "perlish" approach is that there are a
number of default options won't get set intelligently. If that matters,
you'll have to set them either with a debugger command or via
environment variable *TREPANPL_OPTS*. To see the environement
variables, run *trepan.pl* with the `--verbose` option.

Calling the debugger from inside your Perl program using Joshua ben
Jore's [Enbugger](http://search.cpan.org/~jjore/Enbugger/):

    # This needs to be done once and could even be in some sort of
    # conditional code
    require Enbugger; Enbugger->load_debugger( 'trepan' );

    # Alternatively, to unconditionally load Enbugger and trepan:
    use Enbugger 'trepan';

    # work, work, work...
    # Oops! there was an error! Enable the debugger now!
    Enbugger->stop;  # or Enbugger->stop if ...

Or if you just want POSIX-shell-like `set -x` line tracing:

    $ trepan.pl -x -- perl-program [perl-program-opts]

Inside the debugger tracing is turned on using the command `set trace print`.
There is extensive help from the `help` command.


INSTALLATION
------------

To install this Devel::Trepan from source code:

    perl Build.PL
    make
    make test
    [sudo] make install

or to install from CPAN:

    $ cpanm Devel::Trepan


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>

[![endorse](https://api.coderwall.com/rocky/endorsecount.png)](https://coderwall.com/rocky)

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O’Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.
