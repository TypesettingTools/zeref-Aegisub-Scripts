-- load internal libs
ffi = require "ffi"
bit = require "bit"

-- load external libs
requireffi = require "requireffi.requireffi"

local CPP, PNG, JPG, GIF
switch ffi.os
    when "Windows"
        switch ffi.arch
            when "x64"
                CPP = requireffi "ZF.bin.win.clipper64"
                PNG = requireffi "ZF.bin.win.png64"
                JPG = requireffi "ZF.bin.win.jpg64"
                GIF = requireffi "ZF.bin.win.gif64"
            when "x86"
                CPP = requireffi "ZF.bin.win.clipper86"
                PNG = requireffi "ZF.bin.win.png86"
                JPG = requireffi "ZF.bin.win.jpg86"
                GIF = requireffi "ZF.bin.win.gif86"
    when "Linux"
        if ffi.arch == "x64"
            CPP = requireffi "ZF.bin.linux.libclipper64"
            PNG = requireffi "ZF.bin.linux.libpng64"
            JPG = requireffi "ZF.bin.linux.libjpg64"
            GIF = requireffi "ZF.bin.linux.libgif64"
    else
        error "Not compatible with your operating system!"

-- Clipper defs
ffi.cdef [[
    typedef struct __zf_int_point { int64_t x, y; } zf_int_point;
    typedef struct __zf_int_rect { int64_t left; int64_t top; int64_t right; int64_t bottom; } zf_int_rect;
    typedef signed long long cInt;
    typedef struct __zf_path zf_path;
    typedef struct __zf_paths zf_paths;
    typedef struct __zf_offset zf_offset;
    typedef struct __zf_clipper zf_clipper;

    const char* zf_err_msg();
    zf_path* zf_path_new();
    void zf_path_free(zf_path *self);
    zf_int_point* zf_path_get(zf_path *self, int i);
    bool zf_path_add(zf_path *self, cInt x, cInt y);
    int zf_path_size(zf_path *self);

    zf_paths* zf_paths_new();
    void zf_paths_free(zf_paths *self);
    zf_path* zf_paths_get(zf_paths *self, int i);
    bool zf_paths_add(zf_paths *self, zf_path *path);
    int zf_paths_size(zf_paths *self);

    zf_offset* zf_offset_new(double miterLimit, double roundPrecision);
    void zf_offset_free(zf_offset *self);
    zf_paths* zf_offset_path(zf_offset *self, zf_path *subj, double delta, int jointType, int endType);
    zf_paths* zf_offset_paths(zf_offset *self, zf_paths *subj, double delta, int jointType, int endType);

    zf_clipper* zf_clipper_new();
    void zf_clipper_free(zf_clipper *CLP);
    bool zf_clipper_add_path(zf_clipper *CLP, zf_path *path, int pt, bool closed,const char *err);
    bool zf_clipper_add_paths(zf_clipper *CLP, zf_paths *paths, int pt, bool closed, const char *err);
    zf_paths* zf_clipper_execute(zf_clipper *CLP, int clipType, int subjFillType, int clipFillType);
]]

-- Blitbuffer defs
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

-- Gif defs
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

-- ======== CLIPPER LIB ======== --

-- enums
clip_type = {intersection: 0, union: 1, difference: 2, xor: 3}
join_type = {square: 0, round: 1, miter: 2}
end_type  = {closed_polygon: 0, closed_line: 1, open_butt: 2, open_square: 3, open_round: 4}
poly_type = {subject: 0, clip: 1}
fill_type = {none: 0, even_odd: 1, non_zero: 2, positive: 3, negative: 4}

-- metatables
PATH, PATHS, OFFSET, CLIPPER = {}, {}, {}, {}

-- path objects
PATH.new = -> ffi.gc(CPP.zf_path_new!, CPP.zf_path_free)
PATH.add = (self, x, y) -> CPP.zf_path_add(self, x, y)
PATH.get = (self, i) -> CPP.zf_path_get(self, i - 1)
PATH.size = (self) -> CPP.zf_path_size(self)

-- paths objects
PATHS.new = -> ffi.gc(CPP.zf_paths_new!, CPP.zf_paths_free)
PATHS.add = (self, path) -> CPP.zf_paths_add(self, path)
PATHS.get = (self, i) -> CPP.zf_paths_get(self, i - 1)
PATHS.size = (self) -> CPP.zf_paths_size(self)

-- offset objects
OFFSET.new = (ml = 2, at = 0.25) ->
    co = CPP.zf_offset_new(ml, at)
    ffi.gc(co, CPP.zf_offset_free)

OFFSET.add_path = (self, path, delta, jt = "square", et = "open_butt") ->
    out = CPP.zf_offset_path(self, path, delta, join_type[jt], end_type[et])
    if out == nil
        error ffi.string(CPP.zf_err_msg!)
    return out

OFFSET.add_paths = (self, paths, delta, jt = "square", et = "open_butt") ->
    out = CPP.zf_offset_paths(self, paths, delta, join_type[jt], end_type[et])
    if out == nil
        error ffi.string(CPP.zf_err_msg!)
    return out

-- clipper objects
CLIPPER.new = (...) -> ffi.gc(CPP.zf_clipper_new!, CPP.zf_clipper_free)

CLIPPER.add_path = (self, path, pt, closed = true) -> CPP.zf_clipper_add_path(self, path, poly_type[pt], closed, err)

CLIPPER.add_paths = (self, paths, pt, closed = true) ->
    error ffi.string(CPP.zf_err_msg!) unless CPP.zf_clipper_add_paths(self, paths, poly_type[pt], closed, err)

CLIPPER.execute = (self, ct, sft = "even_odd", cft = "even_odd") ->
    out = CPP.zf_clipper_execute(self, clip_type[ct], fill_type[sft], fill_type[cft])
    if out == nil
        error ffi.string(CPP.zf_err_msg!)
    return out

ffi.metatype "zf_path",    {__index: PATH}
ffi.metatype "zf_paths",   {__index: PATHS}
ffi.metatype "zf_offset",  {__index: OFFSET}
ffi.metatype "zf_clipper", {__index: CLIPPER}

-- ======== BLITBUFFER ======== --

-- get types
Color8     = ffi.typeof("Color8")
Color8A    = ffi.typeof("Color8A")
ColorRGB16 = ffi.typeof("ColorRGB16")
ColorRGB24 = ffi.typeof("ColorRGB24")
ColorRGB32 = ffi.typeof("ColorRGB32")
intt       = ffi.typeof("int")
uint8pt    = ffi.typeof("uint8_t*")

Color8_mt     = {__index: {}}
Color8A_mt    = {__index: {}}
ColorRGB16_mt = {__index: {}}
ColorRGB24_mt = {__index: {}}
ColorRGB32_mt = {__index: {}}

Color8_mt.__index.getColor8 = (self) -> self
Color8A_mt.__index.getColor8 = (self) -> Color8(self.a)

ColorRGB16_mt.__index.getColor8 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return Color8(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14))

ColorRGB24_mt.__index.getColor8 = (self) -> Color8(bit.rshift(4897 * self\getR! + 9617 * self\getG! + 1868 * self\getB!, 14))
ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

Color8_mt.__index.getColor8A = (self) -> Color8A(self.a, 0)
Color8A_mt.__index.getColor8A = (self) -> self

ColorRGB16_mt.__index.getColor8A = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return Color8A(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0)

ColorRGB24_mt.__index.getColor8A = (self) -> Color8A(bit.rshift(4897 * self\getR! + 9617 * self\getG! + 1868 * self\getB!, 14), 0)
ColorRGB32_mt.__index.getColor8A = (self) -> Color8A(bit.rshift(4897 * self\getR! + 9617 * self\getG! + 1868 * self\getB!, 14), self\getAlpha!)

Color8_mt.__index.getColorRGB16 = (self) ->
    v = self\getColor8!.a
    v5bit = bit.rshift(v, 3)
    return ColorRGB16(bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit)

Color8A_mt.__index.getColorRGB16 = Color8_mt.__index.getColorRGB16

ColorRGB16_mt.__index.getColorRGB16 = (self) -> self
ColorRGB24_mt.__index.getColorRGB16 = (self) -> ColorRGB16(bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3))
ColorRGB32_mt.__index.getColorRGB16 = ColorRGB24_mt.__index.getColorRGB16

Color8_mt.__index.getColorRGB24 = (self) ->
    v = self\getColor8!
    return ColorRGB24(v.a, v.a, v.a)

Color8A_mt.__index.getColorRGB24 = Color8_mt.__index.getColorRGB24

ColorRGB16_mt.__index.getColorRGB24 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return ColorRGB24(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2))

ColorRGB24_mt.__index.getColorRGB24 = (self) -> self
ColorRGB32_mt.__index.getColorRGB24 = (self) -> ColorRGB24(self.r, self.g, self.b)

Color8_mt.__index.getColorRGB32 = (self) -> ColorRGB32(self.a, self.a, self.a, 0xFF)
Color8A_mt.__index.getColorRGB32 = (self) -> ColorRGB32(self.a, self.a, self.a, self.alpha)

ColorRGB16_mt.__index.getColorRGB32 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return ColorRGB32(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF)

ColorRGB24_mt.__index.getColorRGB32 = (self) -> ColorRGB32(self.r, self.g, self.b, 0xFF)
ColorRGB32_mt.__index.getColorRGB32 = (self) -> self
Color8_mt.__index.getR = (self) -> self\getColor8!.a

Color8_mt.__index.getG = Color8_mt.__index.getR
Color8_mt.__index.getB = Color8_mt.__index.getR

Color8_mt.__index.getAlpha = (self) -> intt(0xFF)

Color8A_mt.__index.getR = Color8_mt.__index.getR
Color8A_mt.__index.getG = Color8_mt.__index.getR
Color8A_mt.__index.getB = Color8_mt.__index.getR

Color8A_mt.__index.getAlpha = (self) -> self.alpha

ColorRGB16_mt.__index.getR = (self) ->
    r = bit.rshift(self.v, 11)
    return bit.lshift(r, 3) + bit.rshift(r, 2)

ColorRGB16_mt.__index.getG = (self) ->
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    return bit.lshift(g, 2) + bit.rshift(g, 4)

ColorRGB16_mt.__index.getB = (self) ->
    b = bit.rshift(self.v, 0x001F)
    return bit.lshift(b, 3) + bit.rshift(b, 2)

ColorRGB16_mt.__index.getAlpha = Color8_mt.__index.getAlpha

ColorRGB24_mt.__index.getR = (self) -> self.r
ColorRGB24_mt.__index.getG = (self) -> self.g
ColorRGB24_mt.__index.getB = (self) -> self.b

ColorRGB24_mt.__index.getAlpha = Color8_mt.__index.getAlpha
ColorRGB32_mt.__index.getR     = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG     = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB     = ColorRGB24_mt.__index.getB

ColorRGB32_mt.__index.getAlpha = (self) -> self.alpha

BB8_mt     = {__index: {}}
BB8A_mt    = {__index: {}}
BBRGB16_mt = {__index: {}}
BBRGB24_mt = {__index: {}}
BBRGB32_mt = {__index: {}}
BB_mt      = {__index: {}}

BB_mt.__index.getRotation = (self) -> bit.rshift(bit.band(0x0C, self.config), 2)
BB_mt.__index.getInverse = (self) -> bit.rshift(bit.band(0x02, self.config), 1)

BB_mt.__index.setAllocated = (self, allocated) ->
    self.config = bit.bor(bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0))

BB8_mt.__index.getBpp     = (self) -> 8
BB8A_mt.__index.getBpp    = (self) -> 8
BBRGB16_mt.__index.getBpp = (self) -> 16
BBRGB24_mt.__index.getBpp = (self) -> 24
BBRGB32_mt.__index.getBpp = (self) -> 32

BB_mt.__index.setType = (self, type_id) ->
    self.config = bit.bor(bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4))

BB_mt.__index.getPhysicalCoordinates = (self, x, y) ->
    return switch self\getRotation!
        when 0 then x, y
        when 1 then self.w - y - 1, x
        when 2 then self.w - x - 1, self.h - y - 1
        when 3 then y, self.h - x - 1

BB_mt.__index.getPixelP = (self, x, y) -> ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x

BB_mt.__index.getPixel = (self, x, y) ->
    px, py = self\getPhysicalCoordinates(x, y)
    color = self\getPixelP(px, py)[0]
    color = color\invert! if self\getInverse! == 1
    return color

BB_mt.__index.getWidth = (self) ->
    if 0 == bit.band(1, self\getRotation!)
        return self.w
    else
        return self.h

BB_mt.__index.getHeight = (self) ->
    if 0 == bit.band(1, self\getRotation!)
        return self.h
    else
        return self.w

for n, f in pairs BB_mt.__index
    BB8_mt.__index[n]     = f unless BB8_mt.__index[n]
    BB8A_mt.__index[n]    = f unless BB8A_mt.__index[n]
    BBRGB16_mt.__index[n] = f unless BBRGB16_mt.__index[n]
    BBRGB24_mt.__index[n] = f unless BBRGB24_mt.__index[n]
    BBRGB32_mt.__index[n] = f unless BBRGB32_mt.__index[n]

BlitBuffer8     = ffi.metatype "BlitBuffer8", BB8_mt
BlitBuffer8A    = ffi.metatype "BlitBuffer8A", BB8A_mt
BlitBufferRGB16 = ffi.metatype "BlitBufferRGB16", BBRGB16_mt
BlitBufferRGB24 = ffi.metatype "BlitBufferRGB24", BBRGB24_mt
BlitBufferRGB32 = ffi.metatype "BlitBufferRGB32", BBRGB32_mt

ffi.metatype "Color8",     Color8_mt
ffi.metatype "Color8A",    Color8A_mt
ffi.metatype "ColorRGB16", ColorRGB16_mt
ffi.metatype "ColorRGB24", ColorRGB24_mt
ffi.metatype "ColorRGB32", ColorRGB32_mt

BUFFER = (width, height, buffertype = 1, dataptr, pitch) ->
    if pitch == nil
        pitch = switch buffertype
            when 1 then width
            when 2 then bit.lshift(width, 1)
            when 3 then bit.lshift(width, 1)
            when 4 then width * 3
            when 5 then bit.lshift(width, 2)
    local bb
    bb = switch buffertype
        when 1 then BlitBuffer8(width, height, pitch, nil, 0)
        when 2 then BlitBuffer8A(width, height, pitch, nil, 0)
        when 3 then BlitBufferRGB16(width, height, pitch, nil, 0)
        when 4 then BlitBufferRGB24(width, height, pitch, nil, 0)
        when 5 then BlitBufferRGB32(width, height, pitch, nil, 0)
        else error "unknown blitbuffer type"
    bb\setType(buffertype)
    if dataptr == nil
        dataptr = ffi.C.malloc(pitch * height)
        assert dataptr, "cannot allocate memory for blitbuffer"
        ffi.fill(dataptr, pitch * height)
        bb\setAllocated(1)
    bb.data = ffi.cast(bb.data, dataptr)
    return bb

class IMG

    new: (filename) => @filename = filename

    bmp: =>
        read_word = (data, offset) -> data\byte(offset + 1) * 256 + data\byte(offset)
        read_dword = (data, offset) -> read_word(data, offset + 2) * 65536 + read_word(data, offset)
        -- local file
        file = assert io.open(@filename, "rb"), "Can't open file!"
        data = file\read("*a")
        file\close!
        --
        if not read_dword(data, 1) == 0x4D42 -- Bitmap "magic" header
            return nil, "Bitmap magic not found"
        elseif read_word(data, 29) != 24 -- Bits per pixel
            return nil, "Only 24bpp bitmaps supported"
        elseif read_dword(data, 31) != 0 -- Compression
            return nil, "Only uncompressed bitmaps supported"
        -- create object
        obj = {
            data:         data
            bit_depth:    24
            pixel_offset: read_word(data, 11)
            width:        read_dword(data, 19)
            height:       read_dword(data, 23)
        }
        -- get pixel
        obj.get_pixel = (x, y) ->
            if (x < 0) or (x > obj.width) or (y < 0) or (y > obj.height)
                return nil, "Out of bounds"
            index = obj.pixel_offset + (obj.height - y - 1) * 3 * obj.width + x * 3
            b = data\byte(index + 1)
            g = data\byte(index + 2)
            r = data\byte(index + 3)
            return r, g, b
        -- map image
        obj.data = ffi.new "ColorRGBA[?]", obj.width * obj.height
        for y = 0, obj.height - 1
            for x = 0, obj.width - 1
                i = y * obj.width + x
                r, g, b = obj.get_pixel(x, y)
                obj.data[i].r = r
                obj.data[i].g = g
                obj.data[i].b = b
                obj.data[i].a = 255
        return obj

    gif: (opaque) =>
        open = (arg) ->
            op = (filename, err) -> GIF.DGifOpenFileName(filename, err)
            er = ffi.new "int[1]"
            ft = op(arg, er) and op(arg, er) or nil
            return not ft and error(ffi.string(GIF.GifErrorString(er[0]))) or ft
        close = (ft) -> ffi.C.free(ft) if GIF.DGifCloseFile(ft) == 0
        checknz = (ft, res) ->
            return if res != 0
            return error(ffi.string(GIF.GifErrorString(ft.Error)))
        transparent = not opaque
        ft = open(@filename)
        checknz(ft, GIF.DGifSlurp(ft))
        obj = {
            frames: {}
            width:  ft.SWidth
            height: ft.SHeight
        }
        gcb = ffi.new "GraphicsControlBlock"
        for i = 0, ft.ImageCount - 1
            si = ft.SavedImages[i]
            local delay_ms, tcolor_idx
            if GIF.DGifSavedExtensionToGCB(ft, i, gcb) == 1
                delay_ms = gcb.DelayTime * 10
                tcolor_idx = gcb.TransparentColor
            w, h = si.ImageDesc.Width, si.ImageDesc.Height
            colormap = si.ImageDesc.ColorMap != nil and si.ImageDesc.ColorMap or ft.SColorMap
            size = w * h
            data = ffi.new "ColorRGBA[?]", size
            for k = 0, size - 1
                idx = si.RasterBits[k]
                assert(idx < colormap.ColorCount)
                if idx == tcolor_idx and transparent
                    data[k].b = 0
                    data[k].g = 0
                    data[k].r = 0
                    data[k].a = 0
                else
                    data[k].b = colormap.Colors[idx].Blue
                    data[k].g = colormap.Colors[idx].Green
                    data[k].r = colormap.Colors[idx].Red
                    data[k].a = 0xff
            img = {data: data, width: w, height: h, x: si.ImageDesc.Left, y: si.ImageDesc.Top, delay_ms: delay_ms}
            obj.frames[#obj.frames + 1] = img
        close(ft)
        return obj.frames

    jpg: (c_color) =>
        file = io.open @filename, "rb"
        assert file, "couldn't open JPG file"
        data = file\read "*a"
        file\close!
        handle = JPG.tjInitDecompress!
        assert handle, "no TurboJPEG API decompressor handle"
        width       = ffi.new "int[1]"
        height      = ffi.new "int[1]"
        jpegSubsamp = ffi.new "int[1]"
        colorspace  = ffi.new "int[1]"
        JPG.tjDecompressHeader3(handle, ffi.cast("const unsigned char*", data), #data, width, height, jpegSubsamp, colorspace)
        assert width[0] > 0 and height[0] > 0, "image dimensions"
        local buf, format
        unless c_color
            buf = BUFFER width[0], height[0], 4
            format = JPG.TJPF_RGB
        else
            buf = BUFFER width[0], height[0], 1
            format = JPG.TJPF_GRAY
        if JPG.tjDecompress2(handle, ffi.cast("unsigned char*", data), #data, ffi.cast("unsigned char*", buf.data), width[0], buf.pitch, height[0], format, 0) == -1
            error "decoding error"
        JPG.tjDestroy(handle)
        obj = {
            data:      buf,
            bit_depth: buf\getBpp!,
            width:     buf\getWidth!,
            height:    buf\getHeight!
        }
        obj.get_pixel = (x, y) -> buf\getPixel(x, y)
        obj.data = ffi.new "ColorRGBA[?]", obj.width * obj.height
        for y = 0, obj.height - 1
            for x = 0, obj.width - 1
                i = y * obj.width + x
                color = obj.get_pixel(x, y)\getColorRGB32!
                obj.data[i].r = color.r
                obj.data[i].g = color.g
                obj.data[i].b = color.b
                obj.data[i].a = color.alpha
        return obj

    png: =>
        w, h, ptr = ffi.new("int[1]"), ffi.new("int[1]"), ffi.new("unsigned char*[1]")
        err = PNG.lodepng_decode32_file ptr, w, h, @filename
        assert err == 0, ffi.string(PNG.lodepng_error_text(err))
        buf = BUFFER w[0], h[0], 5, ptr[0]
        buf\setAllocated(1)
        obj = {
            data:      buf,
            bit_depth: buf\getBpp!,
            width:     buf\getWidth!,
            height:    buf\getHeight!
        }
        obj.get_pixel = (x, y) -> buf\getPixel(x, y)
        obj.data = ffi.new "ColorRGBA[?]", obj.width * obj.height
        for y = 0, obj.height - 1
            for x = 0, obj.width - 1
                i = y * obj.width + x
                color = obj.get_pixel(x, y)\getColorRGB32!
                obj.data[i].r = color.r
                obj.data[i].g = color.g
                obj.data[i].b = color.b
                obj.data[i].a = color.alpha
        return obj

    tracer: (concat, round) =>
        obj = {versionnumber: "1.2.6"}
        ext = type(@filename) == "string" and @filename\match("^.+%.(.+)$") or "gif"
        obj.imgd = switch ext
            when "png"                               then @png!
            when "jpeg", "jpe", "jpg", "jfif", "jfi" then @jpg!
            when "bmp", "dib"                        then @bmp!
            when "gif"                               then @filename
        obj.optionpresets = {
            default: {
                -- Tracing
                ltres: 1
                qtres: 1
                pathomit: 8
                rightangleenhance: true
                -- Color quantization
                colorsampling: 2
                numberofcolors: 16
                mincolorratio: 0
                colorquantcycles: 3
                -- shape rendering
                strokewidth: 1
                scale: 1
                roundcoords: 2
                deletewhite: false
                deleteblack: false
                -- Blur
                blurradius: 0
                blurdelta: 20
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
            {0.27901, 0.44198, 0.27901}
            {0.135336, 0.228569, 0.272192, 0.228569, 0.135336}
            {0.086776, 0.136394, 0.178908, 0.195843, 0.178908, 0.136394, 0.086776}
            {0.063327, 0.093095, 0.122589, 0.144599, 0.152781, 0.144599, 0.122589, 0.093095, 0.063327}
            {0.049692, 0.069304, 0.089767, 0.107988, 0.120651, 0.125194, 0.120651, 0.107988, 0.089767, 0.069304, 0.049692}
        }
        -- randomseed
        math.randomseed os.time!
        -- Tracing imagedata, then returning tracedata (layers with paths, palette, image size)
        obj.to_trace_data = (options) ->
            options = obj.checkoptions(options)
            -- 1. Color quantization
            ii = obj.colorquantization(obj.imgd, options)
            -- create tracedata object
            tracedata = {
                layers:  {}
                palette: ii.palette
                width:   #ii.array[0] - 1
                height:  #ii.array - 1
            }
            -- Loop to trace each color layer
            for colornum = 0, #ii.palette - 1
                -- layeringstep -> pathscan -> internodes -> batchtracepaths
                layeringstep = obj.layeringstep(ii, colornum)
                pathscan     = obj.pathscan(layeringstep, options.pathomit)
                internodes   = obj.internodes(pathscan, options)
                tracedlayer  = obj.batchtracepaths(internodes, options.ltres, options.qtres)
                table.insert(tracedata.layers, tracedlayer)
            return tracedata

        -- Tracing imagedata, then returning the scaled svg string
        obj.to_shape = (options) ->
            options = obj.checkoptions(options)
            td = obj.to_trace_data(options)
            return obj.get_shape(td, options)

        -- creating options object, setting defaults for missing values
        obj.checkoptions = (options = {}) ->
            -- Option preset
            if type(options) == "string"
                options = options\lower!
                options = not obj.optionpresets[options] and {} or obj.optionpresets[options]
            -- Defaults
            for k in pairs obj.optionpresets.default
                options[k] = obj.optionpresets.default[k] unless rawget(options, k)
            -- options.pal is not defined here, the custom palette should be added externally
            -- options.pal = {{"r" = 0,"g" = 0,"b" = 0,"a" = 255}, {...}, ...}
            return options

        obj.blur = (imgd, radius, delta) ->
            -- new ImageData
            imgd2 = {
                width:  imgd.width
                height: imgd.height
                data:   ffi.new("ColorRGBA[?]", imgd.height * imgd.width)
            }
            -- radius and delta limits, this kernel
            radius = math.floor(radius)
            return imgd if radius < 1
            radius = 5 if radius > 5
            delta = math.abs(delta)
            delta = 1024 if delta > 1024
            thisgk = obj.gks[radius]
            -- loop through all pixels, horizontal blur
            for j = 0, imgd.height - 1
                for i = 0, imgd.width - 1
                    racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                    -- gauss kernel loop
                    for k = -radius, radius
                        -- add weighted color values
                        if i + k > 0 and i + k < imgd.width
                            idx = j * imgd.width + i + k
                            racc += imgd.data[idx].r * thisgk[k + radius + 1]
                            gacc += imgd.data[idx].g * thisgk[k + radius + 1]
                            bacc += imgd.data[idx].b * thisgk[k + radius + 1]
                            aacc += imgd.data[idx].a * thisgk[k + radius + 1]
                            wacc += thisgk[k + radius + 1]
                    -- The new pixel
                    idx = j * imgd.width + i
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
            -- copying the half blurred imgd2
            himgd = imgd2.data -- table_copy(imgd2.data)
            -- loop through all pixels, vertical blur
            for j = 0, imgd.height - 1
                for i = 0, imgd.width - 1
                    racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                    -- gauss kernel loop
                    for k = -radius, radius
                        -- add weighted color values
                        if j + k > 0 and j + k < imgd.height
                            idx = (j + k) * imgd.width + i
                            racc += himgd[idx].r * thisgk[k + radius + 1]
                            gacc += himgd[idx].g * thisgk[k + radius + 1]
                            bacc += himgd[idx].b * thisgk[k + radius + 1]
                            aacc += himgd[idx].a * thisgk[k + radius + 1]
                            wacc += thisgk[k + radius + 1]
                    -- The new pixel
                    idx = j * imgd.width + i
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
            -- Selective blur: loop through all pixels
            for j = 0, imgd.height - 1
                for i = 0, imgd.width - 1
                    idx = j * imgd.width + i
                    -- d is the difference between the blurred and the original pixel
                    d = math.abs(imgd2.data[idx].r - imgd.data[idx].r) + math.abs(imgd2.data[idx].g - imgd.data[idx].g) + math.abs(imgd2.data[idx].b - imgd.data[idx].b) + math.abs(imgd2.data[idx].a - imgd.data[idx].a)
                    -- selective blur: if d > delta, put the original pixel back
                    if d > delta
                        imgd2.data[idx].r = imgd.data[idx].r
                        imgd2.data[idx].g = imgd.data[idx].g
                        imgd2.data[idx].b = imgd.data[idx].b
                        imgd2.data[idx].a = imgd.data[idx].a
            return imgd2

        obj.colorquantization = (imgd, options) ->
            arr, idx, paletteacc, pixelnum, palette = {}, 0, {}, imgd.width * imgd.height, nil
            -- Filling arr (color index array) with -1
            for j = 0, imgd.height + 1
                arr[j] = {}
                for i = 0, imgd.width + 1
                    arr[j][i] = -1
            -- Use custom palette if pal is defined or sample / generate custom length palett
            if options.pal
                palette = options.pal
            elseif options.colorsampling == 0
                palette = obj.generatepalette(options.numberofcolors)
            elseif options.colorsampling == 1
                palette = obj.samplepalette(options.numberofcolors, imgd)
            else
                palette = obj.samplepalette2(options.numberofcolors, imgd)
            -- Selective Gaussian blur preprocessin
            imgd = obj.blur(imgd, options.blurradius, options.blurdelta) if options.blurradius > 0
            -- Repeat clustering step options.colorquantcycles times
            for cnt = 0, options.colorquantcycles - 1
                -- Average colors from the second iteration
                if cnt > 0
                    -- averaging paletteacc for palette
                    for k = 1, #palette
                        -- averaging
                        if paletteacc[k].n > 0
                            palette[k] = {
                                r: math.floor(paletteacc[k].r / paletteacc[k].n),
                                g: math.floor(paletteacc[k].g / paletteacc[k].n),
                                b: math.floor(paletteacc[k].b / paletteacc[k].n),
                                a: math.floor(paletteacc[k].a / paletteacc[k].n)
                            }
                        -- Randomizing a color, if there are too few pixels and there will be a new cycle
                        if paletteacc[k].n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1
                            palette[k] = {
                                r: math.floor(math.random! * 255)
                                g: math.floor(math.random! * 255)
                                b: math.floor(math.random! * 255)
                                a: math.floor(math.random! * 255)
                            }
                -- Reseting palette accumulator for averaging
                for i = 1, #palette
                    paletteacc[i] = {r: 0, g: 0, b: 0, a: 0, n: 0}
                -- loop through all pixels
                for j = 0, imgd.height - 1
                    for i = 0, imgd.width - 1
                        idx = j * imgd.width + i -- pixel index
                        -- find closest color from palette by measuring (rectilinear) color distance between this pixel and all palette colors
                        ci, cdl = 0, 1024 -- 4 * 256 is the maximum RGBA distance
                        for k = 1, #palette
                            -- In my experience, https://en.wikipedia.org/wiki/Rectilinear_distance works
                            -- better than https://en.wikipedia.org/wiki/Euclidean_distance
                            pr = palette[k].r > imgd.data[idx].r and palette[k].r - imgd.data[idx].r or imgd.data[idx].r - palette[k].r
                            pg = palette[k].g > imgd.data[idx].g and palette[k].g - imgd.data[idx].g or imgd.data[idx].g - palette[k].g
                            pb = palette[k].b > imgd.data[idx].b and palette[k].b - imgd.data[idx].b or imgd.data[idx].b - palette[k].b
                            pa = palette[k].a > imgd.data[idx].a and palette[k].a - imgd.data[idx].a or imgd.data[idx].a - palette[k].a
                            cd = pr + pg + pb + pa
                            -- Remember this color if this is the closest yet
                            cdl, ci = cd, k if cd < cdl
                        -- add to palettacc
                        paletteacc[ci].r += imgd.data[idx].r
                        paletteacc[ci].g += imgd.data[idx].g
                        paletteacc[ci].b += imgd.data[idx].b
                        paletteacc[ci].a += imgd.data[idx].a
                        paletteacc[ci].n += 1
                        arr[j + 1][i + 1] = ci - 1
            return {array: arr, palette: palette}

        -- Sampling a palette from imagedata
        obj.samplepalette = (numberofcolors, imgd) ->
            palette = {}
            for i = 0, numberofcolors - 1
                idx = math.floor(math.random! * (imgd.width * imgd.height) / 4) * 4
                table.insert(palette, {
                    r: imgd.data[idx].r
                    g: imgd.data[idx].g
                    b: imgd.data[idx].b
                    a: imgd.data[idx].a
                })
            return palette

        -- Deterministic sampling a palette from imagedata: rectangular grid
        obj.samplepalette2 = (numberofcolors, imgd) ->
            palette = {}
            ni = math.ceil(math.sqrt(numberofcolors))
            nj = math.ceil(numberofcolors / ni)
            vx = imgd.width / (ni + 1)
            vy = imgd.height / (nj + 1)
            for j = 0, nj - 1
                for i = 0, ni - 1
                    if #palette == numberofcolors
                        break
                    else
                        idx = math.floor(((j + 1) * vy) * imgd.width + ((i + 1) * vx))
                        table.insert(palette, {
                            r: imgd.data[idx].r
                            g: imgd.data[idx].g
                            b: imgd.data[idx].b
                            a: imgd.data[idx].a
                        })
            return palette

        -- Generating a palette with numberofcolors
        obj.generatepalette = (numberofcolors) ->
            palette = {}
            if numberofcolors < 8
                -- Grayscale
                graystep = math.floor(255 / (numberofcolors - 1))
                for i = 0, numberofcolors - 1
                    table.insert(palette, {
                        r: i * graystep
                        g: i * graystep
                        b: i * graystep
                        a: 255
                    })
            else
                -- RGB color cube
                colorqnum = math.floor(numberofcolors ^ (1 / 3)) -- Number of points on each edge on the RGB color cube
                colorstep = math.floor(255 / (colorqnum - 1)) -- distance between points
                rndnum = numberofcolors - ((colorqnum * colorqnum) * colorqnum) -- number of random colors
                for rcnt = 0, colorqnum - 1
                    for gcnt = 0, colorqnum - 1
                        for bcnt = 0, colorqnum - 1
                            table.insert(palette, {
                                r: rcnt * colorstep,
                                g: gcnt * colorstep,
                                b: bcnt * colorstep,
                                a: 255
                            })
                -- Rest is random
                for rcnt = 0, rndnum - 1
                    table.insert(palette, {
                        r: math.floor(math.random! * 255)
                        g: math.floor(math.random! * 255)
                        b: math.floor(math.random! * 255)
                        a: math.floor(math.random! * 255)
                    })
            return palette

        -- 2. Layer separation and edge detection
        -- Edge node types ( ▓: this layer or 1; ░: not this layer or 0 )
        -- 12  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓
        -- 48  ░░  ░░  ░░  ░░  ░▓  ░▓  ░▓  ░▓  ▓░  ▓░  ▓░  ▓░  ▓▓  ▓▓  ▓▓  ▓▓
        --     0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
        obj.layeringstep = (ii, cnum) ->
            -- Creating layers for each indexed color in arr
            layer, ah, aw = {}, #ii.array + 1, #ii.array[0] + 1
            for j = 0, ah - 1
                layer[j] = {}
                for i = 0, aw - 1
                    layer[j][i] = 0
            -- Looping through all pixels and calculating edge node type
            for j = 1, ah - 1
                for i = 1, aw - 1
                    l1 = ii.array[j - 1][i - 1] == cnum and 1 or 0
                    l2 = ii.array[j - 1][i - 0] == cnum and 2 or 0
                    l3 = ii.array[j - 0][i - 1] == cnum and 8 or 0
                    l4 = ii.array[j - 0][i - 0] == cnum and 4 or 0
                    layer[j][i] = l1 + l2 + l3 + l4
            return layer

        -- Point in polygon test
        obj.pointinpoly = (p, pa) ->
            isin = false
            j = #pa
            for i = 1, #pa
                isin = (pa[i].y > p.y) != (pa[j].y > p.y) and p.x < (pa[j].x - pa[i].x) * (p.y - pa[i].y) / (pa[j].y - pa[i].y) + pa[i].x and not isin or isin
                j = i
            return isin

        -- 3. Walking through an edge node array, discarding edge node types 0 and 15 and creating paths from the rest.
        -- Walk directions (dir): 0 > ; 1 ^ ; 2 < ; 3 v
        obj.pathscan = (arr, pathomit) ->
            paths, pacnt, pcnt, px, py, w, h, dir, pathfinished, holepath, lookuprow = {}, 1, 1, 0, 0, #arr[0] + 1, #arr + 1, 0, true, false, nil
            for j = 0, h - 1
                for i = 0, w - 1
                    if arr[j][i] == 4 or arr[j][i] == 11 --  Other values are not valid
                        px, py = i, j
                        paths[pacnt] = {}
                        paths[pacnt].points = {}
                        paths[pacnt].boundingbox = {px, py, px, py}
                        paths[pacnt].holechildren = {}
                        pathfinished = false
                        holepath = arr[j][i] == 11
                        pcnt, dir = 1, 1
                        -- Path points loop
                        while not pathfinished
                            -- New path point
                            paths[pacnt].points[pcnt] = {}
                            paths[pacnt].points[pcnt].x = px - 1
                            paths[pacnt].points[pcnt].y = py - 1
                            paths[pacnt].points[pcnt].t = arr[py][px]
                            -- Bounding box
                            paths[pacnt].boundingbox[1] = px - 1 if px - 1 < paths[pacnt].boundingbox[1]
                            paths[pacnt].boundingbox[3] = px - 1 if px - 1 > paths[pacnt].boundingbox[3]
                            paths[pacnt].boundingbox[2] = py - 1 if py - 1 < paths[pacnt].boundingbox[2]
                            paths[pacnt].boundingbox[4] = py - 1 if py - 1 > paths[pacnt].boundingbox[4]
                            -- Next: look up the replacement, direction and coordinate changes = clear this cell, turn if required, walk forward
                            lookuprow = obj.pathscan_combined_lookup[arr[py][px] + 1][dir + 1]
                            arr[py][px] = lookuprow[1]
                            dir = lookuprow[2]
                            px += lookuprow[3]
                            py += lookuprow[4]
                            -- Close path
                            if px - 1 == paths[pacnt].points[1].x and py - 1 == paths[pacnt].points[1].y
                                pathfinished = true
                                -- Discarding paths shorter than pathomit
                                if #paths[pacnt].points < pathomit
                                    table.remove(paths)
                                else
                                    paths[pacnt].isholepath = holepath and true or false
                                    if holepath
                                        parentidx, parentbbox = 1, {-1, -1, w + 1, h + 1}
                                        for parentcnt = 1, pacnt
                                            if not paths[parentcnt].isholepath and obj.boundingboxincludes(paths[parentcnt].boundingbox, paths[pacnt].boundingbox) and obj.boundingboxincludes(parentbbox, paths[parentcnt].boundingbox) and obj.pointinpoly(paths[pacnt].points[1], paths[parentcnt].points)
                                                parentidx = parentcnt
                                                parentbbox = paths[parentcnt].boundingbox
                                        table.insert(paths[parentidx].holechildren, pacnt)
                                    pacnt += 1
                            pcnt += 1
            return paths

        obj.boundingboxincludes = (parentbbox, childbbox) ->
            return (parentbbox[1] < childbbox[1]) and (parentbbox[2] < childbbox[2]) and (parentbbox[3] > childbbox[3]) and (parentbbox[4] > childbbox[4])

        -- 4. interpollating between path points for nodes with 8 directions ( East, SouthEast, S, SW, W, NW, N, NE )
        obj.internodes = (paths, options) ->
            ins, palen, nextidx, nextidx2, previdx, previdx2 = {}, 1, 1, 1, 1, 1
            -- paths loop
            for pacnt = 1, #paths
                ins[pacnt] = {}
                ins[pacnt].points = {}
                ins[pacnt].boundingbox = paths[pacnt].boundingbox
                ins[pacnt].holechildren = paths[pacnt].holechildren
                ins[pacnt].isholepath = paths[pacnt].isholepath
                palen = #paths[pacnt].points
                -- pathpoints loop
                for pcnt = 1, palen
                    -- next and previous point indexes
                    nextidx = pcnt % palen + 1
                    nextidx2 = (pcnt + 1) % palen + 1
                    previdx = (pcnt - 2 + palen) % palen + 1
                    previdx2 = (pcnt - 3 + palen) % palen + 1
                    -- right angle enhance
                    if options.rightangleenhance and obj.testrightangle(paths[pacnt], previdx2, previdx, pcnt, nextidx, nextidx2)
                        -- Fix previous direction
                        if #ins[pacnt].points > 1
                            ins[pacnt].points[#ins[pacnt].points].linesegment = obj.getdirection(ins[pacnt].points[#ins[pacnt].points].x, ins[pacnt].points[#ins[pacnt].points].y, paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y)
                        -- This corner point
                        table.insert(ins[pacnt].points, {
                            x: paths[pacnt].points[pcnt].x
                            y: paths[pacnt].points[pcnt].y
                            linesegment: obj.getdirection(paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y, (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2)
                        })
                    -- interpolate between two path points
                    table.insert(ins[pacnt].points, {
                        x: (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2
                        y: (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2
                        linesegment: obj.getdirection((paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2, (paths[pacnt].points[nextidx].x + paths[pacnt].points[nextidx2].x) / 2, (paths[pacnt].points[nextidx].y + paths[pacnt].points[nextidx2].y) / 2)
                    })
            return ins

        obj.testrightangle = (path, idx1, idx2, idx3, idx4, idx5) ->
            return (path.points[idx3].x == path.points[idx1].x and path.points[idx3].x == path.points[idx2].x and path.points[idx3].y == path.points[idx4].y and path.points[idx3].y == path.points[idx5].y) or (path.points[idx3].y == path.points[idx1].y and path.points[idx3].y == path.points[idx2].y and path.points[idx3].x == path.points[idx4].x and path.points[idx3].x == path.points[idx5].x)

        obj.getdirection = (x1, y1, x2, y2) ->
            val = 8
            if x1 < x2
                if y1 < y2 -- SouthEast
                    val = 1
                elseif y1 > y2 -- NE
                    val = 7
                else -- E
                    val = 0
            elseif x1 > x2
                if y1 < y2 -- SW
                    val = 3
                elseif y1 > y2 -- NW
                    val = 5
                else -- W
                    val = 4
            else
                if y1 < y2 -- S
                    val = 2
                elseif y1 > y2 -- N
                    val = 6
                else -- center, this should not happen
                    val = 8
            return val

        -- 5. tracepath() : recursively trying to fit straight and quadratic spline segments on the 8 direction internode path
        -- 5.1. Find sequences of points with only 2 segment types
        -- 5.2. Fit a straight line on the sequence
        -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
        -- 5.4. Fit a quadratic spline through errorpoint (project this to get controlpoint), then measure errors on every point in the sequence
        -- 5.5. If the spline fails (distance error > qtres), find the point with the biggest error, set splitpoint = fitting point
        -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
        obj.tracepath = (path, ltres, qtres) ->
            pcnt = 1
            smp = {}
            smp.segments = {}
            smp.boundingbox = path.boundingbox
            smp.holechildren = path.holechildren
            smp.isholepath = path.isholepath
            while pcnt < #path.points
                -- 5.1. Find sequences of points with only 2 segment types
                segtype1 = path.points[pcnt].linesegment
                segtype2 = -1
                seqend = pcnt + 1
                while (path.points[seqend].linesegment == segtype1 or path.points[seqend].linesegment == segtype2 or segtype2 == -1) and seqend < #path.points
                    if path.points[seqend].linesegment != segtype1 and segtype2 == -1
                        segtype2 = path.points[seqend].linesegment
                    seqend += 1
                seqend = 1 if seqend == #path.points
                -- 5.2. - 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
                smp.segments = concat(smp.segments, obj.fitseq(path, ltres, qtres, pcnt, seqend))
                -- forward pcnt
                pcnt = seqend > 1 and seqend or #path.points
            return smp

        -- 5.2. - 5.6. recursively fitting a straight or quadratic line segment on this sequence of path nodes,
        -- called from tracepath()
        obj.fitseq = (path, ltres, qtres, seqstart, seqend) ->
            -- return if invalid seqend
            return {} if seqend > #path.points or seqend < 1
            errorpoint, errorval, curvepass = seqstart, 0, true
            tl = seqend - seqstart
            tl += #path.points if tl < 1
            vx = (path.points[seqend].x - path.points[seqstart].x) / tl
            vy = (path.points[seqend].y - path.points[seqstart].y) / tl
            -- 5.2. Fit a straight line on the sequence
            pcnt = seqstart % #path.points + 1
            while pcnt != seqend
                pl = pcnt - seqstart
                pl += #path.points if pl < 1
                px = path.points[seqstart].x + vx * pl
                py = path.points[seqstart].y + vy * pl
                dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
                curvepass = false if dist2 > ltres
                if dist2 > errorval
                    errorpoint = pcnt - 1
                    errorval = dist2
                pcnt %= #path.points + 1
            -- return straight line if fits
            if curvepass
                return {
                    {
                        type: "l"
                        x1: path.points[seqstart].x, y1: path.points[seqstart].y
                        x2: path.points[seqend].x, y2: path.points[seqend].y
                    }
                }
            -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
            fitpoint = errorpoint + 1
            curvepass, errorval = true, 0
            -- 5.4. Fit a quadratic spline through this point, measure errors on every point in the sequence
            -- helpers and projecting to get control point
            t = (fitpoint - seqstart) / tl
            t1 = (1 - t) * (1 - t)
            t2 = 2 * (1 - t) * t
            t3 = t * t
            cpx = (t1 * path.points[seqstart].x + t3 * path.points[seqend].x - path.points[fitpoint].x) / -t2
            cpy = (t1 * path.points[seqstart].y + t3 * path.points[seqend].y - path.points[fitpoint].y) / -t2
            -- Check every point
            pcnt = seqstart + 1
            while pcnt != seqend
                t = (pcnt - seqstart) / tl
                t1 = (1 - t) * (1 - t)
                t2 = 2 * (1 - t) * t
                t3 = t * t
                px = t1 * path.points[seqstart].x + t2 * cpx + t3 * path.points[seqend].x
                py = t1 * path.points[seqstart].y + t2 * cpy + t3 * path.points[seqend].y
                dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
                curvepass = false if dist2 > qtres
                if dist2 > errorval
                    errorpoint = pcnt - 1
                    errorval = dist2
                pcnt %= #path.points + 1
            -- return spline if fits
            if curvepass
                x1, y1 = path.points[seqstart].x, path.points[seqstart].y
                x2, y2 = cpx, cpy
                x3, y3 = path.points[seqend].x, path.points[seqend].y
                return {
                    {
                        type: "b"
                        :x1, :y1
                        x2: (x1 + 2 * x2) / 3, y2: (y1 + 2 * y2) / 3
                        x3: (x3 + 2 * x2) / 3, y3: (y3 + 2 * y2) / 3
                        x4: x3, y4: y3
                    }
                }
            -- 5.5. If the spline fails (distance error>qtres), find the point with the biggest error
            splitpoint = fitpoint -- Earlier: math.floor((fitpoint + errorpoint) / 2)
            -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
            return concat(obj.fitseq(path, ltres, qtres, seqstart, splitpoint), obj.fitseq(path, ltres, qtres, splitpoint, seqend))

        -- 5. Batch tracing paths
        obj.batchtracepaths = (internodepaths, ltres, qtres) ->
            btracedpaths = {}
            for k in pairs internodepaths
                continue unless rawget(internodepaths, k)
                table.insert(btracedpaths, obj.tracepath(internodepaths[k], ltres, qtres))
            return btracedpaths

        -- Getting shape
        obj.shape_path = (tracedata, lnum, pathnum, options) ->
            layer = tracedata.layers[lnum]
            smp = layer[pathnum]
            build_style = (c) ->
                color = ("\\c&H%02X%02X%02X&")\format(c.b, c.g, c.r)
                alpha = ("\\alpha&H%02X&")\format(255 - c.a)
                return color, alpha
            color, alpha = build_style(tracedata.palette[lnum])
            -- Creating non-hole path string
            shape = ("m %s %s ")\format(
                round(smp.segments[1].x1 * options.scale, options.roundcoords),
                round(smp.segments[1].y1 * options.scale, options.roundcoords)
            )
            for pcnt = 1, #smp.segments
                shape ..= ("%s %s %s ")\format(
                    smp.segments[pcnt].type,
                    round(smp.segments[pcnt].x2 * options.scale, options.roundcoords),
                    round(smp.segments[pcnt].y2 * options.scale, options.roundcoords)
                )
                if rawget(smp.segments[pcnt], "x4")
                    shape ..= ("%s %s %s %s ")\format(
                        round(smp.segments[pcnt].x3 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].y3 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].x4 * options.scale, options.roundcoords),
                        round(smp.segments[pcnt].y4 * options.scale, options.roundcoords)
                    )
            -- Hole children
            for hcnt = 1, #smp.holechildren
                hsmp = layer[smp.holechildren[hcnt]]
                -- Creating hole path string
                if rawget(hsmp.segments[#hsmp.segments], "x4")
                    shape ..= ("m %s %s ")\format(
                        round(hsmp.segments[#hsmp.segments].x4 * options.scale),
                        round(hsmp.segments[#hsmp.segments].y4 * options.scale)
                    )
                else
                    shape ..= ("m %s %s ")\format(
                        hsmp.segments[#hsmp.segments].x2 * options.scale,
                        hsmp.segments[#hsmp.segments].y2 * options.scale
                    )
                for pcnt = #hsmp.segments, 1, -1
                    shape ..= hsmp.segments[pcnt].type .. " "
                    if rawget(hsmp.segments[pcnt], "x4")
                        shape ..= ("%s %s %s %s ")\format(
                            round(hsmp.segments[pcnt].x2 * options.scale),
                            round(hsmp.segments[pcnt].y2 * options.scale),
                            round(hsmp.segments[pcnt].x3 * options.scale),
                            round(hsmp.segments[pcnt].y3 * options.scale)
                        )
                    shape ..= ("%s %s ")\format(
                        round(hsmp.segments[pcnt].x1 * options.scale),
                        round(hsmp.segments[pcnt].y1 * options.scale)
                    )
            return shape, color, alpha

        -- 5. Batch tracing layers
        obj.get_shape = (tracedata, options) ->
            options = obj.checkoptions(options)
            shaper, build = {}, {}
            for lcnt = 1, #tracedata.layers
                for pcnt = 1, #tracedata.layers[lcnt]
                    unless tracedata.layers[lcnt][pcnt].isholepath
                        shape, color, alpha = obj.shape_path(tracedata, lcnt, pcnt, options)
                        if alpha != "\\alpha&HFF&" -- ignores invisible values
                            shaper[#shaper + 1] = {:shape, :color, :alpha}
            group = loadstring([[
                return function(t)
                    local group = {}
                    for i = 1, #t do
                        local v = t[i]
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
                    return group
                end
            ]])!(shaper)
            for i = 1, #group
                shape = ""
                for j = 1, #group[i]
                    shape ..= group[i][j].shape
                wt = obj.optionpresets.default.deletewhite
                bk = obj.optionpresets.default.deleteblack
                continue if wt and group[i][1].color == "\\c&HFFFFFF&" -- skip white
                continue if bk and group[i][1].color == "\\c&H000000&" -- skip black
                color = group[i][1].color .. (options.strokewidth > 0 and group[i][1].color\gsub("\\c", "\\3c") or "")
                build[#build + 1] = ("{\\an7\\pos(0,0)\\fscx100\\fscy100%s\\bord%s\\shad0\\p1}%s")\format(
                    color .. group[i][1].alpha, options.strokewidth, shape
                )
            return build
        return obj

return {PATH: PATH.new, PATHS: PATHS.new, CLIPPER: CLIPPER.new, OFFSET: OFFSET.new, :IMG}