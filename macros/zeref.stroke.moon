export script_name        = "Stroke Panel"
export script_description = "A stroke panel"
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.utils"

interface = (subs, sel) ->
    stroke = {
        corner: {"Miter", "Round", "Square"}
        align: {"Center", "Inside", "Outside"}
        hints: {
            arctolerance: "The default ArcTolerance is 0.25 units. \nThis means that the maximum distance \nthe flattened path will deviate from the \n\"true\" arc will be no more than 0.25 units \n(before rounding)."
            stroke_size: "Stroke Size."
            miterlimit: "The default value for MiterLimit is 2 (ie twice delta). \nThis is also the smallest MiterLimit that's allowed. \nIf mitering was unrestricted (ie without any squaring), \nthen offsets at very acute angles would generate \nunacceptably long \"spikes\"."
            only_offset: "Return only the offseting text."
        }
    }
    l = subs[sel[#sel]]
    meta, styles = zf.util\tags2styles(subs, l)
    karaskel.preproc_line(subs, meta, styles, l)
    GUI = {
        {class: "label", label: "Stroke Corner:", x: 0, y: 0}
        {class: "label", label: "Align Stroke:",  x: 0, y: 3}
        {class: "label", label: "Stroke Weight:", x: 1, y: 0}
        {class: "label", label: "Miter Limit:",   x: 1, y: 3}
        {class: "label", label: "Arc Tolerance:", x: 1, y: 6}
        {class: "label", label: "Primary Color:", x: 0, y: 9}
        {class: "label", label: "Stroke Color:",  x: 1, y: 9}
        {class: "dropdown", name: "crn", items: stroke.corner, x: 0, y: 1, height: 2, value: stroke.corner[2]}
        {class: "dropdown", name: "alg", items: stroke.align, x: 0, y: 4, height: 2, value: stroke.align[3]}
        {class: "floatedit", name: "ssz", x: 1, y: 1, hint: stroke.hints.stroke_size, height: 2, min: 0, value: l.styleref.outline}
        {class: "floatedit", name: "mtl", x: 1, y: 4, hint: stroke.hints.miterlimit, height: 2, min: 0, value: 2}
        {class: "floatedit", name: "atc", x: 1, y: 7, hint: stroke.hints.arctolerance, height: 2, min: 0, value: 0.25}
        {class: "coloralpha", name: "color1", x: 0, y: 10, width: 1, height: 2, value: l.styleref.color1}
        {class: "coloralpha", name: "color3", x: 1, y: 10, width: 1, height: 2, value: l.styleref.color3}
        {class: "checkbox", label: "Simplify?", name: "smp", x: 0, y: 6, value: true}
        {class: "checkbox", label: "Remove selected layers?", name: "act", x: 0, y: 12, value: true}
        {class: "checkbox", label: "Generate only offset?\t\t", name: "olf", x: 1, y: 12, hint: stroke.hints.only_offset, value: false}
    }
    return GUI

main = (subs, sel) ->
    inter, j = zf.config\load(interface(subs, sel), script_name), 0
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                interface(subs, sel)
        break if buttons == "Ok" or buttons == "Cancel"
    if buttons == "Ok"
        aegisub.progress.task("Generating Stroke...")
        for _, i in ipairs sel
            aegisub.progress.set((i - 1) / #sel * 100)
            l = subs[i + j]
            l.comment = true
            subs[i + j] = l
            if elements.act == true
                subs.delete(i + j)
                j -= 1
            --
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            --
            text = zf.tags\remove("full", l.text)
            tags = zf.tags(l.text)\remove("out")
            tags ..= "\\pos(#{coords.pos.x},#{coords.pos.y})" unless tags\match("\\pos%b()") and not tags\match("\\move%b()")
            --
            shape = text\match("m%s+%-?%d[%.%-%d mlb]*")
            shape or= zf.shape(zf.text\to_clip(l, text))\unclip(l.styleref.align)\build!
            shape = zf.shape(shape)\org_points(l.styleref.align)\build!
            --
            l.comment, out_shape, out_offset = false, "", ""
            if elements.olf
                out_offset = zf.poly\simplify(zf.poly\offset(shape, elements.ssz, elements.crn\lower!, nil, elements.mtl, elements.atc, true), true, 3)
                __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(elements.color1)}}")
                l.text = "#{__tags}#{out_offset}"
                subs.insert(i + j + 1, l)
                j += 1
            else
                out_shape, out_offset = zf.poly\to_outline(shape, elements.ssz, elements.crn, elements.alg, elements.mtl, elements.atc, elements.smp)
                colors, shapes = {elements.color3, elements.color1}, {out_shape, out_offset}
                for k = 1, 2
                    __tags = zf.tags\clean("{#{tags}\\c#{zf.util\html_color(colors[k])}}")
                    l.text = "#{__tags}#{shapes[k]}"
                    subs.insert(i + j + 1, l)
                    j += 1
        aegisub.progress.set(100)
    return

aegisub.register_macro "Stroke Panel", script_description, main