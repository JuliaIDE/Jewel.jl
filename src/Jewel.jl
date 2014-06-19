module Jewel

using Lazy

include("io.jl")
include("eval.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
