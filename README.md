[![Build Status](https://travis-ci.org/rocky/Perl-Devel-Trepan.png)](https://travis-ci.org/rocky/Perl-Devel-Trepan)

[![Packaging status](https://repology.org/badge/vertical-allrepos/perl:devel-trepan.svg)](https://repology.org/project/perl:devel-trepan/versions)

Devel::Trepan &mdash; A gdb-like Perl debugger
====================================

A modular, testable gdb-like debugger in the family of the "Trepanning" debuggers ([trepan3k](https://pypi.org/project/trepan3k/), [trepan-ni](https://www.npmjs.com/package/trepan-ni), [bashdb](http://bashdb.sourceforge.net), [zshdb](https://github.com/rocky/zshdb)). The command set is modeled off of _gdb_, but other command sets are possible.

Features:
* precise location via decomplation (via plugin [Trepan::Devel::Deparse](https://github.com/rocky/p5-Devel-Trepan-Deparse/)
* has extensive online-help,
* syntax highlighting of Perl code
* context-sensitive command completion
* out-of-process and remote debugging
* interactive shell support
* code disassembly
* _gdb_ syntax
* easy extensibility at several levels
    * command aliases
    * a user-supplied command directory
    * Perl Plugin module such as [Trepan::Devel::Disassemble](https://github.com/rocky/Perl-Devel-Trepan-Disassemble)
* is more modular
* comes with extensive tests
* is not as ugly as _perl5db_

Synopsis
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


Installation
------------

To install this Devel::Trepan from source code:

    $ cpan Module::Build
    $ perl Build.PL
    $ ./Build installdeps
    $ make
    $ make test
    $ make install # May need sudo

or to install from CPAN:

    $ cpanm Devel::Trepan

See Also
--------

* [On writing a new Perl Debugger (Part 1 - Why?)](http://blogs.perl.org/users/rockyb/2012/07/on-writing-a-new-perl-debugger-part-1---why.html)
* [Devel::Trepan Debugger command aliases and command completion](http://blogs.perl.org/users/rockyb/2012/08/develtrepan-debugger-command-aliases-and-command-completion.html)
* [Devel::Trepan Debugger evaluation of Perl statements](http://blogs.perl.org/users/rockyb/2012/08/develtrepan-debugger-evaluation-of-perl-statements.html)
* [Location, Location, Location](http://blogs.perl.org/users/rockyb/2012/08/location-location-location.html)
* [Exact Perl location with B::DeparseTree (and Devel::Callsite)](http://blogs.perl.org/users/rockyb/2015/11/exact-perl-location-with-bdeparse-and-develcallsite.html)
* [wiki](https://github.com/rocky/Perl-Devel-Trepan/wiki)

Licence and Copyright
---------------------

Copyright (C) 2011-2015, 2019 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O’Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.
