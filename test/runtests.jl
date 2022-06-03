using BurrowWheelerAligner
const BWA = BurrowWheelerAligner
using Test
import BurrowWheelerAligner.FASTA

#@testset "BurrowWheelerAligner.jl" begin
    index_file = joinpath(@__DIR__, "data", "genome.fa")
    idx = BWA.load_index(index_file)
    @test idx.bns != C_NULL

    aligner = BWA.Aligner(index_file)

    record = FASTA.Record(""">test\nGAGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT""")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 1
    @test BWA.cigar(aln) == "70M"
    @test BWA.mappingquality(aln) == 60
    @test BWA.is_rev(aln) == false
    @test BWA.refname(aln, aligner) == "PhiX"

    # reverse completement
    record = FASTA.Record(""">test\nAAGATAATTTTTCGACTCATCAGAAATATCCGAAAGTGTTAACTTCTGCGTCATGGAAGCGATAAAACTC""")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 1
    @test BWA.cigar(aln) == "70M"
    @test BWA.mappingquality(aln) == 60
    @test BWA.is_rev(aln) == true

    #skip first base
    record = FASTA.Record(""">test\nAGTTTTATCGCTTCCATGACGCAGAAGTTAACACTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT""")
    aln = BWA.align(aligner, record)[1]
    @test BWA.position(aln) == 2

    # 5bp insertion in the middle
    record = FASTA.Record(""">test\nGAGTTTTATCGCTTCCATGACGCAGAAGTTAACACGGGGGTTTCGGATATTTCTGATGAGTCGAAAAATTATCTT""")
    aln = BWA.align(aligner, record)[1]
    @test BWA.cigar(aln) == "35M5I35M"

    # second ref
    record = FASTA.Record(""">test\nAGCTTTTCATTCTGACTGCAACGGGCAATATGTCTCTGTGTGGATTAAAAAAAGAGTGTCTGATAGCAGC""")
    aln = BWA.align(aligner, record)[1]
    @test BWA.cigar(aln) == "70M"
    @test BWA.refname(aln, aligner) == "chr"
    @test BWA.mappingquality(aln) == 60
    
    # todo implement getters and show for mem_aln_t


#end
