#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getEvents.pl --user [username] --passwd [password] --event [eventId]

This test should log in via BetFair::Session, and return all child events
of a given parent event id, eg. eventId "1" refers to soccer, so child events 
are 'Argentinian Soccer', 'Belgium Soccer' etc.

=cut

use strict;
use BetFair::Session;
use BetFair::Template;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'passwd=s', 'user=s', 'event=i' );

die "you must supply a --user argument" unless $opts{user};
die "you must supply a --passwd argument" unless $opts{passwd};
die "you must supply a --event argument, try --event 1 for football" unless $opts{event};

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
			eventParentId => $opts{event} 
             };

my $message = $t->populate( 'getEvents', $params2 );

print $message;

#

 # make the login request
 my $r = new BetFair::Request;
 $r->message( $message, 'getEvents' );
 $r->request();

 print "*** $r->{response} *** \n";

# 
#print $som;
#my $f = open(FH,">_tmp");
#print FH $som;
#close FH;
#system("xsltproc xslt/getAccountFunds _tmp");

print 1;
