ffi = require "ffi"
import BUFFER from require "ZF.img.buffer"

-- https://github.com/koreader/koreader-base/tree/master/ffi
class LIBJPG

    new: (@filename = filename) => assert hasJPG, "libjpeg-turbo was not found"

    read: =>
        file = io.open @filename, "rb"
        assert file, "Couldn't open JPG file"

        @rawData = file\read "*a"
        file\close!

    setArguments: =>
        @width       = ffi.new "int[1]"
        @height      = ffi.new "int[1]"
        @jpegSubsamp = ffi.new "int[1]"
        @colorSpace  = ffi.new "int[1]"

    decode: (gray) =>
        @read!

        handle = JPG.tjInitDecompress!
        assert handle, "no TurboJPEG API decompressor handle"

        @setArguments!

        JPG.tjDecompressHeader3 handle, ffi.cast("const unsigned char*", @rawData), #@rawData, @width, @height, @jpegSubsamp, @colorSpace
        assert @width[0] > 0 and @height[0] > 0, "Image dimensions"

        buffer = gray and BUFFER(@width[0], @height[0], 1) or BUFFER @width[0], @height[0], 4
        format = gray and JPG.TJPF_GRAY or JPG.TJPF_RGB

        err = JPG.tjDecompress2(handle, ffi.cast("unsigned char*", @rawData), #@rawData, ffi.cast("unsigned char*", buffer.data), @width[0], buffer.pitch, @height[0], format, 0) == -1
        assert not err, "Decoding error"

        JPG.tjDestroy handle

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

{:LIBJPG}