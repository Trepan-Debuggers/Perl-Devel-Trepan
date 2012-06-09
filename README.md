Devel::Trepan -- A new Perl debugger
====================================

A modular, testable debugger in the family of the Ruby ["Trepanning"](https://github.com/rocky/rb-trepanning/wiki) [debuggers](https://github.com/rocky/rb-trepanning/wiki). The command set is modeled off of gdb, but other command sets are possible.

Features: 
* has extensive online-help, 
* supports syntax highlighting via Syntax::Highlight::Perl::Improved, 
* has command completion and history via GNU ReadLine via Term::ReadLine::Perl or
Term::ReadLine::Gnu
* interactive shell support via Psh or Devel::REPL.
* supports out-of-host or out-of-process debugging (remote debugging over a socket)
* is user extensible via a number of mechanisms
    * command aliases
    * a user-supplied command directory
    * Perl Plugin module such as [Trepan::Devel::Disassemble](https://github.com/rocky/Perl-Devel-Trepan-Disassemble)
* is more modular
* comes with extensive tests
* is not as ugly as perl5db

SYNOPSIS
--------

From a shell: 

        $ trepan.pl [trepan-opts] -- perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

        $ perl -d:Trepan perl-program [perl-program-opts]

Calling the debugger from inside your Perl program using Joshua ben
Jore's [Enbugger](http://search.cpan.org/~jjore/Enbugger/):

	# This needs to be done once and could even be in some sort of conditional code
        require Enbugger; Enbugger->load_debugger( 'trepan' );
        # Alternatively, to unconditinally load Enbugger and trepan:
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

To install this Devel::Trepan, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

or:

        $ perl -MCPAN -e shell
	...
	cpan[1]> install Devel::Trepan


LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O’Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.

