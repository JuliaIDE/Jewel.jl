using Base.Test, Jewel

@test Jewel.getthing("Base.fft") == fft
@test Jewel.getthing(Base, [:fft]) == fft

@test Jewel.filemodule(Pkg.dir("Jewel", "src", "module.jl")) == "Jewel"

include("utils.jl")
include("scope.jl")
include("display.jl")
