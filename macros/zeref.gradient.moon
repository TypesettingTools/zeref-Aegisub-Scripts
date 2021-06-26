export script_name        = "Gradient Cut"
export script_description = "Generate a gradient from cuts in sequence."
export script_author      = "Zeref"
export script_version     = "0.0.1"
-- LIB
zf = require "ZF.utils"

interface = ->
    {
        {class: "dropdown", name: "mode", items: {"Vertical", "Horizontal"}, value: "Vertical", x: 8, y: 1}
        {class: "label", label: "Gradient Types:", x: 8, y: 0}
        {class: "label", label: "Gap Size: ", x: 8, y: 2}
        {class: "intedit", name: "px", x: 8, y: 3, min: 1, value: 2}
        {class: "label", label: "Accel: ", x: 8, y: 4}
        {class: "floatedit", name: "ac", x: 8, y: 5, value: 1}
        {class: "checkbox", label: "Remove selected layers?", name: "act", x: 8, y: 6, value: true}
        {class: "label", label: "\nColors: ", x: 8, y: 7}
        {class: "color", name: "color1", x: 8, y: 8, value: "#FFFFFF"}
        {class: "color", name: "color2", x: 8, y: 9, value: "#FF0000"}
    }

make_cuts = (shape, pixel = 2, nx = 0, ny = 0, mode = "horizontal") ->
    offset, oft = 10, 1
    origin = zf.shape(shape)\origin!
    zf.shape(shape)\info!
    shape_width, shape_height = w_shape, h_shape
    shape_width, shape_height = shape_width + offset, shape_height + offset
    cap_first_point = (p) ->
        x, y = p\match("(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)")
        tonumber(x), tonumber(y)
    px, py = cap_first_point(shape)
    ox, oy = cap_first_point(origin\build!)
    distx, disty = (px - ox), (py - oy)
    clipped = {}
    switch mode
        when "horizontal"
            loop = shape_width / pixel
            for k = 1, loop
                t = (k - 1) / (loop - 1)
                interpol_l = zf.math\interpolation(t, 0, shape_width - pixel) - oft
                interpol_r = zf.math\interpolation(t, pixel, shape_width) + oft
                clip = zf.util\clip_to_draw("\\clip(#{(distx + nx) + interpol_l},#{(disty + ny)},#{(distx + nx) + interpol_r},#{(disty + ny) + shape_height})")
                cuts = zf.poly\clip(shape, clip, nx, ny)
                clipped[#clipped + 1] = cuts if cuts != ""
        when "vertical"
            loop = shape_height / pixel
            for k = 1, loop
                t = (k - 1) / (loop - 1)
                interpol_t = zf.math\interpolation(t, 0, shape_height - pixel) - oft
                interpol_b = zf.math\interpolation(t, pixel, shape_height) + oft
                clip = zf.util\clip_to_draw("\\clip(#{(distx + nx)},#{(disty + ny) + interpol_t},#{(distx + nx) + shape_width},#{(disty + ny) + interpol_b})")
                cuts = zf.poly\clip(shape, clip, nx, ny)
                clipped[#clipped + 1] = cuts if cuts != ""
    return clipped

gradient = (subs, sel) ->
    rest = (t, read, len = 6) -> -- adds in the GUI, the colors that were added
        for i = 7, len
            t[i + 4] = {class: "color", name: "color#{i - 4}", x: 8, y: i + 3, value: read.v["color#{i - 4}"]}
        return t
    inter, read, len = zf.config\load(interface!, script_name)
    inter = rest(inter, read, len)
    add_colors = (t) ->
        GUI = zf.table(t)\copy!
        table.insert(GUI, {class: "color", name: "color#{(#GUI - 8) + 1}", x: 8, y: (#GUI - 1) + 1, value: "#000000"})
        return GUI
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Add+", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                inter, read, len = zf.config\load(inter, script_name)
                rest(inter, read, len)
            when "Add+"
                add_colors(inter)
            when "Reset"
                interface!
        break if buttons == "Ok" or buttons == "Cancel"
    cap_colors, j = {}, 0
    for i = 9, #inter
        table.insert(cap_colors, zf.util\html_color(elements["color#{i - 8}"]))
    if buttons == "Ok"
        aegisub.progress.task("Generating Gradient...")
        for _, i in ipairs(sel)
            aegisub.progress.set (i - 1) / #sel * 100
            l = subs[i + j]
            l.comment = true
            subs[i + j] = l
            if elements.act == true
                subs.delete(i + j)
                j -= 1
            --
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            --
            text = zf.tags\remove("full", l.text)
            tags = zf.tags(l.text)\remove("shape_gradient")
            tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            --
            shape = text\match("m%s+%-?%d[%.%-%d mlb]*")
            shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build!
            shape = zf.shape(shape)\org_points(l.styleref.align)\build!
            --
            cuts = make_cuts(shape, elements.px, coords.pos.x, coords.pos.y, elements.mode\lower!)
            line = table.copy(l)
            for k = 1, #cuts
                line.comment = false
                colors = "\\c#{zf.util\interpolation((k - 1) / (#cuts - 1), "color", cap_colors)}"
                __tags = zf.tags\clean("{#{tags .. colors}}")
                line.text = "#{__tags}#{cuts[k]}"
                subs.insert(i + j + 1, line)
                j += 1
        aegisub.progress.set(100)
    return

aegisub.register_macro script_name, script_description, gradient
