#!/usr/bin/env perl
#  Copyright (C) 2011 Rocky Bernstein <rockycpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use ExtUtils::PkgConfig;
use Config;

my $builder = Module::Build->new( 
    module_name         => 'Devel::Trepan',
    add_to_cleanup      => [ 'Devel-Trepan-*', 'tmp*', '*.got'  ],
    create_makefile_pl  => 'passthrough',
    dist_abstract       => 
    'Modular Perl Debugger (akin to Ruby "Trepanning" Debuggers).',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Devel/Trepan.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => 'stable',
    configure_requires  => { 'Module::Build' => 0.38,
                             'ExtUtils::PkgConfig' => 0 },
    build_requires => {
        'String::Diff'                      => 0,
    },
    requires => {
	'perl'                              => '5.010',               
	'Array::Columnize'                  => '0.3.5',
	'ExtUtils::PkgConfig'               => '1.03',
	'Data::Dumper::Perltidy'            => 0,
        'Digest::SHA1'                      => 2.13,
        'Psh'                               => '1.8.0',
        'rlib'                              => '0.02',
        'Syntax::Highlight::Perl::Improved' => 0,
        'Test::More'                        => 0,
        'version'                           => 0,
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

#distclean : unlink lib/perliso9660.pm, lib/perlmmc.pm lib/perlcdio.pm
# c files?
$builder->create_build_script();
