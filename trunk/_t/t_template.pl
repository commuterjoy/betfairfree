#!/usr/bin/perl

=head1 ABOUT

usage: perl t_template.pl

This test will populate and return a BetFair::Template with a given set of parameters.

=cut


use BetFair::Template;

my $t = new BetFair::Template;

my $params = { 
		username => 'foo',
		password => 'bar',
		productId => 82
	     };

my $r = $t->populate( 'login', $params );

print $r;

