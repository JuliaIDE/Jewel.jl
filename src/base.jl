macro inmodule(mod, expr)
  expr = Expr(:quote, expr)
  esc(:(eval($mod, $expr)))
end

@inmodule Base begin

  # Display primitives

  export HTML, Text

  type HTML{T}
    content::T
  end

  function HTML(xs...)
    HTML() do io
      for x in xs
        writemime(io, MIME"text/html"(), x)
      end
    end
  end

  writemime(io::IO, ::MIME"text/html", h::HTML) = print(io, h.content)
  writemime(io::IO, ::MIME"text/html", h::HTML{Function}) = h.content(io)

  type Text{T}
    content::T
  end

  print(io::IO, t::Text) = print(io, t.content)
  print(io::IO, t::Text{Function}) = t.content(io)
  writemime(io::IO, ::MIME"text/plain", t::Text) = print(io, t)

  # Add Julia to the path

  @unix_only begin
    export addtopath!, rmfrompath!

    function addtopath!(target = "/usr/local/bin/julia")
      source = joinpath(JULIA_HOME, "julia")
      isfile(target) && error("There is already a file at $target. Please call rmfrompath!() first.")
      run(`sudo ln -s $source $target`)
    end

    function rmfrompath!(target = "/usr/local/bin/julia")
      isfile(target) && run(`sudo rm $target`)
    end
  end

  # Profiler

  export profile
  profile() = Main.Jewel.profileview().fetch()

end
