export script_name        = "Gradient Cut"
export script_description = "Generates a gradient from cuts in sequence."
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

import POINT from require "ZF.2D.point"
import SHAPE from require "ZF.2D.shape"
import LIBCLIPPER from require "ZF.2D.clipper"

-- makes linear cuts in the shape from its bounding box values
gradientCut = (shape, pixel = 4, mode = "Horizontal", angle = 0, offset = 0) ->
    angle = switch mode
        when "Horizontal" then 0
        when "Vertical"   then 90

    -- moves points to origin
    shape = SHAPE(shape)\toOrigin!
    oLeft, oTop = shape.minx, shape.miny

    -- gets the bounding box values before rotation
    shape, left, top, right, bottom = SHAPE(shape)\boudingBox!

    -- difference between the original point and the origin point
    diff = POINT oLeft - left, oTop - top

    -- width and height values
    width = right - left
    height = bottom - top

    -- gets the center point of the bounding box
    pMid = POINT width / 2, height / 2

    -- gets the bounding box shape and rotates through the defined angle
    shapeBox = SHAPE(shape)\boudingBoxShape!
    rotateBox = SHAPE(shapeBox)\rotate angle

    -- gets the bounding box values after rotation
    rotateBox, rLeft, rTop, rRight, rBottom = rotateBox\boudingBox!

    -- gets the values of the relative points to the left of the bounding box with rotation
    pLeft1 = POINT rLeft - offset, rTop - offset
    pLeft2 = POINT rLeft - offset, rBottom + offset

    -- gets the values of the relative points to the right of the bounding box with rotation
    pRight1 = POINT rRight + offset, rTop - offset
    pRight2 = POINT rRight + offset, rBottom + offset

    -- converts left and right lines to shape
    lLeft = "m #{pLeft1.x} #{pLeft1.y} l #{pLeft2.x} #{pLeft2.y} "
    lRight = "m #{pRight1.x} #{pRight1.y} l #{pRight2.x} #{pRight2.y} "

    -- rotates the left and right lines and moves them to their original position
    lLeft = SHAPE(lLeft, false)\rotate(angle, pMid.x, pMid.y)\move(diff.x, diff.y)\build!
    lRight = SHAPE(lRight, false)\rotate(angle, pMid.x, pMid.y)\move(diff.x, diff.y)\build!

    -- moves the shape to its original position
    shape = shape\move diff.x, diff.y

    clipped, len = {}, zf.math\round (rRight - rLeft + offset) / pixel, 0
    for k = 1, len
        t = (k - 1) / (len - 1)

        -- interpolates the points from the left-hand line to the right-hand line
        ipol = zf.util\interpolation t, "shape", lLeft, lRight
        ipol = LIBCLIPPER(ipol)\offset(pixel, "miter", "closed_line")\build "line"

        clip = LIBCLIPPER(shape, ipol)\clip!
        clip = clip\build "line"

        zf.table(clipped)\push clip if clip != ""

    return clipped

addColor = (gui, colorLimit = 16) ->
    last = gui[#gui]

    number = tonumber last.name\match("%d+")

    x, y = last.x, last.y
    cValue = last.value

    if number <= colorLimit
        zf.table(gui)\push {class: "color", name: "color#{number + 1}", :x, y: y + 2, height: 2, value: cValue}

    return gui

addDropColors = (gui, read) ->
    colors = {}

    for name, value in pairs read
        if name\match "color"
            number = tonumber name\match("%d+")
            colors[number] = value

    for k = 3, #colors
        last = gui[#gui]
        zf.table(gui)\push {class: "color", name: "color#{k}", x: last.x, y: last.y + 2, height: 2, value: colors[k]}

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
    for k = 11, #gui
        zf.table(colors)\push zf.util\htmlC(elements["color#{k - 10}"])

    n, i = selected[#selected], 0
    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{s}"

        l = subs[sel + i]

        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        isShape, shape = zf.util\isShape coords, l.text\gsub "%b{}", ""

        unless isShape
            continue unless zf.util\runMacro l

        l.comment = true

        subs[sel + i] = l

        line = zf.table(l)\copy!
        line.comment = false

        rawTag = zf.tags\getTag line.text
        capTag = zf.tags\capTags true

        unless isShape
            shape = zf.text(subs, line, line.text)\toShape(nil, px, py).shape
            rawTag = zf.tags\clear line, rawTag, "text"
            rawTag = zf.tags\merge rawTag, "\\p1"

        tag = zf.tags\replaceT zf.tags\remBarces(rawTag), "pos", {px, py}
        tag = zf.tags\addBarces tag
        tag = zf.tags\clear line, tag, "Gradient Cut"

        shape = SHAPE(shape)\displace(line.styleref.align, "tog")\build!

        with elements

            if .remove
                subs.delete sel + i
                i -= 1

            cuts = gradientCut shape, .gapSize, .mode, .angle

            for c, cut in ipairs cuts
                t = (c - 1) ^ .accel / (#cuts - 1) ^ .accel

                color = zf.util\interpolation t, "color", colors
                tag = zf.tags\merge tag, {capTag["1c"], "\\c#{color}"}

                line.text = tag .. cut

                subs.insert sel + i + 1, line
                i += 1

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main