export script_name        = "Envelope Distort"
export script_description = "Makes distortions in shapes by means of control points."
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.main"

-- generates the inspection points
genr_mesh = (shape, size, bezier) ->
    box = zf.shape(shape)\bounding(true)
    box = size > 1 and zf.shape(box)\split(nil, "all", size) or zf.shape(box)
    box\to_bezier! if bezier
    return box\build!

-- generates the output with the deformation
genr_warp = (shape, mesh, TOLERANCE = 50, perspective) ->
    unless perspective
        get_mesh = {i: {}, o: {}}
        box, l, t, r, b = zf.shape(shape)\bounding(true)
        -- recreates the mesh points from the information given by the mesh point present in the clip
        bezier = mesh\match "b"
        mesh_i, mesh_o = zf.shape(mesh), zf.shape(mesh)
        if not bezier and #mesh_i.paths[1] < 5
            error "Must have at least 4 control points!"
        elseif bezier and #mesh_i.paths[1] < 2
            error "Must have at least 2 control points!"
        -- get size
        size = (#mesh_i.paths[1] - 1) / 4
        mesh_i = size > 1 and zf.shape(box)\split(nil, "all", size) or zf.shape(box)
        -- sets up the points for bezier, if necessary
        if bezier
            mesh_i\to_bezier!
            mesh_i\split(nil, "all", TOLERANCE)
            mesh_o = mesh_o\split(nil, "all", TOLERANCE)
        table.remove(mesh_i.paths[1])
        table.remove(mesh_o.paths[1])
        -- equals the quantity of control points if the clip exceeds the established quantity
        while #mesh_i.paths[1] > #mesh_o.paths[1]
            table.remove(mesh_i.paths[1])
        for j = 1, #mesh_i.paths[1]
            get_mesh.i[#get_mesh.i + 1] = {x: mesh_i.paths[1][j][1], y: mesh_i.paths[1][j][2]}
            get_mesh.o[#get_mesh.o + 1] = {x: mesh_o.paths[1][j][1], y: mesh_o.paths[1][j][2]}
        return zf.shape(shape)\envelope_distort(get_mesh.i, get_mesh.o)\build!
    else
        mesh = zf.shape(mesh).paths
        assert #mesh[1] == 5, "The box can only have 4 points, generate a new box!"
        l1, t1, r1, b1 = mesh[1][1][1], mesh[1][1][2], mesh[1][2][1], mesh[1][3][2]
        l2, t2, r2, b2 = mesh[1][4][1], mesh[1][2][2], mesh[1][3][1], mesh[1][4][2]
        destin = {
            {x: l1, y: t1}
            {x: r1, y: t2}
            {x: r2, y: b1}
            {x: l2, y: b2}
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
            --
            line = zf.table(l)\copy!
            subs[i + j] = l
            if elements.rfl == true
                subs.delete(i + j)
                j -= 1
            --
            line.comment = false
            for t, tag in ipairs zf.text(subs, line, line.text)\tags!
                px, py, org = zf.text\org_pos(coords, tag, line)
                shape = tag.text_stripped\match("m%s+%-?%d[%.%-%d mlb]*")
                shape or=  zf.shape(zf.text(subs, tag, tag.text_stripped)\to_clip!)\unclip(tag.styleref.align)\build!
                shape = zf.shape(shape)\org_points(line.styleref.align)\build!
                --
                __tags = zf.tags(tag.text)\remove("envelope")
                switch elements.gmw
                    when "Mesh"
                        ctrl_pts = genr_mesh(shape, elements.siz, elements.tpc == "Bezier" and true or false)
                        ctrl_pts = "\\clip(#{zf.shape(ctrl_pts)\to_clip(7, px, py)\build(nil, 0)})"
                        --
                        __tags = zf.tags\clean("{\\pos(#{px},#{py})#{org .. __tags\gsub("\\i?clip%b()", "") .. ctrl_pts}}")
                        line.text = "#{__tags}#{shape}"
                        subs.insert(i + j + 1, line)
                        j += 1
                    when "Warp"
                        assert tag.tags\match("\\i?clip"), "clip expected"
                        ctrl_pts = zf.shape(tag.text)\unclip(7, coords.pos.x, coords.pos.y)\build!
                        --
                        __tags = zf.tags\clean("{#{__tags\gsub("\\i?clip%b()", "")}}")
                        tag.text = "#{__tags}#{genr_warp(shape, ctrl_pts, elements.tol)}"
                        subs.insert(i + j + 1, tag)
                        j += 1
                    when "Perspective"
                        assert tag.tags\match("\\i?clip"), "clip expected"
                        ctrl_pts = zf.shape(tag.text)\unclip(7, coords.pos.x, coords.pos.y)\build!
                        --
                        __tags = zf.tags\clean("{#{__tags\gsub("\\i?clip%b()", "")}}")
                        tag.text = "#{__tags}#{genr_warp(shape, ctrl_pts, nil, true)}"
                        subs.insert(i + j + 1, tag)
                        j += 1

aegisub.register_macro script_name, script_description, main