macro inmodule (mod, expr)
  expr = Expr(:quote, expr)
  esc(:(eval($mod, $expr)))
end

@inmodule Base begin

  # Display primitives

  export HTML, Text

  type HTML
    content::UTF8String
  end

  writemime(io::IO, ::MIME"text/html", h::HTML) = print(io, h.content)

  type Text
    content::UTF8String
  end

  writemime(io::IO, ::MIME"text/plain", t::Text) = print(io, t.content)

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

  # Patches for 0.4 changes

  if VERSION < v"0.4-dev"
    split(xs, x; keep=false) = split(xs, x, false)
  end

end
