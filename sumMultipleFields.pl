#!/usr/bin/perl -w

# These are completely adhoc scripts and hence the performance is not the criteria. Also these are not tested proprely
# Written by Jagannatha Reddy
# 
# You are welcome to update this file to suit your needs or to optimize it
#
use strict;
use Getopt::Long;

sub usage {
    print STDERR "Usage: $0 -inputFile <inputFile> -f <fieldNums>\n" .
                 "    <inputFile> - either a text file or .gz or .bz2 file. Each line should contain same number of fields\n" .
                 "                  The separator should be same across all the lines. Supported separators are ^A, Tab, & SPACE\n\n" .
                 "    <fieldNums> - comma separated list of field numbers for which sum has to computed. Examples 1 or 1,2,10, etc.\n" .
                 "                  Each of the specified field number should contain only numeric values in the input file\n\n";
    exit(1);
}

#main
{
    my ($inputFile, $fieldNums, $help);
    my $parseResult = GetOptions("inputFile=s" => \$inputFile,
                                 "fieldNums=s" => \$fieldNums,
                                 "help"        => \$help);

    if(defined $help || !defined $inputFile || !defined $fieldNums) {
        usage();
    }

    my $fileOpenCmd = "";
    # use bzcat for bz2 files and zcat for rest of the files including text file
    if($inputFile =~ /.bz2$/) {
        $fileOpenCmd = "bzcat -d";
    } elsif($inputFile =~ /.gz$/) {
        $fileOpenCmd = "gunzip -fc";
    } else {
        $fileOpenCmd = "cat";
    }

    # extract the field numbers
    my @selectFields = split(/,/, $fieldNums);
    my $numFields    = $#selectFields;

    open(IN, "$fileOpenCmd $inputFile | ") or die "Could not open $inputFile";

    # identify the separator automatically -- order of try ^A, TAB, SPACE
    my $SEPARATOR = "";
    my $firstLine = <IN>;
    my @fields = split(/$SEPARATOR/, $firstLine);

    if($#fields < $selectFields[$numFields-1]) {
        $SEPARATOR = "\t";
        @fields = split(/$SEPARATOR/, $firstLine);
        if($#fields < $selectFields[$numFields-1]) {
            $SEPARATOR = ",";
            @fields = split(/$SEPARATOR/, $firstLine);
            if($#fields < $selectFields[$numFields-1]) {
                $SEPARATOR = " ";
                @fields = split(/$SEPARATOR/, $firstLine);
                if($#fields < $selectFields[$numFields-1]) {
                    print STDERR "Invalid file - doesn't contain required number of fields. Tried with ^A, TAB, COMMA, & SPACE as separators\n";
                    exit(1);
                }
            }
        }
    }
    my $fieldsInFile = $#fields+1;
    print STDERR "Number of fields in the file: " . $fieldsInFile . "\n";
    print STDERR "Last field to be extracted  : $selectFields[$numFields]\n";

    my @totalsArr = (); # initialize the counter
    # consume the first record
    for(my $i=0; $i<=$numFields; $i++) {
        $totalsArr[$i] += $fields[$selectFields[$i]-1];
    }

    my $totalLines = 1;
    while(<IN>) {
	$totalLines++;
        chomp;
        my @fields = split(/$SEPARATOR/, $_);
        for(my $i=0; $i<=$numFields; $i++) {
            $totalsArr[$i] += $fields[$selectFields[$i]-1];
        }
    }
    close IN;
    print STDERR "inputFile   = $inputFile\n";
    print STDERR "fieldNums   = $fieldNums\n";
    print STDERR "totalLines  = $totalLines\n";

    for(my $i=0; $i<=$numFields; $i++) {
        print "Sum of field $selectFields[$i] => $totalsArr[$i]\n";
    }
}
