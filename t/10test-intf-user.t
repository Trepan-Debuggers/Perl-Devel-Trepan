#!/usr/bin/env perl
use strict; use warnings; no warnings 'redefine';
use rlib '../lib';
use vars qw($response); 

use Test::More 'no_plan';
note( "Testing Devel::Trepan::Interface::User" );

BEGIN {
use_ok( 'Devel::Trepan::Interface::User' );
}

package Devel::Trepan::Interface::User;
sub readline($;$) {
    my ($self, $response) = @_;
    return $main::response;
}

package main;
my $user_intf = Devel::Trepan::Interface::User->new;

for my $s ('y', 'Y', 'Yes', '  YES  ') {
    $response = $s;
    my $ans = $user_intf->confirm('Testing', 1);
    is($ans, 1);
}

for my $s ('n', 'N', 'No', '  NO  ') {
    $response = $s;
    my $ans = $user_intf->confirm('Testing', 1);
    is($ans, 0);
}

eval << 'EOF';
    package Devel::Trepan::Interface::User;
    sub readline($;$) {
	my ($self, $response) = @_;
	return '';
    }
};
EOF

package main;
for my $tf (1, 0) {
    is($user_intf->confirm('default testing', $tf), $tf)
}

# FIXME: more thorough testing of other routines in user.


