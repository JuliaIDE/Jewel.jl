module ProfileView

using Compose, Lazy

include("javascript.jl")
include("css.jl")
include("data.jl")

# SVG

childwidths(node::ProfileTree) =
  map(child -> child.data.count/node.data.count, node.children)

maprange(x1, x2, y1, y2, p) = (p-x1)/(x2-x1)*(y2-y1)+y1

fixedscale(node::ProfileTree) = ones(length(node.children))
# widthscale(node::ProfileTree) = childwidths(node)
widthscale(node::ProfileTree) = map(w -> maprange(0, 1, 1/5, 1, w), childwidths(node))

function render_(tree::ProfileTree; childscale = fixedscale, count = 0)
  widths = childwidths(tree)
  offsets = cumsum([0, widths[1:end-1]...])
  scale = childscale(tree)
  li = tree.data.line
  compose(context(),
          (context(), rectangle(),
           jscall("""
             data("lineinfo", {"func": "$(li.func)",
                               "file": "$(li.file)",
                               "line": "$(li.line)",
                               "percent": "$(@sprintf("%.2f", 100*tree.data.count/count))"});
           """),
           jscall("""
             hover(function(){ updatetooltip(this.data("lineinfo")); },
                   function(){ updatetooltip(); });
           """),
           svgclass("file-link"),
           svgattribute("data-file", "$(li.file):$(li.line)")),
          [compose(context(offsets[i], 1, widths[i], scale[i]),
                   render_(tree.children[i], childscale=childscale, count=count))
           for i = 1:length(tree.children)]...)
end

maxheight(node::ProfileTree; childscale = fixedscale) =
  isleaf(node) ? 1 :
    1 + maximum(childscale(node) .*
                  map(node->maxheight(node, childscale=childscale),
                      node.children))

render(tree::ProfileTree; childscale = fixedscale) =
  compose(context(),
          (context(0,0,1,1/maxheight(tree, childscale = childscale)),
           render_(tree,childscale = childscale, count = tree.data.count),
           svgclass("tree")),
          (context(), rectangle(), fill("white")),
          jscall("""
            node.addEventListener("mousewheel", function(event) {
              event.preventDefault();
              event.stopPropagation();

              var e = Snap(this);
              var scale = Math.pow(0.9, event.wheelDelta/100);
              var transform = e.transform().localMatrix;
              var inverse = e.transform().globalMatrix.invert();
              var x = event.clientX; var y = event.clientY;

              e.transform(transform.scale(scale, scale, inverse.x(x, y), inverse.y(x, y)));
            });
          """),
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
          """),
          jscall("""
            selectAll("rect").forEach(function (element) {
              element.attr("vector-effect", "non-scaling-stroke");
            });
          """),
          jscall("""
            mousemove(function(event) {
              tooltip == "nothing" && (tooltip = this.node.parentNode.parentNode.querySelector(".tooltip"));
              tooltip.style.left = event.clientX;
              tooltip.style.top = event.clientY;
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
            });

            var tooltip = "nothing";
            var tooltipvisible = false;
            var hovering = false;

            function updatetooltip(data) {
              if(data != undefined) {
                hovering = true;
                tooltip.querySelector(".func").textContent = data.func;
                tooltip.querySelector(".file").textContent = data.file + ":" + data.line;
                tooltip.querySelector(".percent").textContent = data.percent + "%";
              } else {
                hovering = false;
              }
            }
          """))

showsvg(svg) = sprint(io -> draw(SVGJS(io, 5inch, 3inch, false), svg)) |> LightTable.HTML

function save(svg)
  open("test.html", "w") do io
    write(io, CSS.css)
    write(io, """
      <div class="profile">
        <div class="tooltip">
          <div><span class="func">func</span> <span class="percent">percent</span></div>
          <div class="file">file</div>
        </div>
    """)
    draw(SVGJS(io, 5inch, 3inch, false), svg)
    write(io, """
      </div>
    """)
  end
end

nothing

end
