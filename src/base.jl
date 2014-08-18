macro inmodule (mod, expr)
  expr = Expr(:quote, expr)
  esc(:(eval($mod, $expr)))
end

@inmodule Base begin

  # Display primitives

  export HTML, Text, Printer

  type Printer
    λ::Function
  end

  print(io::IO, s::Printer) = s.λ(io)

  type HTML{T}
    content::T
  end

  HTML(f::Function) = HTML(Printer(f))

  writemime(io::IO, ::MIME"text/html", h::HTML) = print(io, h.content)

  type Text{T}
    content::T
  end

  Text(f::Function) = Text(Printer(f))

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
