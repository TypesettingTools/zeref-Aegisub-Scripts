ffi = require "ffi"

import PNG, has_loaded, version from require "ZPNG.lodepng"
import BUFFER from require "ZF.img.buffer"

-- https://github.com/koreader/koreader-base/tree/master/ffi
class LIBPNG

    :version

    new: (@filename = filename) => assert has_loaded, "lodepng was not found"

    setArguments: =>
        @rawData = ffi.new "unsigned char*[1]"
        @width = ffi.new "int[1]"
        @height = ffi.new "int[1]"

    decode: =>
        @setArguments!

        err = PNG.lodepng_decode32_file @rawData, @width, @height, @filename
        assert err == 0, ffi.string PNG.lodepng_error_text err

        buffer = BUFFER @width[0], @height[0], 5, @rawData[0]
        buffer\set_allocated 1

        @rawData = buffer
        @width = buffer\get_width!
        @height = buffer\get_height!
        @bit_depth = buffer\get_bpp!

        @getPixel = (x, y) => buffer\get_pixel x, y

        @getData = =>
            @data = ffi.new "color_RGBA[?]", @width * @height

            for y = 0, @height - 1
                for x = 0, @width - 1
                    i = y * @width + x
                    with @getPixel(x, y)\get_color_32!
                        @data[i].r = .r
                        @data[i].g = .g
                        @data[i].b = .b
                        @data[i].a = .alpha

            return @data

        return @

{:LIBPNG}