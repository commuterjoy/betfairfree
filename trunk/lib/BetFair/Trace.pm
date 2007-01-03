
=head1 NAME

BetFair::Trace

=head1 SYNOPSIS

Exportable tracing.

=head1 AUTHOR

M Chadburn - August 2006

=cut

package BetFair::Trace;

use BetFair::Config;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( TRACE );

my $DEBUG = new BetFair::Config( 'conf/default.yml' )->{debug};

sub TRACE
 { 
  my $message = shift;
  my $level = shift || 0;
    
  if ( $DEBUG >= $level )
 	{  print "$message\n"; }
 }

1;