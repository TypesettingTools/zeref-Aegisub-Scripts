ffi = require "ffi"
import TABLE from require "ZF.util.table"

-- https://luapower.com/giflib
class LIBGIF

    new: (@filename = filename) => assert hasGIF, "giflib was not found"

    read: =>
        open = (err) -> GIF.DGifOpenFileName @filename, err

        err = ffi.new "int[1]"
        @file = open(err) or nil

        unless @file
            error ffi.string(GIF.GifErrorString(err[0]))

        return @

    close: => ffi.C.free(@file) if GIF.DGifCloseFile(@file) == 0

    decode: (transparent = true) =>
        @read!

        check = ->
            res = GIF.DGifSlurp @file
            if res != 0
                return
            error ffi.string(GIF.GifErrorString(@file.Error))

        check!
        @frames = {}
        @width = @file.SWidth
        @height = @file.SHeight

        gcb = ffi.new "GraphicsControlBlock"
        for i = 0, @file.ImageCount - 1
            si = @file.SavedImages[i]

            local delayMs, tColorK
            if GIF.DGifSavedExtensionToGCB(@file, i, gcb) == 1
                delayMs = gcb.DelayTime * 10
                tColorK = gcb.TransparentColor

            width, height = si.ImageDesc.Width, si.ImageDesc.Height
            colorMap = si.ImageDesc.ColorMap != nil and si.ImageDesc.ColorMap or @file.SColorMap

            length = width * height
            data = ffi.new "color_RGBA[?]", length
            for j = 0, length - 1
                k = si.RasterBits[j]
                assert k < colorMap.ColorCount

                if k == tColorK and transparent
                    data[j].b = 0
                    data[j].g = 0
                    data[j].r = 0
                    data[j].a = 0
                else
                    data[j].b = colorMap.Colors[k].Blue
                    data[j].g = colorMap.Colors[k].Green
                    data[j].r = colorMap.Colors[k].Red
                    data[j].a = 0xff

            TABLE(@frames)\push {:data, :width, :height, :delayMs, x: si.ImageDesc.Left, y: si.ImageDesc.Top, getData: => data}

        @close!

        return @

{:LIBGIF}