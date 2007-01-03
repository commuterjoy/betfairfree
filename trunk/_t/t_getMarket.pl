#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getMarket.pl --user [username] --passwd [password] --market [marketId]

This test should log in via BetFair::Session, and return all markets associated 
with an event. Eg. if the event is 'Chelsea Vs Liverpool', the markets will be
things like 'First Goal', 'Asian Handicap', 'Over/Under 2.5 Goals'.

=cut

use strict;
use BetFair::Session;
use BetFair::Template;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'passwd=s', 'user=s', 'market=i' );

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

print Dumper $s;

print "your betfair session key is : " . $s->{key} . $/;

# 

my $t = new BetFair::Template;

my $params2 = {
                session => $s->{key},
		marketId => $opts{market} 
             };

my $message = $t->populate( 'getMarket', $params2 );

print $message;

#

 # make the login request
 my $r = new BetFair::Request;
 $r->message( $message, 'getMarket' );
 $r->request();

 print "*** $r->{response} *** \n";

# 
#print $som;
#my $f = open(FH,">_tmp");
#print FH $som;
#close FH;
#system("xsltproc xslt/getAccountFunds _tmp");

print 1;
