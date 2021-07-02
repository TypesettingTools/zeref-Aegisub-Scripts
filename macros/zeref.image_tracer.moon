export script_name        = "Image Trace"
export script_description = "Image Trace lets you convert raster images [png, jpeg, bmp, gif] to shape"
export script_author      = "Zeref"
export script_version     = "0.0.1"
-- LIB
zf = require "ZF.utils"
import image_tracer, gif from require "img-libs/image_tracer/image_tracer"

drops = {
    presets: {
        "Custom"
        "Default"
        "Detailed"
        "Black and White"
        "Grayscale"
        "3 Colors"
        "6 Colors"
        "16 Colors"
        "Smoothed"
    }
    modes: {
        "Custom"
        "Color"
        "Black and White"
        "Grayscale"
    }
    palette: {
        "Sampling"
        "Rectangular Grid"
        "Number of colors"
    }
}

interface = ->
    {
        -- Preset
        {class: "label", label: "Preset:", x: 0, y: 0}
        {class: "dropdown", name: "prst", items: drops.presets, x: 1, y: 0, value: drops.presets[1]}
        -- Mode
        {class: "label", label: "Mode:", x: 0, y: 1}
        {class: "dropdown", name: "mds", items: drops.modes, x: 1, y: 1, value: drops.modes[1]}
        -- Palette
        {class: "label", label: "Palette:", x: 0, y: 2}
        {class: "dropdown", name: plt, items: drops.palette, x: 1, y: 2, value: drops.palette[3]}
        -- Color Quantization
        {class: "label", label: "Number of Colors:", x: 2, y: 0}
        {class: "intedit", name: "noc", x: 3, y: 0, min: 2, value: 16}
        {class: "label", label: "Min Color Ratio:", x: 2, y: 1}
        {class: "intedit", name: "cmin", x: 3, y: 1, value: 0}
        {class: "label", label: "Color Quant Cycles:", x: 2, y: 2}
        {class: "intedit", name: "cqcs", x: 3, y: 2, value: 3}
        {class: "label", label: "- Advanced ----------", x: 1, y: 4}
        -- Tracing
        {class: "label", label: "Line Tres:", x: 0, y: 5}
        {class: "floatedit", name: "lte", x: 1, y: 5, min: 0, value: 1}
        {class: "label", label: "Bezier Tres:", x: 0, y: 6}
        {class: "floatedit", name: "bte", x: 1, y: 6, min: 0, value: 1}
        {class: "label", label: "Pathomit:", x: 0, y: 7}
        {class: "intedit", name: "ptt", x: 1, y: 7, min: 0, value: 8}
        {class: "label", label: "Round:", x: 0, y: 8}
        {class: "intedit", name: "rud", x: 1, y: 8, min: 0, value: 2}
        {class: "checkbox", label: "Right Angle ENH?", name: "rga", x: 3, y: 4, value: true}
        -- Shape
        {class: "label", label: "Stroke Size:", x: 2, y: 5}
        {class: "floatedit", name: "skw", x: 3, y: 5, min: 0, value: 1}
        {class: "label", label: "Scale:", x: 2, y: 6}
        {class: "floatedit", name: "scl", x: 3, y: 6, min: 0, value: 1}
        -- Blur
        {class: "label", label: "Blur Radius:", x: 2, y: 7}
        {class: "intedit", name: "brr", x: 3, y: 7, min: 0, max: 5, value: 0}
        {class: "label", label: "Blur Delta:", min: 0, max: 1024, x: 2, y: 8}
        {class: "intedit", name: "brd", x: 3, y: 8, min: 0, value: 20}
        -- Ignore
        {class: "checkbox", label: "Ignore White?", name: "igw", x: 1, y: 9, value: false}
        {class: "checkbox", label: "Ignore Black?", name: "igb", x: 3, y: 9, value: false}
    }

load_preset = (tracer, elements) ->
    -- Redefine values
    default                   = tracer.optionpresets.default
    default.ltres             = elements.lte
    default.qtres             = elements.bte
    default.pathomit          = elements.ptt
    default.rightangleenhance = elements.rga
    default.numberofcolors    = elements.noc
    default.mincolorratio     = elements.cmin
    default.colorquantcycles  = elements.cqcs
    default.strokewidth       = elements.skw 
    default.scale             = elements.scl
    default.roundcoords       = elements.rud
    default.blurradius        = elements.brr
    default.blurdelta         = elements.brd
    default.deletewhite       = elements.igw
    default.deleteblack       = elements.igb
    -- Define Palette
    default.colorsampling = switch elements.plt
        when "Number of colors" then 0
        when "Sampling" then 1
        when "Rectangular Grid" then 2
    -- Define Mode
    switch elements.mds
        when "Color"
            default.colorsampling = 2
        when "Grayscale"
            default.colorsampling = 0
            if default.numberofcolors > 7
                default.numberofcolors = 7
        when "Black and White"
            default.colorsampling = 0
            default.numberofcolors = 2
    -- Define Preset
    switch elements.prst
        when "High Fidelity Photo"
            default.pathomit = 0
            default.roundcoords = 2
            default.ltres = 0.5
            default.qtres = 0.5
            default.numberofcolors = 64
        when "3 Colors"
            default.colorsampling = 0
            default.colorquantcycles = 2
            default.numberofcolors = 3
        when "6 Colors"
            default.colorsampling = 0
            default.colorquantcycles = 4
            default.numberofcolors = 16
        when "16 Colors"
            default.numberofcolors = 16
        when "Black and White"
            default.colorsampling = 0
            default.colorquantcycles = 1
            default.numberofcolors = 2
        when "Smoothed"
            default.blurradius = 5
            default.blurdelta = 6
        when "Grayscale"
            default.colorsampling = 0
            default.colorquantcycles = 1
            default.numberofcolors = 7
    return default

local main
main = (subs, sel) ->
    exts = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.gif"
    filename = aegisub.dialog.open("Open Image File", "", "", "Image extents (#{exts})|#{exts};", false, true)
    aegisub.cancel! unless filename
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
    --
    if buttons == "Ok"
        aegisub.progress.task("Generating Trace...")
        if filename\match("^.+%.(.+)$") != "gif"
            tracer = image_tracer(filename)
            preset = load_preset(tracer, elements)
            --
            l, j = zf.table(subs[sel[#sel]])\copy!, 1
            for k, v in ipairs tracer\to_shape(preset)
                l.text = v
                subs.insert(sel[#sel] + j, l)
                j += 1
        else
            l, i, j = zf.table(subs[sel[#sel]])\copy!, 1, 1
            frames, f_dur = gif(filename)\map!, 42
            while #frames >= i
                tracer = image_tracer(frames[i])
                preset = load_preset(tracer, elements)
                --
                l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                for k, v in ipairs tracer\to_shape(preset)
                    v = v\gsub "m%s+%-?%d[%.%-%d mlb]*", (s) ->
                        s = zf.shape(s)\displace(frames[i].x, frames[i].y)\build!
                        return s
                    l.text = v
                    subs.insert(sel[#sel] + j, l)
                    j += 1
                i += 1
    return

aegisub.register_macro script_name, script_description, main
