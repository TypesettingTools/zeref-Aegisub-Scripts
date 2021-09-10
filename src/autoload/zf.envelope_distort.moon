export script_name        = "Envelope Distort"
export script_description = "Makes distortions in shapes by means of control points."
export script_author      = "Zeref"
export script_version     = "0.0.3"
-- LIB
zf = require "ZF.main"

-- splits a line into 2 segments
split = (t, x1, y1, x3, y3) ->
    x2 = x1 + t * (x3 - x1)
    y2 = y1 + t * (y3 - y1)
	return {typer: "l", x1, y1, x2, y2}, {typer: "l", x2, y2, x3, y3}

-- generates line segments
make_line = (path) ->
    for k = 2, #path
        table.insert(path[k], 1, path[k - 1][#path[k - 1] - 0])
        table.insert(path[k], 1, path[k - 1][#path[k - 1] - 1])
    return path

-- sorts the table according to the largest distance or smallest index
sort_distances = (path) ->
    info = {}
    for i = 1, #path
        p = path[i]
        x0, y0 = p[1], p[2]
        x1, y1 = p[3], p[4]
        d = zf.math\distance(x0, y0, x1 or x0, y1 or y0)
        info[i] = {:p, :d, :i}
    table.sort info, (a, b) -> (a.d == b.d) and a.i < b.i or a.d > b.d
    return info

-- recursive function that splits path until the maximum value is 0
local split_path
split_path = (path, max, addL) ->
    path = make_line(path) unless addL
    info = sort_distances(path)[1]
    if max > 0
        s0, s1 = split(0.5, info.p[1], info.p[2], info.p[3], info.p[4])
        zf.table(path)\splice(info.i, 1, s0, s1)
        -- recursive
        max -= 1
        return split_path(path, max, true)
    for k = 2, #path
        zf.table(path[k])\splice(1, 2)
    return path

-- divides a box imprecisely to the maximum value
split_box = (box, max) ->
    splited, diff, i = zf.shape(box, false).paths[1], 0, 1
    if max > 4
        splited = zf.shape(box)\split(i).paths[1]
        while #splited >= max
            splited = zf.shape(box)\split(i).paths[1]
            i += 1
        diff = max - #splited
    return splited, diff

-- https://math.stackexchange.com/questions/978642/how-to-sort-vertices-of-a-polygon-in-counter-clockwise-order
-- sorts the points clockwise
to_clockwise = (path) ->
    cx, cy = 0, 0
    for _, p in ipairs path
        cx += p[1]
        cy += p[2]
    cx, cy = cx / #path, cy / #path
    table.sort path, (a, b) ->
        a1 = (math.deg(math.atan2(a[1] - cx, a[2] - cy)) + 360) % 360
        a2 = (math.deg(math.atan2(b[1] - cx, b[2] - cy)) + 360) % 360
        return a1 < a2
    return path

-- transforms the points to the envelope_distort structure
make_mesh = (p0, p1, clockwise) ->
    if clockwise
        p0, p1 = to_clockwise(p0), to_clockwise(p1)
    mesh = [{} for k = 1, 2]
    for k = 1, #p0
        mesh[1][k] = {x: p0[k][1], y: p0[k][2]}
        mesh[2][k] = {x: p1[k][1], y: p1[k][2]}
    return unpack mesh

-- makes the distance between the points equal
sort_edges = (path, l, t, r, b) ->
    ipols_edge = (t) ->
        ipol = {}
        for k = 1, #t
            x = zf.util\interpolation((k - 1) / (#t - 1), "number", t[1][1], t[#t][1])
            y = zf.util\interpolation((k - 1) / (#t - 1), "number", t[1][2], t[#t][2])
            zf.table(ipol)\push({x, y, typer: "l"})
        return ipol
    edge, j = [{} for k = 1, 4], 1
    while j <= #path
        point = path[j]
        edge[1][#edge[1] + 1] = point
        j += 1
        break if point[1] == r and point[2] == t
    j -= 1
    while j <= #path
        point = path[j]
        edge[2][#edge[2] + 1] = point
        j += 1
        break if point[1] == r and point[2] == b
    j -= 1
    while j <= #path
        point = path[j]
        edge[3][#edge[3] + 1] = point
        j += 1
        break if point[1] == l and point[2] == b
    j -= 1
    while j <= #path
        point = path[j]
        edge[4][#edge[4] + 1] = point
        j += 1
        break if point[1] == l and point[2] == t
    for k = 1, 4
        unless (k == 4 and #edge[k] == 1)
            edge[k] = ipols_edge(edge[k])
        table.remove(edge[k]) if k < 4
    edge[1][1].typer = "m"
    return zf.table({})\concat(unpack(edge))

-- generates the inspection points
genr_mesh = (shape, size, bezier) ->
    box = zf.shape(shape)\bounding(true)
    box = size > 1 and zf.shape(box)\split(nil, "all", size) or zf.shape(box)
    zf.shape(box)\to_bezier! if bezier
    return box\build!

-- generates the output with the deformation
genr_warp = (shape, mesh, tolerance, clockwise, perspective) ->
    unless perspective
        -- get control
        control = zf.shape(mesh)\split(tolerance, "bezier").paths[1]
        assert #control > 3, "Expected 4 control points or more, got #{#control} points."
        -- get box
        box, l, t, r, b = zf.shape(shape)\bounding(true)
        box_splited, diff = split_box(box, #control)
        box_splited = split_path(box_splited, diff)
        box_splited = sort_edges(box_splited, l, t, r, b)
        -- get warp
        input, output = make_mesh(box_splited, control, clockwise)
        return zf.shape(shape)\envelope_distort(input, output)\build!
    else
        mesh = zf.shape(mesh).paths[1]
        assert #mesh == 5, "Expected 4 control points, got #{#mesh - 1} points."
        destin = {
            {x: mesh[1][1], y: mesh[1][2]}
            {x: mesh[2][1], y: mesh[2][2]}
            {x: mesh[3][1], y: mesh[3][2]}
            {x: mesh[4][1], y: mesh[4][2]}
        }
        return zf.shape(shape)\perspective(destin)\build!

main = (subs, sel) ->
    inter, j = zf.config\load(zf.config\interface(script_name)!, script_name), 0
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                zf.config\interface(script_name)!
        break if buttons == "Ok" or buttons == "Cancel"
    aegisub.progress.task "Processing..."
    if buttons == "Ok"
        for _, i in ipairs sel
            aegisub.progress.set i / #sel * 100
            l = subs[i + j]
            l.comment = true
            --
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta, true)
            px, py = coords.pos.x, coords.pos.y
            --
            line = zf.table(l)\copy!
            subs[i + j] = l
            if elements.rfl == true
                subs.delete(i + j)
                j -= 1
            --
            line.comment = false
            shape = zf.tags\remove("full", line.text)\match("m%s+%-?%d[%.%-%d mlb]*")
            _tags = zf.tags(zf.tags(line.text)\find!)\remove("shape_envelope")
            switch elements.gmw
                when "Mesh"
                    unless shape
                        for t, tag in ipairs zf.text(subs, line, line.text)\tags!
                            _tags = zf.tags(tag.text)\remove("text_envelope")
                            px, py, org = zf.text\org_pos(coords, tag, line)
                            shape = zf.shape(zf.text(subs, tag, tag.text_stripped)\to_clip!)\unclip(tag.styleref.align)\build!
                            shape = zf.shape(shape)\org_points(line.styleref.align)\build!
                            --
                            ctrl_pts = genr_mesh(shape, elements.siz, elements.tpc == "Bezier" and true or false)
                            ctrl_pts = "\\clip(#{zf.shape(ctrl_pts)\to_clip(7, px, py)\build(nil, 0)})"
                            --
                            _tags = zf.tags\clean("{\\pos(#{px},#{py})#{org .. _tags\gsub("\\i?clip%b()", "") .. ctrl_pts}}")
                            line.text = "#{_tags}#{shape}"
                            subs.insert(i + j + 1, line)
                            j += 1
                    else
                        shape = zf.shape(shape)\org_points(line.styleref.align)\build!
                        ctrl_pts = genr_mesh(shape, elements.siz, elements.tpc == "Bezier" and true or false)
                        ctrl_pts = "\\clip(#{zf.shape(ctrl_pts)\to_clip(7, px, py)\build(nil, 0)})"
                        --
                        _tags = zf.tags\clean("{\\pos(#{px},#{py})#{_tags\gsub("\\i?clip%b()", "") .. ctrl_pts}}")
                        line.text = "#{_tags}#{shape}"
                        subs.insert(i + j + 1, line)
                        j += 1
                when "Warp"
                    assert shape, "shape expected"
                    assert line.text\match("\\i?clip%b()"), "clip expected"
                    ctrl_pts = zf.shape(line.text)\unclip(7, coords.pos.x, coords.pos.y)\build!
                    --
                    _tags = zf.tags(line.text)\remove("shape_envelope")
                    _tags = zf.tags\clean("{#{_tags\gsub("\\i?clip%b()", "")}}")
                    line.text = "#{_tags}#{genr_warp(shape, ctrl_pts, elements.tol, elements.srt)}"
                    subs.insert(i + j + 1, line)
                    j += 1
                when "Perspective"
                    assert shape, "shape expected"
                    assert line.text\match("\\i?clip%b()"), "clip expected"
                    ctrl_pts = zf.shape(line.text)\unclip(7, coords.pos.x, coords.pos.y)\build!
                    --
                    _tags = zf.tags(line.text)\remove("shape_envelope")
                    _tags = zf.tags\clean("{#{_tags\gsub("\\i?clip%b()", "")}}")
                    line.text = "#{_tags}#{genr_warp(shape, ctrl_pts, nil, nil, true)}"
                    subs.insert(i + j + 1, line)
                    j += 1

aegisub.register_macro script_name, script_description, main