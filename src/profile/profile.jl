module ProfileView

using Compose, Lazy

include("javascript.jl")
include("css.jl")
include("data.jl")

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
          JS.mapzoom, JS.mapdrag, JS.nonscalingstroke, JS.tooltip)

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
