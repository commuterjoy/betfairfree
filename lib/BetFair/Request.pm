

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

my $soap_uri = 'https://api.betfair.com/betex-api-public-ws/v2/BFService';
my $soap_header = '"https://api.betfair.com/betex-api-public-ws/BFServiceV2"';

sub new
{
        my $class = $_[0];
        my $objref = {
		response => '',
		message => '',
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

 #print "BetFair::Request::request() " . $self->{message} if $DEBUG;

 TRACE("$PACKAGE : LWP calling $soap_uri", 1);

 my $userAgent = LWP::UserAgent->new();
 my $request = HTTP::Request->new( POST => $soap_uri );

 $request->header( SOAPAction => $soap_header );
 $request->content($self->{message});
 $request->content_type("text/xml; charset=utf-8");

 #print "ok to call : " .  $self->{throttle}->ok_to_call( $self->{type} ) . "\n" if $DEBUG;
 
 if ( $self->{throttle}->ok_to_call( $self->{type} ) )
 {
  TRACE("$PACKAGE : Throttle reports ok to call", 1);
  my $response = $userAgent->request($request);
  $self->{response} = $response->{'_content'};
  $self->{throttle}->touch( $self->{type} );

  TRACE($response->{'_content'}, 2);
 
  # check response is parsable
  my $xs = new XML::Simple();
  my $xss = eval{ $xs->XMLin( $self->{response} ) };
  if ( $@ )
  {
   TRACE("$PACKAGE : Response unparsable, ie. not XML. Is the BetFair service ok? http://service.betfair.info/");
   die( $! );
  }	
 }
 else
 {
  $self->{response} = '';
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

