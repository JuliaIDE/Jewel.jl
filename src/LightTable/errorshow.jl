const abspathpattern =
  @windows? r"([a-zA-Z]+:[\\/][a-zA-Z_\./\\ 0-9]+\.jl)(?::([0-9]*))?" : r"(/[a-zA-Z_\./ 0-9]+\.jl)(?::([0-9]*))?"

# Make the prefix optional, but disallow spaces
const relpathpattern =
  @windows? r"([a-zA-Z_\./\\0-9]+\.jl)(?::([0-9]*))?$" : r"([a-zA-Z_\./0-9]+\.jl)(?::([0-9]*))?$"

function basepath(file)
  path = joinpath(JULIA_HOME,"..","share","julia","base",file) |> normpath
  isfile(path) || (path = nothing)
  return path
end

function githublink(path)
  file, line = match(relpathpattern, path).captures
  """<a href="https://github.com/JuliaLang/julia/tree/$(Base.GIT_VERSION_INFO.commit)/base/$file#L$line">$path</a>"""
end

function baselink(path)
  file, line = match(relpathpattern, path).captures
  link = basepath(file)
  link == nothing && return githublink(path)
  line == nothing || (link *= ":$line")
  """<a class="file-link" data-file="$link">$path</a>"""
end

function filelink(path)
  """<a class="file-link" data-file="$path">$(splitdir(path)[2])</a>"""
end

function showerror_html(io, e)
  print(io, """<span class="julia error-description">""")
  showerror(io, e)
  print(io, """</span>""")
end

function showerror_html(io, e, bt, top_function = :eval_user_input)
  println(io, """<div class="julia error">""")
  showerror_html(io, e)
  showbacktrace_html(io, top_function, bt)
  println(io, """</div>""")
end

function showerror_html(io::IO, e::LoadError, bt, top_function = :eval_user_input)
  println(io, """<div class="julia error">""")
  showerror_html(io, e.error)
  showbacktrace_html(io, top_function, bt)
  println(io, """<span class="source">while loading $(e.file), in expression starting on line $(e.line)</span>""")
  println(io, """</div>""")
end

function showbacktrace_html(io::IO, top_function::Symbol, t, set = 1:typemax(Int))
  ls = map!(strip, lines(sprint(Base.show_backtrace, top_function, t, set)))
  print(io, """<ul class="julia trace">""")

  for i = 2:length(ls)
    print(io, """<li class="julia trace-entry">""")
    if ismatch(abspathpattern, ls[i])
      print(io, replace(ls[i], abspathpattern, filelink))
    elseif ismatch(relpathpattern, ls[i])
      print(io, replace(ls[i], relpathpattern, baselink))
    else
      println(io, ls[i])
    end
    print(io, """</li>""")
  end

  println(io, """</ul>""")
end
