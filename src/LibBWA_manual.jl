# there's some issues with the automatic bingings (bit fields), this is corrected by hand

struct mem_alnreg_t
    rb::Int64
    re::Int64
    qb::Cint
    qe::Cint
    rid::Cint
    score::Cint
    truesc::Cint
    sub::Cint
    alt_sc::Cint
    csub::Cint
    sub_n::Cint
    w::Cint
    seedcov::Cint
    secondary::Cint
    secondary_all::Cint
    seedlen0::Cint
    n_comp_is_alt::Cint #two bits fields together
    frac_rep::Cfloat
    hash::UInt64
end



#= typedef struct {
	int64_t rb, re; // [rb,re): reference sequence in the alignment
	int qb, qe;     // [qb,qe): query sequence in the alignment
	int rid;        // reference seq ID
	int score;      // best local SW score
	int truesc;     // actual score corresponding to the aligned region; possibly smaller than $score
	int sub;        // 2nd best SW score
	int alt_sc;
	int csub;       // SW score of a tandem hit
	int sub_n;      // approximate number of suboptimal hits
	int w;          // actual band width used in extension
	int seedcov;    // length of regions coverged by seeds
	int secondary;  // index of the parent hit shadowing the current hit; <0 if primary
	int secondary_all;
	int seedlen0;   // length of the starting seed
	int n_comp:30, is_alt:2; // number of sub-alignments chained together
	float frac_rep;
	uint64_t hash;
} mem_alnreg_t; =#

struct mem_aln_t
    pos::Int64
    rid::Cint
    flag::Cint
    is_rev_is_alt_mapq_NM::UInt32 # bits fields
    n_cigar::Cint
    cigar::Ptr{UInt32}
    XA::Ptr{Cchar}
    score::Cint
    sub::Cint
    alt_sc::Cint
end

#= typedef struct { // This struct is only used for the convenience of API.
	int64_t pos;     // forward strand 5'-end mapping position
	int rid;         // reference sequence index in bntseq_t; <0 for unmapped
	int flag;        // extra flag
	uint32_t is_rev:1, is_alt:1, mapq:8, NM:22; // is_rev: whether on the reverse strand; mapq: mapping quality; NM: edit distance
	int n_cigar;     // number of CIGAR operations
	uint32_t *cigar; // CIGAR in the BAM encoding: opLen<<4|op; op to integer mapping: MIDSH=>01234
	char *XA;        // alternative mappings

	int score, sub, alt_sc;
} mem_aln_t; =#

