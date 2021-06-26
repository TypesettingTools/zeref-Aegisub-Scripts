local ffi = require "ffi"
local requireffi = require "requireffi.requireffi"
local C = nil

if ffi.os == "Windows" then
    if ffi.arch == "x64" then
        C = requireffi("img-libs.gif.bin.x64")
    else
        C = requireffi("img-libs.gif.bin.x86")
    end
elseif ffi.os == "Linux" then
    C = requireffi("img-libs.gif.bin.libpng")
end

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
    typedef struct gif_color {
        uint8_t r, g, b, a;
    } gif_color;
    GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
    int DGifSlurp(GifFileType * GifFile);
    GifFileType *DGifOpen(void *userPtr, GifInputFunc readFunc, int *Error);
    int DGifCloseFile(GifFileType * GifFile);
    char *GifErrorString(int ErrorCode);
    int DGifSavedExtensionToGCB(GifFileType *GifFile, int ImageIndex, GraphicsControlBlock *GCB);
]]

local open_filename = function(filename, err)
    return C.DGifOpenFileName(filename, err)
end

local open = function(opener, arg)
    local err = ffi.new("int[1]")
    local ft = (opener(arg, err) and opener(arg, err) or nil)
    return not ft and error(ffi.string(C.GifErrorString(err[0]))) or ft
end

local close = function(ft)
    if C.DGifCloseFile(ft) == 0 then
        return ffi.C.free(ft)
    end
end

local checknz = function(ft, res)
    if res ~= 0 then
        return
    end
    return error(ffi.string(C.GifErrorString(ft.Error)))
end

local gif = function(filename, opaque)
    local transparent = not opaque
    local ft = open(open_filename, filename)
    checknz(ft, C.DGifSlurp(ft))
    local obj = {
        frames = {},
        width = ft.SWidth,
        height = ft.SHeight
    }
    local gcb = ffi.new("GraphicsControlBlock")
    for i = 0, ft.ImageCount - 1 do
        local si = ft.SavedImages[i]
        local delay_ms, tcolor_idx
        if C.DGifSavedExtensionToGCB(ft, i, gcb) == 1 then
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
    close(ft)
    function obj:map()
        return obj.frames
    end
    return obj
end

return {gif = gif}