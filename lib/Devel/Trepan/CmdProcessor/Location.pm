# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use strict;
use Exporter;
use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../../..';
# require_relative '../app/default'

package Devel::Trepan::CmdProcessor;
use English qw( -no_match_vars );
use Cwd 'abs_path';

use File::Basename;
use File::Spec;
use Devel::Trepan::DB::LineCache;

our $EVENT2ICON = {
    'brkpt'          => 'xx',
    'call'           => '->',
    'debugger-call'  => ':o',
    'end'            => '-|',
    'interrupt'      => 'oo',
    'line'           => '--',
    'post-mortem'    => 'XX',
    'return'         => '<-',
    'signal'         => '!!',
    'tbrkpt'         => 'x1',
    'trace'          => '==',
    'unknown'        => '?!',
    'watch'          => 'wa',
};

sub canonic_file($$;$)
{
    my ($self, $filename, $resolve) = @_;
    return undef unless defined $filename;
    $resolve = 1 unless defined $resolve;

    # For now we want resolved filenames 
    if ($self->{settings}{basename}) {
	my $is_eval = DB::LineCache::filename_is_eval($filename);
	return $is_eval ? $filename : (basename($filename) || $filename);
    } elsif ($resolve) {
    	my $mapped_filename = DB::LineCache::map_file($filename);
	$filename = $mapped_filename if defined($mapped_filename);
	my $is_eval = DB::LineCache::filename_is_eval($filename);
	return $is_eval ? $filename : (abs_path($filename) || $filename);
    } else {
	return $filename;
    }
}

# Return the text to the current source line.
sub current_source_text(;$)
{
    my ($self, $opts) = @_;
    $opts = {} unless defined $opts;
    my $filename    = $self->{frame}{file};
    my $line_number = $self->{frame}{line};
    my $text;
    $text = DB::LineCache::getline($filename, $line_number, $opts); 
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
  
sub text_at($;$) 
{
    my ($self, $opts) = @_;
    $opts = {
	reload_on_change => $self->{settings}{reload},
	output           => $self->{settings}{highlight},
    } unless defined $opts;

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
    $event       = $self->{event} unless defined $event;
    $frame       = $self->{frame} unless defined $frame;
    $frame_index = $self->{frame_index} unless defined $frame_index;
    my $text       = undef;
    my $ev         = '  ';
    if (defined($self->{event}) && 0 == $frame_index) {
    	$ev = $EVENT2ICON->{$self->{event}};
    }

    $self->{line_no}  = $self->{frame}{line};
    
    my $loc = $self->source_location_info;
    my $suffix = ($event eq 'return' && defined($DB::_[0])) ? " $DB::_[0]" : '';
    "${ev} (${loc})$suffix"
}

sub print_location($;$)
{
    my ($self,$opts) = @_;
    $opts = {output => $self->{settings}{highlight}} unless defined $opts;
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
    # my $cop = 0;
    # $cop = 0 + $DB::dbline[$line_number] if defined $DB::dbline[$line_number];
    # return sprintf "${canonic_filename}:${line_number} 0x%x", $cop;
} 

unless (caller()) {
    # Demo it.
    require Devel::Trepan::CmdProcessor;
    my $proc  = Devel::Trepan::CmdProcessor->new;
    sub create_frame() {
    	my ($pkg, $file, $line, $fn) = caller(0);
	return [
	    {
		 file      => $file,
		 fn        => $fn,
		 line      => $line,
		 pkg       => $pkg,
	    }];
    }
    my $frame_ary = create_frame();
    $proc->frame_setup($frame_ary);
    $proc->{event} = 'return';
    print $proc->format_location, "\n";
    print $proc->current_source_text({output=>'term'}), "\n";
    # See if cached line is the same
    print $proc->current_source_text({output=>'term'}), "\n";
    # Try unhighlighted line.
    print $proc->current_source_text, "\n";
}

1;
