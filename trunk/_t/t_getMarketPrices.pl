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
use BetFair;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i', 'compress' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --market argument" unless $opts{market} || $opts{m};

my $b = new BetFair(
        {
           'username' => $opts{user} || $opts{u},
           'password' => $opts{pass} || $opts{p},
           'productId' => 82
        });

my $market = $opts{market} || $opts{m};

if ($opts{compress}) {
    $b->getMarketPricesCompressed($market);
} else {
    $b->getMarketPrices($market);
}

print "*** $b->{response} *** \n";

print 1;
