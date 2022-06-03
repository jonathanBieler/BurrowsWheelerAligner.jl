# BurrowWheelerAligner

[![Build Status](https://github.com/jonathanBieler/BurrowWheelerAligner.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jonathanBieler/BurrowWheelerAligner.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jonathanBieler/BurrowWheelerAligner.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jonathanBieler/BurrowWheelerAligner.jl)


Minimal WIP bindings for bwa (https://github.com/lh3/bwa).

## Example (see tests)

```julia
index_file = joinpath(@__DIR__, "data", "genome.fa")
idx = BWA.load_index(index_file)
@assert idx.bns != C_NULL

aligner = BWA.Aligner(index_file)

record = FASTA.Record(""">test\nGAGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT""")
aln = BWA.align(aligner, record)[1]

@assert BWA.position(aln) == 1
@assert BWA.cigar(aln) == "70M"
@assert BWA.mappingquality(aln) == 60
@assert BWA.is_rev(aln) == false
@assert BWA.refname(aln, aligner) == "PhiX"
```