export script_name        = "Splits Text By"
export script_description = "Splits the text in several ways"
export script_author      = "Zeref"
export script_version     = "1.2.2"
-- LIB
zf = require "ZF.main"

main = (__type) ->
    (subs, selected) ->
        new_selection, i = {}, {0, 0, selected[#selected], zf.util\getFirstLine subs}
        for sel in *selected
            dialogue_index = sel + i[1] - i[2] - i[4] + 1
            aegisub.progress.set 100 * sel / i[3]
            aegisub.progress.task "Processing line: #{dialogue_index}"
            -- gets the current line
            l, remove = subs[sel + i[1]], true
            -- skips execution if execution is not possible
            unless zf.util\runMacro l
                zf.util\warning "The line is commented out or it is an empty line with possible blanks.", dialogue_index
                remove = false
                continue
            -- skips execution if the text is a shape
            if zf.util\isShape l.text\gsub "%b{}", ""
                zf.util\warning "The line text is a shape.", dialogue_index
                remove = false
                continue
            -- copies the current line
            line = zf.table(l)\copy!
            line.comment = false
            -- calls the TEXT class to get the necessary values
            callText = zf.text subs, line
            {:coords} = callText
            zf.util\deleteLine l, subs, sel, remove, i
            for breaks in *callText\breaks2Lines!
                for tag in *breaks
                    switch __type
                        when "Chars", "Words"
                            values =  switch __type
                                when "Chars" then callText\chars tag
                                when "Words" then callText\words tag
                            for value in *values
                                __tags = zf.tags\replaceCoords tag.tags, callText\orgPos line, value, coords
                                __tags = zf.tags\clearStyleValues tag, __tags
                                line.text = "#{__tags}#{value.text_stripped}"
                                zf.util\insertLine line, subs, sel, new_selection, i
                        else
                            __tags = zf.tags\replaceCoords tag.tags, callText\orgPos line, tag, coords
                            __tags = zf.tags\clearStyleValues tag, __tags
                            line.text = "#{__tags}#{tag.text_stripped}"
                            zf.util\insertLine line, subs, sel, new_selection, i
            remove = true
        aegisub.set_undo_point script_name
        if #new_selection > 0
            return new_selection, new_selection[1]

aegisub.register_macro "#{script_name} / Chars",      script_description, main "Chars"
aegisub.register_macro "#{script_name} / Words",      script_description, main "Words"
aegisub.register_macro "#{script_name} / Tags",       script_description, main!