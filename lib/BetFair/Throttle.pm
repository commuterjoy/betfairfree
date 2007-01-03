
=head1 NAME

BetFair::Throttle

=head1 SYNOPSIS

Betfair API limits the number of requests made by a client application per minute, eg. you 
can only login 24 times in 60 seconds.

BetFair::Throttle helps manage API calls made by your client by throttling the requests.

That is to say, Throttle will record the time of every request, and prevent 
futher calls if the number of requests exceeds the alotted total.

=head1 AUTHOR

M Chadburn - July 2006

=head1 TODO

introduce sleeper method, to wait until it's ok to continue program flow

move the %throttle data structure to a config file 

need to make the touch & count values persistant, ie. for multi-threaded programs to share 

=cut


package BetFair::Throttle;

use strict;
use Data::Dumper;
use Time::HiRes qw ( time );
use BetFair::Config;
use BetFair::Trace qw( TRACE );

my $PACKAGE = 'BetFair::Throttle';
my $VERSION = '';

my $cycle = 60; # seconds

# TODO 
#  - introduce sleeper method, to wait until it's ok to continue program flow
#  - move the %throttle data structure to a config file 
#  - need to make the touch & count values persistant, ie. for multi-threaded programs to share 

# template data structure for holding information about the number of API requests
# allowed every minutes.
my %throttle = 
	(
	 'login' => { 'limit' => 24, 'call' => 0, 'count' => 0 },
	 'getAccountFunds' => { 'limit' => 1, 'call' => 0, 'count' =>  0 },		
	 'getEvents' => { 'limit' => 100, 'call' => 0, 'count' =>  0 },
	 'getMarket' => { 'limit' => 60, 'call' => 0, 'count' =>  0 },
	 'getMarketPrices' => { 'limit' => 60, 'call' => 0, 'count' =>  0 },
	 'getAccountStatement' => { 'limit' => 2, 'call' => 0, 'count' =>  0 },
	);


sub new
{
        my $class = shift;
        my $objref = \%throttle;
        bless $objref, $class;
	TRACE("$PACKAGE : created a new instance of throttle",1);
        return $objref;
}


# record number of times method is called in a 60 second cycle
sub touch
{
	my ( $self, $method ) = @_;

	# if the last call is less than a minute ago increment count
	my $t = time();
	$t =~ /([0-9]+)\./; 
		
	# difference in seconds between first call & now
	my $diff = $1 - $self->{$method}{call};
	TRACE("$PACKAGE->touch : difference between first call and now is '$diff' seconds", 1); 	

	# count the number of calls made in a cycle
	if ( $diff < $cycle )
		{
                 $self->{$method}{count}++;
		 TRACE("$PACKAGE->touch : incrementing method '$method' count to '".$self->{$method}{count}."'", 1);
		}
	else 
		{ 
		TRACE("$PACKAGE->touch : resetting method '$method' count to 0", 1);
		# reset count to 1, then log the time of this call
		$self->{$method}{count} = 1;
		$self->{$method}{call} = $1;
		}		
		
	return 1;
}


sub ok_to_call
{
	my ( $self, $method ) = @_;

	my $c = $self->{$method}->{count};
	my $l = $self->{$method}->{limit};

	TRACE("$PACKAGE->ok_to_call : count = '$c', limit = '$l'", 1);
	
	if ( $c > $l ) 
	{
	 TRACE("$PACKAGE->ok_to_call : Throttle limit exceeded on '$method'", 1);
	 return 0;
	}

	# otheriwse ok  
	TRACE("$PACKAGE->ok_to_call : Throttle limit ok on '$method'", 1);
	return 1;
}

1;
