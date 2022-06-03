module BurrowWheelerAligner

    using FASTX, XAM, Printf
    import XAM: position, refname, mappingquality

    include("LibBWA.jl")

    struct Aligner
        index::LibBWA.bwaidx_t
        opt::Ptr{LibBWA.mem_opt_t}

        Aligner(index_file) = new(
            load_index(index_file),
            LibBWA.mem_opt_init()
        )
    end

    function align(aligner::Aligner, record::FASTA.Record)

        seq_ptr, seq_l = pointer(record.data, first(record.sequence)), length(record.sequence)

        ar = LibBWA.mem_align1(aligner.opt, aligner.index.bwt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr)
    
        alns = LibBWA.mem_aln_t[]
        for i=0:ar.n-1
            ptr = ar.a + i*sizeof(LibBWA.mem_alnreg_t)
            aln = LibBWA.mem_reg2aln(aligner.opt, aligner.index.bns, aligner.index.pac, seq_l, seq_ptr, ptr)
            push!(alns, aln)
        end
        alns
    end
    
    ## mem_aln_t
    function cigar(aln::LibBWA.mem_aln_t)
        io = IOBuffer()
        operations = ('M', 'I', 'D', 'S', 'H')
        for i in 1:aln.n_cigar
            OP = unsafe_load(aln.cigar, i)
            @printf(io, "%d%c", OP>>4, getindex(operations,(OP & 0xf) +1))
        end
        String(take!(io))
    end

    position(aln::LibBWA.mem_aln_t) = aln.pos + 1

    refname(aln::LibBWA.mem_aln_t, aligner::Aligner) = begin
        anns = unsafe_load(aligner.index.bns).anns
        name = unsafe_load(anns, aln.rid+1).name
        unsafe_string(name)
    end
    
    # uint32_t is_rev:1, is_alt:1, mapq:8, NM:22; // is_rev: whether on the reverse strand; mapq: mapping quality; NM: edit distance
    is_rev(aln::LibBWA.mem_aln_t) = aln.is_rev_is_alt_mapq_NM >> 0 & 0x01 == 0x00000001
    is_alt(aln::LibBWA.mem_aln_t) = aln.is_rev_is_alt_mapq_NM >> 1 & 0x01 == 0x00000001
    mappingquality(aln::LibBWA.mem_aln_t) = aln.is_rev_is_alt_mapq_NM >> 2 & 0xff
    NM(aln::LibBWA.mem_aln_t) = aln.is_rev_is_alt_mapq_NM >> 10 & 0x003fffff

    function Base.show(io::IO, aln::LibBWA.mem_aln_t)
        print(io, "LibBWA.mem_aln_t", ':')
        println(io)
        #println(io, "             flag: ", hasflag(record) ? flag(record) : "<missing>")
        println(io, "           strand: ", is_rev(aln) ? "-" : "+")
        println(io, "     reference id: ", aln.rid+1)
        println(io, "         position: ", position(aln))
        println(io, "  mapping quality: ", Int(mappingquality(aln)))
        println(io, "            CIGAR: ", cigar(aln))
    end


    """
        load_index(index_file::String)

    Load index file.
    """
    function load_index(index_file::String)
        !isfile(index_file) && error("Index file $(index_file) not found.")
        ptr = LibBWA.bwa_idx_load(index_file, LibBWA.BWA_IDX_ALL)
        ptr == C_NULL && error("Couldn't load index file $(index_file).")
        unsafe_load(ptr)
    end

    
end
