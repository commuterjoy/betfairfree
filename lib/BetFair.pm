
=head1 NAME

BetFair

=head1 SYNOPSIS

This contains the core login and submit_request methods and then a wrapper
calling method for each template type that the library supports. This means
you can call getMarket($marketid) and the library will login, make the
request and return you an XPath or XML::Simple object depending on your choice.

Each template wrapper method will make a call to the XPath variant to parse the
data if XML::Simple is not used.

See the README for examples and useful code bits.

=head1 AUTHOR

M Chadburn - July 2006

=cut

package BetFair;

use Data::Dumper;

use BetFair::Parser;
use BetFair::Request;
use BetFair::Session;
use BetFair::Template;
use BetFair::Throttle;
use BetFair::DataProc;
use BetFair::Trace qw( TRACE );
use XML::Simple;

my $PACKAGE = 'BetFair';
my $VERSION = '0.80';

my $DEBUG = 1;

sub new
{
    my ( $class, $params ) = @_;
    my $objref = {
        '_options' => $params,
        'loggedIn' => 0,
        'response' => '',
        'session' => new BetFair::Session( $params ),
        'request' =>  new BetFair::Request,
        'error' => ''
        };

    if ($objref->{_options}->{xmlsimple}) {
        $objref->{xmlsimple} = XML::Simple->new( NoAttr => 1 );
        delete $objref->{_options}->{xmlsimple};
    }

    bless $objref, $class;
    $objref->{_options}->{password} = 'HIDDEN_POST_LOGIN';

    return $objref;

}


=item submit_request

This method does all the work of getting the session, populating the template,
submitting the request and parsing the result, returning an XPath or XML::Simple
object as _data

This can either be called directly or can be called as part of a wrapper method
like getAccountFunds() below.

=cut

sub submit_request
{
    my ( $self, $type, $params ) = @_;

    $params->{session} = $self->{session}->get_session;

    my $t = new BetFair::Template;
    my $message = $t->populate( $type, $params );

    $self->{request}->message( $message, $type );
    $self->{request}->request();
    $self->{response} = $self->{request}->{response};

    # Did we catch an error in the request code ?
    if ($self->{request}->{error}) {
        $self->{error} = $self->{request}->{error};
    } else {
        my $x = new BetFair::Parser( { 'message' => $self->{response} } );
        $self->{session}->save_session($x->get_sessionToken());

        if ($self->{xmlsimple}) {
            my $xml = $self->{response};
            $xml =~ s/<n\d?:/</g;
            $xml =~ s/<\/n\d?:/<\//g;
            $self->{_data} = $self->{xmlsimple}->XMLin($xml);
            $self->{_orig} = $self->{_data};
        }

        $self->{error} = ($x->get_responseError eq 'OK') ? '' : $x->get_responseError;
    }
    return ($self->{error}) ? '0' : '1';
}

=item getAccountFunds

Returns the balance of the account

=cut

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

sub getSubscriptionInfo {
    my ( $self ) = @_;
    $self->submit_request('getSubscriptionInfo');
}

=item getActiveEventTypes

This returns the currently active event types

=cut

sub getActiveEventTypes {
    my ( $self ) = @_;
    return 0 unless ($self->submit_request('getActiveEventTypes'));
    if ($self->{xmlsimple}) {
        $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getActiveEventTypesResponse}->{Result}->{eventTypeItems};
    } else {
        $self->getActiveEventTypesXPath;
    }
}

=item getActiveEventTypesXPath

This processes the xml returned by getActiveEventTypes and parses it to return
XML::XPath object.

=cut

sub getActiveEventTypesXPath {
    my ( $self ) = @_;

    my $x = new BetFair::Parser( { 'message' => $self->{response} } );

    my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getActiveEventTypes}->{eventTypeItems} } );
    print Dumper $n if $DEBUG;

    foreach my $node ($n->get_nodelist) {
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

sub getEvents {
    my ( $self, $eventId ) = @_;
    return 0 if $eventId !~ /[0-9]+/;

    TRACE("* $PACKAGE->getEvents submitting request ",1);

    return 0 unless ($self->submit_request('getEvents',{ eventParentId => $eventId } ));

    TRACE("* $PACKAGE->getEvents parsing returned request",1);

    if ($self->{xmlsimple}) {
        if ($self->{'_data'}->{'soap:Body'}->{getEventsResponse}->{Result}->{eventItems}->{BFEvent}) {
            $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getEventsResponse}->{Result}->{eventItems}->{BFEvent};
        } else {
            $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getEventsResponse}->{Result}->{marketItems}->{MarketSummary};
        }
        $self->{'_data'} = [ $self->{'_data'} ] if (ref($self->{_data}) ne 'ARRAY');
    } else {
        $self->getEventsXPath;
    }
}

sub getEventsXPath {
    my ( $self ) = shift;

    my $x = new BetFair::Parser( { 'message' => $self->{response} } );

    my $xx = XML::XPath->new( xml => $self->{response} );

    if ( $xx->exists( $x->{xpath}->{getEvents}->{marketItems} ))
    {
        TRACE("* $PACKAGE->getEventsXPath : obtaining events markets for '$marketId'", 1);

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

sub getMarket {
    my ($self, $marketId ) = @_;

    TRACE("* $PACKAGE->getMarket : obtaining market data for '$marketId'", 1);
    return 0 unless ($self->submit_request('getMarket',{ marketId => $marketId } ));

    if ($self->{xmlsimple}) {
        $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getMarketResponse}->{Result}->{Market}->{runners};
    } else {
        $self->getMarketXPath($marketId);
    }
}

sub getMarketXPath {
    my ($self, $marketId ) = @_;

    #clean data structure
    TRACE("$PACKAGE->getMarket : cleaning data structure \$self->{'_data'}->{'getMarket'}->{$marketId}", 1);
    $self->{'_data'}->{'getMarket'}->{$marketId} = {};

    # get general market details
    my $x = new BetFair::Parser( { 'message' => $self->{response} } );

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


sub getAccountStatement {

    my ($self, $startRecord, $recordCount, $startDate, $endDate, $itemsIncluded ) = @_;

    TRACE("* $PACKAGE->getAccountStatement : ", 1);
    return 0 unless ($self->submit_request('getAccountStatement',{
        startRecord => $startRecord,
        recordCount => $recordCount,
        startDate => $startDate,
        endDate => $endDate,
        itemsIncluded => 'ALL'
    } ));

    if ($self->{xmlsimple}) {
        $self->{'_data'} = $self->{'_data'}->{'soap:Body'};
    } else {
        $self->getMarketXPath($marketId);
    }

}

sub getAccountStatementXPath {
    my ($self) = @_;

    my $x = new BetFair::Parser( { 'message' => $self->{response} } );

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

sub getMarketPrices {
    my ($self, $marketId ) = @_;

    TRACE("* $PACKAGE->getMarketPrices : obtaining market prices data for '$marketId'", 1);
    $self->submit_request('getMarketPrices',{ marketId => $marketId } );

    if ($self->{xmlsimple}) {
        $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getMarketPricesResponse}->{Result}->{marketPrices};
    } else {
        # TODO : need to call out to xpath processor here.
    }
}

sub getMarketPricesCompressed {
    my ($self, $marketId ) = @_;

    TRACE("* $PACKAGE->getMarketPricesCompressed : obtaining compressed market prices data for '$marketId'", 1);
    $self->submit_request('getMarketPricesCompressed',{ marketId => $marketId } );

    if ($self->{xmlsimple}) {
        $self->{'_data'} = $self->{'_data'}->{'soap:Body'}->{getMarketPricesCompressedResponse}->{Result}->{marketPrices};
        BetFair::DataProc::proc_getMarketPricesCompressedXMLSimple($self);
    } else {
        # TODO : need to call out to xpath processor here.
    }
}

# for a given market, extract the price, amount available, id for each selection.
sub getBestPricesToBack {
    my ($self, $marketId ) = @_;

    TRACE("$PACKAGE->getBestPricesToBack : obtaining market price data for '$marketId'", 1);

    $self->submit_request('getMarketPrices',{ marketId => $marketId } );

    #clean
    $self->{'_data'}->{'getMarketPrices'}->{$marketId}->{'getBestPricesToBack'} = {};

    my $x = new BetFair::Parser( { 'message' => $self->{response} } );

    my $n = $x->get_nodeSet( { xpath => $x->{xpath}->{getBestPricesToBack}->{runnerPrices} } );

    # scrub data array so we don't continually append market prices
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

1;
