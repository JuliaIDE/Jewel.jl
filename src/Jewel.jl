module Jewel

using Lazy

include("parse/parse.jl")
include("eval.jl")
include("module.jl")
include("errorshow.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
