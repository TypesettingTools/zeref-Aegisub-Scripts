require "ZF.defs.headers"

import CONFIG from require "ZF.defs.config"
import TABLE  from require "ZF.util.table"

import LIBBMP from require "ZF.img.bmp"
import LIBJPG from require "ZF.img.jpg"
import LIBGIF from require "ZF.img.gif"
import LIBPNG from require "ZF.img.png"

class IMAGE

    new: (filename) =>
        fileExist, __error = CONFIG\fileExist filename
        assert fileExist, __error

        @extension = type(filename) == "string" and filename\match("^.+%.(.+)$") or "gif"

        @infos = switch @extension
            when "png"                               then LIBPNG(filename)\decode!
            when "jpeg", "jpe", "jpg", "jfif", "jfi" then LIBJPG(filename)\decode!
            when "bmp", "dib"                        then LIBBMP(filename)\decode!
            when "gif"                               then LIBGIF(filename)\decode!

    getInfos: (frame = 1) =>
        infos = @extension == "gif" and @infos.frames[frame] or @infos
        if @extension == "gif"
            {delayMs: @delayMs, x: @x, y: @y} = infos
        @width = infos.width
        @height = infos.height
        @data = infos\getData!

    raster: (reduce, frame) =>
        @getInfos frame

        shpx = "m 0 0 l %d 0 %d 1 0 1"
        preset = "{\\an7\\pos(%d,%d)\\fscx100\\fscy100\\bord0\\shad0\\frz0%s\\p1}%s"

        realPixels = -> -- real pixels
            pixels = {}
            for y = 0, @height - 1
                for x = 0, @width - 1
                    i = y * @width + x
                    with @data[i]
                        color = ("\\cH%02X%02X%02X")\format .b, .g, .r
                        alpha = ("\\alphaH%02X")\format 255 - .a
                        continue if alpha == "\\alphaHFF"
                        TABLE(pixels)\push (preset)\format x, y, color .. alpha, "m 0 0 l 1 0 1 1 0 1"
            return pixels

        reducePixels = (oneLine) -> -- reduce pixels
            ct_s, ct_r, at_s, at_r, color, alpha, pixels = {}, {}, {}, {}, {}, {}, {}
            for y = 0, @height - 1
                ct_s[y], ct_r[y], at_s[y], at_r[y], pixels[y] = 0, 0, 0, 0, ""
                for x = 0, @width - 1
                    i = y * @width + x

                    currData = @data[i + 0]
                    nextData = @data[i + 1]

                    b, g, r, a = currData.b, currData.g, currData.r, currData.a
                    currColor = ("\\cH%02X%02X%02X")\format b, g, r
                    nextColor = ("\\cH%02X%02X%02X")\format nextData.b or b, nextData.g or g, nextData.r or r

                    currAlpha = ("\\alphaH%02X")\format 255 - a
                    nextAlpha = ("\\alphaH%02X")\format 255 - (nextData.a or a)

                    color[y], alpha[y] = currColor, currAlpha
                    if currColor == nextColor
                        ct_s[y] += 1
                        ct_r[y] += 1
                    else
                        if currAlpha == nextAlpha
                            alpha[y] = at_r[y] == 0 and alpha[y] or nil
                            at_s[y] += 1
                            at_r[y] += 1
                        else
                            at_s[y] -= at_r[y]
                            at_r[y] = 0
                        pixels[y] ..= ("{%s}#{shpx}")\format color[y] .. (alpha[y] or ""), ct_r[y] + 1, ct_r[y] + 1
                        ct_s[y] -= ct_r[y]
                        ct_r[y] = 0

                if pixels[y] != ""
                    pixels[y] = (preset)\format 0, y, "", pixels[y]
                    if ct_s[y] < @width and ct_s[y] > 0
                        pixels[y] ..= alpha[y] != "\\alphaHFF" and ("{%s}#{shpx}")\format(color[y] .. alpha[y], ct_s[y], ct_s[y]) or ""
                else
                    pixels[y] = alpha[y] != "\\alphaHFF" and (preset .. shpx)\format(0, y, color[y] .. alpha[y], "", @width, @width) or nil

            if oneLine
                line = ""
                for p, pixel in pairs pixels
                    line ..= pixel\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
                line = (preset)\format(0, 0, "", line)\gsub "{\\p0}\\N{\\p1}$", ""
                return {line}

            return pixels

        return reduce and (reduce == "oneLine" and reducePixels(true) or reducePixels!) or realPixels!

{:IMAGE}