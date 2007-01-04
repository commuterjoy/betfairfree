
=head1 NAME

BetFair

=head1 SYNOPSIS

Mostly factory methods for other parts of the system.

=head1 AUTHOR

M Chadburn - July 2006

=cut

package BetFair;

use BetFair::Parser;
use BetFair::Request;
use BetFair::Session;
use BetFair::Template;
use BetFair::Throttle;
use Data::Dumper;
use BetFair::Trace qw( TRACE );

my $PACKAGE = 'BetFair';
my $VERSION = '';

my $DEBUG = 0;

sub new
{
	my ( $class, $params ) = @_;
	my $objref = {
		'_options' => $params,
		'loggedIn' => 0,
		};
	bless $objref, $class;
	return $objref;
}

sub login
 {
  TRACE("* $PACKAGE->login : attempting to log in", 1);
  my ( $self ) = @_;
  my $s = new BetFair::Session( $self->{'_options'} );
  $self->{sessionToken} = $s->{key};
  $self->{loggedIn} = 1;
  $self->{_options}->{password} = 'HIDDEN_POST_LOGIN';
  return 1;
 }

sub getAccountFunds
 {
 my ( $self ) = @_;

 TRACE("* $PACKAGE->getAccountFunds : obtaining your account funds", 1);

 print "You must log in" unless $self->{loggedIn};

 my $t = new BetFair::Template;
 my $params2 = {
               session => $self->{sessionToken}
             };
 my $message = $t->populate( 'getAccountFunds', $params2 );

 my $r = new BetFair::Request;
 $r->message( $message, 'getAccountFunds' );
 $r->request();
# print "*** $r->{response} *** \n" if $DEBUG;
# print Dumper $r if $DEBUG;

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 my $session = $x->get_sessionToken();

# update object session token. TODO - should we?
# $self->{sessionToken} = $s->{key};

 while ( my ($key, $value) = each( %{$x->{xpath}->{getAccountFunds}} ) )
 {
   print "*** $key => $value => " . $x->get_nodeSet( { xpath => $value } )->string_value() . "\n" if $DEBUG;
   $self->{'_data'}->{'getAccountFunds'}->{$key} = $x->get_nodeSet( { xpath => $value } )->string_value();
 }
 # TODO - add error code
 }

sub getSubscriptionInfo
 {
 my ( $self ) = @_;
 my $t = new BetFair::Template;
 my $params2 = {
               session => $self->{sessionToken}
             };
 my $message = $t->populate( 'getSubscriptionInfo', $params2 );
 my $r = new BetFair::Request;
 $r->message( $message, 'getSubscriptionInfo' );
 $r->request();
 print "*** $r->{response} *** \n"
 }

sub getActiveEventTypes
 {
 my ( $self ) = @_;
 my $t = new BetFair::Template;
 my $params2 = {
               session => $self->{sessionToken}
             };
 my $message = $t->populate( 'getActiveEventTypes', $params2 );
 my $r = new BetFair::Request;
 $r->message( $message, 'getActiveEventTypes' );
 $r->request();
 #print "*** $r->{response} *** \n"

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 #my $session = $x->get_sessionToken();
 my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getActiveEventTypes}->{eventTypeItems} } );
 print Dumper $n if $DEBUG;
 
 foreach my $node ($n->get_nodelist) 
 {
  my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
  my $e = $xp->getNodeText( '//name' );
  my $i = $xp->getNodeText( '//id' );
  $self->{'_data'}->{'getActiveEventTypes'}->{$i} = "".$e;

    print "FOUND\n\n", 
     XML::XPath::XMLParser::as_string($node),
     "\n\n" if $DEBUG;
     print $e . $i . $/.$/ if $DEBUG;
    }
 }


# TODO - this is more than just a factory method, consider moving to BetFair::Parser::getEvents ?
sub getEvents
 {
 my ( $self, $eventId ) = @_;

 return 0 if $eventId !~ /[0-9]+/;

 my $t = new BetFair::Template;
 my $params2 = {
   session => $self->{sessionToken},
   eventParentId => $eventId,
   };
 my $message = $t->populate( 'getEvents', $params2 );
 my $r = new BetFair::Request;
 $r->message( $message, 'getEvents' );
 $r->request();
 
 my $x = new BetFair::Parser( { 'message' => $r->{response} } );

 my $xx = XML::XPath->new( xml => $r->{response} );

 if ( $xx->exists( $x->{xpath}->{getEvents}->{eventItems} ) )
  {
  print "Events \n";
  my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getEvents}->{BFEvent} } );

  #  clean, so we don't end up collating data multiple event calls
  $self->{'_data'}->{'getEvents'}->{'events'}->{$eventId} = {};

  foreach my $node ($n->get_nodelist)
  {
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
   my $e = $xp->getNodeText( '//eventName' );
   my $i = $xp->getNodeText( '//eventId' );
   $self->{'_data'}->{'getEvents'}->{'events'}->{$eventId}->{$i} = "".$e;
   }
  }

 if ( $xx->exists( $x->{xpath}->{getEvents}->{marketItems} ))
  {
  print "Markets \n";

  my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getEvents}->{marketSummary} } );
  $self->{'_data'}->{'getEvents'}->{'markets'}->{$eventId} = {};

  foreach my $node ($n->get_nodelist)
  {
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
   my $e = $xp->getNodeText( '//marketName' );
   my $i = $xp->getNodeText( '//marketId' );
   $self->{'_data'}->{'getEvents'}->{'markets'}->{$eventId}->{$i} = "".$e;
  }

  }

 }

sub getMarket
{
 my ($self, $marketId ) = @_;

 TRACE("* $PACKAGE->getMarket : obtaining market data for '$marketId'", 1);

 my $t = new BetFair::Template;
 my $params = {
 		session => $self->{sessionToken},
                marketId => $marketId,
             };
 my $message = $t->populate( 'getMarket' , $params );

 my $r = new BetFair::Request;
 $r->message( $message, 'getMarket' );
 $r->request();

 #print "getMarket response" . $r->{response} if $DEBUG;

 #clean data structure
 TRACE("$PACKAGE->getMarket : cleaning data structure \$self->{'_data'}->{'getMarket'}->{$marketId}", 1);
 $self->{'_data'}->{'getMarket'}->{$marketId} = {};

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );

 while ( my ($key, $value) = each( %{$x->{xpath}->{getMarket}} ) )
 {
   my $result = $x->get_nodeSet( { xpath => $value } )->string_value();
   TRACE("$PACKAGE->getMarket : Found '$result', assigning to '$key'", 1);
   self->{'_data'}->{'getMarket'}->{$marketId}->{$key} = $result;
 }

}

sub getBestPricesToBack
{
 my ($self, $marketId ) = @_;

 TRACE("* $PACKAGE->getBestPricesToBack : obtaining market price data for '$marketId'", 1);

 my $t = new BetFair::Template;
 my $params = {
         session => $self->{sessionToken},
         marketId => $marketId,
         };
 my $message = $t->populate( 'getMarketPrices' , $params );

 TRACE("* $PACKAGE->getBestPricesToBack : $message", 1);

 my $r = new BetFair::Request;
 $r->message( $message, 'getMarketPrices' );
 $r->request();
 
 print "getMarket response" . $r->{response} if $DEBUG;
 print Dumper $r if $DEBUG;

 #clean 
 $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{'getBestPricesToBack'} = {};

 my $x = new BetFair::Parser( { 'message' => $r->{response} } ); 

 my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getBestPricesToBack}->{runnerPrices} } );

 foreach my $node ($n->get_nodelist)
 {
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($n->get_nodelist) );
   my $p = $xp->getNodeText( '//bestPricesToBack/*[1]/price' );
   my $a = $xp->getNodeText( '//bestPricesToBack/*[1]/amountAvailable' );
   $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{getBestPricesToBack}->{price} = "".$p;
   $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{getBestPricesToBack}->{amount} = "".$a;   
 }

}


sub getAccountStatement
{

 TRACE("* $PACKAGE->getAccountStatement : ", 1);

 my ($self, $startRecord, $recordCount, $startDate, $endDate, $itemsIncluded ) = @_;
 my $t = new BetFair::Template;
 my $params = {
         session => $self->{sessionToken},
         startRecord => $startRecord,
	 recordCount => $recordCount,
	 startDate => $startDate,
	 endDate => $endDate,
	 itemsIncluded => 'ALL'
         };
 my $message = $t->populate( 'getAccountStatement' , $params );

# print $message;

 my $r = new BetFair::Request;
 $r->message( $message, 'getAccountStatement' );
 $r->request();
 
 print $r->{response};

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 
 my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getAccountStatement}->{items} } );

 # clean
 $self->{'_data'}->{'getAccountStatement'} = {};
 my (@balance, @settled);

 foreach my $node ($n->get_nodelist)
 {
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
   my $p = $xp->getNodeText( '//accountBalance' );
   my $s = $xp->getNodeText( '//settledDate' );
   push( @balance, "".$p );
   push( @settled, "".$s );
 }
   $self->{'_data'}->{'getAccountStatement'}->{accountBalance} = \@balance;
   $self->{'_data'}->{'getAccountStatement'}->{settledDate} = \@settled;
}

1;