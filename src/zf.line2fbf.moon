export script_name        = "Line To FBF"
export script_description = "Splits the line frame by frame interpolating all transformations present in it"
export script_author      = "Zeref"
export script_version     = "1.0.2"
-- LIB
zf = require "ZF.main"

interface = ->
    {
        {class: "label", label: "Frame step:", x: 0, y: 0}
        {class: "intedit", name: "frs", min: 1, x: 0, y: 1, value: 1}  
    }

main = (subs, selected) ->
    button, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, close: "Cancel"
    if button == "Ok"
        new_selection, i = {}, {0, 0, selected[#selected], zf.util\getFirstLine subs}
        for sel in *selected
            dialogue_index = sel + i[1] - i[2] - i[4] + 1
            aegisub.progress.set 100 * sel / i[3]
            aegisub.progress.task "Processing line: #{dialogue_index}"
            -- gets the current line
            l, remove = subs[sel + i[1]], true
            -- skips execution if execution is not possible
            if l.comment
                zf.util\warning "The line is commented out", dialogue_index
                remove = false
                continue
            -- copies the current line
            line = zf.table(l)\copy!
            line.comment = false
            -- calls TEXT class to get the necessary values
            callText = zf.text subs, line
            -- calls FBF class 
            fbf = zf.fbf line
            if fbf.dframe <= 0
                zf.util\warning "The line doesn't have enough time for 1 frame.", dialogue_index
                remove = false
                continue
            -- gets the first tag and the text stripped
            rawTag, rawTxt = zf.tags\getRawText line.text
            text, shape = "", zf.util\isShape rawTxt
            -- adds the style values to all tag layers
            split = zf.tags\splitTextByTags zf.tags\fixtr(shape and rawTag or l.text), true
            for i = 1, #split.tags
                split.tags[i] = zf.tags\addStyleTags line, split.tags[i], nil
            text, shape = split.__tostring!, shape or ""
            zf.util\deleteLine l, subs, sel, remove, i
            for s, e in fbf\iter elements.frs
                break if aegisub.progress.is_cancelled!
                line.start_time = s
                line.end_time = e
                line.text = fbf\perform(text) .. shape
                zf.util\insertLine line, subs, sel, new_selection, i
            remove = true
        aegisub.set_undo_point script_name
        if #new_selection > 0
            return new_selection, new_selection[1]

aegisub.register_macro script_name, script_description, main