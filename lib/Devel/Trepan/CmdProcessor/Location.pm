# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict;
use Exporter;
use warnings;
no warnings 'redefine'; no warnings 'once';
use lib '../../..';
# require_relative '../app/default'

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );
use Cwd 'abs_path';

use File::Basename;
use File::Spec;
use Devel::Trepan::DB::LineCache;

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
    	return abs_path($filename) || $filename;
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
    $text = DB::LineCache::getline($filename, $line_number, 
						  $opts); 
    return $text;
}
  
sub resolve_file_with_dir($$)
{
    my ($self, $path_suffix) = @_;
    my @dirs = @$self->{settings}{directory};
    for my $dir (split(/:/, @dirs)) {
        if ('$cwd' eq $dir) {
	    $dir = `pwd`;
        } elsif ('$cdir' eq $dir) {
	    $dir = $DB::OS_STARTUP_DIR;
	}
	next unless $dir && !-d ($dir);
	my $try_file = File::Spec->catfile($dir, $path_suffix);
	return $try_file if -f $try_file;
    }
    return undef;
}
  
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

sub text_at($;$) 
{
    my ($self, $opts) = @_;
    $opts //= {
	reload_on_change => $self->{settings}{reload},
	output           => $self->{settings}{highlight},
    };

    my $line_no = $self->line();
    my $text;
    my $filename = $self->filename();
    if (DB::LineCache::filename_is_eval($filename)) {
	if ($DB::filename eq $filename) {
	    { 
		# Some lines in @DB::line might not be defined.
		# So we have to turn off strict here.
		no warnings;
		my $string = join("\n", @DB::dbline);
		use warnings;
		$filename = DB::LineCache::map_script($filename, $string);
		$text = DB::LineCache::getline($filename, $line_no, $opts);
	    }
	}
    } else {
	$text = line_at($filename, $line_no, $opts);
	my ($map_file, $map_line) = 
	    DB::LineCache->map_file_line($filename, $line_no);
    }
    $text;
  }
  
sub format_location($;$$$)
{
    my ($self, $event, $frame, $frame_index) = @_;
    $event       //= $self->{event};
    $frame       //= $self->{frame};
    $frame_index //= $self->{frame_index};
    my $text       = undef;
    my $ev         = '  ';
    if (defined($self->{event}) && 0 == $frame_index) {
    	$ev = $EVENT2ICON->{$self->{event}};
    }

    $self->{line_no}  = $self->{frame}{line};
    
    my $loc = $self->source_location_info;
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
    my $filename = $self->filename();
    my $line_number = $self->line() || 0;
    if (DB::LineCache::filename_is_eval($filename)) {
    	if ($DB::filename eq $filename) {
	    # Some lines in @DB::line might not be defined.
	    # So we have to turn off strict here. 
	    no warnings;
	    my $string = join('', @DB::dbline);
	    use warnings;
    	    my $map_file = DB::LineCache::map_script($filename, $string);
    	    $canonic_filename = $self->canonic_file($map_file, 0);
    	    return " $filename:$line_number " . 
    		"remapped ${canonic_filename}:$line_number";
    	}
    }
    $canonic_filename = $self->canonic_file($filename, 0);
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
    # Try unhighlighted line.
    print $proc->current_source_text, "\n";
}

1;
