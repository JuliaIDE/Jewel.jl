#jewel module Jewel

handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  isempty(line) && return
  token = get_qualified_name(line, data["cursor"]["col"])

  meth = get(data, "type", nothing) == "methods"

  meth && (mod = get_module_name(data);
           f = get_thing(mod, token))

  (!meth || (isa(f, Function) && isgeneric(f))) &&
    editor_command(req, "doc", {:doc => meth?
                                          sprint(writemime, "text/html", methods(f)) :
                                          help_str(token),
                                :loc => {:line => data["cursor"]["line"]-1},
                                :html => meth})
  notify_done("")
end
