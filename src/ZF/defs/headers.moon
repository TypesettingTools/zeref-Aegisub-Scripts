ffi = require "ffi"

reqffi = require "requireffi.requireffi"

-- binaries
export hasCPP, hasPNG, hasJPG, hasGIF, CPP, PNG, JPG, GIF

assert ffi.os == "Windows" or ffi.os == "Linux", "Not compatible with your operating system!"
switch ffi.os
    when "Windows"
        switch ffi.arch
            when "x64"
                hasCPP, CPP = pcall reqffi, "ZF.defs.bin.win.clipper64"
                hasPNG, PNG = pcall reqffi, "ZF.defs.bin.win.png64"
                hasJPG, JPG = pcall reqffi, "ZF.defs.bin.win.jpg64"
                hasGIF, GIF = pcall reqffi, "ZF.defs.bin.win.gif64"
            when "x86"
                hasCPP, CPP = pcall reqffi, "ZF.defs.bin.win.clipper86"
                hasPNG, PNG = pcall reqffi, "ZF.defs.bin.win.png86"
                hasJPG, JPG = pcall reqffi, "ZF.defs.bin.win.jpg86"
                hasGIF, GIF = pcall reqffi, "ZF.defs.bin.win.gif86"
    when "Linux"
        assert ffi.arch == "x64", "Not compatible with your operating system!"
        if ffi.arch == "x64"
            hasCPP, CPP = pcall reqffi, "ZF.defs.bin.linux.clipper64"
            hasPNG, PNG = pcall reqffi, "ZF.defs.bin.linux.png64"
            hasJPG, JPG = pcall reqffi, "ZF.defs.bin.linux.jpg64"
            hasGIF, GIF = pcall reqffi, "ZF.defs.bin.linux.gif64"

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
    typedef struct color_8 {
        uint8_t a;
    } color_8;
    typedef struct color_8A {
        uint8_t a;
        uint8_t alpha;
    } color_8A;
    typedef struct color_16 {
        uint16_t v;
    } color_16;
    typedef struct color_24 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
    } color_24;
    typedef struct color_32 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t alpha;
    } color_32;
    typedef struct color_RGBA {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_RGBA;
    typedef struct buffer {
        int w;
        int h;
        int pitch;
        uint8_t *data;
        uint8_t config;
    } buffer;
    typedef struct buffer_8 {
        int w;
        int h;
        int pitch;
        color_8 *data;
        uint8_t config;
    } buffer_8;
    typedef struct buffer_8A {
        int w;
        int h;
        int pitch;
        color_8A *data;
        uint8_t config;
    } buffer_8A;
    typedef struct buffer_16 {
        int w;
        int h;
        int pitch;
        color_16 *data;
        uint8_t config;
    } buffer_16;
    typedef struct buffer_24 {
        int w;
        int h;
        int pitch;
        color_24 *data;
        uint8_t config;
    } buffer_24;
    typedef struct buffer_32 {
        int w;
        int h;
        int pitch;
        color_32 *data;
        uint8_t config;
    } buffer_32;
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