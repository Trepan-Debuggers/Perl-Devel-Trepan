#!/usr/bin/env perl
# Copyright (C) 2013-2014 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
use strict; use warnings;

use rlib '..';
use Devel::Trepan::Version;
use Devel::Trepan::Core;

package Devel::Trepan;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION $TREPAN_CMDPROC $PROGRAM);
use Exporter;

@EXPORT = qw(debugger);
@ISA = qw(Exporter);


use constant PROGRAM => 'trepan.pl';
use version;
$VERSION='0.57'; # To fool CPAN indexer. Is <= real version
$VERSION = $Devel::Trepan::Version::VERSION;
$PROGRAM = PROGRAM;

sub show_version() {
    PROGRAM . ", version $Devel::Trepan::VERSION";
}

# =head2 debugger
# Allows program to make an explicit call to the debugger.
# B<Example:>
#
# In your Perl program I<foo.pl>:
#
#    my $x = 1;
#    Devel::Trepan::debugger;
#    my $y = 2;  # Above line causes a stop here.
#
# Invoke as:
#
#   $ trepan.pl foo.pl
#   -- main::(foo.pl:1)
#   (trepanpl): continue
#   (trepanpl): c
#   :o main::(foo.pl:3)
#   my $y = 2;
#
# This is like C<Enbugger-E<gt>stop> but without L<Enbugger>. However in
# contrast to Enbugger, in order for this to work you must have
# previously set up for debugging previously by running trepan.pl.
#
# =cut

sub debugger {
    $DB::in_debugger = 0;
    $DB::event = 'debugger-call';
    $DB::signal = 2;
}

if (__FILE__ eq $0 ) {
    print show_version(), "\n";
}

unless (caller) {
    print show_version, "\n";
    print "Pssst... this is a module. See trepan.pl to invoke.\n"
}
no warnings;
"Just another Perl Debugger";
__END__

=pod

=for comment
This file is shared by both Trepan.pod and Trepan.pm after its __END__
Trepan.pod is useful in the Github wiki:
https://github.com/rocky/Perl-Devel-Trepan/wiki
where we can immediately see the results and others can contribute.

=begin html

<a href="https://travis-ci.org/rocky/Perl-Devel-Trepan"><img src="https://travis-ci.org/rocky/Perl-Devel-Trepan.png"></a>

=end html

=for comment
The version Trepan.pm however is what is seen at https://metacpan.org/module/Devel::Trepan and when folks download this file


=head1 NAME

Devel::Trepan -- A new modular Perl debugger

=head1 SUMMARY

A modular, testable, gdb-like debugger in the family of the Ruby
L<trepanning debuggers|http://github.com/rocky/rb-trepanning/wiki>.

=head2 Features:

=over

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

=head2 Invocation

From a shell:

    $ trepan.pl [trepan-opts] [--] perl-program [perl-program-opts]

Or for those who prefer the traditional Perlish way:

    $ perl -d:Trepan perl-program [perl-program-opts]

The problem with the above "perlish" approach is that you get the
default trepan options. If you want to set any of these, you'll have
to set them either with a debugger command, possibly via startup
script, e.g. I<~/.treplrc> or via environment variable
I<TREPANPL_OPTS>.

To see the environement variables, run I<trepan.pl> with the
C<--verbose> option or run C<eval $ENV{TREPANPL_OPTS}> inside of the
debugger.

For out-of-process (and possibly out-of server) debugging:

    $ trepan.pl --server [trepan-opts] -- perl-program [perl-program-opts]

and then from another process or computer:

    $ trepan.pl --client [--host DNS-NAME-OR-IP]

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

Inside the debugger tracing is turned on using the command C<set trace
print>.  There is extensive help from the C<help> command.

=head2 Command Categories

The help system follows the I<gdb> classificiation.

=over

=item *

L</Making the program stop at certain points>

=item *

L</Examining data>

=item *

L</Specifying and examining file>

=item *

L</Commands involving running the program>

=item *

L</Examining the call stack>

=item *

L</Status inquiries>

=item *

L</Support facilities>

=item *

L</Syntax of Debugger Commands>

=back

=head3 Making the program stop at certain points

A I<breakpoint> is a way to have the program stop at a pre-determined
location. A breakpoint can be perminant or one-time. A one-time
breakpoint is removed as soon as it is hit. In a sense, stepping is
like setting one-time breakpoints. Breakpoints can also be disabled
which allows you to temporarily ignore stopping at that breakpoint
while it is disabled. Finally one can control conditions under which a
breakpoint is enacted upon.

Another way to force a stop is to watch to see if the value of an
expression changes. Often that expression is simply examinging a
variable's value.

=over

=item *

L<Set an action to be done before the line is executed (action)|Devel::Trepan::CmdProcessor::Command::Action>

=item *

L<Set a breakpoint (break)|Devel::Trepan::CmdProcessor::Command::Break>

=item *

L<Add or modify a condition on a breakpoint (condition)|Devel::Trepan::CmdProcessor::Command::Condition>

=item *

L<Delete some breakpoints (delete)|Devel::Trepan::CmdProcessor::Command::Delete>

=item *

L<Disable some breakpoints (disable)|Devel::Trepan::CmdProcessor::Command::Disable>

=item *

L<Enable some breakpoints (enable)|Devel::Trepan::CmdProcessor::Command::Enable>

=item *

L<Set a temporary breakpoint (tbreak)|Devel::Trepan::CmdProcessor::Command::TBreak>

=item *

L<Stop when an expression changes value (watch)|Devel::Trepan::CmdProcessor::Command::Watch>

=back

=head3 Examining data

=over

=item *

L<Debug into a Perl expression or statement (debug)|Devel::Trepan::CmdProcessor::Command::Debug>

=item *

L<Display expressions when entering the debugger (display)|Devel::Trepan::CmdProcessor::Command::Display>

=item *

L<Evaluate Perl code (eval)|Devel::Trepan::CmdProcessor::Command::Eval>

=item *

L<Recursively Debug into Perl code (debug)|Devel::Trepan::CmdProcessor::Command::Debug>

=item *

L<Cancel some expressions to be displayed when program stops
(undisplay)|Devel::Trepan::CmdProcessor::Command::Undisplay>

=back

=head3 Specifying and examining files

=over

=item *

L<Invoke an editor on some source code (edit)|Devel::Trepan::CmdProcessor::Command::Edit>

=item *

L<List source code (list)|Devel::Trepan::CmdProcessor::Command::List>

=back

=head3 Commands involving running the program

The commands in the section involve controlling execution of the
program, either by kinds of stepping (step into, step over, step out)
restarting or termintating the program altogether. However setting
breakpoints is in L</Making the program stop at certain points>.

=over

=item *

L<Continue execution (continue)|Devel::Trepan::CmdProcessor::Command::Continue>

=item *

L<Step out (finish)|Devel::Trepan::CmdProcessor::Command::Finish>

=item *

L<Specify a how to handle a signal (handle)|Devel::Trepan::CmdProcessor::Command::Handle>

=item *

L<Step over (next)|Devel::Trepan::CmdProcessor::Command::Next>

=item *

L<Step into (step)|Devel::Trepan::CmdProcessor::Command::Step>

=item *

L<Hard termination (kill)|Devel::Trepan::CmdProcessor::Command::Kill>

=item *

L<Gently exit debugged program (quit)|Devel::Trepan::CmdProcessor::Command::Quit>

=item *

L<Restart execution (run)|Devel::Trepan::CmdProcessor::Command::Run>

=back

=head3 Examining the call stack

The commands in this section show the call stack and let set a
reference for the default call stack which other commands like
L<C<list>|Devel::Trepan::CmdProcessor::Command::List> or
L<C<break>|Devel::Trepan::CmdProcessor::Command::Break> use as a
position when one is not specified.

The most recent call stack entry is 0. Except for the relative motion
commands L<C<up>|Devel::Trepan::CmdProcessor::Command::Up> and
L<C<down>|Devel::Trepan::CmdProcessor::Command::Down>, you can refer
to the oldest or top-level stack entry with -1 and negative numbers
refer to the stack from the other end.

Beware that in contrast to debuggers in other programming languages,
Perl really doesn't have an easy way for one to evaluate statements
and expressions other than at the most recent call stack.  There are
ways to see lexical variables I<my> and I<our>, however localized
variables which can hide global variables and other lexicals variables
can be problematic.

=over

=item *

L<Print all or parts of the call stack
(backtrace)|Devel::Trepan::CmdProcessor::Command::Backtrace>

=item *

L<Move to a less recent frame
(down)|Devel::Trepan::CmdProcessor::Command::Down>

=item *

L<Select a call frame
(frame)|Devel::Trepan::CmdProcessor::Command::Frame>

=item *

L<Move to a more recent frame (up)|Devel::Trepan::CmdProcessor::Command::Up>

=back

=head3 Status inquiries

=over

=item *

L<Information for showing things about the program being debugged
(info)|Devel::Trepan::CmdProcessor::Command::Info>

=item *

L<Showing things about the debugger (show)|Devel::Trepan::CmdProcessor::Command::Show>

=back

=head3 Support facilities

=over

=item *

L<Define an alias (alias)|Devel::Trepan::CmdProcessor::Command::Alias>

=item *

L<List the completions for the rest of the line (complete)|Devel::Trepan::CmdProcessor::Command::Complete>

=item *

L<Loading or reloading Debugger or Perlish things (load)|Devel::Trepan::CmdProcessor::Command::Load>

=item *

L<Define a macro (macro)|Devel::Trepan::CmdProcessor::Command::Macro>

=item *

L<Allow remote connections (server)|Devel::Trepan::CmdProcessor::Command::Server>

=item *

L<Run debugger commands from a file (source)|Devel::Trepan::CmdProcessor::Command::Source>

=item *

L<Modify parts of the Debugger Environment (set)|Devel::Trepan::CmdProcessor::Command::Set>

=item *

L<Remove an alias (unalias)|Devel::Trepan::CmdProcessor::Command::Unalias>

=back

=head3 Syntax of Debugger Commands

=over

=item *
L<Overall Debugger Command Syntax|Devel::Trepan::CmdProcessor::Command::Help::command>

=item *
L<Location Syntax|Devel::Trepan::CmdProcessor::Command::Help::location>

=item *
L<Filename syntax|Devel::Trepan::CmdProcessor::Command::Help::filename>

=item *
L<Command suffixes which have special meaning|Devel::Trepan::CmdProcessor::Command::Help::suffixes>

=item *
L<Debugger Command Examples|Devel::Trepan::CmdProcessor::Command::Help::examples>

=back

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

I<Devel::Trepan> will detect automatically whether any of these
modules are present. If so, additional capabilies are available.

=over 4

=item *

L<Devel::Callsite> allows you to see the exact location of where you
are stopped. Location reporting changes by default to show the current
OP address, when this module is present.

=item *
L<Enbugger> allows you to enter the debugger without previously having your program compiled for debugging.

=item *

L<Eval::WithLexicals> allows you to inspect I<my> and I<our> variables
up the call stack. Commands L<C<info variables
my>|Devel::Trepan::CmdProcessor::Command::Info::Variables::My> and
L<C<info variables
our>|Devel::Trepan::CmdProcessor::Command::Info::Variables::Our> become
available when this module is detected.

=item *

L<Data::Printer> allows one to Use I<Data::Printer> to format evaluation output

=item *

L<Data::Dumper::Perltidy> allows one to Use I<Data::Dumper::Perltidy> to format evaluation output

=item *

L<Term::ReadLine::Perl5> allows editing on the command line, command completion, and saving command history. This Module is preferred over I<Term::ReadLine::Perl> or I<Term::ReadLine::Gnu>.

=item *

L<Term::ReadLine::Gnu> allows editing of the command line and command completion. Command completion isn't as good here as with I<Term::ReadLine::Perl5>.

=back

=head2 Other Debuggers

=over 4

=item *

L<perldebug> is perl's built-in tried-and-true debugger that other
debuggers will ultimately be compared with

=item *

L<Devel::ebug>

=item *

L<DB> is a somewhat abandoned debugger API interface. I've tried to
use some parts of this along with C<perl5db>.

=item *

L<Devel::Hdb>

A Perl debugger that uses HTML and javascript to implement the
GUI. The front end talks via a REST service.

=back

=head1 COPYRIGHT

Copyright (C) 2011, 2012, 2014 Rocky Bernstein <rocky@cpan.org>

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
