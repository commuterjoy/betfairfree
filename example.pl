#!/usr/bin/perl -w

#This script tests some basic parts of the BetFair package ensuring that it's 
#all working. It does require account details in order to log in to the Betfair
#API  as required by the terms of use of the API.

use strict;
use Data::Dumper;
use Getopt::Long;

use lib './lib';
use BetFair;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s' );

my $user =  $opts{user} || $opts{u};
my $pass =  $opts{pass} || $opts{p};

#set these to override passing it in each time;
#$user = '';
#$pass = '';

die "you must supply a --user argument" unless ($user);
die "you must supply a --pass argument" unless ($pass);

my $b = new BetFair(
	{
	   'username' => $user,
 	   'password' => $pass,
	   'productId' => 82,
       'xmlsimple' => 1
	});

die $b->{error} unless ($b->getActiveEventTypes);

print Dumper $b->{_data};

my $input = 1;
while( $input ) {
    print "Pick an Event ID to view \n(use m:<NUMBER> if you want a market) => ";
    $input = <STDIN>;
    chomp( $input );

    if ( $input =~ m/m\:([0-9]+)/i ) {
        die $b->{error} unless ($b->getMarket( $1 ));
        print Dumper $b->{_data};
    } else {
        die $b->{error} unless ($b->getEvents( $input ));
        print Dumper $b->{_data};
    }
}
