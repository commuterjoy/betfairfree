#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getAccountFunds.pl --user [username] --passwd [password]

This test should log in using the BetFair module, and return the output of the
getAccountFunds SOAP method, ie. your Betfair bank balance.

=cut

use strict;
use BetFair;
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

# Setup the Betfair object
my $b = BetFair->new( $params );

# make request for your account information
if (my $balance = $b->getAccountFunds) {
	print $balance;
} else {
	# we got an error from betfair
	print $b->{error};
}
