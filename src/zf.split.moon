export script_name        = "Splits Text By"
export script_description = "Splits the text in several ways"
export script_author      = "Zeref"
export script_version     = "1.3.0"
-- LIB
zf = require "ZF.main"

main = (__type) ->
    (subs, selected, active) ->
        dlg = zf.dialog subs, selected, active, true
        for l, line, sel, i, n in dlg\iterSelected!
            dlg\progressLine sel
            -- checks if the line is commented out
            if l.comment
                dlg\warning sel, "The line is commented out"
                continue
            -- checks if the text is a shape
            if zf.util\isShape l.text
                dlg\warning sel, "The line text is a shape."
                continue
            -- extends the line information
            call = zf.line(line)\prepoc dlg
            pers = dlg\getPerspectiveTags line
            dlg\removeLine l, sel
            for tags in *call\breaks2Lines dlg
                for tag in *tags
                    if __type == "Chars" or __type == "Words"
                        for value in *switch __type
                            when "Chars" then zf.line(tag)\chars!
                            when "Words" then zf.line(tag)\words!
                            final = zf.layer(tag.tags)\replaceCoords call\reallocate value, pers
                            line.text = "#{final.layer}#{value.text_stripped}"
                            dlg\insertLine line, sel
                    else
                        final = zf.layer(tag.tags)\replaceCoords call\reallocate tag, pers
                        line.text = "#{final.layer}#{tag.text_stripped}"
                        dlg\insertLine line, sel
        return dlg\getSelection!

aegisub.register_macro "#{script_name} / Chars", script_description, main "Chars"
aegisub.register_macro "#{script_name} / Words", script_description, main "Words"
aegisub.register_macro "#{script_name} / Tags",  script_description, main!