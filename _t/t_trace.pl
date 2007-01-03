
use BetFair::Trace qw( TRACE );

=head1 ABOUT

usage: perl t_trace.pl

This tests the tracing package.

=cut

my $m = "message";

# should write value of $m two times if conf/defaults.yml 
# DEBUG param is set to '2'
TRACE($m, 1);
TRACE($m, 2);
TRACE($m, 3);



