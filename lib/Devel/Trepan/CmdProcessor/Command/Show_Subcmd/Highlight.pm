# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2014 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Highlight;

use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

@ISA = qw(Devel::Trepan::CmdProcessor::Command::ShowBoolSubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subcmd::SUBCMD_VARS;

# =pod
#
# =head2 Synopsis:
#
# =cut
our $HELP = <<"EOH";
=pod

B<show highlight>

Show whether we use terminal highlighting

=head2 See also:

L<C<set highlight>|Devel::Trepan::CmdProcessor::Command::Set::Highlight>
=cut
EOH
our $SHORT_HELP = "Show whether we use terminal highlighting";
our $MIN_ABBREV = length('high');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $val = $proc->{settings}{highlight} || 'plain';
    my $mess;
    if ('plain' eq $val) {
	$mess = 'output set to not use terminal escape sequences';
    } elsif ('light' eq $val) {
	$mess = 'output set for terminal with escape sequences ' .
	    'for a light background';
    } elsif ('dark' eq $val) {
	$mess = ('output set for terminal with escape sequences ' .
		 'for a dark background')
    } else {
	$proc->errmsg(sprintf('Internal error: incorrect highlight setting %s', $val));
    }
    $proc->msg($mess);
}

unless (caller) {
  # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $parent = Devel::Trepan::CmdProcessor::Command::Set->new($proc, 'show');
    my $cmd = __PACKAGE__->new($parent, 'highlight');
    print $cmd->{help}, "\n";
    print "min args: ", $cmd->MIN_ARGS, "\n";
    print $cmd->run();
}

1;
