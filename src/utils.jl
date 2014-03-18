Base.in(name, m::Module) = name in names(m)

Base.get(m::Module, name) = m.(name)

Base.get(m::Module, name, default) =
  name in m ? get(m, name) : default
