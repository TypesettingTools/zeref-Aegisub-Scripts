ffi = require "ffi"
has_loaded, PNG = pcall require("requireffi.requireffi"), "zlodepng.lodepng.lodepng"

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

{:PNG, :has_loaded, version: ffi.string PNG.LODEPNG_VERSION_STRING}