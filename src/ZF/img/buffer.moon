ffi = require "ffi"
bit = require "bit"

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
    get_color_8A: (self) -> color_8A self.a, 0
    get_color_16: (self) ->
        v = self\get_color_8!.a
        v5bit = bit.rshift v, 3
        return color_16 bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit
    get_color_24: (self) ->
        v = self\get_color_8!
        return color_24 v.a, v.a, v.a
    get_color_32: (self) -> color_32 self.a, self.a, self.a, 0xFF
    get_r:        (self) -> self\get_color_8!.a
    get_g:        (self) -> self\get_color_8!.a
    get_b:        (self) -> self\get_color_8!.a
    get_a:        (self) -> int_t 0xFF
}

COLOR_8A = {
    get_color_8: (self) -> color_8 self.a
    get_color_8A: (self) -> self
    get_color_16: COLOR_8.get_color_16
    get_color_24: COLOR_8.get_color_24
    get_color_32: (self) -> color_32 self.a, self.a, self.a, self.alpha
    get_r:        COLOR_8.get_r
    get_g:        COLOR_8.get_r
    get_b:        COLOR_8.get_r
    get_a:        (self) -> self.alpha
}

COLOR_16 = {
    get_color_8: (self) ->
        r = bit.rshift self.v, 11
        g = bit.rshift bit.rshift(self.v, 5), 0x3F
        b = bit.rshift self.v, 0x001F
        return color_8 bit.rshift(39190 * r + 38469 * g + 14942 * b, 14)
    get_color_8A: (self) ->
        r = bit.rshift self.v, 11
        g = bit.rshift bit.rshift(self.v, 5), 0x3F
        b = bit.rshift self.v, 0x001F
        return color_8A bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0
    get_color_16: (self) -> self
    get_color_24: (self) ->
        r = bit.rshift self.v, 11
        g = bit.rshift bit.rshift(self.v, 5), 0x3F
        b = bit.rshift self.v, 0x001F
        return color_24 bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2)
    get_color_32: (self) ->
        r = bit.rshift self.v, 11
        g = bit.rshift bit.rshift(self.v, 5), 0x3F
        b = bit.rshift self.v, 0x001F
        return color_32 bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF
    get_r: (self) ->
        r = bit.rshift self.v, 11
        return bit.lshift(r, 3) + bit.rshift(r, 2)
    get_g: (self) ->
        g = bit.rshift bit.rshift(self.v, 5), 0x3F
        return bit.lshift(g, 2) + bit.rshift(g, 4)
    get_b: (self) ->
        b = bit.rshift self.v, 0x001F
        return bit.lshift(b, 3) + bit.rshift(b, 2)
    get_a: COLOR_8.get_a
}

COLOR_24 = {
    get_color_8:  (self) -> color_8 bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14)
    get_color_8A: (self) -> color_8A bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), 0
    get_color_16: (self) -> color_16 bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3)
    get_color_24: (self) -> self
    get_color_32: (self) -> color_32 self.r, self.g, self.b, 0xFF
    get_r:        (self) -> self.r
    get_g:        (self) -> self.g
    get_b:        (self) -> self.b
    get_a:        COLOR_8.get_a
}

COLOR_32 = {
    get_color_8:  COLOR_24.get_color_8
    get_color_8A: (self) -> color_8A bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), self\get_a!
    get_color_16: COLOR_24.get_color_16
    get_color_24: (self) -> color_24 self.r, self.g, self.b
    get_color_32: (self) -> self
    get_r:        COLOR_24.get_r
    get_g:        COLOR_24.get_g
    get_b:        COLOR_24.get_b
    get_a:        (self) -> self.alpha
}

BBF = {
    get_rotation:  (self) -> bit.rshift bit.band(0x0C, self.config), 2
    get_inverse:   (self) -> bit.rshift bit.band(0x02, self.config), 1
    set_allocated: (self, allocated) -> self.config = bit.bor bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0)
    set_type:      (self, type_id) -> self.config = bit.bor bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4)
    get_physical_coordinates: (self, x, y) ->
        return switch self\get_rotation!
            when 0 then x, y
            when 1 then self.w - y - 1, x
            when 2 then self.w - x - 1, self.h - y - 1
            when 3 then y, self.h - x - 1
    get_pixel_p: (self, x, y) -> ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x
    get_pixel:   (self, x, y) ->
        px, py = self\get_physical_coordinates x, y
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

-- https://github.com/koreader/koreader-base/tree/master/ffi
BUFFER = (width, height, bufferType = 1, data, pitch) ->
    unless pitch
        pitch = switch bufferType
            when 1 then width
            when 2 then bit.lshift(width, 1)
            when 3 then bit.lshift(width, 1)
            when 4 then width * 3
            when 5 then bit.lshift(width, 2)
    bb = switch bufferType
        when 1 then BUFFER8(width, height, pitch, nil, 0)
        when 2 then BUFFER8A(width, height, pitch, nil, 0)
        when 3 then BUFFER16(width, height, pitch, nil, 0)
        when 4 then BUFFER24(width, height, pitch, nil, 0)
        when 5 then BUFFER32(width, height, pitch, nil, 0)
        else error "Unknown blitbuffer type"
    bb\set_type bufferType
    unless data
        data = ffi.C.malloc pitch * height
        assert data, "Cannot allocate memory for blitbuffer"
        ffi.fill data, pitch * height
        bb\set_allocated 1
    bb.data = ffi.cast bb.data, data
    return bb

{:BUFFER}