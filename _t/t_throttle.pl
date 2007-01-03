#!/usr/bin/perl

=head1 ABOUT

usage: perl t_throttle.pl

This test will repeatedly call a method, sleep() for a while, call it again, then sleep() some
more. In between this it will check whether the method is 'ok' to be called at that
point in time and return a boolean value saying as much.

=cut


use strict;
use BetFair::Throttle;
use Data::Dumper;

my $t = new BetFair::Throttle;

$t->touch('login');

print Dumper $t;

sleep(3);

$t->touch('login');
$t->touch('login');
$t->touch('login');

print $t->ok_to_call('login');

print Dumper $t;

for ( my $i = 0; $i < 24; $i++ )
	{ $t->touch('login'); } 

print $t->ok_to_call('login');

print Dumper $t;

sleep(3);

$t->touch('login');
print $t->ok_to_call('login');

print Dumper $t;
