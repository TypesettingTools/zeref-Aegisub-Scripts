export script_name        = "Make Image"
export script_description = "Converts images of various formats to pixels written in shape."
export script_author      = "Zeref"
export script_version     = "1.0.1"
-- LIB
zf = require "ZF.main"

import POTRACE from require "ZF.img.potrace"

interfacePixels = ->
    items = {"All in one line", "On several lines - \"Rec\"", "Pixel by Pixel"}
    {
        {class: "label", label: "Output Type:", x: 0, y: 0}
        {class: "dropdown", name: "otp", :items , x: 0, y: 1, value: items[2]}
    }

interfacePotrace = ->
    x, items = 0, {"right", "black", "white", "majority", "minority"}
    {
        {class: "label", label: "Turnpolicy:", :x, y: 0}
        {class: "dropdown", name: "tpy", :items, :x, y: 1, value: "minority"}
        {class: "label", label: "Corner threshold:", :x, y: 2}
        {class: "intedit", name: "apm", :x, y: 3, min: 0, value: 1}
        {class: "label", label: "Delete until:", :x, y: 4}
        {class: "floatedit", name: "tdz", :x, y: 5, value: 2}
        {class: "label", label: "Tolerance:", :x, y: 6}
        {class: "floatedit", name: "opt", :x, y: 7, min: 0, value: 0.2}
        {class: "checkbox", label: "Curve optimization?", name: "opc", :x, y: 8, value: true}
    }

getVals = (inter) ->
    extensions, frameDur = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.dib;*.gif", zf.util\getFrameDur 0

    filename = aegisub.dialog.open "Open Image File", "", "", "Image extents (#{extensions})|#{extensions};", false, true
    unless filename
        aegisub.cancel! 

    buttons, elements = aegisub.dialog.display inter, {"Ok", "Cancel"}, close: "Cancel"

    return buttons, elements, filename, frameDur

main = (macro) ->
    return (subs, selected) ->
        line, i = zf.table(subs[selected[#selected]])\copy!, 1
        buttons, elements, filename, frameDur = getVals macro == "Pixels" and interfacePixels! or interfacePotrace!

        img = POTRACE filename
        ext = img.extension
        dur = line.end_time - line.start_time
        {:tpy, :tdz, :opc, :apm, :opt, :otp} = elements

        aegisub.progress.task "Processing #{ext\upper!}..."
        if buttons == "Ok"
            aegisub.progress.task "Processing..."
            if macro == "Pixels"
                makePixels = (pixels, isGif) ->
                    for p, pixel in pairs pixels
                        line.text = pixel\gsub "}{", ""
                        if isGif
                            -- repositions the coordinates
                            line.text = line.text\gsub "\\pos%((%d+),(%d+)%)", (x, y) ->
                                px = tonumber(x) + img.x
                                py = tonumber(y) + img.y
                                return "\\pos(#{px},#{py})"
                        i = zf.util\insertLine line, subs, selected[#selected] - 1, i

                typer = switch otp
                    when "All in one line" then "oneLine"
                    when "On several lines - \"Rec\"" then true
                    when "Pixel by Pixel" then nil

                if ext != "gif"
                    makePixels img\raster typer
                else
                    len = #img.infos.frames
                    for j = 1, len
                        aegisub.progress.task "Processing GIF... Frame [ #{j} ]"
                        last = subs[selected[#selected]]

                        line.start_time = last.start_time + dur * (j - 1) / len
                        line.end_time = last.start_time + dur * j / len
                        makePixels img\raster(typer, j), true
            else -- if potrace
                makePotrace = (shp, isGif) ->
                    line.text = "{\\an7\\pos(0,0)\\bord0\\shad0\\fscx100\\fscy100\\fr0\\p1}#{shp}"
                    if isGif
                        -- repositions the coordinates
                        line.text = line.text\gsub "\\pos%((%d+),(%d+)%)", (x, y) ->
                            px = tonumber(x) + img.x
                            py = tonumber(y) + img.y
                            return "\\pos(#{px},#{py})"
                    i = zf.util\insertLine line, subs, selected[#selected] - 1, i

                img\start nil, tpy, tdz, opc, apm, opt
                if ext != "gif"
                    img\process!
                    makePotrace img\getShape!
                else
                    len = #img.infos.frames
                    for j = 1, len
                        aegisub.progress.task "Processing GIF... Frame [ #{j} ]"
                        last = subs[selected[#selected]]

                        line.start_time = last.start_time + dur * (j - 1) / len
                        line.end_time = last.start_time + dur * j / len

                        img\start j
                        if pcall -> img\process!
                            makePotrace img\getShape!, true

        aegisub.set_undo_point macro

aegisub.register_macro "#{script_name}/Pixels", script_description, main "Pixels"
aegisub.register_macro "#{script_name}/Potrace", script_description, main "Potrace"