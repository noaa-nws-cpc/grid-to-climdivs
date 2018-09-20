#!/usr/bin/perl

=pod

=head1 NAME

grid-to-climdivs - Create climate divisions (344) data using gridded data and GrADS

=head1 SYNOPSIS

 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl [-c|-d|-u]
 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl -h
 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl -man

 [OPTION]              [DESCRIPTION]                                         [VALUES]

 -ctl, -c              GrADS formatted gridded data descriptor file          filename
 -date, -d             Valid date for grid (used as GrADS TDEF)              yyyymmdd
 -help, -h             Print usage message and exit
 -manual, -man         Display script documentation
 -output, -o           Output filename                                       filename
 -unit-conversion, -u  Unit conversion to apply to output:
                          Convert Kelvin to degrees Fahrenheit               k,m
                          Convert new = M*old                                M
                          Convert new = M*old + N                            M,N

=head1 DESCRIPTION

=head2 PURPOSE

This script:

=over 3

=item * Takes an input data grid and regrids it to match a 0.125 degree map grid for which there are gridpoints in every climate division

=item * Calculates climate divisional data by averaging the gridpoints that fall into each division

=item * Performs a unit conversion to the climate divisions data if specified

=item * Writes the results to an ASCII output file

=back

=head2 REQUIREMENTS

The following software must be installed on the system running this script:

=over 3

=item * GrADS (2.0.2 or above)

=item * Perl CPAN library

=item * CPC Perl5 Library

=back

The following environment variables are required to be set in order to run this script:

=over 3

=item * GRID_TO_CLIMDIVS - The full path to where grid-to-climdivs is installed on your system

=back

=head1 AUTHOR

L<Adam Allgood|mailto:Adam.Allgood@noaa.gov>

L<Climate Prediction Center - NOAA/NWS/NCEP|http://www.cpc.ncep.noaa.gov>

This documentation was last updated on: 20SEP2018

=cut

# --- Standard and CPAN Perl packages ---

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use File::Copy qw(copy move);
use File::Path qw(mkpath);
use Scalar::Util qw(blessed looks_like_number openhandle);
use Pod::Usage;

# --- CPC Perl5 Library packages ---

use CPC::Day;
use CPC::Env qw(CheckENV RemoveSlash);
use CPC::SpawnGrads qw(grads);

# --- Establish script environment ---

my($scriptName,$scriptPath,$scriptSuffix);

BEGIN { ($scriptName,$scriptPath,$scriptSuffix) = fileparse($0, qr/\.[^.]*/); }

my $APP_PATH;

BEGIN {
    die "GRID_TO_CLIMDIVS must be set to a valid directory - please check your environment settings - exiting" unless(CheckENV('GRID_TO_CLIMDIVS'));
    $APP_PATH   = $ENV{GRID_TO_CLIMDIVS};
    $APP_PATH   = RemoveSlash($APP_PATH);
}

# --- Get the command-line options ---

my $ctl         = undef;
my $date        = undef;
my $help        = undef;
my $manual      = undef;
my $unit_conv   = undef;

GetOptions(
    'ctl|c=s'             => \$ctl,
    'date|d=i'            => \$date,
    'help|h'              => \$help,
    'manual|man'          => \$manual,
    'unit-conversion|u=s' => \$unit_conv,
);

# --- Respond to options -help or -manual if they are passed before doing anything else ---

if($help) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 0,
    } );

}

if($manual) {

    pod2usage( {
        -message => ' ',
        -exitval => 0,
        -verbose => 2,
    } );

}

# --- Make sure --date option  was passed with a valid date ---

my $day;
eval   { $day = CPC::Day->new($date); };
if($@) { die "Option --date=$date is invalid! Reason: $@ - exiting"; }
unless(CPC::Day->new() >= $day - 1) { die "Option --date=$date is too recent - exiting"; }

exit 0;

