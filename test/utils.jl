function get_cursor(s)
  ls = Jewel.lines(s)
  for (i, l) in enumerate(ls)
    m = match(r".*?\|", l)
    m == nothing || return (i, length(m.match))
  end
end

rem_cursor(s) = replace(s, r"\|", "")

to_cursor(s) = (rem_cursor(s), get_cursor(s))

function get_scope(s)
  s, c = to_cursor(s)
  sc = Jewel.scope(s, c)
  if sc[:type] in (:call, :block)
    sc[:name]
  else
    sc
  end
end
