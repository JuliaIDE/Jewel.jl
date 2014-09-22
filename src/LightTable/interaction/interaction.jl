# Result tracking

import Base.Random: uuid4, UUID

type Result
  id::UUID
  value
  data
end

Result(id, value) = Result(id, value, Dict())

const results = (UUID=>Result)[]

handle("result.clear") do _, id
  delete!(results, UUID(id))
end

function register_result(result, dict...)
  id = uuid4()
  results[id] = Result(id, result, dict...)
end

# Raise on results

raise(obj::UUID, event, args...) =
  raise(global_client, :raise, {:id => string(obj),
                                :event => event,
                                :args => args})

raise(obj::Result, args...) = raise(obj.id, args...)

jscall(code) = raise(_currentresult_, :eval, code)

jsescapestring(s::String) = @> s replace("\\", "\\\\") replace("\"", "\\\"") replace("\n", "\\n") replace("'", "\\'")

# Current result

_currentresult_ = nothing

function withcurrentresult(f, r::Result)
  global _currentresult_ = r
  try
    f()
  finally
    _currentresult_ = nothing
  end
end

withcurrentresult(f, r::String) =
  withcurrentresult(f, get(results, UUID(r), nothing))

withcurrentresult(f, r) = nothing

# Evaluate Julia code

handle("eval.julia") do ed, data
  withcurrentresult(data["id"]) do
    include_string(data["code"])
  end
end

jlcall(code) =
  _currentresult_ == nothing ?
    """jlcall('$(htmlescape(code))')""" :
    """jlcall('$(_currentresult_.id)', '$(htmlescape(code))');"""
