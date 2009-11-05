
=head1 ABOUT

usage: perl t_betfair.pl

This test invokes the BetFair package.

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --passwd argument" unless $opts{passwd} || $opts{p};

my $b = new BetFair(
	{
	   'username' => $opts{user} || $opts{u},
 	   'password' => $opts{pass} || $opts{p},
	   'productId' => 82
	});

$b->getActiveEventTypes;

print Dumper $b->{_data}->{getActiveEventTypes};

 my $input = 1;
 while( $input != 0 )
 {
  print "hi. type an event to navigate to => ";
  $input = <STDIN>;
  chomp( $input );

  if ( $input =~ /m\:([0-9]+)/ )
  {
   $b->getMarket( $1 );
   print Dumper $b->{_data}->{getMarket};
  }
  elsif ( $input != 0 )
  {
   $b->getEvents( $input );
   print Dumper $b->{_data}->{getEvents};
  }
 }



