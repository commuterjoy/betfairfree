
use BetFair::Config;
use Data::Dumper;

=head1 ABOUT

usage: perl t_config.pl

This tests the config reader package.

=cut

# default file 
my $a = new BetFair::Config;

print Dumper $a;

# my $b = new BetFair::Config( 'conf/foo.yml' );
# print Dumper $b;

print "**" . $a->{debug} . "**";



