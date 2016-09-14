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

## Mapping sequence to structure

**TL;DR** the numbering in the FASTA headers of the resulting alignments is based on the full protein sequence (```biomap``` entries) or the PDB SEQRES records (```cath```).

It's not always trivial to map between residues in a sequence alignment and residues in a 3D structure.
A couple of issues (#4 and #5) highlight this. The sequence headers in the alignment provide
information on the start/stop positions for each entry. For the ```biomap``` entries, this is a sequential
numbering based on the full protein sequence. For the ```cath``` entries, this is usually based on the PDB
residue labels that appear in the ATOM records of the PDB (e.g. not sequential numbers). To further complicate things, the sequences used for the CATH domains actually come from the PDB SEQRES records,
rather than the ATOM records. As a result, the domain sequences can contain residues not observed in the PDB
structure and this can affect the numbering scheme.

So, long story short - the script currently contains a hack that will 'correct' the
headers in the resulting sequence alignment so that the CATH domains will have start/stop
positions that directly map to the SEQRES records.
