

use DateTime;
use DateTime::TimeZone;
use Date::Calc qw( Add_Delta_Days Gmtime );
use Data::Dumper;


($year,$month,$day, $hour,$min,$sec, $doy,$dow,$dst) =  Gmtime();

($year,$month,$day) = Add_Delta_Days($year, $month, $day, -28 );

$month = sprintf("%02d", $month);
$day = sprintf("%02d", $day);
my $twenty_eight_days_ago = "$year-$month-$day"."T00:00:00";

print $twenty_eight_days_ago . $/;
