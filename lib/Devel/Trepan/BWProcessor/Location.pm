# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use strict;
use Exporter;
use warnings;
no warnings 'redefine'; no warnings 'once';
use rlib '../../..';
# require_relative '../app/default'

package Devel::Trepan::BWProcessor;
use English qw( -no_match_vars );
use Cwd 'abs_path';

use File::Basename;
use File::Spec;
use Devel::Trepan::DB::LineCache;

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

sub min($$) {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

# Return the text to the current source line. We use trace line
# information to try to retrieve all of the current source line up
# to some limit of lines. The lines returned may be colorized. 
# DB::LineCache actually does the retrieval.
sub current_source_text(;$)
{
    my ($self, $opts) = @_;
    $opts = {max_continue => 5} unless defined $opts;
    my $filename    = $self->{frame}{file};
    my $line_number = $self->{frame}{line};
    my $text        = (DB::LineCache::getline($filename, $line_number, $opts)) 
        || '';
    chomp($text);
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

    $self->{line_no}  = $self->{frame}{line};
    
    my $loc = $self->source_location_info;
    my $pkg = $self->{frame}{pkg};
    my $response = {
	name        => 'stop_location',
	'package'   => $pkg,
	location    => $loc,
    };
    $response->{event}       = $event if $event;
    $response->{frame_index} = 	$frame_index if $frame_index;
    return $response;
}

sub print_location($;$$)
{
    my ($self,$event,$opts) = @_;
    my $response  = $self->format_location($event);

    my $text = $self->current_source_text($opts);
    if ($text) {
        $response->{text} = $text;
    }
    $self->{interface}->msg($response);
  }
  
sub source_location_info($)
{
    my $self = shift;
    # if (@frame.eval?)
    my $canonic_filename;
    #    'eval ' + safe_repr(@frame.eval_string.gsub("\n", ';').inspect, 20)
    #  else
    my $filename = $self->{frame}{file};
    my $line_number = $self->line() || 0;
    my $response = {
	canonic_filename => $self->canonic_file($self->filename()),
	filename         => $self->filename(),
	line_number      => ${line_number},
    };

    my $op_addr = $DB::OP_addr;
    $response->{op_addr} = $op_addr if $op_addr;
    if (DB::LineCache::filename_is_eval($filename)) {
        if ($DB::filename eq $filename) {
            # Some lines in @DB::line might not be defined.
            # So we have to turn off strict here. 
            if ($filename ne '-e') {
                no warnings;
                my $string = join('', @DB::dbline);
                use warnings;
                $filename = DB::LineCache::map_script($filename, $string);
            }
            $response->{remapped} =
		{filename    => $filename,
		 line_number => $line_number},
        }
    }
    return $response;
} 

unless (caller()) {
    # Demo it.
    require Devel::Trepan::BWProcessor;
    my $proc  = Devel::Trepan::BWProcessor->new;
    eval <<'EOE';
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
EOE
    my $frame_ary = create_frame();
    $proc->frame_setup($frame_ary);
    $proc->{event} = 'return';
    require Data::Dumper;
    print Data::Dumper::Dumper($proc->format_location);
    print $proc->current_source_text({output=>'plain'}), "\n";

    # Now try an eval
    $DB::filename = '';
    $frame_ary = eval "create_frame()";
    $proc->frame_setup($frame_ary);
    $proc->{event} = 'line';
    print Data::Dumper::Dumper($proc->format_location);
    print $proc->current_source_text({output=>'plain'}), "\n";
    print $proc->current_source_text, "\n";
}

1;
