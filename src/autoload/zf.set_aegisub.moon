export script_name        = "ZF - Set Aegisub Version"
export script_description = "Set Aegisub version to provide specific interfaces. [This is only valid with macros by Zeref.]"
export script_author      = "Zeref"
export script_version     = "0.0.0"
-- LIB
zf = require "ZF.main"

main = ->
    inter = zf.config\load(zf.config\interface(script_name)!, script_name)
    buttons, elements = aegisub.dialog.display(inter, {"Ok", "Cancel"}, {close: "Cancel"})
    zf.config\save(inter, elements, script_name, script_version) if buttons == "Ok"

aegisub.register_macro script_name, script_description, main