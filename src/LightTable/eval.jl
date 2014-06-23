function get_module(data::Dict)
  mod = get_module_name(data)
  mod == "" || return get_thing(mod)
  mod = data["module"]
  mod == nothing || return get_thing(mod)
  return Main
end

# ----
# Eval
# ----

function Base.include_string(s::String, fname::String, line::Integer)
  include_string("\n"^(line-1)*s, fname)
end

function Base.include_string(mod::Module, args...)
  eval(mod, :(include_string($(args...))))
end

# function custom_showerror(io::IO, e::LoadError, bt)
#   custom_showerror_inner(io, e.error, bt)
# end

# function custom_showerror_inner(io::IO, e, bt)
#   showerror_html(io, e, bt, :include_string)
# end

# function custom_showerror_inner(io::IO, e::LoadError, bt)
#   showerror_html(io, e.error, bt)
#   print(io, "\nwhile loading $(e.file), in expression starting on line $(e.line)")
# end

function custom_showerror(io::IO, e::LoadError, bt)
  custom_showerror_inner(io, e.error, bt)
end

function custom_showerror_inner(io::IO, e, bt)
  showerror(io, e)
  Base.show_backtrace(io, :include_string, bt, 1:typemax(Int))
end

function custom_showerror_inner(io::IO, e::LoadError, bt)
  showerror(io, e.error, bt)
  print(io, "\nwhile loading $(e.file), in expression starting on line $(e.line)")
end

# Shoud be split into eval and eval.all
handle("editor.eval.julia") do req, data
  info = get_code(data)
  all = get(data, "all", false)

  val = nothing
  mod = info[:module] != nothing ? info[:module] :
        data["module"] != nothing ? get_thing(data["module"]) : Main

  mod == nothing && error("Module $(data["mod"]) not found")

  path = get(data, "path", nothing)
  task_local_storage()[:SOURCE_PATH] = path
  path == nothing && (path = "REPL")

  try
    val = include_string(mod, info[:code], path, info[:lines][1])
  catch e
    show_exception(req, sprint(custom_showerror, e, catch_backtrace()), info[:lines])
    return
  end

  if all
    notify_done()
    file = path == nothing ? "file" : splitdir(path)[2]
    notify("✓ Evaluated $file in module $mod")
  else
    display_result(req, val, info[:lines])
  end
end
