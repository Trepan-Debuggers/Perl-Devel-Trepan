NAME
    Devel::Trepan -- A new Perl debugger

SYNOPSIS

From a shell: 

        bash$ trepanpl [trepan-opts] perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

       bash$ perl -d:Trepan perl-program [perl-program-opts]

Calling the debugger from inside your Progam program using Joshua ben
Jore's Enbugger (http://search.cpan.org/~jjore/Enbugger/) patched with
the trepan extension
(https://github.com/rocky/Perl-Devel-Trepan/blob/master/data/Enbugger-trepan.patch):

	# This needs to be done once and could even be in some sort of conditional code
        require Enbugger; Enbugger->load_debugger( 'trepan' );

	# work, work, work...
	# Oops! there was an error! Enable the debugger now!
        Enbugger->stop;  # or Enbugger->stop if ... 

INSTALLATION

To install this Devel::Trepan, run the following commands:

	perl Build.PL
	make
	make test
	[sudo] make install

AUTHOR
    Rocky Bernstein <rocky@cpan.org>

LICENSE AND COPYRIGHT

Copyright (C) 2011 Rocky Bernstein

    This program is distributed WITHOUT ANY WARRANTY, including but not
    limited to the implied warranties of merchantability or fitness for a
    particular purpose.

    The program is free software. You may distribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation (either version 2 or any later version) and the
    Perl Artistic License as published by O’Reilly Media, Inc. Please open
    the files named gpl-2.0.txt and Artistic for a copy of these licenses.

