# Should split out editor.julia.methods
handle("editor.julia.doc") do editor, data
  code = data["code"]
  c = cursor(data["cursor"]["line"], data["cursor"]["col"])
  mod = Jewel.getthing(data["module"])

  if get(data, "type", nothing) == "methods"
    meths = Jewel.methodsorwith(code, c, mod)
    meths != nothing &&
      raise(editor, "editor.julia.doc", @d(:doc => stringmime("text/html", meths),
                                           :loc => @d(:line => c.line-1),
                                           :html => true))
  else
    help = Jewel.doc(code, c, mod)
    help != nothing &&
      raise(editor, "editor.julia.doc", @d(:doc => help,
                                           :loc => @d(:line => c.line-1)))
  end
  notify_done("")
end
