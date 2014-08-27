function Base.require(s::ASCIIString)
  invoke(require, (String,), s)
  loadpkg(symbol(s))
end

const pkglisteners = (Symbol=>Vector{Function})[]

loadpkg(pkg::Symbol) =
  map(f->f(), get(pkglisteners, pkg,[]))

listenpkg(f, pkg) =
  pkglisteners[pkg] = push!(get(pkglisteners, pkg, Function[]), f)

macro require (pkg, expr)
  quote
    listenpkg($(Expr(:quote, pkg))) do
      $(esc(Expr(:call, :eval, Expr(:quote, Expr(:block,
                                                 Expr(:using, pkg),
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
      end
      $(mod)
    end
  end |> esc
end
