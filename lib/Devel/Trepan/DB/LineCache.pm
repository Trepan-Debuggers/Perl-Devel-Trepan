#!/usr/bin/env perl
# 
#   Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
#
#
=head1 NAME DB::LineCache

DB::LineCache - package to read and cache lines of a Perl program. 

=head1 SYNOPSIS

The LineCache package allows one to get any line from any file,
caching lines of the file on first access to the file. Although the 
file may be any file, the common use is when the file is a Perl
script since parsing of the file is done to figure out where the
statement boundaries are.

The routines here may be is useful when a small random sets of lines
are read from a single file, in particular in a debugger to show
source lines.

  use DB::LineCache;
  $lines = DB::LineCache::getlines('/tmp/myperl.pl')
  # The following lines have same effect as the above.
  $: << '/tmp'
  Dir.chdir('/tmp') {$lines = DB::LineCache::getlines('myperl.pl')

  $line = DB::LineCache::getline('/tmp/myperl.pl', 6)
  # Note lines[6] == line (if /tmp/myperl.pl has 6 lines)

  DB::LineCache::clear_file_cache
  DB::LineCache::update_cache   # Check for modifications of all cached files.

=cut

use Digest::SHA;

use version; $VERSION = '0.1.0';

# A package to read and cache lines of a Perl program. 
package DB::LineCache;
use English qw( -no_match_vars );
use strict; use warnings;
no warnings 'once';
no warnings 'redefine';

use Cwd 'abs_path';
use File::Basename;
use File::Spec;
use File::stat;

use rlib '../..';
## FIXME:: Make conditional
use Devel::Trepan::DB::Colors;
my $perl_formatter = Devel::Trepan::DB::Colors::setup();

## struct(stat => '$', lines => '%', path => '$', sha1 => '$');

# The file cache. The key is a name as would be given by Perl for
# __FILE__. The value is a LineCacheInfo object.

my %file_cache;
my %script_cache;

# Maps a string filename (a String) to a key in %file_cache (a
# String).
#
# One important use of %file2file_remap is mapping the a full path
# of a file into the name stored in %file_cache or given by Perl's
# __FILE__. Applications such as those that get input from users,
# may want canonicalize a file name before looking it up. This map
# gives a way to do that.
#
# Another related use is when a template system is used.  Here we'll
# probably want to remap not only the file name but also line
# ranges. Will probably use this for that, but I'm not sure.

my %file2file_remap;
my %file2file_remap_lines;
my %script2file;

sub remove_script_temps() 
{
    for my $filename (values %script2file) {
	unlink($filename) if -f $filename;
    }
}

END { remove_script_temps };

  
# Clear the file cache entirely.
sub clear_file_cache(;$)
{
    if (scalar @_ == 1) {
	my $filename = shift;
	if ($file_cache{$filename}) {
	    delete $file_cache{$filename};
	}
    } else {
	%file_cache = {};
	%file2file_remap = {};
	%file2file_remap_lines = {};
    }
}

# Remove syntax-formatted lines in the cache. Use this when you change
# the Syntax::Highlight::Perl colors and want to redo how files may
# have previously been syntax marked.
sub clear_file_format_cache() 
{
    while (my ($fname, $cache_info) = each %file_cache) {
	while (my($format, $lines) = each %{$cache_info->{lines_href}}) {
	    next if 'plain' eq $format;
	    my $ref = $file_cache{$fname};
	    $ref->{lines_href}->{$format} = undef;
	}
    }
}

# Clear the script cache entirely.
sub clear_script_cache() {
    %script_cache = {};
}

# Return an array of cached file names
sub cached_files() {
    keys %file_cache;
}

# Discard cache entries that are out of date. If +filename+ is +undef+
# all entries in the file cache +@@file_cache+ are checked.
# If we don't have stat information about a file, which can happen
# if the file was read from $__SCRIPT_LINES but no corresponding file
# is found, it will be kept. Return a list of invalidated filenames.
# undef is returned if a filename was given but not found cached.
sub checkcache(;$$)
{
    my ($filename, $opts) = @_;
    $opts = {} unless defined $opts;

    my $use_perl_d_file = $opts->{use_perl_d_file};

    my @filenames;
    if (defined $filename) {
	@filenames = keys %file_cache;
    } elsif (exists $file_cache{$filename}) {
	@filenames = ($filename);
    } else {
	return undef;
    }

    my @result = ();
    for my $filename (@filenames) {
	next unless exists $file_cache{$filename};
	my $path = $file_cache{$filename}{path};
	if (-f  $path) {
	    my $cache_info = $file_cache{$filename}{stat};
	    my $stat = File::stat::stat($path);
	    if ($cache_info) {
		if ($stat && 
		    ($cache_info->{size} != $stat->size or 
		     $cache_info->{mtime} != $stat->mtime)) {
		    push @result, $filename;
		    update_cache($filename, $opts);
		}
	    }
        } else {
	    push @result, $filename;
	    update_cache($filename, $opts);
        }
    }
    return @result;
}

# Cache script if it's not already cached.
sub cache_script($;$) 
{
    my ($script, $opts) = @_;
    $opts = {} unless defined $opts;
    update_script_cache($script, $opts) unless 
	(exists $script_cache{$script});
    $script;
}

# Cache file name or script object if it's not already cached.
# Return the expanded filename for it in the cache if a filename,
# or the script, or undef if we can't find the file.
sub cache($;$)
{
    my ($file_or_script, $reload_on_change) = @_;
    cache_file($file_or_script, $reload_on_change)
}

# Cache filename if it's not already cached.
# Return the expanded filename for it in the cache
# or undef if we can't find the file.
sub cache_file($;$$) 
{
    my ($filename, $reload_on_change, $opts) = @_;
    $opts = {} unless defined $opts;
    if (exists $file_cache{$filename}) {
	checkcache($filename) if $reload_on_change;
    } else {
	$opts->{use_perl_d_file} = 1 unless defined $opts->{use_perl_d_file};
	update_cache($filename, $opts);
    }
    if (exists $file_cache{$filename}) {
	$file_cache{$filename}{path};
    } else {
	return undef;
    }
}

# Return true if file_or_script is cached.
sub is_cached($)
{ 
    my $file_or_script = shift;
    return undef unless defined $file_or_script;
    exists $file_cache{map_file($file_or_script)};
}

sub is_cached_script($)
{
    my $filename = shift;
    my $name = map_file($filename);
    scalar @{"_<$name"};
}
      
sub is_empty($)
{
    my $filename = shift;
    $filename=map_file($filename);
    my $ref = $file_cache{$filename};
    $ref->{lines_href}{plain};
}

sub file_list()
{
    sort((cached_files(), keys(%file2file_remap)));
}

# Get line +line_number+ from file named +filename+. Return undef if
# there was a problem. If a file named filename is not found, the
# function will look for it in the $: array.
# 
# Examples:
# 
#  $lines = LineCache::getline('/tmp/myfile.rb')
#  # Same as above
#  $: << '/tmp'
#  $lines = LineCache.getlines('myfile.rb')
#
sub getline($$;$)
{
    my ($file_or_script, $line_number, $opts) = @_;
    $opts = {} unless defined $opts;
    my $reload_on_change = $opts->{reload_on_change};
    my $filename = map_file($file_or_script);
    ($filename, $line_number) = map_file_line($filename, $line_number);
    ## print "+++FILENAME $filename\n";
    my $lines = getlines($filename, $opts);
    if (defined $lines && @$lines && $line_number > 0 && 
	$line_number <= scalar @$lines) {
	my $line = $lines->[$line_number-1];
	chomp $line if defined $line;
        return $line;
    } else {
        return undef;
    }
}

# Read lines of +filename+ and cache the results. However +filename+ was
# previously cached use the results from the cache. Return undef
# if we can't get lines
sub getlines($;$);
sub getlines($;$)
{
    my ($filename, $opts) = @_;
    $opts = {use_perl_d_file => 1} unless defined $opts;
    my ($reload_on_change, $use_perl_d_file) = 
        ($opts->{reload_on_change}, $opts->{use_perl_d_file});
    checkcache($filename) if $reload_on_change;
    my $format = $opts->{output} || 'plain';
    if (exists $file_cache{$filename}) {
	my $lines_href = $file_cache{$filename}{lines_href};
	my $lines_aref = $lines_href->{$format};
	if ($opts->{output} && !defined $lines_aref) {
	    my @formatted_lines = ();
	    my $lines_aref = $lines_href->{plain};
	    for my $line (@$lines_aref) {
		push @formatted_lines, highlight_string($line);
		## print $formatted_text;
	    }
	    $lines_href->{$format} = \@formatted_lines;
	    return \@formatted_lines;
	} else {
	    return $lines_aref;
	}
    } elsif (exists $script_cache{$filename}) {
	### FIXME: combine with above...
	###  print "+++IS IN SCRIPT CACHE\n";
	my $lines_href = $script_cache{$filename}{lines_href};
	my $lines_aref = $lines_href->{$format};
	if ($opts->{output} && !defined $lines_aref) {
	    my @formatted_lines = ();
	    my $lines_aref = $lines_href->{plain};
	    for my $line (@$lines_aref) {
		push @formatted_lines, highlight_string($line);
		## print $formatted_text;
	    }
	    $lines_href->{$format} = \@formatted_lines;
	    return \@formatted_lines;
	} else {
	    return $lines_aref;
	}
    } else {
	$opts->{use_perl_d_file} = 1;
	update_cache($filename, $opts);
	if (exists $file_cache{$filename}) {
	    return getlines($filename, $opts);
	} else {
	    return undef;
	}
    }
}

sub highlight_string($)
{
    my ($string) = shift;
    $string = $perl_formatter->format_string($string);
    chomp $string;
    $string;
  }

 # Return full filename path for filename
sub path($)
{
    my $filename = shift;
    $filename = map_file($filename);
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}->path();
}

sub remap_file($$)
{ 
    my ($from_file, $to_file) = @_;
    $file2file_remap{$from_file} = $to_file;
    cache_file($to_file);
}

sub remap_file_lines($$$$)
{
    my ($from_file, $to_file, $range_ref, $start) = @_;
    my @range = @$range_ref;
    $to_file = $from_file unless $to_file;
    my $ary_ref = ${$file2file_remap_lines{$to_file}};
    $ary_ref = [] unless defined $ary_ref;
    # FIXME: need to check for overwriting ranges: whether
    # they intersect or one encompasses another.
    push @$ary_ref, [$from_file, @range, $start];
}
  
# Return SHA1 of filename.
sub DB::LineCache::sha1($)
{
    my $filename = shift;
    $filename = map_file($filename);
    return undef unless exists $file_cache{$filename};
    my $sha1 = $file_cache{$filename}{sha1};
    return $sha1->hexdigest if exists $file_cache{$filename}{sha1};
    $sha1 = Digest::SHA->new('sha1');
    my $line_ary = $file_cache{$filename}{lines_href}{plain};
    for my $line (@$line_ary) {
	next unless defined $line;
	$sha1->add($line);
    }
    $file_cache{$filename}{sha1} = $sha1;
    $sha1->hexdigest;
  }
      
# Return the number of lines in filename
sub size($)
{
    my $file_or_script = shift;
    cache($file_or_script);
    $file_or_script = map_file($file_or_script);
    return undef unless exists $file_cache{$file_or_script};
    my $lines_href = $file_cache{$file_or_script}{lines_href};
    return undef unless defined $lines_href;
    scalar @{$lines_href->{plain}};
}

# Return File.stat in the cache for filename.
sub DB::LineCache::stat($)
{ 
    my $filename = shift;
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}{stat};
}

# Return an Array of breakpoints in filename.
# The list will contain an entry for each distinct line event call
# so it is possible (and possibly useful) for a line number appear more
# than once.
sub trace_line_numbers($;$)
{
    my ($filename, $reload_on_change) = @_;
    my $fullname = cache($filename, $reload_on_change);
    return undef unless $fullname;
    my $trace_nums_ary = $file_cache{$filename}{trace_nums};
    return @$trace_nums_ary;
  }
    
sub map_file($)
{ 
    my $file = shift;
    return undef unless defined($file);
    $file2file_remap{$file} ? $file2file_remap{$file} : $file
  }

use File::Temp qw(tempfile);
sub map_script($$)
{
    my ($script, $string) = @_;
    if (exists $script2file{$script}) {
	$script2file{$script};
    } else  {
	# my $sha1 = Digest::SHA->new('sha1');
	# $sha1->add($string);
	my ($fh, $tempfile) = tempfile('XXXX', SUFFIX=>'.pl',
				       TMPDIR => 1);
	print $fh $string;
	$fh->close();
	$script2file{$script} = $tempfile;
	# cache_file($tempfile);
	# $file_cache{$tempfile}{sha1} = $sha1;
	$tempfile;
    }
}

sub map_file_line($$)
{
    my ($file, $line) = @_;
    if (exists $file2file_remap_lines{$file}) {
	my $triplet_ref = $file2file_remap_lines{$file};
	for my $triplet (@$triplet_ref) {
	    my ($from_file, $range_ref, $start) = @$triplet;
	    my @range = @$range_ref;
	    if ( $range[0]  >= $line && $range[-1] <= $line) {
		my $from_file = $from_file || $file;
		return [$from_file, $start+$line-$range[0]];
	    }
	}
    }
    return ($file, $line);
}

sub filename_is_eval($)
{
    my $filename = shift;
    return ($filename =~ /^\(eval \d+\)/);
}

# UPDATE a cache entry.  If something is wrong, return undef. Return
# 1 if the cache was updated and false if not. 
sub update_script_cache($$)
{
    my ($script, $opts) = @_;
    return 0 unless filename_is_eval($script);
    my $string = $opts->{string};
    my $lines_href = {};
    unless (defined($string)) {
	if ($script eq $DB::filename) {
	    # Should be the same as the else case, 
	    # but just in case...
	    $lines_href->{plain} = \@DB::lines;
	    $string = join("\n", @DB::lines);
	} else {
	    $lines_href->{plain} = \@{"_<$script"};
	    $string = join("\n", @{"_<$script"});
	}
    }
    $lines_href->{$opts->{output}} = highlight_string($string) if 
	$opts->{output};

    my $entry = {
	lines_href => $lines_href,
    };
    $script_cache{$script} = $entry;
    return 1;
  }

sub read_file($)
{
    my $path = shift;
    if (-r $path) {
	open(FH, '<', $path);
	seek FH, 0, 0;
	my @lines = <FH>;
	close FH;
	return @lines;
    } else {
	return undef;
    }
}

# Update a cache entry.  If something's wrong, return undef. Return 1
# if the cache was updated and false if not.  If use_perl_d_file is 1,
# use that as the source for the lines of the file
sub update_cache($;$) 
{
    my ($filename, $opts) = @_;
    my $read_file = 0;
    $opts = {} unless defined $opts;
    my $use_perl_d_file = $opts->{use_perl_d_file};
    $use_perl_d_file = 1 unless defined $use_perl_d_file;

    return undef unless $filename;

    delete $file_cache{$filename};

    my $is_eval = filename_is_eval($filename);
    my $path = $filename;
    unless ($is_eval) {
	$path = abs_path($filename) if -f $filename;
    }
    my $lines_href;
    my @trace_nums = ();
    if ($use_perl_d_file) {
	my @list = ($filename);
	if ($is_eval) {
	    cache_script($filename);
	    ## FIXME: create a temporary file in script2file;
	}
	push @list, $file2file_remap{$path} if exists $file2file_remap{$path};
	for my $name (@list) {
	    my $stat;
	    no strict; # Avoid string as ARRAY ref error message
	    if (scalar @{"main::_<$name"}) {
		$stat = File::stat::stat($path);
	    }
	    my $raw_lines = \@{"main::_<$name"};

	    # Perl sometimes doesn't seem to save all file data, such
	    # as those intended for POD or possibly those after
	    # __END__. But we want these, so we'll have to read the
	    # file the old-fashioned way and check lines. Variable
	    # $incomplete records if there was a mismatch.
	    my $incomplete = 0;
	    if (-r $path) {
	    	my @lines_check = read_file($path);
	    	my @lines = @$raw_lines;
	    	for (my $i=1; $i<=$#lines; $i++) {
	    	    if (defined $raw_lines->[$i]) {
			push @trace_nums, $i if ($raw_lines->[$i] != 0);
	    		$incomplete = 1 if $raw_lines->[$i] ne $lines[$i];
	    	    } else {
	    		$raw_lines->[$i] = $lines_check[$i-1] 
	    	    }
	    	}
	    }
	    use strict;
	    $lines_href = {};
	    $lines_href->{plain} = $raw_lines;
	    if ($opts->{output} && defined($raw_lines)) {
		# Some lines in $raw_lines may be undefined
		no strict; no warnings;
		local $WARNING=0;
		my $highlight_lines = highlight_string(join('', @$raw_lines));
		my @highlight_lines = split(/\n/, $highlight_lines);
		$lines_href->{$opts->{output}} = \@highlight_lines;
		use strict; use warnings;
	    }
	    my $entry = {
		stat       => $stat,
		lines_href => $lines_href,
		path       => $path,
		incomplete => $incomplete,
		trace_nums => \@trace_nums,
	    };
	    $read_file = 1;
        }
    }
      
    my $stat = undef;
    if (-f $path ) {
	$stat = File::stat::stat($path);
    } elsif (!$read_file) {
	if (basename($filename) eq $filename) {
	    # try looking through the search path.
	    for my $dirname (@INC) {
		$path = File::Spec::catfile->($dirname, $filename);
		if ( -f $path) {
		    $stat = File::stat::stat($path);
		    last;
		}
	    }
	}
	return 0 unless defined $stat;
    }
    if ( -r $path ) { 
	my @lines = read_file($path);
	$lines_href = {plain => \@lines};
	if ($opts->{output}) {
	    my $highlight_lines = highlight_string(join('', @lines));
	    my @highlight_lines = split(/\n/, $highlight_lines);
	    $lines_href->{$opts->{output}} = \@highlight_lines;
	}
    }
    my $entry = {
		stat       => $stat,
		lines_href => $lines_href,
		path       => $path,
		incomplete => 0,
		trace_nums => \@trace_nums,
	    };
    $file_cache{$filename} = $entry;
    $file2file_remap{$path} = $filename;
    return 1;
}

# example usage
unless (caller) {
    BEGIN {
	use English qw( -no_match_vars );
	$PERLDB |= 0x400;
    };  # Turn on saving @{_<$filename};
    my $file=__FILE__;
    my $fullfile = abs_path($file);
    no strict;
    print scalar(@{"main::_<$file"}), "\n";
    use strict;
    
    my $lines = DB::LineCache::getlines(__FILE__);
    printf "%s has %d lines\n",  __FILE__,  scalar @$lines;
    my $full_file = abs_path(__FILE__);
    $lines = DB::LineCache::getlines(__FILE__);
    printf "%s still has %d lines\n",  __FILE__,  scalar @$lines;
    $lines = DB::LineCache::getlines(__FILE__);
    printf "%s also has %d lines\n",  $full_file,  scalar @$lines;
    my $line_number = __LINE__;
    my $line = DB::LineCache::getline(__FILE__, $line_number);
    printf "The %d line is:\n%s\n", $line_number, $line ;
    DB::LineCache::remap_file('another_name', __FILE__);
    print DB::LineCache::getline('another_name', __LINE__), "\n";
    
    printf "Files cached: %s\n", join(', ', DB::LineCache::cached_files);
    DB::LineCache::update_cache(__FILE__);
    ## DB::LineCache::checkcache(__FILE__);
    printf "I said %s has %d lines!\n", __FILE__, DB::LineCache::size(__FILE__);
    printf "SHA1 of %s is:\n%s\n", __FILE__, DB::LineCache::sha1(__FILE__);
    # print "#{__FILE__} trace line numbers:\n" + 

    my $stat = DB::LineCache::stat(__FILE__);
    printf("stat info size: %d, ctime %s, mode %o\n", 
	   $stat->size, $stat->ctime, $stat->mode);

    my $lines_aref = DB::LineCache::getlines(__FILE__, {output=>'term'});
    print join("\n", @$lines_aref), "\n" if defined $lines_aref;

    print("trace nums: ", join(', ',
			       DB::LineCache::trace_line_numbers(__FILE__)),
	  "\n");
    $lines_aref = DB::LineCache::getlines(__FILE__, {output=>'term'});
    print("trace nums again: ", join(', ',
			       DB::LineCache::trace_line_numbers(__FILE__)),
	  "\n");
    eval "printf \"filename_is_eval: %s, %s\n\", __FILE__, 
          filename_is_eval(__FILE__);";
    $DB::filename = 'bogus';
    eval "update_script_cache(__FILE__, {}); 
          print '+++', is_cached_script(__FILE__), \"\\n\"";
    $DB::filename = '(eval 4)';
    my $filename = map_script($DB::filename, "\$x=1;\n\$y=2;\n\$z=3;\n");
    print "mapped eval is $filename\n";
    
    # print("#{__FILE__} is %scached." % 
    #      yes_no(LineCache::cached?(__FILE__)))
    # print "Full path: #{DB::LineCache::path(__FILE__)}"
    # LineCache::checkcache # Check all files in the cache
    # LineCache::clear_file_cache 
    # print("#{__FILE__} is now %scached." % 
    #      yes_no(LineCache::cached?(__FILE__)))
    # digest = SCRIPT_LINES__.select{|k,v| k =~ /digest.rb$/}
    # print digest.first[0] if digest
    # line = LineCache::getline(__FILE__, 7)
    # print "The 7th line is\n#{line}" 
    # LineCache::remap_file_lines(__FILE__, 'test2', (10..20), 6)
    # print LineCache::getline('test2', 10)
    # print "Remapped 10th line of test2 is\n#{line}" 
}

1;
