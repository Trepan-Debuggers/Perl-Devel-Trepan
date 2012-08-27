# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org> 
# Part of Trepan::CmdProcess that deails with alias routines
use rlib '../../..';

package Devel::Trepan::CmdProcessor;

sub add_alias($$$) {
    my ($self, $command_name, $alias, $cmd_str) = @_;

    # Update array inside command name
    my $cmd_alias_ref = $self->{commands}{$command_name}{aliases};
    push @$cmd_alias_ref, $alias;

    # Upate aliases hash
    $self->{aliases}{$alias} = $cmd_str;
}

sub remove_alias($$$) {
    my ($self, $command_name, $alias) = @_;

    # Update array inside command name
    my $cmd_alias_ref = $self->{commands}{$command_name}{aliases};
    my @new_aliases = grep(($alias ne $_), @$cmd_alias_ref);
    $self->{commands}{$command_name}{aliases} = \@new_aliases;
    
    # Upate aliases hash
    delete $self->{aliases}{$alias};
}

1;
