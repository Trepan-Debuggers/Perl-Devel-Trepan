# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2014 Rocky Bernstein <rocky@cpan.org>

# Part of Devel::Trepan::CmdProcessor that loads up debugger commands from
# builtin and user directories.
# Sets @commands, @aliases, @macros
use rlib '../../..';

package Devel::Trepan::CmdProcessor;
$Load_seen = 1;
use warnings; use strict;
no warnings 'redefine';

use File::Spec;
use File::Basename;
use Cwd 'abs_path';

# "initialize" for multi-file class. Called from
# Devel::Trepan::CmdProcessor->new in CmdProcessor.pm
sub load_cmds_initialize($)
{
    my $self = shift;
    $self->{commands} = {};
    $self->{aliases}  = {};
    $self->{macros}   = {};

    my @cmd_dirs = (
        File::Spec->catfile(dirname(__FILE__), 'Command'),
        @{$self->{settings}{cmddir}}
        );
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

sub load_debugger_command($$;$)
{
    my ($self, $command_file, $force) = @_;
    return unless -r $command_file;
    my $rc = '';
    eval { $rc = do $command_file; };
    if (!$rc or $rc eq 'Skip me!') {
        ;
    } elsif ($rc) {
        # Instantiate each Command class found by the above require(s).
        my $name = basename($command_file, '.pm');
        $self->setup_command($name);
    } else {
        $self->errmsg("Trouble reading ${command_file}: $@");
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
    #   $self ->errmsg("run_cmd argument Array should only contain strings. " .
    #                  "Got #{cmd_array.inspect}");
    #   return;
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
        $self->errmsg("Error instantiating $name");
        $self->errmsg($@);
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
}

1;
