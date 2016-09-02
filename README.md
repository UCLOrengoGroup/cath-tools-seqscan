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
```
perl ./script/cath-tools-seqscan.pl --in=query.fasta --out=best_match.fasta
```

## Usage
```
USAGE: cath-tools-seqscan.pl [-h] [long options...]

    --host=String  Host to use for API requests
    --in=String    Query sequence to submit (FASTA file)
    --out=String   Alignment to the best matching FunFam (FASTA file)

    --usage        show a short help message
    -h             show a compact help message
    --help         show a long help message
    --man          show the manual
```

## Dependencies
All non-core Perl dependencies have been bundled into this repo, so the script
should Just Work (tested on Ubuntu 16.04, MacBook).

## Todo
Lots of room for improvement - this was intended as a proof of concept rather
than a genuinely useful script in its own right. Happy to make improvements
though - please log issues with GitHub.
