export script_name = "Gradient"
export script_description = "Generates a Gradient in both shape and text, noclip!"
export script_author = "Zeref"
export script_version = "1.0.1"
-- LIB
zf = require "ZF.utils"

gradient_defs = {}
gradient_defs.modes = {
    "Vertical"
    "Horizontal"
}

INTERFACE = {
    {class: "dropdown", name: "mode", items: gradient_defs.modes, value: gradient_defs.modes[1], x: 6, y: 1}
    {class: "label", label: "Gradient Types:                                  ", x: 6, y: 0}
    {class: "label", label: "Gap Size: ", x: 6, y: 2}
    {class: "intedit", name: "px", x: 6, y: 3, min: 1, value: 2}
    {class: "label", label: "Accel: ", x: 6, y: 4}
    {class: "floatedit", name: "ac", x: 6, y: 5, value: 1}
    {class: "checkbox", label: "Save modifications?", name: "sv", x: 6, y: 6, value: false}
    {class: "checkbox", label: "Remove first line?", name: "act", x: 6, y: 7, value: false}
    {class: "label", label: "\nColors: ", x: 6, y: 8}
    {class: "color", name: "color1", x: 6, y: 9, height: 1, width: 1, value: "#FFFFFF"}
    {class: "color", name: "color2", x: 6, y: 10, height: 1, width: 1, value: "#FF0000"}
}

SAVECONFIG = (gui, ck) ->
    ngui = table.copy(gui)
    vals_write = "GRADIENT CONFIG - VERSION #{script_version}\n\n"
    ngui[1].value, ngui[4].value = ck.mode, ck.px
    ngui[6].value, ngui[7].value = ck.ac, ck.sv
    ngui[8].value = ck.act
    c = 1
    for j = 10, #ngui
        ngui[j].value = ck["color#{c}"]
        c += 1
    for k, v in ipairs ngui
        vals_write ..= "{#{v.name} = #{v.value}}\n" if v.name
    dir = aegisub.decode_path("?user")
    unless zf.util\file_exist("#{dir}\\zeref-cfg", true)
        os.execute("mkdir #{dir .. "\\zeref-cfg"}") -- create folder zeref-cfg
    cfg_save = "#{dir}\\zeref-cfg\\gradient_config.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!
    return

READCONFIG = (filename) ->
    SEPLINES = (val) ->
        sep_vals = {n: {}, v: {}}
        for k = 1, #val
            sep_vals.n[k] = val[k]\gsub "(.+) %= .+", (vls) ->
                vls\gsub "%s+", ""
            rec_names = sep_vals.n[k]
            sep_vals.v[rec_names] = val[k]\gsub ".+ %= (.+)", (vls) ->
                vls\gsub "%s+", ""
        return sep_vals
    if filename
        arq = io.open filename, "r"
        if arq != nil
            read = arq\read "*a"
            io.close arq
            lines = [k for k in read\gmatch "(%{[^\n]+%})"]
            for j = 1, #lines do lines[j] = lines[j]\sub(2, -2)
            return SEPLINES(lines), true, #lines
    return _, false

LOADCONFIG = (gui) ->
    load_config = "#{aegisub.decode_path("?user")}\\zeref-cfg\\gradient_config.cfg"
    read_config, rdn, n = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        new_gui[1].value = read_config.v.mode
        new_gui[4].value = tonumber read_config.v.px
        new_gui[6].value = tonumber read_config.v.ac
        new_gui[7].value = (read_config.v.sv == "true" and true or false)
        new_gui[8].value = (read_config.v.act == "true" and true or false)
        new_gui[10].value = read_config.v.color1
        new_gui[11].value = read_config.v.color2
        i, j, c = 12, 3, 11
        for k = 6, n
            if read_config.v["color#{j}"]
                new_gui[i] = {class: "color", name: "color#{j}", x: 6, y: c, height: 1, width: 1, value: read_config.v["color#{j}"]}
                i += 1
                j += 1
                c += 1
    return new_gui

make_cuts = (shape, pixel, nx, ny, mode) ->
    pixel or= 2
    mode or= "horizontal"
    offset, oft = 10, 1
    shape_width, shape_height = zf.poly\dimension(shape)
    shape_width, shape_height = shape_width + offset, shape_height + offset
    origin = zf.poly\origin(shape)
    cap_first_point = (p) ->
        x, y = p\match("(%-?%d+[%.%d+]*)%s+(%-?%d+[%.%d+]*)")
        tonumber(x), tonumber(y)
    px, py = cap_first_point(shape)
    ox, oy = cap_first_point(origin)
    distx, disty = (px - ox), (py - oy)
    clip, cliped = {}, {}
    switch mode
        when "horizontal"
            loop = shape_width / pixel
            for k = 1, loop
                mod = (k - 1) / (loop - 1)
                interpol_l = zf.math\interpolation(mod, 0, shape_width - pixel) - oft
                interpol_r = zf.math\interpolation(mod, pixel, shape_width) + oft
                clip[k] = zf.util\clip_to_draw("\\clip(#{(distx + nx) + interpol_l},#{(disty + ny)},#{(distx + nx) + interpol_r},#{(disty + ny) + shape_height})")
                cuts = zf.poly\clip(shape, clip[k], nx, ny)
                cliped[#cliped + 1] = cuts if cuts != ""
        when "vertical"
            loop = shape_height / pixel
            for k = 1, loop
                mod = (k - 1) / (loop - 1)
                interpol_t = zf.math\interpolation(mod, 0, shape_height - pixel) - oft
                interpol_b = zf.math\interpolation(mod, pixel, shape_height) + oft
                clip[k] = zf.util\clip_to_draw("\\clip(#{(distx + nx)},#{(disty + ny) + interpol_t},#{(distx + nx) + shape_width},#{(disty + ny) + interpol_b})")
                cuts = zf.poly\clip(shape, clip[k], nx, ny)
                cliped[#cliped + 1] = cuts if cuts != ""
    return cliped

gradient = (subs, sel) ->
    inter, add = LOADCONFIG(INTERFACE), 0
    add_colors = (t) ->
        gui = table.copy(t)
        table.insert(gui, {class: "color", name: "color#{ (#gui - 9) + 1 }", x: 6, y: (#gui - 1) + 1, height: 1, width: 1, value: "#000000"})
        return gui
    local bx, ck
    while true
        bx, ck = aegisub.dialog.display(inter, {"Run", "Add+", "Reset", "Cancel"}, {close: "Cancel"})
        inter = add_colors(inter) if (bx == "Add+")
        inter = INTERFACE if (bx == "Reset")
        break if (bx == "Run") or (bx == "Cancel")
    cap_colors = {}
    for k = 1, #inter do table.insert(cap_colors, ck["color#{k}"])
    for k = 1, #cap_colors do cap_colors[k] = zf.util\html_color(cap_colors[k])
    SAVECONFIG(inter, ck) if (bx != "Cancel") and (bx != "Reset") and (ck.sv == true)
    if bx == "Run"
        aegisub.progress.task("Generating Gradient...")
        for _, i in ipairs(sel)
            aegisub.progress.set((i - 1) / #sel * 100)
            l = subs[i + add]
            l.comment = true
            subs[i + add] = l
            if ck.act == true
                subs.delete(i + add)
                add -= 1
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            tags = zf.tags(l.text)\remove("shape_gradient")
            tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            detect = zf.tags\remove("full", l.text)
            shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
            shape = zf.poly\unclip(zf.text\to_clip(l, detect), l.styleref.align) unless shape
            shape = zf.poly\org_points(shape, l.styleref.align)
            cuts = make_cuts(shape, ck.px, coords.pos.x, coords.pos.y, ck.mode\lower!)
            line = table.copy(l)
            for k = 1, #cuts
                line.comment = false
                colors = "\\c#{zf.util\interpolation((k - 1) / (#cuts - 1), "color", cap_colors)}"
                __tags = zf.tags\clean("{#{tags .. colors}}")
                line.text = "#{__tags}#{cuts[k]}"
                subs.insert(i + add + 1, line)
                add += 1
        aegisub.progress.set(100)
    return

aegisub.register_macro script_name, script_description, gradient
return
