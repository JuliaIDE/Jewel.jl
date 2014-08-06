module Jewel

using Lazy

include("base.jl")
include("parse/parse.jl")
include("eval.jl")
include("module.jl")
include("errorshow.jl")
include("completions.jl")
include("doc.jl")
include("profile/profile.jl")

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
