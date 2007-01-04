#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getAccountFunds.pl --user [username] --passwd [password]

This test should log in via BetFair::Session, and return the output of the
getAccountFunds SOAP method, ie. your Betfair bank balance.

=cut

use strict;
use BetFair::Session;
use BetFair::Template;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'passwd=s', 'user=s' );

die "you must supply a --user argument" unless $opts{user};
die "you must supply a --passwd argument" unless $opts{passwd};

my $params =
 {
  username => $opts{user},
  password => $opts{passwd},
  productId => 82
 };

my $s = new BetFair::Session( $params ); # assign session key to $s->{key}

# define the message to send, with session key
my $t = new BetFair::Template;
my $params2 = {
                session => $s->{key}
             };
my $message = $t->populate( 'getAccountFunds', $params2 );

# make request for your account information
my $r = new BetFair::Request;
$r->message( $message, 'getAccountFunds' );
$r->request();

# render response using the Parser & Xpath
my $p = new BetFair::Parser( { 'message' => $r->{response} } ); 
my $balance = $p->get_nodeSet( { 'xpath' => '/soap:Envelope/soap:Body/n:getAccountFundsResponse/n:Result/availBalance' } );

print $balance;
