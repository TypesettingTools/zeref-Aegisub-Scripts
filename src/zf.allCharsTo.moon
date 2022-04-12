export script_name        = "All Characters To"
export script_description = "Converts all characters to uppercase, lowercase or capitalized."
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

unicode.to_capitalized = (text) ->
    concat, done = "", false
    for char, ci in unicode.chars text
        a = tonumber char
        b = zf.util\isBlank char
        if not done and not a and not b
            done, char = true, unicode.to_upper_case char
        elseif char == "."
            done = false
        concat ..= char
    return concat

splitMap = (text, fn) ->
    concat, split = "", zf.util\splitText text\gsub("\\n", "|\\n|")\gsub "\\h", "|\\h|"
    for i = 1, #split.text
        text = split.text[i]
        tags = split.tags[i]
        concat ..= tags .. fn text
    return concat\gsub("|\\[nN]|", "\\n")\gsub "\\[hH]", "\\h"

main = (fn) ->
    (subs, selected) ->
        for s, sel in ipairs selected
            l = subs[sel]
            l.text = splitMap l.text, fn
            subs[sel] = l
        aegisub.set_undo_point script_name

aegisub.register_macro "#{script_name}/Upper-case",  script_description, main unicode.to_upper_case
aegisub.register_macro "#{script_name}/Lower-case",  script_description, main unicode.to_lower_case
aegisub.register_macro "#{script_name}/Capitalized", script_description, main unicode.to_capitalized