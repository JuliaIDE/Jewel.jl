using Compat
function showresult(value::String, opts; under = false, html = false)
  temp = @compat Dict("value" => value,
         "bounds" => opts[:bounds],
         "under" => under,
         "html"  => html,
         "info"    => opts[:info])
  raise(opts[:editor], "julia.result",
          temp)
end

function showexception(req, value::String, bounds)
  raise(req, "julia.error",
          @compat Dict("value" => value,
         "start" => bounds[1],
         "end"   => bounds[2]))
end

function showexception(editor, e, bt, bounds)
  notify_error(sprint(showerror, e))
  showexception(
    editor,
    sprint(showerror_html, e, bt, :include_string),
    bounds)
end
