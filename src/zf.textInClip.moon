export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "2.1.0"
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

getTextInClip = (t, shape, tag, char) ->
    angle, {:x, :y} = 0, char
    if 0 <= t and t <= 1
        tan, pnt = shape\getNormal t
        pnt\round 3
        angle = zf.math\round deg(atan2(-tan.y, tan.x)) - 90
        {:x, :y} = pnt
    __tags = zf.layer(tag.tags)\replaceCoords {x, y}
    __tags\remove "frz", "clip", "iclip"
    __tags\insert "\\frz#{angle}"
    return __tags\__tostring! .. char.text_stripped

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
    gui = zf.config\loadGui interface!, script_name
    while true
        button, elements = aegisub.dialog.display gui, {"Ok", "Reset", "Cancel"}, close: "Cancel"
        gui = switch button
            when "Reset"  then interface!
            when "Cancel" then return
            else               break
    zf.config\saveGui elements, script_name
    dlg = zf.dialog subs, selected, active, elements.remove
    for l, line, sel, i, n in dlg\iterSelected!
        dlg\progressLine sel
        -- checks if the line is commented out
        if l.comment
            dlg\warning sel, "The line is commented out"
            continue
        -- gets the first tag and the text stripped
        shape, clip = zf.util\isShape line.text
        rawTag = zf.layer line.text, false
        -- checks if the \clip tag exists
        if clip = rawTag\__match "\\i?clip%b()"
            clip = zf.util\clip2Draw clip
        else
            dlg\warning sel, "The line does not have the \"\\clip\" or \"\\iclip\" tag, they are necessary for the macro to work."
            continue
        -- initial text setup
        line.text = line.text\gsub("\\N", " ")\gsub "\\move%b()", ""
        line.text = zf.tags(line.text)\insertPending(false)\clear!
        line.text = line.text\__tostring!
        -- extends the line information
        call = zf.line(line)\prepoc dlg
        pers = dlg\getPerspectiveTags line
        {px, py} = pers["pos"]
        if shape and not elements.ens
            dlg\warning sel, "The line has a shape, you must activate the \"Enable Shape?\" checkbox to enable the use of shapes."
            continue
        elseif not shape and elements.ens
            if elements.list1 != "Clip To Shape"
                shape = call\toShape dlg, nil, px, py
            -- removes unnecessary tags
            rawTag\remove "fs", "fscx", "fscy", "fsp", "fn", "b", "i", "u", "s"
            rawTag\insert "\\fscx100\\fscy100\\p1"

        with elements
            unless .ens
                tags = call\tags2Lines dlg
                left = line.left - (tags.width - line.width) / 2
                {:shap, :slen, :size, :offx, :animated, :offset} = setConfig clip, tags.width, .off, .mds
                dlg\removeLine l, sel
                for tag in *tags
                    chars = zf.line(tag)\chars!
                    charn = chars.n
                    for ci, char in ipairs chars
                        cx = char.x
                        if animated
                            fbf = zf.fbf line
                            for s, e, d, j, n in fbf\iter offset
                                break if aegisub.progress.is_cancelled!
                                u = (j - 1) / (n - 1)
                                u = .mds == "Animated - Right to Left" and 1 - u or u
                                t = (u * size + cx - left) / slen
                                tag.start_time = s
                                tag.end_time = e
                                tag.text = getTextInClip t, shap, tag, char
                                dlg\insertLine tag, sel
                            continue
                        elseif .mds == "Around"
                            u = (ci - 1) / (charn - 1)
                            t = (u * size + cx - left) / slen
                            tag.text = getTextInClip t, shap, tag, char
                        else
                            t = (offx + cx - left) / slen
                            tag.text = getTextInClip t, shap, tag, char
                        dlg\insertLine tag, sel
            else
                rawTag\remove "an", "pos", "clip", "iclip"
                rawTag\insert {"\\an7\\pos(0,0)", true}
                rawTag = rawTag\__tostring!
                shaper = zf.shape shape
                {:shap, :slen, :size, :offx, :animated, :offset} = setConfig clip, shaper.w, .off, .mds
                dlg\removeLine l, sel
                if animated
                    fbf = zf.fbf line
                    for s, e, d, j, n in fbf\iter offset
                        break if aegisub.progress.is_cancelled!
                        u = (j - 1) / (n - 1)
                        u = .mds == "Animated - Right to Left" and 1 - u or u
                        line.start_time = s
                        line.end_time = e
                        line.text = rawTag .. zf.shape(shape)\inClip(line.styleref.align, shap, nil, nil, u * size)\build!
                        dlg\insertLine line, sel
                    continue
                elseif .mds == "Around"
                    line.text = rawTag .. shaper\inClip(line.styleref.align, shap, .mds, shaper.w)\build!
                else
                    line.text = rawTag .. shaper\inClip(line.styleref.align, shap, .mds, nil, offset)\build!
                dlg\insertLine line, sel
    return dlg\getSelection!

aegisub.register_macro script_name, script_description, main