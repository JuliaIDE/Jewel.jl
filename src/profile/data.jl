# Get traces

import Base.Profile: LineInfo

typealias IP UInt
typealias RawData Vector{IP}
typealias Trace Vector{LineInfo}

const lidict = Dict{IP,LineInfo}()
lookup(ip::IP) = haskey(lidict, ip) ? lidict[ip] : (lidict[ip] = Profile.lookup(ip))
lookup(ips::RawData) = map(lookup, ips)

pruneC(trace::Trace) = filter(line->!line.fromC, trace)

traces(data::Vector{UInt}) =
  @>> split(data, 0, keep=false) map(lookup) map!(pruneC) map!(reverse) filter!(t->!isempty(t))

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

# Remove redundant lines

childwidths(node::ProfileTree) =
  map(child -> child.data.count/node.data.count, node.children)

function trimroot(tree::ProfileTree)
  validchildren = tree.children[childwidths(tree) .> 0.1]
  length(validchildren) == 1 ? trimroot(validchildren[1]) : tree
end

function sortchildren!(tree::ProfileTree)
  sort!(map!(sortchildren!,tree.children), by = node->node.data.line.line)
  tree
end

# Flatten the tree

function addmerge!(a::Associative, b::Associative)
  for (k, v) in b
    a[k] = haskey(a, k) ? a[k]+b[k] : b[k]
  end
  return a
end

flatlines(tree::ProfileTree; total = tree.data.count) =
  reduce(addmerge!,
         [tree.data.line=>tree.data.count/total],
         map(t->flatlines(t, total = total), tree.children))

function fetch()
  data = Profile.fetch()
  isempty(data) && error("You need to do some profiling first.")
  @> data traces tree trimroot sortchildren!
end
