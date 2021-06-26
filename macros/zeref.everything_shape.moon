export script_name        = "Everything Shape"
export script_description = "Do \"everything\" you need for a shape!"
export script_author      = "Zeref"
export script_version     = "0.0.1"
-- LIB
zf = require "ZF.utils"

local *

macros_list = {
    "Shape to Clip", "Clip to Shape", "Shape Origin", "Shape Poly", "Shape Expand"
    "Shape Smooth", "Shape Simplify", "Shape Split", "Shape Merge", "Shape Move"
    "Shape Round", "Shape Clipper", "Text to Clip", "Text to Shape"
}

m_c = {
    shape_simplify: {"Line Only", "Line and Bezier"}
    shape_split: {"Full", "Line Only", "Bezier Only"}
}

interfaces = {
    main: {
        {class: "label", label: "Mode List:", x: 0, y: 0}
        {class: "dropdown", name: "modes", items: macros_list, x: 0, y: 1, value: macros_list[1]}
        {class: "label", label: "Tolerance:", x: 0, y: 2}
        {class: "floatedit", name: "tol", x: 0, y: 3, value: 1}
        {class: "label", label: "X - Axis:", x: 1, y: 0}
        {class: "floatedit", name: "px", x: 1, y: 1, value: 0}
        {class: "label", label: "Y - Axis:", x: 1, y: 2}
        {class: "floatedit", name: "py", x: 1, y: 3, value: 0}
    }
    config: {
        {class: "label", label: "Simplify Modes:", x: 0, y: 0}
        {class: "dropdown", name: "sym", items: m_c.shape_simplify, x: 0, y: 1, value: m_c.shape_simplify[1]}
        {class: "label", label: "Split Modes:", x: 0, y: 2}
        {class: "dropdown", name: "spm", items: m_c.shape_split, x: 0, y: 3, value: m_c.shape_split[1]}
        {class: "checkbox", name: "rfl", label: "Remove selected layers?", x: 0, y: 4, value: true}
    }
}

configure_macros = (subs, sel) ->
    buttons, elements = aegisub.dialog.display(zf.config\load(interfaces.config, script_name), {"Save", "Back"})
    zf.config\save(interfaces.config, elements, script_name, script_version) if buttons == "Save"
    main(subs, sel)
    return

merge_shapes = (subs, sel) ->
    mg, line = {shapes: {}, an: {}, pos: {}, result: {}}, {}
    for _, i in ipairs(sel)
        l = subs[i]
        l.comment = true
        line = table.copy(l)
        meta, styles = zf.util\tags2styles(subs, l)
        karaskel.preproc_line(subs, meta, styles, l)
        coords = zf.util\find_coords(l, meta)
        detect = zf.tags\remove("full", l.text)
        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
        if shape
            table.insert(mg.an, l.styleref.align)
            table.insert(mg.pos, coords.pos)
            table.insert(mg.shapes, shape)
        else
            error("shape expected")
    mg.final = ""
    for k = 1, #mg.shapes
        mg.result[k] = zf.shape(mg.shapes[k])\to_clip(mg.an[k], mg.pos[k].x, mg.pos[k].y)\build!
        mg.final ..= mg.result[k]
    mg.final = zf.poly\simplify(zf.shape(mg.final)\unclip(mg.an[1], mg.pos[1].x, mg.pos[1].y)\build!, true, 3)
    return mg, line

main = (subs, sel) ->
    button, elements = aegisub.dialog.display(interfaces.main, {"Ok", "Configure", "Cancel"}, {close: "Cancel"})
    config, j = zf.config\load(interfaces.config, script_name), 0
    config = {sym: config[2].value, spm: config[4].value, rfl: config[5].value}
    aegisub.progress.task("Generating...")
    switch button
        when "Ok"
            for _, i in ipairs(sel)
                aegisub.progress.set((i - 1) / #sel * 100)
                l = subs[i + j]
                l.comment = true
                subs[i + j] = l
                if config.rfl == true
                    if (elements.modes != macros_list[9])
                        subs.delete(i + j)
                        j -= 1
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
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_to_clip = "#{icp_cp}(#{zf.shape(shape)\to_clip(l.styleref.align, px, py)\build!})"
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags\gsub("%}", shape_to_clip .. "}")}#{shape}"
                        else
                            error("shape expected")
                    when macros_list[2]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        clip = tags\match "\\i?clip%b()"
                        if clip
                            tags = tags\gsub "\\i?clip%b()", ""
                            clip_to_shape = zf.shape(clip)\unclip(l.styleref.align, px, py)\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{clip_to_shape}"
                        else
                            error("clip expected")
                    when macros_list[3]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_origin, nx, ny = zf.shape(shape)\origin(true)
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
                            l.text = "#{__tags}#{shape_origin\build!}"
                        else
                            error("shape expected")
                    when macros_list[4]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_poly = zf.shape(shape)\org_points(l.styleref.align)\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_poly}"
                        else
                            error("shape expected")
                    when macros_list[5]
                        tags = zf.tags(l.text)\remove("shape_expand")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_expand = zf.shape(shape)\expand(l, meta)\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_expand}"
                        else
                            error("shape expected")
                    when macros_list[6]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_smooth = zf.shape(shape, false)\org_points(l.styleref.align)\smooth_edges(elements.tol)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{zf.shape(shape_smooth)\build!}"
                        else
                            error("shape expected")
                    when macros_list[7]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape = zf.shape(shape)\org_points(l.styleref.align)\build!
                            n = elements.tol
                            shape_simplify = (config.sym == "Line Only") and zf.poly\simplify(shape, nil, (n > 50) and 50 or n) or zf.poly\simplify(shape, true, n)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_simplify}"
                        else
                            error("shape expected")
                    when macros_list[8]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape = zf.shape(shape)\org_points(l.styleref.align)
                            shape_split = switch config.spm
                                when "Full"        then shape\split(elements.tol)\build!
                                when "Line Only"   then shape\split(elements.tol, "line")\build!
                                when "Bezier Only" then shape\split(elements.tol, "bezier")\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_split}"
                        else
                            error("shape expected")
                    when macros_list[10]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_move = zf.shape(shape)\displace(elements.px, elements.py)\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_move}"
                        else
                            error("shape expected")
                    when macros_list[11]
                        tags = zf.tags(l.text)\remove("shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*")
                        if shape
                            shape_round = zf.shape(shape)\build(nil, elements.tol)
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{shape_round}"
                        else
                            error("shape expected")
                    when macros_list[12]
                        tags = zf.tags(l.text)\remove("shape_poly")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        shape = detect\match("m%s+%-?%d[%.%-%d mlb]*") or error("shape expected")
                        clip = tags\match("\\i?clip%b()") or error("clip expected")
                        tags = tags\gsub("\\i?clip%b()", "")
                        shape_clip = zf.poly\clip(zf.shape(shape)\org_points(l.styleref.align)\build!, zf.util\clip_to_draw(clip), px, py, clip\match "iclip")
                        __tags = zf.tags\clean("{#{tags}}")
                        l.text = "#{__tags}#{shape_clip}" if shape_clip != ""
                    when macros_list[13]
                        tags = zf.tags(l.text)\remove("text_clip")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        icp_cp = tags\match("\\i?clip") and tags\match("\\i?clip") or "\\clip"
                        if not text\match("m%s+%-?%d[%.%-%d mlb]*")
                            text_clip = zf.text\to_clip(l, text, l.styleref.align, coords.pos.x, coords.pos.y)
                            clip = "#{icp_cp}(#{text_clip})"
                            __tags = zf.tags\clean("{#{tags .. clip}}")
                            l.text = "#{__tags}#{text}"
                        else
                            error("text expected")
                    when macros_list[14]
                        tags = zf.tags(l.text)\remove("text_shape")
                        tags ..= "\\pos(#{px},#{py})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                        text = l.text\gsub("%b{}", "")\gsub("\\h", " ")
                        if not text\match("m%s+%-?%d[%.%-%d mlb]*")
                            text_shape = zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build!
                            __tags = zf.tags\clean("{#{tags}}")
                            l.text = "#{__tags}#{text_shape}"
                        else
                            error("text expected")
                if (elements.modes != macros_list[9])
                    l.comment = false
                    subs.insert(i + j + 1, l)
                    j += 1
            if (elements.modes == macros_list[9])
                info, line = merge_shapes(subs, sel)
                line.comment = false
                tags = zf.tags(subs[sel[1]].text)\remove("shape")
                tags ..= "\\pos(#{info.pos[1].x},#{info.pos[1].y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
                __tags = zf.tags\clean("{#{tags}}")
                line.text = "#{__tags}#{info.final}"
                subs.insert(sel[#sel] + 1, line)
            aegisub.progress.set(100)
        when "Configure"
            configure_macros(subs, sel)
    return

aegisub.register_macro script_name, script_description, main