export script_name        = "Line To FBF"
export script_description = "Splits the line frame by frame interpolating all transformations present in it"
export script_author      = "Zeref"
export script_version     = "1.1.2"
export script_namespace   = "zf.line2fbf"
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

interface = ->
    {
        {class: "label", label: "Frame Step:", x: 0, y: 0}
        {class: "intedit", name: "frs", min: 1, x: 0, y: 1, value: 1}  
    }

main = (subs, selected, active) ->
    button, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, close: "Cancel"
    if button == "Ok"
        dlg = zf.dialog subs, selected, active, true
        for l, line, sel, i, n in dlg\iterSelected!
            dlg\progressLine sel
            -- checks if the line is commented out
            if l.comment
                dlg\warning sel, "The line is commented out"
                continue
            -- checks if the line duration is more than 0 frame
            if (l.end_time - l.start_time) <= 0
                dlg\warning sel, "The line doesn't have enough time for 1 frame."
                continue
            -- calls the class FBF
            fbf = zf.fbf l
            -- extends the line information
            zf.line(line)\prepoc dlg
            tags, move, fade = fbf\setup line
            dlg\removeLine l, sel
            -- iteration with all frames
            for s, e in fbf\iter elements.frs
                break if aegisub.progress.is_cancelled!
                line.start_time = s
                line.end_time = e
                line.text = fbf\perform line, tags, move, fade
                dlg\insertLine line, sel
        return dlg\getSelection!

if haveDepCtrl
    depctrl\registerMacro main
else
    aegisub.register_macro script_name, script_description, main
