#!/usr/bin/perl

=head1 ABOUT

usage: perl t_getEvents.pl --user [username] --passwd [password] --event [eventId]

This test should log in via BetFair::Session, and return all child events
of a given parent event id, eg. eventId "1" refers to soccer, so child events
are 'Argentinian Soccer', 'Belgium Soccer' etc.

=cut

use strict;
use BetFair;
use Getopt::Long;

my %opts = ();


GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'e|event=i');

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --event argument, try --event 1 for football" unless $opts{event} || $opts{e};

my $b = new BetFair(
        {
           'username' => $opts{user} || $opts{u},
           'password' => $opts{pass} || $opts{p},
           'productId' => 82
        });

my $event = $opts{event} || $opts{e};

$b->getEvents($event);

print "*** $b->{response} *** \n";

print 1;

