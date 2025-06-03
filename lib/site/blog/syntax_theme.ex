defmodule Site.Blog.SyntaxTheme do
  @moduledoc """
  Custom Autumn syntax theme.
  """

  def umbra_theme do
    %Autumn.Theme{
      name: "umbra_dark",
      appearance: "dark",
      highlights: %{
        "normal" => %Autumn.Theme.Style{
          fg: "#b0b0b0",
          bg: "#141414"
        },
        "variable" => %Autumn.Theme.Style{
          fg: "#ebebeb"
        }
      }
    }
  end
end

# {
#   "name": "aura_dark",
#   "appearance": "dark",
#   "highlights": {
#     "attribute": {
#       "fg": "#a277ff"
#     },
#     "attribute.builtin": {
#       "fg": "#a277ff"
#     },
#     "boolean": {
#       "fg": "#61ffca"
#     },
#     "character": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "character.special": {
#       "fg": "#a277ff"
#     },
#     "comment": {
#       "fg": "#6d6d6d",
#       "italic": true
#     },
#     "comment.documentation": {
#       "fg": "#6d6d6d",
#       "italic": true
#     },
#     "comment.error": {
#       "fg": "#ffc0b9"
#     },
#     "comment.note": {
#       "fg": "#8cf8f7"
#     },
#     "comment.todo": {
#       "fg": "#61ffca",
#       "bold": true,
#       "italic": true
#     },
#     "comment.warning": {
#       "fg": "#fce094"
#     },
#     "constant": {
#       "fg": "#a277ff"
#     },
#     "constant.builtin": {
#       "fg": "#a277ff"
#     },
#     "constant.macro": {
#       "fg": "#a277ff"
#     },
#     "constructor": {
#       "fg": "#a277ff"
#     },
#     "diff.delta": {
#       "fg": "#8cf8f7"
#     },
#     "diff.minus": {
#       "fg": "#ffc0b9"
#     },
#     "diff.plus": {
#       "fg": "#b3f6c0"
#     },
#     "function": {
#       "fg": "#ffca85"
#     },
#     "function.builtin": {
#       "fg": "#a277ff"
#     },
#     "function.call": {
#       "fg": "#ffca85"
#     },
#     "function.macro": {
#       "fg": "#ffca85"
#     },
#     "function.method": {
#       "fg": "#ffca85"
#     },
#     "function.method.call": {
#       "fg": "#ffca85"
#     },
#     "keyword": {
#       "fg": "#a277ff"
#     },
#     "keyword.conditional": {
#       "fg": "#a277ff"
#     },
#     "keyword.conditional.ternary": {
#       "fg": "#a277ff"
#     },
#     "keyword.coroutine": {
#       "fg": "#a277ff"
#     },
#     "keyword.debug": {
#       "fg": "#a277ff"
#     },
#     "keyword.directive": {
#       "fg": "#a277ff"
#     },
#     "keyword.directive.define": {
#       "fg": "#a277ff"
#     },
#     "keyword.exception": {
#       "fg": "#a277ff"
#     },
#     "keyword.function": {
#       "fg": "#a277ff"
#     },
#     "keyword.import": {
#       "fg": "#a277ff"
#     },
#     "keyword.modifier": {
#       "fg": "#a277ff"
#     },
#     "keyword.operator": {
#       "fg": "#a277ff"
#     },
#     "keyword.repeat": {
#       "fg": "#a277ff"
#     },
#     "keyword.return": {
#       "fg": "#a277ff"
#     },
#     "keyword.type": {
#       "fg": "#a277ff"
#     },
#     "label": {
#       "fg": "#a277ff"
#     },
#     "markup.heading": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.1": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.2": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.3": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.4": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.5": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.heading.6": {
#       "fg": "#61ffca",
#       "bold": true
#     },
#     "markup.italic": {
#       "italic": true
#     },
#     "markup.link": {
#       "underline": true
#     },
#     "markup.link.label": {
#       "underline": true
#     },
#     "markup.link.url": {
#       "underline": true
#     },
#     "markup.list": {
#       "fg": "#a277ff"
#     },
#     "markup.list.checked": {
#       "fg": "#a277ff"
#     },
#     "markup.list.unchecked": {
#       "fg": "#a277ff"
#     },
#     "markup.math": {
#       "fg": "#a277ff"
#     },
#     "markup.quote": {
#       "fg": "#a277ff"
#     },
#     "markup.raw": {
#       "fg": "#a277ff"
#     },
#     "markup.raw.block": {
#       "fg": "#a277ff"
#     },
#     "markup.strikethrough": {
#       "strikethrough": true
#     },
#     "markup.strong": {
#       "bold": true
#     },
#     "markup.underline": {
#       "underline": true
#     },
#     "module": {
#       "fg": "#a277ff"
#     },
#     "module.builtin": {
#       "fg": "#a277ff"
#     },
#     "normal": {
#       "fg": "#edecee",
#       "bg": "#15141b"
#     },
#     "number": {
#       "fg": "#61ffca"
#     },
#     "number.float": {
#       "fg": "#61ffca"
#     },
#     "operator": {
#       "fg": "#a277ff"
#     },
#     "property": {
#       "fg": "#a277ff"
#     },
#     "punctuation.bracket": {
#       "fg": "#f694ff",
#       "bold": true
#     },
#     "punctuation.delimiter": {
#       "fg": "#f694ff",
#       "bold": true
#     },
#     "punctuation.special": {
#       "fg": "#a277ff"
#     },
#     "string": {
#       "fg": "#61ffca"
#     },
#     "string.documentation": {
#       "fg": "#61ffca"
#     },
#     "string.escape": {
#       "fg": "#a277ff"
#     },
#     "string.regexp": {
#       "fg": "#a277ff"
#     },
#     "string.special": {
#       "fg": "#a277ff"
#     },
#     "string.special.path": {
#       "fg": "#a277ff"
#     },
#     "string.special.symbol": {
#       "fg": "#a277ff"
#     },
#     "string.special.url": {
#       "underline": true
#     },
#     "tag": {
#       "fg": "#edecee"
#     },
#     "tag.attribute": {
#       "fg": "#edecee"
#     },
#     "tag.builtin": {
#       "fg": "#a277ff"
#     },
#     "tag.delimiter": {
#       "fg": "#edecee"
#     },
#     "type": {
#       "fg": "#82e2ff"
#     },
#     "type.builtin": {
#       "fg": "#a277ff"
#     },
#     "type.definition": {
#       "fg": "#82e2ff"
#     },
#     "variable": {
#       "fg": "#e0e2ea"
#     },
#     "variable.builtin": {
#       "fg": "#a277ff"
#     },
#     "variable.member": {
#       "fg": "#e0e2ea"
#     },
#     "variable.parameter": {
#       "fg": "#e0e2ea"
#     },
#     "variable.parameter.builtin": {
#       "fg": "#a277ff"
#     }
#   }
# }
