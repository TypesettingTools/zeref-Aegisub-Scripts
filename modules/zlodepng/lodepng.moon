versionRecord = "22.1.9"

haveDepCtrl, DependencyControl = pcall require, 'l0.DependencyControl'

local ffi, requireffi, depctrl
if haveDepCtrl
    depctrl = DependencyControl({
        name: "lodepng"
        version: versionRecord
        description: "PNG encoder and decoder"
        author: "Zeref"
        url: "https://github.com/TypesettingTools/zeref-Aegisub-Scripts"
        moduleName: "zlodepng.lodepng"
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

has_loaded, PNG = pcall requireffi, "zlodepng.lodepng.lodepng"

ffi.cdef [[
    typedef enum {
        LCT_GREY = 0,
        LCT_RGB = 2,
        LCT_PALETTE = 3,
        LCT_GREY_ALPHA = 4,
        LCT_RGBA = 6,
    } LodePNGColorType;
    const char *LODEPNG_VERSION_STRING;
    const char *lodepng_error_text(unsigned int);
    unsigned int lodepng_decode32_file(unsigned char **, unsigned int *, unsigned int *, const char *);
]]


if haveDepCtrl
	return depctrl\register {:PNG, :has_loaded, version: versionRecord}
else
	return {:PNG, :has_loaded, version: versionRecord}
