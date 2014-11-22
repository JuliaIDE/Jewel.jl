module Jewel

using LNR, Lazy

include("lazymod.jl")
include("base.jl")
include("parse/parse.jl")
include("eval.jl")
include("module.jl")
include("completions.jl")
include("doc.jl")

@lazymod ProfileView "profile/profile.jl"

# Shim for now
server(args...) = Main.LightTable.server(args...)

end # module

include("LightTable/LightTable.jl")
