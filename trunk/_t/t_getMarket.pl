#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getMarket.pl --user [username] --passwd [password] --market [marketId]

This test should return all markets associated with an event. Eg. if the event
is 'Chelsea Vs Liverpool', the markets will be things like 'First Goal', 'Asian
Handicap', 'Over/Under 2.5 Goals'.

=cut

use strict;
use BetFair;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'm|market=i');

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

$b->getMarket($market);

print "*** $b->{response} *** \n";

print 1;
