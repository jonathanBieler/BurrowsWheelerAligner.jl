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

description(aln::LibBWA.mem_aln_t, aligner::Aligner) = begin
    anns = unsafe_load(aligner.index.bns).anns
    anno = unsafe_load(anns, aln.rid+1).anno
    unsafe_string(anno)
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