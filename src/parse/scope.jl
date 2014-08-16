# A pseudo-parser which extracts information from Julia code

using LNR
import JuliaParser.Lexer
include("streams.jl")

# Legacy definitions, should be removed eventually
const identifier_inner = r"[^,⊶⩃↣⩄≗≦⥥∓≨⊘×≥≫⥘⪚⋼⭂⥩⩾⥓∝⤞⇼⥍⭈∽⩁⥎⟑⟉∊∷≳≠⩧⫏⇿⬵≬⩗⥭⦾⥖→∪⫑⪀⩠⥢⤌⋝⊕⪪≈⪏≤⨤⪿⟰≼⫂≹⪣⋴≧∸≐⭋∨⨳⭁∺⋥⟽⊷⟱≡\]⤅⪃⩋⩊⋣⋎⥗⨮⬻⪻≢∙⪕⩓⫺∧⧻⨭⊵≓⥬⥛⋿⭃⫒⫕⩡⬺⧷⥄⊱⨰⊇≊⨬≖>⤕⬴⟿⋘⪇≯⋕⤏⟶⥚⥜⨼∥⪠⥝⬷∘⊴⪈⤔⪍⫄?⊰⪌⋩≟⋜⫀\)⫎⩦⋏⫷⊋⪱⤀⩯⤘⫌⩱≜↓⋗↑≛⋌⪢⫖⋖⩰⊏⊗⪡⋆⟈⤂⥆⧁⊻⤋⤖⩹↦⪳⩸⥅∔⨺⋐≶⟵\}⪙⪧⇺%≭≕⥔⥐⊆⋸⅋⋒≃≝≿⇴⩌⋠⇽≰/⫙⊠⪼⇔\[⟾+≩⊟⨶⥰⪉≎≷⩣⭄&⨲⧣⩭≑⊐⫗⩬⩢⬽⪯⪓⪒≪∈⪘⬿⫸⇹⊅⨥⨩≚⋹⊃⊂⪞⋺⨹⋦∦≮⋧⋛⋾⊁≉￪≔±\{⩒⩑⋫￩⥤⨽⬲⪄⫓⪑∩⧡⩮⪟⪛⋽⪦⇒≁⪝⬳⩝⩳≴⪰⟻≣⦼⩷⇶⋳⪺⪜⩕⥦∛≽⋑⤓⟼⩏≲⊲≸⟺⇷⟹∌⩪⊞⫉⨴⪤⪸⥡⩔⭊⪆⩲⫈⥒⫋⬶⫁⪵∗⫊⩖≙⩐≍⨫⦸⋚⊄⫐⥇⥣⪲↔⪷⨈⧺⭌⨨≄⤟^≵⋭⋊⟷⩅∤⫆⊽\(⬸⤒⪾⩞⥫⥙⋙⨱⬹<⊎⤊⤁⇏≺⋵⥏⩴⋶⪂⥕⪨⋇⊊⫅⊖⪶⋬≻⋍⋓⩍≱⇻⩵↮⋋⪖⨢↠⤎⊈⊮⋪⊓⪔\⨧⩜⥞⫇⪫⬾⋷⤃⧥⫃⨷⥈⤄⩼⋤⥠⬼⤠⩛≂↚⥧|∍⨻⊙⨪∋⪋⋲⤍.\"⊑⩟⇎*:￬⭉⤉⥯⬱⇾⋡÷⥟⥋∉⬰≞≾⫍⨵⩚⩫≅⩿⪎⪴⊒⪽≀⫹⤇⋅⩀⊡⤆∜⤈⨣↛⊩⫔⦷⩺≋\-≇⋨⊜~⫛≌⥉√⋢⊛⤗⋟⧶≏⊔⪗⋞ ⩎⊳∾⥨￫⩘⥌⪹⪩⩻=⨸⪊⨇⧤⇸⊉⥑⥮⭀⧀⊚⊬≒\$⊀⋻⦿⭇⥊≆←⤐≘⋉⊼⥪⧴⪅⩽⪬⪁⋄⤑⨦⩶⇵⪥⊍⫘⩂⪐⟒⪭⪮⤝∻\"\n]"
const identifier = Regex("(?![!0-9])$(identifier_inner.pattern)+")
const identifier_start = Regex("^$(identifier.pattern)")

@defonce type Token{T} end

token(T) = Token{T}()

Base.symbol{T}(t::Token{T}) = T

Lexer.peekchar(r::LineNumberingReader) =
  eof(r)? Lexer.EOF : LNR.peekchar(r)

function lexcomment(ts)
  Lexer.readchar(ts)
  if !eof(ts.io) && Lexer.peekchar(ts) == '='
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

isidentifier(x::Symbol) = !(x in Lexer.syntactic_ops) && !(x in (:(:),))
isidentifier(x) = false

function qualifiedname(ts, name = nexttoken(ts))
  n = [name]
  pos = 0
  while true
    pos = position(ts.io)
    Lexer.next_token(ts) == :(.) || break
    t = Lexer.next_token(ts)
    isidentifier(t) || break
    push!(n, t)
  end
  seek(ts.io, pos)
  return length(n) > 1 ? n : n[1]
end

function nexttoken(ts)
  Lexer.skipws(ts)
  c = Lexer.peekchar(ts)

  t = c == '#' ? lexcomment(ts) :
      c == '"' ? lexstring(ts.io) :
      Lexer.next_token(ts)

  isidentifier(t) && (t = qualifiedname(ts, t))

  ts.lasttoken = t
  return t
end

function peektoken(ts)
  t = last = ts.lasttoken
  LNR.withstream(ts.io) do
    t = nexttoken(ts)
  end
  ts.lasttoken = last
  return t
end

# Scope parsing

immutable Scope
  kind::Symbol
  name::UTF8String
end

Scope(kind) = Scope(kind, "")
Scope(kind::Symbol, name::String) = Scope(kind, convert(UTF8String, name))
Scope(kind, name) = Scope(symbol(kind), string(name))

==(a::Scope, b::Scope) = a.kind == b.kind && a.name == b.name

const blockopeners = Set(map(symbol, ["begin", "function", "type", "immutable",
                                      "let", "macro", "for", "while",
                                      "quote", "if", "else", "elseif",
                                      "try", "finally", "catch", "do",
                                      "module"]))

const blockclosers = Set(map(symbol, ["end", "else", "elseif", "catch", "finally"]))

function nextscope!(scopes, ts)
  lasttoken = ts.lasttoken
  t = nexttoken(ts)
  if t in (:module, :baremodule) && isa(peektoken(ts), Symbol)
    push!(scopes, Scope(:module, nexttoken(ts)))
  elseif t in blockopeners
    push!(scopes, Scope(:block, t))
  elseif t in ('(', '[', '{')
    push!(scopes, Scope(:array, t))
  elseif last(scopes).kind in (:array, :call) && t in (')', ']', '}')
    pop!(scopes)
  elseif t == symbol("end")
    last(scopes).kind in (:block, :module) && lasttoken ≠ :(:) && pop!(scopes)
  elseif t == :using
    push!(scopes, Scope(:using))
  elseif t == '\n'
    last(scopes).kind == :using && pop!(scopes)
  elseif isidentifier(t) || isa(t, Vector{Symbol})
    if peektoken(ts) == '('
      nexttoken(ts)
      push!(scopes, Scope(:call, join([t], ".")))
    end
  end
  return t
end

# API functions

Optional(T) = Union(T, Nothing)

function scopes(code::LineNumberingReader, cur::Optional(Cursor) = nothing)
  ts = Lexer.TokenStream(code)
  scs = [Scope(:toplevel)]
  while !eof(code) && (cur == nothing || cursor(code) < cur)
    Lexer.skipws(ts) == true && continue
    nextscope!(scs, ts)
  end
  t = ts.lasttoken
  if isa(t, Token) && symbol(t) ≠ :whitespace && (cur == nothing ||
                                                  cur < cursor(code))
    push!(scs, Scope(t))
  elseif last(scs).kind == :call && !(cur == nothing ||
                                      cur >= cursor(code))
    # (only in a :call scope if past the last bracket)
    pop!(scs)
  end
  return scs
end

toLNR(s::String) = LineNumberingReader(s)
toLNR(r::LineNumberingReader) = r
toCursor(i::Integer) = cursor(i, 1)
toCursor(c::Cursor) = c
toCursor(::Nothing) = nothing

scopes(code, cur=nothing) = scopes(toLNR(code), toCursor(cur))

scope(code, cur=nothing) = last(scopes(code, cur))

function tokens(code::LineNumberingReader, cur::Optional(Cursor) = nothing)
  ts = Lexer.TokenStream(code)
  words = Set{UTF8String}()
  while !eof(code)
    Lexer.skipws(ts); start = cursor(code)
    t = nexttoken(ts)
    (cur != nothing && start ≤ cur ≤ cursor(code)) && continue
    isa(t, Symbol) && push!(words, string(t))
    isa(t, Vector{Symbol}) && push!(words, join(t, "."))
  end
  return words
end

tokens(code, cur=nothing) = tokens(toLNR(code), toCursor(cur))
