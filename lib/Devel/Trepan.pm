#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
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
$VERSION='0.48'; # To fool CPAN indexer. Is <= real version
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

    $ trepan.pl [trepan-opts] -- perl-program [perl-program-opts]

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

Inside the debugger tracing is turned on using the command C<set trace print>.
There is extensive help from the C<help> command.

=head2 Basic Commands

The help system follows the gdb classificiation. Below is not a full
list of commands, nor does it contain the full list of options on each
command, but rather some of the more basic commands and options.

=over

=item *

L</"Commands involving running the program">

=item * 

L</"Examining data">

=item * 

L</"Making the program stop at certain points">

=item * 

L</"Examining the call stack">

=item * 

L</"Support facilities">

=item * 

L</"Syntax of debugger commands">

=back 


=head3 Commands involving running the program

The commands in the section involve controlling execution of the
program, either by kinds of stepping (step into, step over, step out)
restarting or termintating the program altogether. However setting
breakpoints is in L</Making the program stop at certain points>.

=over 

=item * 

L</"Step into (step)">

=item *

L</"Step over (next)">

=item * 

L<"Continue execution (continue)">

=item * 

L</"Step out (finish)">

=item *

L</"Gently exit debugged program (quit)">

=item * 

L</"Hard termination (kill)">

=item *

L</"Restart execution (restart)">

=back

=head4 Step into (step)

B<step>[<B<+>|B<->] [B<into>] [I<count>]

Execute the current line, stopping at the next event.  Sometimes this
is called "step into".

With an integer argument, step that many times.  With an 'until'
expression that expression is evaluated and we stop the first time it
is true.

A suffix of C<+> in a command or an alias forces a move to another
position, while a suffix of C<-> disables this requirement.  A suffix
of C<E<gt>> will continue until the next call. (C<finish> will run run until
the return for that call.)

If no suffix is given, the debugger setting C<different> determines
this behavior.

I<Examples:> 

    step        # step 1 event, *any* event obeying 'set different' setting
    step 1      # same as above
    step+       # same but force stopping on a new line
    step over   # same as 'next'
    step out    # same as 'finish'

Related and similar is the C<next> (step over) and C<finish> (step out)
commands.  All of these are slower than running to a breakpoint.

=head4 Step over (next)

B<next>

Step one statement ignoring steps into function calls at this level.
Sometimes this is called "step over".

=head4 Continue execution (continue)

B<continue> [I<location>]

Leave the debugger loop and continue execution. Subsequent entry to
the debugger however may occur via breakpoints or explicit calls, or
exceptions.

If a parameter is given, a temporary breakpoint is set at that position
before continuing. 

I<Examples:>

 continue
 continue 10    # continue to line 10
 continue gcd   # continue to first instruction of method gcd

See also L<C<step>|Devel::Trepan::CmdProcessor::Command::Step>,
L<C<next>|Devel::Trepan::CmdProcessor::Command::Next>,
L<C<finish>|Devel::Trepan::CmdProcessor::Command::Finis> commands and
C<help location>.

=head4 Step out (finish)

B<finish>

Continue execution until the program is about to leave the current
function. Sometimes this is called 'step out'.

=head4 Gently exit debugged program (quit)

B<quit>[B<!>] [B<unconditionally>] [I<exit-code>]

Gently exit the debugger and debugged program.

The program being debugged is exited via I<exit()> which runs the
Kernel I<at_exit()> finalizers. If a return code is given, that is the
return code passed to I<exit()> - presumably the return code that will
be passed back to the OS. If no exit code is given, 0 is used.

B<Examples:>

 quit                 # quit prompting if we are interactive
 quit unconditionally # quit without prompting
 quit!                # same as above
 quit 0               # same as "quit"
 quit! 1              # unconditional quit setting exit code 1

See also C<set confirm> and
L<C<kill>|Devel::Trepan::CmdProcessor::Command::Kill>.  

=head4 Hard termination (kill)

B<kill>[B<!>] [I<signal-number>|I<signal-name>]

Kill execution of program being debugged.

Equivalent of C<kill('KILL', $$)>. This is an unmaskable
signal. Use this when all else fails, e.g. in thread code, use this.

If you are in interactive mode, you are prompted to confirm killing.
However when this command is aliased from a command ending in C<!>, no 
questions are asked.

I<Examples:> 

 kill  
 kill KILL # same as above
 kill -9   # same as above
 kill  9   # same as above
 kill! 9   # same as above, but no questions asked
 kill unconditionally # same as above
 kill TERM # Send "TERM" signal

See also C<quit>

=head4 Restart execution (restart)

B<restart>

Restart debugger and program via an exec call.

See also C<show args> for the exact invocation that will be used.

=head3 Examining data

=over

=item * 

L</"Evaluate Perl code (eval)">

=item *

L</"Recursively Debug into Perl code">

=back 

=head4 Evaluate Perl code (eval)

B<eval>[B<@$>][B<?>] [I<Perl-code>]

Run I<Perl-code> in the context of the current frame.

If no string is given after the word "eval", we run the string from
the current source code about to be run. If the "eval" command ends ?
(via an alias) and no string is given we try to pick out a useful
expression in the line.

Normally eval assumes you are typing a statement, not an expression;
the result is a scalar value. However you can force the type of the result
by adding the appropriate sigil C<@>, or C<$>.

I<Examples:>

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

=head4 Recursively Debug into Perl code (debug)

B<debug> I<Perl-code>

Recursively debug I<Perl-code>.

The level of recursive debugging is shown in the prompt. For example
C<((trepan.pl))> indicates one nested level of debugging.

I<Examples:>

 debug finonacci(5)   # Debug fibonacci function
 debug $x=1; $y=2;    # Kind of pointless, but doable.

=head3 Making the program stop at certain points

A I<Breakpoint> is a way to have the program stop at a pre-determined
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

L</"Set a breakpoint (break)">

=item *

L</"Set a temporary breakpoint (tbreak)">

=item *

L</"Add or modify a condition on a breakpoint (condition)">

=item *

L</"Delete some breakpoints (delete)">

=item *

L</"Enable some breakpoints (enable)">

=item *

L</"Disable some breakpoints (disable)">

=item *

L</"Set an action before a line is executed (action)">

=item *

L</"Stop when an expression changes value (watch)">

=back

=head4 Set a breakpont (break)

B<break> [I<location>] [B<if> I<condition>]

Set a breakpoint. If I<location> is given use the current stopping
point. An optional condition may be given.

I<Examples:>

 break                  # set a breakpoint on the current line
 break gcd              # set a breakpoint in function gcd
 break gcd if $a == 1   # set a breakpoint in function gcd with 
                        # condition $a == 1
 break 10               # set breakpoint on line 10

When a breakpoint is hit the event icon is C<xx>.

See also C<help breakpoints>.

=head4 Set a temporary breakpoint (tbreak)

B<tbreak> [I<location>]

Set a one-time breakpoint. The breakpoint is removed after it is hit.
If no location is given use the current stopping point.

I<Examples:>

   tbreak
   tbreak 10               # set breakpoint on line 10

When a breakpoint is hit the event icon is C<x1>.

See also C<break> and C<help breakpoints>.

=head4 Add or modify a condition on a breakpoint (condition)

B<condition> I<bp-number> I<Perl-expression>

I<bp-number> is a breakpoint number.  I<perl-expresion> is a Perl
expression which must evaluate to true before the breakpoint is
honored.  If I<perl-expression> is absent, any existing condition is removed;
i.e., the breakpoint is made unconditional.

I<Examples:>

   condition 5 x > 10  # Breakpoint 5 now has condition x > 10
   condition 5         # Remove above condition

See also "break", "enable" and "disable".

=head4 Delete some breakpoints (delete)

B<delete> [I<bp-number> [I<bp-number>...]]  

Delete some breakpoints.

Arguments are breakpoint numbers with spaces in between. To delete
all breakpoints, give no arguments.  

See also the C<clear> command which clears breakpoints by line number
and C<info break> to get a list of breakpoint numbers.

=head4 Enable some breakpoints (enable)

B<enable> I<num> [I<num> ...]
    
Enables breakpoints, watch expressions or actions given as a space
separated list of numbers which may be prefaces with an 'a', 'b', or 'w'.
The prefaces are interpreted as follows:

=over

=item a -- action number

=item b -- breakpoint number

=item w -- watch expression number

=back

If I<num> is starts with a digit, I<num> is taken to be a breakpoint number.

=head4 Disable some breakpoints (disable)

B<disable> I<bp-number> [I<bp-number> ...]
    
Disables the breakpoints given as a space separated list of breakpoint
numbers. See also C<info break> to get a list of breakpoints

=head4 Set an action before a line is executed (action)

B<action> I<position> I<Perl-statement>

Set an action to be done before the line is executed. If line is
C<.>, set an action on the line about to be executed. The sequence
of steps taken by the debugger is:

=over

=item 1. check for a breakpoint at this line 

=item 2. print the line if necessary (tracing) 

=item 3. do any actions associated with that line 

=item 4. prompt user if at a breakpoint or in single-step 

=item 5. evaluate line 

=back

For example, this will print out the value of C<$foo> every time line
53 is passed:

=head4 Stop when an expression changes value (watch)

B<watch> I<Perl-expression>

Stop very time I<Perl-expression> changes from its prior value.

I<Examples:>

 watch $a  # enter debugger when the value of $a changes
 watch scalar(@ARGV))  # enter debugger if size of @ARGV changes.

=head3 Examining the call stack

The commands in this section show the call stack and let set a
reference for the default call stack which other commands like C<list>
or C<break> use as a position when one is not specified.

The most recent call stack entry is 0. Except for the relative motion
commands C<up> and C<down>, you can refer to the oldest or top-level
stack entry with -1 and negative numbers refer to the stack from the
other end.

Beware that in contrast to debuggers in other programming languages,
Perl really doesn't have an easy way for one to evaluate statements
and expressions other than at the most recent call stack.  There are
ways to see lexical variables I<my> and I<our>, however localized
variables which can hide global variables and other lexicals variables
can be problematic.

=over

=item *

L</"Print all or parts of the call stack (backtrace)">

=item *

L</"Select a call frame (frame)">

=item *

L</"Move to a more recent frame (up)">

=item *

L</"Move to a less recent frame (down)">

=back

=head4 Print all or parts of the call stack (backtrace)

B<backtrace> [I<count>]

Print a stack trace, with the most recent frame at the top. With a
positive number, print at most many entries. 

In the listing produced, an arrow indicates the 'current frame'. The
current frame determines the context used for many debugger commands
such as source-line listing or the C<edit> command.

I<Examples:>

 backtrace    # Print a full stack trace
 backtrace 2  # Print only the top two entries


=head4 Select a call frame (frame)

B<frame> [I<frame-number>]

Change the current frame to frame I<frame-number> if specified, or the
most-recent frame, 0, if no frame number specified.

A negative number indicates the position from the other or
least-recently-entered end.  So C<frame -1> moves to the oldest frame.

I<Examples:>

    frame     # Set current frame at the current stopping point
    frame 0   # Same as above
    frame .   # Same as above. 'current thread' is explicit.
    frame . 0 # Same as above.
    frame 1   # Move to frame 1. Same as: frame 0; up
    frame -1  # The least-recent frame

=head4 Move to a more recent frame (up)

B<up> [I<count>]

Move the current frame up in the stack trace (to an older frame). 0 is
the most recent frame. If no count is given, move up 1.

=head4 Move to a less recent frame (down)

B<down> [I<count>]

Move the current frame down in the stack trace (to a newer frame). 0
is the most recent frame. If no count is given, move down 1.

=head3 Support facilities

=over

=item *

L</"Define an alias (alias)">

=item *

L</"Remove an alias (unalias)">

=item *

L</"Define a macro (macro)">

=item *

L</"Allow remote connections (server)">

=item *

L</"Run debugger commands from a file (source)">

=item *

L</"Load or Reload something Perlish">

L</"Modify parts of the Debugger Environment">

=back

=head4 Define an alias

B<alias> I<alias> I<command>

Add alias I<alias> for a debugger command I<command>.  

Add an alias when you want to use a command abbreviation for a command
that would otherwise be ambigous. For example, by default we make C<s>
be an alias of C<step> to force it to be used. Without the alias, C<s>
might be C<step>, C<show>, or C<set>, among others.

B<Examples:>

 alias cat list   # "cat file.pl" is the same as "list file.pl"
 alias s   step   # "s" is now an alias for "step".
                  # The above examples done by default.

For more complex definitions, see C<macro>.
See also C<unalias> and C<show alias>.

=head4 Remove an unalias

B<unalias> I<alias1> [I<alias2> ...]

Remove alias I<alias1> and so on.

B<Example:>

 unalias s  # Remove 's' as an alias for 'step'

See also C<alias>.


=head4 Define a debugger macro

B<macro> I<macro-name> B<sub {> ... B<}>

Define I<macro-name> as a debugger macro. Debugger macros get a list of
arguments which you supply without parenthesis or commas. See below
for an example.

The macro (really a Perl anonymous subroutine) should return either a
string or an array reference to a list of strings. The string in both
cases are strings of debugger commands.  If the return is a string,
that gets tokenized by a simple C<split(/ /, $string)>.  Note that
macro processing is done right after splitting on C<;;> so if the macro
returns a string containing C<;;> this will not be handled on the
string returned.

If instead, a reference to a list of strings is returned, then the
first string is shifted from the array and executed. The remaining
strings are pushed onto the command queue. In contrast to the first
string, subsequent strings can contain other macros. Any C<;;> in those
strings will be split into separate commands.

B<Examples:>

The below creates a macro called I<fin+> which issues two commands
C<finish> followed by C<step>:

 macro fin+ sub{ ['finish', 'step']}

If you wanted to parameterize the argument of the C<finish> command
you could do it this way:

  macro fin+ sub{ \
                  ['finish', 'step ' . (shift)] \
                }

Invoking with: 

  fin+ 3

would expand to C<["finish", "step 3"]>

If you were to add another parameter, note that the invocation is like
you use for other debugger commands, no commas or parenthesis. That is:

 fin+ 3 2

rather than C<fin+(3,2)> or C<fin+ 3, 2>.

See also C<info macro>.

=head4 Gently exit debugged program (quit)

B<quit>[B<!>] [B<unconditionally>] [I<exit-code>]

=head4 Allow remote debugger connections (server)

B<server> [I<options>]

options: 

    -p | --port NUMBER
    -a | --address

Suspends interactive debugger session and puts debugger in server mode
which opens a socket for debugger connections

=head4 Run debugger commands from a file (source)

B<source> [I<options>] I<file>

options: 

    -q | --quiet | --no-quiet
    -c | --continue | --no-continue
    -Y | --yes | -N | --no
    -v | --verbose | --no-verbose

Read debugger commands from a file named I<file>.  Optional C<-v> switch
causes each command in FILE to be echoed as it is executed.  Option C<-Y>
sets the default value in any confirmation command to be 'yes' and C<-N>
sets the default value to 'no'.

Option C<-q> will turn off any debugger output that normally occurs in
the running of the program.

An error in any command terminates execution of the command file
unless option C<-c> or C<--continue> is given.

=head4 Load or Reload something Perlish (load)

Sometimes in the middle of debugging you would like to make a change
to a Perl module -- perhaps you've found a bug -- and start using that.
If the change is inside a Perl module, you can use the command
C<load module>:

B<load module> {I<Perl-module-file>}

Another thing that can occur especially if using L<Enbugger> is that
the source to Perl code is not cached inside the debugger and so you
can't set a breakpoint on lines in that module. C<load source> can be
used to rectify this. However this is a bit experimenta. There may
still be a problem in making sure that debugging turned on when
tracing inside of that source.

B<load source> {I<Perl-source_file>}

Finally, if you have debugger commands of your own or if you change a
debugger command, you can force a reread of that debugger command
using C<load command>.

B<load commmand> {I<file-or-directory-name-1> [I<file-or-directory-name-2>...]}

=head4 Modify parts of the Debugger Environment (set, show)

There are many parts of the debugger environment you can change, like
the print line width, whether you want syntax highlighting or not and
so on. These fall under C<set> commands. C<show> commands show you
values that have been set. In fact, many of the C<set> commands finish
by runnin the corresponding "show" to echo you see what you've just
set.

B<Set commands>

=over

=item abbrev  

Set to allow unique abbreviations of commands

=item auto

Set controls for some "automatic" default behaviors

=item basename 

Set to show only file basename in showing file names

=item confirm 

Set whether to confirm potentially dangerous operations.

=item debug 

Set debugging controls

=item different

Set to make sure 'next/step' move to a new position.

=item display 

Set display attributes

=item evaldisplay

Set whether we use terminal highlighting

=item max 

Set maximum length sizes of various things

=item return 

Set the value about to be returned

=item timer 

Set to show elapsed time between debugger events

=item trace 

Set tracing of various sorts.

=item variable 

Set a I<my> or I<our> variable

=back

B<Show commands>

=over

=item abbrev 

Show whether we allow abbreviated debugger command names

=item aliases 

Show defined aliases

=item args 

Arguments to restart program

=item auto

Show controls for things with some sort of "automatic" default behavior

=item basename 

Show only file basename in showing file names

=item confirm 

Show confirm potentially dangerous operations setting

=item debug 

Show debugging controls

=item different

Show status of 'set different'

=item display 

Show display-related controls

=item evaldisplay

Show whether we use terminal highlighting

=item interactive

Show whether debugger input is a terminal

=item max 

Show "maximum length" settings

=item timer 

Show status of the timing hook

=item trace 

Set tracing of various sorts

=item version 

Show debugger name and version

=back

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

=head2 Debugger Command Examples

=head3 Commenting

 # This line does nothing. It is a comment and is useful
 # in debugger command files.
      # any amount of leading space is also ok

=head4 Splitting Commands
 
The following runs two commands: C<info program> and C<list>

 info program;; list 

The following gives a syntax error since C<;;> splits the line and the
simple debugger parse then thinks that the quote (") is not closed.

 print "hi ;;-)\n" 
 
If you have the Devel::Trepan::Shell plugin, you can go into a real
shell and run the above. 

=head4 Command Continuation

If you want to continue a command on the next line use C<\> at the end
of the line. For example:

 eval $x = "This is \
 a multi-line string"

The string in variable C<$x> will have a C<\n> before the article "a".

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

L<Devel::Callsite> allows you to see the exact location of where you are stopped. 

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
