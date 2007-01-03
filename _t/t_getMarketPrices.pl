#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getMarketPrices.pl --user [username] --passwd [password] --market [marketId] --compress

This test should log in via BetFair::Session, and return all prices associated
with a market. Eg. if the event is 'Chelsea Vs Liverpool', the markets will be
things like 'First Goal', 'Asian Handicap', 'Over/Under 2.5 Goals'.

Therefore the prices for, say, 'Over/Under 2.5 Goals' will be the best back, lay prices etc.
available at that present time.

A more traffic-efficient, compressed version of this response is available via the
SOAP method getMarketPricesCompressed. Use the --compress option in this program to 
view this response, rather than the XML based version.

=cut

use strict;
use BetFair::Session;
use BetFair::Template;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'passwd=s', 'user=s', 'market=i', 'compress' );

die "you must supply a --user argument" unless $opts{user};
die "you must supply a --passwd argument" unless $opts{passwd};
die "you must supply a --market argument" unless $opts{market};

my $params =
 {
  username => $opts{user},
  password => $opts{passwd},
  productId => 82
 };
my $s = new BetFair::Session( $params );

# build SOAP message
my $t = new BetFair::Template;
my $params2 = {
                session => $s->{key},
		marketId => $opts{market} 
             };

my $ref = 'getMarketPrices';
$ref .= 'Compressed' if $opts{compress}; 
my $message = $t->populate( $ref, $params2 );

# make request for market data
my $r = new BetFair::Request;
$r->message( $message, $t );
$r->request();

print "*** $r->{response} *** \n";

print 1;
