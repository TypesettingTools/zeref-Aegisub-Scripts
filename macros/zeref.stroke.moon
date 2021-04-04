export script_name = "Stroke Panel"
export script_description = "A stroke panel"
export script_author = "Zeref"
export script_version = "1.5.3"
-- LIB
zf = require "ZF.utils"

stroke = {}
stroke.corner = {
    "Miter"
    "Round"
    "Square"
}

stroke.align = {
    "Center"
    "Inside"
    "Outside"
}

hints = {}
hints.arctolerance = "The default ArcTolerance is 0.25 units. \nThis means that the maximum distance \nthe flattened path will deviate from the \n\"true\" arc will be no more than 0.25 units \n(before rounding)."
hints.stroke_size = "Stroke Size."
hints.miterlimit = "The default value for MiterLimit is 2 (ie twice delta). \nThis is also the smallest MiterLimit that's allowed. \nIf mitering was unrestricted (ie without any squaring), \nthen offsets at very acute angles would generate \nunacceptably long \"spikes\"."
hints.only_offset = "Return only the offseting text."

INTERFACE = (subs, sel) ->
    local gui
    for _, i in ipairs(sel)
        l = subs[i]
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        gui = {
            {class: "label", label: "Stroke Corner:", x: 0, y: 0},
            {class: "label", label: "Align Stroke:", x: 0, y: 3},
            {class: "label", label: "Stroke Weight:", x: 8, y: 0},
            {class: "label", label: "Miter Limit:", x: 8, y: 3},
            {class: "label", label: "Arc Tolerance:", x: 8, y: 6},
            {class: "label", label: "Primary Color:                ", x: 0, y: 9},
            {class: "label", label: "Stroke Color:                     ", x: 8, y: 9},
            {class: "dropdown", name: "crn", items: stroke.corner, x: 0, y: 1, width: 2, height: 2, value: stroke.corner[2]},
            {class: "dropdown", name: "alg", items: stroke.align, x: 0, y: 4, width: 2, height: 2, value: stroke.align[3]},
            {class: "floatedit", name: "ssz", x: 8, y: 1, width: 2, hint: hints.stroke_size, height: 2, value: l.styleref.outline},
            {class: "floatedit", name: "mtl", x: 8, y: 4, width: 2, hint: hints.miterlimit, height: 2, value: 2},
            {class: "floatedit", name: "atc", x: 8, y: 7, hint: hints.arctolerance, width: 2, height: 2, min: 0, value: 0.25},
            {class: "coloralpha", name: "color1", x: 0, y: 10, width: 1, height: 2, value: l.styleref.color1},
            {class: "coloralpha", name: "color3", x: 8, y: 10, width: 1, height: 2, value: l.styleref.color3},
            {class: "checkbox", label: "Remove first line?", name: "act", x: 0, y: 12, value: true},
            {class: "checkbox", label: "Only Offset?", name: "olf", x: 8, y: 12, hint: hints.only_offset, value: false}
        }
    return gui

SAVECONFIG = (subs, sel, gui, elements) ->
    ngui = table.copy(gui)
    vals_write = "STROKE CONFIG - VERSION #{script_version}\n\n"
    ngui[8].value, ngui[9].value = elements.crn, elements.alg
    ngui[11].value, ngui[12].value = elements.mtl, elements.atc
    ngui[15].value, ngui[16].value = elements.act, elements.olf
    for k, v in ipairs ngui
        if v.name == "crn" or v.name == "alg" or v.name == "mtl" or v.name == "atc" or v.name == "act" or v.name == "olf"
            vals_write ..= "{#{v.name} = #{v.value}}\n"
    dir = aegisub.decode_path("?user")
    unless zf.util\file_exist("#{dir}\\zeref-cfg", true)
        os.execute("mkdir #{dir .. "\\zeref-cfg"}") -- create folder zeref-cfg
    cfg_save = "#{dir}\\zeref-cfg\\stroke_config.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!
    -- aegisub.log "Your changes are saved in:\n\n#{cfg_save}"
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
            return SEPLINES(lines), true
    return _, false

LOADCONFIG = (gui) ->
    load_config = aegisub.decode_path("?user") .. "\\zeref-cfg\\stroke_config.cfg"
    read_config, rdn = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        new_gui[8].value = read_config.v.crn
        new_gui[9].value = read_config.v.alg
        new_gui[11].value = tonumber read_config.v.mtl
        new_gui[12].value = tonumber read_config.v.atc
        new_gui[15].value = (read_config.v.act == "true" and true or false)
        new_gui[16].value = (read_config.v.olf == "true" and true or false)
    return new_gui

stroke_panel = (subs, sel) ->
    inter, add = LOADCONFIG(INTERFACE(subs, sel)), 0
    local bx, ck
    while true
        bx, ck = aegisub.dialog.display(inter, {"Run", "Run - Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = INTERFACE(subs, sel) if bx == "Reset"
        break if bx == "Run" or bx == "Run - Save" or bx == "Cancel"
    aegisub.progress.task("Generating Stroke...")
    switch bx
        when "Run", "Run - Save"
            for _, i in ipairs sel
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
                tags = zf.tags(l.text)\remove("out")
                tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                detect = zf.tags\remove("full", l.text)
                shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                shape = zf.poly\unclip(zf.text\to_clip(l, detect), l.styleref.align) unless shape
                out_shape, out_offset = "", ""
                if ck.olf
                    out_shape = zf.poly\offset(zf.poly\org_points(shape, l.styleref.align), ck.ssz, ck.crn\lower!, nil, ck.mtl, ck.atc)
                    l.comment = false
                    __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(ck.color1)}}")
                    l.text = "#{__tags}#{out_shape}"
                    subs.insert(i + add + 1, l)
                    add += 1
                else
                    out_shape, out_offset = zf.poly\to_outline(zf.poly\org_points(shape, l.styleref.align), ck.ssz, ck.crn, ck.alg, ck.mtl, ck.atc)
                    colors = {ck.color3, ck.color1}
                    shapes = {out_shape, out_offset}
                    for k = 1, 2
                        l.comment = false
                        __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(colors[k])}}")
                        l.text = "#{__tags}#{shapes[k]}"
                        subs.insert(i + add + 1, l)
                        add += 1
            SAVECONFIG(subs, sel, inter, ck) if bx == "Run - Save"
            aegisub.progress.set(100)

aegisub.register_macro "Stroke Panel", script_description, stroke_panel
return
