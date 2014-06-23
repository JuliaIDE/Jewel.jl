export showerror_html, showbacktrace_html

function to_link(path)
  file, line = match(r"^([a-zA-Z_\.\\/0-9:]+\.jl)(?::([0-9]*))?$", path).captures
  """<a href="$(isabspath(path) ? "javascript:void(0)" :
                "https://github.com/JuliaLang/julia/tree/$(Base.GIT_VERSION_INFO.commit)/base/$file#L$line")">
     $path
     </a>"""
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

function showbacktrace_html(io::IO, top_function::Symbol, t, set = 1:typemax(Int))
  ls = map!(strip, lines(sprint(Base.show_backtrace, top_function, t, set)))
  print(io, """<ul class="julia trace">""")

  for i = 2:length(ls)
    print(io, """<li class="julia trace-entry">""")
    print(io, replace(ls[i], r"[a-zA-Z_\.\\/0-9:]+\.jl(?::[0-9]*)?$", to_link))
    print(io, """</li>""")
  end

  println(io, """</ul>""")
end
