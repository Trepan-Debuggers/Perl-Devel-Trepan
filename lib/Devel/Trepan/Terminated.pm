# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
=head1 C<Devel::Trepan::Terminated>

Contains the C<at_exit> routine that the debugger uses to issue the
C<Debugged program terminated ...> message after the program completes.

=cut

# rocky: I'm copying what perl5db does here, which I suppose has some
# time-honored benefit. That doesn't mean though that I like it. FIXME!
package Devel::Trepan::Terminated;

sub at_exit {
    $DB::ready = 1;
    # The below is there to have something to look at in "list" command.
    "Debugged program terminated.  Use 'q' to quit or 'R' to restart.";
}

'Just another Perl module';
