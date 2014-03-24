#jewel module Jewel

handle("editor.julia.doc") do req, data
  line = lines(data["code"])[data["cursor"]["line"]]
  @show line
end
