#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
use vars qw($TREPAN_CMDPROC);
use rlib '..';

package Devel::Trepan;
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use version; $VERSION = '0.32';
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

Devel::Trepan -- A new modular Perl debugger

=head1 SUMMARY

A modular, testable, gdb-like debugger in the family of the Ruby
L<trepanning debuggers|http://github.com/rocky/rb-trepanning/wiki>.

=head2 Features: 

=over 4

=item *

extensive online-help

=item *

syntax highlighting of Perl code

=item *

context-sensitive command completion

=item *

out-of-process and remote debugging

=item *

interactive shell support

=item *

code disassembly

=item *

gdb syntax

=item *

easy extensibility at several levels: aliases, commands, and plugins

=item *

comes with extensive tests

=item *

is not as ugly as perl5db

=back

Some of the features above require additional modules before they take
effect. See L</Plugins> and L</Recommended Modules> below.


=head1 DESCRIPTION

From a shell: 

    $ trepan.pl [trepan-opts] -- perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

    $ perl -d:Trepan perl-program [perl-program-opts]

Calling the debugger from inside your Perl program using Joshua ben
Jore's L<Enbugger>:

    # This needs to be done once and could even be in some sort of 
    # conditional code
    require Enbugger; Enbugger->load_debugger( 'trepan' );

    # Alternatively, to unconditionally load Enbugger and trepan:
    use Enbugger 'trepan';

    # work, work, work...
    # Oops! there was an error! Enable the debugger now!
    Enbugger->stop;  # or Enbugger->stop if ... 

Or if you just want POSIX-shell-like C<set -x> line tracing:

    $ trepan.pl -x -- perl-program [perl-program-opts]

Inside the debugger tracing is turned on using the command C<set trace print>.
There is extensive help from the C<help> command.

=head1 BUGS/CAVEATS

Because this should be useful in all sorts of environments such as
back to perl 5.008, we often can make use of newer Perlisms nor can we
I<require> by default all of the modules, say for data printing, stack
inspection, or interactive terminal handling. That said, if you have a
newer Perl or the recommended modules or install plugins, you'll get
more.

Although modular, this program is even larger than C<perl5db> and so
it loads a little slower. I think part of the slowness is the fact
that there are over 70 or so (smallish) files (rather than one nearly
10K file) and because relative linking via L<rlib> is used to glue
them together.

=head1 AUTHOR

Rocky Bernstein

=head1 SEE ALSO

=head2 My Devel::Trepan blogs and wiki

=over 4

=item *

L<On writing a new Perl Debugger (Part 1 - Why?)|http://blogs.perl.org/users/rockyb/2012/07/on-writing-a-new-perl-debugger-part-1---why.html>

=item *

L<Devel::Trepan Debugger command aliases and command completion|http://blogs.perl.org/users/rockyb/2012/08/develtrepan-debugger-command-aliases-and-command-completion.html>

=item *

L<Devel::Trepan Debugger evaluation of Perl statements|http://blogs.perl.org/users/rockyb/2012/08/develtrepan-debugger-evaluation-of-perl-statements.html>

=item *

L<Location, Location, Location|http://blogs.perl.org/users/rockyb/2012/08/location-location-location.html>

=item *

L<Devel::Trepan github wiki|https://github.com/rocky/Perl-Devel-Trepan/wiki>

=back 

=head2 Plugins

=over 4

=item *

L<Devel::Trepan::Shell> adds a debugger C<shell> command support via L<Devel::REPL>

=item *

L<Devel::Trepan::Disassemble> adds a debugger C<disassemble> command
support via L<B::Concise>

=back 

=head2 Recommended Modules

=over 4

=item *

L<Enbugger> allows you to enter the debugger via a direct call in source code

=item *

L<Eval::WithLexicals> allows you to inspect I<my> and I<our> variables up the call stack

=item *

L<Data::Printer> allows one to Use I<Data::Printer> to format evaluation output

=item *

L<Data::Dumper::Perltidy> allows one to Use I<Data::Dumper::Perltidy> to format evaluation output

=item *

L<Term::ReadLine::Perl> allows editing on the command line and command completion. This Module is preferred over L<Term::ReadLine::Gnu>.

=item *

L<Term::ReadLine::Gnu> allows editing of the command line and command completion

=back

=head2 Other Debuggers

=over 4

=item *

L<perldebug> is perl's built-in tried-and-true debugger that other
debuggers will ultimately be compared with

=item *

L<Devel::ebug>

=item *

L<DB> is a somewhat abandoned debugger API interface. I've tried to use some
parts of this along with C<perl5db>.

=back

=head1 COPYRIGHT

Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O'Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.

=cut
