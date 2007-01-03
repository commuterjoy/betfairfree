
=head1 NAME

BetFair::Config

=head1 SYNOPSIS

Interface to configuration files.

=head1 AUTHOR

M Chadburn - August 2006

=cut

package BetFair::Config;

use strict;
use YAML qw( LoadFile );

sub new
{
	my ( $class, $filename ) = @_;
	$filename = ( $filename ) ? $filename : 'conf/default.yml';

	# TODO - do file exists test, return error 
	my $objref = LoadFile( $filename );
	bless $objref, $class;
	return $objref;
}

1;




