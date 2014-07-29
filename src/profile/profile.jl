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
           JS.framedata(li, tree.data.count/count),
           JS.frametooltip,
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
          JS.mapzoom,
          JS.mapdrag,
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
