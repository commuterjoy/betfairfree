#!/usr/bin/perl

=head1 ABOUT

usage: perl t_session.pl --user [username] --passwd [password]

Given a valid Betfair username & password this test will return a session token.

=cut


use strict;
use BetFair::Session;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'passwd=s', 'user=s' );

die "you must supply a --user argument" unless $opts{user};
die "you must supply a --passwd argument" unless $opts{passwd};

my $params =
 {
  username => $opts{user},
  password => $opts{passwd},
  productId => 82
 };

my $s = new BetFair::Session( $params );

#print "your betfair session key is : " . $s->{key} . $/;

print Dumper $s; 

print 1;
