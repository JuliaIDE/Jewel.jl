# Modules

handle("editor.julia.module.update") do editor, data
  mod = data["path"] == nothing ? "Main" : Jewel.filemodule(data["path"])
  mod == "" && (mod = "Main")
  if Jewel.getthing(mod) == nothing
    notify("This file's module, `$mod`, isn't loaded yet.", class = "error")
    mod = "Main"
  end
  raise(editor, "editor.julia.module.update", mod)
end

# Profile tree display

function toabspath(file)
  isabspath(file) && file
  path = Jewel.basepath(file)
  return path == nothing ? file : path
end

function displayinline!(req, tree::Jewel.ProfileView.ProfileTree, bounds)
  raise(req, "julia.profile-result",
        {"value" => stringmime("text/html", tree),
         "start" => bounds[1],
         "end"   => bounds[2],
         "lines" => [{:file => toabspath(li.file),
                      :line => li.line,
                      :percent => p} for (li, p) in Jewel.ProfileView.fetch() |> Jewel.ProfileView.flatlines]})
end

# Function display

function writemime(io::IO, ::MIME"text/html", f::Function)
  if isgeneric(f)
    print(io, f.env.name)
  elseif isdefined(f, :env) && isa(f.env,Symbol)
    print(io, f.env)
  else
    print(io, "λ")
  end
end

function displayinline!(editor, f::Function, bounds)
  showresult(editor, stringmime("text/html", f), bounds, html=true)
end
