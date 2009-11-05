
=head1 ABOUT

This test returns the best 'back' price data of a given market.

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;
use DateTime;
use DateTime::TimeZone;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};

my $b = new BetFair(
        {
           'username' => $opts{user} || $opts{u},
           'password' => $opts{pass} || $opts{p},
           'productId' => 82
        });

my $tz = DateTime::TimeZone->new( name => 'Europe/London' );
my $now = DateTime->now();

# last 5
$b->getAccountStatement( 1, 5, '2006-01-01T00:00:00', $now, 'EXCHANGE');

print Dumper $b;

# last week
my $one_week = '2006-08-06T00:00:00';
$b->getAccountStatement( 1, 100, $one_week, $now, 'EXCHANGE');

print Dumper $b;



#use GD::Graph::linespoints;
#my @xLabels  = qw(  1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 );
#my @data2003 = qw(  19  24  17  21  28  25  39  43 31 39 48 41 19  24  17  21  28  25  39  43 31 39 48 41 23 14 52 26 27 28 );
#my @data     = ( \@xLabels, \@data2003 );

#my $graph = GD::Graph::linespoints->new( 230, 100 );

#$graph->set(
#        line_width       => 1,
#        markers          => 1,
#        marker_size      => 1,
#       # colours
#        bgclr            => 'white',
#        fgclr            => 'white',
#        dclrs            => [ 'black' ],
#        borderclrs       => 'white',
#        );
#
#print $graph->plot(\@data)->jpeg();
