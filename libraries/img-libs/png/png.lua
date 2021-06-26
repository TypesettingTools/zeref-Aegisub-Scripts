local ffi = require "ffi"
local bff = require "img-libs.buffer"
local requireffi = require "requireffi.requireffi"
local C = nil

if ffi.os == "Windows" then
    if ffi.arch == "x64" then
        C = requireffi("img-libs.png.bin.x64")
    else
        C = requireffi("img-libs.png.bin.x86")
    end
elseif ffi.os == "Linux" then
    C = requireffi("img-libs.png.bin.libpng")
end

ffi.cdef [[
    typedef enum LodePNGColorType LodePNGColorType;
    enum LodePNGColorType {
        LCT_GREY = 0,
        LCT_RGB = 2,
        LCT_PALETTE = 3,
        LCT_GREY_ALPHA = 4,
        LCT_RGBA = 6,
    };
    typedef struct png_color {
        uint8_t r, g, b, a;
    } png_color;
    const char *lodepng_error_text(unsigned int);
    unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
]]

local png = function(filename)
    local w, h, ptr = ffi.new("int[1]"), ffi.new("int[1]"), ffi.new("unsigned char*[1]")
    local err = C.lodepng_decode32_file(ptr, w, h, filename)
    assert(err == 0, ffi.string(C.lodepng_error_text(err)))
    local buf = bff(w[0], h[0], 5, ptr[0])
    buf:setAllocated(1)
    local obj = {
        data = buf,
        bit_depth = buf:getBpp(),
		width = buf:getWidth(),
		height = buf:getHeight()
    }
    function obj:get_pixel(x, y)
        return buf:getPixel(x, y)
    end
    function obj:map()
        local i = 0
        self.data = ffi.new("png_color[?]", self.width * self.height)
        for y = 0, self.height - 1 do
            for x = 0, self.width - 1 do
                local color = self:get_pixel(x, y):getColorRGB32()
                self.data[i].r = color.r
                self.data[i].g = color.g
                self.data[i].b = color.b
                self.data[i].a = color.alpha
                i = i + 1
            end
        end
        return self
    end
    return obj
end

return {png = png}