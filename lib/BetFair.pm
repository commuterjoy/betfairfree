
=head1 NAME

BetFair

=head1 SYNOPSIS

Mostly factory methods for other parts of the system. See the README for
examples and useful code bits

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
		'response' => '',
		'error' => '',
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

sub submit_request
{
 my ( $self, $type, $params ) = @_;

 $self->login unless ( $self->{loggedIn} );

 my $t = new BetFair::Template;
 $params->{session} = $self->{sessionToken};

 my $message = $t->populate( $type, $params );

 my $r = new BetFair::Request;
 $r->message( $message, $type );
 $r->request();

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 $self->{sessionToken} =  $x->get_sessionToken();
 $self->{response} = $r->{response};
 
 $self->{error} = ($x->get_responseError eq 'OK') ? '' : $x->get_responseError;
 return ($self->{error}) ? '0' : '1';
}

sub getAccountFunds
 {
 my ( $self ) = @_;

 TRACE("* $PACKAGE->getAccountFunds : obtaining your account funds", 1);

 if ($self->submit_request('getAccountFunds')) {
	 my $p = new BetFair::Parser( { 'message' => $self->{response} }  ); 
	 my $balancenode = $p->get_nodeSet( { 'xpath' => '/soap:Envelope/soap:Body/n:getAccountFundsResponse/n:Result/availBalance' } );
	 return $balancenode->string_value();
 } else {
	 return 0;
 }
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

 print "getMarket response" . $r->{response};

 #clean data structure
 TRACE("$PACKAGE->getMarket : cleaning data structure \$self->{'_data'}->{'getMarket'}->{$marketId}", 1);
 $self->{'_data'}->{'getMarket'}->{$marketId} = {};

 # get general market details
 my $x = new BetFair::Parser( { 'message' => $r->{response} } );

 while ( my ($key, $value) = each( %{$x->{xpath}->{getMarket}} ) )
 {
   my $result = $x->get_nodeSet( { xpath => $value } )->string_value();
   TRACE("$PACKAGE->getMarket : Found '$result', assigning to '$key'", 1);
   $self->{'_data'}->{'getMarket'}->{$marketId}->{$key} = $result;
 }

 # get details of runners
 my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getMarketRunners}->{runners} } );
 
 # temp array to store selection's 
 my @data;

 # for each selection in the market extract current price, money available, and selection id
 foreach my $node ($n->get_nodelist)
 {
   # temp hash
   my %g;
   
   # xpaths to extract text nodes
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
   my $n = $xp->getNodeText( '//name' );
   my $s = $xp->getNodeText( '//selectionId' );
   
   $g{name} = "".$n;
   $g{selection} = "".$s;
   
   # add the temporary hash to the selection array, and add to $self
   push(@data, \%g); 
   $self->{'_data'}->{'getMarket'}->{$marketId}->{runners} = \@data;
 }


}

# for a given market, extract the price, amount available, id for each selection.
sub getBestPricesToBack
{
 my ($self, $marketId ) = @_;

 TRACE("$PACKAGE->getBestPricesToBack : obtaining market price data for '$marketId'", 1);

 my $t = new BetFair::Template;
 my $params = {
         session => $self->{sessionToken},
         marketId => $marketId,
         };
 my $message = $t->populate( 'getMarketPrices' , $params );

 my $r = new BetFair::Request;
 $r->message( $message, 'getMarketPrices' );
 $r->request();
 
 print "getMarket response" . $r->{response} if $DEBUG;
 print Dumper $r if $DEBUG;

 #clean 
 $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{'getBestPricesToBack'} = {};

 my $x = new BetFair::Parser( { 'message' => $r->{response} } ); 

 my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getBestPricesToBack}->{runnerPrices} } );
 
 # temp array to store selection's 
 my @data;

 # for each selection in the market extract current price, money available, and selection id
 foreach my $node ($n->get_nodelist)
 {
   # temp hash
   my %g;
   
   # xpaths to extract text nodes
   my $xp = XML::XPath->new( xml => XML::XPath::XMLParser::as_string($node) );
   my $p = $xp->getNodeText( '//bestPricesToBack/*[1]/price' );
   my $a = $xp->getNodeText( '//bestPricesToBack/*[1]/amountAvailable' );
   my $s = $xp->getNodeText( '//selectionId' );
   
   $g{price} = "".$p;
   $g{amount} = "".$a;
   $g{selection} = "".$s;
   
   # add the temporary hash to the selection array, and add to $self
   push(@data, \%g); 
   $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{getBestPricesToBack} = \@data;
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
