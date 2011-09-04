# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict;
use Exporter;
use warnings;
no warnings 'redefine';
use lib '../../..';
# require_relative '../app/default'

package Devel::Trepan::CmdProcessor;
use English;

#require 'pathname'  # For cleanpath
use File::Basename;
use Devel::Trepan::DB::LineCache;
#require_relative 'msg'
#require_relative 'frame'
#require_relative '../app/file'

my $EVENT2ICON = {
    'brkpt'          => 'xx',
    'tbrkpt'         => 'x1',
    'call'           => '->',
    'debugger-call'  => ':o',
    'end'            => '-|',
    'line'           => '--',
    'interrupt'      => 'oo',
    'signal'         => '!!',
    'return'         => '<-',
    'unknown'        => '?!',
};

sub canonic_file($$;$)
{
    my ($self, $filename, $resolve) = @_;
    $resolve //= 1;

    # For now we want resolved filenames 
    if ($self->{settings}{basename}) {
	return basename($filename);
    } elsif ($resolve) {
    	$filename = DB::LineCache::map_file($filename);
    	return abs_path $filename;
    } else {
	return $filename;
    }
}

# Return the text to the current source line.
sub current_source_text(;$)
{
    my ($self, $opts) = @_;
    $opts //= {};
    my $filename    = $self->{frame}{file};
    my $line_number = $self->{frame}{line};
    my $text;
    { local $WARNING=0;
      ## $text = $DB::dbline[$DB::lineno]; chomp($text);
      $text = DB::LineCache::getline($filename, $line_number, $opts); 
    }
    return $text;
}
  
# sub resolve_file_with_dir($$)
# {
#     my ($self, $path_suffix) = @_;
#     for my $dir (split(/:/, $self->settings{directory})) {
#         if ('$cwd' eq $dir) {
# 	    $dir = Dir.pwd;
#         } elsif ('$cdir' eq $dir) {
# 	    Rubinius::OS_STARTUP_DIR
# 	}
# 	next unless $dir && !-d ($dir);
# 	my $try_file = File.join(dir, path_suffix);
# 	return $try_file if -f $try_file;
#     }
#     return undef;
# }
  
# # Get line +line_number+ from file named +filename+. Return "\n"
# # there was a problem. Leading blanks are stripped off.
# sub line_at(filename, line_number, 
# 	    opts = {
#                 :reload_on_change => @settings[:reload],
#                 :output => @settings[:highlight]
# 	    })
#     # We use linecache first to give precidence to user-remapped
#     # file names
#     line = LineCache::getline(filename, line_number, opts)
#     unless line
#       # Try using search directories (set with command "directory")
#       if filename[0..0] != File::SEPARATOR
#         try_filename = resolve_file_with_dir(filename) 
#         if try_filename && 
#             line = LineCache::getline(try_filename, line_number, opts) 
#           LineCache::remap_file(filename, try_filename)
#         }
#       }
#     }
#     return nil unless line
#     return line.lstrip.chomp
#   }
  
#   sub loc_and_text(loc, opts=
#                    {:reload_on_change => @settings[:reload],
#                      :output => @settings[:highlight]
#                    })
    
#     vm_location = @frame.vm_location
#     filename = vm_location.method.active_path
#     line_no  = @frame.line
#     static   = vm_location.static_scope
#     opts[:compiled_method] = top_scope(@frame.method)
    
#     if @frame.eval?
#       file = LineCache::map_script(static.script)
#       text = LineCache::getline(static.script, line_no, opts)
#       loc += " remapped ${canonic_file(file)}:${line_no}"
#     else
#       text = line_at(filename, line_no, opts)
#       map_file, map_line = LineCache::map_file_line(filename, line_no)
#       if [filename, line_no] != [map_file, map_line]
#         loc += " remapped ${canonic_file(map_file)}:${map_line}"
#       }
#     }
#     [loc, line_no, text]
#   }
  
sub format_location($;$$$)
{
    my ($self, $event, $frame, $frame_index) = @_;
    $event       //= $self->{event};
    $frame       //= $self->{frame};
    $frame_index //= $self->{frame_index};
    my $text       = undef;
    my $ev         = '  ';
    if (defined($self->{event}) || 0 == $frame_index) {
    	$ev = $EVENT2ICON->{$self->{event}};
    }

    $self->{line_no}  = $self->{frame}{line};
    
    my $loc = $self->source_location_info;
    # $loc, @line_no, text = loc_and_text(loc)
    "${ev} (${loc})"
}

sub print_location($;$)
{
    my ($self,$opts) = @_;
    $opts //= {output => $self->{settings}{highlight}};
    my $loc  = $self->format_location;
    $self->msg(${loc});

    my $text = $self->current_source_text($opts);
    if ($text) {
	$self->msg($text, {unlimited => 1});
    }
  }
  
sub source_location_info($)
{
    my $self = shift;
    # if (@frame.eval?)
    my $canonic_filename;
    #    'eval ' + safe_repr(@frame.eval_string.gsub("\n", ';').inspect, 20)
    #  else
    $canonic_filename = $self->canonic_file($self->{frame}->{file}, 0);
    # }
    my $line_number = $self->{frame}->{line} || 0;
    return "${canonic_filename}:${line_number}";
} 

unless (caller()) {
    # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc  = Devel::Trepan::CmdProcessor->new;
    sub foo() {
	my @call_values = caller(0);
	return @call_values;
    }
    my @call_values = foo();
    $proc->frame_setup(\@call_values, 0);
    $proc->{event} = 'return';
    print $proc->format_location, "\n";
    print $proc->current_source_text({output=>'term'}), "\n";
    # See if cached line is the same
    print $proc->current_source_text({output=>'term'}), "\n";
    # Try unhighligted line.
    print $proc->current_source_text, "\n";
}

1;
