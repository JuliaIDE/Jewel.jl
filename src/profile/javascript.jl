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

# SVG JS

const mapzoom =
  jscall("""
    node.addEventListener("mousewheel", function(event) {
      event.preventDefault();
      event.stopPropagation();

      var e = Snap(this);
      var scale = Math.pow(0.9, event.wheelDelta/100);
      var transform = e.transform().localMatrix;
      var inverse = e.transform().globalMatrix.invert();
      var x = event.offsetX; var y = event.offsetY;

      e.transform(transform.scale(scale, scale, inverse.x(x, y), inverse.y(x, y)));
    });
  """)

const mapdrag =
  jscall("""
    drag(
      function(dx, dy) {
        var newdx = dx, newdy = dy;
        var olddx = this.data("dx"), olddy = this.data("dy");
        dx = newdx - olddx; dy = newdy - olddy;
        this.data("dx", newdx); this.data("dy", newdy);
        var transform = this.transform().localMatrix;
        var global = this.transform().globalMatrix.split();
        scalex = global.scalex; scaley = global.scaley;
        this.transform(transform.translate(dx/scalex, dy/scaley));
      },
      function() {
        this.data("dx", 0); this.data("dy", 0);
      });
  """)

const nonscalingstroke =
  jscall("""
    selectAll("rect").forEach(function (element) {
      element.attr("vector-effect", "non-scaling-stroke");
    });
  """)

const settooltip =
  jscall("""
    mouseover(function(event) {
      tooltip == "nothing" && (tooltip = this.node.parentNode.parentNode.querySelector(".tooltip"));
    });
  """)

const tooltip =
  jscall("""
    mousemove(function(event) {
      tooltip.style.left = event.offsetX + 10;
      tooltip.style.top = event.offsetY + 10;
    });

    var tooltip = "nothing";
    var tooltipvisible = false;
    var hovering = false;

    function updatevisible() {
      // TODO: Use JQuery show()/hide().
      if(tooltipvisible != hovering) {
        if(hovering) {
          tooltip.style.visibility = "visible";
          tooltipvisible = true;
        } else {
          tooltip.style.visibility = "hidden";
          tooltipvisible = false;
        }
      }
    }

    function updatetooltip(data) {
      if (tooltip == "nothing") return;
      if(data != undefined) {
        hovering = true;
        tooltip.querySelector(".func").textContent = data.func;
        tooltip.querySelector(".file").textContent = data.file + ":" + data.line;
        tooltip.querySelector(".percent").textContent = data.percent + "%";
      } else {
        hovering = false;
      }
      updatevisible();
    }
  """)

end
