# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Trepan command input validation routines.  A String type is
# usually passed in as the argument to validation routines.

use strict; use warnings;
use Exporter;

use feature 'switch';
use lib '../../..';

package Devel::Trepan::CmdProcessor;

use Cwd 'abs_path';
use Devel::Trepan::DB::Breakpoint;
use Devel::Trepan::DB::LineCache;

# require 'linecache'

# require_relative '../app/cmd_parse'
# require_relative '../app/condition'
# require_relative '../app/file'
# require_relative '../app/thread'

# require_relative 'location' # for resolve_file_with_dir
# require_relative 'virtual'

#     attr_reader :file_exists_proc  # Like File.exists? but checks using
#                                    # cached files

#     include Trepanning
#     include Trepan::ThreadHelper
#     include Trepan::Condition

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
    if ($opts->{min_value} and $ret_value < $opts->{min_value}) {
	my $msg = sprintf("Expecting integer value to be at least %d; got %d.",
			  $opts->{min_value}, $ret_value);
        $self->errmsg($msg);
        return undef;
    } elsif ($opts->{max_value} and $ret_value > $opts->{max_value}) {
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
# 	    my $msg = sprintf("Command '%s' expects an integer; " +
# 			      "got: %s.", $opts->{cmdname}, $arg);
# 	    $self->errmsg($msg);
#         } else {
# 	    $self->errmsg('Expecting a positive integer, got: ${arg}');
#         }
#         return undef;
#       }
      
#     if ($val < $opts->{min_value}) {
#         if ($opts->{cmdname}) {
#           my $msg = sprintf("Command '%s' expects an integer at least" .
# 			    ' %d; got: %d.', 
# 			    $opts->{cmdname}, $opts->{min_value}, 
# 			    $opts->{default});
# 	  $self->errmsg($msg);
# 	} else {
# 	    my $msg = sprintf("Expecting a positive integer at least" .
# 			      ' %d; got: %d', 
# 			      $opts->{min_value}, $opts->{default});  
# 	    $self->errmsg($msg);
#         }
#         return undef;
# 	elsif ($self->opts{max_value} and $val > $self->opts{max_value}) {
# 	    if ($self->opts{cmdname}) {
# 		my $msg = sprintf("Command '%s' expects an integer at most" .
# 				  ' %d; got: %d', $opts->{cmdname},
# 				  $opts->{max_value}, $val);
# 		$self->errmsg($msg);
# 	    }
#         } else {
# 	    my $msg = sprintf("Expecting an integer at most %d; got: %d",
# 			      $opts->{:max_value}, $val);
#           $self->errmsg($msg);
#         }
#         return undef;
#       }
#       return $val
#     }

#     sub get_int_list(args, opts={})
#       args.map{|arg| get_an_int(arg, opts)}.compact
#     }
    
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

#     sub get_thread_from_string(id_or_num_str)
#       if id_or_num_str == '.'
#         Thread.current
#       elsif id_or_num_str.downcase == 'm'
#         Thread.main
#       else
#         num = get_int_noerr(id_or_num_str)
#         if num
#           get_thread(num)
#         else
#           nil
#         }
#       }
#     }

#     # Return the instruction sequence associated with string
#     # OBJECT_STRING or nil if no instruction sequence
#     sub object_iseq(object_string)
#       iseqs = find_iseqs(ISEQS__, object_string)
#       # FIXME: do something if there is more than one.
#       if iseqs.size == 1
#          iseqs[-1]
#       elsif meth = method?(object_string)
#         meth.iseq
#       else
#         nil
#       }
#     rescue
#       nil
#     }

#     sub position_to_line_and_offset(iseq, filename, position, offset_type)
#       case offset_type
#       when :line
#         if ary = iseq.lineoffsets[position]
#           # Normally the first offset is a trace instruction and doesn't
#           # register as the given line, so we need to take the next instruction
#           # after the first one, when available.
#           vm_offset = ary.size > 1 ? ary[1] : ary[0]
#           line_no   = position
#         elsif found_iseq = find_iseqs_with_lineno(filename, position)
#           return position_to_line_and_offset(found_iseq, filename, position, 
#                                              offset_type)
#         elsif found_iseq = find_iseq_with_line_from_iseq(iseq, position)
#           return position_to_line_and_offset(found_iseq, filename, position, 
#                                              offset_type)
#         else
#           errmsg("Unable to find offset for line #{position}\n\t" + 
#                  "in #{iseq.name} of file #{filename}")
#           return [nil, nil]
#         }
#       when :offset
#         position = position.position unless position.kind_of?(Fixnum)
#         if ary=iseq.offset2lines(position)
#           line_no   = ary.first
#           vm_offset = position
#         else
#           errmsg "Unable to find line for offset #{position} in #{iseq}"
#           return [nil, nil]
#         }
#       when nil
#         vm_offset = 0
#         line_no   = iseq.offset2lines(vm_offset).first
#       else
#         errmsg "Bad parse offset_type: #{offset_type.inspect}"
#         return [nil, nil]
#       }
#       return [iseq, line_no, vm_offset]
#     }

#     # Parse a breakpoint position. On success return:
#     #   - the instruction sequence to use
#     #   - the line number - a Fixnum
#     #   - vm_offset       - a Fixnum
#     #   - the condition (by default 'true') to use for this breakpoint
#     #   - true condition should be negated. Used in *condition* if/unless
#     sub breakpoint_position(position_str, allow_condition)
#       break_cmd_parse = if allow_condition
#                           parse_breakpoint(position_str)
#                         else
#                           parse_breakpoint_no_condition(position_str)
#                         }
#       return [nil] * 5 unless break_cmd_parse
#       tail = [break_cmd_parse.condition, break_cmd_parse.negate]
#       meth_or_frame, file, position, offset_type = 
#         parse_position(break_cmd_parse.position)
#       if meth_or_frame
#         if iseq = meth_or_frame.iseq
#           iseq, line_no, vm_offset = 
#             position_to_line_and_offset(iseq, file, position, offset_type)
#           if vm_offset && line_no
#             return [iseq, line_no, vm_offset] + tail
#           }
#         else
#           errmsg("Unable to set breakpoint in #{meth_or_frame}")
#         }
#       elsif file && position
#         if :line == offset_type
#           iseq = find_iseqs_with_lineno(file, position)
#           if iseq
#             junk, line_no, vm_offset = 
#               position_to_line_and_offset(iseq, file, position, offset_type)
#             return [@frame.iseq, line_no, vm_offset] + tail
#           else
#             errmsg("Unable to find instruction sequence for" + 
#                    " position #{position} in #{file}")
#           }
#         else
#           errmsg "Come back later..."
#         }
#       elsif @frame.file == file 
#         line_no, vm_offset = position_to_line_and_offset(@frame.iseq, position, 
#                                                          offset_type)
#         return [@frame.iseq, line_no, vm_offset] + tail
#       else
#         errmsg("Unable to parse breakpoint position #{position_str}")
#       }
#       return [nil] * 5
#     }

# Return true if arg is 'on' or 1 and false arg is 'off' or 0.
# Any other value is returns undef.
sub get_onoff($$;$$) 
{
    my ($self, $arg, $default, $print_error) = @_;
    $print_error //= 1;
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

#     include CmdParser

#     sub get_method(meth)
#       start_binding = 
#         begin
#           @frame.binding
#         rescue
#           binding
#         }
#       if meth.kind_of?(String)
#         meth_for_string(meth, start_binding)
#       else
#         begin
#           meth_for_parse_struct(meth, start_binding)
#         rescue NameError
#           errmsg("Can't evaluate #{meth.name} to get a method")
#           return nil
#         }
#       }
#     }

#     # FIXME: this is a ? method but we return 
#     # the method value. 
#     sub method?(meth)
#       get_method(meth)
#     }

# parse_position
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
    $validate_line_num //= 0;

    if (0 == $size) {
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
	    my $mapped_filename = DB::LineCache::map_file($filename);
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


#     sub validate_initialize
#       ## top_srcdir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
#       ## @dbgr_script_iseqs, @dbgr_iseqs = filter_scripts(top_srcdir)
#       @file_exists_proc = Proc.new {|filename|
#         if LineCache.cached?(filename) || LineCache.cached_script?(filename) ||
#             (File.readable?(filename) && !File.directory?(filename))
#           true
#         else
#           matches = find_scripts(filename)
#           if matches.size == 1 
#             LineCache.remap_file(filename, matches[0])
#             true
#           else
#             false
#           }
#         }
#       }
#     }
#   }
# }

unless (caller) {
    no strict;
    require Devel::Trepan::DB;
    my @onoff = qw(1 0 on off);
    for my $val (@onoff) {
	printf "onoff(${val}) = %s\n", get_onoff('bogus', $val); 
    }
    
    for my $val (qw(1 1E bad 1+1 -5)) {
	my $result = get_int_noerr('bogus', $val);
	$result //= '<undef>';
	print "get_int_noerr(${val}) = $result\n";
    }
    
    require Devel::Trepan::CmdProcessor;
    my $proc  = Devel::Trepan::CmdProcessor->new;
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
	@position = $proc->parse_position([__FILE__, __LINE__], 0);
    print_position;
    @position = $proc->parse_position([__LINE__], 0);
    print_position;
#    @position = $proc->parse_position(['print_position'], 0);
#     print cmdproc.parse_position('@8').inspect
#     print cmdproc.parse_position('8').inspect
#     print cmdproc.parse_position("#{__FILE__} #{__LINE__}").inspect

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
#     p cmdproc.get_int_list(%w(1+0 3-1 3))
#     p cmdproc.get_int_list(%w(a 2 3))
}

1;
