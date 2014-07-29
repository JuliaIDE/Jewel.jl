module JS

using Compose

# Scripts for individual frames

framedata(line, proportion) =
  jscall("""
    data("lineinfo", {"func": "$(line.func)",
                      "file": "$(line.file)",
                      "line": "$(line.line)",
                      "percent": "$(@sprintf("%.2f", 100*proportion))"});
  """)

const frametooltip =
  jscall("""
    hover(function(){ updatetooltip(this.data("lineinfo")); },
          function(){ updatetooltip(); });
  """)

nothing

end
