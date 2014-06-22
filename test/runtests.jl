using Base.Test, Jewel

@test get_thing("Base.fft") == fft
@test get_thing(Base, [:fft]) == fft

@test file_module(Pkg.dir("Jewel", "src", "module.jl")) == "Jewel"
