#jewel module LightTable

# Should split out editor.julia.methods
handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  isempty(line) && return notify_done("")
  token = get_qualified_name(line, data["cursor"]["col"])

  meth = get(data, "type", nothing) == "methods"

  meth && (mod = get_thing(get_module_name(data), Main);
           f = get_thing(mod, token))

  doc_str = nothing
  meth && f != nothing &&
    (doc_str = sprint(writemime, "text/html",
                 typeof(f) in (Function, DataType) && isgeneric(f) ?
                   methods(f) : eval(Main, :(methodswith($(typeof(f)), true)))))
  !meth && (doc_str = help_str(token))

  (doc_str != nothing &&
    editor_command(req, "doc", {:doc => doc_str,
                                :loc => {:line => data["cursor"]["line"]-1},
                                :html => meth}))
  notify_done("")
end
