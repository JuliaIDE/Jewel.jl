function showresult(value::AbstractString, opts; under = false, html = false)
  raise(opts[:editor], "julia.result",
        @d("value" => value,
          "bounds" => opts[:bounds],
          "under"  => under,
          "html"   => html,
          "info"   => opts[:info]))
end

function showexception(req, value::AbstractString, bounds)
  raise(req, "julia.error",
        @d("value" => value,
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
