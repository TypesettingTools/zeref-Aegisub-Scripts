export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "0.0.3"
-- LIB
zf = require "ZF.main"

m_list = {
    ["stc"]: "Shape to Clip",   ["cts"]: "Clip to Shape", ["son"]: "Shape Origin"
    ["spy"]: "Shape Poly",      ["sed"]: "Shape Expand",  ["ssh"]: "Shape Smooth"
    ["ssy"]: "Shape Simplify",  ["sst"]: "Shape Split",   ["sme"]: "Shape Merge"
    ["smv"]: "Shape Move",      ["srd"]: "Shape Round",   ["scr"]: "Shape Clipper"
    ["srr"]: "Shape Relocator", ["ttc"]: "Text to Clip",  ["tts"]: "Text to Shape"
}

-- merges the selected shapes
merge_shapes = (subs, sel, simp) ->
    mg, line = {shapes: {}, pos: {}, an: {}}, nil
    aegisub.progress.task "Merging..."
    for _, i in ipairs sel
        aegisub.progress.set i / #sel * 100
        l = subs[i]
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
    mg.result = zf.poly(zf.shape(mg.result)\unclip(mg.an[1], mg.pos[1].x, mg.pos[1].y)\org_points(mg.an[1]))\simplify!
    mg.result.smp = simp
    mg.result = simp == "full" and mg.result\build(nil, nil, 3) or mg.result\build(nil, nil, 1)
    return mg, line

-- gets the information from the selected shapes
indexed_shapes = (subs, sel) ->
    index_r, index_p = {}, {}
    relocator = (shape) ->
        shape, nx, ny = zf.shape(shape)\origin(true)
        shape\info!
        index_p[#index_p + 1] = {x: nx, y: ny, w: shape.w_shape, h: shape.h_shape, a: nx + ny}
        return shape\build!, nx, ny
    -- organizes the table from the area of the shape
    table.sort(index_p, (a, b) -> a.a < b.a) if index_p[1] != nil
    for _, i in ipairs sel
        aegisub.progress.set i / #sel * 100
        l = subs[i]
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        detect = zf.tags\remove("full", l.text)
        assert detect\match("m%s+%-?%d[%.%-%d mlb]*"), "shape expected"
        shape, nx, ny = relocator(detect)
        index_r[#index_r + 1] = {:shape, :nx, :ny}
    return index_r, index_p

main = (subs, sel) ->
    inter, j = zf.config\load(zf.config\interface(script_name)(m_list), script_name), 0
    local buttons, elements, index_r, index_p, r_inf
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                zf.config\interface(script_name)(m_list)
        break if buttons == "Ok" or buttons == "Cancel"
    -- sets up for a better output
    help = (text, detect, remove_type, px, py, clip) ->
        tags = zf.tags(text)\remove(remove_type)
        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
        tags = zf.tags\clean("{#{tags}}")
        shape = assert detect\match("m%s+%-?%d[%.%-%d mlb]*"), "shape expected" unless clip
        return shape, tags
    switch buttons
        when "Ok"
            aegisub.progress.task "Processing..."
            simp = elements.smp == false and "line" or "full"
            if elements.modes == m_list["srr"]
                index_r, index_p = indexed_shapes(subs, sel)
                r_inf = {["sh"]: {}, ["1c"]: {}, ["2c"]: {}, ["3c"]: {}, ["4c"]: {}}
            if elements.modes == m_list["sme"]
                info, line = merge_shapes(subs, sel, simp, del)
                shape, tags = help(subs[sel[1]].text, info.result, "shape_poly", info.pos[1].x, info.pos[1].y)
                n = sel[#sel]
                for _, i in ipairs sel
                    l = subs[i + j]
                    l.comment = true
                    subs[i + j] = l
                    if elements.rfl == true
                        subs.delete(i + j)
                        j -= 1
                        n -= 1
                line.comment = false
                line.text = "#{tags}#{shape}"
                subs.insert(n + 1, line)
            else
                for _, i in ipairs sel
                    aegisub.progress.set i / #sel * 100
                    l = subs[i + j]
                    l.comment = true
                    -- sets up the entire input structure
                    meta, styles = zf.util\tags2styles(subs, l)
                    karaskel.preproc_line(subs, meta, styles, l)
                    coords = zf.util\find_coords(l, meta, true)
                    --
                    shape = zf.util\clip_to_draw(l.text)
                    detect = zf.tags\remove("full", l.text)
                    px, py = coords.pos.x, coords.pos.y
                    --
                    line = zf.table(l)\copy!
                    subs[i + j] = l
                    -- deletes the selected lines if true
                    if elements.rfl == true
                        subs.delete(i + j)
                        j -= 1
                    line.comment = false
                    switch elements.modes
                        when m_list["stc"]
                            shape, tags = help(line.text, detect, "shape_clip", px, py)
                            icp_cp = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                            shape_to_clip = ("#{icp_cp}(#{zf.shape(shape)\to_clip(line.styleref.align, px, py)\build!\gsub("^%s*(.-)%s*$", "%1")})")
                            line.text = "#{tags\gsub("%}", shape_to_clip .. "}")}#{shape}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["cts"]
                            shape, tags = help(line.text, detect, "shape", px, py, true)
                            clip = assert tags\match("\\i?clip%b()"), "clip expected"
                            clip_to_shape = zf.shape(clip)\unclip(line.styleref.align, px, py)\build!
                            line.text = "#{tags\gsub("\\i?clip%b()", "")}#{clip_to_shape}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["son"]
                            shape, tags = help(line.text, detect, "shape", px, py)
                            shape_origin, nx, ny = zf.shape(shape)\origin(true)
                            if tags\match("\\pos%b()")
                                tags = tags\gsub "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)", (x, y) ->
                                    return "\\pos(#{x + nx},#{y + ny}"
                            elseif tags\match "\\move%b()"
                                tags = tags\gsub "\\move%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)", (x1, y1, x2, y2) ->
                                    return "\\move(#{x1 + nx},#{y1 + ny},#{x2 + nx},#{y2 + ny}"
                            line.text = "#{tags}#{shape_origin\build!}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["spy"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            shape_poly = zf.shape(shape)\org_points(line.styleref.align)\build!
                            line.text = "#{tags}#{shape_poly}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["sed"]
                            shape, tags = help(line.text, detect, "shape_expand", px, py)
                            shape_expand = zf.shape(shape)\expand(line, meta)\build!
                            line.text = "#{tags}#{shape_expand}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["ssh"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            shape_smooth = zf.shape(shape, false)\org_points(line.styleref.align)\smooth_edges(elements.tol)\build!
                            line.text = "#{tags}#{shape_smooth}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["ssy"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            shape = zf.poly(zf.shape(shape)\org_points(line.styleref.align))\simplify!
                            local shape_simplify
                            if elements.sym == "Line Only"
                                shape.smp = "line"
                                shape_simplify = shape\build(nil, nil, elements.tol > 50 and 50 or elements.tol)
                            else
                                shape.smp = "full"
                                shape_simplify = shape\build(nil, nil, elements.tol)
                            line.text = "#{tags}#{shape_simplify}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["sst"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            shape = zf.shape(shape)\org_points(line.styleref.align)
                            shape_split = switch elements.spm
                                when "Full"        then shape\split(elements.tol)\build!
                                when "Line Only"   then shape\split(elements.tol, "line")\build!
                                when "Bezier Only" then shape\split(elements.tol, "bezier")\build!
                            line.text = "#{tags}#{shape_split}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["smv"]
                            shape, tags = help(line.text, detect, "shape", px, py)
                            shape_move = zf.shape(shape)\displace(elements.px, elements.py)\build!
                            line.text = "#{tags}#{shape_move}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["srd"]
                            shape, tags = help(line.text, detect, "shape", px, py)
                            shape_round = zf.shape(shape)\build(elements.tol)
                            line.text = "#{tags}#{shape_round}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["scr"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            clip = assert tags\match("\\i?clip%b()"), "clip expected"
                            tags = tags\gsub "\\i?clip%b()", ""
                            clip_fixed = zf.shape(zf.util\clip_to_draw(clip))\displace(-px, -py)
                            shape_clip = zf.poly(zf.shape(shape)\org_points(line.styleref.align), clip_fixed, elements.smp)\clip(clip\match("iclip"))
                            shape_clip.smp = simp
                            shape_clip = simp == "full" and shape_clip\build(nil, nil, 3) or shape_clip\build(nil, nil, 1)
                            line.text = "#{tags}#{shape_clip}" if shape_clip != ""
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["srr"]
                            shape, tags = help(line.text, detect, "shape_poly", px, py)
                            px, py = (index_r[_].nx - index_p[1].x), (index_r[_].ny - index_p[1].y)
                            px, py = switch elements.tol
                                when 1 then px, py - index_p[1].h
                                when 2 then px - index_p[1].w / 2, py - index_p[1].h
                                when 3 then px - index_p[1].w, py - index_p[1].h
                                when 4 then px, py - index_p[1].h / 2
                                when 5 then px - index_p[1].w / 2, py - index_p[1].h / 2
                                when 6 then px - index_p[1].w, py - index_p[1].h / 2
                                when 8 then px - index_p[1].w / 2, py
                                when 9 then px - index_p[1].w, py
                                else px, py
                            shape = zf.shape(index_r[_].shape)\displace(px, py)\build!
                            tags = tags\gsub("\\pos%b()", "\\pos(0,0)")\gsub("\\move%b()", "\\pos(0,0)")
                            r_inf["sh"][#r_inf["sh"] + 1] = shape
                            r_inf["1c"][#r_inf["1c"] + 1] = color_from_style(line.styleref.color1)
                            r_inf["2c"][#r_inf["2c"] + 1] = color_from_style(line.styleref.color2)
                            r_inf["3c"][#r_inf["3c"] + 1] = color_from_style(line.styleref.color3)
                            r_inf["4c"][#r_inf["4c"] + 1] = color_from_style(line.styleref.color4)
                            -- shows the shapes values and their respective colors in a table
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
                            --
                            line.text = "#{tags}#{shape}"
                            subs.insert(i + j + 1, line)
                            j += 1
                        when m_list["tts"]
                            tags = zf.text(subs, line, line.text)\tags!
                            for t, tag in ipairs tags
                                __tags = zf.tags(tag.text)\remove("text_shape")
                                assert not detect\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"

                                px, py, org = zf.text\org_pos(coords, tag, line)
                                text_shape = zf.shape(zf.text(subs, tag, tag.text_stripped)\to_clip!)\unclip(tag.styleref.align)\build!

                                tag.text = "#{zf.tags\clean("{\\pos(#{px},#{py})#{org .. __tags}}")}#{text_shape}"
                                subs.insert(i + j + 1, tag)
                                j += 1
                        when m_list["ttc"]
                            tags = zf.text(subs, line, line.text)\tags!
                            for t, tag in ipairs tags
                                cp_tag = line.text\match("\\iclip") and "\\iclip" or "\\clip"
                                __tags = zf.tags(tag.text)\remove("text_clip")
                                assert not detect\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"

                                px, py, org = zf.text\org_pos(coords, tag, line)
                                text_clip = zf.text(subs, tag, tag.text_stripped)\to_clip(line.styleref.align, px, py)
                                __tags ..= "#{org}\\pos(#{px},#{py})#{cp_tag}(#{text_clip})"

                                tag.text = "#{zf.tags\clean("{#{__tags}}")}#{tag.text_stripped}"
                                subs.insert(i + j + 1, tag)
                                j += 1

aegisub.register_macro script_name, script_description, main