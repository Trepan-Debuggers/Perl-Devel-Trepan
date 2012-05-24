#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
use vars qw($TREPAN_CMDPROC);
use rlib '..';

package Devel::Trepan;
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use version; $VERSION = '0.2.0';
use Exporter;

use Devel::Trepan::Core;

use constant PROGRAM => 'trepan.pl';

sub show_version {
    PROGRAM . ", version $Devel::Trepan::VERSION";
}

if (__FILE__ eq $0 ) {
    print show_version(), "\n";
}

"Just another Perl Debugger";
__END__

=pod

=head1 NAME

Devel::Trepan -- A new Perl debugger

=head1 SUMMARY

A modular, testable gdb-like debugger in the style of the Ruby
L<trepanning debuggers|http://github.com/rocky/rb-trepanning/wiki>.

It supports syntax highlighting via
L<Syntax::Highlight::Perl::Improved>, a command completion (and
history) via GNU ReadLine via L<Term::ReadLine::Perl> or
L<Term::ReadLine::Gnu>, and interactive shell support via L<Psh> or
L<Devel::REPL>.

=head1 DESCRIPTION

From a shell: 

    bash$ trepan.pl [trepan-opts] perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

    bash$ perl -d:Trepan perl-program [perl-program-opts]

Calling the debugger from inside your Perl program using Joshua ben
Jore's L<Enbugger>:

 	# This needs to be done once and could even be in some sort of 
        # conditional code
        require Enbugger; Enbugger->load_debugger( 'trepan' );

 	# work, work, work...
 	# Oops! there was an error! Enable the debugger now!
        Enbugger->stop;  # or Enbugger->stop if ... 


=head1 AUTHORS

Rocky Bernstein

=head1 COPYRIGHT

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

=cut
