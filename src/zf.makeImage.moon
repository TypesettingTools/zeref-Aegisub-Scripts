export script_name        = "Make Image"
export script_description = "Converts images of various formats to pixels written in shape."
export script_author      = "Zeref"
export script_version     = "1.1.4"
-- LIB
zf = require "ZF.main"

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

exts = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.dib;*.gif"

main = (macro) ->
   (subs, selected) ->
        filename = aegisub.dialog.open "Open Image File", "", "", "Image extents (#{exts})|#{exts};", false, true
        unless filename
            aegisub.cancel!
        new_selection, i = {}, {0, 0, selected[#selected]}
        button, elements = aegisub.dialog.display macro == "Pixels" and interfacePixels! or interfacePotrace!, {"Ok", "Cancel"}, close: "Cancel"
        if button == "Ok"
            img = zf.potrace filename
            ext = img.extension
            aegisub.progress.task "Processing #{ext\upper!}..."
            -- copies the current line
            line = zf.table(subs[i[3]])\copy!
            dur = line.end_time - line.start_time
            {:tpy, :tdz, :opc, :apm, :opt, :otp} = elements
            -- start processing
            aegisub.progress.task "Processing..."
            if macro == "Pixels"
                makePixels = (pixels, isGif) ->
                    for p, pixel in pairs pixels
                        break if aegisub.progress.is_cancelled!
                        aegisub.progress.set 100 * p / #pixels
                        line.text = pixel\gsub "}{", ""
                        if isGif
                            -- repositions the coordinates
                            line.text = line.text\gsub "\\pos%((%d+),(%d+)%)", (x, y) ->
                                {x: vx, y: vy} = img
                                px = tonumber(x) + vx
                                py = tonumber(y) + vy
                                return "\\pos(#{px},#{py})"
                        zf.util\insertLine line, subs, i[3] - 1, new_selection, i

                typer = switch otp
                    when "All in one line" then "oneLine"
                    when "On several lines - \"Rec\"" then true

                if ext != "gif"
                    makePixels img\raster typer
                else
                    line.end_time = line.start_time + #img.infos.frames * zf.fbf\frameDur!
                    for s, e, d, j in zf.fbf(line)\iter!
                        break if aegisub.progress.is_cancelled!
                        line.start_time = s
                        line.end_time = e
                        makePixels img\raster(typer, j), true

            else -- if potrace
                makePotrace = (shp, isGif) ->
                    line.text = "{\\an7\\pos(0,0)\\bord0\\shad0\\fscx100\\fscy100\\fr0\\p1}#{shp}"
                    if isGif
                        -- repositions the coordinates
                        line.text = line.text\gsub "\\pos%((%d+),(%d+)%)", (x, y) ->
                            {x: vx, y: vy} = img
                            px = tonumber(x) + vx
                            py = tonumber(y) + vy
                            return "\\pos(#{px},#{py})"
                    zf.util\insertLine line, subs, i[3] - 1, new_selection, i

                img\start nil, tpy, tdz, opc, apm, opt
                if ext != "gif"
                    img\process!
                    makePotrace img\getShape!
                else
                    line.end_time = line.start_time + #img.infos.frames * zf.fbf\frameDur!
                    for s, e, d, j in zf.fbf(line)\iter!
                        break if aegisub.progress.is_cancelled!
                        line.start_time = s
                        line.end_time = e
                        img\start j
                        if pcall -> img\process!
                            makePotrace img\getShape!, true

        aegisub.set_undo_point macro
        if #new_selection > 0
            return new_selection, new_selection[1]

aegisub.register_macro "#{script_name} / Pixels", script_description, main "Pixels"
aegisub.register_macro "#{script_name} / Potrace", script_description, main "Potrace"