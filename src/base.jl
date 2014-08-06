macro inmodule (mod, expr)
  expr = Expr(:quote, expr)
  esc(:(eval($mod, $expr)))
end

@inmodule Base begin

  # Display primitives

  export HTML

  type HTML
    content::UTF8String
  end

  writemime(io::IO, ::MIME"text/html", h::HTML) = print(io, h.content)

end
