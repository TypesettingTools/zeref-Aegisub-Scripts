export script_name        = "Make Image"
export script_description = "Converts images of various formats to pixels written in shape."
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

import IMAGE from require "ZF.img.img"

interface = ->
    items = {"All in one line", "On several lines - \"Rec\"", "Pixel by Pixel"}
    {
        {class: "label", label: "Output Type:", x: 0, y: 0}
        {class: "dropdown", name: "otp", :items , x: 0, y: 1, value: items[2]}
    }

main = (subs, selected) ->
    extensions, frameDur = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;*.dib;*.gif", zf.util\getFrameDur 0

    filename = aegisub.dialog.open "Open Image File", "", "", "Image extents (#{extensions})|#{extensions};", false, true
    aegisub.cancel! unless filename

    buttons, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, close: "Cancel"

    if buttons == "Ok"
        aegisub.progress.task "Processing..."

        line, i = zf.table(subs[selected[#selected]])\copy!, 1

        typer = switch elements.otp
            when "All in one line" then "oneLine"
            when "On several lines - \"Rec\"" then true
            when "Pixel by Pixel" then nil

        img = IMAGE filename
        ext = img.extension

        aegisub.progress.task "Processing #{ext\upper!}..."

        make = (pixels, isGif) ->
            for p, pixel in pairs pixels
                line.text = pixel\gsub "}{", ""

                if isGif
                    -- repositions the coordinates
                    line.text = line.text\gsub "\\pos%((%d+),(%d+)%)", (x, y) ->
                        px = tonumber(x) + img.x
                        py = tonumber(y) + img.y
                        return "\\pos(#{px},#{py})"

                subs.insert selected[#selected] + i, line
                i += 1

        if ext != "gif"
            make img\raster typer
        else
            length = #img.infos.frames
            for j = 1, length
                aegisub.progress.task "Processing GIF... Frame [ #{j} ]"
                last = subs[selected[#selected]]

                line.start_time = last.start_time + length * frameDur * (j - 1) / length
                line.end_time = last.start_time + length * frameDur * j / length
                make img\raster(typer, j), true

    aegisub.set_undo_point script_name

aegisub.register_macro script_name, script_description, main