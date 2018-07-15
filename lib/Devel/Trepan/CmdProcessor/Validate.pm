# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
# Trepan command input validation routines.  A String type is
# usually passed in as the argument to validation routines.

use strict; use warnings;
use Exporter;

use rlib '../../..';

package Devel::Trepan::CmdProcessor;

use Cwd 'abs_path';
use Devel::Trepan::DB::Breakpoint;
use Devel::Trepan::DB::LineCache;
no warnings 'redefine';

# require_relative '../app/cmd_parse'
# require_relative '../app/condition'
# require_relative '../app/file'
# require_relative '../app/thread'

# require_relative 'location' # for resolve_file_with_dir

#     attr_reader :file_exists_proc  # Like File.exists? but checks using
#                                    # cached files

# Check that arg is an Integer between opts->{min_value} and
# opts->{max_value}
sub get_an_int($$$)
{
    my ($self, $arg, $opts) = @_;
    $opts ||= {};
    my $ret_value = $self->get_int_noerr($arg);
    if (! defined $ret_value) {
        if ($opts->{msg_on_error}) {
            $self->errmsg($opts->{msg_on_error});
        } else {
            $self->errmsg("Expecting an integer, got: ${arg}.");
        }
        return undef;
    }
    if (defined($opts->{min_value}) and $ret_value < $opts->{min_value}) {
        my $msg = sprintf("Expecting integer value to be at least %d; got %d.",
                          $opts->{min_value}, $ret_value);
        $self->errmsg($msg);
        return undef;
    } elsif (defined($opts->{max_value}) and $ret_value > $opts->{max_value}) {
        my $msg = sprintf("Expecting integer value to be at most %d; got %d.",
                          $opts->{max_value}, $ret_value);
        $self->errmsg($msg);
        return undef;
    }
    return $ret_value;
}

use constant DEFAULT_GET_INT_OPTS => {
    min_value => 0, default => 1, cmdname => undef, max_value => undef
};
use Devel::Trepan::Util qw(hash_merge);

# # If argument parameter 'arg' is not given, then use what is in
# # $opts->{default}. If String 'arg' evaluates to an integer between
# # least min_value and at_most, use that. Otherwise report an
# # error.  If there's a stack frame use that for bindings in
# # evaluation.
# sub get_int($$;$)
# {
#     my ($self, $arg, $opts)= @_;
#     $opts ||={};

#     return $opts->{default} unless $arg;
#     $opts = hash_merge($opts, DEFAULT_GET_INT_OPTS);
#     my $val = $arg ? $self->get_int_noerr($arg) : $opts->{default};
#     unless ($val) {
#         if ($opts->{cmdname}) {
#           my $msg = sprintf("Command '%s' expects an integer; " +
#                             "got: %s.", $opts->{cmdname}, $arg);
#           $self->errmsg($msg);
#         } else {
#           $self->errmsg('Expecting a positive integer, got: ${arg}');
#         }
#         return undef;
#       }

#     if ($val < $opts->{min_value}) {
#         if ($opts->{cmdname}) {
#           my $msg = sprintf("Command '%s' expects an integer at least" .
#                           ' %d; got: %d.',
#                           $opts->{cmdname}, $opts->{min_value},
#                           $opts->{default});
#         $self->errmsg($msg);
#       } else {
#           my $msg = sprintf("Expecting a positive integer at least" .
#                             ' %d; got: %d',
#                             $opts->{min_value}, $opts->{default});
#           $self->errmsg($msg);
#         }
#         return undef;
#       elsif ($self->opts{max_value} and $val > $self->opts{max_value}) {
#           if ($self->opts{cmdname}) {
#               my $msg = sprintf("Command '%s' expects an integer at most" .
#                                 ' %d; got: %d', $opts->{cmdname},
#                                 $opts->{max_value}, $val);
#               $self->errmsg($msg);
#           }
#         } else {
#           my $msg = sprintf("Expecting an integer at most %d; got: %d",
#                             $opts->{:max_value}, $val);
#           $self->errmsg($msg);
#         }
#         return undef;
#       }
#       return $val
#     }

sub get_int_list($$;$)
{
    my ($self, $args, $opts) = @_;
    $opts = {} unless defined $opts;
    map {$self->get_an_int($_, $opts)} @{$args}; # .compact
}

# Eval arg and it is an integer return the value. Otherwise
# return undef;
sub get_int_noerr($$)
{
    my ($self, $arg) = @_;
    my $val = eval {
        no warnings 'all';
        eval($arg);
    };
    if (defined $val) {
        return $val =~ /^[+-]?\d+$/ ? $val : undef;
    } else {
        return undef;
    }
}

# Return true if arg is 'on' or 1 and false arg is 'off' or 0.
# Any other value is returns undef.
sub get_onoff($$;$$)
{
    my ($self, $arg, $default, $print_error) = @_;
    $print_error = 1 unless defined $print_error;
    unless (defined $arg) {
        unless (defined $default) {
            if ($print_error) {
                $self->errmsg("Expecting 'on', 1, 'off', or 0. Got nothing.");
                return undef;
            }
        }
        return $default
    }
    my $darg = lc $arg;
    return 1 if ($arg eq '1') || ($darg eq 'on');
    return 0 if ($arg eq '0') || ($darg eq'off');

    $self->errmsg("Expecting 'on', 1, 'off', or 0. Got: ${arg}.") if
        $print_error;
    return undef;
}

sub is_method($$)
{
    my ($self, $method_name) = @_;
    my ($filename, $fn, $line_num) = DB::find_subline($method_name) ;
    return !!$line_num;
}

# NOTE: this is slated to disappear
# parse: file line [rest...]
#        line [rest..]
#        fn [rest..]
# returns (filename, line_num, fn, rest)
# NOTE: Test for failure should only be on $line_num
sub parse_position($$;$)
{
    my ($self, $args, $validate_line_num) = @_;
    my @args = @$args;
    my $size = scalar @args;
    my $gobble_count = 0;
    $validate_line_num = 0 unless defined $validate_line_num;

    if (0 == $size) {
        no warnings 'once';
        return ($DB::filename, $DB::line, undef, 0, ());
    }
    my ($filename, $line_num, $fn);
    my $first_arg = shift @args;
    if ($first_arg =~ /^\d+$/) {
        $line_num = $first_arg;
        $filename = $DB::filename;
        $gobble_count = 1;
        $fn = undef;
    } else {
        ($filename, $fn, $line_num) = DB::find_subline($first_arg) ;
        unless ($line_num) {
            $filename = $first_arg;
            my $mapped_filename = map_file($filename);
            if (-r $mapped_filename) {
                if (scalar @args == 0) {
                    $line_num = 1;
                } else {
                    $line_num = shift @args;
                }
                unless ($line_num =~ /\d+/) {
                    $self->errmsg("Got filename $first_arg, " .
                                  "expecting $line_num to a line number");
                    return ($filename, undef, undef, 0, @args);
                }
            } else {
                $self->errmsg("Expecting $first_arg to be a file " .
                              "or function name");
                return ($filename, undef, $fn, 0, @args);
            }
        }
        $gobble_count = 1;
    }
    if ($validate_line_num) {
        local(*DB::dbline) = "::_<'$filename" ;
        if (!defined($DB::dbline[$line_num]) || $DB::dbline[$line_num] == 0) {
            $self->errmsg("Line $line_num of file $filename not a stopping line");
            return ($filename, undef, $fn, 0, @args);
        }
    }
    return ($filename, $line_num, $fn, $gobble_count, @args);
}

unless (caller) {
    no strict;
    require Devel::Trepan::DB;
    my @onoff = qw(1 0 on off);
    for my $val (@onoff) {
        printf "onoff(${val}) = %s\n", get_onoff('bogus', $val);
    }

    for my $val (qw(1 1E bad 1+1 -5)) {
        my $result = get_int_noerr('bogus', $val);
        $result = '<undef>' unless defined $result;
        print "get_int_noerr(${val}) = $result\n";
    }

    no warnings 'redefine';
    require Devel::Trepan::CmdProcessor;
    my $proc  = Devel::Trepan::CmdProcessor::new(__PACKAGE__);
    my @aref = $proc->get_int_list(['1+0', '3-1', '3']);
    print join(', ', @aref), "\n";

    @aref = $proc->get_int_list(['a', '2', '3']);
    print join(', ', @aref[1..2]), "\n";

    local @position = ();
    sub print_position() {
        my @call_values = caller(0);
        for my $arg (@position) {
            print defined($arg) ? $arg : 'undef';
            print "\n";
        }
        print "\n";
        return @call_values;
    }
    my @call_values = foo();

    $DB::package = 'main';
    print_position;
#     print '=' * 40
#     ['Array.map', 'Trepan::CmdProcessor.new',
#      'foo', 'cmdproc.errmsg'].each do |str|
#       print "#{str} should be method: #{!!cmdproc.method?(str)}"
#     }
#     print '=' * 40

#     # FIXME:
#     print "Trepan::CmdProcessor.allocate is: #{cmdproc.get_method('Trepan::CmdProcessor.allocate')}"

#     ['food', '.errmsg'].each do |str|
#       print "#{str} should be false: #{cmdproc.method?(str).to_s}"
#     }
#     print '-' * 20
#     p cmdproc.breakpoint_position('foo', true)
#     p cmdproc.breakpoint_position('@0', true)
#     p cmdproc.breakpoint_position("#{__LINE__}", true)
#     p cmdproc.breakpoint_position("#{__FILE__}   @0", false)
#     p cmdproc.breakpoint_position("#{__FILE__}:#{__LINE__}", true)
#     p cmdproc.breakpoint_position("#{__FILE__} #{__LINE__} if 1 == a", true)
#     p cmdproc.breakpoint_position("cmdproc.errmsg", false)
#     p cmdproc.breakpoint_position("cmdproc.errmsg:@0", false)
#     ### p cmdproc.breakpoint_position(%w(2 if a > b))
}

1;
