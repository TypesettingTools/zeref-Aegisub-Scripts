export script_name        = "Stroke Panel"
export script_description = "A stroke panel"
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.main"

main = (subs, sel) ->
    inter, j = zf.config\load(zf.config\interface(script_name)(subs, sel), script_name), 0
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                zf.config\interface(script_name)(subs, sel)
        break if buttons == "Ok" or buttons == "Cancel"
    if buttons == "Ok"
        aegisub.progress.task "Generating Stroke..."
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
            line.comment, out_shape, out_offset = false, "", ""
            tags = zf.text(subs, line, line.text)\tags!
            for t, tag in ipairs tags
                px, py, org = zf.text\org_pos(coords, tag, line)
                shape = tag.text_stripped\match("m%s+%-?%d[%.%-%d mlb]*")
                is_text = not shape
                shape or=  zf.shape(zf.text(subs, tag, tag.text_stripped)\to_clip!)\unclip(tag.styleref.align)\build!
                shape = zf.shape(shape)\org_points(line.styleref.align)\build!
                --
                __tags = zf.tags(tag.text)\remove(is_text and "text_offset" or "shape_offset")
                if elements.olf
                    out_offset = zf.poly(shape, nil, elements.smp)\offset(elements.ssz, elements.crn\lower!, nil, elements.mtl, elements.atc)\build(nil, nil, 3)
                    tag.text = "#{zf.tags\clean("{\\pos(#{px},#{py})#{org .. __tags}\\c#{zf.util\html_color(elements.color1)}}")}#{out_offset}"
                    subs.insert(i + j + 1, tag)
                    j += 1
                else
                    out_shape, out_offset = zf.poly(shape, nil, elements.smp)\to_outline(elements.ssz, elements.crn, elements.alg, elements.mtl, elements.atc)
                    colors, shapes = {elements.color3, elements.color1}, {out_shape\build(nil, nil, 3), out_offset\build(nil, nil, 3)}
                    for k = 1, 2
                        tag.text = "#{zf.tags\clean("{\\pos(#{px},#{py})#{org .. __tags}\\c#{zf.util\html_color(colors[k])}}")}#{shapes[k]}"
                        subs.insert(i + j + 1, tag)
                        j += 1

aegisub.register_macro script_name, script_description, main