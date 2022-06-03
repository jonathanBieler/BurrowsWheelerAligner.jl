using Clang
using Clang.Generators
using BWA_jll

@eval Clang.JLLEnvs begin

function get_system_dirs(triple::String, version::VersionNumber=v"4.8.5")
    triple = expand_triple(triple)
    info = get_environment_info(triple, version)
    gcc_info = info[1]
    sys_info = info[2]

    # download shards
    #Artifacts.download_artifact(Base.SHA1(gcc_info.id), gcc_info.url, gcc_info.chk)
    # Artifacts.download_artifact(Base.SHA1(sys_info.id), sys_info.url, sys_info.chk)
    # -isystem paths
    #@show  gcc_triple_path = Artifacts.artifact_path(Base.SHA1(gcc_info.id))
    gcc_triple_path = "/Users/jbieler/.julia/artifacts/78a3cf7c8dfe0b0ad81b8ba0a86f7d89a8d19300/"

    # sys_triple_path = Artifacts.artifact_path(Base.SHA1(sys_info.id))
    isys = String[]
    if triple == "x86_64-apple-darwin14"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "System", "Library", "Frameworks"))
    elseif triple == "aarch64-apple-darwin20"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, "11.0.0", "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, "11.0.0", "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "System", "Library", "Frameworks"))
    elseif triple == "x86_64-w64-mingw32" || triple == "i686-w64-mingw32"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "include"))
    elseif triple == "i686-linux-gnu" || triple == "x86_64-linux-gnu" ||
            triple == "aarch64-linux-gnu" || triple == "powerpc64le-linux-gnu" ||
            triple == "x86_64-unknown-freebsd12.2"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
    elseif triple == "i686-linux-musl" || triple == "x86_64-linux-musl" ||
            triple == "aarch64-linux-musl"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", triple, string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, triple, "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, triple, "sys-root", "usr", "include"))
    elseif triple == "armv7l-linux-gnueabihf"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-gnueabihf", string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-gnueabihf", string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, "arm-linux-gnueabihf", "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, "arm-linux-gnueabihf", "sys-root", "usr", "include"))
    elseif triple == "armv7l-linux-musleabihf"
        # compiler
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-musleabihf", string(version), "include"))
        push!(isys, joinpath(gcc_triple_path, "lib", "gcc", "arm-linux-musleabihf", string(version), "include-fixed"))
        push!(isys, joinpath(gcc_triple_path, "arm-linux-musleabihf", "include"))
        # sys-root
        push!(isys, joinpath(gcc_triple_path, "arm-linux-musleabihf", "sys-root", "usr", "include"))
    else
        error("Platform $triple is not supported.")
    end

    #@assert all(isdir, isys) "failed to setup environment due to missing dirs, please file an issue at https://github.com/JuliaInterop/Clang.jl/issues."
    @show isdir.(isys)

    return normpath.(isys)
end

end

@eval Clang.Generators begin

function (x::IndexDefinition)(dag::ExprDAG, options::Dict)
    general_options = get(options, "general", Dict())
    log_options = get(general_options, "log", Dict())
    show_info = get(log_options, "IndexDefinition_log", x.show_info)

    empty!(dag.tags)
    empty!(dag.ids)
    for (i, node) in enumerate(dag.nodes)
        !isempty(node.adj) && empty!(node.adj)

        if is_tag_def(node)
            if haskey(dag.tags, node.id)
                n = dag.nodes[dag.tags[node.id]]
                #@assert is_same(n.cursor, node.cursor) "duplicated definitions should be exactly the same!"
                show_info && @info "[IndexDefinition]: marked an indexed tag $(node.id) at nodes[$i]"
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing tag $(node.id) at nodes[$i]"
                dag.tags[node.id] = i
            end
        end

        if is_identifier(node)
            if haskey(dag.ids, node.id)
                show_info &&
                    @info "[IndexDefinition]: found duplicated identifier $(node.id) at nodes[$i]"
                ty = dup_type(node.type)
                dag.nodes[i] = ExprNode(node.id, ty, node.cursor, node.exprs, node.adj)
            else
                show_info && @info "[IndexDefinition]: indexing identifier $(node.id) at nodes[$i]"
                dag.ids[node.id] = i
            end
        end
    end

    return dag
end


function emit!(dag::ExprDAG, node::ExprNode{StructMutualRef}, options::Dict; args...)
    node_idx = args[:idx]
    struct_sym = make_symbol_safe(node.id)
    block = Expr(:block)
    expr = Expr(:struct, false, struct_sym, block)
    mutual_ref_field_cursors = CLCursor[]
    field_cursors = fields(getCursorType(node.cursor))
    field_cursors = isempty(field_cursors) ? children(node.cursor) : field_cursors
    for field_cursor in field_cursors
        field_sym = make_symbol_safe(name(field_cursor))
        field_ty = getCursorType(field_cursor)
        jlty = tojulia(field_ty)
        leaf_ty = get_jl_leaf_type(jlty)
        translated = translate(jlty, options)

        if jlty != leaf_ty && !is_jl_basic(leaf_ty)
            # this assumes tag-types and identifiers that have the same name are the same
            # thing, which is validated in the audit pass.
            field_idx = get(dag.tags, leaf_ty.sym, typemax(Int))
            if field_idx == typemax(Int)
                field_idx = get(dag.ids, leaf_ty.sym, typemax(Int))
            end

            # if `leaf_ty.sym` can not be found in `tags` and `ids` then it's in `ids_extra`
            field_idx == typemax(Int) && @assert haskey(dag.ids_extra, leaf_ty.sym)

            if node_idx < field_idx
                # this assumes that circular references were removed at pointers
                #@assert is_jl_pointer(jlty)

                # also emit the original expressions, so we can add corresponding comments
                # in the pretty-print pass
                comment = Expr(:(::), field_sym, deepcopy(translated))
                replace_pointee!(translated, :Cvoid)
                push!(mutual_ref_field_cursors, field_cursor)
                # Avoid pushing two expressions for one field
                push!(block.args, Expr(:block, comment, :($field_sym::$translated)))
                continue
            end
        end

        push!(block.args, Expr(:(::), field_sym, translated))
    end

    push!(node.exprs, expr)

    # make corrections by overloading `Base.getproperty` for those `Ptr{Cvoid}` fields
    if !isempty(mutual_ref_field_cursors)
        getter = Expr(:call, :(Base.getproperty), :(x::$struct_sym), :(f::Symbol))
        body = Expr(:block)
        for mrfield_cursor in mutual_ref_field_cursors
            n = name(mrfield_cursor)
            @assert !isempty(n)
            fsym = make_symbol_safe(n)
            fty = getCursorType(mrfield_cursor)
            ty = translate(tojulia(fty), options)
            ex = :(f === $(QuoteNode(fsym)) && return $ty(getfield(x, f)))
            push!(body.args, ex)
        end
        push!(body.args, :(return getfield(x, f)))
        getproperty_expr = Expr(:function, getter, body)
        push!(node.exprs, getproperty_expr)
    end

    if haskey(options, "field_access_method_list")
        if string(node.id) in options["field_access_method_list"]
            emit_getproperty_ptr!(dag, node, options)
            # emit_getproperty!(dag, node, options)
            emit_setproperty!(dag, node, options)
        end
    end

    return dag
end

end

cd(@__DIR__)

#git clone https://github.com/lh3/bwa.git
include_dir = "bwa"
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()

##
push!(args, "-I$include_dir")

headers = [joinpath(include_dir, header) for header in readdir(include_dir) if endswith(header, ".h")]
headers = ["bwa/bwamem.h", "bwa/kseq.h"]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
#headers = detect_headers(include_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
