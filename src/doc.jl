#jewel module Jewel

handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  isempty(line) && return
  token = get_qualified_name(line, data["cursor"]["col"])

  meth = get(data, "type", nothing) == "methods"

  meth && (mod = get_module_name(data);
              thing = get_thing(mod, token))

  (!meth || thing != nothing) &&
    editor_command(req, "doc", {:doc => meth?
                                          sprint(writemime, "text/html", methods(thing)) :
                                          help_str(token),
                                :loc => {:line => data["cursor"]["line"]-1},
                                :html => meth})
end

