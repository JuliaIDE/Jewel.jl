#jewel module Jewel

handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  isempty(line) && return
  token = get_qualified_name(line, data["cursor"]["col"])

  editor_command(req, "doc", {:doc => help_str(token),
                              :loc => {:line => data["cursor"]["line"]-1}})
end

names
