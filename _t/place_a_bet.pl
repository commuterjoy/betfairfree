=head1 WARNING

This script has the ability to make monetary transactions using your Betfair wallet.

Misunderstanding this script may cost you a significant amount of money.

Do not use it if you do not understand what it does. The author of this script accepts no liabilities for misuse.

=head1 ABOUT

This is a command line utlity to place a single bet.

 * if no odd's are given the best odds at that time are taken
 * if no bet argument is given then the minimum bet of £2 is assumed
 * if no -back or -lay flag is given then -back is assumed
 * unless the -noprompt flag is given you will be given an opportunity to review the bet before it's placed
 * if betfair odds are higher that those given the bet goes ahead at those odds, if lower it's held
     at the site until the bet is matched or cancelled.

=head1 USAGE

 # bet £3.20 at odds of 2.43 as a backer on selection 123512 from market 21031232
 perl -I./lib _t/place_a_bet.pl -u [user] -p [pass] -m 21031232 -s 123512 -b 3.20 -o 2.43 -back

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;

my $DEBUG = 0;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i', 's|selection=i', 'o|odds=s', 'stake=s', 'back', 'lay', 'verbose', 'noprompt' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --selection argument" unless $opts{selection} || $opts{'s'};
die "you must supply a --market argument" unless $opts{market} || $opts{'m'};

my $m = $opts{'m'} . $opts{market};
my $s = $opts{'s'} . $opts{selection};

my $stake = $opts{stake} || "2.00";
my $odds = ( $opts{o} || $opts{odds} ) ? $opts{o} . $opts{odds} : 0;

my $type = ( $opts{lay} ) ? 'L' : 'B';


my ( $runner, $amount, $best_price );

# TODO datatypes check inputs carefully

my $b = new BetFair(
	{
	   'username' => $opts{user} || $opts{u},
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});

# get the runners
$b->getMarket( $m );

# find the plain English name associated with the selection
foreach ( @{$b->{'_data'}->{'getMarket'}->{$m}->{runners}} )
 {
  $runner = $_->{'name'} if ( $_->{'selection'} == $s );
 }

# get best prices
$b->getBestPricesToBack( $m );

# find the best price for that runner
foreach ( @{$b->{_data}->{getMarketPrices}->{$m}->{getBestPricesToBack}} )
 {
  if ( $_->{'selection'} == $s )
   {
      $best_price = $_->{'price'};
      $amount = $_->{'amount'};
   }
 }

die "Couldn't find runner \#$s in market \#$m" unless $runner;
die "Couldn't find best price or amount for \#$s in market \#$m" unless $best_price || $amount;

print "you have 10 seconds to cancel : Selection : $runner (\#$s), UKP$stake \@ $odds" . $/;

# give time for user to cancel, unless they have explicitly asked for no safety catch
sleep( 10 ) unless $opts{'noprompt'};

$b->submit_request( 'placeBets', {
        marketId => $m, selectionid => $s, price => $odds, size => $stake, bettype => $type
        });







