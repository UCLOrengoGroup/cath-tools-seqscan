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
perl script/cath-tools-seqscan.pl --in=query.fasta
```

Output alignments for the top 10 matches to a specific directory:

```
perl script/cath-tools-seqscan.pl --in=query.fasta --out=aln_dir --max_aln=10
```

## Usage
```
USAGE: cath-tools-seqscan.pl [-h] [long options...] --in=query.fasta

    --in=String    Query sequence to submit (FASTA file)

    --host=String    API host (default: 'beta.cathdb.info')
    --out=String     directory to output alignments (default './')
    --max_aln=Int    max number of alignments to output (default: 5)
    --max_hits=Int   max number of hits to report (default: 50)

    --usage          show a short help message
    -h               show a compact help message
    --help           show a long help message
    --man            show the manual
```

## Dependencies
All non-core Perl dependencies have been bundled into this repo, so the script
should Just Work (tested on Ubuntu 16.04, MacBook).

## Todo
Lots of room for improvement - this was intended as a proof of concept rather
than a genuinely useful script in its own right. Happy to make improvements
though - please log issues with GitHub.
