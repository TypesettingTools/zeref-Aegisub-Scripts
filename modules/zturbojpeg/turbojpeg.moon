versionRecord = "2.1.3"

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

local ffi, requireffi, depctrl
if haveDepCtrl
    depctrl = DependencyControl({
        name: "turbojpeg"
        version: versionRecord
        description: "jpeg library"
        author: "Zeref"
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        moduleName: "zturbojpeg.turbojpeg"
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

has_loaded, JPG = pcall requireffi, "zturbojpeg.turbojpeg.turbojpeg"

ffi.cdef [[
    typedef void *tjhandle;
    typedef enum {
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
    } TJPF;
    typedef enum {
        TJSAMP_444 = 0,
        TJSAMP_422,
        TJSAMP_420,
        TJSAMP_GRAY,
        TJSAMP_440,
        TJSAMP_411
    } TJPF;
    int tjDestroy(tjhandle handle);
    tjhandle tjInitDecompress(void);
    int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace);
    int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags);
]]


if haveDepCtrl
	return depctrl\register {:JPG, :has_loaded, version: versionRecord}
else
	return {:JPG, :has_loaded, version: versionRecord}
