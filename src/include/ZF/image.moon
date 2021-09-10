-- load internal libs
ffi = require "ffi"
bit = require "bit"

-- load external libs
import MATH  from require "ZF.math"
import TABLE from require "ZF.table"
import SHAPE from require "ZF.shape"

-- get types
color_8  = ffi.typeof "color_8"
color_8A = ffi.typeof "color_8A"
color_16 = ffi.typeof "color_16"
color_24 = ffi.typeof "color_24"
color_32 = ffi.typeof "color_32"
int_t    = ffi.typeof "int"
uint8pt  = ffi.typeof "uint8_t*"

-- metatables
local COLOR_8, COLOR_8A, COLOR_16, COLOR_24, COLOR_32, BBF8, BBF8A, BBF16, BBF24, BBF32, BBF

COLOR_8 = {
    get_color_8:  (self) -> self
    get_color_8A: (self) -> color_8A(self.a, 0)
    get_color_16: (self) ->
        v = self\get_color_8!.a
        v5bit = bit.rshift(v, 3)
        return color_16(bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit)
    get_color_24: (self) ->
        v = self\get_color_8!
        return color_24(v.a, v.a, v.a)
    get_color_32: (self) -> color_32(self.a, self.a, self.a, 0xFF)
    get_r:        (self) -> self\get_color_8!.a
    get_g:        (self) -> self\get_color_8!.a
    get_b:        (self) -> self\get_color_8!.a
    get_a:        (self) -> int_t(0xFF)
}

COLOR_8A = {
    get_color_8: (self) -> color_8(self.a)
    get_color_8A: (self) -> self
    get_color_16: COLOR_8.get_color_16
    get_color_24: COLOR_8.get_color_24
    get_color_32: (self) -> color_32(self.a, self.a, self.a, self.alpha)
    get_r:        COLOR_8.get_r
    get_g:        COLOR_8.get_r
    get_b:        COLOR_8.get_r
    get_a:        (self) -> self.alpha
}

COLOR_16 = {
    get_color_8: (self) ->
        r = bit.rshift(self.v, 11)
        g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
        b = bit.rshift(self.v, 0x001F)
        return color_8(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14))
    get_color_8A: (self) ->
        r = bit.rshift(self.v, 11)
        g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
        b = bit.rshift(self.v, 0x001F)
        return color_8A(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0)
    get_color_16: (self) -> self
    get_color_24: (self) ->
        r = bit.rshift(self.v, 11)
        g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
        b = bit.rshift(self.v, 0x001F)
        return color_24(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2))
    get_color_32: (self) ->
        r = bit.rshift(self.v, 11)
        g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
        b = bit.rshift(self.v, 0x001F)
        return color_32(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF)
    get_r: (self) ->
        r = bit.rshift(self.v, 11)
        return bit.lshift(r, 3) + bit.rshift(r, 2)
    get_g: (self) ->
        g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
        return bit.lshift(g, 2) + bit.rshift(g, 4)
    get_b: (self) ->
        b = bit.rshift(self.v, 0x001F)
        return bit.lshift(b, 3) + bit.rshift(b, 2)
    get_a: COLOR_8.get_a
}

COLOR_24 = {
    get_color_8:  (self) -> color_8(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14))
    get_color_8A: (self) -> color_8A(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), 0)
    get_color_16: (self) -> color_16(bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3))
    get_color_24: (self) -> self
    get_color_32: (self) -> color_32(self.r, self.g, self.b, 0xFF)
    get_r:        (self) -> self.r
    get_g:        (self) -> self.g
    get_b:        (self) -> self.b
    get_a:        COLOR_8.get_a
}

COLOR_32 = {
    get_color_8:  COLOR_24.get_color_8
    get_color_8A: (self) -> color_8A(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), self\get_a!)
    get_color_16: COLOR_24.get_color_16
    get_color_24: (self) -> color_24(self.r, self.g, self.b)
    get_color_32: (self) -> self
    get_r:        COLOR_24.get_r
    get_g:        COLOR_24.get_g
    get_b:        COLOR_24.get_b
    get_a:        (self) -> self.alpha
}

BBF = {
    get_rotation:  (self) -> bit.rshift(bit.band(0x0C, self.config), 2)
    get_inverse:   (self) -> bit.rshift(bit.band(0x02, self.config), 1)
    set_allocated: (self, allocated) -> self.config = bit.bor(bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0))
    set_type:      (self, type_id) -> self.config = bit.bor(bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4))
    get_physical_coordinates: (self, x, y) ->
        return switch self\get_rotation!
            when 0 then x, y
            when 1 then self.w - y - 1, x
            when 2 then self.w - x - 1, self.h - y - 1
            when 3 then y, self.h - x - 1
    get_pixel_p: (self, x, y) -> ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x
    get_pixel:   (self, x, y) ->
        px, py = self\get_physical_coordinates(x, y)
        color = self\get_pixel_p(px, py)[0]
        color = color\invert! if self\get_inverse! == 1
        return color
    get_width:  (self) -> bit.band(1, self\get_rotation!) == 0 and self.w or self.h
    get_height: (self) -> bit.band(1, self\get_rotation!) == 0 and self.h or self.w
}

BBF8  = {get_bpp: (self) -> 8}
BBF8A = {get_bpp: (self) -> 8}
BBF16 = {get_bpp: (self) -> 16}
BBF24 = {get_bpp: (self) -> 24}
BBF32 = {get_bpp: (self) -> 32}

for n, f in pairs BBF
    BBF8[n]  = f unless BBF8[n]
    BBF8A[n] = f unless BBF8A[n]
    BBF16[n] = f unless BBF16[n]
    BBF24[n] = f unless BBF24[n]
    BBF32[n] = f unless BBF32[n]

BUFFER8  = ffi.metatype "buffer_8",  {__index: BBF8}
BUFFER8A = ffi.metatype "buffer_8A", {__index: BBF8A}
BUFFER16 = ffi.metatype "buffer_16", {__index: BBF16}
BUFFER24 = ffi.metatype "buffer_24", {__index: BBF24}
BUFFER32 = ffi.metatype "buffer_32", {__index: BBF32}

ffi.metatype "color_8",  {__index: COLOR_8}
ffi.metatype "color_8A", {__index: COLOR_8A}
ffi.metatype "color_16", {__index: COLOR_16}
ffi.metatype "color_24", {__index: COLOR_24}
ffi.metatype "color_32", {__index: COLOR_32}

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
        when 1 then BUFFER8(width, height, pitch, nil, 0)
        when 2 then BUFFER8A(width, height, pitch, nil, 0)
        when 3 then BUFFER16(width, height, pitch, nil, 0)
        when 4 then BUFFER24(width, height, pitch, nil, 0)
        when 5 then BUFFER32(width, height, pitch, nil, 0)
        else error "unknown blitbuffer type"
    bb\set_type(buffertype)
    if dataptr == nil
        dataptr = ffi.C.malloc(pitch * height)
        assert dataptr, "cannot allocate memory for blitbuffer"
        ffi.fill(dataptr, pitch * height)
        bb\set_allocated(1)
    bb.data = ffi.cast(bb.data, dataptr)
    return bb

class IMAGE

    new: (filename) => @filename = filename

    bmp: =>
        read_word = (data, offset) -> data\byte(offset + 1) * 256 + data\byte(offset)
        read_dword = (data, offset) -> read_word(data, offset + 2) * 65536 + read_word(data, offset)
        file = assert io.open(@filename, "rb"), "Can't open file!"
        data = file\read("*a")
        file\close!
        if not read_dword(data, 1) == 0x4D42 -- Bitmap "magic" header
            return nil, "Bitmap magic not found"
        elseif read_word(data, 29) != 24 -- Bits per pixel
            return nil, "Only 24bpp bitmaps supported"
        elseif read_dword(data, 31) != 0 -- Compression
            return nil, "Only uncompressed bitmaps supported"
        obj = {
            data:         data
            bit_depth:    24
            pixel_offset: read_word(data, 11)
            width:        read_dword(data, 19)
            height:       read_dword(data, 23)
        }
        obj.get_pixel = (x, y) ->
            if (x < 0) or (x > obj.width) or (y < 0) or (y > obj.height)
                return nil, "Out of bounds"
            index = obj.pixel_offset + (obj.height - y - 1) * 3 * obj.width + x * 3
            b = data\byte(index + 1)
            g = data\byte(index + 2)
            r = data\byte(index + 3)
            return r, g, b
        obj.data = ffi.new "color_RGBA[?]", obj.width * obj.height
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
            data = ffi.new "color_RGBA[?]", size
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
            img = {:data, width: w, height: h, x: si.ImageDesc.Left, y: si.ImageDesc.Top, :delay_ms}
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
            bit_depth: buf\get_bpp!,
            width:     buf\get_width!,
            height:    buf\get_height!
        }
        obj.get_pixel = (x, y) -> buf\get_pixel(x, y)
        obj.data = ffi.new "color_RGBA[?]", obj.width * obj.height
        for y = 0, obj.height - 1
            for x = 0, obj.width - 1
                i = y * obj.width + x
                color = obj.get_pixel(x, y)\get_color_32!
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
        buf\set_allocated(1)
        obj = {
            data:      buf,
            bit_depth: buf\get_bpp!,
            width:     buf\get_width!,
            height:    buf\get_height!
        }
        obj.get_pixel = (x, y) -> buf\get_pixel(x, y)
        obj.data = ffi.new "color_RGBA[?]", obj.width * obj.height
        for y = 0, obj.height - 1
            for x = 0, obj.width - 1
                i = y * obj.width + x
                color = obj.get_pixel(x, y)\get_color_32!
                obj.data[i].r = color.r
                obj.data[i].g = color.g
                obj.data[i].b = color.b
                obj.data[i].a = color.alpha
        return obj

    raster: (rez) =>
        ext = type(@filename) == "string" and @filename\match("^.+%.(.+)$") or "gif"
        img = switch ext
            when "png"                               then @png!
            when "jpeg", "jpe", "jpg", "jfif", "jfi" then @jpg!
            when "bmp", "dib"                        then @bmp!
            when "gif"                               then @filename
        shpx = "m 0 0 l %d 0 %d 1 0 1"
        pstr = "{\\an7\\pos(0,%d)\\fscx100\\fscy100\\bord0\\shad0\\p1}"
        pstl = "{\\an7\\pos(%d,%d)\\fscx100\\fscy100\\bord0\\shad0%s\\p1}m 0 0 l 1 0 1 1 0 1"
        rel_pixels = (img) -> -- real pixels
            px = {}
            for y = 0, img.height - 1
                for x = 0, img.width - 1
                    i = y * img.width + x
                    color = ("\\cH%02X%02X%02X")\format(img.data[i].b, img.data[i].g, img.data[i].r)
                    alpha = ("\\alphaH%02X")\format(255 - img.data[i].a)
                    continue if alpha == "\\alphaHFF"
                    px[#px + 1] = (pstl)\format(x, y, color .. alpha)
            return px
        rez_pixels = (img, once) -> -- resize pixels
            ct_s, ct_r, px, color, alpha = {}, {}, {}, {}, {}
            for y = 0, img.height - 1
                ct_s[y], ct_r[y], px[y] = 0, 0, ""
                for x = 0, img.width - 1
                    i = y * img.width + x
                    b, g, r = img.data[i].b, img.data[i].g, img.data[i].r
                    color_p = ("\\cH%02X%02X%02X")\format(b, g, r)
                    color_n = ("\\cH%02X%02X%02X")\format(img.data[i + 1].b or b, img.data[i + 1].g or g, img.data[i + 1].r or r)
                    alpha_p = ("\\alphaH%02X")\format(255 - img.data[i].a)
                    color[y], alpha[y] = color_p, alpha_p
                    if color_p == color_n
                        ct_s[y] += 1
                        ct_r[y] += 1
                    else
                        px[y] ..= ("{%s}#{shpx}")\format(color[y] .. alpha[y], ct_r[y] + 1, ct_r[y] + 1)
                        ct_s[y] -= ct_r[y]
                        ct_r[y] = 0
                if px[y] != ""
                    px[y] = ("#{pstr}%s")\format(y, px[y])
                    if ct_s[y] < img.width and ct_s[y] > 0
                        px[y] ..= alpha[y] != "\\alphaHFF" and ("{%s}#{shpx}")\format(color[y] .. alpha[y], ct_s[y], ct_s[y]) or ""
                else
                    px[y] = alpha[y] != "\\alphaHFF" and ("{\\an7\\pos(0,%d)\\fscx100\\fscy100\\bord0\\shad0%s\\p1}#{shpx}")\format(y, color[y] .. alpha[y], img.width, img.width) or nil
            if once
                line = ""
                for k, v in pairs px
                    line ..= v\gsub("%b{}", "", 1) .. "{\\p0}\\N{\\p1}"
                line = ("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0\\p1}#{line}")\gsub("{\\p0}\\N{\\p1}$", "")
                return {line}
            return px
        return rez and (rez == "once" and rez_pixels(img, true) or rez_pixels(img)) or rel_pixels(img)

    tracer: =>
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
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
            {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}}
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}}
            {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}}
            {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}}
            {{13, 3, 0, 1},    {13, 2, -1, 0},   {7, 1, 0, -1},    {7, 0, 1, 0}}
            {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}}
            {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}}
            {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}}
            {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}}
            {{11, 1, 0, -1},   {14, 0, 1, 0},    {14, 3, 0, 1},    {11, 2, -1, 0}}
            {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}}
            {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}}
            {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}}
            {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}}
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
                data:   ffi.new("color_RGBA[?]", imgd.height * imgd.width)
            }
            -- radius and delta limits, this kernel
            radius = floor(radius)
            return imgd if radius < 1
            radius = 5 if radius > 5
            delta = abs(delta)
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
                    imgd2.data[idx].r = floor(racc / wacc)
                    imgd2.data[idx].g = floor(gacc / wacc)
                    imgd2.data[idx].b = floor(bacc / wacc)
                    imgd2.data[idx].a = floor(aacc / wacc)
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
                    imgd2.data[idx].r = floor(racc / wacc)
                    imgd2.data[idx].g = floor(gacc / wacc)
                    imgd2.data[idx].b = floor(bacc / wacc)
                    imgd2.data[idx].a = floor(aacc / wacc)
            -- Selective blur: loop through all pixels
            for j = 0, imgd.height - 1
                for i = 0, imgd.width - 1
                    idx = j * imgd.width + i
                    -- d is the difference between the blurred and the original pixel
                    d = abs(imgd2.data[idx].r - imgd.data[idx].r) + abs(imgd2.data[idx].g - imgd.data[idx].g) + abs(imgd2.data[idx].b - imgd.data[idx].b) + abs(imgd2.data[idx].a - imgd.data[idx].a)
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
                                r: floor(paletteacc[k].r / paletteacc[k].n)
                                g: floor(paletteacc[k].g / paletteacc[k].n)
                                b: floor(paletteacc[k].b / paletteacc[k].n)
                                a: floor(paletteacc[k].a / paletteacc[k].n)
                            }
                        -- Randomizing a color, if there are too few pixels and there will be a new cycle
                        if paletteacc[k].n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1
                            palette[k] = {
                                r: floor(random! * 255)
                                g: floor(random! * 255)
                                b: floor(random! * 255)
                                a: floor(random! * 255)
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
                idx = floor(random! * (imgd.width * imgd.height) / 4) * 4
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
            ni = ceil(sqrt(numberofcolors))
            nj = ceil(numberofcolors / ni)
            vx = imgd.width / (ni + 1)
            vy = imgd.height / (nj + 1)
            for j = 0, nj - 1
                for i = 0, ni - 1
                    if #palette == numberofcolors
                        break
                    else
                        idx = floor(((j + 1) * vy) * imgd.width + ((i + 1) * vx))
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
                graystep = floor(255 / (numberofcolors - 1))
                for i = 0, numberofcolors - 1
                    table.insert(palette, {
                        r: i * graystep
                        g: i * graystep
                        b: i * graystep
                        a: 255
                    })
            else
                -- RGB color cube
                colorqnum = floor(numberofcolors ^ (1 / 3)) -- Number of points on each edge on the RGB color cube
                colorstep = floor(255 / (colorqnum - 1)) -- distance between points
                rndnum = numberofcolors - ((colorqnum * colorqnum) * colorqnum) -- number of random colors
                for rcnt = 0, colorqnum - 1
                    for gcnt = 0, colorqnum - 1
                        for bcnt = 0, colorqnum - 1
                            table.insert(palette, {
                                r: rcnt * colorstep
                                g: gcnt * colorstep
                                b: bcnt * colorstep
                                a: 255
                            })
                -- Rest is random
                for rcnt = 0, rndnum - 1
                    table.insert(palette, {
                        r: floor(random! * 255)
                        g: floor(random! * 255)
                        b: floor(random! * 255)
                        a: floor(random! * 255)
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

        obj.boundingboxincludes = (parentbbox, childbbox) -> (parentbbox[1] < childbbox[1]) and (parentbbox[2] < childbbox[2]) and (parentbbox[3] > childbbox[3]) and (parentbbox[4] > childbbox[4])

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

        obj.testrightangle = (path, idx1, idx2, idx3, idx4, idx5) -> (path.points[idx3].x == path.points[idx1].x and path.points[idx3].x == path.points[idx2].x and path.points[idx3].y == path.points[idx4].y and path.points[idx3].y == path.points[idx5].y) or (path.points[idx3].y == path.points[idx1].y and path.points[idx3].y == path.points[idx2].y and path.points[idx3].x == path.points[idx4].x and path.points[idx3].x == path.points[idx5].x)

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
                smp.segments = TABLE(smp.segments)\concat(obj.fitseq(path, ltres, qtres, pcnt, seqend))
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
            splitpoint = fitpoint -- Earlier: floor((fitpoint + errorpoint) / 2)
            -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
            return TABLE(obj.fitseq(path, ltres, qtres, seqstart, splitpoint))\concat(obj.fitseq(path, ltres, qtres, splitpoint, seqend))

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
            x1 = MATH\round(smp.segments[1].x1 * options.scale, options.roundcoords)
            y1 = MATH\round(smp.segments[1].y1 * options.scale, options.roundcoords)
            shape = ("m %s %s ")\format(x1, y1)
            for pcnt = 1, #smp.segments
                x2 = MATH\round(smp.segments[pcnt].x2 * options.scale, options.roundcoords)
                y2 = MATH\round(smp.segments[pcnt].y2 * options.scale, options.roundcoords)
                shape ..= ("%s %s %s ")\format(smp.segments[pcnt].type, x2, y2)
                if rawget(smp.segments[pcnt], "x4")
                    x3 = MATH\round(smp.segments[pcnt].x3 * options.scale, options.roundcoords)
                    y3 = MATH\round(smp.segments[pcnt].y3 * options.scale, options.roundcoords)
                    x4 = MATH\round(smp.segments[pcnt].x4 * options.scale, options.roundcoords)
                    y4 = MATH\round(smp.segments[pcnt].y4 * options.scale, options.roundcoords)
                    shape ..= ("%s %s %s %s ")\format(x3, y3, x4, y4)
            -- Hole children
            for hcnt = 1, #smp.holechildren
                hsmp = layer[smp.holechildren[hcnt]]
                -- Creating hole path string
                if rawget(hsmp.segments[#hsmp.segments], "x4")
                    x4 = MATH\round(hsmp.segments[#hsmp.segments].x4 * options.scale)
                    y4 = MATH\round(hsmp.segments[#hsmp.segments].y4 * options.scale)
                    shape ..= ("m %s %s ")\format(x4, y4)
                else
                    x2 = MATH\round(hsmp.segments[#hsmp.segments].x2 * options.scale)
                    y2 = MATH\round(hsmp.segments[#hsmp.segments].y2 * options.scale)
                    shape ..= ("m %s %s ")\format(x2, y2)
                for pcnt = #hsmp.segments, 1, -1
                    shape ..= hsmp.segments[pcnt].type .. " "
                    if rawget(hsmp.segments[pcnt], "x4")
                        x2 = MATH\round(hsmp.segments[pcnt].x2 * options.scale, options.roundcoords)
                        y2 = MATH\round(hsmp.segments[pcnt].y2 * options.scale, options.roundcoords)
                        x3 = MATH\round(hsmp.segments[pcnt].x3 * options.scale, options.roundcoords)
                        y3 = MATH\round(hsmp.segments[pcnt].y3 * options.scale, options.roundcoords)
                        shape ..= ("%s %s %s %s ")\format(x2, y2, x3, y3)
                    x1 = MATH\round(hsmp.segments[pcnt].x1 * options.scale, options.roundcoords)
                    y1 = MATH\round(hsmp.segments[pcnt].y1 * options.scale, options.roundcoords)
                    shape ..= ("%s %s ")\format(x1, y1)
            return SHAPE(shape)\build!, color, alpha

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
                build[#build + 1] = ("{\\an7\\pos(0,0)\\fscx100\\fscy100%s\\bord%s\\shad0\\p1}%s")\format(color .. group[i][1].alpha, options.strokewidth, shape)
            return build
        return obj

    potrace: (...) =>
        push_b0 = (t, ...) -> -- table.push base 0
            n = select("#", ...)
            for i = 1, n
                v = select(i, ...)
                if not t[0] and #t == 0
                    t[0] = v
                else
                    t[#t + 1] = v
            return ...

        class Point

            new: (x = 0, y = 0) =>
                @x = x
                @y = y

            copy: => Point(@x, @y)

        class Bitmap

            new: (w, h) =>
                @w = w
                @h = h
                @size = w * h
                @data = {}

            at: (x, y) => (x >= 0 and x < @w and y >= 0 and y < @h) and (@data[@w * y + x] == 1)

            index: (i) =>
                point = Point!
                point.y = floor(i / @w)
                point.x = i - point.y * @w
                return point

            flip: (x, y) =>
                if @at(x, y)
                    @data[@w * y + x] = 0
                else
                    @data[@w * y + x] = 1

            copy: =>
                bm = Bitmap(@w, @h)
                for i = 0, @size - 1
                    bm.data[i] = @data[i]
                return bm

        class Curve

            new: (n) =>
                @n = n
                @tag = {}
                @c = {}
                @alphaCurve = 0
                @vertex = {}
                @alpha = {}
                @alpha0 = {}
                @beta = {}

        class Path

            new: =>
                @area = 0
                @len = 0
                @curve = {}
                @pt = {}
                @minX = 100000
                @minY = 100000
                @maxX = -1
                @maxY = -1

        class Sum

            new: (x, y, xy, x2, y2) =>
                @x = x
                @y = y
                @xy = xy
                @x2 = x2
                @y2 = y2

        class Configs

            new: (...) =>
                args = ... and (type(...) == "table" and ... or {...}) or {}
                @turnpolicy = args[1] or "minority"
                @turdsize = args[2] or 2
                @optcurve = args[3] or true
                @alphamax = args[4] or 1
                @opttolerance = args[5] or 0.2

        class Potrace

            new: (filename, ...) =>
                img, ext = IMAGE(filename), type(filename) == "string" and filename\match("^.+%.(.+)$") or "gif"
                cot = switch ext -- content
                    when "png"                               then img\png!
                    when "jpeg", "jpe", "jpg", "jfif", "jfi" then img\jpg!
                    when "bmp", "dib"                        then img\bmp!
                    when "gif"                               then filename
                @bm = Bitmap(cot.width, cot.height)
                @info = Configs(...)
                @pathlist = Path!
                for i = 0, cot.width * cot.height - 1
                    color = 0.2126 * cot.data[i].r + 0.7153 * cot.data[i].g + 0.0721 * cot.data[i].b
                    @bm.data[i] = color < 128 and 1 or 0
                return @

            process: =>
                @bmToPathlist!
                @processPath!
                return

            bmToPathlist: =>
                currentPoint = Point!
                bm1 = @bm\copy!
                findNext = (point) ->
                    i = bm1.w * point.y + point.x
                    while i < bm1.size and bm1.data[i] != 1
                        i += 1
                    return i < bm1.size and bm1\index(i) or nil

                majority = (x, y) ->
                    for i = 2, 4
                        ct = 0
                        for a = -i + 1, i - 1
                            ct += bm1\at(x + a, y + i - 1) and 1 or -1
                            ct += bm1\at(x + i - 1, y + a - 1) and 1 or -1
                            ct += bm1\at(x + a - 1, y - i) and 1 or -1
                            ct += bm1\at(x - i, y + a) and 1 or -1
                        if ct > 0
                            return 1
                        elseif ct < 0
                            return 0
                    return 0

                findPath = (point) ->
                    path, x, y, dirx, diry = Path!, point.x, point.y, 0, 1
                    path.sign = @bm\at(point.x, point.y) and "+" or "-"
                    while true
                        push_b0(path.pt, Point(x, y))
                        if x > path.maxX then path.maxX = x
                        if x < path.minX then path.minX = x
                        if y > path.maxY then path.maxY = y
                        if y < path.minY then path.minY = y
                        path.len += 1
                        x += dirx
                        y += diry
                        path.area -= x * diry
                        break if x == point.x and y == point.y
                        l = bm1\at(x + (dirx + diry - 1) / 2, y + (diry - dirx - 1) / 2)
                        r = bm1\at(x + (dirx - diry - 1) / 2, y + (diry + dirx - 1) / 2)
                        if r and not l
                            if @info.turnpolicy == "right" or (@info.turnpolicy == "black" and path.sign == '+') or (@info.turnpolicy == "white" and path.sign == '-') or (@info.turnpolicy == "majority" and majority(x, y)) or (@info.turnpolicy == "minority" and not majority(x, y))
                                tmp = dirx
                                dirx = -diry
                                diry = tmp
                            else
                                tmp = dirx
                                dirx = diry
                                diry = -tmp
                        elseif r
                            tmp = dirx
                            dirx = -diry
                            diry = tmp
                        elseif not l
                            tmp = dirx
                            dirx = diry
                            diry = -tmp
                    return path

                xorPath = (path) ->
                    y1, len = path.pt[0].y, path.len
                    for i = 1, len - 1
                        x = path.pt[i].x
                        y = path.pt[i].y
                        if y != y1
                            minY = y1 < y and y1 or y
                            maxX = path.maxX
                            for j = x, maxX - 1
                                bm1\flip(j, minY)
                            y1 = y
                while currentPoint
                    path = findPath(currentPoint)
                    xorPath(path)
                    if path.area > @info.turdsize
                        push_b0(@pathlist, path)
                    currentPoint = findNext(currentPoint)

            processPath: =>
                class Quad

                    new: =>
                        @data = {[0]: 0, 0, 0, 0, 0, 0, 0, 0, 0}

                    at: (x, y) => @data[x * 3 + y]

                mod = (a, n) -> a >= n and a % n or a >= 0 and a or n - 1 - (-1 - a) % n
                xprod = (p1, p2) -> p1.x * p2.y - p1.y * p2.x
                sign = (i) -> i > 0 and 1 or i < 0 and -1 or 0
                ddist = (p, q) -> sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y))

                cyclic = (a, b, c) ->
                    if a <= c
                        return a <= b and b < c
                    else
                        return a <= b or b < c

                quadform = (Q, w) ->
                    sum, v = 0, {[0]: w.x, [1]: w.y, [2]: 1}
                    for i = 0, 2
                        for j = 0, 2
                            sum += v[i] * Q\at(i, j) * v[j]
                    return sum

                interval = (lambda, a, b) ->
                    res = Point!
                    res.x = a.x + lambda * (b.x - a.x)
                    res.y = a.y + lambda * (b.y - a.y)
                    return res

                dorth_infty = (p0, p2) ->
                    r = Point!
                    r.y = sign(p2.x - p0.x)
                    r.x = -sign(p2.y - p0.y)
                    return r

                ddenom = (p0, p2) ->
                    r = dorth_infty(p0, p2)
                    return r.y * (p2.x - p0.x) - r.x * (p2.y - p0.y)

                dpara = (p0, p1, p2) ->
                    x1 = p1.x - p0.x
                    y1 = p1.y - p0.y
                    x2 = p2.x - p0.x
                    y2 = p2.y - p0.y
                    return x1 * y2 - x2 * y1

                cprod = (p0, p1, p2, p3) ->
                    x1 = p1.x - p0.x
                    y1 = p1.y - p0.y
                    x2 = p3.x - p2.x
                    y2 = p3.y - p2.y
                    return x1 * y2 - x2 * y1

                iprod = (p0, p1, p2) ->
                    x1 = p1.x - p0.x
                    y1 = p1.y - p0.y
                    x2 = p2.x - p0.x
                    y2 = p2.y - p0.y
                    return x1 * x2 + y1 * y2

                iprod1 = (p0, p1, p2, p3) ->
                    x1 = p1.x - p0.x
                    y1 = p1.y - p0.y
                    x2 = p3.x - p2.x
                    y2 = p3.y - p2.y
                    return x1 * x2 + y1 * y2

                bezier = (t, p0, p1, p2, p3) ->
                    s, res = 1 - t, Point!
                    res.x = s * s * s * p0.x + 3 * (s * s * t) * p1.x + 3 * (t * t * s) * p2.x + t * t * t * p3.x
                    res.y = s * s * s * p0.y + 3 * (s * s * t) * p1.y + 3 * (t * t * s) * p2.y + t * t * t * p3.y
                    return res

                tangent = (p0, p1, p2, p3, q0, q1) ->
                    A = cprod(p0, p1, q0, q1)
                    B = cprod(p1, p2, q0, q1)
                    C = cprod(p2, p3, q0, q1)
                    a = A - 2 * B + C
                    b = -2 * A + 2 * B
                    c = A
                    d = b * b - 4 * a * c
                    return -1 if a == 0 or d < 0
                    s = sqrt(d)
                    r1 = (-b + s) / (2 * a)
                    r2 = (-b - s) / (2 * a)
                    if r1 >= 0 and r1 <= 1
                        return r1
                    elseif r2 >= 0 and r2 <= 1
                        return r2
                    else
                        return -1

                calcSums = (path) ->
                    path.x0 = path.pt[0].x
                    path.y0 = path.pt[0].y
                    path.sums = {}
                    s = path.sums
                    push_b0(s, Sum(0, 0, 0, 0, 0))
                    for i = 0, path.len - 1
                        x = path.pt[i].x - path.x0
                        y = path.pt[i].y - path.y0
                        push_b0(s, Sum(s[i].x + x, s[i].y + y, s[i].xy + x * y, s[i].x2 + x * x, s[i].y2 + y * y))

                calcLon = (path) ->
                    n, pt, pivk, nc, ct, path.lon, foundk = path.len, path.pt, {}, {}, {}, {}
                    constraint = {[0]: Point!, Point!}
                    cur, off, dk, k = Point!, Point!, Point!, 0
                    for i = n - 1, 0, -1
                        if pt[i].x != pt[k].x and pt[i].y != pt[k].y
                            k = i + 1
                        nc[i] = k
                    for i = n - 1, 0, -1
                        ct[0], ct[1], ct[2], ct[3] = 0, 0, 0, 0
                        dir = (3 + 3 * (pt[mod(i + 1, n)].x - pt[i].x) + (pt[mod(i + 1, n)].y - pt[i].y)) / 2
                        ct[dir] += 1
                        constraint[0].x = 0
                        constraint[0].y = 0
                        constraint[1].x = 0
                        constraint[1].y = 0
                        k, k1 = nc[i], i
                        while true
                            foundk = 0
                            dir = (3 + 3 * sign(pt[k].x - pt[k1].x) + sign(pt[k].y - pt[k1].y)) / 2
                            ct[dir] += 1
                            if ct[0] != 0 and ct[1] != 0 and ct[2] != 0 and ct[3] != 0
                                pivk[i] = k1
                                foundk = 1
                                break
                            cur.x = pt[k].x - pt[i].x
                            cur.y = pt[k].y - pt[i].y
                            if xprod(constraint[0], cur) < 0 or xprod(constraint[1], cur) > 0
                                break
                            if abs(cur.x) <= 1 and abs(cur.y) <= 1
                                _ = _ -- ??
                            else
                                off.x = cur.x + ((cur.y >= 0 and (cur.y > 0 or cur.x < 0)) and 1 or -1)
                                off.y = cur.y + ((cur.x <= 0 and (cur.x < 0 or cur.y < 0)) and 1 or -1)
                                if xprod(constraint[0], off) >= 0
                                    constraint[0].x = off.x
                                    constraint[0].y = off.y
                                off.x = cur.x + ((cur.y <= 0 and (cur.y < 0 or cur.x < 0)) and 1 or -1)
                                off.y = cur.y + ((cur.x >= 0 and (cur.x > 0 or cur.y < 0)) and 1 or -1)
                                if xprod(constraint[1], off) <= 0
                                    constraint[1].x = off.x
                                    constraint[1].y = off.y
                            k1 = k
                            k = nc[k1]
                            break if not cyclic(k, i, k1)
                        if foundk == 0
                            dk.x = sign(pt[k].x - pt[k1].x)
                            dk.y = sign(pt[k].y - pt[k1].y)
                            cur.x = pt[k1].x - pt[i].x
                            cur.y = pt[k1].y - pt[i].y
                            a = xprod(constraint[0], cur)
                            b = xprod(constraint[0], dk)
                            c = xprod(constraint[1], cur)
                            d = xprod(constraint[1], dk)
                            j = 10000000
                            if b < 0
                                j = floor(a / -b)
                            if d > 0
                                j = min(j, floor(-c / d))
                            pivk[i] = mod(k1 + j, n)
                    j = pivk[n - 1]
                    path.lon[n - 1] = j
                    for i = n - 2, 0, -1
                        if cyclic(i + 1, pivk[i], j)
                            j = pivk[i]
                        path.lon[i] = j
                    i = n - 1
                    while cyclic(mod(i + 1, n), j, path.lon[i])
                        path.lon[i] = j
                        i -= 1

                bestPolygon = (path) ->
                    penalty3 = (path, i, j) ->
                        local x, y, xy, x2, y2, k
                        n, pt, sums, r = path.len, path.pt, path.sums, 0
                        if j >= n
                            j -= n
                            r = 1
                        if r == 0
                            x = sums[j + 1].x - sums[i].x
                            y = sums[j + 1].y - sums[i].y
                            x2 = sums[j + 1].x2 - sums[i].x2
                            xy = sums[j + 1].xy - sums[i].xy
                            y2 = sums[j + 1].y2 - sums[i].y2
                            k = j + 1 - i
                        else
                            x = sums[j + 1].x - sums[i].x + sums[n].x
                            y = sums[j + 1].y - sums[i].y + sums[n].y
                            x2 = sums[j + 1].x2 - sums[i].x2 + sums[n].x2
                            xy = sums[j + 1].xy - sums[i].xy + sums[n].xy
                            y2 = sums[j + 1].y2 - sums[i].y2 + sums[n].y2
                            k = j + 1 - i + n
                        px = (pt[i].x + pt[j].x) / 2 - pt[0].x
                        py = (pt[i].y + pt[j].y) / 2 - pt[0].y
                        ey = (pt[j].x - pt[i].x)
                        ex = -(pt[j].y - pt[i].y)
                        a = ((x2 - 2 * x * px) / k + px * px)
                        b = ((xy - x * py - y * px) / k + px * py)
                        c = ((y2 - 2 * y * py) / k + py * py)
                        s = ex * ex * a + 2 * ex * ey * b + ey * ey * c
                        return sqrt(s)
                    n = path.len
                    pen, prev, clip0, clip1, seg0, seg1 = {}, {}, {}, {}, {}, {}
                    for i = 0, n - 1
                        c = mod(path.lon[mod(i - 1, n)] - 1, n)
                        if c == i
                            c = mod(i + 1, n)
                        if c < i
                            clip0[i] = n
                        else
                            clip0[i] = c
                    j = 1
                    for i = 0, n - 1
                        while j <= clip0[i]
                            clip1[j] = i
                            j += 1
                    i, j = 0, 0
                    while i < n
                        seg0[j] = i
                        i = clip0[i]
                        j += 1
                    seg0[j] = n
                    m = j
                    i, j = n, m
                    while j > 0
                        seg1[j] = i
                        i = clip1[i]
                        j -= 1
                    seg1[0], pen[0], j = 0, 0, 1
                    while j <= m
                        for i = seg1[j], seg0[j]
                            best = -1
                            for k = seg0[j - 1], clip1[i], -1
                                thispen = penalty3(path, k, i) + pen[k]
                                if best < 0 or thispen < best
                                    prev[i] = k
                                    best = thispen
                            pen[i] = best
                        j += 1
                    path.m, path.po = m, {}
                    i, j = n, m - 1
                    while i > 0
                        i = prev[i]
                        path.po[j] = i
                        j -= 1

                adjustVertices = (path) ->
                    pointslope = (path, i, j, ctr, dir) ->
                        n, sums, r = path.len, path.sums, 0
                        while j >= n
                            j -= n
                            r += 1
                        while i >= n
                            i -= n
                            r -= 1
                        while j < 0
                            j += n
                            r -= 1
                        while i < 0
                            i += n
                            r += 1
                        x = sums[j + 1].x - sums[i].x + r * sums[n].x
                        y = sums[j + 1].y - sums[i].y + r * sums[n].y
                        x2 = sums[j + 1].x2 - sums[i].x2 + r * sums[n].x2
                        xy = sums[j + 1].xy - sums[i].xy + r * sums[n].xy
                        y2 = sums[j + 1].y2 - sums[i].y2 + r * sums[n].y2
                        k = j + 1 - i + r * n
                        ctr.x = x / k
                        ctr.y = y / k
                        a = (x2 - x * x / k) / k
                        b = (xy - x * y / k) / k
                        c = (y2 - y * y / k) / k
                        lambda2 = (a + c + sqrt((a - c) * (a - c) + 4 * b * b)) / 2
                        a -= lambda2
                        c -= lambda2
                        if abs(a) >= abs(c)
                            l = sqrt(a * a + b * b)
                            if l != 0
                                dir.x = -b / l
                                dir.y = a / l
                        else
                            l = sqrt(c * c + b * b)
                            if l != 0
                                dir.x = -c / l
                                dir.y = b / l
                        if l == 0
                            dir.x = 0
                            dir.y = 0
                    m, po, n, pt, x0, y0 = path.m, path.po, path.len, path.pt, path.x0, path.y0
                    q, v, s, ctr, dir = {}, {}, Point!, {}, {}
                    path.curve = Curve(m)
                    for i = 0, m - 1
                        j = po[mod(i + 1, m)]
                        j = mod(j - po[i], n) + po[i]
                        ctr[i] = Point!
                        dir[i] = Point!
                        pointslope(path, po[i], j, ctr[i], dir[i])
                    for i = 0, m - 1
                        q[i] = Quad!
                        d = dir[i].x * dir[i].x + dir[i].y * dir[i].y
                        if d == 0
                            for j = 0, 2
                                for k = 0, 2
                                    q[i].data[j * 3 + k] = 0
                        else
                            v[0] = dir[i].y
                            v[1] = -dir[i].x
                            v[2] = -v[1] * ctr[i].y - v[0] * ctr[i].x
                            for l = 0, 2
                                for k = 0, 2
                                    q[i].data[l * 3 + k] = v[l] * v[k] / d
                    for i = 0, m - 1
                        Q = Quad!
                        w = Point!
                        s.x = pt[po[i]].x - x0
                        s.y = pt[po[i]].y - y0
                        j = mod(i - 1, m)
                        for l = 0, 2
                            for k = 0, 2
                                Q.data[l * 3 + k] = q[j]\at(l, k) + q[i]\at(l, k)
                        while true
                            det = Q\at(0, 0) * Q\at(1, 1) - Q\at(0, 1) * Q\at(1, 0)
                            if det != 0
                                w.x = (-Q\at(0, 2) * Q\at(1, 1) + Q\at(1, 2) * Q\at(0, 1)) / det
                                w.y = (Q\at(0, 2) * Q\at(1, 0) - Q\at(1, 2) * Q\at(0, 0)) / det
                                break
                            if Q\at(0, 0) > Q\at(1, 1)
                                v[0] = -Q\at(0, 1)
                                v[1] = Q\at(0, 0)
                            elseif (Q\at(1, 1)) != 0
                                v[0] = -Q\at(1, 1)
                                v[1] = Q\at(1, 0)
                            else
                                v[0] = 1
                                v[1] = 0
                            d = v[0] * v[0] + v[1] * v[1]
                            v[2] = -v[1] * s.y - v[0] * s.x
                            for l = 0, 2
                                for k = 0, 2
                                    Q.data[l * 3 + k] += v[l] * v[k] / d
                        dx = abs(w.x - s.x)
                        dy = abs(w.y - s.y)
                        if dx <= 0.5 and dy <= 0.5
                            path.curve.vertex[i] = Point(w.x + x0, w.y + y0)
                            continue
                        min, xmin, ymin = quadform(Q, s), s.x, s.y
                        if Q\at(0, 0) != 0
                            for z = 0, 1
                                w.y = s.y - 0.5 + z
                                w.x = -(Q\at(0, 1) * w.y + Q\at(0, 2)) / Q\at(0, 0)
                                dx = abs(w.x - s.x)
                                cand = quadform(Q, w)
                                if dx <= 0.5 and cand < min
                                    min, xmin, ymin = cand, w.x, w.y
                        if Q\at(1, 1) != 0
                            for z = 0, 1
                                w.x = s.x - 0.5 + z
                                w.y = -(Q\at(1, 0) * w.x + Q\at(1, 2)) / Q\at(1, 1)
                                dy = abs(w.y - s.y)
                                cand = quadform(Q, w)
                                if dy <= 0.5 and cand < min
                                    min, xmin, ymin = cand, w.x, w.y
                        for l = 0, 2
                            for k = 0, 2
                                w.x = s.x - 0.5 + l
                                w.y = s.y - 0.5 + k
                                cand = quadform(Q, w)
                                if cand < min
                                    min, xmin, ymin = cand, w.x, w.y
                        path.curve.vertex[i] = Point(xmin + x0, ymin + y0)

                reverse = (path) ->
                    curve = path.curve
                    m, v = curve.n, curve.vertex
                    i, j = 0, m - 1
                    while i < j
                        tmp = v[i]
                        v[i] = v[j]
                        v[j] = tmp
                        i += 1
                        j -= 1

                smooth = (path) ->
                    m, curve, alpha = path.curve.n, path.curve
                    for i = 0, m - 1
                        j = mod(i + 1, m)
                        k = mod(i + 2, m)
                        p4 = interval(1 / 2, curve.vertex[k], curve.vertex[j])
                        denom = ddenom(curve.vertex[i], curve.vertex[k])
                        if denom != 0
                            dd = dpara(curve.vertex[i], curve.vertex[j], curve.vertex[k]) / denom
                            dd = abs(dd)
                            alpha = dd > 1 and (1 - 1 / dd) or 0
                            alpha /= 0.75
                        else
                            alpha = 4 / 3
                        curve.alpha0[j] = alpha
                        if alpha >= @info.alphamax
                            curve.tag[j] = "CORNER"
                            curve.c[3 * j + 1] = curve.vertex[j]
                            curve.c[3 * j + 2] = p4
                        else
                            if alpha < 0.55
                                alpha = 0.55
                            elseif alpha > 1
                                alpha = 1
                            p2 = interval(0.5 + 0.5 * alpha, curve.vertex[i], curve.vertex[j])
                            p3 = interval(0.5 + 0.5 * alpha, curve.vertex[k], curve.vertex[j])
                            curve.tag[j] = "CURVE"
                            curve.c[3 * j + 0] = p2
                            curve.c[3 * j + 1] = p3
                            curve.c[3 * j + 2] = p4
                        curve.alpha[j] = alpha
                        curve.beta[j] = 0.5
                    curve.alphacurve = 1

                optiCurve = (path) ->
                    class Opti

                        new: =>
                            @pen = 0
                            @c = {[0]: Point!, Point!}
                            @t = 0
                            @s = 0
                            @alpha = 0

                    opti_penalty = (path, i, j, res, opttolerance, convc, areac) ->
                        m = path.curve.n
                        curve = path.curve
                        vertex = curve.vertex
                        return 1 if i == j
                        k = i
                        i1 = mod(i + 1, m)
                        k1 = mod(k + 1, m)
                        conv = convc[k1]
                        return 1 if conv == 0
                        d = ddist(vertex[i], vertex[i1])
                        k = k1
                        while k != j
                            k1 = mod(k + 1, m)
                            k2 = mod(k + 2, m)
                            return 1 if convc[k1] != conv
                            return 1 if sign(cprod(vertex[i], vertex[i1], vertex[k1], vertex[k2])) != conv
                            return 1 if iprod1(vertex[i], vertex[i1], vertex[k1], vertex[k2]) < d * ddist(vertex[k1], vertex[k2]) * -0.999847695156
                            k = k1
                        p0 = curve.c[mod(i, m) * 3 + 2]\copy!
                        p1 = vertex[mod(i + 1, m)]\copy!
                        p2 = vertex[mod(j, m)]\copy!
                        p3 = curve.c[mod(j, m) * 3 + 2]\copy!
                        area = areac[j] - areac[i]
                        area -= dpara(vertex[0], curve.c[i * 3 + 2], curve.c[j * 3 + 2]) / 2
                        area += areac[m] if i >= j
                        A1 = dpara(p0, p1, p2)
                        A2 = dpara(p0, p1, p3)
                        A3 = dpara(p0, p2, p3)
                        A4 = A1 + A3 - A2
                        return 1 if A2 == A1
                        t = A3 / (A3 - A4)
                        s = A2 / (A2 - A1)
                        A = A2 * t / 2
                        return 1 if A == 0
                        R = area / A
                        alpha = 2 - sqrt(4 - R / 0.3)
                        res.c[0] = interval(t * alpha, p0, p1)
                        res.c[1] = interval(s * alpha, p3, p2)
                        res.alpha = alpha
                        res.t = t
                        res.s = s
                        p1 = res.c[0]\copy!
                        p2 = res.c[1]\copy!
                        res.pen = 0
                        k = mod(i + 1, m)
                        while k != j
                            k1 = mod(k + 1, m)
                            t = tangent(p0, p1, p2, p3, vertex[k], vertex[k1])
                            return 1 if t < -0.5
                            pt = bezier(t, p0, p1, p2, p3)
                            d = ddist(vertex[k], vertex[k1])
                            return 1 if d == 0
                            d1 = dpara(vertex[k], vertex[k1], pt) / d
                            return 1 if abs(d1) > opttolerance
                            return 1 if iprod(vertex[k], vertex[k1], pt) < 0 or iprod(vertex[k1], vertex[k], pt) < 0
                            res.pen += d1 * d1
                            k = k1
                        k = i
                        while k != j
                            k1 = mod(k + 1, m)
                            t = tangent(p0, p1, p2, p3, curve.c[k * 3 + 2], curve.c[k1 * 3 + 2])
                            return 1 if t < -0.5
                            pt = bezier(t, p0, p1, p2, p3)
                            d = ddist(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2])
                            return 1 if d == 0
                            d1 = dpara(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2], pt) / d
                            d2 = dpara(curve.c[k * 3 + 2], curve.c[k1 * 3 + 2], vertex[k1]) / d
                            d2 *= 0.75 * curve.alpha[k1]
                            if d2 < 0
                                d1 = -d1
                                d2 = -d2
                            return 1 if d1 < d2 - opttolerance
                            if d1 < d2
                                res.pen += (d1 - d2) * (d1 - d2)
                            k = k1
                        return 0
                    curve = path.curve
                    m, vert, pt, pen, len, opt, convc, areac, o = curve.n, curve.vertex, {}, {}, {}, {}, {}, {}, Opti!
                    for i = 0, m - 1
                        if curve.tag[i] == "CURVE"
                            convc[i] = sign(dpara(vert[mod(i - 1, m)], vert[i], vert[mod(i + 1, m)]))
                        else
                            convc[i] = 0
                    area, areac[0] = 0, 0
                    p0 = curve.vertex[0]
                    for i = 0, m - 1
                        i1 = mod(i + 1, m)
                        if curve.tag[i1] == "CURVE"
                            alpha = curve.alpha[i1]
                            area += 0.3 * alpha * (4 - alpha) * dpara(curve.c[i * 3 + 2], vert[i1], curve.c[i1 * 3 + 2]) / 2
                            area += dpara(p0, curve.c[i * 3 + 2], curve.c[i1 * 3 + 2]) / 2
                        areac[i + 1] = area
                    pt[0], pen[0], len[0] = -1, 0, 0
                    for j = 1, m
                        pt[j] = j - 1
                        pen[j] = pen[j - 1]
                        len[j] = len[j - 1] + 1
                        for i = j - 2, 0, -1
                            r = opti_penalty(path, i, mod(j, m), o, @info.opttolerance, convc, areac)
                            break if r == 1
                            if len[j] > len[i] + 1 or (len[j] == len[i] + 1 and pen[j] > pen[i] + o.pen)
                                pt[j] = i
                                pen[j] = pen[i] + o.pen
                                len[j] = len[i] + 1
                                opt[j] = o
                                o = Opti!
                    om = len[m]
                    ocurve = Curve(om)
                    s, t, j = {}, {}, m
                    for i = om - 1, 0, -1
                        if pt[j] == j - 1
                            ocurve.tag[i] = curve.tag[mod(j, m)]
                            ocurve.c[i * 3 + 0] = curve.c[mod(j, m) * 3 + 0]
                            ocurve.c[i * 3 + 1] = curve.c[mod(j, m) * 3 + 1]
                            ocurve.c[i * 3 + 2] = curve.c[mod(j, m) * 3 + 2]
                            ocurve.vertex[i] = curve.vertex[mod(j, m)]
                            ocurve.alpha[i] = curve.alpha[mod(j, m)]
                            ocurve.alpha0[i] = curve.alpha0[mod(j, m)]
                            ocurve.beta[i] = curve.beta[mod(j, m)]
                            s[i] = 1
                            t[i] = 1
                        else
                            ocurve.tag[i] = "CURVE"
                            ocurve.c[i * 3 + 0] = opt[j].c[0]
                            ocurve.c[i * 3 + 1] = opt[j].c[1]
                            ocurve.c[i * 3 + 2] = curve.c[mod(j, m) * 3 + 2]
                            ocurve.vertex[i] = interval(opt[j].s, curve.c[mod(j, m) * 3 + 2], vert[mod(j, m)])
                            ocurve.alpha[i] = opt[j].alpha
                            ocurve.alpha0[i] = opt[j].alpha
                            s[i] = opt[j].s
                            t[i] = opt[j].t
                        j = pt[j]
                    for i = 0, om - 1
                        i1 = mod(i + 1, om)
                        ocurve.beta[i] = s[i] / (s[i] + t[i1])
                    ocurve.alphacurve = 1
                    path.curve = ocurve
                for i = 0, #@pathlist
                    path = @pathlist[i]
                    calcSums(path)
                    calcLon(path)
                    bestPolygon(path)
                    adjustVertices(path)
                    reverse(path) if path.sign == "-"
                    smooth(path)
                    optiCurve(path) if @info.optcurve

            get_shape: =>
                path = (curve) ->
                    bezier = (i) ->
                        x1, y1 = MATH\round(curve.c[i * 3 + 0].x), MATH\round(curve.c[i * 3 + 0].y)
                        x2, y2 = MATH\round(curve.c[i * 3 + 1].x), MATH\round(curve.c[i * 3 + 1].y)
                        x3, y3 = MATH\round(curve.c[i * 3 + 2].x), MATH\round(curve.c[i * 3 + 2].y)
                        return "b #{x1} #{y1} #{x2} #{y2} #{x3} #{y3} "
                    segment = (i) ->
                        x1, y1 = MATH\round(curve.c[i * 3 + 1].x), MATH\round(curve.c[i * 3 + 1].y)
                        return "l #{x1} #{y1} "
                    n = curve.n
                    x1, y1 = MATH\round(curve.c[(n - 1) * 3 + 2].x), MATH\round(curve.c[(n - 1) * 3 + 2].y)
                    build = "m #{x1} #{y1} "
                    for i = 0, n - 1
                        if curve.tag[i] == "CURVE"
                            build ..= bezier(i)
                        elseif curve.tag[i] == "CORNER"
                            build ..= segment(i)
                    return SHAPE(build)\build!
                shape = ""
                for i = 0, #@pathlist
                    c = @pathlist[i].curve
                    shape ..= path(c)
                return shape
        return Potrace(@filename, ...)

{:IMAGE}