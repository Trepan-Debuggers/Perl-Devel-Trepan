# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-
use strict; use warnings;

use Exporter;

package Devel::Trepan::CmdProcessor;

sub abbrev_stringify($$$) {
    my ($self, $name, $min_abbrev) = @_;
    sprintf "(%s)%s", substr($name, 0, $min_abbrev), substr($name, $min_abbrev);
}

# Return constant SHORT_HELP or build it from HELP
sub summary_help($$) {
    my ($self, $subcmd) = @_;
    my $short_help;
    if (defined $subcmd->{help} && !defined $subcmd->{short_help}) {
        my @lines = split("\n", $subcmd->{help});
        $short_help = $lines[0];
        $short_help = substr($short_help, 0, -1) if 
            '.' eq substr($short_help, -1, 1);
    } else {
        $short_help = $subcmd->{short_help};
    }

    sprintf('  %-13s -- %s', 
            $self->abbrev_stringify($subcmd->{name},
                                    $subcmd->{min_abbrev}),
            $short_help);
}

# We were given cmd without a subcommand; cmd is something
# like "show", "info" or "set". Generally this means list
# all of the subcommands.
sub summary_list($$$) {
    my ($self, $name, $subcmds) = @_;
    $self->section("List of ${name} commands (with minimum abbreviation in parenthesis):");
    foreach my $subcmd_name (sort keys %{$subcmds}) {
        # Some commands have lots of output.
        # they are excluded here because 'in_list' is false.
        $self->msg($self->summary_help($subcmds->{$subcmd_name}));
    }
}

# Error message when subcommand asked for but doesn't exist
sub undefined_subcmd($$$) {
    my ($self, $cmd, $subcmd) = @_;
    my $ambig = $self->{settings}->{abbrev} ? 'or ambiguous ' : '';
    $self->errmsg([sprintf('Undefined %s"%s" subcommand: "%s". ', $ambig, $cmd, $subcmd),
                   sprintf('Try "help %s *".', $cmd)]);
}

if (__FILE__ eq $0) {
    print abbrev_stringify('bogus-class', 'foo-command', 3), "\n";
}
1;
