#!/usr/bin/perl 

=head1 ABOUT

Reads and dumps out a YML file created by log_best_prices.pl. Handy for validation.

=head1 USAGE

 perl _t/yml_validator.pl [log file]
 
 eg. perl _t/yml_validator.pl "20481083.txt"

 $VAR1 = {
          'Sun Jul  8 16:45:39 2007' => [
                                          {
                                            'amount' => '9351.71',
                                            'selection' => '2251402',
                                            'price' => '1.19'
                                          },
                                          {
                                            'amount' => '931.48',
                                            'selection' => '2251410',
                                            'price' => '6.0'
                                          }
                                        ],
          ... etc.
          
=cut

use strict;
use YAML qw( LoadFile );
use Data::Dumper;

my $foo = LoadFile( $ARGV[0] ) || die $!;
print Dumper $foo;

