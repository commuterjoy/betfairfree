
=head1 ABOUT

This will log the best back price of each selection in a given market to a file at a 
given interval (eg. 2 seconds)

The file is written in YAML format

=head1 VERSION

0.2

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;
use Time::Local;
use YAML qw(Dump);

# tell YML not to use headers when dumping data structure
local $YAML::UseHeader = 0;

print Dumper $YAML;

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

# fetch human readable market data
$b->getMarket( $m );

# write market data and each runner to the YML file
my %out;
$out{market} = $b->{'_data'}->{'getMarket'}->{$m}->{runners};
my $line = Dump \%out;
open(I, ">>$log") || die $!;
print I $line || die $!;
close I;

# until the user intervention (eg. ctrl-z), append a YAML dump of the the best prices for all runners/selections
while ( 1 )
{
 open(I, ">>$log") || die $!;
 my $now = localtime time;
 
 print "$now\n" if $opts{verbose};
 $b->getBestPricesToBack( $m );
 
 my %out;
 $out{$now} = $b->{_data}->{getMarketPrices}->{$m}->{getBestPricesToBack};
 my $line = Dump \%out;

 print I $line || die $!;
 sleep( $interval );
 close I;
}


