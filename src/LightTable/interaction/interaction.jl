# Result tracking

import Base.Random: uuid4, UUID

type Result{T}
  id::UUID
  value::T
end

const results = (UUID=>Result)[]

handle("result.clear") do _, id
  delete!(results, UUID(id))
end

function register_result(result)
  id = uuid4()
  results[id] = Result(id, result)
  return id
end
