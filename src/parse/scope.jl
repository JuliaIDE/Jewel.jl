# A pseudo-parser which extracts information from Julia code

# stream utils

include("LineNumberingReader.jl")

import Base: peek

const whitespace = " \t"

function skip_whitespace(io::IO; newlines = true)
  while !eof(io) && (peek(io) in whitespace || (newlines && peek(io) == '\n'))
    read(io, Char)
  end
  return io
end

function starts_with(stream::IO, s::String; eat = true, padding = false)
  start = position(stream)
  padding && skip_whitespace(stream)
  result = true
  for char in s
    !eof(stream) && read(stream, Char) == char ||
      (result = false; break)
  end
  !(result && eat) && seek(stream, start)
  return result
end

function starts_with{T<:String}(stream::IO, ss::Vector{T}; eat = true)
  for s in ss
    starts_with(stream, s, eat = eat) && return true
  end
  return false
end

function starts_with(stream::IO, r::Regex; eat = true, padding = false)
  @assert beginswith(r.pattern, "^")
  start = position(stream)
  padding && skip_whitespace(stream)
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

  cur_scope() = scopes[end][:type]
  cur_scope(ts...) = cur_scope() in ts
  leaving_expr() = cur_scope() == :binary && pop!(scopes)
  pushtoken(t) = collect && push!(tokens, t)
  function pushscope(scope)
    if !(stop && line(stream) > target[1] || (line(stream) == target[1] && column(stream) > target[2]))
      push!(scopes, scope)
    end
  end

  while !eof(stream)
    # Comments
    if starts_with(stream, "\n")
      cur_scope() in (:comment, :using) && pop!(scopes)

    elseif starts_with(stream, "#=")
      pushscope({:type => :multiline_comment})

    elseif starts_with(stream, "#")
      readline(stream)
      skip(stream, -1)
      pushscope({:type => :comment})

    elseif cur_scope() == :multiline_comment
      if starts_with(stream, "=#")
        pop!(scopes)
      else
        read(stream, Char)
      end

    # Strings
    elseif cur_scope() == :string || cur_scope() == :multiline_string
      if starts_with(stream, "\\\"")
      elseif (cur_scope() == :string && starts_with(stream, "\"")) ||
             (cur_scope() == :multiline_string && starts_with(stream, "\"\"\""))
        pop!(scopes)
      else
        read(stream, Char)
      end

    elseif starts_with(stream, "\"\"\"")
      pushscope({:type => :multiline_string})
    elseif starts_with(stream, "\"")
      pushscope({:type => :string})

    # Brackets
    elseif starts_with(stream, ["(", "[", "{"], eat = false)
      pushscope({:type => :array, :name => read(stream, Char)})

    elseif cur_scope(:array, :call) && starts_with(stream, [")", "]", "}"])
      pop!(scopes)

    # Binary Operators
    elseif starts_with(stream, operators_end) != ""
      pushscope({:type => :binary})

    elseif starts_with(stream, "@", eat = false)
      token = starts_with(stream, macro_start)
      token != "" && pushtoken(token)

    # Tokens
    elseif (token = starts_with(stream, identifier_start)) != ""
      if token == "end"
        pop!(scopes)
        leaving_expr()
      elseif token == "module"
        skip_whitespace(stream, newlines = false)
        pushscope({:type => :module,
                   :name => starts_with(stream, identifier_start)})
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
          while starts_with(stream, ".")
            if (next = starts_with(stream, identifier_start)) != ""
              token *= ".$next"
            end
          end
          starts_with(stream, "(") ?
            pushscope({:type => :call, :name => token}) :
            leaving_expr()
        end
      end
    else
      read(stream, Char)
    end
    if stop && line(stream) > target[1] || (line(stream) == target[1] && column(stream) >= target[2])
      return scopes
    end
  end
  return collect ? tokens : scopes
end
