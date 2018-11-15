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

my $app_path;

BEGIN {
    die "GRID_TO_CLIMDIVS must be set to a valid directory - please check your environment settings - exiting" unless(CheckENV('GRID_TO_CLIMDIVS'));
    $app_path   = $ENV{GRID_TO_CLIMDIVS};
    $app_path   = RemoveSlash($app_path);
}

# --- Get the command-line options ---

my $ctl         = undef;
my $time        = undef;
my $help        = undef;
my $manual      = undef;

GetOptions(
    'ctl|c=s'             => \$ctl,
    'time|t=s'            => \$time,
    'help|h'              => \$help,
    'manual|man'          => \$manual,
);

# --- Handle -help and -manual options if they are supplied ---

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

# --- Make sure the required options are supplied ---

unless($ctl and $time and $output) {

    pod2usage( {
        -message => 'Options -ctl, -time, and -output are required to run this script',
        -exitval => 1,
        -verbose => 0,
    } );

}

# --- Set up temporary file to hold regridded data ---

unless(-d "$app_path/.temp") { mkpath("$app_path/.temp") or die "Could not create directory $app_path/.temp - check your permissions - exiting"; }
my $temp_file = "$app_path/.temp/regridded-".int(rand(1000000));

END {
    if(-e $temp_file) { unlink($temp_file) or warn "Could not remove $temp_file"; }
}

# --- Regrid the data to 0.125 degree resolution using GrADS ---

print "\nRegridding the input data using GrADS...\n";

my $grads_script = "$app_path/scripts/regrid-input.gs";
my $grads_err    = grads("run $grads_script $ctl $time $temp_file");

if($grads_err)        { die "\n$grads_err\n"; }
unless(-s $temp_file) { die "No GrADS errors found, but regridded data not created - exiting"; }

# --- Load gridded input data from the temporary file ---

unless(open(INPUT, '<' ,$temp_file) { die "Could not open $temp_file for reading - check your permissions - exiting"; }
binmode(INPUT);
my $input = join('',<INPUT>);
my @input = unpack('f*',$input);
close(INPUT);

# --- Load the gridpoint to climate divisions map data ---

my $map_file = "$app_path/ref/Conus0.125DegreeGrid-ClimateDivisions.map";
die "$map_file not found - your repository may be corrupted - exiting" unless(-s $map_file);
unless(open(MAP, '<' ,$map_file) { die "Could not open $map_file for reading - check your permissions - exiting"; }
my $header = <MAP>;
my @map;

while (<MAP>) {
    my $line = $_;
    chomp $line;
    my($lon,$lat,$stcd) = split(/\|/,$line);
    push(@map,$stcd);
}

close(MAP);

# --- Make sure the input and data lists are the same size ---

die "Input data and gridpoint to climate divisions map arrays are different sizes - exiting" if(@input != @map);

# --- Compute the averages of the gridpoints that fall into each division ---

my $sums   = CPC::Regions::ClimateDivisions->new();
my $npts   = CPC::Regions::ClimateDivisions->new();
my $output = CPC::Regions::ClimateDivisions->new();
$sums->Initialize(0);
$npts->Initialize(0);
$sums->SetMissing(-9999);
$npts->SetMissing(-9999);
$output->SetMissing(-9999);

GRIDPOINT: for(my $i=0; $i<@map; $i++) {
    next GRIDPOINT unless($sums->Exists($map[$i]));

    if(looks_like_number($input[$i]) and $input[$i] > -9999) {
        $sums->SetData($map[$i],$sums->GetData($map[$i]) + $input[$i]);
        $npts->SetData($map[$i],$npts->GetData($map[$i]) + 1);
    }

} # :GRIDPOINT

$npts->SetMissing(0);
$npts->SetMissing(-9999);
$result = $sums / $npts;

# --- Write out the climate divisions data ---



exit 0;

