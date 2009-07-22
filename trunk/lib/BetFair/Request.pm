#!/usr/bin/perl -w

=head1 NAME

BetFair::Request

=head1 SYNOPSIS

This package makes the actual HTTP/SOAP requests to the Betfair API.

=head1 DEPENDENCIES

This package uses use LWP::UserAgent and HTTP::Request.

=head1 AUTHOR

M Chadburn - July 2006

=cut

package BetFair::Request;

use strict;
use LWP::UserAgent;
use HTTP::Request;
use BetFair::Throttle;
use Data::Dumper;
use BetFair::Config;
use BetFair::Trace qw( TRACE );
use XML::Simple;

my $PACKAGE = 'BetFair::Request';
my $VERSION = '';

my $conf = new BetFair::Config;
my $logfile = $conf->{log} ? $conf->{log} . 'request.log' : '';

# All calls whose type is below have to go to the global api, everything else 
# should go to the exchange server. See Betfair API docs.
my @globalAPI = qw(addPaymentCard convertCurrency createAccount deletePaymentCard depositFromPaymentCard forgotPassword getActiveEventTypes getAllCurrencies getAllEventTypes getEvents getPaymentCard getSubscriptionInfo keepAlive login logout modifyPassword modifyProfile retrieveLIMBMessage submitLIMBMessage transferFunds updatePaymentCard viewProfile withdrawToPaymentCard );

sub new
{
        my $class = $_[0];
        my $objref = {
		response => '',
		message => '',
        error => '',
		logfile => $logfile,
		type => '',
	        throttle => new BetFair::Throttle
                };
        bless $objref, $class;
	TRACE("$PACKAGE : new request object created", 1);
        return $objref;
}

sub request
{

 my ($self) = shift;

 my $soap_uri = $conf->{soap_exchange_uri};
 $soap_uri = $conf->{soap_global_uri} if (grep(/$self->{type}/, @globalAPI));

 my $soap_header = '"' . $soap_uri .'"';

 TRACE("$PACKAGE : LWP calling $soap_uri", 1);

 my $userAgent = LWP::UserAgent->new();
 $userAgent->env_proxy;
 
 my $request = HTTP::Request->new( POST => $soap_uri );

 $request->header( SOAPAction => $soap_header );
 $request->content($self->{message});
 $request->content_type("text/xml; charset=utf-8");
  
 # reset the error string;
 $self->{error} = '';

 if ( $self->{throttle}->ok_to_call( $self->{type} ) )
 {
  TRACE("$PACKAGE : Throttle reports ok to call", 1);
  my $response = $userAgent->request($request);
  $self->{response} = $response->{'_content'};
  $self->{throttle}->touch( $self->{type} );
  
  # log the request/response
  
  if ( $conf->{log} )
  {
      TRACE("$PACKAGE->request log directory '$self->{logfile}' does not exist", 1) unless ( -e $self->{logfile} );
      
      open(LOG, ">>".$self->{logfile}) || TRACE($!);
      print LOG "--- Request ----------\n";
      print LOG $self->{message} . $/;  # TODO - password isn't hidden here & should be.
      print LOG "--- Response ---------\n";
      print LOG $response->{'_content'} . $/;
      print LOG "\n\n**********************\n\n";
      close LOG;
  }
  
  TRACE($response->{'_content'}, 2);

  # check response is parsable
  my $xs = new XML::Simple();
  my $xss = eval{ $xs->XMLin( $self->{response} ) };
  if ( $@ )
  {
   TRACE("$PACKAGE : Response unparsable, ie. not XML. Is the BetFair service ok? http://service.betfair.info/");
   $self->{error} = "$PACKAGE : Response unparsable, ie. not XML. Is the BetFair service ok? http://service.betfair.info/\n" . $self->{message} . "\n\n" . $self->{response};
  }	
 }
 else
 {
  $self->{response} = '';
  $self->{error} = "$PACKAGE : Slow down. Throttle reports limit exceeded for " . $self->{type} . " - request not made.";
  TRACE("$PACKAGE : Slow down. Throttle reports false, request not made.", 1); 
 }

 return 1;
}

sub message
{
 my ($self, $message, $type) = @_;
 TRACE("$PACKAGE->message : assigning new message of type '$type' to request", 1);
 $self->{message} = $message;
 $self->{type} = $type; 
 return 1;
}

1;

