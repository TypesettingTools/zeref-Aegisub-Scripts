export script_name        = "Envelope Distort"
export script_description = "Makes distortions in shapes by means of control points."
export script_author      = "Zeref"
export script_version     = "0.0.0"
-- LIB
zf = require "ZF.utils"

inter_utils = {
    m: { -- mesh
        t: {"Bezier", "Line"} -- types
        g: {"Mesh", "Warp"} -- types
        h: {
            "Interpolation of the control points around the bounding box.",
            "Mesh, will generate the control points.\nWarp, will generate the distortion from the control points."
            "Interpolation tolerance of the control points that are of Bezier type."
            "Control points style type."
        }
    }
}

interfaces = {
    mesh: {
        {class: "label", label: "Control Points: ", x: 0, y: 0}
        {class: "intedit", name: "siz", hint: inter_utils.m.h[1], x: 0, y: 1, min: 1, value: 1}
        {class: "label", label: "Generator: ", x: 0, y: 2}
        {class: "dropdown", name: "gmw", items: inter_utils.m.g, hint: inter_utils.m.h[2], x: 0, y: 3, value: inter_utils.m.g[1]}
        {class: "label", label: "-----------------------------------", x: 0, y: 4}
        {class: "label", label: "Tolerance: ", x: 0, y: 5}
        {class: "intedit", name: "tol", hint: inter_utils.m.h[3], x: 0, y: 6, min: 1, value: 50}
        {class: "label", label: "Type: ", x: 0, y: 7}
        {class: "dropdown", name: "tpc", items: inter_utils.m.t, hint: inter_utils.m.h[4], x: 0, y: 8, value: inter_utils.m.t[2]}
    }
}

genr_ctrl_pts = (shape, size, bezier) ->
    -- generates a bounding box around the shape
    box, l, t, r, b = zf.shape(shape)\bounding(true)
    if size > 1
        box = zf.shape(box)\split(nil, "all", size)
    else
        box = zf.shape(box)
    box.points = box\to_bezier! if bezier
    return box\build!

genr_warp = (shape, mesh, TOLERANCE = 50, perspective) ->
    unless perspective
        get_mesh = {i: {}, o: {}}
        -- generates a bounding box around the shape
        box, l, t, r, b = zf.shape(shape)\bounding(true)
        -- recreates the mesh points from the information given by the mesh point present in the clip
        bezier = mesh\match("b")
        mesh_i, mesh_o = zf.shape(mesh), zf.shape(mesh)
        if not bezier and (#mesh_i.points[1] < 5)
            error("Must have at least 4 control points!")
        elseif bezier and (#mesh_i.points[1] < 2)
            error("Must have at least 2 control points!")
        -- get size
        size = (#mesh_i.points[1] - 1) / 4
        --
        if size > 1
            mesh_i = zf.shape(box)\split(nil, "all", size)
        else
            mesh_i = zf.shape(box)
        -- sets up the points for bezier, if necessary
        if bezier
            mesh_i.points = mesh_i\to_bezier!
            mesh_i = zf.shape(mesh_i)\split(nil, "all", TOLERANCE)\build!
            mesh_i = zf.shape(mesh_i)
            --
            mesh_o = mesh_o\split(nil, "all", TOLERANCE)\build!
            mesh_o = zf.shape(mesh_o)
        else
            mesh_i = mesh_i\build!
            mesh_i = zf.shape(mesh_i)
        -- equals the quantity of control points if the clip exceeds the established quantity
        while #mesh_i.points[1] > #mesh_o.points[1]
            table.remove(mesh_i.points[1])
        --
        for j = 1, #mesh_i.points[1]
            get_mesh.i[#get_mesh.i + 1] = {x: mesh_i.points[1][j][1], y: mesh_i.points[1][j][2]}
            get_mesh.o[#get_mesh.o + 1] = {x: mesh_o.points[1][j][1], y: mesh_o.points[1][j][2]}
        return zf.shape(shape)\envelop_distort(get_mesh.i, get_mesh.o)\build!
    else
        local l1, t1, r1, b1, l2, t2, r2, b2
        mesh = zf.shape(mesh, false).points
        if (#mesh > 1) or (#mesh[1] > 5) or (#mesh[1] < 5)
            error("The box can only have 4 points, generate a new box!", 2)
        else
            l1, t1, r1, b1 = mesh[1][1][1], mesh[1][1][2], mesh[1][2][1], mesh[1][3][2]
            l2, t2, r2, b2 = mesh[1][4][1], mesh[1][2][2], mesh[1][3][1], mesh[1][4][2]
        destin = {
            {x: l1, y: t1}
            {x: r1, y: t2}
            {x: r2, y: b1}
            {x: l2, y: b2}
        }
        return zf.shape(shape)\perspective(destin)\build!

main = (macro) ->
    switch macro
        when "mesh"
            return (subs, sel) ->
                buttons, elements = aegisub.dialog.display(interfaces.mesh, {"Ok", "Cancel"})
                if (buttons == "Ok")
                    for k, v in ipairs(sel)
                        l = subs[v]
                        meta, styles = zf.util\tags2styles(subs, l)
                        karaskel.preproc_line(subs, meta, styles, l)
                        coords = zf.util\find_coords(l, meta)
                        --
                        text = zf.tags\remove("full", l.text)
                        tags = zf.tags(l.text)\remove("shape_poly")
                        --
                        shape = text\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build! -- If it is not a shape, transform the text into a shape
                        shape = zf.shape(shape)\org_points(l.styleref.align)\build! -- Moves the points to the alignment 7
                        --
                        px, py = coords.pos.x, coords.pos.y
                        --
                        if (elements.gmw == "Mesh")
                            tags = tags\gsub("{(.-)}", "%1", 1)
                            --
                            ctrl_pts = genr_ctrl_pts(shape, elements.siz, (elements.tpc == "Bezier") and true or false)
                            ctrl_pts = zf.shape(ctrl_pts)\to_clip(7, px, py)\build(nil, 0)
                            ctrl_pts = "\\clip(#{ctrl_pts})"
                            --
                            tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "") .. ctrl_pts}}")
                            l.text = "#{tags}#{shape}"
                        elseif (elements.gmw == "Warp")
                            error("You did not generate the control points!") unless l.text\match("\\i?clip()")
                            ctrl_pts = l.text\match("\\i?clip%((.-)%)")
                            ctrl_pts = zf.shape(ctrl_pts)\unclip(7, px, py)\build!
                            --
                            warp = genr_warp(shape, ctrl_pts, elements.tol)
                            --
                            tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "")}}")
                            l.text = "#{tags}#{warp}"
                        subs[v] = l
                else
                    aegisub.cancel!
                return
        when "warp"
            return (subs, sel) ->
                interfaces.warp = {
                    {class: "label", label: "Tolerance:  ", x: 0, y: 0}
                    {class: "intedit", name: "tol", hint: inter_utils.m.h[3], x: 0, y: 1, width: 7, min: 1, value: 50}
                }
                buttons, elements = aegisub.dialog.display(interfaces.warp, {"Ok", "Cancel"})
                if (buttons == "Ok")
                    for k, v in ipairs(sel)
                        l = subs[v]
                        meta, styles = zf.util\tags2styles(subs, l)
                        karaskel.preproc_line(subs, meta, styles, l)
                        coords = zf.util\find_coords(l, meta)
                        --
                        text = zf.tags\remove("full", l.text)
                        tags = zf.tags(l.text)\remove("shape_poly")
                        --
                        shape = text\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                        shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build! -- If it is not a shape, transform the text into a shape
                        shape = zf.shape(shape)\org_points(l.styleref.align)\build! -- Moves the points to the alignment 7
                        --
                        px, py = coords.pos.x, coords.pos.y
                        --
                        error("You did not generate the control points!") unless l.text\match("\\i?clip()")
                        ctrl_pts = l.text\match("\\i?clip%((.-)%)")
                        ctrl_pts = zf.shape(ctrl_pts)\unclip(7, px, py)\build!
                        --
                        warp = genr_warp(shape, ctrl_pts, elements.tol)
                        --
                        tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "")}}")
                        l.text = "#{tags}#{warp}"
                        subs[v] = l
                else
                    aegisub.cancel!
                return
        when "pers"
            return (subs, sel) ->
                for k, v in ipairs(sel)
                    l = subs[v]
                    meta, styles = zf.util\tags2styles(subs, l)
                    karaskel.preproc_line(subs, meta, styles, l)
                    coords = zf.util\find_coords(l, meta)
                    --
                    text = zf.tags\remove("full", l.text)
                    tags = zf.tags(l.text)\remove("shape_poly")
                    --
                    shape = text\match("m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*")
                    shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build! -- If it is not a shape, transform the text into a shape
                    shape = zf.shape(shape)\org_points(l.styleref.align)\build! -- Moves the points to the alignment 7
                    --
                    px, py = coords.pos.x, coords.pos.y
                    --
                    error("You did not generate the control points!") unless l.text\match("\\i?clip()")
                    ctrl_pts = l.text\match("\\i?clip%((.-)%)")
                    ctrl_pts = zf.shape(ctrl_pts)\unclip(7, px, py)\build!
                    --
                    warp = genr_warp(shape, ctrl_pts, nil, true)
                    --
                    tags = zf.tags\clean("{#{tags\gsub("\\i?clip%b()", "")}}")
                    l.text = "#{tags}#{warp}"
                    subs[v] = l
                return

aegisub.register_macro "#{script_name}/Make with - Mesh", script_description, main("mesh")
aegisub.register_macro "#{script_name}/Make with - Warp", script_description, main("warp")
aegisub.register_macro "#{script_name}/Make with - Perspective", script_description, main("pers")
return