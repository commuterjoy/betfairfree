#!/usr/bin/perl

=head1 NAME

BetFair::Template

=head1 SYNOPSIS

This package helps to construct the SOAP envelopes the client needs in order to
request data from the Betfair API.

It does this by receieving a data structure from the calling program containing
SOAP parameter values, then populating a corresponding XML template with this
data.

The template files are held in the ./tmpl/soap-responses directory, one per SOAP method.

=head1 TEMPLATES 
 
getAccountFunds
getAccountStatement
getActiveEventTypes
getEvents
getMarket
getMarketPrices
getMarketPricesCompressed - shorthand version of market prices xml
getSubscriptionInfo 
keepAlive - make sure we stay logged in
login
placeBets - place a single bet (either back or lay)
 
=head1 DEPENDENCIES

This package uses HTML::Template.

=head1 AUTHOR

M Chadburn - July 2006

=cut	

package BetFair::Template;

use HTML::Template;
use BetFair::Trace qw( TRACE );
use BetFair::Config;

my $PACKAGE = 'BetFair::Template';
my $VERSION = 1;

sub new
{
	my $class = $_[0];
	my $objref = {
		params => $_[1],
		soap_method => $_[2],
		};
	bless $objref, $class;
	return $objref;
}

sub populate
{
 
my ($self, $t, $p) = @_;

my $path = 'tmpl/soap-responses/'.$t;

TRACE("$PACKAGE : opening template '$path'", 1);
  
if ( -e $path )
 {
  my $template = HTML::Template->new(filename => $path);

  TRACE("$PACKAGE : populating template with paramaters", 1);
  while( my ($k, $v) = each %{$p} )
   {
	TRACE("$PACKAGE :  $k => $v", 2);
    $template->param( $k => $v ); 
   }
  
  TRACE("$PACKAGE : success. returning fully populated template", 1);
  TRACE("$PACKAGE : ".$template->output, 3);
  return $template->output;
  
 }
 else
 	{ TRACE("$PACKAGE : can't open '$path', are you sure it exists?", 1); }
}

1;
