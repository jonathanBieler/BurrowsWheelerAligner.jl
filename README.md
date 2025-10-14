# BurrowsWheelerAligner

[![Build Status](https://github.com/jonathanBieler/BurrowsWheelerAligner.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jonathanBieler/BurrowsWheelerAligner.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jonathanBieler/BurrowsWheelerAligner.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jonathanBieler/BurrowsWheelerAligner.jl)

Minimal WIP bindings for bwa (https://github.com/lh3/bwa)

**Warning** : This package is still experimental, double check that the results are correct.
Make sure you use the same version of BWA as https://github.com/JuliaBinaryWrappers/BWA_jll.jl (0.7.17) to generate the reference index.

## Usage
### Single read alignment 

```julia
using BurrowsWheelerAligner
const BWA = BurrowsWheelerAligner
import BWA.FASTA

# this folder include all the files generate by `bwa index`
index_file = joinpath(@__DIR__, "data", "genome.fa")

aligner = BWA.Aligner(index_file)

record = FASTA.Record(""">test\nGAGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT""")
aln = BWA.align(aligner, record)[1]

@assert BWA.position(aln) == 1
@assert BWA.cigar(aln) == "70M"
@assert BWA.mappingquality(aln) == 60
@assert BWA.is_rev(aln) == false
@assert BWA.refname(aln, aligner) == "PhiX"
```

### Paired-end alignment 

In paired-end mode `align` will return `SAM` records (and return only the primary alignement):

```julia
    aligner = BWA.Aligner(index_file; paired = true, nthreads = 8)

    r1 = FASTA.Record("test1", "TGCGTTTATGGTACGCTGGACTTTGTGGGATACCCTCGCTTTCCTGCTCCTGTTGAGTTTATTGCTGCCG")
    r2 = FASTA.Record("test1", "AAAGGCAAGCGTAAAGGCGCTCGTCTTTGGTATGTAGGTGGTCAACAATTTTAATTGCAGGGGCTTCGGC")
    
    sam1, sam2 = BWA.align(aligner, (r1,r2))
```

Multithreading can be used by providing an array of paired records :

```julia
    using Random
    records = Tuple{FASTA.Record,FASTA.Record}[]
    for i in 1:1000
        n = randstring(rand(10:20))
        r1 = FASTA.Record(n, "TGCGTTTATGGTACGCTGGACTTTGTGGGATACCCTCGCTTTCCTGCTCCTGTTGAGTTTATTGCTGCCG")
        r2 = FASTA.Record(n, "AAAGGCAAGCGTAAAGGCGCTCGTCTTTGGTATGTAGGTGGTCAACAATTTTAATTGCAGGGGCTTCGGC")
        push!(records, (r1,r2))
    end

    alns = BWA.align(aligner, records)
```

### Additional methods

The aligner mode can be switched with :

`BWA.flag!(aligner, BWA.LibBWA.MEM_F_PE)`
`BWA.flag!(aligner, BWA.LibBWA.MEM_F_NOPAIRING)`
