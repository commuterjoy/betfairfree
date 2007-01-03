
=head1 NAME

BetFair::Parser

=head1 SYNOPSIS

Responsible for rendering the SOAP responses in to a usable data structure.

This package will load a YAML file containing a set of XPath statements.

It also contains various methods for accessing both individual node or attribute values
as well as nodesets.  
 
=head1 AUTHOR

M Chadburn - July 2006

=cut

package BetFair::Parser;

use strict;
use XML::XPath;
use YAML qw( LoadFile );
use Data::Dumper;
use BetFair::Config;
use BetFair::Trace qw( TRACE );

my $PACKAGE = 'BetFair::Parser';
my $VERSION = '';

sub new
{
        my ( $class, $params ) = @_;
		
	my $conf = ( $params->{config} ) ? new BetFair::Config( $params->{config} ) : new BetFair::Config;

	TRACE("$PACKAGE : Creating a new Parser, with data file '$conf->{xpath_conf}'",1);

        my $objref = {
		'message' => $params->{message},
		'xpath' => LoadFile( $conf->{xpath_conf} ),
		};

        bless $objref, $class;
        return $objref;
}

# TODO - get_nodeset(xpath);

sub get_responseError
{
 my ( $self, $message ) = @_;

 my $m = ($message) ? $message : $self->{message};

 TRACE("$PACKAGE->get_responseError : Getting error using '$self->{xpath}->{generalResponse}->{errorCode}'", 1);
 
 my $xp = XML::XPath->new( xml => $m );
 my $nodeset = $xp->find( $self->{xpath}->{generalResponse}->{errorCode} );

 TRACE("$PACKAGE->get_responseError : Found '".$nodeset->string_value()."'", 1);

 return $nodeset->string_value();
}

sub get_sessionToken
{
  my ( $self, $message ) = @_;

  my $m = ($message) ? $message : $self->{message};

  TRACE("$PACKAGE->get_sessionToken : Getting session token using '$self->{xpath}->{generalResponse}->{sessionToken}'", 1);
 
  my $xp = XML::XPath->new( xml => $m );
  my $nodeset = $xp->find( $self->{xpath}->{generalResponse}->{sessionToken} );
 
  TRACE("$PACKAGE->get_sessionToken : Found '".$nodeset->string_value()."'", 1);

  return $nodeset->string_value();
}


sub get_nodeSet
{
  my ( $self, $params ) = @_;

  my $m = ( $params->{message} ) ? $params->{message} : $self->{message};
  my $x = $params->{xpath};

  TRACE("$PACKAGE->get_nodeSet : Getting node set using '$x'", 1);
    
  my $xp = XML::XPath->new( xml => $m );
  my $nodeset = $xp->find( $x );

  return $nodeset;
}

1;




