# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
use feature ":5.10";  # Includes "state" feature.
# require 'tmpdir'

# Part of Trepan::CmdProcess that loads up debugger commands from
# builtin and user directories.  
# Sets @commands, @aliases, @macros
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
$Load_seen = 1;
use warnings;
use strict;

use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use Devel::Trepan::Complete;

# attr_reader   :aliases         # Hash[String] of command names
#                                # indexed by alias name
# attr_reader   :commands        # Hash[String] of command objects
#                                # indexed by name
# attr_reader   :macros          # Hash[String] of Proc objects 
#                                # indexed by macro name.
# attr_reader   :leading_str     # leading part of string. Used in 
#                                # command completion

  # "initialize" for multi-file class. Called from main.rb's "initialize".
sub load_cmds_initialize($)
{
    my $self = shift;
    $self->{commands} = {};
    $self->{aliases}  = {};
    $self->{macros}   = {};
    
    my @cmd_dirs = ( File::Spec->catfile(dirname(__FILE__), 'Command') );
    # push @cmd_dirs, $self->{settings}->{user_cmd_dir} if $self-settings->{user_cmd_dir}
    for my $cmd_dir (@cmd_dirs) {
	$self->load_debugger_commands($cmd_dir) if -d $cmd_dir;
    }
}

# Loads in debugger commands by require'ing each ruby file in the
# 'command' directory. Then a new instance of each class of the 
# form Trepan::xxCommand is added to @commands and that array
# is returned.
sub load_debugger_commands($$) 
{
    my ($self, $file_or_dir) = @_;
    if ( -d $file_or_dir ) {
	my $dir = abs_path($file_or_dir);
	# change $0 so it doesn't get in the way of __FILE__ eq $0
	# old_dollar0 = $0
	# $0 = ''
	for my $pm (glob(File::Spec->catfile($dir, '*.pm'))) {
	    $self->load_debugger_command($pm);
	}
	# $0 = old_dollar0
    } elsif (-r $file_or_dir) {
	$self->load_debugger_command($file_or_dir);
    } else {
      return;
    }
    return 1;
  }

sub load_debugger_command($$) 
{
    my ($self, $command_file) = @_;
    return unless -r $command_file;
    if (eval "require '$command_file'; 1") {
	# Instantiate each Command class found by the above require(s).
	my $name = basename($command_file, '.pm');
	$self->setup_command($name);
    } else {
	$self->errmsg("Trouble reading $command_file");
    }
}

# Looks up cmd_array[0] in @commands and runs that. We do lots of 
# validity testing on cmd_array.
sub run_cmd($$)
{
    my ($self, $cmd_array) = @_;
    unless ('ARRAY' eq ref $cmd_array) {
	my $ref_msg = ref($cmd_array) ? ", got: " . ref($cmd_array): '';
	$self->errmsg("run_cmd argument should be an Array reference$ref_msg");
	return;
    }
    # if ($cmd_array.detect{|item| !item.is_a?(String)}) {
    # 	$self ->errmsg("run_cmd argument Array should only contain strings. " .
    # 		       "Got #{cmd_array.inspect}");
    # 	return;
    # }
    if (0 == scalar @$cmd_array) {
	$self->errmsg("run_cmd Array should have at least one item");
	return;
    }
    my $cmd_name = $cmd_array->[0];
    if (exists($self->{commands}{$cmd_name})) {
	$self->{commands}{$cmd_name}->run($cmd_array);
    }
}

# sub save_commands(opts) 
# {
#     save_filename = opts[:filename] || 
#       File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname(['trepanning-save', '.txt'], nil))
#     begin
#       save_file = File.open(save_filename, 'w')
#     rescue => exc
#       errmsg("Can't open #{save_filename} for writing.")
#       errmsg("System reports: #{exc.inspect}")
#       return nil
#     }
#     save_file.print "#\n# Commands to restore trepanning environment\n#\n"
#     @commands.each do |cmd_name, cmd_obj|
#       cmd_obj.save_command if cmd_obj.respond_to?(:save_command)
#       next unless cmd_obj.is_a?(Trepan::SubcommandMgr)
#       cmd_obj.subcmds.subcmds.each do |subcmd_name, subcmd_obj|
#         save_file.print subcmd_obj.save_command if 
#           subcmd_obj.respond_to?(:save_command)
#         next unless subcmd_obj.is_a?(Trepan::SubSubcommandMgr)
#         subcmd_obj.subcmds.subcmds.each do |subsubcmd_name, subsubcmd_obj|
#           save_file.print subsubcmd_obj.save_command if 
#             subsubcmd_obj.respond_to?(:save_command)
#         }
#       }
#     }
#     save_file.print "!FileUtils.rm #{save_filename.inspect}" if 
#       opts[:erase]
#     save_file.close

#     return save_filename
#   }

# Instantiate a Trepan::Command and extract info: the NAME, ALIASES
# and store the command in @commands.
sub setup_command($$) 
{
    my ($self, $name) = @_;
    my $cmd_obj;
    my $cmd_name = lc $name;
    my $new_cmd = "\$cmd_obj=Devel::Trepan::CmdProcessor::Command::${name}" .
	"->new(\$self, \$cmd_name); 1";
    if (eval $new_cmd) {
	# Add to list of commands and aliases.
	if ($cmd_obj->{aliases}) {
	    for my $a (@{$cmd_obj->{aliases}}) {
		$self->{aliases}{$a} = $cmd_name;
	    }
	}
	$self->{commands}{$cmd_name} = $cmd_obj;
    } else {
	$self->errmsg("Error instantiating $name")
    }
  }

# Handle initial completion. We draw from the commands, aliases,
# and macros for completion. However we won't include aliases which
# are prefixes of other commands.
sub complete($$$) 
{
    my ($self, $text, $line, $start, $end) = @_;
    $self->{leading_str} = $line;
    
    state ($last_line, $last_start, $last_end, @last_return, $last_token);
    $last_line //= '';  $last_start //= -1; $last_end //= -1; 
    $last_token //= '';
    $last_token = '' unless 
	$last_start < length($line) &&
	0 == index(substr($line, $last_start), $last_token);
    # print "\ntext: $text, line: $line, start: $start, end: $end\n";
    # print "\nlast_line: $last_line, last_start: $last_start, last_end: $last_end\n";
    my $stripped_line;
    ($stripped_line = $line) =~ s/\s*$//;
    if ($last_line eq $stripped_line) {
    	return @last_return;
    }
    ($last_line, $last_start, $last_end) = ($line, $start, $end);

    my @commands = sort keys %{$self->{commands}};
    my ($next_blank_pos, $token) = 
	Devel::Trepan::Complete::next_token($line, 0);
    if (!$token && !$last_token) { 
	@last_return = @commands;
	$last_token = $last_return[0];
	$last_line = $line . $last_token;
	$last_end += length($last_token);
	return (@commands);
    }

    $token ||= $last_token;
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
    	@last_return = sort map {$_->[0]} @match_pairs;
    	$last_token = $last_return[0];
    	if (defined($last_token)) {
    	    $last_line = $line . $last_token;
    	    $last_end += length($last_token);
    	}
    	return @last_return;
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
    # match_pairs.size == 1
    @last_return = $self->next_complete($line, $next_blank_pos, 
					$match_pairs[0]->[1], 
					$token);
    return (@last_return);
}

sub next_complete($$$$$)
{
    my($self, $str, $next_blank_pos, $cmd, $last_token) = @_;

    my $token;
    ($next_blank_pos, $token) = 
	Devel::Trepan::Complete::next_token($str, $next_blank_pos);
    return () if !$token && !$last_token;
    
    if ($cmd->can("complete_token_with_next")) {
	my @match_pairs = $cmd->complete_token_with_next($token);
	return () unless scalar @match_pairs;
	if ($next_blank_pos >= length($str)) {
	    return map {$_->[0]} @match_pairs;
	} else {
	    if (scalar @match_pairs == 1) {
		if ($next_blank_pos >= length($str) 
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
    } elsif (defined($cmd) &&  $cmd->can('complete')) {
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
    require Array::Columnize;
    my @cmds = sort keys(%{$cmdproc->{commands}});
    print Array::Columnize::columnize(\@cmds);
    my $sep = '=' x 20 . "\n";
    print $sep;
    my @aliases = sort keys(%{$cmdproc->{aliases}});
    print Array::Columnize::columnize(\@aliases);
    print $sep;

    $cmdproc->run_cmd('foo');  # Invalid - not an Array
    $cmdproc->run_cmd([]);     # Invalid - empty Array
    $cmdproc->run_cmd(['help', '*']);
    # $cmdproc->run_cmd(['list', 5]);  # Invalid - nonstring arg
    printf "complete('s') => %s\n", join(',  ', $cmdproc->complete("s", 's', 0, 1));
    printf "complete('') => %s\n", join(',  ', $cmdproc->complete("", '', 0, 1));
    printf "complete('help se') => %s\n", join(',  ', $cmdproc->complete("help se", 'help se', 0, 1));

sub complete_it($)
{
    my $str = shift;
    my @c = $cmdproc->complete($str, $str, 0, length($str));
    printf "complete('$str') => %s\n", join(', ', @c);
    return @c;
}

    my @c = complete_it("set ");
    @c = complete_it("help set base");
    @c = complete_it("set basename on ");
}

1;
