local ffi, requireffi, blitbuf, C

ffi = require("ffi")
requireffi = require("requireffi.requireffi")
blitbuf = require("img-libs.png.blitbuffer")

if (ffi.os == "Windows")
    if (ffi.arch == "x64")
        C = requireffi("img-libs.png.bin.x64")
    else
        C = requireffi("img-libs.png.bin.x86")
elseif (ffi.os == "Linux")
    C = requireffi("img-libs.png.bin.libpng")

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
    unsigned int lodepng_decode32(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, long unsigned int);
    unsigned int lodepng_decode24_file(unsigned char **, unsigned int *, unsigned int *, const char *);
    unsigned int lodepng_decode24(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, long unsigned int);
    unsigned int lodepng_decode_memory(unsigned char **, unsigned int *, unsigned int *, const unsigned char *, long unsigned int, LodePNGColorType, unsigned int);
    unsigned int lodepng_decode_file(unsigned char **, unsigned int *, unsigned int *, const char *, LodePNGColorType, unsigned int);
    unsigned int lodepng_encode32_file(const char *, const unsigned char *, unsigned int, unsigned int);
]]

return {
    encode_to_file: (filename, mem, w, h) ->
        err = C.lodepng_encode32_file(filename, mem, w, h)
        if (err != 0)
            err_msg = C.lodepng_error_text(err)
            return false, err_msg
        else
            return true

    decode_from_file: (filename) ->
        w, h, ptr = ffi.new("int[1]"), ffi.new("int[1]"), ffi.new("unsigned char*[1]")
        err = C.lodepng_decode32_file(ptr, w, h, filename)
        if (err != 0)
            error(ffi.string(C.lodepng_error_text(err)))
        else
            buf = blitbuf.new(w[0], h[0], blitbuf.TYPE_BBRGB32, ptr[0])
            buf\setAllocated(1)
            return buf
}