
=head1 ABOUT

This test returns the best 'back' price data of a given market.

=cut

use BetFair;
use Data::Dumper;
use Getopt::Long;
use DateTime;
use DateTime::TimeZone;
use GD::Graph::lines;
use GD::Graph;
use List::Util qw( min max );
use Date::Calc qw( Add_Delta_Days Delta_Days Gmtime );
use Data::Dumper;

my $TYPE = 0;

my %opts = ();
GetOptions (\%opts, 'p|pass=s', 'u|user=s', 'd|days=i' );

die "you must supply a --user argument" unless $opts{user} || $opts{u};
die "you must supply a --pass argument" unless $opts{pass} || $opts{p};
die "you must supply a --days argument" unless $opts{days} || $opts{d};

my $b = new BetFair(
        {
           'username' => $opts{user} || $opts{u},
           'password' => $opts{pass} || $opts{p},
           'productId' => 82
        });

$DAYS = $opts{d};

my $tz = DateTime::TimeZone->new( name => 'Europe/London' );
my $now = DateTime->now();

$b->login;

if ( $TYPE )
 {
 # last twenty
 $b->getAccountStatement( 1, 20, '2006-01-01T00:00:00', $now, 'EXCHANGE');
 }
else
 {
 # n days ago
 ($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =  Gmtime();
 ($year,$month,$day) = Add_Delta_Days($year, $month, $day, -$DAYS );
 $month = sprintf("%02d", $month);
 $day = sprintf("%02d", $day);
 my $days_ago = "$year-$month-$day"."T00:00:00";
 $b->getAccountStatement( 1, 300, $days_ago, $now, 'EXCHANGE');
 }

#print Dumper $b;
# last week
#my $one_week = '2006-01-01T00:00:00';
#$b->getAccountStatement( 1, 100, $one_week, $now, 'EXCHANGE');
#print Dumper $b;

#my @a = ('57.25','59.25','61.25','61.4','58.4','58.47','57.11','57.19','55.6','61.94');
#$b->{_data}->{getAccountStatement}->{accountBalance} = \@a;

my $t = $b->{_data}->{getAccountStatement}->{accountBalance};

my @r = reverse @{$t};

my $start = @r[0];
my $max = max @a;
my $min = min @a;
my $mid = ( ( $max - $min ) / 2 ) + $min;
my $max_buffer = $max + ( $max * 0.05 );
my $min_buffer = $min - ( $max * 0.05 );

my @x = ();
for ( my $i = 0; $i <= $#r; $i++ )
 {
  my $a = $start;
  my $b = $r[$i];
  my $n = ( ( $b - $a ) / $a ) * 100;
  $round = sprintf("%.4f", $n x 100);
  push ( @x, $round );
 }

my $p_start = @x[0];
my $p_max = max @x;
my $p_min = min @x;
my $p_mid = ( ( $p_max - $p_min ) / 2 ) + $p_min;
my $p_max_buffer = $p_max + ( $p_max * 0.05 );
my $p_min_buffer = $p_min - ( $p_max * 0.05 );

$p_max_buffer = sprintf("%.0f", $p_max_buffer);
$p_min_buffer = sprintf("%.0f", $p_min_buffer);

print "start : $start ... max : $max ... min : $min .. mid : $mid .. max buf : $max_buffer .. min buf : $min_buffer \n\n";
print Dumper @x;

my @labels;
for ( my $i = 1; $i <= $#r + 1; $i++ )
 { push( @labels, $i ); }

my @data  = ( \@labels, \@x );

my $graph = GD::Graph::lines->new( 270, 150 );

$graph->set(
        y_label => '% change',
	y_label_position => 0.5,
        y_max_value => $p_max_buffer,
        y_min_value => $p_min_buffer,
        y_number_format => \&y_format,
	x_number_format => \&x_format,
	x_min_value => 1,
	x_ticks_number => 0,
	x_label_skip => 1000,
        y_tick_number => 10,
        y_label_skip => 2,
        box_axis => 0,
        line_width => 1,
        zero_axis_only => 1,
        # colours
	valuesclr => '#666666',
	textclr => '#666666',
	axislabelclr => '#666666',
        bgclr => 'white',
        fgclr => '#999999',
        dclrs => [ '#FF0066' ],
        );

open(IMG, ">/home/mcport/fluttr/www/feeds/$DAYS-days.png") or die $!;
binmode IMG;
print IMG $graph->plot(\@data)->png;
close IMG;

#open(SSI, '>/home/mcport/fluttr/www/feeds/mattc') or die $!;
#print SSI '<!--#set var="last.20.profit" value="'..'" -->';
#close SSI;

sub y_format
 {
 my $value = shift;
 my $ret = sprintf("%.0f", $value);
 return $ret;
 }

sub x_format
 {
 return '';
 }
