module Jewel

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
