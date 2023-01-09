export script_name        = "Gradient Cut"
export script_description = "Generates a gradient from cuts in sequence."
export script_author      = "Zeref"
export script_version     = "1.3.4"
export script_namespace   = "zf.gradientCut"
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

-- makes linear cuts in the shape from its bounding box values
gradientCut = (shape, pixel = 4, mode = "Horizontal", angle = 0, offset = 0) ->
    angle = switch mode
        when "Horizontal" then 0
        when "Vertical"   then 90

    sh = zf.shape shape
    original = zf.point sh.l, sh.t

    -- gets the bounding box values before rotation
    sh\toOrigin!
    sh\setBoudingBox!

    -- difference between the original point and the origin point
    diff = original - zf.point sh\unpackBoudingBox!

    -- gets the center point of the bounding box
    pmid = zf.point sh.w / 2, sh.h / 2

    -- gets the bounding box shape and rotates through the defined angle
    shapeBox = sh\getBoudingBoxAssDraw!
    rotateBox = zf.shape(shapeBox)\rotate angle

    -- gets the bounding box values after rotation
    rLeft, rTop, rRight, rBottom = zf.shape(rotateBox)\unpackBoudingBox!

    -- gets the values of the relative points to the left of the bounding box with rotation
    pLeft1 = zf.point rLeft - offset, rTop - offset
    pLeft2 = zf.point rLeft - offset, rBottom + offset

    -- gets the values of the relative points to the right of the bounding box with rotation
    pRight1 = zf.point rRight + offset, rTop - offset
    pRight2 = zf.point rRight + offset, rBottom + offset

    -- rotates the left and right lines and moves them to their original position
    lLeft = zf.shape("m #{pLeft1.x} #{pLeft1.y} l #{pLeft2.x} #{pLeft2.y} ", false)\rotate(angle, pmid.x, pmid.y)\move(diff.x, diff.y)\build!
    lRight = zf.shape("m #{pRight1.x} #{pRight1.y} l #{pRight2.x} #{pRight2.y} ", false)\rotate(angle, pmid.x, pmid.y)\move(diff.x, diff.y)\build!

    -- moves the shape to its original position
    sclip = zf.clipper sh\move(diff.x, diff.y)\build!

    clipped, len = {}, zf.math\round (rRight - rLeft + offset) / pixel, 0
    for i = 1, len
        -- interpolates the points from the left-hand line to the right-hand line
        ipol = zf.util\interpolation (i - 1) / (len - 1), "shape", lLeft, lRight
        ipol = zf.clipper(ipol)\offset pixel, "miter", "closed_line"
        -- adds the shape as a clip
        ipol.clp = sclip.sbj
        -- clip and build the new shape
        clip = ipol\clip!
        clip = clip\build "line"
        zf.table(clipped)\push clip if clip != ""
    return clipped

colorConfig = (gui, mode = "add", colorLimit = 16) ->
    {:x, :y, :name, :value} = gui[#gui]
    i = tonumber name\match "%d+"
    if mode == "add"
        if i <= colorLimit
            zf.table(gui)\push {class: "color", name: "color#{i + 1}", :x, y: y + 2, height: 2, :value}
        else
            aegisub.debug.out 2, "color limit reached" .. "\n"
    elseif mode == "rem"
        if i > 2
            zf.table(gui)\pop!
        else
            aegisub.debug.out 2, "cannot remove any more" .. "\n"
    return gui

addDropColors = (gui, read) ->
    colors = {}
    for name, value in pairs read
        if i = name\match "color(%d+)"
            colors[tonumber i] = value
    for i = 3, #colors
        {:x, :y} = gui[#gui]
        zf.table(gui)\push {class: "color", name: "color#{i}", :x, y: y + 2, height: 2, value: colors[i]}
    return gui

interface = (x = 7) ->
    modes = {"Vertical", "Horizontal", "By Angle"}
    {
        {class: "label", label: "Gradient Type:", :x, y: 0}
        {class: "dropdown", name: "mode", items: modes, :x, y: 1, value: modes[1]}
        {class: "label", label: "Gap Size:", :x, y: 2}
        {class: "intedit", name: "gapSize", :x, y: 3, value: 2}
        {class: "label", label: "Accel:", :x, y: 4}
        {class: "floatedit", name: "accel", :x, y: 5, value: 1}
        {class: "label", label: "Angle:", :x, y: 6}
        {class: "floatedit", name: "angle", :x, y: 7, value: 0}
        {class: "checkbox", label: "Remove selected layers?\t\t\t\t", name: "remove", :x, y: 8, value: true}
        {class: "label", label: "Colors:", :x, y: 10}
        {class: "color", name: "color1", :x, y: 11, height: 2, value: "#FFFFFF"}
        {class: "color", name: "color2", :x, y: 13, height: 2, value: "#FF0000"}
    }

main = (subs, selected, active, button, elements) ->
    gui, read = zf.config\loadGui interface!, script_name
    gui = addDropColors gui, read if read
    while true
        button, elements = aegisub.dialog.display gui, {"Ok", "Add+", "Rem-", "Reset", "Cancel"}, close: "Cancel"
        gui = switch button
            when "Add+"   then colorConfig gui, "add"
            when "Rem-"   then colorConfig gui, "rem"
            when "Reset"  then interface!
            when "Cancel" then return
            else               break
    zf.config\saveGui elements, script_name
    colors = [zf.util\convertColor elements["color#{j - 10}"] for j = 11, #gui]
    dlg = zf.dialog subs, selected, active, elements.remove
    for l, line, sel, i, n in dlg\iterSelected!
        dlg\progressLine sel
        -- skips execution if execution is not possible
        if l.comment
            dlg\warning sel, "The line is commented out."
            continue
        -- gets the shape if it exists in the line
        shape, clip = zf.util\isShape line.text
        rawTag = zf.layer line.text, false
        -- extends the line information
        call = zf.line(line)\prepoc dlg
        pers = dlg\getPerspectiveTags line
        {px, py} = pers["pos"]
        -- if the shape is not found transform the text into a shape
        unless shape
            if elements.list1 != "Clip To Shape"
                shape, clip = call\toShape dlg, nil, px, py
            -- removes unnecessary tags
            rawTag\remove "fs", "fscx", "fscy", "fsp", "fn", "b", "i", "u", "s"
            rawTag\insert "\\fscx100\\fscy100\\p1"
        shape = zf.shape(shape)\setPosition(line.styleref.align)\build!
        with elements
            dlg\removeLine l, sel
            final = zf.layer(rawTag)\replaceCoords {px, py}
            final\remove "an", "bord", "xbord", "ybord", "shad", "xshad", "yshad"
            final\insert {"\\an7", true}, "\\bord0\\shad0"
            gcuts = gradientCut shape, .gapSize, .mode, .angle
            for c, gcut in ipairs gcuts
                t = (c - 1) ^ .accel / (#gcuts - 1) ^ .accel
                color = zf.util\interpolation t, "color", colors
                final\remove "1c"
                final\insert "\\1c#{color}"
                line.text = final\__tostring! .. gcut
                dlg\insertLine line, sel
    return dlg\getSelection!

if haveDepCtrl
    depctrl\registerMacro main
else
    aegisub.register_macro script_name, script_description, main
