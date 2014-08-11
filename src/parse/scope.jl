# A pseudo-parser which extracts information from Julia code

# stream utils

using LNR

import Base: peek

const whitespace = " \t"

function skipwhitespace(io::IO; newlines = true)
  while !eof(io) && (peek(io) in whitespace || (newlines && peek(io) == '\n'))
    read(io, Char)
  end
  return io
end

function startswith(stream::IO, s::String; eat = true, padding = false)
  start = position(stream)
  padding && skipwhitespace(stream)
  result = true
  for char in s
    !eof(stream) && read(stream, Char) == char ||
      (result = false; break)
  end
  !(result && eat) && seek(stream, start)
  return result
end

function startswith{T<:String}(stream::IO, ss::Vector{T}; eat = true)
  for s in ss
    startswith(stream, s, eat = eat) && return true
  end
  return false
end

function startswith(stream::IO, r::Regex; eat = true, padding = false)
  @assert beginswith(r.pattern, "^")
  start = position(stream)
  padding && skipwhitespace(stream)
  line = chomp(readline(stream))
  seek(stream, start)
  m = match(r, line)
  m == nothing && return ""
  eat && @dotimes length(m.match) read(stream, Char)
  return m.match
end

# the parser

const identifier_inner = r"[^,⊶⩃↣⩄≗≦⥥∓≨⊘×≥≫⥘⪚⋼⭂⥩⩾⥓∝⤞⇼⥍⭈∽⩁⥎⟑⟉∊∷≳≠⩧⫏⇿⬵≬⩗⥭⦾⥖→∪⫑⪀⩠⥢⤌⋝⊕⪪≈⪏≤⨤⪿⟰≼⫂≹⪣⋴≧∸≐⭋∨⨳⭁∺⋥⟽⊷⟱≡\]⤅⪃⩋⩊⋣⋎⥗⨮⬻⪻≢∙⪕⩓⫺∧⧻⨭⊵≓⥬⥛⋿⭃⫒⫕⩡⬺⧷⥄⊱⨰⊇≊⨬≖>⤕⬴⟿⋘⪇≯⋕⤏⟶⥚⥜⨼∥⪠⥝⬷∘⊴⪈⤔⪍⫄?⊰⪌⋩≟⋜⫀\)⫎⩦⋏⫷⊋⪱⤀⩯⤘⫌⩱≜↓⋗↑≛⋌⪢⫖⋖⩰⊏⊗⪡⋆⟈⤂⥆⧁⊻⤋⤖⩹↦⪳⩸⥅∔⨺⋐≶⟵\}⪙⪧⇺%≭≕⥔⥐⊆⋸⅋⋒≃≝≿⇴⩌⋠⇽≰/⫙⊠⪼⇔\[⟾+≩⊟⨶⥰⪉≎≷⩣⭄&⨲⧣⩭≑⊐⫗⩬⩢⬽⪯⪓⪒≪∈⪘⬿⫸⇹⊅⨥⨩≚⋹⊃⊂⪞⋺⨹⋦∦≮⋧⋛⋾⊁≉￪≔±\{⩒⩑⋫￩⥤⨽⬲⪄⫓⪑∩⧡⩮⪟⪛⋽⪦⇒≁⪝⬳⩝⩳≴⪰⟻≣⦼⩷⇶⋳⪺⪜⩕⥦∛≽⋑⤓⟼⩏≲⊲≸⟺⇷⟹∌⩪⊞⫉⨴⪤⪸⥡⩔⭊⪆⩲⫈⥒⫋⬶⫁⪵∗⫊⩖≙⩐≍⨫⦸⋚⊄⫐⥇⥣⪲↔⪷⨈⧺⭌⨨≄⤟^≵⋭⋊⟷⩅∤⫆⊽\(⬸⤒⪾⩞⥫⥙⋙⨱⬹<⊎⤊⤁⇏≺⋵⥏⩴⋶⪂⥕⪨⋇⊊⫅⊖⪶⋬≻⋍⋓⩍≱⇻⩵↮⋋⪖⨢↠⤎⊈⊮⋪⊓⪔\⨧⩜⥞⫇⪫⬾⋷⤃⧥⫃⨷⥈⤄⩼⋤⥠⬼⤠⩛≂↚⥧|∍⨻⊙⨪∋⪋⋲⤍.\"⊑⩟⇎*:￬⭉⤉⥯⬱⇾⋡÷⥟⥋∉⬰≞≾⫍⨵⩚⩫≅⩿⪎⪴⊒⪽≀⫹⤇⋅⩀⊡⤆∜⤈⨣↛⊩⫔⦷⩺≋\-≇⋨⊜~⫛≌⥉√⋢⊛⤗⋟⧶≏⊔⪗⋞ ⩎⊳∾⥨￫⩘⥌⪹⪩⩻=⨸⪊⨇⧤⇸⊉⥑⥮⭀⧀⊚⊬≒\$⊀⋻⦿⭇⥊≆←⤐≘⋉⊼⥪⧴⪅⩽⪬⪁⋄⤑⨦⩶⇵⪥⊍⫘⩂⪐⟒⪭⪮⤝∻\"\n]"
const identifier = Regex("(?![!0-9])$(identifier_inner.pattern)+")
const identifier_start = Regex("^$(identifier.pattern)")

const blockopeners = Set(["begin", "function", "type", "immutable",
                         "let", "macro", "for", "while",
                         "quote", "if", "else", "elseif",
                         "try", "finally", "catch", "do",
                         "module"])

const blockclosers = Set(["end", "else", "elseif", "catch", "finally"])

const operators = r"(?:\.?[|&^\\%*+\-<>!=\/]=?|\?|~|::|:|\$|<:|\.[<>]|<<=?|>>>?=?|\.[<>=]=|->?|\/\/|\bin\b|\.{3}|\.)"
const operators_end = Regex("^\\s*"*operators.pattern*"\$")

const macros = Regex("@(?:" * identifier.pattern * "\\.?)*")
const macro_start = Regex("^"*macros.pattern)

scope_pass(s::String; kws...) = scope_pass(LineNumberingReader(s); kws...)

# Pretty much just a port of the CodeMirror mode
# I'm going to be upfront on this one: this is not my prettiest code.
function scope_pass(stream::LineNumberingReader; stop = false, collect = true, target = (0, 0))
  isa(target, Integer) && (target = (target, 1))
  collect && (tokens = Set{UTF8String}())
  scopes = Dict[{:type => :toplevel}]

  tokenstart = cursor(1, 1)
  crossedcursor() = tokenstart <= cursor(target...) <= cursor(stream)

  cur_scope() = scopes[end][:type]
  cur_scope(ts...) = cur_scope() in ts
  leaving_expr() = cur_scope() == :binary && pop!(scopes)
  pushtoken(t) = collect && !crossedcursor() && push!(tokens, t)
  function pushscope(scope)
    if !(stop && cursor(stream) > cursor(target...))
      push!(scopes, scope)
    end
  end

  while !eof(stream)
    tokenstart = cursor(stream)

    # Comments
    if startswith(stream, "\n")
      cur_scope() in (:comment, :using) && pop!(scopes)

    elseif cur_scope() == :comment
      read(stream, Char)

    elseif startswith(stream, "#=")
      pushscope({:type => :multiline_comment})

    elseif startswith(stream, "#")
      pushscope({:type => :comment})

    elseif cur_scope() == :multiline_comment
      if startswith(stream, "=#")
        pop!(scopes)
      else
        read(stream, Char)
      end

    # Strings
    elseif cur_scope() == :string || cur_scope() == :multiline_string
      if startswith(stream, "\\\"")
      elseif (cur_scope() == :string && startswith(stream, "\"")) ||
             (cur_scope() == :multiline_string && startswith(stream, "\"\"\""))
        pop!(scopes)
      else
        read(stream, Char)
      end

    elseif startswith(stream, "\"\"\"")
      pushscope({:type => :multiline_string})
    elseif startswith(stream, "\"")
      pushscope({:type => :string})

    # Brackets
    elseif startswith(stream, ["(", "[", "{"], eat = false)
      pushscope({:type => :array, :name => read(stream, Char)})

    elseif cur_scope(:array, :call) && startswith(stream, [")", "]", "}"])
      pop!(scopes)

    # Binary Operators
    elseif startswith(stream, operators_end) != ""
      pushscope({:type => :binary})

    elseif startswith(stream, "@", eat = false)
      token = startswith(stream, macro_start)
      token != "" && pushtoken(token)

    # Tokens
    elseif (token = startswith(stream, identifier_start)) != ""
      if token == "end"
        pop!(scopes)
        leaving_expr()
      elseif token == "module"
        skipwhitespace(stream, newlines = false)
        pushscope({:type => :module,
                   :name => startswith(stream, identifier_start)})
      elseif token == "using"
        pushscope({:type => :using})
      else
        keyword = false
        token in blockclosers && (pop!(scopes); keyword = true)
        token in blockopeners && (pushscope({:type => :block,
                                             :name => token});
                                  keyword = true)
        if !keyword
          pushtoken(token)
          while startswith(stream, ".")
            if (next = startswith(stream, identifier_start)) != ""
              token = "$token.$next"
            end
          end
          startswith(stream, "(") ?
            pushscope({:type => :call, :name => token}) :
            leaving_expr()
        end
      end
    else
      read(stream, Char)
    end
    if stop && (line(stream) > target[1] || (line(stream) == target[1] && column(stream) >= target[2]))
      return scopes
    end
  end
  return collect ? tokens : scopes
end
