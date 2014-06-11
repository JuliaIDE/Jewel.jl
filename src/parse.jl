#jewel module Jewel

# -------------
# Code handling
# -------------

# All this is a somewhat temporary solution,
# it can be much improved once CodeMirror's
# julia mode is fixed

cursor_start(data) = data["start"]["line"], data["start"]["col"]
cursor_end(data) = data["end"]["line"], data["end"]["col"]
cursor(data) = cursor_start(data)

function index_of(s, line, char)
  lines = 1
  chars = 0
  for i = 1:endof(s)
    isvalid(s, i) || continue
    lines == line && char == chars+1 && return i
    if s[i] == '\n'
      lines += 1
      chars =  0
      i == length(s) && return i-1
    else
      chars += 1
    end
  end
  error("Position $line:$char not found in string.")
end

isblank(s) = ismatch(r"^\s*(#.*)?$", s)
isend(s) = ismatch(r"^end", s)
isstart(s) = !(ismatch(r"^\s", s) || isblank(s) || isend(s))

# Find to the start of this block.
function walk_back(code::Vector, line)
  while line > 1 && !isstart(code[line])
    line -= 1
  end
  return line
end

# Scan to the start of the next block, find the end of
# this one.
function walk_forward(code::Vector, line)
  l = line
  while l < length(code) && (!isstart(code[l]) || l == line)
    l += 1
    !(isblank(code[l]) || isstart(code[l])) && (line = l)
  end
  return line
end

function get_module_name(code::Vector, line)
  while line > 1
    line -= 1
    m = match(r"^(?:#jewel )?module (\w+)", code[line])
    m == nothing || return m.captures[1]
  end
  return nothing
end

get_module_name(code::String, line) =
  get_module_name(lines(code), line)

get_module_name(data::Dict) =
  get_module_name(data["code"], data["cursor"]["line"])

function file_module(code::String)
  m = match(r"^\s*#jewel module (\w+)", code)
  m == nothing ? nothing : symbol(m.captures[1])
end

function get_code(s, start, stop)
  i, j = index_of(s, start[1], start[2]), index_of(s, stop[1], stop[2]-1) # Selection is in front of cursor
  {:code   => s[i:j],
   :lines  => (start[1], stop[1]),
   :module => get_module_name(lines(s), start[1])}
end

function get_code(s, line)
  c = lines(s)
  i, j = walk_back(c, line), walk_forward(c, line)
  {:code   => join(c[i:j], "\n"),
   :lines  => (i, j),
   :module => get_module_name(c, i)}
end

function get_code(s::String)
  {:code   => s,
   :lines  => (1, length(lines(s))),
   :module => file_module(s)}
end

get_code(data::Dict) =
  get(data, "all", false) ? get_code(data["code"]) :
  cursor_start(data) == cursor_end(data) ?
    get_code(data["code"], cursor(data)[1]) :
    get_code(data["code"], cursor_start(data), cursor_end(data))

# Token parsing

const identifier_inner = "[^,⊶⩃↣⩄≗≦⥥∓≨⊘×≥≫⥘⪚⋼⭂⥩⩾⥓∝⤞⇼⥍⭈∽⩁⥎⟑⟉∊∷≳≠⩧⫏⇿⬵≬⩗⥭⦾⥖→∪⫑⪀⩠⥢⤌⋝⊕⪪≈⪏≤⨤⪿⟰≼⫂≹⪣⋴≧∸≐⭋∨⨳⭁∺⋥⟽⊷⟱≡\\]⤅⪃⩋⩊⋣⋎⥗⨮⬻⪻≢∙⪕⩓⫺∧⧻⨭⊵≓⥬⥛⋿⭃⫒⫕⩡⬺⧷⥄⊱⨰⊇≊⨬≖>⤕⬴⟿⋘⪇≯⋕⤏⟶⥚⥜⨼∥⪠⥝⬷∘⊴⪈⤔⪍⫄?⊰⪌⋩≟⋜⫀\\)⫎⩦⋏⫷⊋⪱⤀⩯⤘⫌⩱≜↓⋗↑≛⋌⪢⫖⋖⩰⊏⊗⪡⋆⟈⤂⥆⧁⊻⤋⤖⩹↦⪳⩸⥅∔⨺⋐≶⟵\\}⪙⪧⇺%≭≕⥔⥐⊆⋸⅋⋒≃≝≿⇴⩌⋠⇽≰/⫙⊠⪼⇔\\[⟾+≩⊟⨶⥰⪉≎≷⩣⭄&⨲⧣⩭≑⊐⫗⩬⩢⬽⪯⪓⪒≪∈⪘⬿⫸⇹⊅⨥⨩≚⋹⊃⊂⪞⋺⨹⋦∦≮⋧⋛⋾⊁≉￪≔±\\{⩒⩑⋫￩⥤⨽⬲⪄⫓⪑∩⧡⩮⪟⪛⋽⪦⇒≁⪝⬳⩝⩳≴⪰⟻≣⦼⩷⇶⋳⪺⪜⩕⥦∛≽⋑⤓⟼⩏≲⊲≸⟺⇷⟹∌⩪⊞⫉⨴⪤⪸⥡⩔⭊⪆⩲⫈⥒⫋⬶⫁⪵∗⫊⩖≙⩐≍⨫⦸⋚⊄⫐⥇⥣⪲↔⪷⨈⧺⭌⨨≄⤟^≵⋭⋊⟷⩅∤⫆⊽\\(⬸⤒⪾⩞⥫⥙⋙⨱⬹<⊎⤊⤁⇏≺⋵⥏⩴⋶⪂⥕⪨⋇⊊⫅⊖⪶⋬≻⋍⋓⩍≱⇻⩵↮⋋⪖⨢↠⤎⊈⊮⋪⊓⪔\\\⨧⩜⥞⫇⪫⬾⋷⤃⧥⫃⨷⥈⤄⩼⋤⥠⬼⤠⩛≂↚⥧|∍⨻⊙⨪∋⪋⋲⤍.\\'⊑⩟⇎*:￬⭉⤉⥯⬱⇾⋡÷⥟⥋∉⬰≞≾⫍⨵⩚⩫≅⩿⪎⪴⊒⪽≀⫹⤇⋅⩀⊡⤆∜⤈⨣↛⊩⫔⦷⩺≋\\-≇⋨⊜~⫛≌⥉√⋢⊛⤗⋟⧶≏⊔⪗⋞ ⩎⊳∾⥨￫⩘⥌⪹⪩⩻=⨸⪊⨇⧤⇸⊉⥑⥮⭀⧀⊚⊬≒\\\$⊀⋻⦿⭇⥊≆←⤐≘⋉⊼⥪⧴⪅⩽⪬⪁⋄⤑⨦⩶⇵⪥⊍⫘⩂⪐⟒⪭⪮⤝∻\\\"]*"
const identifier = "[^!0-9 \\.]" * identifier

function match_or_empty(args...)
  result = match(args...)
  result == nothing ? "" : result.match
end

function get_qualified_name(str::String, index)
  pre = str[1:(index <= endof(str) ? index : end)]
  post = index > endof(str) ? "" : str[index+1:end]

  pre = match_or_empty(Regex("(?:$identifier\\.)*(?:$identifier)\\.?\$"), pre)

  beginning = pre == "" || last(pre) == '.'
  post = match_or_empty(Regex("^$(beginning ? identifier : identifier_inner)"), post)

  if beginning && post == ""
    return pre[1:end]
  else
    return pre * post
  end
end
