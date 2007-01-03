
  use DateTime;
  use DateTime::TimeZone;

  my $tz = DateTime::TimeZone->new( name => 'Europe/London' );

  my $dt = DateTime->now();
 
  print $dt;

