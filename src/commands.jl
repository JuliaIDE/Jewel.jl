#jewel module Jewel

# ---------------
# Global Commands
# ---------------

handle("julia.set-global-client") do req, data
  global const global_client = req[1]
end

function command(cmd, data = Dict())
  data[:cmd] = cmd
  send(global_client, "editor.eval.julia.command", data)
end

function popup(header, body="", buttons = [{:label => "Ok"}])
  command("popup",
          [:header => header,
           :body => body,
           :buttons => buttons])
end

function ltprint(message; error = false)
  command("print",
          [:value => message,
           :error => error])
end

function notify_done()
  command("done")
end

function notify(message; class = "")
  command("notify",
          {:msg => message,
           :class => class})
end
