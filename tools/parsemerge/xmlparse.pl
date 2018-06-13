#!/usr/local/bin/perl

# downloaded Nov 14 2012 by Erin Fichot from www.oardc.ohio-state.edu/tomato/HCS806/blast_parsing_pl.txt
# some changes made:
# 1. changed header descriptions
# 2. made flags for each value in command line
# 3. added code to remove hits below input bit score threshold
# 4. outputs 3 files, one with reads hitting database, one with hits NOT hitting database, one with hit headers
# 5. added format flag and code so that data can be parsed differently for cog vs. refseq databases
#	Dr. Xiaodong Bai
#	It may be freely distributed under GNU General Public License.
#	This script will parse a NCBI blastx output file and output the top N hits of each blast search result.
#	For each hit, the following results are reported:
#	accesion number, length, description, E value, bit score, query frame, query start, query end, hit start, hit end, positives, and identical
# 	The results are tab-deliminated and ready for import into a spreadsheet program for browsing and further analysis.
#
# Usage information
#Usage: $0 -i <BLAST-report-file> -o <output-file_base_name> -n <number-of-top-hits> -b <min_bit_score>
# -f <format of input: cog, refseq> 

use strict;
use warnings;
use Bio::SearchIO;
use Getopt::Std;#needed for flagging parameters

sub main{

my %opt;
#note: colons after letter mean the flag expects an argument
getopt('i:o:n:b:f:', \%opt);

print "Parsing the BLAST result ...\n";
my $in = Bio::SearchIO->new(-format => 'blastxml', -file => $opt{i});
open (OUT,">$opt{o}.hits.txt") or die "Cannot open $opt{o}.hits.txt: $!";
open (OUT2,">$opt{o}.nohits.txt") or die "Cannot open $opt{o}.nohits.txt: $!";
open (OUT3, ">$opt{o}.hits.header") or die "Cannot open $opt{o}.hits.header: $!";


# print the header info for tab-deliminated columns
print OUT "query_name\tquery_length\taccession_number\tsubject_length\tsubject_description\tE value\tbit score\tframe\tquery_start\t";
print OUT "query_end\thit_start\thit_end\t%_conserved\t%_identical\n";

print OUT2 "query_name\tquery_length\taccession_number\tsubject_length\tsubject_description\tE value\tbit score\tframe\tquery_start\t";
print OUT2 "query_end\thit_start\thit_end\t%_conserved\t%_identical\n";


# extraction of information for each result recursively
while ( my $result = $in->next_result ) {

	#prints query info for reads WITHOUT hits into -t ="bad" file
   	if ( $result->num_hits == 0 ) {
		print OUT2 $result->query_description . "\t";
    	print OUT2 $result->query_length . "\t";
		print OUT2 "No hits found\n";
		
		}
	else {
		my $count = 0;
		# process each hit recursively
		while (my $hit = $result->next_hit) {



			#prints query info for reads WITH hits BELOW bit-score input value into -t = "bad" file
			if ( $hit->bits < $opt{b}) {
   				print OUT2 $result->query_description . "\t";
    			print OUT2 $result->query_length . "\t";
				print OUT2 "below bit score\n";}
			#prints query and other info for reads WITH hits ABOVE bit-score input into -o = "good" file
			elsif (	$hit->bits >= $opt{b}) {
   				print OUT $result->query_description . "\t";
   				print OUT3 $result->query_description . "\n";
    			print OUT $result->query_length . "\t";
        		print OUT $hit->accession . "\t";
           		print OUT $hit->length . "\t";
           		
           		if ($opt{f} eq 'cog') {
					print OUT $hit->name . "\t";}
					
				elsif ($opt{f} eq 'refseq') {
					print OUT $hit->description . "\t";}
					
				print OUT $hit->significance . "\t";
				#print OUT $hit->bits . "\t";
				
				my $hspcount = 0;
			
				# process the top HSP for the top number of hits (user defined) into -o file
				while (my $hsp = $hit->next_hsp) {
					if ($hit->bits >= $opt{b} && $hspcount == 0){
						#print OUT "\t\t\t\t\t\t\t", if ($hspcount > 0);
          	      		print OUT $hsp->bits . "\t";
          	      		print OUT $hsp->query->frame . "\t";
						print OUT $hsp->start('query') . "\t" . $hsp->end('query'). "\t";
						print OUT $hsp->start('hit') . "\t" . $hsp->end('hit') . "\t";
						printf OUT "%.1f" , ($hsp->frac_conserved * 100);
						print OUT "%\t";
						printf OUT "%.1f" , ($hsp->frac_identical * 100);
		       			print OUT "%\n";
           				$hspcount++;
            			}

            		}
            		
         	   }
			$count++;
			# flow control for the number of hits needed
			last if ($count == $opt{n});

		}
		
    	}
  	
}

close OUT;
close OUT2;
close OUT3;
}
main();
print " DONE!!!\n";
