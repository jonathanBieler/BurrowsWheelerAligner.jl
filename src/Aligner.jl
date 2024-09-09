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

refname(aligner::Aligner, reference_id::Int) = begin
    @assert reference_id > 0
    anns = unsafe_load(aligner.index.bns).anns
    name = unsafe_load(anns, reference_id).name
    unsafe_string(name)
end

reflength(aligner::Aligner, reference_id::Int) = begin
    @assert reference_id > 0
    anns = unsafe_load(aligner.index.bns).anns
    unsafe_load(anns, reference_id).len
end

number_of_references(aligner::Aligner) = unsafe_load(aligner.index.bns).n_seqs

function header(aligner::Aligner) 
    SAM.Header(vcat(
        SAM.MetaInfo("HD", ["VN" => "1.0", "SO" => "coordinate"]),
        [SAM.MetaInfo("SQ", ["SN" => refname(aligner, i), "LN" => reflength(aligner, i)]) for i in 1:number_of_references(aligner)],
        SAM.MetaInfo("PG", ["ID" => "BWA_jll", "PN" => "BWA_jll", "VN" => "0.7.17+0"]),
    ))
end

function close_alns(alns)
    for aln in alns
        ccall((:free, LibBWA.libbwa), Cvoid, (Ptr{UInt32},), aln.cigar)
    end
end

# https://github.com/lh3/bwa/blob/master/example.c#L37
function align(aligner::Aligner, record::Union{FASTA.Record, FASTQ.Record})

    GC.@preserve record begin

        seq_idx = FASTX.seq_data_part(record, 1:seqsize(record))
        seq_ptr = Base.unsafe_convert(Ptr{Cchar}, record.data) + (first(seq_idx)-1)*sizeof(Cchar)  #pointer(record.data, first(seq_idx))
        seq_l = seqsize(record)

        ar = LibBWA.mem_align1(aligner.opt, aligner.index.bwt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr)
        
        alns = LibBWA.mem_aln_t[]
        for i=1:Int(ar.n)
            ptr = ar.a + (i-1)*sizeof(LibBWA.mem_alnreg_t)
            aln = LibBWA.mem_reg2aln(aligner.opt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr, ptr)
            push!(alns, aln)

        end
        ccall((:free, LibBWA.libbwa), Cvoid, (Ptr{LibBWA.mem_alnreg_t},), ar.a)
        finalizer(close_alns, alns)
    end
    alns
end

## pair-end


""" Buffer to hold read names """
mutable struct IdentifierBuffer
    free_idx::Int
    data::Vector{Cchar}

    IdentifierBuffer() = new(1, zeros(Cchar, 10_000 * 100)) # will hold 10k names of length 100
end

reset!(x::IdentifierBuffer) = x.free_idx = 1

global const identifierbuffer = IdentifierBuffer() 

# For 10_000 reads went from 
# 0.386775 seconds (280.01 k allocations: 341.492 MiB, 3.52% gc time)
# to
# 0.387009 seconds (260.01 k allocations: 340.271 MiB, 3.01% gc time)
# worth ?
function convert_identifier(record) 

    name = FASTX.identifier(record)
    
    # -------- x----------------------x0x00 ------
    #          start     - name -   end     next free_idx
    idx_start = identifierbuffer.free_idx
    idx_end = idx_start + length(name) - 1 

    idx_end+1 > length(identifierbuffer.data) && error("Too many reads to fit in IdentifierBuffer, reduce the number of reads.")

    buffer_idx = idx_start:idx_end
    #@assert length(name) == length(buffer_idx)

    for (in, ib) in zip(eachindex(name), buffer_idx)
        identifierbuffer.data[ib] = Cchar(name[in])
    end
    identifierbuffer.data[idx_end + 1] = 0x00
    identifierbuffer.free_idx = idx_end + 2
    
    unsafe_convert(Ptr{Cchar}, identifierbuffer.data) + sizeof(Cchar) * (idx_start-1)
end

quality_pointer(record::FASTA.Record) = C_NULL
quality_pointer(record::FASTQ.Record) = unsafe_convert(Ptr{Cchar}, FASTX.quality(record))

function bseq1_t(record::Union{FASTA.Record, FASTQ.Record}, name_ptr, id::Int)

    comment = C_NULL
    seq = FASTX.sequence(record) 
    qual = quality_pointer(record)
    
    bseq1 = LibBWA.bseq1_t(
        length(seq),
        id,
        name_ptr,
        comment,
        unsafe_convert(Ptr{Cchar}, seq),
        qual,
        C_NULL,
    )
end

function align(aligner::Aligner, records::Union{Tuple{FASTA.Record, FASTA.Record}, Tuple{FASTQ.Record, FASTQ.Record}})

    # As I need to add a null terminator to IDs, I need to allocate a new array and avoid it
    # being GC'ed. I use a global array to hold names.
    reset!(identifierbuffer)
    id1 = convert_identifier(records[1])
    id2 = convert_identifier(records[2])
    identifiers = (id1,id2)
    seqs = [bseq1_t(records[1], identifiers[1], 1), bseq1_t(records[2], identifiers[2], 2)]
    
    GC.@preserve seqs identifiers begin

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

function align(aligner::Aligner, records::AbstractVector)

    reset!(identifierbuffer)
    
    identifiers = Array{Tuple{Ptr{Cchar},Ptr{Cchar}}}(undef, length(records))
    for i in eachindex(records)
        id1 = convert_identifier(records[i][1])
        id2 = convert_identifier(records[i][2])
        #@assert unsafe_string(id1) == unsafe_string(id2)
        identifiers[i] = (id1,id2)
    end

    seqs = Array{LibBWA.bseq1_t}(undef, 2*length(records))
    for (i,r) in enumerate(records)
        
        seqs[2*(i-1)+1] = bseq1_t(r[1], identifiers[i][1], 1)
        seqs[2*(i-1)+2] = bseq1_t(r[2], identifiers[i][2], 2)
    end
    
    GC.@preserve seqs records identifiers begin

        n_processed = 0
        n = length(seqs)
        LibBWA.mem_process_seqs(
            aligner.opt, aligner.index.bwt, aligner.index.bns, aligner.index.pac, n_processed,
            n, unsafe_convert(Ptr{LibBWA.bseq1_t}, seqs), unsafe_convert(Ptr{LibBWA.mem_pestat_t}, aligner.pes0)
        )
        
        @assert any(s.sam != C_NULL for s in seqs)

        out = Array{Tuple{SAM.Record, SAM.Record}}(undef, length(records))
        
        for i in eachindex(records)
            sam = split(unsafe_string(seqs[2*(i-1)+1].sam), '\n')[1]
            r1 = SAM.Record(sam)

            sam = split(unsafe_string(seqs[2*(i-1)+2].sam), '\n')[1]
            r2 = SAM.Record(sam)

            out[i] = (r1,r2)
        end
    end

    out
end

