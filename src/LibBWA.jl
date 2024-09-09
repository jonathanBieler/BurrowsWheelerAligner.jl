module LibBWA

using BWA_jll
export BWA_jll

include("LibBWA_manual.jl")

const __darwin_off_t = Int64

const off_t = __darwin_off_t

struct gzFile_s
    have::Cuint
    next::Ptr{Cuchar}
    pos::off_t
end

const gzFile = Ptr{gzFile_s}

const bwtint_t = UInt64

const ubyte_t = Cuchar

struct bwt_t
    primary::bwtint_t
    L2::NTuple{5, bwtint_t}
    seq_len::bwtint_t
    bwt_size::bwtint_t
    bwt::Ptr{UInt32}
    cnt_table::NTuple{256, UInt32}
    sa_intv::Cint
    n_sa::bwtint_t
    sa::Ptr{bwtint_t}
end

struct bwtintv_t
    x::NTuple{3, bwtint_t}
    info::bwtint_t
end

struct bwtintv_v
    n::Csize_t
    m::Csize_t
    a::Ptr{bwtintv_t}
end

function bwt_dump_bwt(fn, bwt)
    ccall((:bwt_dump_bwt, libbwa), Cvoid, (Ptr{Cchar}, Ptr{bwt_t}), fn, bwt)
end

function bwt_dump_sa(fn, bwt)
    ccall((:bwt_dump_sa, libbwa), Cvoid, (Ptr{Cchar}, Ptr{bwt_t}), fn, bwt)
end

function bwt_restore_bwt(fn)
    ccall((:bwt_restore_bwt, libbwa), Ptr{bwt_t}, (Ptr{Cchar},), fn)
end

function bwt_restore_sa(fn, bwt)
    ccall((:bwt_restore_sa, libbwa), Cvoid, (Ptr{Cchar}, Ptr{bwt_t}), fn, bwt)
end

function bwt_destroy(bwt)
    ccall((:bwt_destroy, libbwa), Cvoid, (Ptr{bwt_t},), bwt)
end

function bwt_bwtgen(fn_pac, fn_bwt)
    ccall((:bwt_bwtgen, libbwa), Cvoid, (Ptr{Cchar}, Ptr{Cchar}), fn_pac, fn_bwt)
end

function bwt_bwtgen2(fn_pac, fn_bwt, block_size)
    ccall((:bwt_bwtgen2, libbwa), Cvoid, (Ptr{Cchar}, Ptr{Cchar}, Cint), fn_pac, fn_bwt, block_size)
end

function bwt_cal_sa(bwt, intv)
    ccall((:bwt_cal_sa, libbwa), Cvoid, (Ptr{bwt_t}, Cint), bwt, intv)
end

function bwt_bwtupdate_core(bwt)
    ccall((:bwt_bwtupdate_core, libbwa), Cvoid, (Ptr{bwt_t},), bwt)
end

function bwt_occ(bwt, k, c)
    ccall((:bwt_occ, libbwa), bwtint_t, (Ptr{bwt_t}, bwtint_t, ubyte_t), bwt, k, c)
end

function bwt_occ4(bwt, k, cnt)
    ccall((:bwt_occ4, libbwa), Cvoid, (Ptr{bwt_t}, bwtint_t, Ptr{bwtint_t}), bwt, k, cnt)
end

function bwt_sa(bwt, k)
    ccall((:bwt_sa, libbwa), bwtint_t, (Ptr{bwt_t}, bwtint_t), bwt, k)
end

function bwt_gen_cnt_table(bwt)
    ccall((:bwt_gen_cnt_table, libbwa), Cvoid, (Ptr{bwt_t},), bwt)
end

function bwt_2occ(bwt, k, l, c, ok, ol)
    ccall((:bwt_2occ, libbwa), Cvoid, (Ptr{bwt_t}, bwtint_t, bwtint_t, ubyte_t, Ptr{bwtint_t}, Ptr{bwtint_t}), bwt, k, l, c, ok, ol)
end

function bwt_2occ4(bwt, k, l, cntk, cntl)
    ccall((:bwt_2occ4, libbwa), Cvoid, (Ptr{bwt_t}, bwtint_t, bwtint_t, Ptr{bwtint_t}, Ptr{bwtint_t}), bwt, k, l, cntk, cntl)
end

function bwt_match_exact(bwt, len, str, sa_begin, sa_end)
    ccall((:bwt_match_exact, libbwa), Cint, (Ptr{bwt_t}, Cint, Ptr{ubyte_t}, Ptr{bwtint_t}, Ptr{bwtint_t}), bwt, len, str, sa_begin, sa_end)
end

function bwt_match_exact_alt(bwt, len, str, k0, l0)
    ccall((:bwt_match_exact_alt, libbwa), Cint, (Ptr{bwt_t}, Cint, Ptr{ubyte_t}, Ptr{bwtint_t}, Ptr{bwtint_t}), bwt, len, str, k0, l0)
end

function bwt_extend(bwt, ik, ok, is_back)
    ccall((:bwt_extend, libbwa), Cvoid, (Ptr{bwt_t}, Ptr{bwtintv_t}, Ptr{bwtintv_t}, Cint), bwt, ik, ok, is_back)
end

function bwt_smem1(bwt, len, q, x, min_intv, mem, tmpvec)
    ccall((:bwt_smem1, libbwa), Cint, (Ptr{bwt_t}, Cint, Ptr{UInt8}, Cint, Cint, Ptr{bwtintv_v}, Ptr{Ptr{bwtintv_v}}), bwt, len, q, x, min_intv, mem, tmpvec)
end

function bwt_smem1a(bwt, len, q, x, min_intv, max_intv, mem, tmpvec)
    ccall((:bwt_smem1a, libbwa), Cint, (Ptr{bwt_t}, Cint, Ptr{UInt8}, Cint, Cint, UInt64, Ptr{bwtintv_v}, Ptr{Ptr{bwtintv_v}}), bwt, len, q, x, min_intv, max_intv, mem, tmpvec)
end

function bwt_seed_strategy1(bwt, len, q, x, min_len, max_intv, mem)
    ccall((:bwt_seed_strategy1, libbwa), Cint, (Ptr{bwt_t}, Cint, Ptr{UInt8}, Cint, Cint, Cint, Ptr{bwtintv_t}), bwt, len, q, x, min_len, max_intv, mem)
end

struct bntann1_t
    offset::Int64
    len::Int32
    n_ambs::Int32
    gi::UInt32
    is_alt::Int32
    name::Ptr{Cchar}
    anno::Ptr{Cchar}
end

struct bntamb1_t
    offset::Int64
    len::Int32
    amb::Cchar
end

struct bntseq_t
    l_pac::Int64
    n_seqs::Int32
    seed::UInt32
    anns::Ptr{bntann1_t}
    n_holes::Int32
    ambs::Ptr{bntamb1_t}
    fp_pac::Ptr{Libc.FILE}
end

function bns_dump(bns, prefix)
    ccall((:bns_dump, libbwa), Cvoid, (Ptr{bntseq_t}, Ptr{Cchar}), bns, prefix)
end

function bns_restore(prefix)
    ccall((:bns_restore, libbwa), Ptr{bntseq_t}, (Ptr{Cchar},), prefix)
end

function bns_restore_core(ann_filename, amb_filename, pac_filename)
    ccall((:bns_restore_core, libbwa), Ptr{bntseq_t}, (Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), ann_filename, amb_filename, pac_filename)
end

function bns_destroy(bns)
    ccall((:bns_destroy, libbwa), Cvoid, (Ptr{bntseq_t},), bns)
end

function bns_fasta2bntseq(fp_fa, prefix, for_only)
    ccall((:bns_fasta2bntseq, libbwa), Int64, (gzFile, Ptr{Cchar}, Cint), fp_fa, prefix, for_only)
end

function bns_pos2rid(bns, pos_f)
    ccall((:bns_pos2rid, libbwa), Cint, (Ptr{bntseq_t}, Int64), bns, pos_f)
end

function bns_cnt_ambi(bns, pos_f, len, ref_id)
    ccall((:bns_cnt_ambi, libbwa), Cint, (Ptr{bntseq_t}, Int64, Cint, Ptr{Cint}), bns, pos_f, len, ref_id)
end

function bns_get_seq(l_pac, pac, beg, _end, len)
    ccall((:bns_get_seq, libbwa), Ptr{UInt8}, (Int64, Ptr{UInt8}, Int64, Int64, Ptr{Int64}), l_pac, pac, beg, _end, len)
end

function bns_fetch_seq(bns, pac, beg, mid, _end, rid)
    ccall((:bns_fetch_seq, libbwa), Ptr{UInt8}, (Ptr{bntseq_t}, Ptr{UInt8}, Ptr{Int64}, Int64, Ptr{Int64}, Ptr{Cint}), bns, pac, beg, mid, _end, rid)
end

function bns_intv2rid(bns, rb, re)
    ccall((:bns_intv2rid, libbwa), Cint, (Ptr{bntseq_t}, Int64, Int64), bns, rb, re)
end

function bns_depos(bns, pos, is_rev)
    ccall((:bns_depos, libbwa), Int64, (Ptr{bntseq_t}, Int64, Ptr{Cint}), bns, pos, is_rev)
end

struct bwaidx_t
    bwt::Ptr{bwt_t}
    bns::Ptr{bntseq_t}
    pac::Ptr{UInt8}
    is_shm::Cint
    l_mem::Int64
    mem::Ptr{UInt8}
end

struct bseq1_t
    l_seq::Cint
    id::Cint
    name::Ptr{Cchar}
    comment::Ptr{Cchar}
    seq::Ptr{Cchar}
    qual::Ptr{Cchar}
    sam::Ptr{Cchar}
end

function bseq_read(chunk_size, n_, ks1_, ks2_)
    ccall((:bseq_read, libbwa), Ptr{bseq1_t}, (Cint, Ptr{Cint}, Ptr{Cvoid}, Ptr{Cvoid}), chunk_size, n_, ks1_, ks2_)
end

function bseq_classify(n, seqs, m, sep)
    ccall((:bseq_classify, libbwa), Cvoid, (Cint, Ptr{bseq1_t}, Ptr{Cint}, Ptr{Ptr{bseq1_t}}), n, seqs, m, sep)
end

function bwa_fill_scmat(a, b, mat)
    ccall((:bwa_fill_scmat, libbwa), Cvoid, (Cint, Cint, Ptr{Int8}), a, b, mat)
end

function bwa_gen_cigar(mat, q, r, w_, l_pac, pac, l_query, query, rb, re, score, n_cigar, NM)
    ccall((:bwa_gen_cigar, libbwa), Ptr{UInt32}, (Ptr{Int8}, Cint, Cint, Cint, Int64, Ptr{UInt8}, Cint, Ptr{UInt8}, Int64, Int64, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), mat, q, r, w_, l_pac, pac, l_query, query, rb, re, score, n_cigar, NM)
end

function bwa_gen_cigar2(mat, o_del, e_del, o_ins, e_ins, w_, l_pac, pac, l_query, query, rb, re, score, n_cigar, NM)
    ccall((:bwa_gen_cigar2, libbwa), Ptr{UInt32}, (Ptr{Int8}, Cint, Cint, Cint, Cint, Cint, Int64, Ptr{UInt8}, Cint, Ptr{UInt8}, Int64, Int64, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), mat, o_del, e_del, o_ins, e_ins, w_, l_pac, pac, l_query, query, rb, re, score, n_cigar, NM)
end

function bwa_idx_build(fa, prefix, algo_type, block_size)
    ccall((:bwa_idx_build, libbwa), Cint, (Ptr{Cchar}, Ptr{Cchar}, Cint, Cint), fa, prefix, algo_type, block_size)
end

function bwa_idx_infer_prefix(hint)
    ccall((:bwa_idx_infer_prefix, libbwa), Ptr{Cchar}, (Ptr{Cchar},), hint)
end

function bwa_idx_load_bwt(hint)
    ccall((:bwa_idx_load_bwt, libbwa), Ptr{bwt_t}, (Ptr{Cchar},), hint)
end

function bwa_idx_load_from_shm(hint)
    ccall((:bwa_idx_load_from_shm, libbwa), Ptr{bwaidx_t}, (Ptr{Cchar},), hint)
end

function bwa_idx_load_from_disk(hint, which)
    ccall((:bwa_idx_load_from_disk, libbwa), Ptr{bwaidx_t}, (Ptr{Cchar}, Cint), hint, which)
end

function bwa_idx_load(hint, which)
    ccall((:bwa_idx_load, libbwa), Ptr{bwaidx_t}, (Ptr{Cchar}, Cint), hint, which)
end

function bwa_idx_destroy(idx)
    ccall((:bwa_idx_destroy, libbwa), Cvoid, (Ptr{bwaidx_t},), idx)
end

function bwa_idx2mem(idx)
    ccall((:bwa_idx2mem, libbwa), Cint, (Ptr{bwaidx_t},), idx)
end

function bwa_mem2idx(l_mem, mem, idx)
    ccall((:bwa_mem2idx, libbwa), Cint, (Int64, Ptr{UInt8}, Ptr{bwaidx_t}), l_mem, mem, idx)
end

function bwa_print_sam_hdr(bns, hdr_line)
    ccall((:bwa_print_sam_hdr, libbwa), Cvoid, (Ptr{bntseq_t}, Ptr{Cchar}), bns, hdr_line)
end

function bwa_set_rg(s)
    ccall((:bwa_set_rg, libbwa), Ptr{Cchar}, (Ptr{Cchar},), s)
end

function bwa_insert_header(s, hdr)
    ccall((:bwa_insert_header, libbwa), Ptr{Cchar}, (Ptr{Cchar}, Ptr{Cchar}), s, hdr)
end

mutable struct __smem_i end

const smem_i = __smem_i

struct mem_opt_t
    a::Cint
    b::Cint
    o_del::Cint
    e_del::Cint
    o_ins::Cint
    e_ins::Cint
    pen_unpaired::Cint
    pen_clip5::Cint
    pen_clip3::Cint
    w::Cint
    zdrop::Cint
    max_mem_intv::UInt64
    T::Cint
    flag::Cint
    min_seed_len::Cint
    min_chain_weight::Cint
    max_chain_extend::Cint
    split_factor::Cfloat
    split_width::Cint
    max_occ::Cint
    max_chain_gap::Cint
    n_threads::Cint
    chunk_size::Cint
    mask_level::Cfloat
    drop_ratio::Cfloat
    XA_drop_ratio::Cfloat
    mask_level_redun::Cfloat
    mapQ_coef_len::Cfloat
    mapQ_coef_fac::Cint
    max_ins::Cint
    max_matesw::Cint
    max_XA_hits::Cint
    max_XA_hits_alt::Cint
    mat::NTuple{25, Int8}
end

struct mem_alnreg_v
    n::Csize_t
    m::Csize_t
    a::Ptr{mem_alnreg_t}
end

struct mem_pestat_t
    low::Cint
    high::Cint
    failed::Cint
    avg::Cdouble
    std::Cdouble
end

function smem_itr_init(bwt)
    ccall((:smem_itr_init, libbwa), Ptr{smem_i}, (Ptr{bwt_t},), bwt)
end

function smem_itr_destroy(itr)
    ccall((:smem_itr_destroy, libbwa), Cvoid, (Ptr{smem_i},), itr)
end

function smem_set_query(itr, len, query)
    ccall((:smem_set_query, libbwa), Cvoid, (Ptr{smem_i}, Cint, Ptr{UInt8}), itr, len, query)
end

function smem_config(itr, min_intv, max_len, max_intv)
    ccall((:smem_config, libbwa), Cvoid, (Ptr{smem_i}, Cint, Cint, UInt64), itr, min_intv, max_len, max_intv)
end

function smem_next(itr)
    ccall((:smem_next, libbwa), Ptr{bwtintv_v}, (Ptr{smem_i},), itr)
end

function mem_opt_init()
    ccall((:mem_opt_init, libbwa), Ptr{mem_opt_t}, ())
end

function mem_fill_scmat(a, b, mat)
    ccall((:mem_fill_scmat, libbwa), Cvoid, (Cint, Cint, Ptr{Int8}), a, b, mat)
end

function mem_process_seqs(opt, bwt, bns, pac, n_processed, n, seqs, pes0)
    ccall((:mem_process_seqs, libbwa), Cvoid, (Ptr{mem_opt_t}, Ptr{bwt_t}, Ptr{bntseq_t}, Ptr{UInt8}, Int64, Cint, Ptr{bseq1_t}, Ptr{mem_pestat_t}), opt, bwt, bns, pac, n_processed, n, seqs, pes0)
end

function mem_align1(opt, bwt, bns, pac, l_seq, seq)
    ccall((:mem_align1, libbwa), mem_alnreg_v, (Ptr{mem_opt_t}, Ptr{bwt_t}, Ptr{bntseq_t}, Ptr{UInt8}, Cint, Ptr{Cchar}), opt, bwt, bns, pac, l_seq, seq)
end

function mem_reg2aln(opt, bns, pac, l_seq, seq, ar)
    ccall((:mem_reg2aln, libbwa), mem_aln_t, (Ptr{mem_opt_t}, Ptr{bntseq_t}, Ptr{UInt8}, Cint, Ptr{Cchar}, Ptr{mem_alnreg_t}), opt, bns, pac, l_seq, seq, ar)
end

function mem_reg2aln2(opt, bns, pac, l_seq, seq, ar, name)
    ccall((:mem_reg2aln2, libbwa), mem_aln_t, (Ptr{mem_opt_t}, Ptr{bntseq_t}, Ptr{UInt8}, Cint, Ptr{Cchar}, Ptr{mem_alnreg_t}, Ptr{Cchar}), opt, bns, pac, l_seq, seq, ar, name)
end

function mem_pestat(opt, l_pac, n, regs, pes)
    ccall((:mem_pestat, libbwa), Cvoid, (Ptr{mem_opt_t}, Int64, Cint, Ptr{mem_alnreg_v}, Ptr{mem_pestat_t}), opt, l_pac, n, regs, pes)
end

struct __kstring_t
    l::Csize_t
    m::Csize_t
    s::Ptr{Cchar}
end

const kstring_t = __kstring_t

const OCC_INTV_SHIFT = 7

const OCC_INTERVAL = Clonglong(1) << OCC_INTV_SHIFT

const OCC_INTV_MASK = OCC_INTERVAL - 1

const BWA_IDX_BWT = 0x01

const BWA_IDX_BNS = 0x02

const BWA_IDX_PAC = 0x04

const BWA_IDX_ALL = 0x07

const BWA_CTL_SIZE = 0x00010000

const BWTALGO_AUTO = 0

const BWTALGO_RB2 = 1

const BWTALGO_BWTSW = 2

const BWTALGO_IS = 3

const BWA_DBG_QNAME = 0x01

const MEM_MAPQ_COEF = 30.0

const MEM_MAPQ_MAX = 60

const MEM_F_PE = 0x02

const MEM_F_NOPAIRING = 0x04

const MEM_F_ALL = 0x08

const MEM_F_NO_MULTI = 0x10

const MEM_F_NO_RESCUE = 0x20

const MEM_F_REF_HDR = 0x0100

const MEM_F_SOFTCLIP = 0x0200

const MEM_F_SMARTPE = 0x0400

const MEM_F_PRIMARY5 = 0x0800

const MEM_F_KEEP_SUPP_MAPQ = 0x1000

const MEM_F_XB = 0x2000

const KS_SEP_SPACE = 0

const KS_SEP_TAB = 1

const KS_SEP_LINE = 2

const KS_SEP_MAX = 2

const KSTRING_T = kstring_t

# exports
const PREFIXES = ["CX", "bwa_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
