tocursors(range, start=1) =
  cursor(range[1]-start+1, range[2]+1),
  cursor(range[1]-start+1, range[3]+1)

function fillranges(code, values, ranges, line = 1)
  reader = LineNumberingReader(code)
  result = IOBuffer()
  for i = 1:length(ranges)
    start, stop = tocursors(ranges[i], line)
    while cursor(reader) < start
      print(result, read(reader, Char))
    end
    while cursor(reader) < stop
      read(reader, Char)
    end
    print(result, values[i])
  end
  while !eof(reader)
    print(result, read(reader, Char))
  end
  return takebuf_string(result)
end
