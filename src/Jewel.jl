VERSION > v"0.4-" && __precompile__()

module Jewel

using LNR, Lazy, Requires

import Base: (==)

if VERSION > v"0.4-"
typealias String AbstractString
typealias FloatingPoint AbstractFloat
typealias Nothing Void
typealias Uint UInt
end

include("base.jl")
include("parse/parse.jl")
include("eval.jl")
include("module.jl")
include("completions.jl")
include("doc.jl")
include("profile/profile.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
