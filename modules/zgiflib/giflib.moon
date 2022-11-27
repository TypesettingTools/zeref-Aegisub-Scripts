versionRecord = "5.2.1"

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

local ffi, requireffi, depctrl
if haveDepCtrl
    depctrl = DependencyControl({
        name: "giflib"
        version: versionRecord
        description: "giflib is a library for reading and writing gif images."
        author: "Zeref"
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        moduleName: "zgiflib.giflib"
        feed: "https://raw.githubusercontent.com/TypesettingTools/zeref-Aegisub-Scripts/main/DependencyControl.json"
        {
            { "ffi" }
            { "requireffi.requireffi", version: "0.1.2" }
        }
    })
    ffi, requireffi = depctrl\requireModules!
else
    ffi = require "ffi"
    requireffi = require "requireffi.requireffi"

has_loaded, GIF = pcall requireffi, "zgiflib.giflib.giflib"

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

if haveDepCtrl
	return depctrl\register {:GIF, :has_loaded, version: versionRecord}
else
	return {:GIF, :has_loaded, version: versionRecord}
