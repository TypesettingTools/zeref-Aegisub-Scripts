export script_name        = "Envelope Distort"
export script_description = "Makes distortions in shapes by means of control points."
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.utils"

interface = ->
    inter_utils = {
        m: { -- mesh
            t: {"Bezier", "Line"} -- types
            g: {"Mesh", "Warp", "Perspective"} -- types
            h: {
                "Interpolation of the control points around the bounding box.",
                "Mesh, will generate the control points.\nWarp, will generate the distortion from the control points."
                "Interpolation tolerance of the control points that are of Bezier type."
                "Control points style type."
            }
        }
    }
    {
        {class: "label", label: "Control Points: ", x: 0, y: 0}
        {class: "intedit", name: "siz", hint: inter_utils.m.h[1], x: 0, y: 1, width: 5, min: 1, value: 1}
        {class: "label", label: "Generator: ", x: 0, y: 2}
        {class: "dropdown", name: "gmw", items: inter_utils.m.g, hint: inter_utils.m.h[2], x: 0, y: 3, width: 5, value: inter_utils.m.g[1]}
        {class: "label", label: "Tolerance:  ", x: 5, y: 0}
        {class: "intedit", name: "tol", hint: inter_utils.m.h[3], x: 5, y: 1, width: 7, min: 1, value: 50}
        {class: "label", label: "Type:  ", x: 5, y: 2}
        {class: "dropdown", name: "tpc", items: inter_utils.m.t, hint: inter_utils.m.h[4], x: 5, y: 3, width: 7, value: inter_utils.m.t[2]}
    }

genr_ctrl_pts = (shape, size, bezier) ->
    -- generates a bounding box around the shape
    box, l, t, r, b = zf.shape(shape)\bounding(true)
    box = size > 1 and zf.shape(box)\split(nil, "all", size) or zf.shape(box)
    box\to_bezier! if bezier
    return box\build!

genr_warp = (shape, mesh, TOLERANCE = 50, perspective) ->
    unless perspective
        get_mesh = {i: {}, o: {}}
        -- generates a bounding box around the shape
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
    inter = zf.config\load(interface!, script_name)
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                interface!
        break if buttons == "Ok" or buttons == "Cancel"
    if buttons == "Ok"
        for k, v in ipairs(sel)
            l = subs[v]
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            --
            text = zf.tags\remove("full", l.text)
            tags = zf.tags(l.text)\remove("shape_poly")
            --
            shape = text\match("m%s+%-?%d[%.%-%d mlb]*")
            shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build!
            shape = zf.shape(shape)\org_points(l.styleref.align)\build!
            px, py = coords.pos.x, coords.pos.y
            switch elements.gmw
                when "Mesh"
                    tags = tags\gsub("{(.-)}", "%1", 1)
                    --
                    ctrl_pts = genr_ctrl_pts(shape, elements.siz, (elements.tpc == "Bezier") and true or false)
                    ctrl_pts = zf.shape(ctrl_pts)\to_clip(7, px, py)\build(nil, 0)
                    ctrl_pts = "\\clip(#{ctrl_pts})"
                    --
                    tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "") .. ctrl_pts}}")
                    l.text = "#{tags}#{shape}"
                when "Warp"
                    assert l.text\match("\\i?clip()"), "You did not generate the control points!"
                    ctrl_pts = zf.shape(l.text)\unclip(7, px, py)\build!
                    --
                    tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "")}}")
                    l.text = "#{tags}#{genr_warp(shape, ctrl_pts, elements.tol)}"
                when "Perspective"
                    assert l.text\match("\\i?clip()"), "You did not generate the control points!"
                    ctrl_pts = zf.shape(l.text)\unclip(7, px, py)\build!
                    --
                    tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "")}}")
                    l.text = "#{tags}#{genr_warp(shape, ctrl_pts, nil, true)}"
            subs[v] = l
    return

aegisub.register_macro "#{script_name}", script_description, main