export script_name        = "Make Image"
export script_description = "Make Image lets you convert images [png, jpeg, bmp, gif] into shape or to pixels."
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.main"

tracer_config = (tracer, elements) ->
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
                inter = zf.config\load(zf.config\interface(script_name)!, script_name)
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
                if buttons == "Ok"
                    aegisub.progress.task "Generating Tracer..."
                    if not_GIF
                        tracer = zf.image(filename)\tracer!
                        preset = tracer_config(tracer, elements)
                        for k, v in ipairs tracer\to_shape(preset)
                            l.text = v
                            subs.insert(sel[#sel] + j, l)
                            j += 1
                    else
                        frames = zf.image(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            tracer = zf.image(f)\tracer!
                            preset = tracer_config(tracer, elements)
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            for k, v in ipairs tracer\to_shape(preset)
                                l.text = v\gsub "m%s+%-?%d[%.%-%d mlb]*", (s) -> zf.shape(s)\displace(f.x, f.y)\build!
                                subs.insert(sel[#sel] + j, l)
                                j += 1
            when "potrace"
                inter = zf.config\load(zf.config\interface(script_name)("potrace"), script_name .. "_po")
                local buttons, elements
                while true
                    buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
                    inter = switch buttons
                        when "Save"
                            zf.config\save(inter, elements, script_name .. "_po", script_version)
                            zf.config\load(inter, script_name .. "_po")
                        when "Reset"
                            zf.config\interface(script_name)("potrace")
                    break if buttons == "Ok" or buttons == "Cancel"
                if buttons == "Ok"
                    infos = {elements.tpy, elements.tdz, elements.opc, elements.apm, elements.opt}
                    aegisub.progress.task "Generating Trace..."
                    if not_GIF
                        -- execute potrace
                        pot = zf.image(filename)\potrace(infos)
                        pot\process!
                        shape = pot\get_shape!
                        --
                        l.text = "{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0\\p1}" .. shape
                        subs.insert(sel[#sel] + 1, l)
                    else
                        frames = zf.image(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            -- execute potrace
                            pot = zf.image(f)\potrace(infos)
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
                inter = zf.config\load(zf.config\interface(script_name)("pixel"), script_name .. "_px")
                local buttons, elements
                while true
                    buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
                    inter = switch buttons
                        when "Save"
                            zf.config\save(inter, elements, script_name .. "_px", script_version)
                            zf.config\load(inter, script_name .. "_px")
                        when "Reset"
                            zf.config\interface(script_name)("pixel")
                    break if buttons == "Ok" or buttons == "Cancel"
                if buttons == "Ok"
                    aegisub.progress.task "Generating Pixels..."
                    if not_GIF
                        px = switch elements.otp
                            when "All in one line" then zf.image(filename)\raster("once")
                            when "On several lines - rec" then zf.image(filename)\raster(true)
                            when "Pixel by Pixel" then zf.image(filename)\raster!
                        for k, v in pairs px
                            l.text = v\gsub "}{", ""
                            subs.insert(sel[#sel] + j, l)
                            j += 1
                    else
                        frames = zf.image(filename)\gif!
                        for i, f in ipairs frames -- index, frame
                            l.start_time = subs[sel[#sel]].start_time + #frames * f_dur * (i - 1) / #frames
                            l.end_time = subs[sel[#sel]].start_time + #frames * f_dur * i / #frames
                            px = switch elements.otp
                                when "All in one line" then zf.image(f)\raster("once")
                                when "On several lines - rec" then zf.image(f)\raster(true)
                                when "Pixel by Pixel" then zf.image(f)\raster!
                            for k, v in pairs px
                                l.text = v\gsub("}{", "")\gsub "\\pos((%d+),(%d+))", (x, y) -> tonumber(x) + f.x, tonumber(y) + f.y
                                subs.insert(sel[#sel] + j, l)
                                j += 1

aegisub.register_macro "#{script_name}/Tracer", script_description, main("tracer")
aegisub.register_macro "#{script_name}/Potrace", script_description, main("potrace")
aegisub.register_macro "#{script_name}/By Pixels", script_description, main("pixel")