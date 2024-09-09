using BurrowsWheelerAligner
const BWA = BurrowsWheelerAligner
using Test, Random
import BurrowsWheelerAligner.FASTA
import BurrowsWheelerAligner.SAM

@testset "BurrowsWheelerAligner.jl" begin
    index_file = joinpath(@__DIR__, "data", "genome.fa")
    idx = BWA.load_index(index_file)
    @test idx.bns != C_NULL

    aligner = BWA.Aligner(index_file)

    record = FASTA.Record("test", "GAGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 1
    @test BWA.cigar(aln) == "70M"
    @test BWA.mappingquality(aln) == 60
    @test BWA.is_rev(aln) == false
    @test BWA.refname(aln, aligner) == "PhiX"

    # reverse completement
    record = FASTA.Record("test", "AAGATAATTTTTCGACTCATCAGAAATATCCGAAAGTGTTAACTTCTGCGTCATGGAAGCGATAAAACTC")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 1
    @test BWA.cigar(aln) == "70M"
    @test BWA.mappingquality(aln) == 60
    @test BWA.is_rev(aln) == true

    #skip first base
    record = FASTA.Record("test", "AGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 2

    # 5bp insertion in the middle
    record = FASTA.Record("test", "GAGTTTTATCGCTTCCATGACGCAGAAGTTAACACGGGGGTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT")
    aln = BWA.align(aligner, record)[1]
    @test BWA.cigar(aln) == "35M5I35M"

    # second ref
    record = FASTA.Record("test", "AGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC")
    aln = BWA.align(aligner, record)[1]
    @test BWA.cigar(aln) == "70M"
    @test BWA.refname(aln, aligner) == "chr"
    @test BWA.mappingquality(aln) == 60

    # check 0 matches work
    record = FASTA.Record("test", "AACTCCTAGGCCCAGGATGGTAAGTGTGGGCCTAGGGGAGACTGGGAATAGCCCTGGGTCAGGGTCTAGT")
    aln = BWA.align(aligner, record)
    @test length(aln) == 0
    
    # todo implement getters and show for mem_aln_t
    
    ## pair-end

    aligner = BWA.Aligner(index_file; paired = true, nthreads = 8)

    r1 = FASTA.Record("test1", "TGCGTTTATGGTACGCTGGACTTTGTGGGATACCCTCGCTTTCCTGCTCCTGTTGAGTTTATTGCTGCCG")
    r2 = FASTA.Record("test1", "AAAGGCAAGCGTAAAGGCGCTCGTCTTTGGTATGTAGGTGGTCAACAATTTTAATTGCAGGGGCTTCGGC")

    # test internals
    ptr1 = BWA.convert_identifier(r1) 
    ptr2 = BWA.convert_identifier(r2) 
    @test ptr2 - ptr1 == length(FASTA.identifier(r1)) + 1
    @test unsafe_string(ptr1) == FASTA.identifier(r1)
    @test unsafe_string(ptr2) == FASTA.identifier(r2)

    records = (r1,r2)

    sam1, sam2 = BWA.align(aligner, records)

    @test SAM.cigar(sam1) == "70M"
    @test SAM.cigar(sam2) == "70M"

    @test SAM.position(sam1) == 561
    @test SAM.position(sam2) == 911
    
    ## pair-end with lots of records
    
    records = Tuple{FASTA.Record,FASTA.Record}[]
    for i in 1:10_000
        n = randstring(rand(10:20))
        r1 = FASTA.Record(n, "TGCGTTTATGGTACGCTGGACTTTGTGGGATACCCTCGCTTTCCTGCTCCTGTTGAGTTTATTGCTGCCG")
        r2 = FASTA.Record(n, "AAAGGCAAGCGTAAAGGCGCTCGTCTTTGGTATGTAGGTGGTCAACAATTTTAATTGCAGGGGCTTCGGC")
        push!(records, (r1,r2))
    end

    alns = BWA.align(aligner, records)
    @time alns = BWA.align(aligner, records)
    @test length(alns) == length(records)
    
    @test SAM.position(alns[end][1]) == 561
    @test SAM.position(alns[end][2]) == 911

end
