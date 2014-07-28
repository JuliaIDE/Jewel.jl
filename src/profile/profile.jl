module ProfileView

using Compose, Lazy

# Get traces

import Base.Profile: LineInfo

typealias IP Uint
typealias RawData Vector{IP}
typealias Trace Vector{LineInfo}

const lidict = (IP=>LineInfo)[]
lookup(ip::IP) = haskey(lidict, ip) ? lidict[ip] : (lidict[ip] = Profile.lookup(ip))
lookup(ips::RawData) = map(lookup, ips)

pruneC(trace::Trace) = filter(line->!line.fromC, trace)

traces(data::Vector{Uint}) =
  @>> split(data, 0) map(lookup) map!(pruneC) map!(reverse) filter!(t->!isempty(t))

# Tree Implementation

immutable Node{T}
  data::T
  children::Vector{Node{T}}
end

Node{T}(x::T) = Node(x, Node{T}[])
Node{T}(x::T, children::Node{T}...) = Node(x, [children...])

Base.push!(parent::Node, child::Node) = push!(parent.children, child)
isleaf(node::Node) = isempty(node.children)

# Profile Trees

type ProfileNode
  line::LineInfo
  count::Int
end

ProfileNode(line::LineInfo) = ProfileNode(line, 1)

typealias ProfileTree Node{ProfileNode}

tree(trace::Trace) =
  length(trace) ≤ 1 ?
    Node(ProfileNode(trace[1])) :
    Node(ProfileNode(trace[1]), tree(trace[2:end]))

# Conceptually, a trace is a tree with no branches
# We merge trees by (a) increasing the count of the common nodes
# and (b) adding any new nodes as children.
function Base.merge!(node::ProfileTree, trace::Trace)
  @assert !isempty(trace) && node.data.line == trace[1]
  node.data.count += 1
  length(trace) == 1 && return node
  for child in node.children
    if child.data.line == trace[2]
      merge!(child, trace[2:end])
      return node
    end
  end
  push!(node, tree(trace[2:end]))
  return node
end

function tree(traces::Vector{Trace})
  root = Node(ProfileNode(Profile.UNKNOWN))
  traces = map(trace -> [Profile.UNKNOWN, trace...], traces)
  for trace in traces
    merge!(root, trace)
  end
  return root
end

depth(node::Node) =
  isleaf(node) ? 1 : 1 + maximum(map(depth, node.children))

function trimroot(tree::ProfileTree)
  validchildren = tree.children[childwidths(tree) .> 0.1]
  length(validchildren) == 1 ? trimroot(validchildren[1]) : tree
end

# SVG

childwidths(node::ProfileTree) =
  map(child -> child.data.count/node.data.count, node.children)

maprange(x1, x2, y1, y2, p) = (p-x1)/(x2-x1)*(y2-y1)+y1

fixedscale(node::ProfileTree) = ones(length(node.children))
# widthscale(node::ProfileTree) = childwidths(node)
widthscale(node::ProfileTree) = map(w -> maprange(0, 1, 1/5, 1, w), childwidths(node))

function render_(tree::ProfileTree; childscale = fixedscale)
  widths = childwidths(tree)
  offsets = cumsum([0, widths[1:end-1]...])
  scale = childscale(tree)
  li = tree.data.line
  compose(context(),
          (context(), rectangle(),
           jscall("""
             data("lineinfo", {"func": "$(li.func)",
                               "file": "$(li.file)",
                               "line": "$(li.line)"});
           """),
           jscall("""
             hover(function(){ updatetooltip(this.data("lineinfo")); },
                   function(){ updatetooltip(); });
           """)),
          [compose(context(offsets[i], 1, widths[i], scale[i]),
                   render_(tree.children[i], childscale=childscale))
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
           render_(tree,childscale=childscale),
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
              } else {
                hovering = false;
              }
            }
          """))

showsvg(svg) = sprint(io -> draw(SVGJS(io, 5inch, 3inch, false), svg)) |> LightTable.HTML

css = """
  <style>
  .profile {
    position: relative;
  }
  .profile .tooltip {
    position: absolute;
    font-family: 'DejaVu Sans';
    font-size: 10pt;
    background: white;
    color: black;
    border: 1px solid #e1e1e1;
    box-shadow: 1px 1px 0px #e1e1e1;
    border-radius: 5px;
    padding: 5px;
    visibility: hidden;
  }
  .profile .func {
    font-weight: bold;
  }
  .tree rect {
    fill: #464;
    stroke: #FFF;
    transition: fill 0.2s ease;
  }
  .tree rect:hover {
    fill: #575;
  }
  </style>
  """

function save(svg)
  open("test.html", "w") do io
    write(io, css)
    write(io, """
      <div class="profile">
        <div class="tooltip">
          <div class="func">func</div>
          <div class="file">file</div>
        </div>
    """)
    draw(SVGJS(io, 5inch, 3inch, false), svg)
    write(io, """
      </div>
    """)
  end
end

t = @> data traces tree trimroot

# render(t,childscale=widthscale) |> save

# render(t) |> save

end
