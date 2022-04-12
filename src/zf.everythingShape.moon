export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "1.0.1"
-- LIB
zf = require "ZF.main"

shapeMerge = (subs, selected, n, firstIndex) ->
    values, result = {}, ""
    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{sel - firstIndex + 1}"
        l = subs[sel]

        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""
        unless isShape
            unless zf.util\runMacro l
                continue
            shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape

        zf.table(values)\push l.styleref.align, coords.pos, shape

    if #values != 0
        for i = 1, #values, 3
            an = values[i + 0]
            ps = values[i + 1]
            sh = values[i + 2]
            result ..= zf.shape(sh)\setPosition(an, "tcp", ps.x, ps.y)\build!
        return zf.shape(result)\setPosition(values[1], "ucp", values[2].x, values[2].y)\build!

interface = ->
    hints = {
        "Specific tolerance of some modes that need a customizable value"
        "Number of times there will be a recursive\npoint division on the edges of the bounding box"
        "Defines the output type relative to the control points"
        "Defines what the macro's purpose will be for the output"
        "The default value for MiterLimit is 2 (ie twice delta). \nThis is also the smallest MiterLimit that's allowed. \nIf mitering was unrestricted (ie without any squaring), \nthen offsets at very acute angles would generate \nunacceptably long \"spikes\"."
        "The default ArcTolerance is 0.25 units. \nThis means that the maximum distance \nthe flattened path will deviate from the \n\"true\" arc will be no more than 0.25 units \n(before rounding)."
        "Function to filter all the points of the shape,\nI recommend that you first split the shape so\nyou can have more variety of manipulation."
    }

    lists = {
        {
            "Shape To Clip", "Clip To Shape"
            "Shape Origin", "Shape Expand"
            "Shape Simplify", "Shape Flatten"
            "Shape Merge", "Shape Round"
            "Shape Clipper", "Shape Move"
            "Shape Round Corners"
        }
        {"Full", "Line"}
        {"Full", "Bezier", "Line"}
        {"Miter", "Round", "Square"}
        {"Center", "Inside", "Outside"}
        {"Line", "Bezier"}
        {"Mesh", "Warp", "Perspective"}
    }
    table.sort lists[1]

    {
        -- Section for shape or text
        {class: "label", label: "Mode List:", x: 0, y: 0}
        {class: "dropdown", name: "list1", items: lists[1], x: 0, y: 1, value: lists[1][1]}
        {class: "label", label: "Simplify Modes:", x: 0, y: 2}
        {class: "dropdown", name: "list2", items: lists[2], x: 0, y: 3, value: lists[2][1]}
        {class: "label", label: "Flatten Modes:", x: 0, y: 4}
        {class: "dropdown", name: "list3", items: lists[3], x: 0, y: 5, value: lists[3][1]}
        {class: "label", label: "X - Axis:", x: 0, y: 7}
        {class: "floatedit", name: "px", x: 0, y: 8, value: 0}
        {class: "label", label: "Y - Axis:", x: 0, y: 9}
        {class: "floatedit", name: "py", x: 0, y: 10, value: 0}
        {class: "checkbox", label: "Remove selected layers?", name: "remove", x: 0, y: 11, value: true}

        -- Section for shape strokes
        {class: "label", label: "Stroke Corner:", x: 2, y: 0}
        {class: "dropdown", name: "list4", items: lists[4], x: 2, y: 1, value: lists[4][2]}
        {class: "label", label: "Align Stroke:", x: 2, y: 2}
        {class: "dropdown", name: "list5", items: lists[5], x: 2, y: 3, value: lists[5][3]}
        {class: "label", label: "Stroke Weight:", x: 2, y: 4}
        {class: "floatedit", name: "strokeSize", x: 2, y: 5, min: 0, value: 2}
        {class: "label", label: "Miter Limit:", x: 2, y: 7}
        {class: "floatedit", name: "miterl", hint: hints[5], x: 2, y: 8, min: 0, value: 2}
        {class: "label", label: "Arc Tolerance:", x: 2, y: 9}
        {class: "floatedit", name: "arct", hint: hints[6], x: 2, y: 10, min: 0, value: 0.25}
        {class: "checkbox", label: "Generate only offset?", name: "genroo", x: 2, y: 11, value: false}

        -- Section for Envelope Distort
        {class: "label", label: "Control Points: ", x: 4, y: 0}
        {class: "intedit", name: "cpsize", hint: hints[2], x: 4, y: 1, width: 2, min: 1, value: 1}
        {class: "label", label: "Type: ", x: 4, y: 2}
        {class: "dropdown", name: "list6", hint: hints[3],  items: lists[6], x: 4, y: 3, width: 2, value: lists[6][1]}
        {class: "label", label: "Generator: ", x: 4, y: 4}
        {class: "dropdown", name: "list7", hint: hints[4], items: lists[7], x: 4, y: 5, width: 2, value: lists[7][1]}
        {class: "label", label: "Tolerance: ", x: 4, y: 7}
        {class: "floatedit", name: "tol", hint: hints[1], x: 4, y: 8, width: 2, min: 0, value: 1}
        {class: "checkbox", label: "Close paths? ", name: "opn", x: 4, y: 9, value: true}
    }

main = (subs, selected) ->
    gui = zf.config\loadGui interface!, script_name
    firstIndex = zf.util\getFirstLine subs

    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display gui, {"Shape", "Stroke", "Envelope", "Reset", "Cancel"}, close: "Cancel"
        gui = switch buttons
            when "Reset"  then interface!
            when "Cancel" then return
            else               break

    zf.config\saveGui elements, script_name
    n, i, capTag = selected[#selected], 0, zf.tags\capTags true
    if buttons == "Shape" and elements.list1 == "Shape Merge"
        if shape = shapeMerge subs, selected, n, firstIndex
            line = zf.table(subs[selected[1]])\copy!

            for s, sel in ipairs selected
                l = subs[sel + i]
                l.comment = true
                subs[sel + i] = l

                if elements.remove
                    i = zf.util\deleteLine subs, sel, i
                    n -= 1

            rawTag = zf.tags\getTag line.text
            coords = zf.util\setPreprocLine subs, line
            px, py = coords.pos.x, coords.pos.y

            unless zf.util\isShape coords, line.text\gsub "%b{}", ""
                rawTag = zf.tags\clear line, rawTag, "text"
                rawTag = zf.tags\merge rawTag, "\\p1"

            line.text = zf.tags\replaceCoords(rawTag, {px, py}) .. shape
            zf.util\insertLine line, subs, n, 0
        return

    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{sel + i - firstIndex + 1}"
        l = subs[sel + i]

        rawTag = zf.tags\getTag l.text
        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""
        unless isShape
            -- if there is no text and the mode is clip to shape, do not continue
            unless elements.list1 == "Clip To Shape" and l.text\match "%b{}"
                unless zf.util\runMacro l
                    continue
            shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape
            rawTag = zf.tags\clear l, rawTag, "Text"
            rawTag = zf.tags\merge rawTag, "\\p1"

        l.comment = true
        subs[sel + i] = l

        line = zf.table(l)\copy!
        line.comment = false
        with elements
            i = zf.util\deleteLine subs, sel, i if .remove

            tag = zf.tags\replaceCoords rawTag, {px, py}
            simplifyType = .list2 == "Full" and "bezier" or "line"
            switch buttons
                when "Shape"
                    tag = zf.tags\clear line, tag, .list1
                    switch .list1
                        when "Shape To Clip"
                            cpt = tag\match "\\iclip%b()"

                            clip = zf.shape(shape, .opn)\setPosition(line.styleref.align, "tcp", px, py)\build!
                            clip = clip\sub 1, -2

                            tag = zf.tags\merge tag, cpt and {capTag.iclip, {"\\iclip(", clip, ")"}} or {capTag.clip, {"\\clip(", clip, ")"}}
                        when "Clip To Shape"
                            zf.tags\dependency rawTag, "clips"
                            clip = zf.util\clip2Draw rawTag

                            shape = zf.shape(clip, .opn)\setPosition(line.styleref.align, "ucp", px, py)\build!
                        when "Shape Origin"
                            shape = zf.shape(shape, .opn)\toOrigin!
                            -- left, top
                            {l: lf, t: tp} = shape
                            shape = shape\build!

                            local value
                            with coords
                                value = {zf.math\round(.pos.x + lf), zf.math\round(.pos.y + tp)}
                                if .move.x2 != nil
                                    value = {.move.x1 + lf, .move.y1 + tp, .move.x2 + lf, .move.y2 + tp, .move.ts or nil, .move.te or nil}

                            tag = zf.tags\replaceCoords tag, value
                        when "Shape Flatten"
                            segment = switch .list3
                                when "Full"   then "m"
                                when "Line"   then "l"
                                when "Bezier" then "b"
                            shape = zf.shape(shape, .opn)\flatten(nil, nil, .tol <= 0 and 1e-1 or .tol, segment)\build!
                        when "Shape Clipper"
                            zf.tags\dependency rawTag, "clips"
                            clip = zf.util\clip2Draw rawTag
                            clip = zf.shape(clip)\move(-px, -py)\build!

                            shape = zf.shape(shape, .opn)\setPosition(line.styleref.align, "ply")\build!
                            shape = zf.clipper(shape, clip, .opn)\clip(rawTag\match "\\iclip%b()")\build simplifyType
                        when "Shape Simplify"
                            shape = zf.shape(shape, .opn)\setPosition(line.styleref.align, "ply")\build!
                            shape = zf.clipper(shape, nil, .opn)\simplify!
                            shape = shape\build simplifyType
                        when "Shape Expand"
                            shape = zf.shape(shape, .opn)\setPosition(line.styleref.align, "ply")\expand(line, coords)\build!
                        when "Shape Round"
                            shape = zf.shape(shape, .opn)\build zf.math\round .tol, 0
                        when "Shape Round Corners"
                            shape = zf.shape(shape, .opn)\setPosition(line.styleref.align, "ply")\roundCorners(.tol)\build!
                        when "Shape Move"
                            shape = zf.shape(shape, .opn)\move(.px, .py)\build!

                    line.text = tag .. shape
                    i = zf.util\insertLine line, subs, sel, i
                when "Stroke"
                    tag = zf.tags\clear line, tag, "Stroke Panel"
                    shape = zf.shape(shape)\setPosition(line.styleref.align, "ply")\build!
                    if .genroo
                        .strokeSize = switch .list5
                            when "Inside" then -.strokeSize
                            when "Center" then .strokeSize / 2

                        shape = zf.clipper(shape)\offset(.strokeSize, .list4, nil, .miterl, .arct)\build simplifyType
                        line.text = tag .. shape
                        i = zf.util\insertLine line, subs, sel, i
                    else
                        colors = {line.styleref.color3, line.styleref.color1}
                        shapes = {zf.clipper(shape)\toStroke .strokeSize, .list4, .list5, .miterl, .arct}
                        for j = 1, 2
                            add = {
                                {capTag["1c"], "\\c#{color_from_style(colors[j])}"}
                                {capTag["1a"], "\\1a#{alpha_from_style(colors[j])}"}
                            }
                            tag = zf.tags\merge zf.tags\deleteTags(tag, "3c", "3a"), unpack add
                            line.text = tag .. shapes[j]\build simplifyType
                            i = zf.util\insertLine line, subs, sel, i

                when "Envelope"
                    tag = zf.tags\clear line, tag, "Shape Clipper"
                    shape = zf.shape(shape)\setPosition(line.styleref.align, "ply")\build!
                    mesh, real = {}, {}
                    switch .list7
                        when "Mesh"
                            bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                            bbox = zf.shape(bbox)\setPosition 7, "tcp", px, py
                            if .list6 == "Bezier"
                                bbox\allCubic!
                            else
                                bbox = bbox\flatten nil, .cpsize
                            bbox = bbox\build 0
                            tag = zf.tags\merge tag, {capTag.clip, {"\\clip(", bbox\sub(1, -2), ")"}}
                        when "Perspective"
                            zf.tags\dependency rawTag, "clips"

                            clip = zf.util\clip2Draw rawTag
                            assert not clip\match("b"), "expected line segments, received bezier segments"

                            clip = zf.shape(clip)\move -px, -py
                            clip = clip.paths[1].path
                            assert #clip == 4, "expected 4 points, received #{#clip}"

                            {a, b} = clip[1].segment
                            zf.table(mesh)\push a, b
                            for i = 2, #clip - 1
                                zf.table(mesh)\push clip[i].segment[2]

                            shape = zf.shape(shape, .opn)\perspective(mesh)\build!
                        when "Warp"
                            zf.tags\dependency rawTag, "clips"

                            clip = zf.util\clip2Draw rawTag
                            bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                            if .list6 != "Bezier"
                                assert not clip\match("b"), "expected linear segments, received bezier segments"

                                clip = zf.shape(clip)\move -px, -py
                                clip = clip.paths[1].path
                                size = zf.math\round #clip / 4

                                bbox = bbox\flatten nil, size
                                bbox = bbox.paths[1].path
                            else
                                assert not clip\match("l"), "expected bezier segments, received linear segments"

                                clip = zf.shape(clip)\move -px, -py
                                size = zf.math\round clip.w / 10
                                clip = clip\flatten nil, size, nil, "b"
                                clip = clip.paths[1].path

                                bbox = zf.shape(bbox)\flatten nil, size
                                bbox = bbox.paths[1].path

                            {a, b} = clip[1].segment
                            zf.table(mesh)\push a, b
                            {a, b} = bbox[1].segment
                            zf.table(real)\push a, b
                            for i = 2, #bbox - 1
                                zf.table(mesh)\push clip[i].segment[2]
                                zf.table(real)\push bbox[i].segment[2]

                            shape = zf.shape(shape, .opn)\envelopeDistort(mesh, real)\build!

                    line.text = tag .. shape
                    i = zf.util\insertLine line, subs, sel, i

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main