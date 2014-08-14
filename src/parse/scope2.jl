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

# Similar to Lexer.next_token, but treats comments and whitespace as tokens
function nexttoken(ts)
  Lexer.skipws(ts) == true && return token(:whitepace)
  c = Lexer.peekchar(ts)

  c == '#' && return lexcomment(ts)
  c == '"' && return lexstring(ts.io)

  t = next_token(ts)
  return t
end

# Scope passing

immutable Scope
  kind::Symbol
  name::UTF8String
end

typealias Scopes Vector{Scope}

# ts = Lexer.TokenStream(IOBuffer("""
#   function foo()
#     \"""Hello World\"""
#   end
#   """))

# nexttoken(ts)
