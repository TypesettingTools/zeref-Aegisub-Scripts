export script_name        = "Splits Text By"
export script_description = "Splits the text in several ways"
export script_author      = "Zeref"
export script_version     = "1.0.1"
-- LIB
zf = require "ZF.main"

main = (__type) ->
    (subs, selected) ->
        n, i, pos, org = selected[#selected], 0, nil, nil
        for s, sel in ipairs selected
            l = subs[sel + i]

            coords = zf.util\setPreprocLine subs, l
            isShape = zf.util\isShape coords, l.text\gsub "%b{}", ""
            assert not isShape, "expected text, received a shape"

            unless zf.util\runMacro l
                continue 

            l.comment = true
            subs[sel + i] = l

            line = zf.table(l)\copy!
            line.comment = false

            i = zf.util\deleteLine subs, sel, i

            call = zf.text subs, line, line.text
            for t, tag in ipairs __type != "Break" and call\tags! or call\breaks!
                switch __type
                    when "Chars", "Words"
                        value = switch __type
                            when "Chars" then zf.text(subs, tag)\chars!
                            when "Words" then zf.text(subs, tag)\words!
                        for _, index in ipairs value
                            conc = zf.tags\replaceCoords tag.tags, call\orgPos coords, index, line
                            line.text = "#{conc}#{index.text_stripped}"
                            i = zf.util\insertLine line, subs, sel, i
                    else
                        conc = zf.tags\replaceCoords tag.tags, call\orgPos coords, tag, line
                        line.text = "#{conc}#{tag.text_stripped_non_tags}"
                        i = zf.util\insertLine line, subs, sel, i

        aegisub.set_undo_point script_name

aegisub.register_macro "#{script_name}/Chars",      script_description, main "Chars"
aegisub.register_macro "#{script_name}/Words",      script_description, main "Words"
aegisub.register_macro "#{script_name}/Tags",       script_description, main "Tags"
aegisub.register_macro "#{script_name}/Line Break", script_description, main "Break"