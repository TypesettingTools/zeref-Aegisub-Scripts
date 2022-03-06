export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "1.0.1"
-- LIB
zf = require "ZF.main"

shapeInClip = (shape, clip, line, mode = 1, offset = 0) ->
    clip = zf.shape clip, false
    add, len = {}, clip\length!

    animated = mode == "Animated - Start to End" or mode == "Animated - End to Start"
    loop = animated and line.duration / (zf.util\getFrameDur(0) * offset) or 1
    for i = 1, loop
        t = (i - 1) / (loop - 1)
        val = zf.shape shape
        siz = len - val.w
        if animated
            t = mode == "Animated - Start to End" and t or 1 - t
            val = val\inClip line.styleref.align, clip, nil, nil, t * siz
        elseif mode == "Around"
            val = val\inClip line.styleref.align, clip, mode, val.w
        else
            val = val\inClip line.styleref.align, clip, mode, nil, offset
        add[i] = val\build!

    return add

textInClip = (line, clip, values, mode = 1, offset = 0, diff = 0) ->
    clip = zf.shape clip, false
    add, len, left, width = {}, clip\length!, line.left, line.width

    size = len - width
    offx = switch mode
        when 1, "Left" then offset
        when 2, "Center" then size / 2 + offset
        when 3, "Right" then size - offset

    animated = mode == "Animated - Start to End" or mode == "Animated - End to Start"
    loop = animated and line.duration / (zf.util\getFrameDur(0) * offset) or 1
    for i = 1, loop
        add[i] = {}
        u = (i - 1) / (loop - 1)
        u = animated and (mode == "Animated - Start to End" and u or 1 - u) or nil
        for v, value in ipairs values
            u = mode == "Around" and (v - 1) / (values.n - 1) or u
            offx = u and u * size or offx
            t = (offx + value.x + diff - left) / len

            if 0 <= t and t <= 1
                tan, pnt = clip\getNormal t
                pnt\round 3

                {:x, :y} = pnt
                angle = deg atan2 -tan.y, tan.x
                angle = zf.math\round angle - 90
                add[i][v] = {:x, :y, :angle}
            else
                {:x, :y} = value
                add[i][v] = {:x, :y, angle: 0}

    return add

interface = ->
    items = {"Left", "Center", "Right", "Around", "Animated - Start to End", "Animated - End to Start"}
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

main = (subs, selected) ->
    gui = zf.config\loadGui interface!, script_name
    firstIndex = zf.util\getFirstLine subs

    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display gui, {"Ok", "Reset", "Cancel"}, close: "Cancel"
        gui = switch buttons
            when "Reset"  then interface!
            when "Cancel" then return
            else               break

    zf.config\saveGui elements, script_name
    n, i = selected[#selected], 0
    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{sel + i - firstIndex + 1}"
        l = subs[sel + i]

        rawTag = zf.tags\getTag l.text
        zf.tags\dependency rawTag, "clips"
        clip = zf.util\clip2Draw rawTag

        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""

        if isShape and not elements.ens 
            continue
        elseif not isShape
            unless zf.util\runMacro l
                continue
            shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape
            rawTag = zf.tags\clear l, rawTag, "text"
            rawTag = zf.tags\merge rawTag, "\\p1"

        l.comment = true
        subs[sel + i] = l

        line = zf.table(l)\copy!
        line.comment = false

        with elements
            i = zf.util\deleteLine subs, sel, i if .remove

            call = zf.text(subs, line, line.text)\tags!

            sumWidth = zf.table(call)\arithmeticOp ((val) -> val.width), "+"
            dffWidth = sumWidth - line.width
            line.width += dffWidth

            animated = .mds == "Animated - Start to End" or .mds == "Animated - End to Start"
            if animated
                .off = 1 if .off <= 0

            for t, tag in ipairs call
                rawTag = zf.tags\getTag tag.text
                rawTag = zf.tags\clear tag, rawTag, "Shape To Clip"

                values, chars = nil, not .ens and zf.text(subs, tag)\chars! or nil
                unless .ens
                    values = textInClip line, clip, chars, .mds, .off, ceil dffWidth / 2
                else
                    rawTag = zf.tags\clear line, rawTag, "Shape"
                    rawTag = zf.tags\clear line, rawTag, "Shape In Clip"
                    values = shapeInClip shape, clip, line, .mds, .off

                length, start, dur = #values, tag.start_time, tag.duration
                for j = 1, length
                    if animated
                        tag.start_time = start + dur * (j - 1) / length
                        tag.end_time = start + dur * j / length

                    unless .ens
                        for c, char in ipairs chars
                            cliped = values[j][c]
                            tags = zf.tags\replaceCoords rawTag, {cliped.x, cliped.y}
                            tags = zf.tags\merge tags, "\\frz#{cliped.angle}"

                            tag.text = tags .. char.text_stripped
                            i = zf.util\insertLine tag, subs, sel, i
                    else
                        tag.text = rawTag .. values[j]
                        i = zf.util\insertLine tag, subs, sel, i

aegisub.register_macro script_name, script_description, main