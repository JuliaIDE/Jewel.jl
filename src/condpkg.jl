function Base.require(s::ASCIIString)
  invoke(require, (String,), s)
  loadpkg(symbol(s))
end

const pkglisteners = (Symbol=>Vector{Function})[]

loadpkg(pkg::Symbol) =
  map(f->f(), get(pkglisteners, pkg,[]))

listenpkg(f, pkg) =
  pkglisteners[pkg] = push!(get(pkglisteners, pkg, Function[]), f)

macro require(pkg, expr)
  quote
    listenpkg($(Expr(:quote, pkg))) do
      $(esc(Expr(:call, :eval, Expr(:quote, Expr(:block,
                                                 Expr(:using, pkg),
                                                 expr)))))
    end
  end
end
