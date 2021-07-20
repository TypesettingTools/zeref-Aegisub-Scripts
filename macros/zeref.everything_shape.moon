export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "0.0.3"
-- LIB
zf = require "ZF.utils"

m_list = {
    ["stc"]: "Shape to Clip",   ["cts"]: "Clip to Shape", ["son"]: "Shape Origin"
    ["spy"]: "Shape Poly",      ["sed"]: "Shape Expand",  ["ssh"]: "Shape Smooth"
    ["ssy"]: "Shape Simplify",  ["sst"]: "Shape Split",   ["sme"]: "Shape Merge"
    ["smv"]: "Shape Move",      ["srd"]: "Shape Round",   ["scr"]: "Shape Clipper"
    ["srr"]: "Shape Relocator", ["ttc"]: "Text to Clip",  ["tts"]: "Text to Shape"
}

interface = ->
    -- get modes
    modes_list = [v for k, v in pairs m_list]
    table.sort(modes_list)
    --
    simplify_list = {"Line Only", "Line and Bezier"}
    split_list = {"Full", "Line Only", "Bezier Only"}
    {
        {class: "label", label: "Mode List:", x: 0, y: 0}
        {class: "dropdown", name: "modes", items: modes_list, x: 0, y: 1, value: modes_list[1]}
        {class: "label", label: "Tolerance:", x: 0, y: 2}
        {class: "floatedit", name: "tol", x: 0, y: 3, value: 1}
        {class: "label", label: "X - Axis:", x: 1, y: 0}
        {class: "floatedit", name: "px", width: 4, x: 1, y: 1, value: 0}
        {class: "label", label: "Y - Axis:", x: 1, y: 2}
        {class: "floatedit", name: "py", width: 4, x: 1, y: 3, value: 0}
        {class: "label", label: "Simplify Modes:", x: 0, y: 4}
        {class: "dropdown", name: "sym", items: simplify_list, x: 0, y: 5, value: simplify_list[2]}
        {class: "label", label: "Split Modes:", x: 1, y: 4}
        {class: "dropdown", name: "spm", items: split_list, width: 4, x: 1, y: 5, value: split_list[1]}
        {class: "checkbox", name: "rfl", label: "Remove selected layers?", x: 0, y: 6, value: true}
        {class: "checkbox", name: "smp", label: "Simplify?   ", x: 1, y: 6, value: true}
    }

merge_shapes = (subs, sel) ->
    mg, line = {shapes: {}, pos: {}, an: {}}, nil
    for k, v in ipairs(sel)
        l = subs[v]
        l.comment = true
        line = zf.table(l)\copy!
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        detect = zf.tags\remove("full", l.text)
        shape = assert detect\match("m%s+%-?%d[%.%-%d mlb]*"), "shape expected"
        table.insert(mg.shapes, shape)
        table.insert(mg.pos, coords.pos)
        table.insert(mg.an, l.styleref.align)
    mg.result = ""
    for k = 1, #mg.shapes
        mg.result ..= zf.shape(mg.shapes[k])\to_clip(mg.an[k], mg.pos[k].x, mg.pos[k].y)\build!
    mg.result = zf.poly\simplify(zf.shape(mg.result)\unclip(mg.an[1], mg.pos[1].x, mg.pos[1].y)\org_points(mg.an[1])\build!, true, 3)
    return mg, line

shape_relocator = (subs, sel) ->
    index_r, index_p = {}, {}
    relocator = (shape) ->
        shape, nx, ny = zf.shape(shape)\origin(true)
        shape\info!
        index_p[#index_p + 1] = {x: nx, y: ny, w: w_shape, h: h_shape, a: nx + ny}
        return shape\build!, nx, ny
    -- organizes the table from the area of the shape
    table.sort(index_p, (a, b) -> a.a < b.a) if index_p[1] != nil
    for k, v in ipairs sel
        l = subs[v]
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        detect = zf.tags\remove("full", l.text)
        shape = assert detect\match("m%s+%-?%d[%.%-%d mlb]*"), "shape expected"
        shape, nx, ny = relocator(shape)
        index_r[#index_r + 1] = {shape: shape, nx: nx, ny: ny}
    return index_r, index_p

main = (subs, sel) ->
    inter, j = zf.config\load(interface!, script_name), 0
    local buttons, elements, index_r, index_p, r_inf
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                interface!
        break if buttons == "Ok" or buttons == "Cancel"
    help = (text, detect, remove_type, px, py, clip) -> -- l.text
        tags = zf.tags(text)\remove(remove_type)
        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        tags = zf.tags\clean("{#{tags}}")
        shape = assert detect\match("m%s+%-?%d[%.%-%d mlb]*"), "shape expected" unless clip
        return shape, tags
    aegisub.progress.task("Generating...")
    switch buttons
        when "Ok"
            if elements.modes == "Shape Relocator"
                index_r, index_p = shape_relocator(subs, sel)
                r_inf = {["sh"]: {}, ["1c"]: {}, ["2c"]: {}, ["3c"]: {}, ["4c"]: {}}
            for k, i in ipairs(sel)
                aegisub.progress.set((i - 1) / #sel * 100)
                l = subs[i + j]
                l.comment = true
                subs[i + j] = l
                if elements.rfl == true
                    if elements.modes != m_list["sme"]
                        subs.delete(i + j)
                        j -= 1
                meta, styles = zf.util\tags2styles(subs, l)
                karaskel.preproc_line(subs, meta, styles, l)
                coords = zf.util\find_coords(l, meta)
                detect = zf.tags\remove("full", l.text)
                px, py = coords.pos.x, coords.pos.y
                switch elements.modes
                    when m_list["stc"]
                        shape, tags = help(l.text, detect, "shape_clip", px, py)
                        icp_cp = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                        shape_to_clip = ("#{icp_cp}(#{zf.shape(shape)\to_clip(l.styleref.align, px, py)\build!\gsub("^%s*(.-)%s*$", "%1")})")
                        l.text = "#{tags\gsub("%}", shape_to_clip .. "}")}#{shape}"
                    when m_list["cts"]
                        shape, tags = help(l.text, detect, "shape", px, py, true)
                        clip = assert tags\match("\\i?clip%b()"), "clip expected"
                        clip_to_shape = zf.shape(clip)\unclip(l.styleref.align, px, py)\build!
                        l.text = "#{tags\gsub("\\i?clip%b()", "")}#{clip_to_shape}"
                    when m_list["son"]
                        shape, tags = help(l.text, detect, "shape", px, py)
                        shape_origin, nx, ny = zf.shape(shape)\origin(true)
                        if tags\match("\\pos%b()")
                            tags = tags\gsub "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)", (x, y) ->
                                return "\\pos(#{x + nx},#{y + ny}"
                        elseif tags\match "\\move%b()"
                            tags = tags\gsub "\\move%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)", (x1, y1, x2, y2) ->
                                return "\\move(#{x1 + nx},#{y1 + ny},#{x2 + nx},#{y2 + ny}"
                        l.text = "#{tags}#{shape_origin\build!}"
                    when m_list["spy"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        shape_poly = zf.shape(shape)\org_points(l.styleref.align)\build!
                        l.text = "#{tags}#{shape_poly}"
                    when m_list["sed"]
                        shape, tags = help(l.text, detect, "shape_expand", px, py)
                        shape_expand = zf.shape(shape)\expand(l, meta)\build!
                        l.text = "#{tags}#{shape_expand}"
                    when m_list["ssh"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        shape_smooth = zf.shape(shape, false)\org_points(l.styleref.align)\smooth_edges(elements.tol)\build!
                        l.text = "#{tags}#{shape_smooth}"
                    when m_list["ssy"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        shape = zf.shape(shape)\org_points(l.styleref.align)\build!
                        shape_simplify = (elements.sym == "Line Only") and zf.poly\simplify(shape, nil, elements.tol > 50 and 50 or elements.tol) or zf.poly\simplify(shape, true, elements.tol)
                        l.text = "#{tags}#{shape_simplify}"
                    when m_list["sst"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        shape = zf.shape(shape)\org_points(l.styleref.align)
                        shape_split = switch elements.spm
                            when "Full"        then shape\split(elements.tol)\build!
                            when "Line Only"   then shape\split(elements.tol, "line")\build!
                            when "Bezier Only" then shape\split(elements.tol, "bezier")\build!
                        l.text = "#{tags}#{shape_split}"
                    when m_list["smv"]
                        shape, tags = help(l.text, detect, "shape", px, py)
                        shape_move = zf.shape(shape)\displace(elements.px, elements.py)\build!
                        l.text = "#{tags}#{shape_move}"
                    when m_list["srd"]
                        shape, tags = help(l.text, detect, "shape", px, py)
                        shape_round = zf.shape(shape)\build(nil, elements.tol)
                        l.text = "#{tags}#{shape_round}"
                    when m_list["scr"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        clip = assert tags\match("\\i?clip%b()"), "clip expected"
                        tags = tags\gsub "\\i?clip%b()", ""
                        shape_clip = zf.poly\clip(zf.shape(shape)\org_points(l.styleref.align)\build!, zf.util\clip_to_draw(clip), px, py, clip\match("iclip"), elements.smp)
                        l.text = "#{tags}#{shape_clip}" if shape_clip != ""
                    when m_list["srr"]
                        shape, tags = help(l.text, detect, "shape_poly", px, py)
                        px, py = (index_r[k].nx - index_p[1].x), (index_r[k].ny - index_p[1].y)
                        switch elements.tol
                            when 1
                                px = px
                                py -= index_p[1].h
                            when 2
                                px -= index_p[1].w / 2
                                py -= index_p[1].h
                            when 3
                                px -= index_p[1].w
                                py -= index_p[1].h
                            when 4
                                px = px
                                py -= index_p[1].h / 2
                            when 5
                                px -= index_p[1].w / 2
                                py -= index_p[1].h / 2
                            when 6
                                px -= index_p[1].w
                                py -= index_p[1].h / 2
                            when 8
                                px -= index_p[1].w / 2
                                py = py
                            when 9
                                px -= index_p[1].w
                                py = py
                            else
                                error "align value expected"
                        shape = zf.shape(index_r[k].shape)\displace(px, py)\build!
                        tags = tags\gsub("\\pos%b()", "\\pos(0,0)")\gsub("\\move%b()", "\\pos(0,0)")
                        r_inf["sh"][#r_inf["sh"] + 1] = shape
                        r_inf["1c"][#r_inf["1c"] + 1] = color_from_style(l.styleref.color1)
                        r_inf["2c"][#r_inf["2c"] + 1] = color_from_style(l.styleref.color2)
                        r_inf["3c"][#r_inf["3c"] + 1] = color_from_style(l.styleref.color3)
                        r_inf["4c"][#r_inf["4c"] + 1] = color_from_style(l.styleref.color4)
                        l.text = "#{tags}#{shape}"
                    when m_list["ttc"]
                        tags = zf.tags(l.text)\remove("text_clip")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        ctag = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                        assert not text\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"
                        text_clip = zf.text\to_clip(l, text, l.styleref.align, coords.pos.x, coords.pos.y)
                        clip = "#{ctag}(#{text_clip})"
                        __tags = zf.tags\clean("{#{tags .. clip}}")
                        l.text = "#{__tags}#{text}"
                    when m_list["tts"]
                        tags = zf.tags(l.text)\remove("text_shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        assert not text\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"
                        text_shape = zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build!
                        __tags = zf.tags\clean("{#{tags}}")
                        l.text = "#{__tags}#{text_shape}"
                if elements.modes != m_list["sme"]
                    l.comment = false
                    subs.insert(i + j + 1, l)
                    j += 1
            if elements.modes == m_list["sme"]
                info, line = merge_shapes(subs, sel)
                shape, tags = help(subs[sel[1]].text, info.result, "shape_poly", info.pos[1].x, info.pos[1].y)
                line.comment = false
                line.text = "#{tags}#{shape}"
                subs.insert(sel[#sel] + 1, line)
            elseif elements.modes == m_list["srr"]
                m_inf = (t) ->
                    v = ""
                    for k = 1, #t
                        v ..= "\"#{t[k]}\", "
                    return v\sub(1, -3)
                _sh = m_inf r_inf["sh"]
                _1c = m_inf r_inf["1c"]
                _2c = m_inf r_inf["2c"]
                _3c = m_inf r_inf["3c"]
                _4c = m_inf r_inf["4c"]
                aegisub.log("shapes = {#{_sh}}\nc1 = {#{_1c}}\nc2 = {#{_2c}}\nc3 = {#{_3c}}\nc4 = {#{_4c}}")
            aegisub.progress.set(100)
    return

aegisub.register_macro script_name, script_description, main