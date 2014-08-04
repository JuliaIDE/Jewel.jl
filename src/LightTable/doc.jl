# Should split out editor.julia.methods
handle("editor.julia.doc") do editor, data
  code = data["code"]
  cursor = data["cursor"]["line"], data["cursor"]["col"]
  mod = getthing(data["module"])

  if get(data, "type", nothing) == "methods"
    meths = Jewel.methodsorwith(code, cursor, mod)
    meths != nothing &&
      raise(editor, "editor.julia.doc", {:doc => stringmime("text/html", meths),
                                         :loc => {:line => cursor[1]-1},
                                         :html => true})
  else
    help = Jewel.doc(code, cursor, mod)
    help != nothing &&
      raise(editor, "editor.julia.doc", {:doc => help,
                                         :loc => {:line => cursor[1]-1}})
  end
  notify_done("")
end
