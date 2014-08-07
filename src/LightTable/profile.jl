function displayinline!(req, tree::Jewel.ProfileView.ProfileTree, bounds)
  raise(req, "julia.profile-result",
        {"value" => stringmime("text/html", tree),
         "start" => bounds[1],
         "end"   => bounds[2],
         "lines" => [{:file => li.file,
                      :line => li.line,
                      :percent => p} for (li, p) in Jewel.ProfileView.fetch() |> Jewel.ProfileView.flatlines]})
end
