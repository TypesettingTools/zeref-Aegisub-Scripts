export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "1.2.0"
-- LIB
zf = require "ZF.utils"

local *

macros_list = {
    "Shape to Clip", "Clip to Shape", "Shape Origin", "Shape Poly", "Shape Expand"
    "Shape Smooth", "Shape Simplify", "Shape Split", "Shape Merge", "Shape Move"
    "Shape Round", "Shape Clipper", "Text to Clip", "Text to Shape"
}

m_c = {
    shape_simplify: {
        "Line Only", "Line and Bezier"
    }
    shape_split: {
        "Full", "Line Only", "Bezier Only"
    }
}

interfaces = {
    main: {
        {class: "label", label: ":Modes List:", x: 0, y: 0}
        {class: "dropdown", name: "modes", items: macros_list, x: 0, y: 1, value: macros_list[1]}
        {class: "label", label: ":Tolerance:", x: 0, y: 2}
        {class: "floatedit", name: "tol", x: 0, y: 3, value: 1}
        {class: "label", label: ":X - Axis:", x: 4, y: 0}
        {class: "floatedit", name: "px", x: 4, y: 1, value: 0}
        {class: "label", label: ":Y - Axis:", x: 4, y: 2}
        {class: "floatedit", name: "py", x: 4, y: 3, value: 0}
    }
    config: {
        {class: "label", label: ":Simplify Mode:", x: 0, y: 0}
        {class: "dropdown", name: "sym", items: m_c.shape_simplify, x: 0, y: 1, width: 3, value: m_c.shape_simplify[1]}
        {class: "label", label: ":Split Mode:", x: 0, y: 2}
        {class: "dropdown", name: "spm", items: m_c.shape_split, x: 0, y: 3, width: 3, value: m_c.shape_split[1]}
        {class: "checkbox", name: "rfl", label: "Remove first line?\t\t", x: 0, y: 4, value: true}
    }
}

SAVECONFIG = (subs, sel, gui, elements) ->
    ngui = table.copy(gui)
    vals_write = "EVERYTHING SHAPE - VERSION #{script_version}\n\n"
    ngui[2].value = elements.sym
    ngui[4].value = elements.spm
    ngui[5].value = elements.rfl
    for k, v in ipairs ngui
        vals_write ..= "{#{v.name} = #{v.value}}\n" if v.name
    dir = aegisub.decode_path("?user")
    unless zf.util\file_exist("#{dir}\\zeref-cfg", true)
        os.execute("mkdir #{dir .. "\\zeref-cfg"}") -- create folder zeref-cfg
    cfg_save = "#{dir}\\zeref-cfg\\everything_shape.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!
    return

READCONFIG = (filename) ->
    SEPLINES = (val) ->
        sep_vals = {n: {}, v: {}}
        for k = 1, #val
            sep_vals.n[k] = val[k]\gsub "(.+) %= .+", (vls) ->
                return vls
            rec_names = sep_vals.n[k]
            sep_vals.v[rec_names] = val[k]\gsub ".+ %= (.+)", (vls) ->
                return vls
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

LOADCONFIG = (gui, cfg) ->
    load_config = "#{aegisub.decode_path("?user")}\\zeref-cfg\\everything_shape.cfg"
    read_config, rdn = READCONFIG load_config
    new_gui = table.copy(not gui and interfaces.config or gui)
    if rdn != false
        new_gui[2].value = read_config.v.sym
        new_gui[4].value = read_config.v.spm
        new_gui[5].value = (read_config.v.rfl == "true" and true or false)
    return {sym: new_gui[2].value, spm: new_gui[4].value, rfl: new_gui[5].value} if cfg
    return new_gui

configure_macros = (subs, sel) ->
    button, elements = aegisub.dialog.display(LOADCONFIG(interfaces.config), {"Save", "Back"})
    SAVECONFIG(subs, sel, interfaces.config, elements) if button == "Save"
    main(subs, sel)
    return

merge_shapes = (subs, sel) ->
    mg = {shapes: {}, an: {}, pos: {}, result: {}}
    line = {}
    for _, i in ipairs(sel)
        l = subs[i]
        l.comment = true
        line = table.copy(l)
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        detect = zf.tags\remove("full", l.text)
        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
        if shape
            table.insert(mg.an, l.styleref.align)
            table.insert(mg.pos, coords.pos)
            table.insert(mg.shapes, shape)
        else
            error("shape expected")
    mg.final = ""
    for k = 1, #mg.shapes
        mg.result[k] = zf.poly\to_clip(mg.shapes[k], mg.an[k], mg.pos[k].x, mg.pos[k].y)
        mg.final ..= mg.result[k]
    mg.final = zf.poly\simplify(zf.poly\unclip(mg.final, mg.an[1], mg.pos[1].x, mg.pos[1].y))
    return mg, line

main = (subs, sel) ->
    button, elements = aegisub.dialog.display(interfaces.main, {"Run", "Configure", "Exit"})
    config, add = LOADCONFIG(nil, true), 0
    aegisub.progress.task("Generating...")
    switch button
        when "Exit"
            aegisub.cancel!
        when "Configure"
            configure_macros(subs, sel)
        when "Run"
            for _, i in ipairs(sel)
                aegisub.progress.set((i - 1) / #sel * 100)
                l = subs[i + add]
                l.comment = true
                subs[i + add] = l
                if config.rfl == true
                    if (elements.modes != macros_list[9])
                        subs.delete(i + add)
                        add -= 1
                meta, styles = zf.util\tags2styles(subs, l)
                karaskel.preproc_line(subs, meta, styles, l)
                coords = zf.util\find_coords(l, meta)
                detect = zf.tags\remove("full", l.text)
                px, py = coords.pos.x, coords.pos.y
                switch elements.modes
                    when macros_list[1]
                        tags = zf.tags(l.text)\remove("shape_clip")
                        icp_cp = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_to_clip = "#{icp_cp}(#{zf.poly\to_clip(shape, l.styleref.align, px, py)})"
                            __tags = zf.tags\clean("{#{tags .. shape_to_clip}}")
                            l.text = "#{__tags}#{shape}"
                        else
                            error("shape expected")
                    when macros_list[2]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        clip = tags\match "\\i?clip%b()"
                        if clip
                            tags = tags\gsub "\\i?clip%b()", ""
                            clip_to_shape = zf.poly\unclip(clip, l.styleref.align, px, py)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{clip_to_shape}"
                        else
                            error("clip expected")
                    when macros_list[3]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_origin, nx, ny = zf.poly\origin(shape, true)
                            if tags\match("\\pos%b()")
                                tags = tags\gsub "\\pos%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)%)", (x, y) ->
                                    x += nx
                                    y += ny
                                    "\\pos(#{x},#{y})"
                            elseif tags\match "\\move%b()"
                                tags = tags\gsub "\\move%((%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*),(%-?%d+[%.%d+]*)", (x1, y1, x2, y2) ->
                                    x1 += nx
                                    y1 += ny
                                    x2 += nx
                                    y2 += ny
                                    "\\move(#{x1},#{y1},#{x2},#{y2}"
                            else
                                tags ..= "\\pos(#{px + nx},#{py + ny})"
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_origin}"
                        else
                            error("shape expected")
                    when macros_list[4]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_poly = zf.poly\org_points(shape, l.styleref.align)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_poly}"
                        else
                            error("shape expected")
                    when macros_list[5]
                        tags = zf.tags(l.text)\remove("shape_expand")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_expand = zf.poly\expand(shape, l, meta)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_expand}"
                        else
                            error("shape expected")
                    when macros_list[6]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape = zf.poly\org_points(shape, l.styleref.align)
                            shape_smooth_edges = zf.poly\smooth_edges(shape, elements.tol)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_smooth_edges}"
                        else
                            error("shape expected")
                    when macros_list[7]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape = zf.poly\org_points(shape, l.styleref.align)
                            n = elements.tol
                            shape_simplify = (config.sym == "Line Only") and zf.poly\simplify(shape, nil, (n > 50) and 50 or n) or zf.poly\simplify(shape, true, n)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_simplify}"
                        else
                            error("shape expected")
                    when macros_list[8]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape = zf.poly\org_points(shape, l.styleref.align)
                            shape_split = switch config.spm
                                when "Full"        then zf.shape(shape)\redraw(elements.tol).code
                                when "Line Only"   then zf.shape(shape)\redraw(elements.tol, "line").code
                                when "Bezier Only" then zf.shape(shape)\redraw(elements.tol, "bezier").code
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_split}"
                        else
                            error("shape expected")
                    when macros_list[10]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_move = zf.poly\displace(shape, elements.px, elements.py)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_move}"
                        else
                            error("shape expected")
                    when macros_list[11]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        if shape
                            shape_round = zf.poly\round(shape, elements.tol)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_round}"
                        else
                            error("shape expected")
                    when macros_list[12]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*") or error("shape expected")
                        clip = tags\match("\\i?clip%b()") or error("clip expected")
                        tags = tags\gsub("\\i?clip%b()", "")
                        shape_clip = zf.poly\clip(zf.poly\org_points(shape, l.styleref.align), zf.util\clip_to_draw(clip), px, py, clip\match "iclip")
                        __tags = zf.tags\clean("{#{tags}}")
                        l.text = "#{__tags}#{shape_clip}" if shape_clip != ""
                    when macros_list[13]
                        tags = zf.tags(l.text)\remove("text_clip")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        icp_cp = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                        if text != " " or text != text\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                            text_clip = zf.text\to_clip(l, text, l.styleref.align, coords.pos.x, coords.pos.y)
                            clip = "#{icp_cp}(#{text_clip})"
                            __tags = zf.tags\clean("{#{tags .. clip}}")
                            l.text = "#{__tags}#{text}"
                        else
                            error("text expected")
                    when macros_list[14]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        if text != " " or text != text\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                            text_shape = zf.poly\unclip(zf.text\to_clip(l, text), l.styleref.align)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{text_shape}"
                        else
                            error("text expected")
                if (elements.modes != macros_list[9])
                    l.comment = false
                    subs.insert(i + add + 1, l)
                    add += 1
            if (elements.modes == macros_list[9])
                info, line = merge_shapes(subs, sel)
                line.comment = false
                tags = zf.tags(subs[sel[1]].text)\remove("shape")
                tags ..= "\\pos(#{info.pos[1].x},#{info.pos[1].y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                __tags = zf.tags\clean("{#{tags}}")
                line.text = "#{__tags}#{info.final}"
                subs.insert(sel[#sel] + 1, line)
            aegisub.progress.set(100)
    return

aegisub.register_macro script_name, script_description, main
return
