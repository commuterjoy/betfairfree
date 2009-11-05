
=head1 NAME

BetFair::DataProc

=head1 SYNOPSIS

This is for processing of data objects to extract information in a more
useful format. Effectively extensions to the main calls in BetFair.pm

=head1 AUTHOR

P Orrock - July 2009

=cut

package BetFair::DataProc;

use strict;
use BetFair::Config;
use BetFair::Trace qw( TRACE );

sub proc_getMarketPricesCompressedXMLSimple {
    my $self = shift;
    my %datahash = (
        'marketinfo' => '',
        'removedrunners' => '',
        'runners' => '' );
    my @data = split(/:/,$self->{_data});
    ($datahash{marketinfo},$datahash{removedrunners}) = split(/,/,$data[0]);
    shift @data;
    foreach my $runner (@data) {
        my @object = split(/:/,$runner);
    }
    my @marketinfo = split (/~/,$data[0]);

}

sub takeatick() {
    my $price = shift;
    if ($price <= 2) {
        $price -= 0.01;
    } elsif ($price <= 3) {
        $price -= 0.02;
    } elsif ($price <= 4) {
        $price -= 0.05;
    } elsif ($price <= 6) {
        $price -= 0.1;
    } else {
        $price -= 0.2;
    }
}

sub addatick() {
    my $price = shift;
    if ($price < 2) {
        $price += 0.01;
    } elsif ($price < 3) {
        $price += 0.02;
    } elsif ($price < 4) {
        $price += 0.05;
    } elsif ($price < 6) {
        $price += 0.1;
    } else {
        $price += 0.2;
    }
}

1;