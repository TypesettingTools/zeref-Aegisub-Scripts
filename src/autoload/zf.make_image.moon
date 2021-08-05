export script_name        = "Make Image"
export script_description = "Make Image lets you convert images [png, jpeg, bmp, gif] into shape or to pixels."
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.utils"

-- São as listas de dropdowns
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

interface = (typer = "tracer") ->
    switch typer
        when "tracer"
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
        when "potrace"
            items = {"right", "black", "white", "majority", "minority"}
            {
                {class: "label", label: "Turnpolicy:", x: 0, y: 0}
                {class: "dropdown", name: "tpy", :items, x: 0, y: 1, value: "minority"}
                {class: "label", label: "Corner threshold:", x: 0, y: 2}
                {class: "intedit", name: "apm", x: 0, y: 3, min: 0, value: 1}
                {class: "label", label: "Delete until:\t\t\t\t\t\t\t\t\t\t ", x: 1, y: 0}
                {class: "floatedit", name: "tdz", x: 1, y: 1, value: 2}
                {class: "label", label: "Tolerance:", x: 1, y: 2}
                {class: "floatedit", name: "opt", x: 1, y: 3, min: 0, value: 0.2}
                {class: "checkbox", label: "Curve optimization?\t\t  ", name: "opc", x: 0, y: 4, value: true}
            }
        when "pixel"
            items = {"All in one line", "On several lines - rec", "Pixel by Pixel"}
            {
                {class: "label", label: "Output Type:", x: 0, y: 0}
                {class: "dropdown", name: "otp", :items, x: 0, y: 1, value: items[2]}
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

main = (macro) ->
    ext = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.dib;*.gif"
    return (subs, sel) ->
        filename = aegisub.dialog.open("Open Image File", "", "", "Image extents (#{ext})|#{ext};", false, true)
        aegisub.cancel! unless filename
        not_GIF, f_dur = filename\match("^.+%.(.+)$") != "gif", 41.708
        l, j = zf.table(subs[sel[#sel]])\copy!, 1
        switch macro
            when "tracer"
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
                    aegisub.progress.task "Generating Tracer..."
                    if not_GIF
                        tracer = zf.img(filename)\tracer!
                        preset = load_preset(tracer, elements)
                        for k, v in ipairs tracer\to_shape(preset)
                            l.text = v
                            subs.insert(sel[#sel] + j, l)
                            j += 1
                    else
                        frames = zf.img(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            tracer = zf.img(f)\tracer!
                            preset = load_preset(tracer, elements)
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            for k, v in ipairs tracer\to_shape(preset)
                                l.text = v\gsub "m%s+%-?%d[%.%-%d mlb]*", (s) -> zf.shape(s)\displace(f.x, f.y)\build!
                                subs.insert(sel[#sel] + j, l)
                                j += 1
            when "potrace"
                inter = zf.config\load(interface("potrace"), script_name .. "_po")
                local buttons, elements
                while true
                    buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
                    inter = switch buttons
                        when "Save"
                            zf.config\save(inter, elements, script_name .. "_po", script_version)
                            zf.config\load(inter, script_name .. "_po")
                        when "Reset"
                            interface("potrace")
                    break if buttons == "Ok" or buttons == "Cancel"
                if buttons == "Ok"
                    infos = {elements.tpy, elements.tdz, elements.opc, elements.apm, elements.opt}
                    aegisub.progress.task "Generating Trace..."
                    if not_GIF
                        -- execute potrace
                        pot = zf.img(filename)\potrace(infos)
                        pot\process!
                        shape = pot\get_shape!
                        --
                        l.text = "{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0\\p1}" .. shape
                        subs.insert(sel[#sel] + 1, l)
                    else
                        frames = zf.img(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            -- execute potrace
                            pot = zf.img(f)\potrace(infos)
                            pot\process!
                            shape = zf.shape(pot\get_shape!)\displace(f.x, f.y)\build!
                            --
                            l.text = "{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0\\p1}" .. shape
                            subs.insert(sel[#sel] + j, l)
                            j += 1
            when "pixel"
                interface_px = ->
                    items = {"All in one line", "On several lines - rec", "Pixel by Pixel"}
                    {
                        {class: "label", label: "Output Type:", x: 0, y: 0}
                        {class: "dropdown", name: "otp", :items , x: 0, y: 1, value: items[2]}
                    }
                inter = zf.config\load(interface("pixel"), script_name .. "_px")
                local buttons, elements
                while true
                    buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
                    inter = switch buttons
                        when "Save"
                            zf.config\save(inter, elements, script_name .. "_px", script_version)
                            zf.config\load(inter, script_name .. "_px")
                        when "Reset"
                            interface("pixel")
                    break if buttons == "Ok" or buttons == "Cancel"
                if buttons == "Ok"
                    aegisub.progress.task "Generating Pixels..."
                    if not_GIF
                        px = switch elements.otp
                            when "All in one line" then zf.img(filename)\raster("once")
                            when "On several lines - rec" then zf.img(filename)\raster(true)
                            when "Pixel by Pixel" then zf.img(filename)\raster!
                        for k, v in pairs px
                            l.text = v\gsub "}{", ""
                            subs.insert(sel[#sel] + j, l)
                            j += 1
                    else
                        frames = zf.img(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            px = switch elements.otp
                                when "All in one line" then zf.img(f)\raster("once")
                                when "On several lines - rec" then zf.img(f)\raster(true)
                                when "Pixel by Pixel" then zf.img(f)\raster!
                            for k, v in pairs px
                                l.text = v\gsub("}{", "")\gsub "\\pos((%d+),(%d+))", (x, y) -> tonumber(x) + f.x, tonumber(y) + f.y
                                subs.insert(sel[#sel] + j, l)
                                j += 1

aegisub.register_macro "#{script_name}/Tracer", script_description, main("tracer")
aegisub.register_macro "#{script_name}/Potrace", script_description, main("potrace")
aegisub.register_macro "#{script_name}/By Pixels", script_description, main("pixel")