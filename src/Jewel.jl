module Jewel

using Lazy

include("io.jl")
include("eval.jl")
include("module.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
