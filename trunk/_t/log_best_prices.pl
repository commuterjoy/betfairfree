
=head1 ABOUT

This will log the best back price of each selection in a given market to a file at a 
given interval (eg. 2 seconds)

The file is written in YAML format

=head1 USAGE

 # log a market's, every 10 seconds
 perl -I./lib _t/log_best_prices.pl -u username -p password -interval 10 -m marketid -iso

=head1 VERSION

0.4

=head1 Notes
 
 * v0.4 - optionally use ISO-8601 format as date stamp
 * v0.3 - logs now use a formatted date as the YAML key for each entry for ease of sorting
 * v0.2 - logs prices and amount available data for all runners in the market
        - includes a summary of the market at head of log file
 * v0.1 - functional proof of concept

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;
use Time::Local;
use YAML qw(Dump);
use POSIX qw(strftime);

# tell YML not to use headers when dumping data structure
local $YAML::UseHeader = 0;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i', 'l|log=s', 'i|interval=i', 'iso', 'verbose' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --market argument" unless $opts{market} || $opts{m};

my $m = $opts{m} . $opts{market};
my $interval = ( $opts{i} || $opts{interval} ) ? $opts{i} . $opts{interval} : 5;
my $log = ( $opts{l} || $opts{log} ) ? $opts{l} . $opts{log} : $m.'.txt';
my $iso = ( $opts{iso} ) ? $opts{iso} : 0;

my $b = new BetFair( 
	{ 	
	   'username' => $opts{user} || $opts{u}, 
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});

$b->login;

if ( -f $log && $opts{verbose} ) { print "appending $log \n"; }

# write market data and each runner to the YML file, but only if the file doesn't exist
unless ( -f $log )
 {
    # fetch human readable market data
    $b->getMarket( $m );
    
    # convert the extracted data to a YAML data structure via Dump
    my %out;
    $out{market} = $b->{'_data'}->{'getMarket'}->{$m}->{runners};
    my $line = Dump \%out;

    # write to file
     _log( $line );
 }
 
# until the user intervention (eg. ctrl-z), append a YAML dump of the the best prices for all runners/selections
while ( 1 )
{

 # get time
 my $now = _time(); 
 print "$now\n" if $opts{verbose};
 
 # fetch the best prices from Betfair
 $b->getBestPricesToBack( $m );

 # convert the extracted data to a YAML data structure via Dump 
 my %out;
 $out{$now} = $b->{_data}->{getMarketPrices}->{$m}->{getBestPricesToBack};
 my $line = Dump \%out;

 # log to file
 _log( $line );
 
 # sleep for the given interval (in seconds)
 sleep( $interval );

}

# utility routine for writing a line to a log file
sub _log
 {
    my $line = shift;
    open(I, ">>$log") || die $!;
    print I $line || die $!;
    close I;
 }

# returns current time formatted as YYYYMMDDHHMMSS or ISO-8601 if the -iso flag is supplied
sub _time
 {
  my $now = time();
  my $tz = strftime("%z", localtime($now));
  $tz =~ s/(\d{2})(\d{2})/$1:$2/;
  if ( $iso ){
	strftime("%Y-%m-%dT%H:%M:%S", localtime($now));
  } else {
  	strftime("%Y%m%d%H%M%S", localtime($now));
	}
 }

