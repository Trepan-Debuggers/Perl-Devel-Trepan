# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014-2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine'; no warnings 'once';
use rlib '../../../../../..';

package Devel::Trepan::CmdProcessor::Command::Show::Display::Eval;
use Devel::Trepan::CmdProcessor::Command::Subcmd::Subsubcmd;

use strict;
use vars qw(@ISA @SUBCMD_VARS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
# Values inherited from parent
use vars @Devel::Trepan::CmdProcessor::Command::Subsubcmd::SUBCMD_VARS;

## FIXME: do automatically.
our $CMD  = 'show display eval';
our $HELP = <<"EOH";
B<show display eval> [B<long>]

Shows which of Data::Printer ('ddp'),
Data::Dumper ('dumper'), Data::Dumper::Concise,
Data::Dumper::Perltidy ('tidy') is used to format evaluation results.

For Data::Dumper, if B<long> is given the configuration will be show.

=head2 See also:

L<C<set display eval>|Devel::Trepan::CmdProcessor::Command::Set::Display::Eval>,
L<C<eval>|Devel::Trepan::CmdProcessor::Command::Eval>,
L<C<set auto eval>|Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval>,
L<C<set auto eval>|Devel::Trepan::CmdProcessor::Command::Set::Auto::Eval>,
L<Data::Dumper::Perltidy>, and
L<Data::Printer>.
EOH

our $SHORT_HELP = 'Show how the evaluation results are displayed';
our $MIN_ABBREV = length('ev');

sub run($$)
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $key  = $self->{subcmd_setting_key};
    my $val  = $proc->{settings}{$key};
    my $msg = sprintf "Eval result display style is %s.", $val;
    $proc->msg($msg);
    if ($val eq 'tidy') {
	$proc->msg("Perlidy options: " . $Data::Dumper::Perltidy::ARGV);
    } elsif ($val eq 'ddp') {
	my @args = @{$args};
	if (scalar @args > 3 && $args[3] eq 'long') {
	    $proc->msg("Data::Printer options:");
	    my $opts = Data::Printer::p($Data::Printer::properties);
	    $proc->msg($opts);
	}
    }
}

unless (caller) {
    # Demo it.
    # FIXME: DRY the below code
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new();
    my $subcmd  =  Devel::Trepan::CmdProcessor::Command::Show->new($cmdproc,
								   'show');
    my $dispcmd =  Devel::Trepan::CmdProcessor::Command::Show::Display->new($subcmd, 'display');
    my $cmd   =  Devel::Trepan::CmdProcessor::Command::Show::Display::Eval->new($dispcmd, 'eval');
    # Add common routine
    foreach my $field (qw(min_abbrev name)) {
	printf "Field %s is: %s\n", $field, $cmd->{$field};
    }
    $cmd->run(['show', 'display', 'eval']);
    $cmd->run(['show', 'display', 'eval', 'long']);
}

1;
