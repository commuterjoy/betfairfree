#!/usr/bin/perl

=head1 NAME

BetFair::Throttle

=head1 SYNOPSIS

Betfair API limits the number of requests made by a client application per 
clock minute, eg. you can only login 24 times in each minute. However you can
login 24 times in the last 5 seconds of a minute and 24 times in the first 
5 seconds of the next minute.

BetFair::Throttle helps manage API calls made by your client by throttling 
the requests.

That is to say, Throttle will record the time of every request, and prevent 
further calls if the number of requests exceeds the allotted total.

=head1 NOTES

It is critically important that your machine is synced to several valid NTP
timesources since the counter is reset every minute at Betfair, your machine 
needs to be as close to this as possible so that you don't get throttled when
you think you're ok and vice versa.

=head1 AUTHOR

M Chadburn - July 2006

=head1 TODO

introduce sleeper method, to wait until it's ok to continue program flow

move the %throttle data structure to a config file 

need to make the touch & count values persistent, ie. for multi-threaded programs to share 

=cut


package BetFair::Throttle;

use strict;
use Data::Dumper;
use Time::HiRes qw ( time );
use BetFair::Config;
use BetFair::Trace qw( TRACE );

my $PACKAGE = 'BetFair::Throttle';
my $VERSION = '';

my $conf = new BetFair::Config;
my $cycle = $conf->{cycle} ? $conf->{cycle} : '60';

# template data structure for holding information about the number of API requests
# allowed every minute.
my %throttle = 
	(
	 'login' => { 'limit' => 24, 'call' => 0, 'count' => 0 },
	 'getAccountFunds' => { 'limit' => 1, 'call' => 0, 'count' =>  0 },		
	 'getEvents' => { 'limit' => 100, 'call' => 0, 'count' =>  0 },
	 'getMarket' => { 'limit' => 5, 'call' => 0, 'count' =>  0 },
	 'getMarketPrices' => { 'limit' => 10, 'call' => 0, 'count' =>  0 },
	 'getMarketPricesCompressed' => { 'limit' => 60, 'call' => 0, 'count' =>  0 },
	 'getAccountStatement' => { 'limit' => 2, 'call' => 0, 'count' =>  0 },
	 'placeBets' => { 'limit' => 60, 'call' => 0, 'count' =>  0 },
	);


sub new {
    my $class = shift;
    my $objref = \%throttle;
    bless $objref, $class;
	TRACE("$PACKAGE : created a new instance of throttle",1);
    return $objref;
}

# Increment call to $method by 1
sub touch {
	my ( $self, $method ) = @_;
    if ( ! $self->{$method}->{call} ) {
       $self->{$method}->{call} = int((time-1)/60); 
    }
    $self->{$method}{count}++;
    return 1;
}

=item 

The ok_to_call method needs to work out how many times the method has been 
called in the last minute and do all the cleaning up so it can be confident 
whether we can be called again. 

=cut

sub ok_to_call
{
	my ( $self, $method ) = @_;

    # Fast as you like, user has turned off throttling
    return 1 if ($cycle == 1);
       
    # Would calling $method again push us over what we think the method is ?
	if ( ($self->{$method}->{count}+1) > $self->{$method}->{limit} ) {
        #full minutes since epoch, 1 second slow for safety
        my $thisminute = int((time-1)/60); 
        if ($self->{$method}->{call} < $thisminute ) {
            $self->{$method}->{call} = $thisminute;
            $self->{$method}->{count} = 0;
        } else {
            TRACE("$PACKAGE->ok_to_call : Throttle limit exceeded on '$method'", 1);
	        return 0;
        }
	}

	# otherwise ok  
    print "$PACKAGE->ok_to_call : Throttle limit ok on '$method' (".$self->{$method}->{count}." / ".$self->{$method}->{limit} .")";
	TRACE("$PACKAGE->ok_to_call : Throttle limit ok on '$method' (".$self->{$method}->{count}." / ".$self->{$method}->{limit} .")", 1);
	return 1;
}

1;
