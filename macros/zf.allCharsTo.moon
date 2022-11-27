export script_name        = "All Characters To"
export script_description = "Converts all characters to uppercase, lowercase or capitalized."
export script_author      = "Zeref"
export script_version     = "1.0.5"
export script_namespace   = "zf.allCharsTo"
-- LIB
haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"
local zf, depctrl
if haveDepCtrl
    depctrl = DependencyControl {
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"
        {
            "ZF.main"
        }
    }
    zf = depctrl\requireModules!

else
    zf = require "ZF.main"

unicode.to_capitalized = (text, i = 1) ->
    concat, done = "", false
    for char, ci in unicode.chars text
        a = tonumber char
        b = zf.util\isBlank char
        if not done and not a and not b
            done = true
            unless ci == 1 and i > 1
                char = unicode.to_upper_case char
        elseif char == "."
            done = false
        concat ..= char
    return concat

splitMap = (text, fn) ->
    concat = ""
    with zf.tags text\gsub("\\N", "%[@%]")\gsub("\\h", "%[#%]"), false
        for i = 1, #.between
            sucess, result = pcall fn, .between[i], i
            concat ..= .layers[i]["layer"] .. (sucess and result or fn .between[i])
    return concat\gsub("%[@%]", "\\N")\gsub("%[#%]", "\\h")\gsub "{%s*}", ""

main = (fn) ->
    (subs, selected) ->
        for sel in *selected
            l = subs[sel]
            unless zf.util\isShape l.text\gsub "%b{}", ""
                l.text = splitMap l.text, fn
            subs[sel] = l
        aegisub.set_undo_point script_name

if haveDepCtrl
    depctrl\registerMacros {
        {"Upper-case", script_description, main unicode.to_upper_case}
        {"Lower-case", script_description, main unicode.to_lower_case}
        {"Capitalized", script_description, main unicode.to_capitalized}
    }
else
    aegisub.register_macro "#{script_name} / Upper-case",  script_description, main unicode.to_upper_case
    aegisub.register_macro "#{script_name} / Lower-case",  script_description, main unicode.to_lower_case
    aegisub.register_macro "#{script_name} / Capitalized", script_description, main unicode.to_capitalized
