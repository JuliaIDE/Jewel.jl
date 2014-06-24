module Jewel

using Lazy

include("parse/parse.jl")
include("eval.jl")
include("module.jl")
include("errorshow.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

# Work around for lack-of-a-decent-parser issue
#jewel module Main

include("LightTable/LightTable.jl")
