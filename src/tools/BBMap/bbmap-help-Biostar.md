# From

[Biostar Handbook](https://www.biostarhandbook.com/tools/bbmap/bbmap-help.html), Source: <https://github.com/ialbert/biostar-handbook-web/blob/master/www/tools/bbmap/bbmap-help.html>.

# Content

Below this horizontal rule:

---

The content on this page originates in a
[SeqAnswers forum post](http://seqanswers.com/forums/showthread.php?t=58221)

That content has been reformatted and it is being expanded to
include more information.

- - -

There are common options for most BBMap suite programs and
depending on the file extension the input/output format is
automatically chosen/set.

- - -

### Using BBMap

#### Mapping Nanopore reads

BBMap.sh has a length cap of 6kbp. Reads longer than this
will be broken into 6kbp pieces and mapped independently.

Code:

    mapPacBio.sh -Xmx20g k=7 in=reads.fastq ref=reference.fa maxlen=1000 minlen=200 idtag ow int=f qin=33 out=mapped1.sam minratio=0.15 ignorequality slow ordered maxindel1=40 maxindel2=400

The "maxlen" flag shreds them to a max length of 1000; you
can set that up to 6000. But I found 1000 gave a higher
mapping rate.

#### Using Paired-end and single-end reads at the same time

BBMap itself can only run single-ended or paired-ended in a
single run, but it has a wrapper that can accomplish it,
like this:

    bbwrap.sh in1=read1.fq,singletons.fq in2=read2.fq,null out=mapped.sam append

This will write all the reads to the same output file but
only print the headers once. I have not tried that for bam
output, only sam output

--------------------------------------------------------

### Reformat.sh

Count k-mers/find unknown primers

    reformat.sh in=reads.fq out=trimmed.fq ftr=19

This will trim all but the first 20 bases (all bases after position 19, zero-based).

    kmercountexact.sh in=trimmed.fq out=counts.txt fastadump=f mincount=10 k=20 rcomp=f

This will generate a file containing the counts of all
20-mers that occurred at least 10 times, in a 2-column
format that is easy to sort in Excel.

    ACCGTTACCGTTACCGTTAC	100
    AAATTTTTTTCCCCCCCCCC	85

...etc. If the primers are 20bp long, they should be pretty obvious.

#### Sampling reads

    reformat.sh in=reads.fq out=sampled.fq sample=3000

#### Extract reads from a sam file

    reformat.sh in=reads.sam out=reads.fastq

#### Verify pairing and optionally de-interleave the reads

    reformat.sh in=reads.fastq verifypairing

If that completes successfully and says the reads were
correctly paired, then you can simply de-interleave reads
into two files like this:

    reformat.sh in=reads.fastq out1=r1.fastq out2=r2.fastq

#### Base quality histograms

    reformat.sh in=reads.fq qchist=qchist.txt

That stands for "quality count histogram".

#### Filter SAM/BAM file by read length

    reformat.sh in=x.sam out=y.sam minlength=50 maxlength=200

- - -

### BBMerge.sh

BBMerge now has a new flag - "outa" or "outadapter". This
allows you to automatically detect the adapter sequence of
reads with short insert sizes, in case you don't know what
adapters were used. It works like this:

    bbmerge.sh in=reads.fq outa=adapters.fa reads=1m

Of course, it will only work for paired reads! The output
fasta file will look like this:

    >Read1_adapter
    GATCGGAAGAGCACACGTCTGAACTCCAGTCACATCACGATCTCGTATGCCGTCTTCTGCTTG
    >Read2_adapter
    GATCGGAAGAGCACACGTCTGAACTCCAGTCACCGATGTATCTCGTATGCCGTCTTCTGCTTG

If you have multiplexed things with different barcodes in
the adapters, the part with the barcode will show up as Ns,
like this:

    GATCGGAAGAGCACACGTCTGAACTCCAGTCACNNNNNNATCTCGTATGCCGTCTTCTGCTTG

- - -

### BBDuk.sh

Finding reads with a specific sequence at the beginning of
read

    bbduk.sh -Xmx1g in=reads.fq outm=matched.fq outu=unmatched.fq restrictleft=25 k=25 literal=AAAAACCCCCTTTTTGGGGGAAAAA

In this case, all reads starting with
'AAAAACCCCCTTTTTGGGGGAAAAA` will end up in `matched.fq` and
all other reads will end up in `unmatched.fq`. Specifically,
the command means "look for 25-mers in the leftmost 25 bp of
the read", which will require an exact prefix match, though
you can relax that if you want.

So you could bin all the reads with your known sequence,
then look at the remaining reads to see what they have in
common. You can do the same thing with the tail of the read
using "restrictright" instead, though you can't use both
restrictions at the same time.

    bbduk.sh in=reads.fq outm=matched.fq literal=NNNNNNCCCCGGGGGTTTTTAAAAA k=25 copyundefined

With the "copyundefined" flag, a copy of each reference
sequence will be made representing every valid combination
of defined letter. So instead of increasing memory or time
use by 6^75, it only increases them by 4^6 or 4096 which is
completely reasonable, but it only allows substitutions at
predefined locations. You can use the "copyundefined",
"hdist", and "qhdist" flags together for a lot of
flexibility - for example, hdist=2 qhdist=1 and 3 Ns in the
reference would allow a hamming distance of 6 with much
lower resource requirements than hdist=6. Just be sure to
give BBDuk as much memory as possible. Removing illumina
adapters (if exact adapters not known)

    bbduk.sh in=reads.fq out=unmatched.fq outm=matched.fq literal=ACGTACGTACGTACGTAC k=18 mm=f hdist=2

Make sure "k" is set to the exact length of the sequence.
"hdist" controls the number of substitutions allowed. "outm"
gets the reads that match. By default this also looks for
the reverse-complement; you can disable that with "rcomp=f".

#### General notes for BBDuk.sh

BBDuk can operate in one of 4 kmer-matching modes:
Right-trimming (ktrim=r), left-trimming (ktrim=l), masking
(ktrim=n), and filtering (default). But it can only do one
at a time because all kmers are stored in a single table. It
can still do non-kmer-based operations such as quality
trimming at the same time.

BBDuk2 can do all 4 kmer operations at once and is designed
for integration into automated pipelines where you do
contaminant removal and adapter-trimming in a single pass to
minimize filesystem I/O. Personally, I never use BBDuk2 from
the command line. Both have identical capabilities and
functionality otherwise, but the syntax is different.

- - -

#### Randomreads.sh

Generate random reads in various formats

    randomreads.sh ref=genome.fasta out=reads.fq len=100 reads=10000

You can specify paired reads, an insert size distribution, read lengths (or length ranges), and so forth. But because I developed it to benchmark mapping algorithms, it is specifically designed to give excellent control over mutations. You can specify the number of snps, insertions, deletions, and Ns per read, either exactly or probabilistically; the lengths of these events is individually customizable, the quality values can alternately be set to allow errors to be generated on the basis of quality; there's a PacBio error model; and all of the reads are annotated with their genomic origin, so you will know the correct answer when mapping.

Bear in mind that 50% of the reads are going to be generated from the plus strand and 50% from the minus strand. So, either a read will match the reference perfectly, OR its reverse-complement will match perfectly.

You can generate the same set of reads with and without SNPs by fixing the seed to a positive number, like this:

    randomreads.sh maxsnps=0 adderrors=false out=perfect.fastq reads=1000 minlength=18 maxlength=55 seed=5
    randomreads.sh maxsnps=2 snprate=1 adderrors=false out=2snps.fastq reads=1000 minlength=18 maxlength=55 seed=5

#### Simulate a jump library

You can simulate a 4000bp jump library from your existing data like this.

    cat assembly1.fa assembly2.fa > combined.fa
    bbmap.sh ref=combined.fa
    randomreads.sh reads=1000000 length=100 paired interleaved mininsert=3500 maxinsert=4500 bell perfect=1 q=35 out=jump.fq.gz

- - -

### Demuxbyname.sh

Demultiplex fastq files when the tag is present in the fastq read header (illumina)

    demuxbyname.sh in=r#.fq out=out_%_#.fq prefixmode=f names=GGACTCCT+GCGATCTA,TAAGGCGA+TCTACTCT,... outu=filename

"Names" can also be a text file with one barcode per line (in exactly the format found in the read header). You do have to include all of the expected barcodes, though.

In the output filename, the "%" symbol gets replaced by the barcode; in both the input and output names, the "#" symbol gets replaced by 1 or 2 for read 1 or read 2. It's optional, though; you can leave it out for interleaved input/output, or specify in1=/in2=/out1=/out2= if you want custom naming.

- - -

### Readlength.sh

Plotting the length distribution of reads

    readlength.sh in=file out=histogram.txt bin=10 max=80000

That will plot the result in bins of size 10, with
everything above 80k placed in the same bin. The defaults
are set for relatively short sequences so if they are many
megabases long you may need to add the flag "-Xmx8g" and
increase "max=" to something much higher.

Alternatively, if these are assemblies and you're interested
in continuity information (L50, N50, etc), you can run stats
on each or statswrapper on all of them:

    stats.sh in=file

or
    statswrapper.sh in=file,file,file,file…

- - -

### Filterbyname.sh

By default, "filterbyname" discards reads with names in your
name list, and keeps the rest. To include them and discard
the others, do this:

    filterbyname.sh in=003.fastq out=filter003.fq names=names003.txt include=t

- - -

### Splitsam.sh

Splits a sam file into forward and reverse reads

    splitsam.sh mapped.sam forward.sam reverse.sam

- - -

## BBSplit.sh

BBSplit now has the ability to output paired reads in dual files using the # symbol. For example:

    bbsplit.sh ref=x.fa,y.fa in1=read1.fq in2=read2.fq basename=o%_#.fq

will produce ox_1.fq, ox_2.fq, oy_1.fq, and oy_2.fq

You can use the # symbol for input also, like "in=read#.fq",
and it will get expanded into 1 and 2.

Added feature: One can specify a directory for the "ref="
argument. If anything in the list is a directory, it will
use all fasta files in that directory. They need a fasta
extension, like .fa or .fasta, but can be compressed with an
additional .gz after that. Reason this is useful is to use
BBSplit is to have it split input into one output file per
reference file.

**NOTE**: 1 By default BBSplit uses fairly strict mapping
parameters; you can get the same sensitivity as BBMap by
adding the flags "minid=0.76 maxindel=16k minhits=1". With
those parameters it is extremely sensitive.

NOTE: 2 BBSplit has different ambiguity settings for dealing
with reads that map to multiple genomes. In any case, if the
alignment score is higher to one genome than another, it
will be associated with that genome only (this considers the
combined scores of read pairs - pairs are always kept
together). But when a read or pair has two
identically-scoring mapping locations, on different genomes,
the behavior is controlled by the "ambig2" flag -
"ambig2=toss" will discard the read, "all" will send it to
all output files, and "split" will send it to a separate
file for ambiguously-mapped reads (one per genome to which
it maps).

NOTE: 3 Zero-count lines are suppressed by default, but they
should be printed if you include the flag "nzo=f"
(nonzeroonly=false).

NOTE: 4 BBSplit needs multiple reference files as input; one
per organism, or one for target and another for everything
else. It only outputs one file per reference file.

Seal.sh, on the other hand, which is similar, can use a single concatenated file, as it (by default) will output one file per reference sequence within a concatenated set of references.

- - -

### Pileup.sh

To generate transcript coverage stats

    pileup.sh in=mapped.sam normcov=normcoverage.txt normb=20 stats=stats.txt

That will generate coverage per transcript, with 20 lines
per transcript, each line showing the coverage for that
fraction of the transcript. "stats" will contain other
information like the fraction of bases in each transcript
that was covered.

#### Calculating coverage of the genome

Program will take sam or bam, sorted or unsorted.

    pileup.sh in=mapped.sam out=stats.txt hist=histogram.txt

stats.txt will contain the average depth and percent covered
of each reference sequence; the histogram will contain the
exact number of bases with a each coverage level. You can
also get per-base coverage or binned coverage if you want to
plot the coverage. It also generates median and standard
deviation, and so forth.

It's also possible to generate coverage directly from BBMap,
without an intermediate sam file, like this:

    bbmap.sh in=reads.fq ref=reference.fasta nodisk covstats=stats.txt covhist=histogram.txt

We use this a lot in situations where all you care about is
coverage distributions, which is somewhat common in
metagenome assemblies. It also supports most of the flags
that pileup.sh supports, though the syntax is slightly
different to prevent collisions. In each case you can see
all the possible flags by running the shellscript with no
arguments.

To bin aligned reads

    pileup.sh in=mapped.sam out=stats.txt bincov=coverage.txt binsize=1000

That will give coverage within each bin. For read density
regardless of read length, add the "startcov=t" flag.

- - -

### Dedupe.sh

Dedupe ensures that there is at most one copy of any input
sequence, optionally allowing contaminants (substrings) to
be removed, and a variable hamming or edit distance to be
specified. Usage:

    dedupe.sh in=assembly1.fa,assembly2.fa out=merged.fa

That will absorb exact duplicates and containments. You can
use "hdist" and "edist" flags to allow mismatches, or get a
complete list of flags by running the shellscript with no
arguments.

Dedupe will merge assemblies, but it will not produce
consensus sequences or join overlapping reads; it only
removes sequences that are fully contained within other
sequences (allowing the specified number of mismatches or
edits).

Dedupe can remove duplicate reads from multiple files
simultaneously, if they are comma-delimited (e.g.
in=file1.fastq,file2.fastq,file3.fastq). And if you set the
flag "uniqueonly=t" then ALL copies of duplicate reads will
be removed, as opposed to the default behavior of leaving
one copy of duplicate reads.

However, it does not care which file a read came from; in
other words, it can't remove only reads that are duplicates
across multiple files but leave the ones that are duplicates
within a file. That can still be accomplished, though, like
this:

1. Run dedupe on each sample individually, so now there are at most 1 copy of a read per sample.
2. Run dedupe again on all of the samples together, with "uniqueonly=t". The only remaining duplicate reads will be the ones duplicated between samples, so that's all that will be removed.

- - -

### Generate ROC curves from any aligner

You have to index the reference

1. Index the reference:

        bbmap.sh ref=reference.fasta

2. Generate random reads

        randomreads.sh reads=100000 length=100 out=synth.fastq maxq=35 midq=25 minq=15

3. Map to produce a sam file

        bbmap.sh in=synth.fq out=mapped.sam

...substitute this command with the appropriate one from your aligner of choice

4. Generate ROC curve

    samtoroc.sh in=mapped.sam reads=100000

- - -

#### Calculate heterozygous rate for sequence data

    kmercountexact.sh in=reads.fq khist=histogram.txt peaks=peaks.txt

You can examine the histogram manually, or use the "peaks" file which tells you the number of unique kmers in each peak on the histogram. For a diploid, the first peak will be the het peak, the second will be the homozygous peak, and the rest will be repeat peaks. The peak caller is not perfect, though, so particularly with noisy data I would only rely on it for the first two peaks, and try to quantify the higher-order peaks manually if you need to (which you generally don't).

- - -

#### Compare mapped reads between two files

To see how many mapped reads (can be mapped concordant or
discordant, doesn't matter) are shared between the two
alignment files and how many mapped reads are unique to one
file or the other.

    reformat.sh in=file1.sam out=mapped1.sam mappedonly
    reformat.sh in=file2.sam out=mapped2.sam mappedonly

That gets you the mapped reads only. Then:


    filterbyname.sh in=mapped1.sam names=mapped2.sam out=shared.sam include=t

...which gets you the set intersection;

    filterbyname.sh in=mapped1.sam names=mapped2.sam out=only1.sam include=f
    filterbyname.sh in=mapped2.sam names=mapped1.sam out=only2.sam include=f

...which get you the set subtractions.

- - -

## BBrename.sh

    bbrename.sh in=old.fasta out=new.fasta

That will rename the reads as 1, 2, 3, 4, ... 222.

You can also give a custom prefix if you want. The input has
to be text format, not .doc.

- - -

#### BBfakereads.sh

Generating “fake” paired end reads from a single end read file

    bfakereads.sh in=reads.fastq out1=r1.fastq out2=r2.fastq length=100

That will generate fake pairs from the input file, with
whatever length you want (maximum of input read length). We
use it in some cases for generating a fake LMP library for
scaffolding from a set of contigs. Read 1 will be from the
left end, and read 2 will be reverse-complemented and from
the right end; both will retain the correct original
qualities. And " /1" " /2" will be suffixed after the read
name.

- - -

#### Randomreads.sh

Generate random reads

    randomreads.sh ref=genome.fasta out=reads.fq len=100 reads=10000

"seed=-1" will use a random seed; any other value will use that specific number as the seed

You can specify paired reads, an insert size distribution,
read lengths (or length ranges), and so forth. But because I
developed it to benchmark mapping algorithms, it is
specifically designed to give excellent control over
mutations. You can specify the number of snps, insertions,
deletions, and Ns per read, either exactly or
probabilistically; the lengths of these events is
individually customizable, the quality values can
alternately be set to allow errors to be generated on the
basis of quality; there's a PacBio error model; and all of
the reads are annotated with their genomic origin, so you
will know the correct answer when mapping.

- - -

#### Generate saturation curves to assess sequencing depth

    bbcountunique.sh in=reads.fq out=histogram.txt

It works by pulling kmers from each input read, and testing
whether it has been seen before, then storing it in a table.

The bottom line, "first", tracks whether the first kmer of
the read has been seen before (independent of whether it is
read 1 or read 2).

The top line, "pair", indicates whether a combined kmer from
both read 1 and read 2 has been seen before. The other lines
are generally safe to ignore but they track other things,
like read1- or read2-specific data, and random kmers versus
the first kmer.

It plots a point every X reads (configurable, default
25000).

In noncumulative mode (default), a point indicates "for the
last X reads, this percentage had never been seen before".
In this mode, once the line hits zero, sequencing more is
not useful.

In cumulative mode, a point indicates "for all reads, this
percentage had never been seen before", but still only one
point is plotted per X reads.

- - -

#### CalcTrueQuality.sh

CalcTrueQuality is a new member of the BBTools package. In
light of the quality-score issues with the NextSeq platform,
and the possibility of future Illumina platforms (HiSeq 3000
and 4000) also using quantized quality scores, I developed
it for recalibrating the scores to ensure accuracy and
restore the full range of values.

The usage is fairly simple. I will walk through how I
recalibrated the reads used in the attached images. First
adapter-trim the reads:

    bbduk.sh -Xmx1g in=reads.fq out=trimmed.fq ref=adapters.fa tbo tpe k=23 mink=11 hdist=1 ftm=5

This is very important because adapter sequence will appear
to be errors during mapping, so it will mess up the
calibration statistics. Do not quality-trim or quality
filter. The "ftm=5" flag is optional; it will trim the last
base off of 151bp reads; that base is very low quality.
Specifically, ftm=5 will trim reads so that their length is
equal to zero modulo 5, and ignore reads that are already
100bp or 150bp, etc. Next, map the reads to a reference:

    bbmap.sh in=trimmed.fq outm=mapped.sam ignorequality maxindel=100 minratio=0.4 ambig=toss qahist=qahist_raw.txt qhist=qhist_raw.txt mhist=mhist_raw.txt

A finished reference is optimal, but not required; any
assembly will be sufficient. For paired reads, I recommend
using the "po" flag to only include proper pairs in the
output. If you have a lot of input you can just map a
fraction of it, with e.g. the flag "reads=20m" to only use
the first 20 million reads (or pairs). You don't have to use
BBMap for this, but you do need to use an aligner that
produces cigar strings with "=" and "X" symbols for match
and mismatch, not just "M" for everything.

Then, generate recalibration matrices:

    calctruequality.sh in=mapped.sam

This will analyze the sam file and write some small files to
/ref/qual/ (you can change the location to write to with the
"path" flag). You can also give the program multiple sam
files with a comma-delimited list; the more data, the more
precise the calibration.

Lastly, recalibrate the reads:

    bbduk.sh in=trimmed.fq out=recalibrated.fq recalibrate

The reads that you map to generate the calibration matrices
do not need to be the same as the reads you are
recalibrating. For example, if you multiplexed 10 samples in
a lane, you could just map one of them and recalibrate the
others based on it. But certainly it's best to do the
mapping with reads from the same run, and ideally, the
actual reads you are recalibrating.

This is what the NextSeq V1 data looked before recalibration
(but after adapter-trimming):

The left is "qhist" and the right is "qahist", both outputs
from BBMap. For qhist, the "log" lines are based on
translating the quality score to probability, then taking
the average, then translating back to a quality score, so
perfectly accurate quality scores will have for example the
"Read1_log" line exactly overlaying the "Read1_measured"
line.

With perfectly accurate quality scores, the yellow points on
the qahist graph will overlay the dark blue line. Points
under the blue line indicate inflated quality scores. For
example, the upper-right yellow point is calculated by
counting the number of times bases with Q37 map with a match
or a mismatch. TrueQualitySub is based only on mismatches,
while TrueQuality also counts indels as errors.

After recalibration, the data looks much better, and has
expanded to the full range of 2 through 41:

Finally, since that's not quite perfect, I decided to try a
second pass of recalibration. I don't think that's generally
necessary and it requires you to regenerate the calibration
matrices (you can't use the same ones again!) but it did
lead to very nice results:


As you can see, up to Q34 the quality scores are pretty much
dead-on in the qahist, and in qhist, the "log" lines are now
very close to the "measured" lines.

This program will work with any Illumina reads, not just
NextSeq. Right now I don't recommend it for platforms that
exhibit indel-type errors because those are not used in the
recalibration.

P.S. Probably, you could get even better results by
separately calibrating read 1 and read 2; I may add that
capability later.

In light of the quality-score issues with the NextSeq
platform, and the possibility of future Illumina platforms
(HiSeq 3000 and 4000) also using quantized quality scores, I
developed it for recalibrating the scores to ensure accuracy
and restore the full range of values.

- - -

#### BBMapskimmer.sh

BBMap is designed to find the best mapping, and heuristics
will cause it to ignore mappings that are valid but
substantially worse. Therefore, I made a different version
of it, BBMapSkimmer, which is designed to find all of the
mappings above a certain threshold. The shellscript is
bbmapskimmer.sh and the usage is similar to bbmap.sh or
mapPacBio.sh. For primers, which I assume will be short, you
may wish to use a lower than default K of, say, 10 or 11,
and add the "slow" flag.

- - -

#### msa.sh and curprimers.sh

Quoted from Brian's response directly.

I also wrote another pair of programs specifically for
working with primer pairs, msa.sh and cutprimers.sh. msa.sh
will forcibly align a primer sequence (or a set of primer
sequences) against a set of reference sequences to find the
single best matching location per reference sequence - in
other words, if you have 3 primers and 100 ref sequences, it
will output a sam file with exactly 100 alignments - one per
ref sequence, using the primer sequence that matched best.
Of course you can also just run it with 1 primer sequence.

So you run msa twice - once for the left primer, and once
for the right primer - and generate 2 sam files. Then you
feed those into cutprimers.sh, which will create a new fasta
file containing the sequence between the primers, for each
reference sequence. We used these programs to synthetically
cut V4 out of full-length 16S sequences.

I should say, though, that the primer sites identified are
based on the normal BBMap scoring, which is not necessarily
the same as where the primers would bind naturally, though
with highly conserved regions there should be no difference.

- - -

#### testformat.sh

Identify type of Q-score encoding in sequence files

    testformat.sh in=seq.fq.gz sanger fastq gz interleaved 150bp

- - -

#### kcompress.sh
