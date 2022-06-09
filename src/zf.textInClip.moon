export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "2.0.0"
-- LIB
zf = require "ZF.main"

setConfig = (shape, width, offset = 0, mode = 1) ->
    shap = zf.shape shape, false
    slen = shap\length!
    size = slen - width
    offx = switch mode
        when 1, "Left" then offset
        when 2, "Center" then size / 2 + offset
        when 3, "Right" then size - offset
    animated = mode == "Animated - Left to Right" or mode == "Animated - Right to Left"
    offset = (animated and offset <= 0) and 1 or offset
    return {:shap, :slen, :size, :offx, :animated, :offset}

getTextInClipValues = (t, shape, tag, char) ->
    angle, {:x, :y} = 0, char
    if 0 <= t and t <= 1
        tan, pnt = shape\getNormal t
        angle = zf.math\round deg(atan2(-tan.y, tan.x)) - 90
        pnt\round 3
        {:x, :y} = pnt
    __tags = zf.tags\replaceCoords tag.tags, {x, y}
    __tags = zf.tags\insertTags __tags, "\\frz#{angle}"
    __tags = zf.tags\removeTags __tags, "clip", "iclip"
    return __tags .. char.text_stripped

interface = ->
    items = {"Left", "Center", "Right", "Around", "Animated - Left to Right", "Animated - Right to Left"}
    hints = {
        items: "Position of the text relative to the text",
        offset: "The offset value of the position of the text \nrelative to the clip. \nIn case of animations, the value is a natural \nnumber that equals the frame step."
    }
    {
        {class: "label", label: "Modes:", x: 0, y: 0}
        {class: "dropdown", name: "mds", :items, hint: hints.items, x: 0, y: 1, value: items[1]}
        {class: "checkbox", name: "ens", label: "Enable shape?", x: 0, y: 2, value: false}
        {class: "label", label: "\nOffset:", x: 0, y: 3}
        {class: "intedit", name: "off", hint: hints.offset, x: 0, y: 4, value: 0}
        {class: "checkbox", name: "remove", label: "Remove selected layers?", x: 0, y: 5, value: true}
    }

main = (subs, selected, active, button, elements) ->
    new_selection, i = {}, {0, 0, selected[#selected], zf.util\getFirstLine subs}
    gui = zf.config\loadGui interface!, script_name
    while true
        button, elements = aegisub.dialog.display gui, {"Ok", "Reset", "Cancel"}, close: "Cancel"
        gui = switch button
            when "Reset"  then interface!
            when "Cancel" then return
            else               break
    zf.config\saveGui elements, script_name
    for sel in *selected
        dialogue_index = sel + i[1] - i[2] - i[4] + 1
        aegisub.progress.set 100 * sel / i[3]
        aegisub.progress.task "Processing line: #{dialogue_index}"
        -- gets the current line
        l, remove = subs[sel + i[1]], elements.remove
        -- skips execution if execution is not possible
        unless zf.util\runMacro l
            zf.util\warning "The line is commented out or it is an empty line with possible blanks.", dialogue_index
            remove = false
            continue
        -- gets the first tag and the text stripped
        rawTag, rawTxt = zf.tags\getRawText l.text
        -- checks if the \clip tag exists
        unless zf.tags\getTagInTags(rawTag, "clip") or zf.tags\getTagInTags(rawTag, "iclip")
            zf.util\warning "The line does not have the \"\\clip\" or \"\\iclip\" tag, they are necessary for the macro to work.", dialogue_index
            remove = false
            continue
        clip = zf.util\clip2Draw rawTag
        -- copies the current line
        line = zf.table(l)\copy!
        line.text = line.text\gsub("\\N", " ")\gsub "\\move%b()", ""
        line.comment = false
        -- calls the TEXT class to get the necessary values
        callText = zf.text subs, line
        {:coords} = callText
        {px, py} = coords.pos
        shape = zf.util\isShape rawTxt
        if shape and not elements.ens
            zf.util\warning "The line has a shape, you must activate the \"Enable Shape?\" checkbox to enable the use of shapes.", dialogue_index
            remove = false
            continue
        elseif not shape and elements.ens
            shape = callText\toShape nil, px, py
            rawTag = zf.tags\clear rawTag, "To Text"
            rawTag = zf.tags\insertTag rawTag, "\\p1"
        with elements
            fbf = zf.fbf line
            -- if it's text
            unless .ens
                tags = callText\tags2Lines!
                left = line.left - (tags.width - line.width) / 2
                {:shap, :slen, :size, :offx, :animated, :offset} = setConfig clip, tags.width, .off, .mds
                i[1], i[2] = zf.util\deleteLine l, subs, sel, remove, i[1], i[2]
                for ti, tag in ipairs tags
                    chars = callText\chars tag
                    charn = chars.n
                    for ci, char in ipairs chars
                        cx = char.x
                        if animated
                            for s, e, d, j, n in fbf\iter offset
                                break if aegisub.progress.is_cancelled!
                                u = (j - 1) / (n - 1)
                                u = .mds == "Animated - Right to Left" and 1 - u or u
                                t = (u * size + cx - left) / slen
                                tag.start_time = s
                                tag.end_time = e
                                tag.text = getTextInClipValues t, shap, tag, char
                                i[1], i[2] = zf.util\insertLine tag, subs, sel, new_selection, i[1], i[2]
                            continue
                        elseif .mds == "Around"
                            u = (ci - 1) / (charn - 1)
                            t = (u * size + cx - left) / slen
                            tag.text = getTextInClipValues t, shap, tag, char
                        else
                            t = (offx + cx - left) / slen
                            tag.text = getTextInClipValues t, shap, tag, char
                        i[1], i[2] = zf.util\insertLine tag, subs, sel, new_selection, i[1], i[2]
            else
                rawTag = zf.tags\removeTags rawTag, "clip", "iclip"
                rawTag = zf.tags\insertTags rawTag, "\\an7", "\\pos(0,0)"
                shaper = zf.shape shape
                {:shap, :slen, :size, :offx, :animated, :offset} = setConfig clip, shaper.w, .off, .mds
                i[1], i[2] = zf.util\deleteLine l, subs, sel, remove, i[1], i[2]
                if animated
                    for s, e, d, j, n in fbf\iter offset
                        break if aegisub.progress.is_cancelled!
                        u = (j - 1) / (n - 1)
                        u = .mds == "Animated - Right to Left" and 1 - u or u
                        line.start_time = s
                        line.end_time = e
                        line.text = rawTag .. zf.shape(shape)\inClip(line.styleref.align, shap, nil, nil, u * size)\build!
                        i[1], i[2] = zf.util\insertLine line, subs, sel, new_selection, i[1], i[2]
                    continue
                elseif .mds == "Around"
                    line.text = rawTag .. shaper\inClip(line.styleref.align, shap, .mds, shaper.w)\build!
                else
                    line.text = rawTag .. shaper\inClip(line.styleref.align, shap, .mds, nil, offset)\build!
                i[1], i[2] = zf.util\insertLine line, subs, sel, new_selection, i[1], i[2]
        remove = elements.remove
    aegisub.set_undo_point script_name
    if #new_selection > 0
        return new_selection, new_selection[1]

aegisub.register_macro script_name, script_description, main