export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "1.0.2"
-- LIB
zf = require "ZF.main"

class IN_CLIP

    new: (line, shape, offset = 0, @mode = 1) =>
        @shape = zf.shape shape, false
        @len, @left, width = @shape\length!, line.left, line.width
        @size = @len - width
        @offx = switch @mode
            when 1, "Left" then offset
            when 2, "Center" then @size / 2 + offset
            when 3, "Right" then @size - offset
        @animated = @mode == "Animated - Start to End" or @mode == "Animated - End to Start"
        @offset = (@animated and offset <= 0) and 1 or offset
        @loop = @animated and line.duration / (zf.util\getFrameDur(0) * @offset) or 1
        @line = line

    iterText: (start_time, end_time, char, cn, ci, df = 0) =>
        i, n, dur = 0, @loop, end_time - start_time
        s, e, v = start_time, end_time, nil
        ->
            i += 1
            if i <= n
                if @animated
                    s = start_time + dur * (i - 1) / n
                    e = start_time + dur * i / n
                u = (i - 1) / (n - 1)
                u = @animated and (@mode == "Animated - Start to End" and u or 1 - u) or (@mode == "Around" and (ci - 1) / (cn - 1) or nil)
                o = u and u * @size or @offx
                t = (o + char.x + df - @left) / @len
                if 0 <= t and t <= 1
                    tan, pnt = @shape\getNormal t
                    pnt\round 3
                    angle = deg atan2 -tan.y, tan.x
                    angle = zf.math\round angle - 90
                    v = {x: pnt.x, y: pnt.y, :angle}
                else
                    v = {x: char.x, y: char.y, angle: 0}
                return v, s, e

    iterShape: (start_time, end_time, shape) =>
        i, n, dur, clip = 0, @loop, @line.duration, @shape\build!
        s, e, an, add = start_time, end_time, @line.styleref.align, nil
        ->
            i += 1
            if i <= n
                u = (i - 1) / (n - 1)
                v = zf.shape shape
                w = v.w
                size = @len - w
                if @animated
                    s = start_time + dur * (i - 1) / n
                    e = start_time + dur * i / n
                    u = @mode == "Animated - Start to End" and u or 1 - u
                    v = v\inClip an, clip, nil, nil, u * size
                elseif @mode == "Around"
                    v = v\inClip an, clip, @mode, w
                else
                    v = v\inClip an, clip, @mode, nil, @offset
                return v\build!, s, e

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
            unless .ens
                callTags = zf.text(subs, line, line.text)\tags!
                result = IN_CLIP line, clip, .off, .mds
                for t, tag in ipairs callTags
                    rawTag = zf.tags\clear tag, zf.tags\getTag(tag.text), "Shape To Clip"
                    chars = zf.text(subs, tag)\chars!
                    for c, char in ipairs chars
                        for v, s, e in result\iterText l.start_time, l.end_time, char, chars.n, c
                            {:x, :y, :angle} = v
                            tags = zf.tags\replaceCoords rawTag, {x, y}
                            tags = zf.tags\merge tags, "\\frz#{angle}"
                            tag.start_time = s
                            tag.end_time = e
                            tag.text = tags .. char.text_stripped
                            i = zf.util\insertLine tag, subs, sel, i
            else
                result = IN_CLIP line, clip, .off, .mds
                rawTag = zf.tags\clear line, rawTag, "Shape"
                rawTag = zf.tags\clear line, rawTag, "Shape In Clip"
                for v, s, e in result\iterShape l.start_time, l.end_time, shape
                    line.start_time = s
                    line.end_time = e
                    line.text = rawTag .. v
                    i = zf.util\insertLine line, subs, sel, i

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main