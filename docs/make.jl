using BurrowWheelerAligner
using Documenter

DocMeta.setdocmeta!(BurrowWheelerAligner, :DocTestSetup, :(using BurrowWheelerAligner); recursive=true)

makedocs(;
    modules=[BurrowWheelerAligner],
    authors="Jonathan Bieler <jonathan.bieler@alumni.epfl.ch> and contributors",
    repo="https://github.com/jonathanBieler/BurrowWheelerAligner.jl/blob/{commit}{path}#{line}",
    sitename="BurrowWheelerAligner.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jonathanBieler.github.io/BurrowWheelerAligner.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jonathanBieler/BurrowWheelerAligner.jl",
    devbranch="main",
)
