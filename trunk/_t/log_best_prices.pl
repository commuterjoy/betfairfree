
=head1 ABOUT

This will log the best back price of a given market to a file at a 
given interval (eg. 2 seconds)

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;
use Time::Local;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i', 'l|log=s', 'i|interval=i', 'verbose' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --market argument" unless $opts{market} || $opts{m};

my $m = $opts{m} . $opts{market};
my $interval = ( $opts{i} || $opts{interval} ) ? $opts{i} . $opts{interval} : 5;
my $log = ( $opts{l} || $opts{log} ) ? $opts{l} . $opts{log} : $m.'.txt';

my $b = new BetFair( 
	{ 	
	   'username' => $opts{user} || $opts{u}, 
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});

$b->login;

if ( -f $log && $opts{verbose} ) { print "appending $log \n"; }

while ( 1 )
{
 open(I, ">>$log") || die $!;
 my $now = localtime time;
 print "$now\n" if $opts{verbose};
 $b->getBestPricesToBack( $m );
 my $line = $now . "," . $b->{_data}->{getMarketPrices}->{$m}->{getBestPricesToBack}->{amount} . "," . $b->{_data}->{getMarketPrices}->{$m}->{getBestPricesToBack}->{price} . $/;
 print I $line || die $!;
 sleep( $interval );
 close I;
}


