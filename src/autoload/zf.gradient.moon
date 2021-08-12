export script_name        = "Gradient Cut"
export script_description = "Generate a gradient from cuts in sequence."
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.main"

-- https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
line_intersection = (a, b, c, d) ->
    compute_H = (a, b, c, d) ->
        e = {x: b.x - a.x, y: b.y - a.y}
        f = {x: d.x - c.x, y: d.y - c.y}
        p = {x: -e.y, y: e.x}
        intersection = f.x * p.x + f.y * p.y
        return ((a.x - c.x) * p.x + (a.y - c.y) * p.y) / intersection
    h1 = compute_H(a, b, c, d)
    h2 = compute_H(c, d, a, b)
    parallel = h1 != h1 or h2 != h2
    f = {x: d.x - c.x, y: d.y - c.y}
    return {
        intersected: h1 >= 0 and h1 <= 1 and h2 >= 0 and h2 <= 1
        x: parallel and 0 or c.x + f.x * h1
        y: parallel and 0 or c.y + f.y * h1
    }

-- cuts shapes into several pieces
make_cuts = (shape, pixel = 10, mode = "Horizontal", ang = 0) ->
    ang = switch mode
        when "Horizonal"  then 0
        when "Vertical"   then 90
        when "Diagonal 1" then 45
        when "Diagonal 2" then -45
    -- gets left and top values from the original value and from the source value
    fl, ft = zf.shape(shape)\bounding! -- left and top
    shapeo = zf.shape(shape)\origin! -- moves to origin
    ll, lt = shapeo\bounding! -- left and top origin
    -- saves the real width and height values
    owi, ohe = shapeo.w_shape, shapeo.h_shape
    -- gets the new width and height after rotation
    cos = math.cos(math.rad(ang))
    sin = math.sin(math.rad(ang))
    new_w = math.abs(owi * cos) + math.abs(ohe * sin) + owi
    new_h = math.abs(owi * sin) + math.abs(ohe * cos) + ohe
    -- sets the parallel line in the center of the rectangle
    line_center = zf.shape("m 0 0 l #{new_w} 0 ", false)\rotate(ang)\to_center!
    line_center\displace(owi / 2, ohe / 2)
    lp = line_center.paths[1]
    -- arrow the parallel line on the left of the rectangle
    line_first = zf.shape("m 0 0 l #{new_w} 0 ", false)\to_center!
    line_first\displace(owi / 2, ohe / 2)
    line_first\rotate(ang + 90)
    ls = line_first.paths[1]
    -- returns the point of intersection of the center line and the left line
    get_inter = line_intersection({x: lp[1][1], y: lp[1][2]}, {x: lp[2][1], y: lp[2][2]}, {x: ls[1][1], y: ls[1][2]}, {x: ls[2][1], y: ls[2][2]})
    -- repositions the line on the left so that it tangents to the one in the center
    disx_f = get_inter.x - lp[1][1]
    disy_l = get_inter.y - lp[1][2]
    line_first\displace(-disx_f, -disy_l)
    line_first = line_first\build!
    -- arrow the parallel line on the right of the rectangle
    line_last = zf.shape("m 0 0 l #{new_w} 0 ", false)\to_center!
    line_last\displace(owi / 2, ohe / 2)
    line_last\rotate(ang + 90)
    ls = line_last.paths[1]
    -- returns the point of intersection of the center line and the right line
    get_inter = line_intersection({x: lp[1][1], y: lp[1][2]}, {x: lp[2][1], y: lp[2][2]}, {x: ls[1][1], y: ls[1][2]}, {x: ls[2][1], y: ls[2][2]})
    -- repositions the line on the right so that it tangents to the one in the center
    disx_f = get_inter.x - lp[2][1]
    disy_f = get_inter.y - lp[2][2]
    line_last\displace(-disx_f, -disy_f)
    line_last = line_last\build!
    --
    clipped = {}
    len = zf.math\round(new_w / pixel, 0)
    for k = 1, len
        ipol = zf.util\interpolation((k - 1) / (len - 1), "shape", line_first, line_last) -- interpolation between first and last line
        ipol = zf.poly(ipol)\offset(pixel, "miter", "closed_line")\build! -- fills the line through the pixel value
        ipol = zf.shape(ipol)\displace(fl - ll, ft - lt)\build!
        clip = zf.poly(shape, ipol)\clip(false)
        clip.smp = "line"
        clip = clip\build!
        clipped[#clipped + 1] = clip if clip != ""
    return clipped

gradient = (subs, sel) ->
    -- adds in the GUI, the colors that were added
    rest = (t, read, len = 6) ->
        j = 1
        for i = 7, len
            t[i + 5] = {class: "color", name: "color#{i - 5}", x: t[1].x, y: i + j + 4, height: 2, value: read.v["color#{i - 5}"]}
            j += 1
        return t
    -- adds new color palettes to the interface
    add_colors = (t, j) ->
        gui = zf.table(t)\copy!
        table.insert(gui, {class: "color", name: "color#{(#gui - 10) + 1}", x: 8, y: gui[#gui].y + j, height: 2, value: "#000000"})
        return gui
    inter, read, len = zf.config\load(zf.config\interface(script_name)!, script_name)
    inter = rest(inter, read, len)
    local buttons, elements, j
    while true
        j = 0
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Add+", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                inter, read, len = zf.config\load(inter, script_name)
                rest(inter, read, len)
            when "Add+"
                j += 2
                add_colors(inter, j)
            when "Reset"
                zf.config\interface(script_name)!
        break if buttons == "Ok" or buttons == "Cancel"
    cap_colors, j = {}, 0
    for i = 11, #inter
        table.insert(cap_colors, zf.util\html_color(elements["color#{i - 10}"]))
    if buttons == "Ok"
        aegisub.progress.task "Generating Gradient..."
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
            if elements.act == true
                subs.delete(i + j)
                j -= 1
            --
            line.comment = false
            tags = zf.text(subs, line, line.text)\tags!
            for t, tag in ipairs tags
                px, py, org = zf.text\org_pos(coords, tag, line)
                shape = tag.text_stripped\match("m%s+%-?%d[%.%-%d mlb]*")
                is_text = not shape
                shape or=  zf.shape(zf.text(subs, tag, tag.text_stripped)\to_clip!)\unclip(tag.styleref.align)\build!
                shape = zf.shape(shape)\org_points(line.styleref.align)\build!
                --
                __tags = zf.tags(tag.text)\remove(is_text and "text_gradient" or "shape_gradient")
                cuts = make_cuts(shape, elements.px, elements.mode, elements.ag, meta)
                for k = 1, #cuts
                    color = "\\c#{zf.util\interpolation((k - 1) ^ elements.ac / (#cuts - 1) ^ elements.ac, "color", cap_colors)}"
                    __tag = zf.tags\clean("{\\pos(#{px},#{py})#{org .. __tags .. color}}")
                    tag.text = "#{__tag}#{cuts[k]}"
                    subs.insert(i + j + 1, tag)
                    j += 1

aegisub.register_macro script_name, script_description, gradient