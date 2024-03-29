module BurrowsWheelerAligner

    using FASTX, XAM, Printf
    import XAM: position

    include("LibBWA.jl")
    include("Aligner.jl")
    include("mem_aln_t.jl")

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
