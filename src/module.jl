# –––––––––––––––
# Some file utils
# –––––––––––––––

files(dir) =
  @>> dir readdir map!(f->joinpath(dir, f)) filter!(isfile)

dirs(dir) =
  @>> dir readdir filter!(f->!beginswith(f, ".")) map!(f->joinpath(dir, f)) filter!(isdir)

jl_files(dir::String) = @>> dir files filter!(f->endswith(f, ".jl"))

function jl_files(set)
  files = Set{UTF8String}()
  for dir in set, file in jl_files(dir)
    push!(files, file)
  end
  return files
end

"""
Takes a start directory and returns a set of nearby directories.
"""
# Recursion + Mutable State = Job Security
function dirsnearby(dir; descend = 1, ascend = 1, set = Set{UTF8String}())
  push!(set, dir)
  if descend > 0
    for down in dirs(dir)
      if !(down in set)
        push!(set, down)
        descend > 1 && dirsnearby(down, descend = descend-1, ascend = 0, set = set)
      end
    end
  end
  ascend > 0 && dirsnearby(dirname(dir), descend = descend, ascend = ascend-1, set = set)
  return set
end

# ––––––––––––––
# The Good Stuff
# ––––––––––––––

"""
Takes a given Julia source file and another (absolute) path, gives the
line on which the path is included in the file or 0.
"""
function includeline(file::String, included_file::String)
  i = 0
  open(file) do io
    for (index, line) in enumerate(eachline(io))
      m = match(r"include\(\"([a-zA-Z_\.\\/]*)\"\)", line)
      if m != nothing && normpath(joinpath(dirname(file), m.captures[1])) == included_file
        i = index
        break
      end
    end
  end
  return i
end

"""
Takes an absolute path to a file and returns the (file, line) where that
file is included or nothing.
"""
function find_include(path::String)
  for file in @> path dirname dirsnearby jl_files
    line = includeline(file, path)
    line > 0 && (return file, line)
  end
end

"""
Takes an absolute path to a file and returns a string
representing the module it belongs to.
"""
function file_module(path::String)
  loc = find_include(path)
  if loc != nothing
    file, line = loc
    mod = Main.LightTable.get_module_name(readall(file), line) # TODO: use more robust parser
    super = file_module(file)
    if super != "" && mod != ""
      return "$super.$mod"
    else
      return super == "" ? mod : super
    end
  end
  return ""
end
