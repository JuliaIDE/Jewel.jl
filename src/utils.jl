macro dotimes(n, body)
  quote
    for i = 1:$(esc(n))
      $(esc(body))
    end
  end
end

macro once_then(expr::Expr)
  @assert expr.head == :while
  esc(quote
    $(expr.args[2]) # body of loop
    $expr # loop
  end)
end
