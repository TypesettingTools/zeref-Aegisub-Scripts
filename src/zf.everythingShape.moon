export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "1.4.8"
-- LIB
zf = require "ZF.main"

shapeMerge = (subs, selected) ->
    add, result = {}, ""
    for sel in *selected
        -- gets the current line
        l = subs[sel]
        -- gets the first tag and the text stripped
        rawTag, rawTxt = zf.tags\getRawText l.text
        -- skips execution if execution is not possible
        unless zf.util\runMacro l
            continue
        -- calls the TEXT class to get the necessary values
        callText = zf.text subs, l
        {:coords} = callText
        shape = zf.util\isShape rawTxt
        unless shape
            shape = callText\toShape nil, px, py
        zf.table(add)\push l, coords, shape
    -- if any shape were added
    if #add != 0
        for i = 1, #add, 3
            ln = add[i + 0]
            cd = add[i + 1]
            sh = add[i + 2]
            result ..= zf.shape(sh)\setPosition(ln.styleref.align)\expand(ln, cd)\move(cd.pos[1], cd.pos[2])\build!
        {ln, cd} = add
        return zf.shape(result)\setPosition(ln.styleref.align, "ucp", cd.pos[1], cd.pos[2])\build!

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
            "Shape Round Corners", "Shape Bounding Box"
        }
        {"Line", "Full"}
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

main = (subs, selected, active, button, elements) ->
    new_selection, i = {}, {0, 0, selected[#selected], zf.util\getFirstLine subs}
    gui = zf.config\loadGui interface!, script_name
    while true
        button, elements = aegisub.dialog.display gui, {"Shape", "Stroke", "Envelope", "Reset", "Cancel"}, close: "Cancel"
        gui = switch button
            when "Reset"  then interface!
            when "Cancel" then return
            else               break
    zf.config\saveGui elements, script_name
    if elements.list1 == "Shape Merge"
        merged_shape = shapeMerge subs, selected
        -- gets the line
        line = zf.table(subs[selected[1]])\copy!
        -- gets the text stripped and the first tag
        rawTag, rawTxt = zf.tags\getRawText line.text
        unless zf.util\isShape rawTxt
            rawTag = zf.tags\clearByPreset rawTag, "To Text"
            rawTag = zf.tags\insertTag rawTag, "\\p1"
        rawTag = zf.tags\clearByPreset rawTag, {"fscx", "fscy", "fax", "fay", "frx", "fry", "frz", "org"}
        line.text = rawTag .. merged_shape
        -- comments and removes the original lines
        for sel in *selected
            dialogue_index = sel + i[1] - i[2] - i[4] + 1
            -- gets the current line
            l, remove = subs[sel + i[1]], elements.remove
            -- skips execution if execution is not possible
            unless zf.util\runMacro l
                zf.util\warning "The line is commented out or it is an empty line with possible blanks.", dialogue_index
                remove = false
                continue
            zf.util\deleteLine l, subs, sel, remove, i
            remove = elements.remove
        zf.util\insertLine line, subs, selected[#selected], new_selection, i
        aegisub.set_undo_point script_name
        if #new_selection > 0
            return new_selection, new_selection[1]
        return selected, active
    -- else
    for sel in *selected
        dialogue_index = sel + i[1] - i[2] - i[4] + 1
        aegisub.progress.set 100 * sel / i[3]
        aegisub.progress.task "Processing line: #{dialogue_index}"
        -- gets the current line
        l, remove = subs[sel + i[1]], elements.remove
        -- skips execution if execution is not possible
        unless zf.util\runMacro l
            if elements.list1 != "Clip To Shape"
                zf.util\warning "The line is commented out or it is an empty line with possible blanks.", dialogue_index
                remove = false
                continue
        -- copies the current line
        line = zf.table(l)\copy!
        line.comment = false
        -- calls the TEXT class to get the necessary values
        callText = zf.text subs, line
        {:coords} = callText
        {px, py} = coords.pos
        -- gets the first tag and the text stripped
        rawTag, rawTxt = zf.tags\getRawText line.text
        shape, clip = zf.util\isShape rawTxt
        unless shape
            shape, clip = callText\toShape nil, px, py
            rawTag = zf.tags\clearByPreset rawTag, "To Text"
            rawTag = zf.tags\insertTag rawTag, "\\p1"
            -- fixes the scale interference in the function expand
            line.styleref.scale_x = 100
            line.styleref.scale_y = 100
        with elements
            -- sets the final tag value and the type of shape simplification
            stype = .list2 == "Full" and "bezier" or "line"
            final = zf.tags\replaceCoords rawTag, coords.pos
            {:align} = line.styleref
            if button == "Shape"
                -- Shape Mode List
                switch .list1
                    when "Shape To Clip"
                        clip = zf.shape(shape, .opn)\setPosition(align)\expand(line, coords)\move(px, py)\build!
                        tclip = rawTag\match("\\iclip%b()") and "iclip" or "clip"
                        final = zf.tags\insertTag final, "\\#{tclip}(#{clip\sub 1, -2})"
                    when "Clip To Shape"
                        if clip = rawTag\match "\\i?clip%b()"
                            -- transforms clip into shape
                            shape = zf.shape zf.util\clip2Draw(clip), .opn
                            shape = shape\setPosition(align, "ucp", px, py)\build!
                            final = zf.tags\clearByPreset final, .list1
                        else
                            zf.util\warning "Tag \"\\clip\" not found", dialogue_index
                            remove = false
                            continue
                    when "Shape Origin"
                        shape = zf.shape(shape, .opn)\toOrigin!
                        {l: lf, t: tp} = shape
                        shape = shape\build!
                        with coords
                            x1 = zf.math\round px + lf
                            y1 = zf.math\round py + tp
                            value = {x1, y1}
                            if .move[3] != nil
                                {x1, y1, x2, y2, ts, te} = .move
                                x1 = zf.math\round x1 + lf
                                y1 = zf.math\round y1 + tp
                                x2 = zf.math\round x2 + lf
                                y2 = zf.math\round y2 + tp
                                value = {x1, y1, x2, y2, ts, te}
                            final = zf.tags\replaceCoords final, value
                    when "Shape Flatten"
                        segment = switch .list3
                            when "Full"   then "m"
                            when "Line"   then "l"
                            when "Bezier" then "b"
                        shape = zf.shape(shape, .opn)\flatten(nil, nil, .tol <= 0 and 1e-1 or .tol, segment)\build!
                    when "Shape Clipper"
                        if clip = rawTag\match "\\i?clip%b()"
                            clip = zf.shape zf.util\clip2Draw(clip), .opn
                            clip = clip\move(-px, -py)\build!
                            shape = zf.shape(shape, .opn)\setPosition(align)\build!
                            shape = zf.clipper(shape, clip, .opn)\clip(rawTag\match("\\iclip%b()"))\build stype
                            final = zf.tags\removeTags final, "clip", "iclip"
                            final = zf.tags\insertTags final, "\\an7"
                        else
                            zf.util\warning "Tag \"\\clip\" not found", dialogue_index
                            remove = false
                            continue
                    when "Shape Simplify"
                        shape = zf.shape(shape, .opn)\setPosition(align)\build!
                        shape = zf.clipper(shape, nil, .opn)\simplify!
                        shape = shape\build stype, .tol <= 1 and 1 or .tol
                        final = zf.tags\insertTags final, "\\an7"
                    when "Shape Bounding Box"
                        bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                        shape = zf.shape(bbox, .opn)\setPosition(align)\build!
                        final = zf.tags\insertTags final, "\\an7"
                    when "Shape Expand"
                        shape = zf.shape(shape, .opn)\setPosition(align)\expand(line, coords)\build!
                        final = zf.tags\clearByPreset final, "Shape Expand"
                        final = zf.tags\insertTags final, "\\an7"
                    when "Shape Round Corners"
                        shape = zf.shape(shape, .opn)\setPosition(align)\roundCorners(.tol)\build!
                        final = zf.tags\insertTags final, "\\an7"
                    when "Shape Round"
                        shape = zf.shape(shape, .opn)\build .tol
                    when "Shape Move"
                        shape = zf.shape(shape, .opn)\move(.px, .py)\build!
                line.text = zf.tags\clearStyleValues(line, final) .. shape
                zf.util\deleteLine l, subs, sel, remove, i
                zf.util\insertLine line, subs, sel, new_selection, i
            elseif button == "Stroke"
                zf.util\deleteLine l, subs, sel, remove, i
                final = zf.tags\insertTags final, "\\an7", "\\bord0"
                shape = zf.clipper zf.shape(shape)\setPosition(align)\build!
                if .genroo
                    .strokeSize = switch .list5
                        when "Inside" then -.strokeSize
                        when "Center" then .strokeSize / 2
                    line.text = zf.tags\clearStyleValues(line, final) .. shape\offset(.strokeSize, .list4, nil, .miterl, .arct)\build stype
                    zf.util\insertLine line, subs, sel, new_selection, i
                else
                    colors = {"\\c" .. line.styleref.color3, "\\c" .. line.styleref.color1}
                    alphas = {"\\1a" .. line.styleref.alpha3, "\\1a" .. line.styleref.alpha1}
                    if line.styleref.alpha != "&H00&"
                        if final\match "\\1a%s*&?[Hh]%x+&?"
                            alphas[1] = "\\1a" .. line.styleref.alpha
                        else
                            alphas = nil
                    shapes = {shape\toStroke .strokeSize, .list4, .list5, .miterl, .arct}
                    for j = 1, 2
                        final = zf.tags\insertTags final, colors[j], alphas and alphas[j] or nil
                        line.text = zf.tags\clearStyleValues(line, final) .. shapes[j]\build stype
                        zf.util\insertLine line, subs, sel, new_selection, i
            elseif button == "Envelope"
                mesh, real = {}, {}
                final = zf.tags\insertTags final, "\\an7"
                shape = zf.shape(shape)\setPosition(align)\build!
                if .list7 == "Mesh"
                    bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                    bbox = zf.shape(bbox)\setPosition 7, nil, px, py
                    bbox = (.list6 == "Bezier" and bbox\allCubic! or bbox\flatten nil, .cpsize)\build!
                    final = zf.tags\insertTags final, "\\clip(#{bbox\sub(1, -2)})"
                elseif .list7 == "Perspective"
                    if clip = rawTag\match "\\i?clip%b()"
                        clip = zf.util\clip2Draw clip 
                        if clip\match "b"
                            zf.util\warning "The perspective transformation only works with line segments", dialogue_index
                            remove = false
                            continue
                        clip = zf.shape(clip)\move -px, -py
                        clip = clip["paths"][1]["path"]
                        unless #clip == 4
                            zf.util\warning "The perspective transformation needs 4 segments.", dialogue_index
                            remove = false
                            continue
                        zf.table(mesh)\push unpack clip[1].segment
                        for i = 2, #clip - 1
                            zf.table(mesh)\push clip[i].segment[2]
                        shape = zf.shape(shape, .opn)\perspective(mesh)\build!
                        final = zf.tags\removeTags final, "clip", "iclip"
                    else
                        zf.util\warning "Tag \"\\clip\" not found", dialogue_index
                        remove = false
                        continue
                elseif .list7 == "Warp"
                    if clip = rawTag\match "\\i?clip%b()"
                        clip = zf.util\clip2Draw clip 
                        bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                        if .list6 != "Bezier"
                            if clip\match "b"
                                zf.util\warning "The perspective transformation only works with line segments.", dialogue_index
                                remove = false
                                continue
                            clip = zf.shape(clip)\move -px, -py
                            clip = clip["paths"][1]["path"]
                            size = zf.math\round #clip / 4
                            bbox = zf.shape(bbox)\flatten nil, size
                            bbox = bbox["paths"][1]["path"]
                        else
                            if clip\match "l"
                                zf.util\warning "The perspective transformation only works with bezier segments.", dialogue_index
                                remove = false
                                continue
                            clip = zf.shape(clip)\move -px, -py
                            size = zf.math\round clip.w / 10
                            clip = clip\flatten nil, size, nil, "b"
                            clip = clip["paths"][1]["path"]
                            bbox = zf.shape(bbox)\flatten nil, size
                            bbox = bbox["paths"][1]["path"]
                        {a, b} = clip[1]["segment"]
                        zf.table(mesh)\push a, b
                        {a, b} = bbox[1]["segment"]
                        zf.table(real)\push a, b
                        for i = 2, #bbox - 1
                            zf.table(mesh)\push clip[i]["segment"][2]
                            zf.table(real)\push bbox[i]["segment"][2]
                        shape = zf.shape(shape, .opn)\envelopeDistort(mesh, real)\build!
                        final = zf.tags\removeTags final, "clip", "iclip"
                    else
                        zf.util\warning "Tag \"\\clip\" not found", dialogue_index
                        remove = false
                        continue
                line.text = zf.tags\clearStyleValues(line, final) .. shape
                zf.util\deleteLine l, subs, sel, remove, i
                zf.util\insertLine line, subs, sel, new_selection, i
        remove = elements.remove
    aegisub.set_undo_point script_name
    if #new_selection > 0
        return new_selection, new_selection[1]

aegisub.register_macro script_name, script_description, main