using Compat

function Base.require(s::ASCIIString)
  invoke(require, (String,), s)
  loadmod(s)
end

loaded(mod) = getthing(Main, mod) != nothing

const modlisteners = @compat Dict{String,Vector{Function}}()

listenmod(f, mod) =
  loaded(mod) ? f() :
    modlisteners[mod] = push!(get(modlisteners, mod, Function[]), f)

loadmod(mod) =
  map(f->f(), get(modlisteners, mod, []))

importexpr(mod::Symbol) = Expr(:import, mod)
importexpr(mod::Expr) = Expr(:import, map(symbol, split(string(mod), "."))...)

macro require (mod, expr)
  quote
    listenmod($(string(mod))) do
      $(esc(Expr(:call, :eval, Expr(:quote, Expr(:block,
                                                 importexpr(mod),
                                                 expr)))))
    end
  end
end

macro lazymod (mod, path)
  quote
    function $(symbol(lowercase(string(mod))))()
      if !isdefined($(current_module()), $(Expr(:quote, mod)))
        includehere(path) = eval(Expr(:call, :include, path))
        includehere(joinpath(dirname(@__FILE__), $path))
        loadmod(string($mod))
      end
      $mod
    end
  end |> esc
end
