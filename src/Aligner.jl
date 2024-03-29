struct Aligner
    index::LibBWA.bwaidx_t
    opt::Ptr{LibBWA.mem_opt_t}
    pes0::Vector{LibBWA.mem_pestat_t}

    function Aligner(index_file; paired = false, nthreads=2)  

        aligner = new(
            load_index(index_file),
            LibBWA.mem_opt_init(),
            get_pes0(),
        )

        paired && pairend_flag!(aligner)
        nthreads!(aligner, nthreads)
        aligner
    end
end

# typedef struct {
# 	int low, high;   // lower and upper bounds within which a read pair is considered to be properly paired
# 	int failed;      // non-zero if the orientation is not supported by sufficient data
# 	double avg, std; // mean and stddev of the insert size distribution
# } me
get_pes0(low, high, failed, avg, std) = [LibBWA.mem_pestat_t(low, high, failed, avg, std) for i in 1:4]
get_pes0() = get_pes0(0, 2000, 0, 200, 150)

flag!(aligner::Aligner, flag) = unsafe_store!(Ptr{Cint}(aligner.opt + fieldoffset(LibBWA.mem_opt_t, 14)), flag)
pairend_flag!(aligner::Aligner) = flag!(aligner::Aligner, LibBWA.MEM_F_PE)

nthreads!(aligner::Aligner, n) = unsafe_store!(Ptr{Cint}(aligner.opt + fieldoffset(LibBWA.mem_opt_t, 22)), n)

function close_alns(alns)
    for aln in alns
        ccall((:free, LibBWA.libbwa), Cvoid, (Ptr{UInt32},), aln.cigar)
    end
end

# https://github.com/lh3/bwa/blob/master/example.c#L37
function align(aligner::Aligner, record::Union{FASTA.Record, FASTQ.Record})

    seq_idx = FASTX.seq_data_part(record, 1:seqsize(record))
    seq_ptr, seq_l = pointer(record.data, first(seq_idx)), seqsize(record)

    ar = LibBWA.mem_align1(aligner.opt, aligner.index.bwt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr)
    
    alns = LibBWA.mem_aln_t[]
    for i=1:Int(ar.n)
        ptr = ar.a + (i-1)*sizeof(LibBWA.mem_alnreg_t)
        aln = LibBWA.mem_reg2aln(aligner.opt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr, ptr)
        push!(alns, aln)

    end
    ccall((:free, LibBWA.libbwa), Cvoid, (Ptr{LibBWA.mem_alnreg_t},), ar.a)
    finalizer(close_alns, alns)
    alns
end

## pair-end

to_null_terminated(x) = vcat([Cchar(c) for c in x], 0x00)

quality_pointer(record::FASTA.Record) = C_NULL
quality_pointer(record::FASTQ.Record) = pointer(FASTX.quality(record))

function bseq1_t(record::Union{FASTA.Record, FASTQ.Record}, id::Int) 

    name = FASTX.identifier(record) |> to_null_terminated
    comment = C_NULL
    seq = FASTX.sequence(record) 
    qual = quality_pointer(record)
    
    bseq1 = LibBWA.bseq1_t(
        length(seq),
        id,
        pointer(name),
        comment,
        pointer(seq),
        qual,
        C_NULL,
    )
end

function align(aligner::Aligner, records::Union{Tuple{FASTA.Record, FASTA.Record}, Tuple{FASTQ.Record, FASTQ.Record}})

    seqs = [bseq1_t(records[1], 1), bseq1_t(records[2], 2)]
    
    GC.@preserve seqs begin

        n_processed = 0
        n = length(seqs)
        LibBWA.mem_process_seqs(
            aligner.opt, aligner.index.bwt, aligner.index.bns, aligner.index.pac, n_processed,
            n, pointer(seqs), pointer(aligner.pes0)
        )
        
        @assert seqs[1].sam != C_NULL
        @assert seqs[2].sam != C_NULL

        sam = split(unsafe_string(seqs[1].sam), '\n')[1]
        r1 = SAM.Record(sam)

        sam = split(unsafe_string(seqs[2].sam), '\n')[1]
        r2 = SAM.Record(sam)
    end

    (r1, r2)
end


