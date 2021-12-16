export script_name        = "Splits Text By"
export script_description = "Splits the text in several ways"
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

main = (__type) ->
    (subs, selected) ->
        n, i, pos, org = selected[#selected], 0, nil, nil
        for s, sel in ipairs selected
            l = subs[sel + i]

            coords = zf.util\setPreprocLine subs, l

            continue if not zf.util\runMacro(l) or zf.util\isShape coords, l.text\gsub "%b{}", ""

            l.comment = true

            subs[sel + i] = l

            subs.delete sel + i
            i -= 1

            line = zf.table(l)\copy!
            line.comment = false

            call = zf.text subs, line, line.text
            for t, tag in ipairs __type != "Break" and call\tags! or call\breaks!
                switch __type
                    when "Chars", "Words"
                        value = switch __type
                            when "Chars" then zf.text(subs, tag)\chars!
                            when "Words" then zf.text(subs, tag)\words!

                        for _, index in ipairs value
                            pos, org = zf.text\orgPos coords, index, line

                            tag.tags = zf.tags\replaceT tag.tags, "pos", pos
                            tag.tags = zf.tags\replaceT tag.tags, "org", org

                            line.text = "{#{tag.tags}}#{index.text_stripped}"

                            subs.insert sel + i + 1, line
                            i += 1
                    else
                        pos, org = zf.text\orgPos coords, tag, line

                        tag.tags = zf.tags\replaceT tag.tags, "pos", pos
                        tag.tags = zf.tags\replaceT tag.tags, "org", org

                        line.text = "{#{tag.tags}}#{tag.text_stripped_non_tags}"

                        subs.insert sel + i + 1, line
                        i += 1

        aegisub.set_undo_point script_name

aegisub.register_macro "#{script_name}/Chars",      script_description, main "Chars"
aegisub.register_macro "#{script_name}/Words",      script_description, main "Words"
aegisub.register_macro "#{script_name}/Tags",       script_description, main "Tags"
aegisub.register_macro "#{script_name}/Line Break", script_description, main "Break"