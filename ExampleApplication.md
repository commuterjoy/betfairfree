# Example Code #

```
# lets setup a new BetFair object - 82 is the free api product code 

my $b = new BetFair({	username => 'foo',  
					password => 'bar',
					productId => 82 } );

# pull out the details for the market we want - (submit_request returns 0 if it 
# got an error)
unless ($b->submit_request( 'getMarket', { marketId => $marketid } )) {
	die $b->{error} if $b->{error};
}

# now parse the returned XML to get the selection id of the contender
# we want to bet on my $returnedXML = $b->{response};
[code]

# so now we want prices on our selection 
# note that submit_request returns 0 if it got an error
unless ($b->submit_request( 'getMarketPrices', { marketId => $marketid } ) ) {
	die $b->{error};
} 

# parse the xml returned for our selection and check that we're happy with the 
# price returned 
$returnedXML = $b->{response};
[code]

# So lets place a back bet
$b->submit_request( 'placeBets', { marketId => $marketid, selectionid => 
$selectionid, price => $betprice, size => $stake ,  bettype => 'B' } );

# parse the XML and make sure we got the bet on
$returnedXML = $b->{response};
[code]
# parse the xml returned for our selection and check that we're happy with the price returned 

$returnedXML = $b->{response};

[code]

# So lets place a back bet

$b->submit_request( 'placeBets', { marketId => $marketid, selectionid => $selectionid, price => $betprice, size => $stake ,  bettype => 'B' } );

# parse the XML and make sure we got the bet on

$returnedXML = $b->{response};

[code]
```