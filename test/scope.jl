@test get_scope("""
  function foo()
    |
  end
  """) == "function"

@test get_scope("""
  let x = 1, y = 2
    # comment
    Pkg.add(x, |)
  end
  """) == "Pkg.add"

@test get_scope("""
  let x = 1, y = 2
    # |comment
    Pkg.add(x, )
  end
  """).kind == :comment

@test get_scope("""
  for i in 1:10
    foo(|, y)
  end
  """) == "foo"

@test get_scope("""
  try
    fo|o(, y)
  end
  """) == "try"

# @test get_scope("""
#   function foo()
#     le|t x = 1, y = 2
#       foo()
#     end
#   end
#   """) == "function"

@test get_scope("""
  try
    foo()
  catch e
    |bar()
  end
  """) == "catch"

@test get_scope("""
  if a
    foo()
  else
    |bar()
  end
  """) == "else"

@test Jewel.codemodule(to_cursor("""
  module Foo
  module Bar|
  end
  end
  """)...) == "Foo.Bar"

# Treating end correctly in arrays
@test get_scope("""
  [end|]
  """) == Jewel.Scope(:array, "[")

# Failing gracefully with too many ends
@test get_scope("""
  end|
  """).kind == :toplevel

# Ignore the :end keyword
@test get_scope("""
  if foo
    :end|
  """) == "if"
