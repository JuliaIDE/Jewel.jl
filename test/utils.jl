using LNR

function get_cursor(s)
  ls = Jewel.lines(s)
  for (i, l) in enumerate(ls)
    m = match(r".*?\|", l)
    m == nothing || return LNR.cursor(i, length(m.match))
  end
  error("no cursor found")
end

rem_cursor(s) = replace(s, r"\|", "")

to_cursor(s) = (rem_cursor(s), get_cursor(s))

function get_tokens(s)
  s, c = to_cursor(s)
  Jewel.tokens(s, c)
end

function get_scopes(s)
  s, c = to_cursor(s)
  Jewel.scopes(s, c)
end

function get_scope(s)
  sc = get_scopes(s)[end]
  if sc.kind in (:call, :block)
    sc.name
  else
    sc
  end
end
