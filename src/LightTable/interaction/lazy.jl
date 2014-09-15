displayinline(xs::List) =
  Collapsible(HTML("List"),
              HTML() do io
                println(io, """<table class="array">""")
                for x in take(MAX_CELLS, xs)
                  print(io, "<tr><td>")
                  x = displayinline(x)
                  writemime(io, bestmime(x), x)
                  print(io, "</td></tr>")
                end
                !isempty(drop(MAX_CELLS, xs)) && println(io, """<td>⋮</td><td>⋮</td>""")
                println(io, """</table>""")
              end)
