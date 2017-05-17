# cath-tools-seqscan
Tool to scan and align a protein sequence against functional families in CATH

Currently this consists of a Perl script demonstrating how the CATH API can be used.

## Overview
 - submit sequence, get a task id
 - check task id until job is done
 - retrieve results
 - get alignment between query sequence and best match
 - write alignment to file

## Example

Submit a query sequence and output the alignment for the 5 matches to the current directory:

```
./script/cath-tools-seqscan.pl --in=query.fasta
```

Output alignments for the top 10 matches to a specific directory:

```
./script/cath-tools-seqscan.pl --in=query.fasta --out=aln_dir --max_aln=10
```

## Usage
```
USAGE: cath-tools-seqscan.pl [-h] [long options...]

    --host=String   Host to use for API requests
    --in=String     Query sequence to submit (FASTA file)
    --max_aln=Int   Maximum number of alignments to output (default: 5)
    --max_hits=Int  Maximum number of hits to output (default: 50)
    --out=String    Directory to output alignments (STOCKHOLM format)
    --queue=String  Specify a custom queue

    --usage         show a short help message
    -h              show a compact help message
    --help          show a long help message
    --man           show the manual
```

### Examples

Search a sequence against CATH models:

```
cath-tools-seqscan.pl --in=t/P03372.fa
```

Return the 100 top hits (rather than the top 50 hits):

```
cath-tools-seqscan.pl --in=t/P03372.fa --max_hits=100
```

Build alignments for just the best 3 hits (rather than the best 3 hits):

```
cath-tools-seqscan.pl --in=t/P03372.fa --max_aln=3
```

Run this job on a specific queue (the default is 'api')

```
cath-tools-seqscan.pl --in=t/P03372.fa --queue=<your_queue_name>
```

## Dependencies
All non-core Perl dependencies have been bundled into this repo, so the script
should Just Work (tested on Ubuntu 16.04, MacBook).

## Todo
Lots of room for improvement - this was intended as a proof of concept rather
than a genuinely useful script in its own right. Happy to make improvements
though - please log issues with GitHub.

## Mapping sequence to structure

**TL;DR**: the numbering in the resulting alignments depends on the type of entry:

 * ```UniProtKB```: numbering is based on the full protein sequence
 * ```CATH Domain```: numbering is based on the SEQRES records in the PDB chain (the script applies a fix to correct the incoming alignments)

It's not always trivial to map between residues in a sequence alignment and residues in a 3D structure.
A couple of issues (#4 and #5) highlight this. The sequence headers in the alignment provide
information on the start/stop positions for each entry. For the ```UniProtKB``` entries, this is a sequential
numbering based on the full protein sequence. For the ```CATH Domain``` entries, this is a sequential numbering scheme based on the sequence specified in the SEQRES records of the PDB file. The meta data in the headers provides a mapping between this numbering
and the PDB residue labels in the ATOM records (which look like numbers but aren't).
