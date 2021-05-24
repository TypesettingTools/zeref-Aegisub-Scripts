local *

png = require("img-libs.png.png")
gif = require("img-libs.gif.gif")
Yutils = require("Yutils")

png_util = {
    raster: (filename, reencode, one_line) ->
        png_raster = (data) ->
            w, h = data\getWidth!, data\getHeight!
            count_s, count_r, shape, color, alpha = {}, {}, {}, {}, {}
            for y = 0, h - 1
                count_s[y], count_r[y], shape[y] = 0, 0, ""
                for x = 0, w - 1
                    px_firs = data\getPixel(x + 0, y)
                    px_next = data\getPixel(x + 1, y)
                    --
                    color_firs = px_firs\getColorRGB32!
                    color_next = px_next\getColorRGB32!
                    alpha_firs = (("\\1aH%02X")\format(color_firs.alpha - 255))\gsub("(%x%x)%x%x%x%x%x%x", "%1")
                    color_firs = ("\\cH%02X%02X%02X")\format(color_firs.b, color_firs.g, color_firs.r)
                    color_next = ("\\cH%02X%02X%02X")\format(color_next.b, color_next.g, color_next.r)
                    --
                    color[y] = color_firs
                    alpha[y] = alpha_firs
                    --
                    if (color_firs == color_next)
                        count_s[y] += 1
                        count_r[y] += 1
                    else
                        if (alpha[y] == "\\1aHFF") or (color[y] == "\\cH4C7047")
                            color[y], alpha[y] = "", "\\1aHFF"
                        shape[y] ..= ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_r[y] + 1, count_r[y] + 1)
                        count_s[y] = (count_s[y] - count_r[y])
                        count_r[y] = 0
                if (shape[y] != "")
                    if (count_s[y] < w) and (count_s[y] > 0)
                        if (alpha[y] == "\\1aHFF") or (color[y] == "\\cH4C7047")
                            shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y])
                        else
                            shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y]) .. ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_s[y], count_s[y])
                    else
                        shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y])
                else
                    if (alpha[y] == "\\1aHFF") or (color[y] == "\\cH4C7047")
                        shape[y] = nil
                    else
                        shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0%s\\p1}m 0 0 l %d 0 %d 1 0 1 ")\format(y, color[y] .. alpha[y], w, w)
            if one_line
                one = ""
                for k, v in pairs(shape)
                    one ..= v\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
                one = ("{\\an7\\pos(0,0)\\bord0\\shad0\\p1}%s")\format(one)\gsub("{\\p0}\\N{\\p1}$", "")
                return {one}
            return shape
        png_decode = png.decode_from_file(filename)
        if reencode then
            filename_coded = filename\gsub("%.png$", "_coded.png") -- Temporary encoding filename
            png_decode\writePNG(png, filename_coded) -- Reencode the png file
            columns = png_raster(png.decode_from_file(filename_coded))
            os.remove(filename_coded) -- Remove the temporary file
            return columns
        else
            return png_raster(png_decode)
}

gif_util = {
    raster: (filename, one_line) ->
        gif_raster_frame = (frame, px = 0, py = 0) ->
            count_s, count_r, shape, color, alpha, i = {}, {}, {}, {}, {}, 0
            for y = 0, frame.h - 1
                count_s[y], count_r[y], shape[y] = 0, 0, ""
                for x = 0, frame.w - 1
                    data_firs = frame.data[i]
                    color_firs = ("\\cH%02X%02X%02X")\format(data_firs.b, data_firs.g, data_firs.r)
                    alpha_firs = (("\\1aH%02X")\format(data_firs.a - 255))\gsub("(%x%x)%x%x%x%x%x%x", "%1")
                    --
                    data_next = frame.data[i + 1]
                    color_next = ("\\cH%02X%02X%02X")\format(data_next.b, data_next.g, data_next.r)
                    --
                    color[y] = color_firs
                    alpha[y] = alpha_firs
                    --
                    if (color_firs == color_next)
                        count_s[y] += 1
                        count_r[y] += 1
                    else
                        color[y] = (alpha[y] == "\\1aHFF" and "" or color[y])
                        shape[y] = shape[y] .. ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_r[y] + 1, count_r[y] + 1)
                        count_s[y] = (count_s[y] - count_r[y])
                        count_r[y] = 0
                    i += 1
                if (shape[y] != "")
                    if (count_s[y] < frame.w) and (count_s[y] > 0)
                        if (alpha[y] == "\\1aHFF")
                            shape[y] = ("{\\an7\\pos(%d,%d)\\bord0\\shad0\\p1}%s")\format(px, py + y, shape[y])
                        else
                            shape[y] = ("{\\an7\\pos(%d,%d)\\bord0\\shad0\\p1}%s")\format(px, py + y, shape[y]) .. ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_s[y], count_s[y])
                    else
                        shape[y] = ("{\\an7\\pos(%d,%d)\\bord0\\shad0\\p1}%s")\format(px, py + y, shape[y])
                else
                    if (alpha[y] == "\\1aHFF")
                        shape[y] = nil
                    else
                        shape[y] = ("{\\an7\\pos(%d,%d)\\bord0\\shad0%s\\p1}m 0 0 l %d 0 %d 1 0 1 ")\format(px, py + y, color[y] .. alpha[y], frame.w, frame.w)
            if one_line
                one = ""
                for k, v in pairs(shape)
                    one ..= v\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
                one = ("{\\an7\\pos(0,0)\\bord0\\shad0\\p1}%s")\format(one)\gsub("{\\p0}\\N{\\p1}$", "")
                return {one}
            return shape
        get_gif, frames = gif.decode_from_file(filename), {}
        for k = 1, #get_gif.frames
            frames[k] = gif_raster_frame(get_gif.frames[k], get_gif.frames[k].x, get_gif.frames[k].y)
        return frames
}

bmp_util = {
    raster: (filename, one_line) ->
        bmp_raster = (data) ->
            w, h = data.width!, data.height!
            count_s, count_r, shape, color, alpha, i = {}, {}, {}, {}, {}, 0
            for y = 0, h - 1
                count_s[y], count_r[y], shape[y] = 0, 0, ""
                for x = 0, w - 1
                    i += 1
                    data_firs = data.data_packed![i]
                    color_firs = ("\\cH%02X%02X%02X")\format(data_firs.b, data_firs.g, data_firs.r)
                    alpha_firs = ("\\1aH%02X")\format(data_firs.a - 255)
                    --
                    data_next = data.data_packed![i + 1]
                    color_next = not data_next and color_firs or ("\\cH%02X%02X%02X")\format(data_next.b, data_next.g, data_next.r)
                    --
                    color[y] = color_firs
                    alpha[y] = alpha_firs
                    --
                    if (color_firs == color_next)
                        count_s[y] += 1
                        count_r[y] += 1
                    else
                        color[y] = (alpha[y] == "\\1aHFF" and "" or color[y])
                        shape[y] = shape[y] .. ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_r[y] + 1, count_r[y] + 1)
                        count_s[y] = (count_s[y] - count_r[y])
                        count_r[y] = 0
                if (shape[y] != "")
                    if (count_s[y] < w) and (count_s[y] > 0)
                        if (alpha[y] == "\\1aHFF")
                            shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y])
                        else
                            shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y]) .. ("{%s}m 0 0 l %d 0 %d 1 0 1 ")\format(color[y] .. alpha[y], count_s[y], count_s[y])
                    else
                        shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0\\p1}%s")\format(y, shape[y])
                else
                    if (alpha[y] == "\\1aHFF")
                        shape[y] = nil
                    else
                        shape[y] = ("{\\an7\\pos(0,%d)\\bord0\\shad0%s\\p1}m 0 0 l %d 0 %d 1 0 1 ")\format(y, color[y] .. alpha[y], w, w)
            if one_line
                one = ""
                for k, v in pairs(shape)
                    one ..= v\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
                one = ("{\\an7\\pos(0,0)\\bord0\\shad0\\p1}%s")\format(one)\gsub("{\\p0}\\N{\\p1}$", "")
                return {one}
            return shape
        return bmp_raster(Yutils.decode.create_bmp_reader(filename))
}

return {
    png: png_util,
    gif: gif_util,
    bmp: bmp_util
}