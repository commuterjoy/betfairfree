#!/usr/bin/perl 

=head1 ABOUT

Reads a YML file generated by the market logger and produces a graph that tracks the
rise and fall in prices of each runner.
=head1 USAGE

 # generate a 300px by 500px graph for YAML data source foo.txt, cap any odds over 100/1
 ./perl -I./lib _t/yml_grapher.pl -d foo.txt -h 300 -w 500 -c 100

=cut

use strict;
use YAML qw( LoadFile );
use Data::Dumper;
use GD::Graph::lines;
use GD::Graph;
use Getopt::Long;

my $DEBUG = 0;

# sort out arguments
my %opts = ();
GetOptions (\%opts, 'd|data=s', 'h|height=i', 'w|width=i', 'c|cap=i', 'verbose' );

die "you must supply a --data argument" unless $opts{data} || $opts{d};

my $source = $opts{d} . $opts{data};
my $height = ( $opts{h} || $opts{height} ) ? $opts{h} . $opts{height} : 400;
my $width = ( $opts{w} || $opts{width} ) ? $opts{w} . $opts{width} : 600;

# betfair has a 1000/1 ceiling on the maximum odds it offers. because most of the activity happens under 20/1
# you can set this value to a lower number to make the y axis shorter.
my $ceiling = ( $opts{c} || $opts{cap} ) ? $opts{c} . $opts{cap} : 100;

# derive a name for the image 
$source =~ /(([0-9]+)\.txt)/;
my $file = $1;
my $market = $2;

my @runners; # holds a list selection ID's of each runner
my %graph; # holds arrays for the graph to plot

# load the YAML
my $foo = LoadFile( $source ) || die $!;
print Dumper $foo if $DEBUG;

# get runners
foreach ( @{$foo->{'market'}} )
 {
     push( @runners, $_->{selection} );
 }
 
# for each runner build up the list of prices
foreach my $r ( @runners )
 {
    
    $graph{$r} = [ ];
  
    # sort the YML by date/time
    foreach my $key (sort ( keys( %{$foo} ) ) )
     {
       # for every date key ...
       if ( $key =~ /^[0-9]+$/ )
         {    
           # loop through each runner
           foreach ( @{$foo->{$key}} )
            {
                # where price doesn't exist set to 1.00 - ie. odds of 0/1
                my $price = ( $_->{'price'} ) ? $_->{'price'} : 1.00;
                
                # limit the price to the figure so as not to make the y axis too long
                $price = $ceiling if ( $price > $ceiling );
                
                # where runner is same as the root foreach loop push the price value to the graph array
                push( @{$graph{$r}}, $price ) if ( $_->{selection} == $r );
            }
         }
        
     }
 }

# create x-axis labels
my @x;
for ( my $i = 1; $i <= keys( %{$foo} ) - 1; $i++ )
 { push( @x, $i ); }

# prepare the yaxis
my @y;
while ( my ( $key, $value ) = each (%graph) )
 {
  push( @y, $value );
 } 

# prepare the graph data
my @data = ( \@x, @y );

# graph properties
my $graph = GD::Graph::lines->new( $width, $height );
$graph->set(
        y_label => 'price',
        x_label => 'time',
        line_width => 1,

	    # colours
        valuesclr => '#666666',
        textclr => '#666666',
        axislabelclr => '#666666',
        bgclr => 'white',
        fgclr => '#999999',
        );
      
# write graph to GIF      
open(IMG, ">$market.gif") or die $!;
binmode IMG;
print IMG $graph->plot(\@data)->gif;
close IMG;


