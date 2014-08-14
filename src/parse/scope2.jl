using LNR, Lazy
import JuliaParser.Lexer
import JuliaParser.Lexer: next_token, peekchar, readchar

include("streams.jl")

type Token{T} end

token(T) = Token{T}()

function lexcomment(ts)
  readchar(ts)
  if peekchar(ts) == '='
    Lexer.skip_multiline_comment(ts, 1)
    return token(:multicomment)
  else
    Lexer.skip_to_eol(ts)
    return token(:comment)
  end
end

function skipstring(stream::IO, multi=false)
  while !eof(stream)
    if startswith(stream, "\\\"")
    elseif startswith(stream, multi ? "\"\"\"" : "\"")
      break
    else
      read(stream, Char)
    end
  end
end

# TODO: handle string splicing
function lexstring(stream::IO)
  multi = startswith(stream, "\"\"\"")
  multi || startswith(stream, '"')
  skipstring(stream, multi)
  return token(multi ? :multistring : :string)
end

function nexttoken(ts)
  Lexer.skipws(ts) == true && return token(:whitepace)
  c = Lexer.peekchar(ts)

  c == '#' && return lexcomment(ts)
  c == '"' && return lexstring(ts.io)

  t = next_token(ts)
  return t
end

function peektoken(ts)
  LNR.withstream(ts.io) do
    nexttoken(ts)
  end
end

# Scope parsing

immutable Scope
  kind::Symbol
  name::UTF8String
end

Scope(kind) = Scope(kind, "")
Scope(kind::Symbol, name::String) = Scope(kind, convert(UTF8String, name))
Scope(kind, name) = Scope(symbol(kind), string(name))

const blockopeners = Set(map(symbol, ["begin", "function", "type", "immutable",
                                      "let", "macro", "for", "while",
                                      "quote", "if", "else", "elseif",
                                      "try", "finally", "catch", "do",
                                      "module"]))

const blockclosers = Set(map(symbol, ["end", "else", "elseif", "catch", "finally"]))

function nextscope!(scopes, ts)
  t = nexttoken(ts)
  if t in blockopeners
    push!(scopes, Scope(:block, t))
  elseif t in ('(', '[', '{')
    push!(scopes, Scope(:array, t))
  elseif last(scopes).kind == :array && t in (')', ']', '}')
    pop!(scopes)
  end
  return t
end

ts = Lexer.TokenStream(IOBuffer("""
  function.foo foo()
    \"""Hello World\"""
  end
  """))

# scs = [Scope(:toplevel)]
# nextscope!(scs, ts)
# scs
