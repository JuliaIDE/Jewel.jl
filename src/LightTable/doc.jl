# Should split out editor.julia.methods
handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  isempty(line) && return notify_done("")
  token = get_qualified_name(line, data["cursor"]["col"])

  meth = get(data, "type", nothing) == "methods"

  meth && (mod = get_module(data);
           f = getthing(mod, token))

  doc_str = nothing
  meth && f != nothing &&
    (doc_str = sprint(writemime, "text/html",
                 typeof(f) in (Function, DataType) && isgeneric(f) ?
                   methods(f) : eval(Main, :(methodswith($(typeof(f)), true)))))
  !meth && (doc_str = help_str(token))

  (doc_str != nothing &&
     raise(req, "editor.julia.doc", {:doc => doc_str,
                                     :loc => {:line => data["cursor"]["line"]-1},
                                     :html => meth}))
  notify_done("")
end
