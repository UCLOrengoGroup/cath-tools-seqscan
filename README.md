# cath-tools-seqscan
Scan and align protein sequence against functional families in CATH

Currently this is just a Perl script demonstrating how the CATH API can be used.

 - submit sequence, get a task id
 - check task id until job is done
 - retrieve results
 - get alignment between query sequence and best match
 - write alignment to file

Lots of room for improvement, please log issues in GitHub.

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
