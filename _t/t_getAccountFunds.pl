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

my $s = new BetFair::Session( $params );

print Dumper $s;

print "your betfair session key is : " . $s->{key} . $/;

# 

my $t = new BetFair::Template;

my $params2 = {
                session => $s->{key}
             };

my $message = $t->populate( 'getAccountFunds', $params2 );

print $message;

#

 # make the login request
 my $r = new BetFair::Request;
 $r->message( $message, 'getAccountFunds' );
 $r->request();
# $r->request();
# $r->request();

print "*** $r->{response} *** \n";
 
print 1;
