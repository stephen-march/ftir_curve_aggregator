#!/usr/bin/perl
# need the line above for Windows file systems. not needed for unix systems

use warnings;
use strict;
use List::Util qw[min max];
use Cwd;

####################################################################################################################
#                                       === Script Notes === 	                                                   #
####################################################################################################################
# ftir_aggregator.pl
#
# Parses through ftir .dpt files
# Merges all files from a specified directory into a single csv file
# Output file is saved as ftir_aggregate.txt
#
# How to use:
# 	perl ftir_aggregate some_directory_path
# Examples of use:
#	1. Within the current directory (pwd)
#		perl ftir_aggregate.pl 
#	1. Within some other directory
#		perl ftir_aggregate.pl "C:\Users\some directory\some other directory\hey another directory"


####################################################################################################################
#                                       === Subroutines === 	                                                   #
####################################################################################################################

sub getFilename{
	
	my($original_filename) = $_[0];	
	my $re_remove_dpt = '(.*)\.dpt'; # removes both the .dpt in the file name
	my $new_filename = 0;
	
	if($original_filename =~ m/$re_remove_dpt/){
		$new_filename = $1;
	}
	
	return $new_filename;
	
}

sub printLine{

	my @line = @{$_[0]}; # dereference input array for the current line
	my $fh = $_[1]; # get the current file handle for printing
	# print out each element of the line array with a comma separating each
	print $fh join(", ", @line);	
	# end the line with a new line character
	print $fh "\n";
	
}	

sub mergeArrays{

	# https://stackoverflow.com/questions/23859243/merge-two-dimensional-array-in-perl
	# dereference input arrays
	my(@a1) = @{$_[0]};
	my(@a2) = @{$_[1]};
	my $file_count = $_[2];
	
	my @r;

	# For an array that is larger than nx1 in size, the array must be dereferenced
	# Both @a1 and @a2 are smaller than nx1 when file_count is 0
	if ($file_count == 0){
		for my $i (0 .. $#a1) {
		  # dereference $a1[$i] and $a2[$i] arrays,
		  # merge them, and push into @r as new row
		  push @r, [ $a1[$i], $a2[$i] ];
		}
	}
	
	# For an array that is larger than nx1 in size, the array must be dereferenced
	# @a1 is larger than nx1 when file_count is larger than 0
	# This means $a1 is the hex address in memory, thus @{$a1} gets the actual array
	# but @a2 is alway a nx1 array in the main body of code
	if ($file_count > 0){
		for my $i (0 .. $#a1) {
		  # dereference $a1[$i] and $a2[$i] arrays,
		  # merge them, and push into @r as new row
		  push @r, [ @{$a1[$i]}, $a2[$i] ];
		}
	}
	
	# DEBUG LINE
	#print "@{ $r[$i] }\n";
	
	return @r;

}

sub printHelp{
	
	print "\n";
	print "\n";
	print "ftir_aggregator.pl\n";
	print "\n";
	print "Parses through ftir .dpt files\n";
	print "Merges all files from a specified directory into a single csv file\n";
	print "Output file is saved as ftir_aggregate.txt\n";
	print "\n";
	print "How to use:\n";
	print "\tperl ftir_aggregate some_directory_path\n";
	print "Example of use:\n";
	print "\tperl ftir_aggregate.pl \"C:\\Users\\some directory\\some other directory\\hey another directory\\\"\n";
	print "\n";
	print "\n";
	exit;
}

####################################################################################################################
#                                       === Main Body === 	                                                   	   #
####################################################################################################################

open(aggregateoutput, ">ftir_aggregate.txt"); # output file 
system("cls"); # clears command line screen

my $re_extension = '.*\.dpt';
my $re_line = '(\d+\.\d+),(\d+\.\d+|\-\d+\.\d+)'; # Example: "7997.02602,0.318843" and account for negative sign
my @file_names = ('wavevector (cm^-1)'); # Assumes the x-axis is in wavevectors
my @aggregate_matrix;
my $file_count = 0;
my $prev_size = 0;
my $prev_min = 0;
my $prev_max = 0;
my $cur_size = 0;
my $cur_min = 0;
my $cur_max = 0;


# Get the directory where the files are located that you want to scan
my $file_dir = $ARGV[0]; # reads in first argument from the commandline
# if no directory is defined as an input variable, use the current working directory
if(not defined $file_dir){
	$file_dir = cwd();
	warn "***********************************************\n";
	warn "AN INPUT DIRECTORY WAS NOT PROVIDED!\n";
	warn "Using the current working directory instead...\n";
	warn "\n";
	warn "For an example of how to use this script, try:\n";
	warn "\t perl ftir_aggregate.pl  -help\n";
	warn "***********************************************\n";
}

if($file_dir =~ m/-help/){
	printHelp();
}

print "Using directory: $file_dir\n";

#chdir($file_dir)
opendir(DIR, $file_dir) or die "cannot open dir $file_dir: $!";
while (my $filename = readdir(DIR)) { 
  
	if($filename =~ m/$re_extension/){
		
		# get the filename without the '.dpt' extension
		my $cur_filename = getFilename($filename); # strip off the .dpt
		my $temp_file_count = $file_count + 1;
		print "file: $temp_file_count\tfilename: $cur_filename\n";
		push(@file_names,$cur_filename);
		
		# get the x and y data for the current file
		my @cur_x;
		my @cur_y;
		open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
		while (my $line = <$fh>) {																# reads through each line of the file
			chomp($line);																	# segments the file based on white space
			
			# get the wavenumber and measured data for the current line in the data file
			if ($line =~ m/$re_line/){
			
				#print "DEBUG: $1,$2\n";
				push(@cur_x,$1);
				push(@cur_y,$2);
			}
		}
		
		# Merge the current data with data that was already collected
		if($file_count == 0){
			@aggregate_matrix = mergeArrays(\@cur_x,\@cur_y,$file_count);
			$cur_size = scalar(@cur_x);
			$cur_min = min @cur_x;
			$cur_max = max @cur_x;
			#print "DEBUG: cur_min: $cur_min, cur_max: $cur_max, cur_size: $cur_size\n";
		}
		else {			
			$cur_size = scalar(@cur_x);
			$cur_min = min @cur_x;
			$cur_max = max @cur_x;		
			#print "DEBUG: cur_min: $cur_min, cur_max: $cur_max, cur_size: $cur_size\n";
		
			# compare to the other x data to make sure that the sizes are correct...
			# simply compare to the previous arrays, and it should be okay
			if ( ($cur_size == $prev_size) and ($cur_min == $prev_min) and ($cur_max == $prev_max) ){			
				@aggregate_matrix = mergeArrays(\@aggregate_matrix,\@cur_y,$file_count);
			}
			
			else {
				warn "$filename data is not the same size as other files and will not be collected!\n";
				warn "cur_min: $cur_min, cur_max: $cur_max, cur_size: $cur_size\n";
				warn "prev_min: $prev_min, prev_max: $prev_max, prev_size: $prev_size\n";
			}			
		}
		
		#print "DEBUG: cur_min: $cur_min, cur_max: $cur_max, cur_size: $cur_size\n";
		$file_count = $file_count + 1;
		$prev_size = $cur_size;
		$prev_min = $cur_min;
		$prev_max = $cur_max;
	}
}

# check to see if there are any files, if not, warn the user
if($file_count == 0){
	warn "***********************************************\n";
	warn "NO FILES WERE FOUND!\n";
	warn "Check the directory path and its contents!\n";
	warn "***********************************************\n";
}

# print out the headers for each file column
printLine(\@file_names,\*aggregateoutput);
for my $i (0 .. $#aggregate_matrix) {
	print aggregateoutput join(",", @{ $aggregate_matrix[$i] }), "\n";
}

close (aggregateoutput);
closedir(DIR);