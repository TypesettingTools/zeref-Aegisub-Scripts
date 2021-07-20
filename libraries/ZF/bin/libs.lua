-- load internal libs
local ffi = require "ffi"
local bit = require "bit"

-- load external libs
local requireffi = require "requireffi.requireffi"

local CPP, PNG, JPG, GIF
if "Windows" == ffi.os then
    if "x64" == ffi.arch then
        CPP = requireffi("ZF.bin.win.clipper64")
        PNG = requireffi("ZF.bin.win.png64")
        JPG = requireffi("ZF.bin.win.jpg64")
        GIF = requireffi("ZF.bin.win.gif64")
    elseif "x86" == ffi.arch then
        CPP = requireffi("ZF.bin.win.clipper86")
        PNG = requireffi("ZF.bin.win.png86")
        JPG = requireffi("ZF.bin.win.jpg86")
        GIF = requireffi("ZF.bin.win.gif86")
    end
elseif "Linux" == ffi.os then
    if ffi.arch == "x64" then
        CPP = requireffi("ZF.bin.linux.libclipper64")
        PNG = requireffi("ZF.bin.linux.libpng64")
        JPG = requireffi("ZF.bin.linux.libjpg64")
        GIF = requireffi("ZF.bin.linux.libgif64")
    end
else
    return error("Not compatible with your operating system!")
end

-- Clipper defs
ffi.cdef [[
    // structs
    typedef struct __Point64 {
        int64_t x;
        int64_t y;
    } Point64;
    typedef struct __zf_path zf_path;
    typedef struct __zf_paths zf_paths;
    typedef struct __zf_clipper zf_clipper;
    typedef struct __zf_clipper_offset zf_clipper_offset;
    // error
    const char* err_msg();
    // path
    zf_path* path_new();
    void path_free(zf_path* self);
    Point64* path_get(zf_path* self, int i);
    bool path_add(zf_path* self, int64_t x, int64_t y);
    int path_size(zf_path* self);
    // paths
    zf_paths* paths_new();
    void paths_free(zf_paths* self);
    zf_path* paths_get(zf_paths* self, int i);
    bool paths_add(zf_paths* self, zf_path* path);
    int paths_size(zf_paths* self);
    // offset
    zf_clipper_offset* offset_new(double mt, double at);
    void offset_free(zf_clipper_offset* self);
    zf_paths* offset_add_path(zf_clipper_offset* self, zf_path* path, double delta, int jt, int et);
    zf_paths* offset_add_paths(zf_clipper_offset* self, zf_paths* path, double delta, int jt, int et);
    // clipper
    zf_clipper* clipper_new();
    void clipper_free(zf_clipper* self);
    bool clipper_add_path(zf_clipper* self, zf_path* path, int type, bool is_open);
    bool clipper_add_paths(zf_clipper* self, zf_paths* paths, int type, bool is_open);
    zf_paths* clipper_execute(zf_clipper* self, int ct, int fr);
]]

-- Buffer defs
ffi.cdef [[
    typedef struct Color8 {
        uint8_t a;
    } Color8;
    typedef struct Color8A {
        uint8_t a;
        uint8_t alpha;
    } Color8A;
    typedef struct ColorRGB16 {
        uint16_t v;
    } ColorRGB16;
    typedef struct ColorRGB24 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
    } ColorRGB24;
    typedef struct ColorRGB32 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t alpha;
    } ColorRGB32;
    typedef struct ColorRGBA {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } ColorRGBA;
    typedef struct BlitBuffer {
        int w;
        int h;
        int pitch;
        uint8_t *data;
        uint8_t config;
    } BlitBuffer;
    typedef struct BlitBuffer8 {
        int w;
        int h;
        int pitch;
        Color8 *data;
        uint8_t config;
    } BlitBuffer8;
    typedef struct BlitBuffer8A {
        int w;
        int h;
        int pitch;
        Color8A *data;
        uint8_t config;
    } BlitBuffer8A;
    typedef struct BlitBufferRGB16 {
        int w;
        int h;
        int pitch;
        ColorRGB16 *data;
        uint8_t config;
    } BlitBufferRGB16;
    typedef struct BlitBufferRGB24 {
        int w;
        int h;
        int pitch;
        ColorRGB24 *data;
        uint8_t config;
    } BlitBufferRGB24;
    typedef struct BlitBufferRGB32 {
        int w;
        int h;
        int pitch;
        ColorRGB32 *data;
        uint8_t config;
    } BlitBufferRGB32;
    void *malloc(int size);
    void free(void *ptr);
]]

-- GIF defs
ffi.cdef [[
    typedef unsigned char GifByteType;
    typedef int GifWord;
    typedef struct GifColorType {
        GifByteType Red, Green, Blue;
    } GifColorType;
    typedef struct ColorMapObject {
        int ColorCount;
        int BitsPerPixel;
        _Bool SortFlag;
        GifColorType *Colors;
    } ColorMapObject;
    typedef struct GifImageDesc {
        GifWord Left, Top, Width, Height;
        _Bool Interlace;
        ColorMapObject *ColorMap;
    } GifImageDesc;
    typedef struct ExtensionBlock {
        int ByteCount;
        GifByteType *Bytes;
        int Function;
    } ExtensionBlock;
    typedef struct SavedImage {
        GifImageDesc ImageDesc;
        GifByteType *RasterBits;
        int ExtensionBlockCount;
        ExtensionBlock *ExtensionBlocks;
    } SavedImage;
    typedef struct GifFileType {
        GifWord SWidth, SHeight;
        GifWord SColorResolution;
        GifWord SBackGroundColor;
        GifByteType AspectByte;
        ColorMapObject *SColorMap;
        int ImageCount;
        GifImageDesc Image;
        SavedImage *SavedImages;
        int ExtensionBlockCount;
        ExtensionBlock *ExtensionBlocks;
        int Error;
        void *UserData;
        void *Private;
    } GifFileType;
    typedef int (*GifInputFunc) (GifFileType *, GifByteType *, int);
    typedef int (*GifOutputFunc) (GifFileType *, const GifByteType *, int);
    typedef struct GraphicsControlBlock {
        int DisposalMode;
        _Bool UserInputFlag;
        int DelayTime;
        int TransparentColor;
    } GraphicsControlBlock;
    GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
    int DGifSlurp(GifFileType * GifFile);
    GifFileType *DGifOpen(void *userPtr, GifInputFunc readFunc, int *Error);
    int DGifCloseFile(GifFileType * GifFile);
    char *GifErrorString(int ErrorCode);
    int DGifSavedExtensionToGCB(GifFileType *GifFile, int ImageIndex, GraphicsControlBlock *GCB);
]]

-- TurboJPEG defs
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
    int tjDestroy(tjhandle handle);
    tjhandle tjInitDecompress(void);
    int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace);
    int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags);
]]

-- LodePNG defs
ffi.cdef [[
    typedef enum LodePNGColorType LodePNGColorType;
    enum LodePNGColorType {
        LCT_GREY = 0,
        LCT_RGB = 2,
        LCT_PALETTE = 3,
        LCT_GREY_ALPHA = 4,
        LCT_RGBA = 6,
    };
    const char *lodepng_error_text(unsigned int);
    unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
]]

-- == [[ CLIPPER LIB ]] == --

-- enums
local CLIP_TYPE = {none = 0, intersection = 1, union = 2, difference = 3, xor = 4}
local FILL_RULE = {even_odd = 0, non_zero = 1, positive = 2, negative = 3}
local PATH_TYPE = {subject = 0, clip = 1}
local JOIN_TYPE = {square = 0, round = 1, miter = 2}
local END_TYPE  = {polygon = 0, open_joined = 1, open_butt = 2, open_square = 3, open_round = 4}

-- create tables
PATH, PATHS, CLIPPER, OFFSET = {}, {}, {}, {}

-- init metatable path
function PATH.new()
    return ffi.gc(CPP.path_new(), CPP.path_free)
end
function PATH:get(i)
    return CPP.path_get(self, i - 1)
end
function PATH:add(x, y)
    return CPP.path_add(self, x, y)
end
function PATH:size()
    return CPP.path_size(self)
end

-- init metatable paths
function PATHS.new()
    return ffi.gc(CPP.paths_new(), CPP.paths_free)
end
function PATHS:get(i)
    return CPP.paths_get(self, i - 1)
end
function PATHS:add(p)
    return CPP.paths_add(self, p)
end
function PATHS:size()
    return CPP.paths_size(self)
end

-- init metatable clipper
function CLIPPER.new()
    return ffi.gc(CPP.clipper_new(), CPP.clipper_free)
end
function CLIPPER:add_path(p, pt, is_open)
    CPP.clipper_add_path(self, p, PATH_TYPE[pt], is_open or false)
end
function CLIPPER:add_paths(p, pt, is_open)
    CPP.clipper_add_paths(self, p, PATH_TYPE[pt], is_open or false)
end
function CLIPPER:execute(ct, fr)
    ct = CLIP_TYPE[ct or "intersection"]
    fr = FILL_RULE[fr or "even_odd"]
    return CPP.clipper_execute(self, ct, fr)
end

-- init metatable offset
function OFFSET.new(mt, at)
    return ffi.gc(CPP.offset_new(mt or 2, at or 0), CPP.offset_free)
end
function OFFSET:add_path(p, delta, jt, et)
    jt = JOIN_TYPE[jt or "round"]
    et = END_TYPE[et or "polygon"]
    CPP.offset_add_path(self, p, delta, jt, et)
end
function OFFSET:add_paths(p, delta, jt, et)
    jt = JOIN_TYPE[jt or "round"]
    et = END_TYPE[et or "polygon"]
    return CPP.offset_add_paths(self, p, delta, jt, et)
end

ffi.metatype("zf_path",           {__index = PATH})
ffi.metatype("zf_paths",          {__index = PATHS})
ffi.metatype("zf_clipper",        {__index = CLIPPER})
ffi.metatype("zf_clipper_offset", {__index = OFFSET})

-- == [[ IMAGE LIBS ]] == --

local Color8     = ffi.typeof("Color8")
local Color8A    = ffi.typeof("Color8A")
local ColorRGB16 = ffi.typeof("ColorRGB16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")
local intt       = ffi.typeof("int")
local uint8pt    = ffi.typeof("uint8_t*")

local Color8_mt     = {__index = {}}
local Color8A_mt    = {__index = {}}
local ColorRGB16_mt = {__index = {}}
local ColorRGB24_mt = {__index = {}}
local ColorRGB32_mt = {__index = {}}

function Color8_mt.__index:getColor8()
    return self
end

function Color8A_mt.__index:getColor8()
    return Color8(self.a)
end

function ColorRGB16_mt.__index:getColor8()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return Color8(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14))
end

function ColorRGB24_mt.__index:getColor8()
    return Color8(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14))
end

ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

function Color8_mt.__index:getColor8A()
    return Color8A(self.a, 0)
end

function Color8A_mt.__index:getColor8A()
    return self
end

function ColorRGB16_mt.__index:getColor8A()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return Color8A(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0)
end

function ColorRGB24_mt.__index:getColor8A()
    return Color8A(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14), 0)
end

function ColorRGB32_mt.__index:getColor8A()
    return Color8A(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14), self:getAlpha())
end

function Color8_mt.__index:getColorRGB16()
    local v = self:getColor8().a
    local v5bit = bit.rshift(v, 3)
    return ColorRGB16(bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit)
end

Color8A_mt.__index.getColorRGB16 = Color8_mt.__index.getColorRGB16

function ColorRGB16_mt.__index:getColorRGB16()
    return self
end

function ColorRGB24_mt.__index:getColorRGB16()
    return ColorRGB16(bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3))
end

ColorRGB32_mt.__index.getColorRGB16 = ColorRGB24_mt.__index.getColorRGB16

function Color8_mt.__index:getColorRGB24()
    local v = self:getColor8()
    return ColorRGB24(v.a, v.a, v.a)
end

Color8A_mt.__index.getColorRGB24 = Color8_mt.__index.getColorRGB24

function ColorRGB16_mt.__index:getColorRGB24()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return ColorRGB24(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2))
end

function ColorRGB24_mt.__index:getColorRGB24()
    return self
end

function ColorRGB32_mt.__index:getColorRGB24()
    return ColorRGB24(self.r, self.g, self.b)
end

function Color8_mt.__index:getColorRGB32()
    return ColorRGB32(self.a, self.a, self.a, 0xFF)
end

function Color8A_mt.__index:getColorRGB32()
    return ColorRGB32(self.a, self.a, self.a, self.alpha)
end

function ColorRGB16_mt.__index:getColorRGB32()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return ColorRGB32(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF)
end

function ColorRGB24_mt.__index:getColorRGB32()
    return ColorRGB32(self.r, self.g, self.b, 0xFF)
end

function ColorRGB32_mt.__index:getColorRGB32()
    return self
end

function Color8_mt.__index:getR()
    return self:getColor8().a
end

Color8_mt.__index.getG = Color8_mt.__index.getR
Color8_mt.__index.getB = Color8_mt.__index.getR

function Color8_mt.__index:getAlpha()
    return intt(0xFF)
end

Color8A_mt.__index.getR = Color8_mt.__index.getR
Color8A_mt.__index.getG = Color8_mt.__index.getR
Color8A_mt.__index.getB = Color8_mt.__index.getR

function Color8A_mt.__index:getAlpha()
    return self.alpha
end

function ColorRGB16_mt.__index:getR()
    local r = bit.rshift(self.v, 11)
    return bit.lshift(r, 3) + bit.rshift(r, 2)
end

function ColorRGB16_mt.__index:getG()
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    return bit.lshift(g, 2) + bit.rshift(g, 4)
end

function ColorRGB16_mt.__index:getB()
    local b = bit.rshift(self.v, 0x001F)
    return bit.lshift(b, 3) + bit.rshift(b, 2)
end

ColorRGB16_mt.__index.getAlpha = Color8_mt.__index.getAlpha

function ColorRGB24_mt.__index:getR()
    return self.r
end

function ColorRGB24_mt.__index:getG()
    return self.g
end

function ColorRGB24_mt.__index:getB()
    return self.b
end

ColorRGB24_mt.__index.getAlpha = Color8_mt.__index.getAlpha
ColorRGB32_mt.__index.getR     = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG     = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB     = ColorRGB24_mt.__index.getB

function ColorRGB32_mt.__index:getAlpha()
    return self.alpha
end

local BB8_mt     = {__index = {}}
local BB8A_mt    = {__index = {}}
local BBRGB16_mt = {__index = {}}
local BBRGB24_mt = {__index = {}}
local BBRGB32_mt = {__index = {}}
local BB_mt      = {__index = {}}

function BB_mt.__index:getRotation()
    return bit.rshift(bit.band(0x0C, self.config), 2)
end

function BB_mt.__index:getInverse()
    return bit.rshift(bit.band(0x02, self.config), 1)
end

function BB_mt.__index:setAllocated(allocated)
    self.config = bit.bor(bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0))
end

function BB8_mt.__index:getBpp()
    return 8
end

function BB8A_mt.__index:getBpp()
    return 8
end

function BBRGB16_mt.__index:getBpp()
    return 16
end

function BBRGB24_mt.__index:getBpp()
    return 24
end

function BBRGB32_mt.__index:getBpp()
    return 32
end

function BB_mt.__index:setType(type_id)
    self.config = bit.bor(bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4))
end

function BB_mt.__index:getPhysicalCoordinates(x, y)
    local rotation = self:getRotation()
    if rotation == 0 then
        return x, y
    elseif rotation == 1 then
        return self.w - y - 1, x
    elseif rotation == 2 then
        return self.w - x - 1, self.h - y - 1
    elseif rotation == 3 then
        return y, self.h - x - 1
    end
end

function BB_mt.__index:getPixelP(x, y)
    return ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x
end

function BB_mt.__index:getPixel(x, y)
    local px, py = self:getPhysicalCoordinates(x, y)
    local color = self:getPixelP(px, py)[0]
    if self:getInverse() == 1 then
        color = color:invert()
    end
    return color
end

function BB_mt.__index:getWidth()
    if 0 == bit.band(1, self:getRotation()) then
        return self.w
    else
        return self.h
    end
end

function BB_mt.__index:getHeight()
    if 0 == bit.band(1, self:getRotation()) then
        return self.h
    else
        return self.w
    end
end

for name, func in pairs(BB_mt.__index) do
    if not BB8_mt.__index[name] then
        BB8_mt.__index[name] = func
    end
    if not BB8A_mt.__index[name] then
        BB8A_mt.__index[name] = func
    end
    if not BBRGB16_mt.__index[name] then
        BBRGB16_mt.__index[name] = func
    end
    if not BBRGB24_mt.__index[name] then
        BBRGB24_mt.__index[name] = func
    end
    if not BBRGB32_mt.__index[name] then
        BBRGB32_mt.__index[name] = func
    end
end

local BlitBuffer8     = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBuffer8A    = ffi.metatype("BlitBuffer8A", BB8A_mt)
local BlitBufferRGB16 = ffi.metatype("BlitBufferRGB16", BBRGB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

ffi.metatype("Color8",     Color8_mt)
ffi.metatype("Color8A",    Color8A_mt)
ffi.metatype("ColorRGB16", ColorRGB16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

local function BUFFER(width, height, buffertype, dataptr, pitch)
    buffertype = buffertype or 1
    if pitch == nil then
        if buffertype == 1 then
            pitch = width
        elseif buffertype == 2 then
            pitch = bit.lshift(width, 1)
        elseif buffertype == 3 then
            pitch = bit.lshift(width, 1)
        elseif buffertype == 4 then
            pitch = width * 3
        elseif buffertype == 5 then
            pitch = bit.lshift(width, 2)
        end
    end
    local bb = nil
    if buffertype == 1 then
        bb = BlitBuffer8(width, height, pitch, nil, 0)
    elseif buffertype == 2 then
        bb = BlitBuffer8A(width, height, pitch, nil, 0)
    elseif buffertype == 3 then
        bb = BlitBufferRGB16(width, height, pitch, nil, 0)
    elseif buffertype == 4 then
        bb = BlitBufferRGB24(width, height, pitch, nil, 0)
    elseif buffertype == 5 then
        bb = BlitBufferRGB32(width, height, pitch, nil, 0)
    else
        error("unknown blitbuffer type")
    end
    bb:setType(buffertype)
    if dataptr == nil then
        dataptr = ffi.C.malloc(pitch * height)
        assert(dataptr, "cannot allocate memory for blitbuffer")
        ffi.fill(dataptr, pitch * height)
        bb:setAllocated(1)
    end
    bb.data = ffi.cast(bb.data, dataptr)
    return bb
end

local function IMG(filename)
    -- utils
    local function gopen(arg)
        local function opener(name, err)
            return GIF.DGifOpenFileName(name, err)
        end
        local err = ffi.new("int[1]")
        local ft = opener(arg, err) and opener(arg, err) or nil
        return not ft and error(ffi.string(GIF.GifErrorString(err[0]))) or ft
    end
    local function gclose(ft)
        if GIF.DGifCloseFile(ft) == 0 then
            return ffi.C.free(ft)
        end
    end
    local function checknz(ft, res)
        if res ~= 0 then
            return
        end
        return error(ffi.string(GIF.GifErrorString(ft.Error)))
    end
    local function read_word(data, offset)
        return data:byte(offset + 1) * 256 + data:byte(offset)
    end
    local function read_dword(data, offset)
        return read_word(data, offset + 2) * 65536 + read_word(data, offset)
    end
    -- decoders
    local function gif(opaque)
        local transparent = not opaque
        local ft = gopen(filename)
        checknz(ft, GIF.DGifSlurp(ft))
        local obj = {
            frames = {},
            width = ft.SWidth,
            height = ft.SHeight
        }
        local gcb = ffi.new("GraphicsControlBlock")
        for i = 0, ft.ImageCount - 1 do
            local si = ft.SavedImages[i]
            local delay_ms, tcolor_idx
            if GIF.DGifSavedExtensionToGCB(ft, i, gcb) == 1 then
                delay_ms = gcb.DelayTime * 10
                tcolor_idx = gcb.TransparentColor
            end
            local w, h = si.ImageDesc.Width, si.ImageDesc.Height
            local colormap = si.ImageDesc.ColorMap ~= nil and si.ImageDesc.ColorMap or ft.SColorMap
            local size = w * h
            local data = ffi.new("gif_color[?]", size)
            for k = 0, size - 1 do
                local idx = si.RasterBits[k]
                assert(idx < colormap.ColorCount)
                if idx == tcolor_idx and transparent then
                    data[k].b = 0
                    data[k].g = 0
                    data[k].r = 0
                    data[k].a = 0
                else
                    data[k].b = colormap.Colors[idx].Blue
                    data[k].g = colormap.Colors[idx].Green
                    data[k].r = colormap.Colors[idx].Red
                    data[k].a = 0xff
                end
            end
            local img = {
                data = data,
                width = w,
                height = h,
                x = si.ImageDesc.Left,
                y = si.ImageDesc.Top,
                delay_ms = delay_ms
            }
            obj.frames[#obj.frames + 1] = img
        end
        gclose(ft)
        return obj.frames
    end
    local function jpg(c_color)
        local file = io.open(filename, "rb")
        assert(file, "couldn't open JPG file")
        local data = file:read("*a")
        file:close()
        local handle = JPG.tjInitDecompress()
        assert(handle, "no TurboJPEG API decompressor handle")
        local width = ffi.new("int[1]")
        local height = ffi.new("int[1]")
        local jpegSubsamp = ffi.new("int[1]")
        local colorspace = ffi.new("int[1]")
        JPG.tjDecompressHeader3(handle, ffi.cast("const unsigned char*", data), #data, width, height, jpegSubsamp, colorspace)
        assert(width[0] > 0 and height[0] > 0, "image dimensions")
        local buf, format
        if not c_color then
            buf = BUFFER(width[0], height[0], 4)
            format = JPG.TJPF_RGB
        else
            buf = BUFFER(width[0], height[0], 1)
            format = JPG.TJPF_GRAY
        end
        if JPG.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data, ffi.cast("unsigned char*", buf.data), width[0], buf.pitch, height[0], format, 0) == -1 then
            error("decoding JPEG file")
        end
        JPG.tjDestroy(handle)
        local obj = {
            data = buf,
            bit_depth = buf:getBpp(),
            width = buf:getWidth(),
            height = buf:getHeight()
        }
        local i = 0
        obj.data = ffi.new("ColorRGBA[?]", obj.width * obj.height)
        for y = 0, obj.height - 1 do
            for x = 0, obj.width - 1 do
                local color = buf:getPixel(x, y):getColorRGB32()
                obj.data[i].r = color.r
                obj.data[i].g = color.g
                obj.data[i].b = color.b
                obj.data[i].a = color.alpha
                i = i + 1
            end
        end
        return obj
    end
    local function png()
        local w, h, ptr = ffi.new("int[1]"), ffi.new("int[1]"), ffi.new("unsigned char*[1]")
        local err = PNG.lodepng_decode32_file(ptr, w, h, filename)
        assert(err == 0, ffi.string(PNG.lodepng_error_text(err)))
        local buf = BUFFER(w[0], h[0], 5, ptr[0])
        buf:setAllocated(1)
        local obj = {
            data = buf,
            bit_depth = buf:getBpp(),
            width = buf:getWidth(),
            height = buf:getHeight()
        }
        local i = 0
        obj.data = ffi.new("ColorRGBA[?]", obj.width * obj.height)
        for y = 0, obj.height - 1 do
            for x = 0, obj.width - 1 do
                local color = buf:getPixel(x, y):getColorRGB32()
                obj.data[i].r = color.r
                obj.data[i].g = color.g
                obj.data[i].b = color.b
                obj.data[i].a = color.alpha
                i = i + 1
            end
        end
        return obj
    end
    local function bmp()
        local file = assert(io.open(filename, "rb"), "Can't open file!")
        local data = file:read("*a")
        file:close()
        if not read_dword(data, 1) == 0x4D42 then -- Bitmap "magic" header
            return nil, "Bitmap magic not found"
        elseif read_word(data, 29) ~= 24 then -- Bits per pixel
            return nil, "Only 24bpp bitmaps supported"
        elseif read_dword(data, 31) ~= 0 then -- Compression
            return nil, "Only uncompressed bitmaps supported"
        end
        local obj = {
            data = data,
            bit_depth = 24,
            pixel_offset = read_word(data, 11),
            width = read_dword(data, 19),
            height = read_dword(data, 23)
        }
        function obj:get_pixel(x, y)
            if (x < 0) or (x > self.width) or (y < 0) or (y > self.height) then
                return nil, "Out of bounds"
            end
            local index = self.pixel_offset + (self.height - y - 1) * 3 * self.width + x * 3
            local b = data:byte(index + 1)
            local g = data:byte(index + 2)
            local r = data:byte(index + 3)
            return r, g, b
        end
        local i = 0
        obj.data = ffi.new("ColorRGBA[?]", obj.width * obj.height)
        for y = 0, obj.height - 1 do
            for x = 0, obj.width - 1 do
                local r, g, b = obj:get_pixel(x, y)
                obj.data[i].r = r
                obj.data[i].g = g
                obj.data[i].b = b
                obj.data[i].a = 255
                i = i + 1
            end
        end
        return obj
    end
    local tracer = function(concat, round)
        local obj = {versionnumber = "1.2.6"}
        local ext = type(filename) == "string" and filename:match("^.+%.(.+)$") or "gif"
        if ext == "png" then
            obj.imgd = png()
        elseif ext == "jpeg" or ext == "jpe" or ext == "jpg" or ext == "jfif" or ext == "jfi" then
            obj.imgd = jpg()
        elseif ext == "bmp" or ext == "dib" then
            obj.imgd = bmp()
        elseif ext == "gif" then
            obj.imgd = filename
        end
        obj.optionpresets = {
            default = {
                -- Tracing
                ltres = 1,
                qtres = 1,
                pathomit = 8,
                rightangleenhance = true,
                -- Color quantization
                colorsampling = 2,
                numberofcolors = 16,
                mincolorratio = 0,
                colorquantcycles = 3,
                -- shape rendering
                strokewidth = 1,
                scale = 1,
                roundcoords = 2,
                deletewhite = false,
                deleteblack = false,
                -- Blur
                blurradius = 0,
                blurdelta = 20
            }
        }
        -- Lookup tables for pathscan
        -- pathscan_combined_lookup[arr[py][px]][dir + 1] = {nextarrpypx, nextdir, deltapx, deltapy}
        -- arr[py][px] == 15 or arr[py][px] == 0 is invalid
        obj.pathscan_combined_lookup = {
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}},
            {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}},
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}},
            {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}},
            {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}},
            {{13, 3, 0, 1},    {13, 2, -1, 0},   {7, 1, 0, -1},    {7, 0, 1, 0}},
            {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}},
            {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}},
            {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}},
            {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}},
            {{11, 1, 0, -1},   {14, 0, 1, 0},    {14, 3, 0, 1},    {11, 2, -1, 0}},
            {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}},
            {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}},
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}},
            {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}},
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
        }
        -- Gaussian kernels for blur
        obj.gks = {
            {0.27901, 0.44198, 0.27901},
            {0.135336, 0.228569, 0.272192, 0.228569, 0.135336},
            {0.086776, 0.136394, 0.178908, 0.195843, 0.178908, 0.136394, 0.086776},
            {0.063327, 0.093095, 0.122589, 0.144599, 0.152781, 0.144599, 0.122589, 0.093095, 0.063327},
            {0.049692, 0.069304, 0.089767, 0.107988, 0.120651, 0.125194, 0.120651, 0.107988, 0.089767, 0.069304, 0.049692}
        }
        -- randomseed
        math.randomseed(os.time())
        -- Tracing imagedata, then returning tracedata (layers with paths, palette, image size)
        function obj:to_trace_data(options)
            options = self:checkoptions(options)
            -- 1. Color quantization
            local ii = self:colorquantization(self.imgd, options)
            -- create tracedata object
            local tracedata = {
                layers = {},
                palette = ii.palette,
                width = #ii.array[0] - 1,
                height = #ii.array - 1
            }
            -- Loop to trace each color layer
            for colornum = 0, #ii.palette - 1 do
                -- layeringstep -> pathscan -> internodes -> batchtracepaths
                local layeringstep = self:layeringstep(ii, colornum)
                local pathscan = self:pathscan(layeringstep, options.pathomit)
                local internodes = self:internodes(pathscan, options)
                local tracedlayer = self:batchtracepaths(internodes, options.ltres, options.qtres)
                table.insert(tracedata.layers, tracedlayer)
            end
            return tracedata
        end
        -- Tracing imagedata, then returning the scaled svg string
        function obj:to_shape(options)
            options = self:checkoptions(options)
            local td = self:to_trace_data(options)
            return self:get_shape(td, options)
        end
        -- creating options object, setting defaults for missing values
        function obj:checkoptions(options)
            options = options or {}
            -- Option preset
            if type(options) == "string" then
                options = options:lower()
                options = not self.optionpresets[options] and {} or self.optionpresets[options]
            end
            -- Defaults
            for k in pairs(self.optionpresets.default) do
                if not rawget(options, k) then
                    options[k] = self.optionpresets.default[k]
                end
            end
            -- options.pal is not defined here, the custom palette should be added externally
            -- options.pal = {{"r" = 0,"g" = 0,"b" = 0,"a" = 255}, {...}, ...}
            return options
        end
        function obj:blur(imgd, radius, delta)
            -- new ImageData
            local imgd2 = {
                width = imgd.width,
                height = imgd.height,
                data = ffi.new("ColorRGBA[?]", imgd.height * imgd.width)
            }
            -- radius and delta limits, this kernel
            radius = math.floor(radius)
            if radius < 1 then
                return imgd
            end
            if radius > 5 then
                radius = 5
            end
            delta = math.abs(delta)
            if delta > 1024 then
                delta = 1024
            end
            local thisgk = self.gks[radius]
            -- loop through all pixels, horizontal blur
            for j = 0, imgd.height - 1 do
                for i = 0, imgd.width - 1 do
                    local racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                    -- gauss kernel loop
                    for k = -radius, radius do
                        -- add weighted color values
                        if i + k > 0 and i + k < imgd.width then
                            local idx = j * imgd.width + i + k
                            racc = racc + imgd.data[idx].r * thisgk[k + radius + 1]
                            gacc = gacc + imgd.data[idx].g * thisgk[k + radius + 1]
                            bacc = bacc + imgd.data[idx].b * thisgk[k + radius + 1]
                            aacc = aacc + imgd.data[idx].a * thisgk[k + radius + 1]
                            wacc = wacc + thisgk[k + radius + 1]
                        end
                    end
                    -- The new pixel
                    local idx = j * imgd.width + i
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
                end
            end
            -- copying the half blurred imgd2
            local himgd = imgd2.data -- table_copy(imgd2.data)
            -- loop through all pixels, vertical blur
            for j = 0, imgd.height - 1 do
                for i = 0, imgd.width - 1 do
                    local racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                    -- gauss kernel loop
                    for k = -radius, radius do
                        -- add weighted color values
                        if j + k > 0 and j + k < imgd.height then
                            local idx = (j + k) * imgd.width + i
                            racc = racc + himgd[idx].r * thisgk[k + radius + 1]
                            gacc = gacc + himgd[idx].g * thisgk[k + radius + 1]
                            bacc = bacc + himgd[idx].b * thisgk[k + radius + 1]
                            aacc = aacc + himgd[idx].a * thisgk[k + radius + 1]
                            wacc = wacc + thisgk[k + radius + 1]
                        end
                    end
                    -- The new pixel
                    local idx = j * imgd.width + i
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
                end
            end
            -- Selective blur: loop through all pixels
            for j = 0, imgd.height - 1 do
                for i = 0, imgd.width - 1 do
                    local idx = j * imgd.width + i
                    -- d is the difference between the blurred and the original pixel
                    local d = math.abs(imgd2.data[idx].r - imgd.data[idx].r) + math.abs(imgd2.data[idx].g - imgd.data[idx].g) + math.abs(imgd2.data[idx].b - imgd.data[idx].b) + math.abs(imgd2.data[idx].a - imgd.data[idx].a)
                    -- selective blur: if d > delta, put the original pixel back
                    if d > delta then
                        imgd2.data[idx].r = imgd.data[idx].r
                        imgd2.data[idx].g = imgd.data[idx].g
                        imgd2.data[idx].b = imgd.data[idx].b
                        imgd2.data[idx].a = imgd.data[idx].a
                    end
                end
            end
            return imgd2
        end
        function obj:colorquantization(imgd, options)
            local arr, idx, paletteacc, pixelnum, palette = {}, 0, {}, imgd.width * imgd.height, nil
            -- Filling arr (color index array) with -1
            for j = 0, imgd.height + 1 do
                arr[j] = {}
                for i = 0, imgd.width + 1 do
                    arr[j][i] = -1
                end
            end
            -- Use custom palette if pal is defined or sample / generate custom length palett
            if options.pal then
                palette = options.pal
            elseif options.colorsampling == 0 then
                palette = self:generatepalette(options.numberofcolors)
            elseif options.colorsampling == 1 then
                palette = self:samplepalette(options.numberofcolors, imgd)
            else
                palette = self:samplepalette2(options.numberofcolors, imgd)
            end
            -- Selective Gaussian blur preprocessin
            if options.blurradius > 0 then
                imgd = self:blur(imgd, options.blurradius, options.blurdelta)
            end
            -- Repeat clustering step options.colorquantcycles times
            for cnt = 0, options.colorquantcycles - 1 do
                -- Average colors from the second iteration
                if cnt > 0 then
                    -- averaging paletteacc for palette
                    for k = 1, #palette do
                        -- averaging
                        if paletteacc[k].n > 0 then
                            palette[k] = {
                                r = math.floor(paletteacc[k].r / paletteacc[k].n),
                                g = math.floor(paletteacc[k].g / paletteacc[k].n),
                                b = math.floor(paletteacc[k].b / paletteacc[k].n),
                                a = math.floor(paletteacc[k].a / paletteacc[k].n)
                            }
                        end
                        -- Randomizing a color, if there are too few pixels and there will be a new cycle
                        if paletteacc[k].n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1 then
                            palette[k] = {
                                r = math.floor(math.random() * 255),
                                g = math.floor(math.random() * 255),
                                b = math.floor(math.random() * 255),
                                a = math.floor(math.random() * 255)
                            }
                        end
                    end
                end
                -- Reseting palette accumulator for averaging
                for i = 1, #palette do
                    paletteacc[i] = {r = 0, g = 0, b = 0, a = 0, n = 0}
                end
                -- loop through all pixels
                for j = 0, imgd.height - 1 do
                    for i = 0, imgd.width - 1 do
                        idx = j * imgd.width + i -- pixel index
                        -- find closest color from palette by measuring (rectilinear) color distance between this pixel and all palette colors
                        local ci, cdl = 0, 1024 -- 4 * 256 is the maximum RGBA distance
                        for k = 1, #palette do
                            -- In my experience, https://en.wikipedia.org/wiki/Rectilinear_distance works
                            -- better than https://en.wikipedia.org/wiki/Euclidean_distance
                            local pr = palette[k].r > imgd.data[idx].r and palette[k].r - imgd.data[idx].r or imgd.data[idx].r - palette[k].r
                            local pg = palette[k].g > imgd.data[idx].g and palette[k].g - imgd.data[idx].g or imgd.data[idx].g - palette[k].g
                            local pb = palette[k].b > imgd.data[idx].b and palette[k].b - imgd.data[idx].b or imgd.data[idx].b - palette[k].b
                            local pa = palette[k].a > imgd.data[idx].a and palette[k].a - imgd.data[idx].a or imgd.data[idx].a - palette[k].a
                            local cd = pr + pg + pb + pa
                            -- Remember this color if this is the closest yet
                            if cd < cdl then
                                cdl, ci = cd, k
                            end
                        end
                        -- add to palettacc
                        paletteacc[ci].r = paletteacc[ci].r + imgd.data[idx].r
                        paletteacc[ci].g = paletteacc[ci].g + imgd.data[idx].g
                        paletteacc[ci].b = paletteacc[ci].b + imgd.data[idx].b
                        paletteacc[ci].a = paletteacc[ci].a + imgd.data[idx].a
                        paletteacc[ci].n = paletteacc[ci].n + 1
                        arr[j + 1][i + 1] = ci - 1
                    end
                end
            end
            return {array = arr, palette = palette}
        end
        -- Sampling a palette from imagedata
        function obj:samplepalette(numberofcolors, imgd)
            local idx, palette = nil, {}
            for i = 0, numberofcolors - 1 do
                idx = math.floor(math.random() * (imgd.width * imgd.height) / 4) * 4
                table.insert(palette, {
                    r = imgd.data[idx].r,
                    g = imgd.data[idx].g,
                    b = imgd.data[idx].b,
                    a = imgd.data[idx].a
                })
            end
            return palette
        end
        -- Deterministic sampling a palette from imagedata: rectangular grid
        function obj:samplepalette2(numberofcolors, imgd)
            local palette = {}
            local ni = math.ceil(math.sqrt(numberofcolors))
            local nj = math.ceil(numberofcolors / ni)
            local vx = imgd.width / (ni + 1)
            local vy = imgd.height / (nj + 1)
            for j = 0, nj - 1 do
                for i = 0, ni - 1 do
                    if #palette == numberofcolors then
                        break
                    else
                        local idx = math.floor(((j + 1) * vy) * imgd.width + ((i + 1) * vx))
                        table.insert(palette, {
                            r = imgd.data[idx].r,
                            g = imgd.data[idx].g,
                            b = imgd.data[idx].b,
                            a = imgd.data[idx].a
                        })
                    end
                end
            end
            return palette
        end
        -- Generating a palette with numberofcolors
        function obj:generatepalette(numberofcolors)
            local palette = {}
            if numberofcolors < 8 then
                -- Grayscale
                local graystep = math.floor(255 / (numberofcolors - 1))
                for i = 0, numberofcolors - 1 do
                    table.insert(palette, {
                        r = i * graystep,
                        g = i * graystep,
                        b = i * graystep,
                        a = 255
                    })
                end
            else
                -- RGB color cube
                local colorqnum = math.floor(numberofcolors ^ (1 / 3)) -- Number of points on each edge on the RGB color cube
                local colorstep = math.floor(255 / (colorqnum - 1)) -- distance between points
                local rndnum = numberofcolors - ((colorqnum * colorqnum) * colorqnum) -- number of random colors
                for rcnt = 0, colorqnum - 1 do
                    for gcnt = 0, colorqnum - 1 do
                        for bcnt = 0, colorqnum - 1 do
                            table.insert(palette, {
                                r = rcnt * colorstep,
                                g = gcnt * colorstep,
                                b = bcnt * colorstep,
                                a = 255
                            })
                        end
                    end
                end
                -- Rest is random
                for rcnt = 0, rndnum - 1 do
                    table.insert(palette, {
                        r = math.floor(math.random() * 255),
                        g = math.floor(math.random() * 255),
                        b = math.floor(math.random() * 255),
                        a = math.floor(math.random() * 255)
                    })
                end
            end
            return palette
        end
        -- 2. Layer separation and edge detection
        -- Edge node types ( ▓: this layer or 1; ░: not this layer or 0 )
        -- 12  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓
        -- 48  ░░  ░░  ░░  ░░  ░▓  ░▓  ░▓  ░▓  ▓░  ▓░  ▓░  ▓░  ▓▓  ▓▓  ▓▓  ▓▓
        --     0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
        function obj:layeringstep(ii, cnum)
            -- Creating layers for each indexed color in arr
            local layer, ah, aw = {}, #ii.array + 1, #ii.array[0] + 1
            for j = 0, ah - 1 do
                layer[j] = {}
                for i = 0, aw - 1 do
                    layer[j][i] = 0
                end
            end
            -- Looping through all pixels and calculating edge node type
            for j = 1, ah - 1 do
                for i = 1, aw - 1 do
                    local l1 = ii.array[j - 1][i - 1] == cnum and 1 or 0
                    local l2 = ii.array[j - 1][i - 0] == cnum and 2 or 0
                    local l3 = ii.array[j - 0][i - 1] == cnum and 8 or 0
                    local l4 = ii.array[j - 0][i - 0] == cnum and 4 or 0
                    layer[j][i] = l1 + l2 + l3 + l4
                end
            end
            return layer
        end
        -- Point in polygon test
        function obj:pointinpoly(p, pa)
            local isin = false
            local j = #pa
            for i = 1, #pa do
                isin = (pa[i].y > p.y) ~= (pa[j].y > p.y) and p.x < (pa[j].x - pa[i].x) * (p.y - pa[i].y) / (pa[j].y - pa[i].y) + pa[i].x and not isin or isin
                j = i
            end
            return isin
        end
        -- 3. Walking through an edge node array, discarding edge node types 0 and 15 and creating paths from the rest.
        -- Walk directions (dir): 0 > ; 1 ^ ; 2 < ; 3 v
        function obj:pathscan(arr, pathomit)
            local paths, pacnt, pcnt, px, py, w, h, dir, pathfinished, holepath, lookuprow = {}, 1, 1, 0, 0, #arr[0] + 1, #arr + 1, 0, true, false, nil
            for j = 0, h - 1 do
                for i = 0, w - 1 do
                    if arr[j][i] == 4 or arr[j][i] == 11 then --  Other values are not valid
                        px, py = i, j
                        paths[pacnt] = {}
                        paths[pacnt].points = {}
                        paths[pacnt].boundingbox = {px, py, px, py}
                        paths[pacnt].holechildren = {}
                        pathfinished = false
                        holepath = arr[j][i] == 11
                        pcnt, dir = 1, 1
                        -- Path points loop
                        while not pathfinished do
                            -- New path point
                            paths[pacnt].points[pcnt] = {}
                            paths[pacnt].points[pcnt].x = px - 1
                            paths[pacnt].points[pcnt].y = py - 1
                            paths[pacnt].points[pcnt].t = arr[py][px]
                            -- Bounding box
                            if px - 1 < paths[pacnt].boundingbox[1] then
                                paths[pacnt].boundingbox[1] = px - 1
                            end
                            if px - 1 > paths[pacnt].boundingbox[3] then
                                paths[pacnt].boundingbox[3] = px - 1
                            end
                            if py - 1 < paths[pacnt].boundingbox[2] then
                                paths[pacnt].boundingbox[2] = py - 1
                            end
                            if py - 1 > paths[pacnt].boundingbox[4] then
                                paths[pacnt].boundingbox[4] = py - 1
                            end
                            -- Next: look up the replacement, direction and coordinate changes = clear this cell, turn if required, walk forward
                            lookuprow = self.pathscan_combined_lookup[arr[py][px] + 1][dir + 1]
                            arr[py][px] = lookuprow[1]
                            dir = lookuprow[2]
                            px = px + lookuprow[3]
                            py = py + lookuprow[4]
                            -- Close path
                            if px - 1 == paths[pacnt].points[1].x and py - 1 == paths[pacnt].points[1].y then
                                pathfinished = true
                                -- Discarding paths shorter than pathomit
                                if #paths[pacnt].points < pathomit then
                                    table.remove(paths)
                                else
                                    paths[pacnt].isholepath = holepath and true or false
                                    if holepath then
                                        local parentidx, parentbbox = 1, {-1, -1, w + 1, h + 1}
                                        for parentcnt = 1, pacnt do
                                            if not paths[parentcnt].isholepath and
                                                self:boundingboxincludes(paths[parentcnt].boundingbox, paths[pacnt].boundingbox) and
                                                self:boundingboxincludes(parentbbox, paths[parentcnt].boundingbox) and
                                                self:pointinpoly(paths[pacnt].points[1], paths[parentcnt].points) then
                                                parentidx = parentcnt
                                                parentbbox = paths[parentcnt].boundingbox
                                            end
                                        end
                                        table.insert(paths[parentidx].holechildren, pacnt)
                                    end
                                    pacnt = pacnt + 1
                                end
                            end
                            pcnt = pcnt + 1
                        end
                    end
                end
            end
            return paths
        end
        function obj:boundingboxincludes(parentbbox, childbbox)
            return (parentbbox[1] < childbbox[1]) and (parentbbox[2] < childbbox[2]) and (parentbbox[3] > childbbox[3]) and (parentbbox[4] > childbbox[4])
        end
        -- 4. interpollating between path points for nodes with 8 directions ( East, SouthEast, S, SW, W, NW, N, NE )
        function obj:internodes(paths, options)
            local ins, palen, nextidx, nextidx2, previdx, previdx2 = {}, 1, 1, 1, 1, 1
            -- paths loop
            for pacnt = 1, #paths do
                ins[pacnt] = {}
                ins[pacnt].points = {}
                ins[pacnt].boundingbox = paths[pacnt].boundingbox
                ins[pacnt].holechildren = paths[pacnt].holechildren
                ins[pacnt].isholepath = paths[pacnt].isholepath
                palen = #paths[pacnt].points
                -- pathpoints loop
                for pcnt = 1, palen do
                    -- next and previous point indexes
                    nextidx = pcnt % palen + 1
                    nextidx2 = (pcnt + 1) % palen + 1
                    previdx = (pcnt - 2 + palen) % palen + 1
                    previdx2 = (pcnt - 3 + palen) % palen + 1
                    -- right angle enhance
                    if options.rightangleenhance and self:testrightangle(paths[pacnt], previdx2, previdx, pcnt, nextidx, nextidx2) then
                        -- Fix previous direction
                        if #ins[pacnt].points > 1 then
                            ins[pacnt].points[#ins[pacnt].points].linesegment = self:getdirection(ins[pacnt].points[#ins[pacnt].points].x, ins[pacnt].points[#ins[pacnt].points].y, paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y)
                        end
                        -- This corner point
                        table.insert(ins[pacnt].points, {
                            x = paths[pacnt].points[pcnt].x,
                            y = paths[pacnt].points[pcnt].y,
                            linesegment = self:getdirection(paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y, (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2)
                        })
                    end
                    -- interpolate between two path points
                    table.insert(ins[pacnt].points, {
                        x = (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2,
                        y = (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2,
                        linesegment = self:getdirection((paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2, (paths[pacnt].points[nextidx].x + paths[pacnt].points[nextidx2].x) / 2, (paths[pacnt].points[nextidx].y + paths[pacnt].points[nextidx2].y) / 2)
                    })
                end
            end
            return ins
        end
        function obj:testrightangle(path, idx1, idx2, idx3, idx4, idx5)
            return (path.points[idx3].x == path.points[idx1].x and path.points[idx3].x == path.points[idx2].x and path.points[idx3].y == path.points[idx4].y and path.points[idx3].y == path.points[idx5].y) or (path.points[idx3].y == path.points[idx1].y and path.points[idx3].y == path.points[idx2].y and path.points[idx3].x == path.points[idx4].x and path.points[idx3].x == path.points[idx5].x)
        end
        function obj:getdirection(x1, y1, x2, y2)
            local val = 8
            if x1 < x2 then
                if y1 < y2 then -- SouthEast
                    val = 1
                elseif y1 > y2 then -- NE
                    val = 7
                else -- E
                    val = 0
                end
            elseif x1 > x2 then
                if y1 < y2 then -- SW
                    val = 3
                elseif y1 > y2 then -- NW
                    val = 5
                else -- W
                    val = 4
                end
            else
                if y1 < y2 then -- S
                    val = 2
                elseif y1 > y2 then -- N
                    val = 6
                else -- center, this should not happen
                    val = 8
                end
            end
            return val
        end
        -- 5. tracepath() : recursively trying to fit straight and quadratic spline segments on the 8 direction internode path
        -- 5.1. Find sequences of points with only 2 segment types
        -- 5.2. Fit a straight line on the sequence
        -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
        -- 5.4. Fit a quadratic spline through errorpoint (project this to get controlpoint), then measure errors on every point in the sequence
        -- 5.5. If the spline fails (distance error > qtres), find the point with the biggest error, set splitpoint = fitting point
        -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
        function obj:tracepath(path, ltres, qtres)
            local pcnt = 1
            local smp = {}
            smp.segments = {}
            smp.boundingbox = path.boundingbox
            smp.holechildren = path.holechildren
            smp.isholepath = path.isholepath
            while pcnt < #path.points do
                -- 5.1. Find sequences of points with only 2 segment types
                local segtype1 = path.points[pcnt].linesegment
                local segtype2 = -1
                local seqend = pcnt + 1
                while (path.points[seqend].linesegment == segtype1 or path.points[seqend].linesegment == segtype2 or segtype2 == -1) and seqend < #path.points do
                    if path.points[seqend].linesegment ~= segtype1 and segtype2 == -1 then
                        segtype2 = path.points[seqend].linesegment
                    end
                    seqend = seqend + 1
                end
                if seqend == #path.points then
                    seqend = 1
                end
                -- 5.2. - 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
                -- smp.segments = zf.table(smp.segments):concat(self:fitseq(path, ltres, qtres, pcnt, seqend))
                smp.segments = concat(smp.segments, self:fitseq(path, ltres, qtres, pcnt, seqend))
                -- forward pcnt
                if seqend > 1 then
                    pcnt = seqend
                else
                    pcnt = #path.points
                end
            end
            return smp
        end
        -- 5.2. - 5.6. recursively fitting a straight or quadratic line segment on this sequence of path nodes,
        -- called from tracepath()
        function obj:fitseq(path, ltres, qtres, seqstart, seqend)
            -- return if invalid seqend
            if seqend > #path.points or seqend < 1 then
                return {}
            end
            local errorpoint, errorval, curvepass = seqstart, 0, true
            local tl = seqend - seqstart
            if tl < 1 then
                tl = tl + #path.points
            end
            local vx = (path.points[seqend].x - path.points[seqstart].x) / tl
            local vy = (path.points[seqend].y - path.points[seqstart].y) / tl
            -- 5.2. Fit a straight line on the sequence
            local pcnt = seqstart % #path.points + 1
            while pcnt ~= seqend do
                local pl = pcnt - seqstart
                if pl < 1 then
                    pl = pl + #path.points
                end
                local px = path.points[seqstart].x + vx * pl
                local py = path.points[seqstart].y + vy * pl
                local dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
                if dist2 > ltres then
                    curvepass = false
                end
                if dist2 > errorval then
                    errorpoint = pcnt - 1
                    errorval = dist2
                end
                pcnt = pcnt % #path.points + 1
            end
            -- return straight line if fits
            if curvepass then
                return {
                    {
                        type = "l",
                        x1 = path.points[seqstart].x, y1 = path.points[seqstart].y,
                        x2 = path.points[seqend].x, y2 = path.points[seqend].y
                    }
                }
            end
            -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
            local fitpoint = errorpoint + 1
            curvepass, errorval = true, 0
            -- 5.4. Fit a quadratic spline through this point, measure errors on every point in the sequence
            -- helpers and projecting to get control point
            local t = (fitpoint - seqstart) / tl
            local t1 = (1 - t) * (1 - t)
            local t2 = 2 * (1 - t) * t
            local t3 = t * t
            local cpx = (t1 * path.points[seqstart].x + t3 * path.points[seqend].x - path.points[fitpoint].x) / -t2
            local cpy = (t1 * path.points[seqstart].y + t3 * path.points[seqend].y - path.points[fitpoint].y) / -t2
            -- Check every point
            pcnt = seqstart + 1
            while pcnt ~= seqend do
                t = (pcnt - seqstart) / tl
                t1 = (1 - t) * (1 - t)
                t2 = 2 * (1 - t) * t
                t3 = t * t
                local px = t1 * path.points[seqstart].x + t2 * cpx + t3 * path.points[seqend].x
                local py = t1 * path.points[seqstart].y + t2 * cpy + t3 * path.points[seqend].y
                local dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
                if dist2 > qtres then
                    curvepass = false
                end
                if dist2 > errorval then
                    errorpoint = pcnt - 1
                    errorval = dist2
                end
                pcnt = pcnt % #path.points + 1
            end
            -- return spline if fits
            if curvepass then
                local x1, y1 = path.points[seqstart].x, path.points[seqstart].y
                local x2, y2 = cpx, cpy
                local x3, y3 = path.points[seqend].x, path.points[seqend].y
                return {
                    {
                        type = "b",
                        x1 = x1, y1 = y1,
                        x2 = (x1 + 2 * x2) / 3, y2 = (y1 + 2 * y2) / 3,
                        x3 = (x3 + 2 * x2) / 3, y3 = (y3 + 2 * y2) / 3,
                        x4 = x3, y4 = y3
                    }
                }
            end
            -- 5.5. If the spline fails (distance error>qtres), find the point with the biggest error
            local splitpoint = fitpoint -- Earlier: math.floor((fitpoint + errorpoint) / 2)
            -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
            return concat(self:fitseq(path, ltres, qtres, seqstart, splitpoint), self:fitseq(path, ltres, qtres, splitpoint, seqend))
        end
        -- 5. Batch tracing paths
        function obj:batchtracepaths(internodepaths, ltres, qtres)
            local btracedpaths = {}
            for k in pairs(internodepaths) do
                if not rawget(internodepaths, k) then
                    goto continue
                end
                table.insert(btracedpaths, self:tracepath(internodepaths[k], ltres, qtres))
                ::continue::
            end
            return btracedpaths
        end
        -- Getting shape
        function obj:shape_path(tracedata, lnum, pathnum, options)
            local layer = tracedata.layers[lnum]
            local smp = layer[pathnum]
            local function build_style(c)
                local color = ("\\c&H%02X%02X%02X&"):format(c.b, c.g, c.r)
                local alpha = ("\\alpha&H%02X&"):format(255 - c.a)
                return color, alpha
            end
            local color, alpha = build_style(tracedata.palette[lnum])
            -- Creating non-hole path string
            local shape = ("m %s %s "):format(
                round(smp.segments[1].x1 * options.scale, options.roundcoords),
                round(smp.segments[1].y1 * options.scale, options.roundcoords)
            )
            for pcnt = 1, #smp.segments do
                shape = shape .. ("%s %s %s "):format(
                    smp.segments[pcnt].type,
                    round(smp.segments[pcnt].x2 * options.scale, options.roundcoords),
                    round(smp.segments[pcnt].y2 * options.scale, options.roundcoords)
                )
                if rawget(smp.segments[pcnt], "x4") then
                    shape = shape .. ("%s %s %s %s "):format(
                        round(smp.segments[pcnt].x3 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].y3 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].x4 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].y4 * options.scale, options.roundcoords)
                    )
                end
            end
            -- Hole children
            for hcnt = 1, #smp.holechildren do
                local hsmp = layer[smp.holechildren[hcnt]]
                -- Creating hole path string
                if rawget(hsmp.segments[#hsmp.segments], "x4") then
                    shape = shape .. ("m %s %s "):format(
                        round(hsmp.segments[#hsmp.segments].x4 * options.scale),
                        round(hsmp.segments[#hsmp.segments].y4 * options.scale)
                    )
                else
                    shape = shape .. ("m %s %s "):format(
                        hsmp.segments[#hsmp.segments].x2 * options.scale,
                        hsmp.segments[#hsmp.segments].y2 * options.scale
                    )
                end
                for pcnt = #hsmp.segments, 1, -1 do
                    shape = shape .. hsmp.segments[pcnt].type .. " "
                    if rawget(hsmp.segments[pcnt], "x4") then
                        shape = shape .. ("%s %s %s %s "):format(
                            round(hsmp.segments[pcnt].x2 * options.scale),
                            round(hsmp.segments[pcnt].y2 * options.scale),
                            round(hsmp.segments[pcnt].x3 * options.scale),
                            round(hsmp.segments[pcnt].y3 * options.scale)
                        )
                    end
                    shape = shape .. ("%s %s "):format(
                        round(hsmp.segments[pcnt].x1 * options.scale),
                        round(hsmp.segments[pcnt].y1 * options.scale)
                    )
                end
            end
            return shape, color, alpha
        end
        -- 5. Batch tracing layers
        function obj:get_shape(tracedata, options)
            options = self:checkoptions(options)
            local shaper = {}
            for lcnt = 1, #tracedata.layers do
                for pcnt = 1, #tracedata.layers[lcnt] do
                    if not tracedata.layers[lcnt][pcnt].isholepath then
                        local shape, color, alpha = self:shape_path(tracedata, lcnt, pcnt, options)
                        if alpha ~= "\\alpha&HFF&" then -- ignores invisible values
                            shaper[#shaper + 1] = {shape = shape, color = color, alpha = alpha}
                        end
                    end
                end
            end
            local group, build = {}, {}
            for i = 1, #shaper do
                local v = shaper[i]
                for k = 1, #group do
                    for j = 1, #group[k] do
                        if v.color == group[k][j].color and v.alpha == group[k][j].alpha then
                            group[k][#group[k] + 1] = v
                            goto join
                        end
                    end
                end
                group[#group + 1] = {v}
                ::join::
            end
            for i = 1, #group do
                local shape = ""
                for j = 1, #group[i] do
                    shape = shape .. group[i][j].shape
                end
                local wt = self.optionpresets.default.deletewhite
                local bk = self.optionpresets.default.deleteblack
                if (wt and group[i][1].color == "\\c&HFFFFFF&") then -- skip white
                    goto continue
                end
                if (bk and group[i][1].color == "\\c&H000000&") then -- skip black
                    goto continue
                end
                local color = group[i][1].color .. (options.strokewidth > 0 and group[i][1].color:gsub("\\c", "\\3c") or "")
                build[#build + 1] = ("{\\an7\\pos(0,0)\\fscx100\\fscy100%s\\bord%s\\shad0\\p1}%s"):format(
                    color .. group[i][1].alpha, options.strokewidth, shape
                )
                ::continue::
            end
            return build
        end
        return obj
    end
    return {bmp = bmp, gif = gif, jpg = jpg, png = png, tracer = tracer}
end

return {
    PATH = PATH.new,
    PATHS = PATHS.new,
    CLIPPER = CLIPPER.new,
    OFFSET = OFFSET.new,
    IMG = IMG
}