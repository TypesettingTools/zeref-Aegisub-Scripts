local ffi = require "ffi"

ffi.cdef [[
	typedef struct bmp_color {
		uint8_t r, g, b, a;
	} bmp_color;
]]

local function read_word(data, offset)
	return data:byte(offset + 1) * 256 + data:byte(offset)
end

local function read_dword(data, offset)
	return read_word(data, offset + 2) * 65536 + read_word(data, offset)
end

local bmp = function(filename)
	local file = assert(io.open(filename, "rb"), "Can't open file!")
	local data = file:read("*a")
	file:close()
	if not read_dword(data, 1) == 0x4D42 then -- Bitmap "magic" header
		return nil, "Bitmap magic not found"
	elseif read_word(data, 29) ~= 24 then -- Bits per pixel
		return nil, "Only 24bpp bitmaps supported"
	elseif read_dword(data, 31) ~= 0 then -- Compression
		return nil, "Only uncompressed bitmaps supported"
	end
	local obj = {
		data = data,
		bit_depth = 24,
		pixel_offset = read_word(data, 11),
		width = read_dword(data, 19),
		height = read_dword(data, 23)
	}
	function obj:get_pixel(x, y)
		if (x < 0) or (x > self.width) or (y < 0) or (y > self.height) then
			return nil, "Out of bounds"
		end
		local index = self.pixel_offset + (self.height - y - 1) * 3 * self.width + x * 3
		local b = data:byte(index + 1)
		local g = data:byte(index + 2)
		local r = data:byte(index + 3)
		return r, g, b
	end
	function obj:map()
		local i = 0
		self.data = ffi.new("bmp_color[?]", self.width * self.height)
		for y = 0, self.height - 1 do
			for x = 0, self.width - 1 do
				local r, g, b = self:get_pixel(x, y)
				self.data[i].r = r
				self.data[i].g = g
				self.data[i].b = b
				self.data[i].a = 255
				i = i + 1
			end
		end
		return self
	end
	return obj
end

return {bmp = bmp}