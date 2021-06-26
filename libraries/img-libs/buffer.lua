local ffi = require "ffi"
local bit = require "bit"

ffi.cdef [[
    typedef struct Color8 {
        uint8_t a;
    } Color8;
    typedef struct Color8A {
        uint8_t a;
        uint8_t alpha;
    } Color8A;
    typedef struct ColorRGB16 {
        uint16_t v;
    } ColorRGB16;
    typedef struct ColorRGB24 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
    } ColorRGB24;
    typedef struct ColorRGB32 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t alpha;
    } ColorRGB32;
    typedef struct BlitBuffer {
        int w;
        int h;
        int pitch;
        uint8_t *data;
        uint8_t config;
    } BlitBuffer;
    typedef struct BlitBuffer8 {
        int w;
        int h;
        int pitch;
        Color8 *data;
        uint8_t config;
    } BlitBuffer8;
    typedef struct BlitBuffer8A {
        int w;
        int h;
        int pitch;
        Color8A *data;
        uint8_t config;
    } BlitBuffer8A;
    typedef struct BlitBufferRGB16 {
        int w;
        int h;
        int pitch;
        ColorRGB16 *data;
        uint8_t config;
    } BlitBufferRGB16;
    typedef struct BlitBufferRGB24 {
        int w;
        int h;
        int pitch;
        ColorRGB24 *data;
        uint8_t config;
    } BlitBufferRGB24;
    typedef struct BlitBufferRGB32 {
        int w;
        int h;
        int pitch;
        ColorRGB32 *data;
        uint8_t config;
    } BlitBufferRGB32;
    void *malloc(int size);
    void free(void *ptr);
]]

local Color8     = ffi.typeof("Color8")
local Color8A    = ffi.typeof("Color8A")
local ColorRGB16 = ffi.typeof("ColorRGB16")
local ColorRGB24 = ffi.typeof("ColorRGB24")
local ColorRGB32 = ffi.typeof("ColorRGB32")
local intt       = ffi.typeof("int")
local uint8pt    = ffi.typeof("uint8_t*")

local Color8_mt     = {__index = {}}
local Color8A_mt    = {__index = {}}
local ColorRGB16_mt = {__index = {}}
local ColorRGB24_mt = {__index = {}}
local ColorRGB32_mt = {__index = {}}

function Color8_mt.__index:getColor8()
    return self
end

function Color8A_mt.__index:getColor8()
    return Color8(self.a)
end

function ColorRGB16_mt.__index:getColor8()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return Color8(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14))
end

function ColorRGB24_mt.__index:getColor8()
    return Color8(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14))
end

ColorRGB32_mt.__index.getColor8 = ColorRGB24_mt.__index.getColor8

function Color8_mt.__index:getColor8A()
    return Color8A(self.a, 0)
end

function Color8A_mt.__index:getColor8A()
    return self
end

function ColorRGB16_mt.__index:getColor8A()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return Color8A(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0)
end

function ColorRGB24_mt.__index:getColor8A()
    return Color8A(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14), 0)
end

function ColorRGB32_mt.__index:getColor8A()
    return Color8A(bit.rshift(4897 * self:getR() + 9617 * self:getG() + 1868 * self:getB(), 14), self:getAlpha())
end

function Color8_mt.__index:getColorRGB16()
    local v = self:getColor8().a
    local v5bit = bit.rshift(v, 3)
    return ColorRGB16(bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit)
end

Color8A_mt.__index.getColorRGB16 = Color8_mt.__index.getColorRGB16

function ColorRGB16_mt.__index:getColorRGB16()
    return self
end

function ColorRGB24_mt.__index:getColorRGB16()
    return ColorRGB16(bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3))
end

ColorRGB32_mt.__index.getColorRGB16 = ColorRGB24_mt.__index.getColorRGB16

function Color8_mt.__index:getColorRGB24()
    local v = self:getColor8()
    return ColorRGB24(v.a, v.a, v.a)
end

Color8A_mt.__index.getColorRGB24 = Color8_mt.__index.getColorRGB24

function ColorRGB16_mt.__index:getColorRGB24()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return ColorRGB24(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2))
end

function ColorRGB24_mt.__index:getColorRGB24()
    return self
end

function ColorRGB32_mt.__index:getColorRGB24()
    return ColorRGB24(self.r, self.g, self.b)
end

function Color8_mt.__index:getColorRGB32()
    return ColorRGB32(self.a, self.a, self.a, 0xFF)
end

function Color8A_mt.__index:getColorRGB32()
    return ColorRGB32(self.a, self.a, self.a, self.alpha)
end

function ColorRGB16_mt.__index:getColorRGB32()
    local r = bit.rshift(self.v, 11)
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    local b = bit.rshift(self.v, 0x001F)
    return ColorRGB32(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF)
end

function ColorRGB24_mt.__index:getColorRGB32()
    return ColorRGB32(self.r, self.g, self.b, 0xFF)
end

function ColorRGB32_mt.__index:getColorRGB32()
    return self
end

function Color8_mt.__index:getR()
    return self:getColor8().a
end

Color8_mt.__index.getG = Color8_mt.__index.getR
Color8_mt.__index.getB = Color8_mt.__index.getR

function Color8_mt.__index:getAlpha()
    return intt(0xFF)
end

Color8A_mt.__index.getR = Color8_mt.__index.getR
Color8A_mt.__index.getG = Color8_mt.__index.getR
Color8A_mt.__index.getB = Color8_mt.__index.getR

function Color8A_mt.__index:getAlpha()
    return self.alpha
end

function ColorRGB16_mt.__index:getR()
    local r = bit.rshift(self.v, 11)
    return bit.lshift(r, 3) + bit.rshift(r, 2)
end

function ColorRGB16_mt.__index:getG()
    local g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    return bit.lshift(g, 2) + bit.rshift(g, 4)
end

function ColorRGB16_mt.__index:getB()
    local b = bit.rshift(self.v, 0x001F)
    return bit.lshift(b, 3) + bit.rshift(b, 2)
end

ColorRGB16_mt.__index.getAlpha = Color8_mt.__index.getAlpha

function ColorRGB24_mt.__index:getR()
    return self.r
end

function ColorRGB24_mt.__index:getG()
    return self.g
end

function ColorRGB24_mt.__index:getB()
    return self.b
end

ColorRGB24_mt.__index.getAlpha = Color8_mt.__index.getAlpha
ColorRGB32_mt.__index.getR     = ColorRGB24_mt.__index.getR
ColorRGB32_mt.__index.getG     = ColorRGB24_mt.__index.getG
ColorRGB32_mt.__index.getB     = ColorRGB24_mt.__index.getB

function ColorRGB32_mt.__index:getAlpha()
    return self.alpha
end

local BB8_mt     = {__index = {}}
local BB8A_mt    = {__index = {}}
local BBRGB16_mt = {__index = {}}
local BBRGB24_mt = {__index = {}}
local BBRGB32_mt = {__index = {}}
local BB_mt      = {__index = {}}

function BB_mt.__index:getRotation()
    return bit.rshift(bit.band(0x0C, self.config), 2)
end

function BB_mt.__index:getInverse()
    return bit.rshift(bit.band(0x02, self.config), 1)
end

function BB_mt.__index:setAllocated(allocated)
    self.config = bit.bor(bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0))
end

function BB8_mt.__index:getBpp()
    return 8
end

function BB8A_mt.__index:getBpp()
    return 8
end

function BBRGB16_mt.__index:getBpp()
    return 16
end

function BBRGB24_mt.__index:getBpp()
    return 24
end

function BBRGB32_mt.__index:getBpp()
    return 32
end

function BB_mt.__index:setType(type_id)
    self.config = bit.bor(bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4))
end

function BB_mt.__index:getPhysicalCoordinates(x, y)
    local rotation = self:getRotation()
    if rotation == 0 then
        return x, y
    elseif rotation == 1 then
        return self.w - y - 1, x
    elseif rotation == 2 then
        return self.w - x - 1, self.h - y - 1
    elseif rotation == 3 then
        return y, self.h - x - 1
    end
end

function BB_mt.__index:getPixelP(x, y)
    return ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x
end

function BB_mt.__index:getPixel(x, y)
    local px, py = self:getPhysicalCoordinates(x, y)
    local color = self:getPixelP(px, py)[0]
    if self:getInverse() == 1 then
        color = color:invert()
    end
    return color
end

function BB_mt.__index:getWidth()
    if 0 == bit.band(1, self:getRotation()) then
        return self.w
    else
        return self.h
    end
end

function BB_mt.__index:getHeight()
    if 0 == bit.band(1, self:getRotation()) then
        return self.h
    else
        return self.w
    end
end

function BB_mt.__index:writePNG(png, filename)
    -- png = png or require("png.png")
    local w, h = self:getWidth(), self:getHeight()
    local cdata = ffi.C.malloc(w * h * 4)
    local mem = ffi.cast("char*", cdata)
    for y = 0, h - 1 do
        local offset = 4 * w * y
        for x = 0, w - 1 do
            local c = self:getPixel(x, y):getColorRGB32()
            mem[offset + 0] = c.r
            mem[offset + 1] = c.g
            mem[offset + 2] = c.b
            mem[offset + 3] = 0xFF
            offset = offset + 4
        end
    end
    png.encode_to_file(filename, mem, w, h)
    ffi.C.free(cdata)
end

for name, func in pairs(BB_mt.__index) do
    if not BB8_mt.__index[name] then
        BB8_mt.__index[name] = func
    end
    if not BB8A_mt.__index[name] then
        BB8A_mt.__index[name] = func
    end
    if not BBRGB16_mt.__index[name] then
        BBRGB16_mt.__index[name] = func
    end
    if not BBRGB24_mt.__index[name] then
        BBRGB24_mt.__index[name] = func
    end
    if not BBRGB32_mt.__index[name] then
        BBRGB32_mt.__index[name] = func
    end
end

local BlitBuffer8     = ffi.metatype("BlitBuffer8", BB8_mt)
local BlitBuffer8A    = ffi.metatype("BlitBuffer8A", BB8A_mt)
local BlitBufferRGB16 = ffi.metatype("BlitBufferRGB16", BBRGB16_mt)
local BlitBufferRGB24 = ffi.metatype("BlitBufferRGB24", BBRGB24_mt)
local BlitBufferRGB32 = ffi.metatype("BlitBufferRGB32", BBRGB32_mt)

ffi.metatype("Color8",     Color8_mt)
ffi.metatype("Color8A",    Color8A_mt)
ffi.metatype("ColorRGB16", ColorRGB16_mt)
ffi.metatype("ColorRGB24", ColorRGB24_mt)
ffi.metatype("ColorRGB32", ColorRGB32_mt)

local BB = function(width, height, buffertype, dataptr, pitch)
    buffertype = buffertype or 1
    if pitch == nil then
        if buffertype == 1 then
            pitch = width
        elseif buffertype == 2 then
            pitch = bit.lshift(width, 1)
        elseif buffertype == 3 then
            pitch = bit.lshift(width, 1)
        elseif buffertype == 4 then
            pitch = width * 3
        elseif buffertype == 5 then
            pitch = bit.lshift(width, 2)
        end
    end
    local bb = nil
    if buffertype == 1 then
        bb = BlitBuffer8(width, height, pitch, nil, 0)
    elseif buffertype == 2 then
        bb = BlitBuffer8A(width, height, pitch, nil, 0)
    elseif buffertype == 3 then
        bb = BlitBufferRGB16(width, height, pitch, nil, 0)
    elseif buffertype == 4 then
        bb = BlitBufferRGB24(width, height, pitch, nil, 0)
    elseif buffertype == 5 then
        bb = BlitBufferRGB32(width, height, pitch, nil, 0)
    else
        error("unknown blitbuffer type")
    end
    bb:setType(buffertype)
    if dataptr == nil then
        dataptr = ffi.C.malloc(pitch * height)
        assert(dataptr, "cannot allocate memory for blitbuffer")
        ffi.fill(dataptr, pitch * height)
        bb:setAllocated(1)
    end
    bb.data = ffi.cast(bb.data, dataptr)
    return bb
end

return BB