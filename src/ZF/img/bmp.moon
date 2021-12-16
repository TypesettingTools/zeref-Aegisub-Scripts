ffi = require "ffi"

-- https://github.com/max1220/lua-bitmap
class LIBBMP

    new: (@filename = filename) =>

    read: =>
        file = io.open @filename, "rb"
        assert file, "Couldn't open JPG file"

        @rawData = file\read "*a"
        file\close!

    readWord: (offset) => @rawData\byte(offset + 1) * 256 + @rawData\byte offset

    readDword: (offset) => @readWord(offset + 2) * 65536 + @readWord offset

    decode: =>
        @read!

        if not @readDword(1) == 0x4D42
            error "Bitmap magic not found"

        assert @readWord(29) == 24, "Bitmap magic not found"
        assert @readDword(31) == 0, "Only uncompressed bitmaps supported"

        @pxOffset = @readWord 11
        @width = @readDword 19
        @height = @readDword 23
        @bit_depth = 24

        @getPixel = (x, y) =>
            assert not (x < 0 or x > @width or y < 0 or y > @height), "Out of bounds"

            index = @pxOffset + (@height - y - 1) * 3 * @width + x * 3
            b = @rawData\byte index + 1
            g = @rawData\byte index + 2
            r = @rawData\byte index + 3

            return r, g, b, 255

        @getData = =>
            @data = ffi.new "color_RGBA[?]", @width * @height

            for y = 0, @height - 1
                for x = 0, @width - 1
                    i = y * @width + x
                    r, g, b, a = @getPixel x, y
                    @data[i].r = r
                    @data[i].g = g
                    @data[i].b = b
                    @data[i].a = a

            return @data

        return @

{:LIBBMP}