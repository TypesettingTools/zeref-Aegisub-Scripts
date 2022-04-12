export script_name        = "Gradient Cut"
export script_description = "Generates a gradient from cuts in sequence."
export script_author      = "Zeref"
export script_version     = "1.0.1"
-- LIB
zf = require "ZF.main"

-- makes linear cuts in the shape from its bounding box values
gradientCut = (shape, pixel = 4, mode = "Horizontal", angle = 0, offset = 0) ->
    angle = switch mode
        when "Horizontal" then 0
        when "Vertical"   then 90

    -- moves points to origin
    shape = zf.shape(shape)\toOrigin!
    oLeft, oTop = shape.l, shape.t
    shape = zf.shape shape\build!

    -- gets the bounding box values before rotation
    left, top, right, bottom = shape\unpackBoudingBox!

    -- difference between the original point and the origin point
    diff = zf.point oLeft - left, oTop - top

    -- width and height values
    width = right - left
    height = bottom - top

    -- gets the center point of the bounding box
    pMid = zf.point width / 2, height / 2

    -- gets the bounding box shape and rotates through the defined angle
    shapeBox = shape\getBoudingBoxAssDraw!
    rotateBox = zf.shape(shapeBox)\rotate angle

    -- gets the bounding box values after rotation
    rLeft, rTop, rRight, rBottom = zf.shape(rotateBox)\unpackBoudingBox!

    -- gets the values of the relative points to the left of the bounding box with rotation
    pLeft1 = zf.point rLeft - offset, rTop - offset
    pLeft2 = zf.point rLeft - offset, rBottom + offset

    -- gets the values of the relative points to the right of the bounding box with rotation
    pRight1 = zf.point rRight + offset, rTop - offset
    pRight2 = zf.point rRight + offset, rBottom + offset

    -- converts left and right lines to shape
    lLeft = "m #{pLeft1.x} #{pLeft1.y} l #{pLeft2.x} #{pLeft2.y} "
    lRight = "m #{pRight1.x} #{pRight1.y} l #{pRight2.x} #{pRight2.y} "

    -- rotates the left and right lines and moves them to their original position
    lLeft = zf.shape(lLeft, false)\rotate(angle, pMid.x, pMid.y)\move(diff.x, diff.y)\build!
    lRight = zf.shape(lRight, false)\rotate(angle, pMid.x, pMid.y)\move(diff.x, diff.y)\build!

    -- moves the shape to its original position
    sclip = zf.clipper shape\move diff.x, diff.y

    clipped, len = {}, zf.math\round (rRight - rLeft + offset) / pixel, 0
    for i = 1, len
        t = (i - 1) / (len - 1)
        -- interpolates the points from the left-hand line to the right-hand line
        ipol = zf.util\interpolation t, "shape", lLeft, lRight
        ipol = zf.clipper(ipol)\offset pixel, "miter", "closed_line"
        -- adds the shape as a clip
        ipol.clp = sclip.sbj
        -- clip and build the new shape
        clip = ipol\clip!
        clip = clip\build "line"
        zf.table(clipped)\push clip if clip != ""
    return clipped

addColor = (gui, colorLimit = 16) ->
    {:x, :y, :name, value: cValue} = gui[#gui]
    i = tonumber name\match "%d+"
    if i <= colorLimit
        zf.table(gui)\push {class: "color", name: "color#{i + 1}", :x, y: y + 2, height: 2, value: cValue}
    else
        aegisub.debug.out 2, "color limit reached" .. "\n"
    return gui

addDropColors = (gui, read) ->
    colors = {}
    for name, value in pairs read
        if name\match "color"
            colors[tonumber name\match "%d+"] = value
    for i = 3, #colors
        {:x, :y} = gui[#gui]
        zf.table(gui)\push {class: "color", name: "color#{i}", :x, y: y + 2, height: 2, value: colors[i]}
    return gui

interface = ->
    types, x = {"Vertical", "Horizontal", "By Angle"}, 5
    {
        {class: "label", label: "Gradient Type:", :x, y: 0}
        {class: "dropdown", name: "mode", items: types, :x, y: 1, value: types[1]}
        {class: "label", label: "Gap Size:", :x, y: 2}
        {class: "intedit", name: "gapSize", :x, y: 3, value: 2}
        {class: "label", label: "Accel:", :x, y: 4}
        {class: "floatedit", name: "accel", :x, y: 5, value: 1}
        {class: "label", label: "Angle:", :x, y: 6}
        {class: "floatedit", name: "angle", :x, y: 7, value: 0}
        {class: "checkbox", label: "Remove selected layers?\t", name: "remove", :x, y: 8, value: true}
        {class: "label", label: "Colors:", :x, y: 10}
        {class: "color", name: "color1", :x, y: 11, height: 2, value: "#FFFFFF"}
        {class: "color", name: "color2", :x, y: 13, height: 2, value: "#FF0000"}
    }

main = (subs, selected) ->
    gui, read = zf.config\loadGui interface!, script_name
    gui = addDropColors gui, read if read
    firstIndex = zf.util\getFirstLine subs

    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display gui, {"Ok", "Add+", "Reset", "Cancel"}, close: "Cancel"
        gui = switch buttons
            when "Add+"   then addColor gui
            when "Reset"  then interface!
            when "Cancel" then return
            else               break

    zf.config\saveGui elements, script_name

    colors = {}
    for i = 11, #gui
        zf.table(colors)\push zf.util\htmlC elements["color#{i - 10}"]

    n, i, capTag = selected[#selected], 0, zf.tags\capTags true
    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{sel + i - firstIndex + 1}"

        l = subs[sel + i]

        rawTag = zf.tags\getTag l.text
        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""
        unless isShape
            unless zf.util\runMacro l
                continue
            shape = zf.text(subs, l, l.text)\toShape(nil, px, py).shape
            rawTag = zf.tags\clear l, rawTag, "text"
            rawTag = zf.tags\merge rawTag, "\\p1"

        l.comment = true
        subs[sel + i] = l

        line = zf.table(l)\copy!
        line.comment = false

        shape = zf.shape(shape)\setPosition(line.styleref.align, "ply")\build!
        with elements
            i = zf.util\deleteLine subs, sel, i if .remove

            tag = zf.tags\replaceCoords rawTag, {px, py}
            tag = zf.tags\clear line, tag, "Gradient Cut"
            cuts = gradientCut shape, .gapSize, .mode, .angle
            for c, cut in ipairs cuts
                t = (c - 1) ^ .accel / (#cuts - 1) ^ .accel

                color = zf.util\interpolation t, "color", colors
                conct = zf.tags\merge tag, {capTag["1c"], "\\c#{color}"}

                line.text = conct .. cut
                i = zf.util\insertLine line, subs, sel, i

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main