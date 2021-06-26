local ffi = require "ffi"
local bff = require "img-libs.buffer"
local requireffi = require "requireffi.requireffi"
local C = nil

if ffi.os == "Windows" then
    if ffi.arch == "x64" then
        C = requireffi("img-libs.jpg.bin.x64")
    else
        C = requireffi("img-libs.jpg.bin.x86")
    end
elseif ffi.os == "Linux" then
    C = requireffi("img-libs.jpg.bin.libjpg")
end

ffi.cdef [[
    typedef void *tjhandle;
    enum TJPF {
        TJPF_RGB = 0,
        TJPF_BGR = 1,
        TJPF_RGBX = 2,
        TJPF_BGRX = 3,
        TJPF_XBGR = 4,
        TJPF_XRGB = 5,
        TJPF_GRAY = 6,
        TJPF_RGBA = 7,
        TJPF_BGRA = 8,
        TJPF_ABGR = 9,
        TJPF_ARGB = 10,
        TJPF_CMYK = 11,
        TJPF_UNKNOWN = -1,
    };
    enum TJSAMP {
        TJSAMP_444 = 0,
        TJSAMP_422,
        TJSAMP_420,
        TJSAMP_GRAY,
        TJSAMP_440,
        TJSAMP_411
    };
    typedef struct jpg_color {
        uint8_t r, g, b, a;
    } jpg_color;
    int tjDestroy(tjhandle handle);
    tjhandle tjInitDecompress(void);
    int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace);
    int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags);
]]

local jpg = function(filename, c_color)
    local file = io.open(filename, "rb")
    assert(file, "couldn't open JPG file")
    local data = file:read("*a")
    file:close()
    local handle = C.tjInitDecompress()
    assert(handle, "no TurboJPEG API decompressor handle")
    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local jpegSubsamp = ffi.new("int[1]")
    local colorspace = ffi.new("int[1]")
    C.tjDecompressHeader3(handle, ffi.cast("const unsigned char*", data), #data, width, height, jpegSubsamp, colorspace)
    assert(width[0] > 0 and height[0] > 0, "image dimensions")
    local buf, format
    if not c_color then
        buf = bff(width[0], height[0], 4)
        format = C.TJPF_RGB
    else
        buf = bff(width[0], height[0], 1)
        format = C.TJPF_GRAY
    end
    if C.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data, ffi.cast("unsigned char*", buf.data), width[0], buf.pitch, height[0], format, 0) == -1 then
        error("decoding JPEG file")
    end
    C.tjDestroy(handle)
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
        self.data = ffi.new("jpg_color[?]", self.width * self.height)
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

return {jpg = jpg}