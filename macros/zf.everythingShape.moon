export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "1.5.4"
export script_namespace   = "zf.everythingShape"
-- LIB
haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"
local zf, depctrl
if haveDepCtrl
    depctrl = DependencyControl {
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"
        {
            "ZF.main"
        }
    }
    zf = depctrl\requireModules!

else
    zf = require "ZF.main"

shapeMerge = (subs, selected, add = {}, result = "") ->
    dlg = zf.dialog subs, selected
    for l, line, sel, i, n in dlg\iterSelected!
        dlg\progressLine sel
        -- checks if the line is commented out
        if l.comment
            dlg\warning sel, "The line is commented out"
            continue
        -- extends the line information
        call = zf.line(line)\prepoc dlg
        shape = zf.util\isShape line.text_stripped
        pers = dlg\getPerspectiveTags line
        unless shape
            shape = call\toShape dlg, nil, px, py
            -- fixes the scale interference in the function expand
            line.styleref.scale_x = 100
            line.styleref.scale_y = 100
        zf.table(add)\push line, pers, shape
    dlg\progressLine "reset"
    -- if something has been added
    if #add != 0
        for i = 1, #add, 3
            ln = add[i + 0]
            ps = add[i + 1]
            sh = add[i + 2]
            result ..= zf.shape(sh)\setPosition(ln.styleref.align)\expand(ln, ps)\move(ps.pos[1], ps.pos[2])\build!
        {ln, ps} = add
        return zf.shape(result)\setPosition(ln.styleref.align, "ucp", ps.pos[1], ps.pos[2])\build!

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
        {"Mesh", "Warp", "Perspective - A", "Perspective - B"}
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
        {class: "intedit", name: "cpsize", hint: hints[2], x: 4, y: 1, width: 3, min: 1, value: 1}
        {class: "label", label: "Type: ", x: 4, y: 2}
        {class: "dropdown", name: "list6", hint: hints[3],  items: lists[6], x: 4, y: 3, width: 3, value: lists[6][1]}
        {class: "label", label: "Generator: ", x: 4, y: 4}
        {class: "dropdown", name: "list7", hint: hints[4], items: lists[7], x: 4, y: 5, width: 3, value: lists[7][1]}
        {class: "label", label: "Tolerance: ", x: 4, y: 7}
        {class: "floatedit", name: "tol", hint: hints[1], x: 4, y: 8, width: 3, min: 0, value: 1}
        {class: "checkbox", label: "Close paths? ", name: "opn", x: 4, y: 9, value: true}
    }

main = (subs, selected, active, button, elements) ->
    gui = zf.config\loadGui interface!, script_name
    while true
        button, elements = aegisub.dialog.display gui, {"Shape", "Stroke", "Envelope", "Reset", "Cancel"}, close: "Cancel"
        gui = switch button
            when "Reset"  then interface!
            when "Cancel" then return
            else               break
    zf.config\saveGui elements, script_name
    dlg = zf.dialog subs, selected, active, elements.remove
    if elements.list1 == "Shape Merge"
        merged_shape = shapeMerge subs, selected
        -- gets the first selected line
        line = zf.table(subs[selected[1]])\copy!
        -- extends the line information
        zf.line(line)\prepoc dlg
        final = zf.layer(line.tags)
        final\remove "fs", "fscx", "fscy", "fsp", "fn", "b", "i", "u", "s", "p", "clip", "iclip", "fax", "fay", "frx", "fry", "frz", "org"
        final\insert "\\fscx100\\fscy100\\p1"
        for l, line, sel, i, n in dlg\iterSelected!
            -- checks if the line is commented out
            if l.comment
                dlg\warning sel, "The line is commented out."
                continue
            dlg\removeLine l, sel
        final\clear line.styleref_old
        line.text = final\__tostring! .. merged_shape
        dlg\insertLine line, selected[#selected]
        return dlg\getSelection!
    -- else
    for l, line, sel, i, n in dlg\iterSelected!
        dlg\progressLine sel
        -- checks if the line is commented out
        if l.comment
            dlg\warning sel, "The line is commented out."
            continue
        -- gets the shape if it exists in the line
        shape, clip = zf.util\isShape line.text
        rawTag = zf.layer line.text, false
        -- extends the line information
        call = zf.line(line)\prepoc dlg
        pers = dlg\getPerspectiveTags line
        tags = zf.tags line.text
        {px, py} = pers["pos"]
        -- if the shape is not found transform the text into a shape
        unless shape
            unless button == "Shape" and elements.list1 == "Clip To Shape"
                shape, clip = call\toShape dlg, nil, px, py
                -- fixes the scale interference in the function expand
                line.styleref.scale_x = 100
                line.styleref.scale_y = 100
            -- removes unnecessary tags
            rawTag\remove "fs", "fscx", "fscy", "fsp", "fn", "b", "i", "u", "s"
            rawTag\insert "\\fscx100\\fscy100\\p1"

        with elements
            stype = .list2 == "Full" and "bezier" or "line"
            final = zf.layer(rawTag)\replaceCoords {px, py}
            {:align} = line.styleref
            if button == "Shape"
                switch .list1
                    when "Shape To Clip"
                        tclip = rawTag\__match("\\iclip%b()") and "iclip" or "clip"
                        if clip
                            clip = zf.shape(shape, .opn)\setPosition(align)\expand(line, pers)\move(px, py)\build!
                            layer = tags["layers"][1]
                            layer\remove "clip", "iclip"
                            layer\insert "\\#{tclip}(#{clip\sub 1, -2})"
                            dlg\removeLine l, sel
                            line.text = tags\__tostring!
                            dlg\insertLine line, sel
                            continue
                        else
                            clip = zf.shape(shape, .opn)\setPosition(align)\expand(line, pers)\move(px, py)\build!
                            final\remove "clip", "iclip"
                            final\insert "\\#{tclip}(#{clip\sub 1, -2})"
                    when "Clip To Shape"
                        if clip = rawTag\__match "\\i?clip%b()"
                            cclip = zf.util\clip2Draw clip
                            shape = zf.shape cclip, .opn
                            shape = shape\setPosition(align, "ucp", px, py)\build!
                            final\remove "clip", "iclip", "fax", "fay", "frx", "fry", "frz", "org"
                        else
                            dlg\warning sel, "Tag \"\\clip\" not found"
                            continue
                    when "Shape Origin"
                        shape = zf.shape(shape, .opn)\toOrigin!
                        {l: lf, t: tp} = shape
                        shape = shape\build!
                        with pers
                            x1 = zf.math\round px + lf
                            y1 = zf.math\round py + tp
                            value = {x1, y1}
                            if .move and .move[3] != nil
                                {x1, y1, x2, y2, ts, te} = .move
                                x1 = zf.math\round x1 + lf
                                y1 = zf.math\round y1 + tp
                                x2 = zf.math\round x2 + lf
                                y2 = zf.math\round y2 + tp
                                value = {x1, y1, x2, y2, ts, te}
                            final\replaceCoords value
                    when "Shape Flatten"
                        segment = switch .list3
                            when "Full"   then "m"
                            when "Line"   then "l"
                            when "Bezier" then "b"
                        shape = zf.shape(shape, .opn)\flatten(nil, nil, .tol <= 0 and 1e-1 or .tol, segment)\build!
                    when "Shape Clipper"
                        if clip = rawTag\__match "\\i?clip%b()"
                            iclip = rawTag\__match "\\iclip%b()"
                            cclip = zf.util\clip2Draw clip
                            cclip = zf.shape(cclip, .opn)\move(-px, -py)\build!
                            shape = zf.shape(shape, .opn)\setPosition(align)\build!
                            shape = zf.clipper(shape, cclip, .opn)\clip(iclip)\build stype
                            final\remove "an", "clip", "iclip"
                            final\insert {"\\an7", true}
                        else
                            dlg\warning sel, "Tag \"\\clip\" not found"
                            continue
                    when "Shape Simplify"
                        shape = zf.shape(shape, .opn)\setPosition(align)\build!
                        shape = zf.clipper(shape, nil, .opn)\simplify!
                        shape = shape\build stype, .tol <= 1 and 1 or .tol
                        final\insert {"\\an7", true}
                    when "Shape Bounding Box"
                        bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                        shape = zf.shape(bbox, .opn)\setPosition(align)\expand(line, pers)\build!
                        final\remove "p", "an", "fscx", "fscy", "fax", "fay", "frx", "fry", "frz", "org"
                        final\insert {"\\an7", true}, "\\fscx100\\fscy100\\frz0\\p1"
                    when "Shape Expand"
                        shape = zf.shape(shape, .opn)\setPosition(align)\expand(line, pers)\build!
                        final\remove "p", "an", "fscx", "fscy", "fax", "fay", "frx", "fry", "frz", "org"
                        final\insert {"\\an7", true}, "\\fscx100\\fscy100\\frz0\\p1"
                    when "Shape Round Corners"
                        shape = zf.shape(shape, .opn)\setPosition(align)\roundCorners(.tol)\build!
                        final\remove "an"
                        final\insert {"\\an7", true}
                    when "Shape Round"
                        shape = zf.shape(shape, .opn)\build .tol
                    when "Shape Move"
                        shape = zf.shape(shape, .opn)\move(.px, .py)\build!
                final\clear line.styleref_old
                dlg\removeLine l, sel
                line.text = final\__tostring! .. shape
                dlg\insertLine line, sel
            elseif button == "Stroke"
                dlg\removeLine l, sel
                final\remove "an", "bord"
                final\insert {"\\an7", true}, "\\bord0"
                final\clear line.styleref_old
                shape = zf.clipper zf.shape(shape)\setPosition(align)\build!
                if .genroo
                    .strokeSize = switch .list5
                        when "Inside" then -.strokeSize
                        when "Center" then .strokeSize / 2
                    shape = shape\offset(.strokeSize, .list4, nil, .miterl, .arct)\build stype
                    line.text = final\__tostring! .. shape
                    dlg\insertLine line, sel
                else
                    colors = {"\\1c" .. line.styleref.color3, "\\1c" .. line.styleref.color1}
                    alphas = {"\\1a" .. line.styleref.alpha3, "\\1a" .. line.styleref.alpha1}
                    if line.styleref.alpha != "&H00&"
                        if final\__match "\\1a%s*&?[Hh]%x+&?"
                            alphas[1] = "\\1a" .. line.styleref.alpha
                        else
                            alphas = nil
                    shapes = {shape\toStroke .strokeSize, .list4, .list5, .miterl, .arct}
                    for j = 1, 2
                        final\remove "1c", "1a"
                        final\insert colors[j], alphas and alphas[j] or nil
                        final\clear line.styleref_old
                        line.text = final\__tostring! .. shapes[j]\build stype
                        dlg\insertLine line, sel
            elseif button == "Envelope"
                local mesh, real
                final\remove "an", "clip", "iclip"
                final\insert {"\\an7", true}
                shape = zf.shape(shape, .opn)\setPosition(align)\build!
                if .list7 == "Mesh"
                    bbox = zf.shape(shape)\getBoudingBoxAssDraw!
                    bbox = zf.shape(bbox)\setPosition 7, nil, px, py
                    bbox = (.list6 == "Bezier" and bbox\allCubic! or bbox\flatten nil, .cpsize)\build!
                    final\insert "\\clip(#{bbox\sub(1, -2)})"
                elseif .list7 == "Perspective - A" or .list7 == "Perspective - B"
                    if clp = rawTag\__match "\\i?clip%b()"
                        clp = zf.util\clip2Draw clp
                        -- checks for bezier segments
                        if clp\match "b"
                            dlg\warning sel, "The perspective transformation only works with line segments"
                            continue
                        -- gets the mesh value and real value
                        mesh = zf.shape(clp)\move(-px, -py)\toPoints![1]
                        if .list7 == "Perspective - A"
                            real = zf.shape(clp)\getBoudingBoxAssDraw!
                            real = zf.shape(real)\move(-px, -py)\toPoints![1]
                        -- checks if the mesh has the four points that compose the quadrilateral
                        unless #mesh == 4
                            dlg\warning sel, "The perspective transformation needs 4 points."
                            continue
                        -- performs perspective transformation on the shape
                        shape = zf.shape(shape)\perspective(mesh, real)\build!
                        final\remove "clip", "iclip"
                    else
                        dlg\warning sel, "Tag \"\\clip\" not found"
                        continue
                elseif .list7 == "Warp"
                    if clp = rawTag\__match "\\i?clip%b()"
                        clp = zf.util\clip2Draw clp
                        box = zf.shape(shape)\getBoudingBoxAssDraw!
                        if .list6 != "Bezier"
                            -- checks for bezier segments
                            if clp\match "b"
                                dlg\warning sel, "The perspective transformation only works with line segments."
                                continue
                            -- gets the mesh value and real value
                            mesh = zf.shape(clp)\move(-px, -py)\toPoints![1]
                            size = zf.math\round #mesh / 4, 0
                            real = zf.shape(box)\flatten(nil, size)\toPoints![1]
                        else
                            -- checks for line segments
                            if clp\match "l"
                                dlg\warning sel, "The perspective transformation only works with bezier segments."
                                continue
                            -- gets the mesh value and real value
                            clpp = zf.shape(clp)\move -px, -py
                            size = zf.math\round clpp.w / 10, 0
                            mesh = clpp\flatten(nil, size, nil, "b")\toPoints![1]
                            real = zf.shape(box)\flatten(nil, size)\toPoints![1]
                        -- performs envelope transformation on the shape
                        shape = zf.shape(shape)\envelopeDistort(mesh, real)\build!
                        final\remove "clip", "iclip"
                    else
                        dlg\warning sel, "Tag \"\\clip\" not found"
                        continue
                final\clear line.styleref_old
                dlg\removeLine l, sel
                line.text = final\__tostring! .. shape
                dlg\insertLine line, sel
    return dlg\getSelection!

if haveDepCtrl
    depctrl\registerMacro main
else
    aegisub.register_macro script_name, script_description, main
