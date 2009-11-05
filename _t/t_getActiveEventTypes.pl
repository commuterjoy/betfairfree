#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getActiveEventTypes.pl --user [username] --passwd [password]

This test returns the output of all top-level active events in the Betfair
system. This is a good starting point for navigating around the event
hierarchy.

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

my $b = new BetFair(
        {
           'username' => $opts{user} || $opts{u},
           'password' => $opts{pass} || $opts{p},
           'productId' => 82
        });

$b->getActiveEventTypes();

print "*** $b->{response} *** \n";

print 1;
