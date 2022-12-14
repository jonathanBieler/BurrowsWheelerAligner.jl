using BurrowsWheelerAligner
using Documenter

DocMeta.setdocmeta!(BurrowsWheelerAligner, :DocTestSetup, :(using BurrowsWheelerAligner); recursive=true)

makedocs(;
    modules=[BurrowsWheelerAligner],
    authors="Jonathan Bieler <jonathan.bieler@alumni.epfl.ch> and contributors",
    repo="https://github.com/jonathanBieler/BurrowsWheelerAligner.jl/blob/{commit}{path}#{line}",
    sitename="BurrowsWheelerAligner.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jonathanBieler.github.io/BurrowsWheelerAligner.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jonathanBieler/BurrowsWheelerAligner.jl",
    devbranch="main",
)
