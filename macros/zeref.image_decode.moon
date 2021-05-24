export script_name        = "Image Decode"
export script_description = "Decode png, bitmap and gif images for Ass."
export script_author      = "Zeref"
export script_version     = "0.0.0"
-- LIB
zf = require "ZF.utils"
import png, gif, bmp from require "img-libs/img"

interface = {
    png: {
        {class: "label", label: "Output Type:", x: 0, y: 0}
        {class: "dropdown", name: "otp", items: {"All in one line", "On several lines - rec\t\t\t\t\t"}, x: 0, y: 1, value: "On several lines - rec\t\t\t\t\t"}
        {class: "checkbox", label: "Reencode png file?", name: "ree", value: false, x: 0, y: 2}
    }
    bmp: {
        {class: "label", label: "Output Type:", x: 0, y: 0}
        {class: "dropdown", name: "otp", items: {"All in one line", "On several lines - rec\t\t\t\t\t"}, x: 0, y: 1, value: "On several lines - rec\t\t\t\t\t"}
    }
    gif: {
        {class: "label", label: "Output Type:", x: 0, y: 0}
        {class: "dropdown", name: "otp", items: {"All in one line", "On several lines - rec\t\t\t\t\t"}, x: 0, y: 1, value: "On several lines - rec\t\t\t\t\t"}
        {class: "label", label: "Frame duration:", x: 0, y: 2}
        {class: "intedit", name: "frd", min: 1, x: 0, y: 3, value: 1}
    }
}

main = (subs, sel) ->
    filename = aegisub.dialog.open("Open", "", "", "Image (*.png;*.bmp;*.gif)|*.png;*.bmp;*.gif;", false, true)
    aegisub.cancel! unless filename
    image_type = filename\match("%.(.-)$")
    line, add = table.copy(subs[sel[#sel]]), 1
    switch image_type
        when "png"
            buttons, elements = aegisub.dialog.display(interface.png, {"Ok", "Cancel"}, {cancel: "Cancel"})
            if (buttons == "Ok")
                image_lines = png.raster(filename, elements.ree, elements.otp == "All in one line")
                for k, v in pairs(image_lines)
                    line.text = v\gsub "}{", ""
                    subs.insert(sel[#sel] + add, line)
                    add += 1
            else
                aegisub.cancel!
        when "bmp"
            buttons, elements = aegisub.dialog.display(interface.bmp, {"Ok", "Cancel"}, {cancel: "Cancel"})
            if (buttons == "Ok")
                image_lines = bmp.raster(filename, elements.otp == "All in one line")
                for k, v in pairs(image_lines)
                    line.text = v\gsub "}{", ""
                    subs.insert(sel[#sel] + add, line)
                    add += 1
            else
                aegisub.cancel!
        when "gif"
            buttons, elements = aegisub.dialog.display(interface.gif, {"Ok", "Cancel"}, {cancel: "Cancel"})
            msa = aegisub.ms_from_frame(1), aegisub.ms_from_frame(101)
            frame_dur = (not msb and 41.708 or (msb - msa) / 100) * elements.frd
            if (buttons == "Ok")
                frames = gif.raster(filename, elements.otp == "All in one line")
                for i = 1, #frames
                    line.start_time = subs[sel[#sel]].start_time + zf.math\round(#frames * frame_dur, 0) * (i - 1) / #frames
                    line.end_time = subs[sel[#sel]].start_time + zf.math\round(#frames * frame_dur, 0) * i / #frames
                    for k, v in pairs(frames[i])
                        line.text = v\gsub "}{", ""
                        subs.insert(sel[#sel] + add, line)
                        add += 1
            else
                aegisub.cancel!
        else
            error("Image format not supported!")
    return

aegisub.register_macro script_name, script_description, main