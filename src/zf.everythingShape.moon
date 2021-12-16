export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

import SHAPE      from require "ZF.2D.shape"
import POINT      from require "ZF.2D.point"
import BEZIER     from require "ZF.2D.bezier"
import LIBCLIPPER from require "ZF.2D.clipper"

splitBox = (box, max = 5) ->
    splited, i = SHAPE(box).paths[1], 1

    if max > 5

        while max % 5 != 0
            max += 1

        splited = SHAPE(box)\split(1).paths[1]
        while #splited >= max
            i += 1
            splited = SHAPE(box)\split(i).paths[1]

    return splited

splitByLength = (shape, size = 0) ->

    splitPath = (path, info) ->
        split = BEZIER(path[info.index])\split 0.5
        path[info.index] = split[1].paths
        table.insert path, info.index + 1, split[2].paths
        return path

    shape = SHAPE shape
    infos = shape\sortLengths (a, b) -> a.len > b.len

    path, info = shape.paths[1], infos[1]
    while size > 0
        path = splitPath path, info[1]
        size -= 1

    return path

shapeMerge = (subs, selected) ->
    values, result = {}, ""
    for s, sel in ipairs selected
        l = subs[sel]

        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""

        unless isShape
            continue unless zf.util\runMacro l
            shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape

        zf.table(values)\push l.styleref.align, coords.pos, shape

    for i = 1, #values, 3
        an = values[i + 0]
        ps = values[i + 1]
        sh = values[i + 2]
        result ..= SHAPE(sh)\displace(an, "tcp", ps.x, ps.y)\build!

    return SHAPE(result)\displace(values[1], "ucp", values[2].x, values[2].y)\build!

interface = ->
    defaultFilter = "function(x, y, p)\n local size = 15\n p.x = p.x + math.random() * size\n p.y = p.y + math.random() * size\n return p\nend"

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
            "Shape To Clip", "Clip To Shape",  "Shape Origin"
            "Shape Expand",  "Shape Simplify", "Shape Split"
            "Shape Merge",   "Shape Round",    "Shape Clipper"
            "Shape Filter",  "Shape Move",     "Shape Round Corners"
        }
        {"Full", "Line"}
        {"Full", "Bezier", "Line"}
        {"Miter", "Round", "Square"}
        {"Center", "Inside", "Outside"}
        {"Bezier", "Line"}
        {"Mesh", "Warp", "Perspective"}
    }
    table.sort lists[1]

    {
        -- Section for shape or text
        {class: "label", label: "Mode List:", x: 0, y: 0}
        {class: "dropdown", name: "list1", items: lists[1], x: 0, y: 1, value: lists[1][1]}
        {class: "label", label: "Simplify Modes:", x: 0, y: 2}
        {class: "dropdown", name: "list2", items: lists[2], x: 0, y: 3, value: lists[2][1]}
        {class: "label", label: "Split Modes:", x: 0, y: 4}
        {class: "dropdown", name: "list3", items: lists[3], x: 0, y: 5, value: lists[3][1]}
        {class: "label", label: "X - Axis:", x: 0, y: 7}
        {class: "floatedit", name: "px", x: 0, y: 8, value: 0}
        {class: "label", label: "Y - Axis:", x: 0, y: 9}
        {class: "floatedit", name: "py", x: 0, y: 10, value: 0}
        {class: "checkbox", label: "Remove selected layers?", name: "remove", x: 0, y: 11, value: true}
        {class: "label", label: "Filter Section:", x: 0, y: 13}
        {class: "textbox", name: "fil", hint: hints[7], x: 0, y: 14, width: 12, height: 5, value: defaultFilter}
        {class: "label", label: "Tolerance: ", x: 8, y: 7}
        {class: "floatedit", name: "tol", hint: hints[1],  x: 8, y: 8, width: 4, min: 0, value: 1}

        -- Section for shape strokes
        {class: "label", label: "Stroke Corner:", x: 4, y: 0}
        {class: "dropdown", name: "list4", items: lists[4], x: 4, y: 1, value: lists[4][2]}
        {class: "label", label: "Align Stroke:", x: 4, y: 2}
        {class: "dropdown", name: "list5", items: lists[5], x: 4, y: 3, value: lists[5][3]}
        {class: "label", label: "Stroke Weight:", x: 4, y: 4}
        {class: "floatedit", name: "strokeSize", x: 4, y: 5, min: 0, value: 2}
        {class: "label", label: "Miter Limit:", x: 4, y: 7}
        {class: "floatedit", name: "miterl", hint: hints[5], x: 4, y: 8, min: 0, value: 2}
        {class: "label", label: "Arc Tolerance:", x: 4, y: 9}
        {class: "floatedit", name: "arct", hint: hints[6], x: 4, y: 10, min: 0, value: 0.25}
        {class: "checkbox", label: "Generate only offset?", name: "genroo", x: 4, y: 11, value: false}

        -- Section for Envelope Distort
        {class: "label", label: "Control Points: ", x: 8, y: 0}
        {class: "intedit", name: "cpsize", hint: hints[2], x: 8, y: 1, width: 4, min: 1, value: 1}
        {class: "label", label: "Type: ", x: 8, y: 2}
        {class: "dropdown", name: "list6", hint: hints[3],  items: lists[6], x: 8, y: 3, width: 4, value: lists[6][2]}
        {class: "label", label: "Generator: ", x: 8, y: 4}
        {class: "dropdown", name: "list7", hint: hints[4], items: lists[7], x: 8, y: 5, width: 4, value: lists[7][1]}
    }

main = (subs, selected) ->
    gui = zf.config\loadGui interface!, script_name

    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display gui, {"Shape", "Stroke", "Envelope", "Reset", "Cancel"}, close: "Cancel"
        gui = switch buttons
            when "Reset"  then interface!
            when "Cancel" then return
            else               break

    zf.config\saveGui elements, script_name

    n, i = selected[#selected], 0
    if buttons == "Shape" and elements.list1 == "Shape Merge"
        shape = shapeMerge subs, selected
        line = zf.table(subs[selected[1]])\copy!

        for s, sel in ipairs selected
            l = subs[sel + i]
            l.comment = true
            subs[sel + i] = l

            if elements.remove
                subs.delete sel + i
                i -= 1
                n -= 1

        coords = zf.util\setPreprocLine subs, line
        px, py = coords.pos.x, coords.pos.y
        rawTag = zf.tags\getTag line.text

        unless zf.util\isShape coords, line.text\gsub "%b{}", ""
            rawTag = zf.tags\clear line, rawTag, "text"
            rawTag = zf.tags\merge rawTag, "\\p1"

        tag = zf.tags\replaceT zf.tags\remBarces(rawTag), "pos", {px, py}
        tag = zf.tags\addBarces tag

        line.text = tag .. shape
        subs.insert n + 1, line

    else

        for s, sel in ipairs selected
            aegisub.progress.set 100 * sel / n
            aegisub.progress.task "Processing line: #{s}"

            l = subs[sel + i]

            coords = zf.util\setPreprocLine subs, l
            px, py = coords.pos.x, coords.pos.y

            isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""

            rawTag = zf.tags\getTag l.text
            capTag = zf.tags\capTags true

            unless isShape
                continue unless zf.util\runMacro l
                shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape
                rawTag = zf.tags\clear l, rawTag, "text"
                rawTag = zf.tags\merge rawTag, "\\p1"

            l.comment = true

            subs[sel + i] = l

            line = zf.table(l)\copy!
            line.comment = false

            with elements

                if .remove
                    subs.delete sel + i
                    i -= 1

                tag = zf.tags\replaceT zf.tags\remBarces(rawTag), "pos", {px, py}
                tag = zf.tags\addBarces tag

                simplifyType = .list2 == "Full" and "bezier" or "line"

                switch buttons

                    when "Shape"

                        tag = zf.tags\clear line, tag, .list1

                        switch .list1

                            when "Shape To Clip"
                                cpt = tag\match "\\iclip%b()"

                                clip = SHAPE(shape)\displace(line.styleref.align, "tcp", px, py)\build!
                                clip = clip\sub 1, -2

                                tag = zf.tags\merge tag, cpt and {capTag.iclip, {"\\iclip(", clip, ")"}} or {capTag.clip, {"\\clip(", clip, ")"}}

                            when "Clip To Shape"
                                zf.tags\dependency rawTag, "clips"
                                shape = zf.util\clip2Draw rawTag

                                shape = SHAPE(shape)\displace(line.styleref.align, "ucp", px, py)\build!

                            when "Shape Origin"
                                shape = SHAPE(shape)\toOrigin!
                                mx, my = shape.minx, shape.miny
                                shape = shape\build!

                                local value
                                with coords
                                    value = {zf.math\round(.pos.x + mx), zf.math\round(.pos.y + my)}
                                    if .move.x2 != nil
                                        value = {.move.x1 + mx, .move.y1 + my, .move.x2 + mx, .move.y2 + my}

                                tag = zf.tags\replaceT zf.tags\remBarces(tag), "pos", value
                                tag = zf.tags\addBarces tag

                            when "Shape Expand"
                                shape = SHAPE(shape)\displace(line.styleref.align, "tog")\expand(line, coords)\build!

                            when "Shape Simplify"
                                shape = SHAPE(shape)\displace(line.styleref.align, "tog")\build!

                                shape = LIBCLIPPER(shape)\simplify!
                                shape = shape\build simplifyType

                            when "Shape Split"
                                segment = switch .list3
                                    when "Full"   then "m"
                                    when "Line"   then "l"
                                    when "Bezier" then "b"

                                shape = SHAPE(shape)\split(.tol < 1 and 1 or .tol, segment)\build!

                            when "Shape Round"
                                shape = SHAPE(shape)\build zf.math\round .tol, 0

                            when "Shape Round Corners"
                                shape = SHAPE(shape)\displace(line.styleref.align, "tog")\roundCorners .tol
                                shape = shape\build!

                            when "Shape Clipper"
                                zf.tags\dependency rawTag, "clips"

                                clip = SHAPE(zf.util\clip2Draw(rawTag))\move(-px, -py)\build!
                                shape = SHAPE(shape)\displace(line.styleref.align, "tog")\build!
                                shape = LIBCLIPPER(shape, clip)\clip(tag\match("\\iclip%b()"))\build simplifyType

                            when "Shape Filter"
                                filter = loadstring("return #{.fil}")!
                                shape = SHAPE(shape)\filter(filter)\build!

                            when "Shape Move"
                                shape = SHAPE(shape)\move(.px, .py)\build!

                        line.text = tag .. shape

                        subs.insert sel + i + 1, line
                        i += 1

                    when "Stroke"
                        tag = zf.tags\clear line, tag, "Stroke Panel"

                        shape = SHAPE(shape)\displace(line.styleref.align, "tog")\build!

                        if .genroo
                            .strokeSize = switch .list5
                                when "Inside" then -.strokeSize
                                when "Center" then .strokeSize / 2

                            shape = LIBCLIPPER(shape)\offset(.strokeSize, .list4, nil, .miterl, .arct)\build simplifyType

                            line.text = tag .. shape

                            subs.insert sel + i + 1, line
                            i += 1
                        else
                            colors = {line.styleref.color3, line.styleref.color1}
                            shapes = {LIBCLIPPER(shape)\toStroke .strokeSize, .list4, .list5, .miterl, .arct}

                            for k = 1, 2
                                tag = zf.tags\merge tag, {capTag["1c"], "\\c#{color_from_style(colors[k])}"}
                                line.text = tag .. shapes[k]\build simplifyType

                                subs.insert sel + i + 1, line
                                i += 1

                    when "Envelope"

                        tag = zf.tags\clear line, tag, "Shape Clipper"
                        shape = SHAPE(shape)\displace(line.styleref.align, "tog")\build!

                        switch .list7

                            when "Mesh"
                                sBox = SHAPE(shape)\boudingBoxShape!
                                sBox = sBox\displace(7, "tcp", px, py)\split nil, nil, .cpsize
                                if .list6 == "Bezier"
                                    sBox = sBox\toBezier!
                                sBox = sBox\build!

                                tag = zf.tags\merge tag, {capTag.clip, {"\\clip(", sBox\sub(1, -2), ")"}}

                                line.text = tag .. shape

                            when "Warp", "Perspective"
                                isWarp = .list7 == "Warp"
                                zf.tags\dependency rawTag, "clips"

                                sBox = SHAPE(shape)\boudingBoxShape!

                                rawClip = zf.util\clip2Draw rawTag
                                clip = SHAPE(rawClip)\move(-px, -py)\split 5, "b"
                                path = clip.paths[1]

                                assert #path == 5, "Expected 5 points, received #{#path}" unless isWarp

                                points = {}
                                for p, point in ipairs path
                                    zf.table(points)\push #point == 2 and point[2] or point[1]

                                unless isWarp
                                    zf.table(points)\pop!
                                    shape = SHAPE(shape)\perspective(points)\build!
                                else
                                    sBox = splitBox sBox\build!, #path
                                    diff = #sBox - #path
                                    clip = splitByLength clip, diff

                                    mesh = [{} for i = 1, 2]
                                    for i = 2, #sBox
                                        zf.table(mesh[1])\push sBox[i][1]
                                        zf.table(mesh[2])\push clip[i][1]

                                    shape = SHAPE(shape)\envelopeDistort(unpack(mesh))\build!

                                line.text = tag .. shape

                        subs.insert sel + i + 1, line
                        i += 1

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main