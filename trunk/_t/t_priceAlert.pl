
=head1 ABOUT

This test returns the best 'back' price data of a given market.

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --market argument" unless $opts{market} || $opts{m};

my $b = new BetFair( 
	{ 	
	   'username' => $opts{user} || $opts{u}, 
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});


#my $e = 5965719;

my $m = $opts{m};
$b->login;
$b->getMarket( $m );
$b->getBestPricesToBack( $m );

# ie. data at $self->{_data}->{getMarketPrices}->{[marketId]}->{bestBackPrices}
print Dumper $b;


