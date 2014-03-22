module_usings(mod) = ccall(:jl_module_usings, Any, (Any,), mod)

# Reasons to use Functional Programming:
# 7. Mixing Functional and Procedural => Job Security
function accessible_modules(mod, ret = Set())
  push!(ret, mod)
  map(m->accessible_modules(m, ret), setdiff(module_usings(mod), ret))
  return ret
end

accessible_names(mod = Main) =
  @as _ mod accessible_modules(_, Set()) map(names, _) [_...] Set
