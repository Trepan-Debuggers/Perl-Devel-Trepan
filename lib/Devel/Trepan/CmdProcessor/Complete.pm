# -*- coding: utf-8 -*-
# Copyright (C) 2014 Rocky Bernstein <rocky@cpan.org>

# Part of Devel::Trepan::CmdProcessor that loads up debugger commands from
# builtin and user directories.
# Top-level command completion routines.
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
use warnings; use strict;
no warnings 'redefine';
use Devel::Trepan::Complete;

my $_list_complete_i = -1;
sub list_complete($$$)
{
    my($self, $text, $state) = @_;
    state $_list_complete_i = -1; # clear counter at the first call
    $_list_complete_i++;;
    my $cw = $self->{completions};
    for (; $_list_complete_i <= $#{$cw}; $_list_complete_i++) {
        return $cw->[$_list_complete_i]
            if ($cw->[$_list_complete_i] =~ /^\Q$text/);
    }
    return undef;
};


my ($_last_line, $_last_start, $_last_end, @_last_return, $_last_token);
# Handle initial completion. We draw from the commands, aliases,
# and macros for completion. However we won't include aliases which
# are prefixes of other commands.
sub complete($$$$$)
{
    my ($self, $text, $line, $start, $end) = @_;
    $self->{leading_str} = $line;

    $_last_line  = '' unless defined $_last_line;
    $_last_start = -1 unless defined $_last_start;
    $_last_end   = -1 unless defined $_last_end;
    $_last_token = '' unless defined $_last_token;
    $_last_token = '' unless
        $_last_start < length($line) &&
        0 == index(substr($line, $_last_start), $_last_token);
    # print "\ntext: $text, line: $line, start: $start, end: $end\n";
    # print "\nlast_line: $_last_line, last_start: $_last_start, last_end: $last_end\n";
    my $stripped_line;
    ($stripped_line = $line) =~ s/\s*$//;
    if ($_last_line eq $stripped_line && $stripped_line) {
        $self->{completions} = \@_last_return;
        return @_last_return;
    }
    ($_last_line, $_last_start, $_last_end) = ($line, $start, $end);

    my @commands = sort keys %{$self->{commands}};
    my ($next_blank_pos, $token) =
        Devel::Trepan::Complete::next_token($line, 0);
    if (!$token && !$_last_token) {
        @_last_return = @commands;
        $_last_token = $_last_return[0];
        $_last_line = $line . $_last_token;
        $_last_end += length($_last_token);
        $self->{completions} = \@_last_return;
        return (@commands);
    }

    $token ||= $_last_token;
    my @match_pairs = complete_token_with_next($self->{commands}, $token);

    my $match_hash = {};
    for my $pair (@match_pairs) {
        $match_hash->{$pair->[0]} = $pair->[1];
    }

    my @alias_pairs = complete_token_filtered_with_next($self->{aliases},
                                                        $token, $match_hash,
                                                        $self->{commands});
    push @match_pairs, @alias_pairs;
    if ($next_blank_pos >= length($line)) {
        @_last_return = sort map {$_->[0]} @match_pairs;
        $_last_token = $_last_return[0];
        if (defined($_last_token)) {
            $_last_line = $line . $_last_token;
            $_last_end += length($_last_token);
        }
	if (scalar @_last_return == 0 && $self->{settings}{autoeval}) {
	    return Devel::Trepan::Complete::complete_function($stripped_line);
	}
        $self->{completions} = \@_last_return;
        return @_last_return;
    } else {
	for my $pair (@alias_pairs) {
	    $match_hash->{$pair->[0]} = $pair->[1];
	}
    }
    if (scalar(@match_pairs) > 1) {
        # FIXME: figure out what to do here.
        # Matched multiple items in the middle of the string
        # We can't handle this so do nothing.
        return ();
      # return match_pairs.map do |name, cmd|
      #   ["#{name} #{args[1..-1].join(' ')}"]
      # }
    }
    # scalar @match_pairs == 1
    @_last_return = $self->next_complete($line, $next_blank_pos,
                                        $match_pairs[0]->[1],
                                        $token);

    $self->{completions} = \@_last_return;
    if (scalar @_last_return == 0 && $self->{settings}{autoeval}) {
	return Devel::Trepan::Complete::complete_function($stripped_line);
    }

    return @_last_return;
}

sub next_complete($$$$$)
{
    my($self, $str, $next_blank_pos, $cmd, $last_token) = @_;

    my $token;
    ($next_blank_pos, $token) =
        Devel::Trepan::Complete::next_token($str, $next_blank_pos);
    return () if !$token && !$last_token;
    return () unless defined($cmd);
    return @{$cmd} if ref($cmd) eq 'ARRAY';
    return $cmd->($token) if (ref($cmd) eq 'CODE');

    if ($cmd->can("complete_token_with_next")) {
        my @match_pairs = $cmd->complete_token_with_next($token);
        return () unless scalar @match_pairs;
        if ($next_blank_pos >= length($str)) {
            return map {$_->[0]} @match_pairs;
        } else {
            if (scalar @match_pairs == 1) {
                if ($next_blank_pos == length($str)-1
                    && ' ' ne substr($str, length($str)-1)) {
                    return map {$_->[0]} @match_pairs;
                } elsif ($match_pairs[0]->[0] eq $token) {
                    return $self->next_complete($str, $next_blank_pos,
                                                $match_pairs[0]->[1],
                                                $token);
                } else {
                    return ();
                }
            } else {
                # FIXME: figure out what to do here.
                # Matched multiple items in the middle of the string
                # We can't handle this so do nothing.
                return ();
            }
        }
    } elsif ($cmd->can('complete')) {
        my @matches = $cmd->complete($token);
        return () unless scalar @matches;
        if (substr($str, $next_blank_pos) =~ /\s*$/ ) {
            if (1 == scalar(@matches) && $matches[0] eq $token) {
                # Nothing more to complete.
                return ();
            } else {
                return @matches;
            }
        } else {
            # FIXME: figure out what to do here.
            # Matched multiple items in the middle of the string
            # We can't handle this so do nothing.
            return ();
        }
    } else {
        return ();
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $cmdproc = Devel::Trepan::CmdProcessor->new;
    # $cmdproc->run_cmd(['list', 5]);  # Invalid - nonstring arg
    printf "complete('s') => %s\n", join(',  ', $cmdproc->complete("s", 's', 0, 1));
    printf "complete('') => %s\n", join(',  ', $cmdproc->complete("", '', 0, 1));
    printf "complete('help se') => %s\n", join(',  ', $cmdproc->complete("help se", 'help se', 0, 1));

    eval {
        sub complete_it($$) {
            my ($cmdproc, $str) = @_;
            my @c = $cmdproc->complete($str, $str, 0, length($str));
            printf "complete('$str') => %s\n", join(', ', @c);
            return @c;
                        }
            };

    my @c = complete_it($cmdproc, "set ");
    @c = complete_it($cmdproc, "help set base");
    @c = complete_it($cmdproc, "set basename on ");
}

1;
