local ffi, requireffi, C

ffi = require("ffi")
requireffi = require("requireffi.requireffi")

if (ffi.os == "Windows")
    if (ffi.arch == "x64")
        C = requireffi("img-libs.gif.bin.x64")
    else
        C = requireffi("img-libs.gif.bin.x86")
elseif (ffi.os == "Linux")
    C = requireffi("img-libs.gif.bin.libgif")

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
    typedef struct COLORBGRA8 {
        uint8_t r, g, b, a;
    } COLORBGRA8;
    GifFileType *DGifOpenFileName(const char *GifFileName, int *Error);
    int DGifSlurp(GifFileType * GifFile);
    GifFileType *DGifOpen(void *userPtr, GifInputFunc readFunc, int *Error);
    int DGifCloseFile(GifFileType * GifFile);
    char *GifErrorString(int ErrorCode);
    int DGifSavedExtensionToGCB(GifFileType *GifFile, int ImageIndex, GraphicsControlBlock *GCB);
]]

open_filename = (filename, err) -> C.DGifOpenFileName(filename, err)

open = (opener, arg) ->
    err = ffi.new "int[1]"
    ft = (opener(arg, err) != nil and opener(arg, err) or nil)
    return not ft and error(ffi.string(C.GifErrorString(err[0]))) or ft

close = (ft) ->
    ffi.C.free(ft) if (C.DGifCloseFile(ft) == 0)
    return

checknz = (ft, res) ->
    return if (res != 0)
    error(ffi.string(C.GifErrorString(ft.Error)))
    return

return {
    decode_from_file: (filename) ->
        -- normalize args
        filename = (type(filename) == "string" and {path: filename} or filename)
        transparent = not filename.opaque
        -- open source
        ft = open(open_filename, filename.path)
        -- decode gif
        checknz(ft, C.DGifSlurp(ft))
        -- collect data
        gif = {frames: {}}
        gif.w, gif.h = ft.SWidth, ft.SHeight
        c = ft.SColorMap.Colors[ft.SBackGroundColor]
        gif.bg_color = {c.Red / 255, c.Green / 255, c.Blue / 255}
        gcb = ffi.new "GraphicsControlBlock"
        for i = 0, ft.ImageCount - 1
            si = ft.SavedImages[i]
            -- find delay and transparent color index, if any
            local delay_ms, tcolor_idx
            if C.DGifSavedExtensionToGCB(ft, i, gcb) == 1
                delay_ms = gcb.DelayTime * 10 -- make it milliseconds
                tcolor_idx = gcb.TransparentColor
            w, h = si.ImageDesc.Width, si.ImageDesc.Height
            colormap = si.ImageDesc.ColorMap != nil and si.ImageDesc.ColorMap or ft.SColorMap
            -- convert image to top-down 8bpc rgba.
            stride = w * 4
            size = stride * h
            data = ffi.new("COLORBGRA8[?]", size)
            for k = 0, w * h - 1
                idx = si.RasterBits[k]
                assert(idx < colormap.ColorCount)
                if (idx == tcolor_idx) and transparent
                    data[k].b = 0
                    data[k].g = 0
                    data[k].r = 0
                    data[k].a = 0
                else
                    data[k].b = colormap.Colors[idx].Blue
                    data[k].g = colormap.Colors[idx].Green
                    data[k].r = colormap.Colors[idx].Red
                    data[k].a = 0xff
            img = {:data, :w, :h, x: si.ImageDesc.Left, y: si.ImageDesc.Top, :delay_ms}
            gif.frames[#gif.frames + 1] = img
        close(ft)
        return gif
    :C
}