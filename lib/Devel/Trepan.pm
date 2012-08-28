#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
use vars qw($TREPAN_CMDPROC);
use rlib '..';

package Devel::Trepan;
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use version; $VERSION = '0.35';
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

=head2 Basic Commands

The help system follows the gdb classificiation. Below is not a full
list of commands, nor does it contain the full list of options on each
command, but rather some of the more basic commands and options.

=head3 Commands involving Running the program

=head4 step [COUNT]

Execute the current line, stopping at the next event.  Sometimes this
is called 'step into'.

With an integer argument, step that many times.  

A suffix of C<+> in a command or an alias forces a move to another
position.

If no suffix is given, the debugger setting 'different' determines
this behavior.

Examples: 

    step        # step 1 event, *any* event obeying 'set different' setting
    step 1      # same as above
    step+       # same but force stopping on a new line
    step over   # same as 'next'
    step out    # same as 'finish'

Related and similar is the C<next> (step over) and C<finish> (step out)
commands.  All of these are slower than running to a breakpoint.

=head4 next

Step one statement ignoring steps into function calls at this level.
Sometimes this is called "step over".

=head4 continue [LOCATION]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. 

Examples:

    continue
    continue 10    # continue to line 10
    continue gcd   # continue to first instruction of method gcd

=head4 finish

Continue execution until the program is about to leave the current
function. Sometimes this is called 'step out'.

=head4 quit[!] [unconditionally] [exit code] 

Gentlly exit the debugger and debugged program.

The program being debugged is exited via exit() which runs the Kernel
at_exit finalizers. If a return code is given, that is the return code
passed to exit() - presumably the return code that will be passed back
to the OS. If no exit code is given, 0 is used.

Examples: 

    quit                 # quit prompting if we are interactive
    quit unconditionally # quit without prompting
    quit!                # same as above
    quit 0               # same as "quit"
    quit! 1              # unconditional quit setting exit code 1

=head4 kill 

Kill execution of program being debugged.
Equivalent of kill('KILL', $$). This is an unmaskable
signal. Use this when all else fails, e.g. in thread code, use this.

If you are in interactive mode, you are prompted to confirm killing.
However when this command is aliased from a command ending in !, no 
questions are asked.

    kill  
    kill unconditionally
    kill KILL # same as above
    kill TERM # Send "TERM" signal
    kill -9   # same as above
    kill  9   # same as above
    kill! 9   # above, but no questions asked

See also C<quit>

=head4 restart

Restart debugger and program via an exec call.

See also C<show args> for the exact invocation that will be used.

=head3 Examining data

=head4 eval[@$][?] [STRING]

Run code in the context of the current frame.

If no string is given after the word "eval", we run the string from
the current source code about to be run. If the "eval" command ends ?
(via an alias) and no string is given we try to pick out a useful
expression in the line.

Normally eval assumes you are typing a statement, not an expression;
the result is a scalar value. However you can force the type of the result
by adding the appropriate sigil @, or $.

Examples:

    eval 1+2 # 3
    eval$ 3   # Same as above, but the return type is explicit
    $ 3       # Probably same as above if $ alias is around
    eval $^X  # Possibly /usr/bin/perl
    eval      # Run current source-code line
    eval?     # but strips off leading 'if', 'while', ..
              # from command 
    eval @ARGV  # Make sure the result saved is an array rather than 
                # an array converted to a scalar.
    @ @ARG       # Same as above if @ alias is around
    use English  # Note this is a statement, not an expression
    use English; # Same as above
    eval$ use English # Error because this is not a valid expression 

See also C<set auto eval> to treat unrecognized debugger commands as
Perl code.

=head4 debug PERL-EXPRESSION

To be completed...

=head3 Examining the call stack

=head4 backtrace [COUNT]

Print a stack trace, with the most recent frame at the top.  With a
positive number, print at most many entries. 

An arrow indicates the 'current frame'. The current frame determines
the context used for many debugger commands such as source-line
listing or the 'edit' command.

Examples:

   backtrace   # Print a full stack trace
   bactrace 2  # Print only the top two entries


=head4 frame FRAME-NUMBER

Change the current frame to frame FRAME-NUMBER if specified, or the
most-recent frame, 0, if no frame number specified.

A negative number indicates the position from the other or
least-recently-entered end.  So 'frame -1' moves to the oldest frame.

Examples:

    frame     # Set current frame at the current stopping point
    frame 0   # Same as above
    frame .   # Same as above. 'current thread' is explicit.
    frame . 0 # Same as above.
    frame 1   # Move to frame 1. Same as: frame 0; up
    frame -1  # The least-recent frame

=head4 up [COUNT]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame. If no count is given, move up 1.

=head4 down [COUNT]

Move the current frame down in the stack trace (to a newer frame). 0
is the most recent frame. If no count is given, move down 1.

=head3 Syntax of debugger commands

=head4 Overall Debugger Command Syntax

If the first non-blank character of a line starts with #, the command
is ignored.

Commands are split at whereever C<;;> appears. This process disregards
any quotes or other symbols that have meaning in Perl. The strings
after the leading command string are put back on a command queue. 

Within a single command, tokens are then white-space split. Again,
this process disregards quotes or symbols that have meaning in Perl.
Some commands like C<eval>, C<macro>, and C<break> have access to the
untokenized string entered and make use of that rather than the
tokenized list.

Resolving a command name involves possibly 4 steps. Some steps may be
omitted depending on early success or some debugger settings:

1. The leading token is first looked up in the macro table. If it is in
the table, the expansion is replaces the current command and possibly
other commands pushed onto a command queue. See the "help macros" for
help on how to define macros, and "info macro" for current macro
definitions. 

2. The leading token is next looked up in the debugger alias table and
the name may be substituted there. See "help alias" for how to define
aliases, and "show alias" for the current list of aliases.

3. After the above, The leading token is looked up a table of debugger
commands. If an exact match is found, the command name and arguments
are dispatched to that command. Otherwise, we may check to see the the
token is a unique prefix of a valid command. For example, "dis" is not
a unique prefix because there are both "display" and "disable"
commands, but "disp" is a unique prefix. You can allow or disallow
abbreviations for commands using "set abbrev". The default is
abbreviations are on.

4. If after all of the above, we still don't find a command, the line
may be evaluated as a Perl statement in the current context of the
program at the point it is stoppped. However this is done only if
"auto eval" is on.  (It is on by default.)

If "auto eval" is not set on, or if running the Perl statement
produces an error, we display an error message that the entered string
is "undefined".

=head4 Command suffixes which have special meaning

Some commands like C<step>, or C<list> do different things when an
alias to the command ends in a particular suffix like ">". 

Here are a list of commands and the special suffixes:

    command   suffix
    -------   ------
    list       >
    step       +,-,<,>
    next       +,-,<,> 
    quit       !
    kill       !
    eval       ?

See help on the commands listed above for the specific meaning of the suffix.

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
