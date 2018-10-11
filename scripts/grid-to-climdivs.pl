#!/usr/bin/perl

=pod

=head1 NAME

grid-to-climdivs - GrADS-based utility to create data on the 344 U.S. climate divisions from gridded data

=head1 SYNOPSIS

 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl [-c|-t|-o]
 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl -h
 $GRID_TO_CLIMDIVS/scripts/grid-to-climdivs.pl -man

 [OPTION]              [DESCRIPTION]                                         [VALUES]

 -ctl, -c              GrADS formatted gridded data descriptor file          filename
 -help, -h             Print usage message and exit
 -manual, -man         Display script documentation
 -output, -o           Climate divisions data output filename                filename
 -time, -t             Time associated with the data (for GrADS TDEF)        hh:mmZddmmmyyyy - see http://cola.gmu.edu/grads/gadoc/descriptorfile.html#TDEF for more information

=head1 DESCRIPTION

=head2 PURPOSE

What this script does:

=over 3

=item * Loads a data grid specified by a GrADS data descriptor (ctl) file and a TDEF specification into GrADS

=item * Regrids the data to 0.125 degree resolution in GrADS and dumps to a temporary file

=item * Opens the temporary file and calculates climate divisions data by averaging the gridpoints that fall into each division

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

=item * GRID_TO_CD - Full path to where grid-to-climdivs is installed on your system

=back

=head1 AUTHOR

L<Adam Allgood|mailto:Adam.Allgood@noaa.gov>

L<Climate Prediction Center - NOAA/NWS/NCEP|http://www.cpc.ncep.noaa.gov>

This documentation was last updated on: 11OCT2018

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
my $time        = undef;
my $help        = undef;
my $manual      = undef;

GetOptions(
    'ctl|c=s'             => \$ctl,
    'time|t=i'            => \$time,
    'help|h'              => \$help,
    'manual|man'          => \$manual,
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


exit 0;

