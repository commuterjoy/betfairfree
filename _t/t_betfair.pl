
=head1 ABOUT

usage: perl t_betfair.pl

This test invokes the BetFair package.

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};

my $b = new BetFair(
	{
	   'username' => $opts{user} || $opts{u},
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});

print Dumper $b;

print "getAccountFunds\n";

$b->getAccountFunds;

#$b->getSubscriptionInfo;

$b->getActiveEventTypes;

$b->getEvents( 5985633 );

$b->getMarket( 4575285 );

#$b->getBestPricesToBack( 5977150 );

print Dumper $b;


