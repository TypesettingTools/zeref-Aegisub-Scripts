-- This is free and unencumbered software released into the public domain.

-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.

-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.

-- For more information, please refer to <http://unlicense.org/>

-- Lua port of imagetracer.js <https://github.com/jankovicsandras/imagetracerjs>
-- Port by Zeref <https://github.com/zerefxx>

local bmp = require "img-libs.bmp.bmp".bmp
local png = require "img-libs.png.png".png
local jpg = require "img-libs.jpg.jpg".jpg
local gif = require "img-libs.gif.gif".gif

local ffi = require "ffi"
local zf  = require "ZF.utils"

ffi.cdef [[
    typedef struct imgd {
        uint8_t r, g, b, a;
    } imgd;
]]

local image_tracer = function(filename)
    local obj = {versionnumber = "1.2.6"}
    local file_ext = type(filename) == "string" and filename:match("^.+%.(.+)$") or "gif"
    if file_ext == "png" then
        obj.imgd = png(filename):map()
    elseif file_ext == "jpg" then
        obj.imgd = jpg(filename):map()
    elseif file_ext == "bmp" then
        obj.imgd = bmp(filename):map()
    elseif file_ext == "gif" then
        obj.imgd = filename
    end
    obj.optionpresets = {
        default = {
            -- Tracing
            ltres = 1,
            qtres = 1,
            pathomit = 8,
            rightangleenhance = true,
            -- Color quantization
            colorsampling = 2,
            numberofcolors = 16,
            mincolorratio = 0,
            colorquantcycles = 3,
            -- shape rendering
            strokewidth = 1,
            scale = 1,
            roundcoords = 2,
            deletewhite = false,
            deleteblack = false,
            -- Blur
            blurradius = 0,
            blurdelta = 20
        }
    }
    -- Lookup tables for pathscan
    -- pathscan_combined_lookup[arr[py][px]][dir + 1] = {nextarrpypx, nextdir, deltapx, deltapy}
    -- arr[py][px] == 15 or arr[py][px] == 0 is invalid
    obj.pathscan_combined_lookup = {
        {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}},
        {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}},
        {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}},
        {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}},
        {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}},
        {{13, 3, 0, 1},    {13, 2, -1, 0},   {7, 1, 0, -1},    {7, 0, 1, 0}},
        {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}},
        {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}},
        {{0, 3, 0, 1},     {0, 2, -1, 0},    {-1, -1, -1, -1}, {-1, -1, -1, -1}},
        {{-1, -1, -1, -1}, {0, 1, 0, -1},    {-1, -1, -1, -1}, {0, 3, 0, 1}},
        {{11, 1, 0, -1},   {14, 0, 1, 0},    {14, 3, 0, 1},    {11, 2, -1, 0}},
        {{-1, -1, -1, -1}, {0, 0, 1, 0},     {0, 3, 0, 1},     {-1, -1, -1, -1}},
        {{0, 0, 1, 0},     {-1, -1, -1, -1}, {0, 2, -1, 0},    {-1, -1, -1, -1}},
        {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 1, 0, -1},    {0, 0, 1, 0}},
        {{0, 1, 0, -1},    {-1, -1, -1, -1}, {-1, -1, -1, -1}, {0, 2, -1, 0}},
        {{-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}, {-1, -1, -1, -1}}
    }
    -- Gaussian kernels for blur
    obj.gks = {
        {0.27901, 0.44198, 0.27901},
        {0.135336, 0.228569, 0.272192, 0.228569, 0.135336},
        {0.086776, 0.136394, 0.178908, 0.195843, 0.178908, 0.136394, 0.086776},
        {0.063327, 0.093095, 0.122589, 0.144599, 0.152781, 0.144599, 0.122589, 0.093095, 0.063327},
        {0.049692, 0.069304, 0.089767, 0.107988, 0.120651, 0.125194, 0.120651, 0.107988, 0.089767, 0.069304, 0.049692}
    }
    -- randomseed
    math.randomseed(os.time())
    -- Tracing imagedata, then returning tracedata (layers with paths, palette, image size)
    function obj:to_trace_data(options)
        options = self:checkoptions(options)
        -- 1. Color quantization
        local ii = self:colorquantization(self.imgd, options)
        -- create tracedata object
        local tracedata = {
            layers = {},
            palette = ii.palette,
            width = #ii.array[0] - 1,
            height = #ii.array - 1
        }
        -- Loop to trace each color layer
        for colornum = 0, #ii.palette - 1 do
            -- layeringstep -> pathscan -> internodes -> batchtracepaths
            local layeringstep = self:layeringstep(ii, colornum)
            local pathscan = self:pathscan(layeringstep, options.pathomit)
            local internodes = self:internodes(pathscan, options)
            local tracedlayer = self:batchtracepaths(internodes, options.ltres, options.qtres)
            table.insert(tracedata.layers, tracedlayer)
        end
        return tracedata
    end

    -- Tracing imagedata, then returning the scaled svg string
    function obj:to_shape(options)
        options = self:checkoptions(options)
        local td = self:to_trace_data(options)
        return self:get_shape(td, options)
    end

    -- creating options object, setting defaults for missing values
    function obj:checkoptions(options)
        options = options or {}
        -- Option preset
        if type(options) == "string" then
            options = options:lower()
            options = not self.optionpresets[options] and {} or self.optionpresets[options]
        end
        -- Defaults
        for k in pairs(self.optionpresets.default) do
            if not rawget(options, k) then
                options[k] = self.optionpresets.default[k]
            end
        end
        -- options.pal is not defined here, the custom palette should be added externally
        -- options.pal = {{"r" = 0,"g" = 0,"b" = 0,"a" = 255}, {...}, ...}
        return options
    end

    function obj:blur(imgd, radius, delta)
        -- new ImageData
        local imgd2 = {
            width = imgd.width,
            height = imgd.height,
            data = ffi.new("imgd[?]", imgd.height * imgd.width)
        }
        -- radius and delta limits, this kernel
        radius = math.floor(radius)
        if radius < 1 then
            return imgd
        end
        if radius > 5 then
            radius = 5
        end
        delta = math.abs(delta)
        if delta > 1024 then
            delta = 1024
        end
        local thisgk = self.gks[radius]
        -- loop through all pixels, horizontal blur
        for j = 0, imgd.height - 1 do
            for i = 0, imgd.width - 1 do
                local racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                -- gauss kernel loop
                for k = -radius, radius do
                    -- add weighted color values
                    if i + k > 0 and i + k < imgd.width then
                        local idx = j * imgd.width + i + k
                        racc = racc + imgd.data[idx].r * thisgk[k + radius + 1]
                        gacc = gacc + imgd.data[idx].g * thisgk[k + radius + 1]
                        bacc = bacc + imgd.data[idx].b * thisgk[k + radius + 1]
                        aacc = aacc + imgd.data[idx].a * thisgk[k + radius + 1]
                        wacc = wacc + thisgk[k + radius + 1]
                    end
                end
                -- The new pixel
                local idx = j * imgd.width + i
                imgd2.data[idx].r = math.floor(racc / wacc)
                imgd2.data[idx].g = math.floor(gacc / wacc)
                imgd2.data[idx].b = math.floor(bacc / wacc)
                imgd2.data[idx].a = math.floor(aacc / wacc)
            end
        end
        -- copying the half blurred imgd2
        local himgd = imgd2.data -- table_copy(imgd2.data)
        -- loop through all pixels, vertical blur
        for j = 0, imgd.height - 1 do
            for i = 0, imgd.width - 1 do
                local racc, gacc, bacc, aacc, wacc = 0, 0, 0, 0, 0
                -- gauss kernel loop
                for k = -radius, radius do
                    -- add weighted color values
                    if j + k > 0 and j + k < imgd.height then
                        local idx = (j + k) * imgd.width + i
                        racc = racc + himgd[idx].r * thisgk[k + radius + 1]
                        gacc = gacc + himgd[idx].g * thisgk[k + radius + 1]
                        bacc = bacc + himgd[idx].b * thisgk[k + radius + 1]
                        aacc = aacc + himgd[idx].a * thisgk[k + radius + 1]
                        wacc = wacc + thisgk[k + radius + 1]
                    end
                end
                -- The new pixel
                local idx = j * imgd.width + i
                imgd2.data[idx].r = math.floor(racc / wacc)
                imgd2.data[idx].g = math.floor(gacc / wacc)
                imgd2.data[idx].b = math.floor(bacc / wacc)
                imgd2.data[idx].a = math.floor(aacc / wacc)
            end
        end
        -- Selective blur: loop through all pixels
        for j = 0, imgd.height - 1 do
            for i = 0, imgd.width - 1 do
                local idx = j * imgd.width + i
                -- d is the difference between the blurred and the original pixel
                local d = math.abs(imgd2.data[idx].r - imgd.data[idx].r) + math.abs(imgd2.data[idx].g - imgd.data[idx].g) + math.abs(imgd2.data[idx].b - imgd.data[idx].b) + math.abs(imgd2.data[idx].a - imgd.data[idx].a)
                -- selective blur: if d > delta, put the original pixel back
                if d > delta then
                    imgd2.data[idx].r = imgd.data[idx].r
                    imgd2.data[idx].g = imgd.data[idx].g
                    imgd2.data[idx].b = imgd.data[idx].b
                    imgd2.data[idx].a = imgd.data[idx].a
                end
            end
        end
        return imgd2
    end

    function obj:colorquantization(imgd, options)
        local arr, idx, paletteacc, pixelnum, palette = {}, 0, {}, imgd.width * imgd.height, nil
        -- Filling arr (color index array) with -1
        for j = 0, imgd.height + 1 do
            arr[j] = {}
            for i = 0, imgd.width + 1 do
                arr[j][i] = -1
            end
        end
        -- Use custom palette if pal is defined or sample / generate custom length palett
        if options.pal then
            palette = options.pal
        elseif options.colorsampling == 0 then
            palette = self:generatepalette(options.numberofcolors)
        elseif options.colorsampling == 1 then
            palette = self:samplepalette(options.numberofcolors, imgd)
        else
            palette = self:samplepalette2(options.numberofcolors, imgd)
        end
        -- Selective Gaussian blur preprocessin
        if options.blurradius > 0 then
            imgd = self:blur(imgd, options.blurradius, options.blurdelta)
        end
        -- Repeat clustering step options.colorquantcycles times
        for cnt = 0, options.colorquantcycles - 1 do
            -- Average colors from the second iteration
            if cnt > 0 then
                -- averaging paletteacc for palette
                for k = 1, #palette do
                    -- averaging
                    if paletteacc[k].n > 0 then
                        palette[k] = {
                            r = math.floor(paletteacc[k].r / paletteacc[k].n),
                            g = math.floor(paletteacc[k].g / paletteacc[k].n),
                            b = math.floor(paletteacc[k].b / paletteacc[k].n),
                            a = math.floor(paletteacc[k].a / paletteacc[k].n)
                        }
                    end
                    -- Randomizing a color, if there are too few pixels and there will be a new cycle
                    if paletteacc[k].n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1 then
                        palette[k] = {
                            r = math.floor(math.random() * 255),
                            g = math.floor(math.random() * 255),
                            b = math.floor(math.random() * 255),
                            a = math.floor(math.random() * 255)
                        }
                    end
                end
            end
            -- Reseting palette accumulator for averaging
            for i = 1, #palette do
                paletteacc[i] = {r = 0, g = 0, b = 0, a = 0, n = 0}
            end
            -- loop through all pixels
            for j = 0, imgd.height - 1 do
                for i = 0, imgd.width - 1 do
                    idx = j * imgd.width + i -- pixel index
                    -- find closest color from palette by measuring (rectilinear) color distance between this pixel and all palette colors
                    local ci, cdl = 0, 1024 -- 4 * 256 is the maximum RGBA distance
                    for k = 1, #palette do
                        -- In my experience, https://en.wikipedia.org/wiki/Rectilinear_distance works
                        -- better than https://en.wikipedia.org/wiki/Euclidean_distance
                        local pr = palette[k].r > imgd.data[idx].r and palette[k].r - imgd.data[idx].r or imgd.data[idx].r - palette[k].r
                        local pg = palette[k].g > imgd.data[idx].g and palette[k].g - imgd.data[idx].g or imgd.data[idx].g - palette[k].g
                        local pb = palette[k].b > imgd.data[idx].b and palette[k].b - imgd.data[idx].b or imgd.data[idx].b - palette[k].b
                        local pa = palette[k].a > imgd.data[idx].a and palette[k].a - imgd.data[idx].a or imgd.data[idx].a - palette[k].a
                        local cd = pr + pg + pb + pa
                        -- Remember this color if this is the closest yet
                        if cd < cdl then
                            cdl, ci = cd, k
                        end
                    end
                    -- add to palettacc
                    paletteacc[ci].r = paletteacc[ci].r + imgd.data[idx].r
                    paletteacc[ci].g = paletteacc[ci].g + imgd.data[idx].g
                    paletteacc[ci].b = paletteacc[ci].b + imgd.data[idx].b
                    paletteacc[ci].a = paletteacc[ci].a + imgd.data[idx].a
                    paletteacc[ci].n = paletteacc[ci].n + 1
                    arr[j + 1][i + 1] = ci - 1
                end
            end
        end
        return {array = arr, palette = palette}
    end

    -- Sampling a palette from imagedata
    function obj:samplepalette(numberofcolors, imgd)
        local idx, palette = nil, {}
        for i = 0, numberofcolors - 1 do
            idx = math.floor(math.random() * (imgd.width * imgd.height) / 4) * 4
            table.insert(palette, {
                r = imgd.data[idx].r,
                g = imgd.data[idx].g,
                b = imgd.data[idx].b,
                a = imgd.data[idx].a
            })
        end
        return palette
    end

    -- Deterministic sampling a palette from imagedata: rectangular grid
    function obj:samplepalette2(numberofcolors, imgd)
        local palette = {}
        local ni = math.ceil(math.sqrt(numberofcolors))
        local nj = math.ceil(numberofcolors / ni)
        local vx = imgd.width / (ni + 1)
        local vy = imgd.height / (nj + 1)
        for j = 0, nj - 1 do
            for i = 0, ni - 1 do
                if #palette == numberofcolors then
                    break
                else
                    local idx = math.floor(((j + 1) * vy) * imgd.width + ((i + 1) * vx))
                    table.insert(palette, {
                        r = imgd.data[idx].r,
                        g = imgd.data[idx].g,
                        b = imgd.data[idx].b,
                        a = imgd.data[idx].a
                    })
                end
            end
        end
        return palette
    end

    -- Generating a palette with numberofcolors
    function obj:generatepalette(numberofcolors)
        local palette = {}
        if numberofcolors < 8 then
            -- Grayscale
            local graystep = math.floor(255 / (numberofcolors - 1))
            for i = 0, numberofcolors - 1 do
                table.insert(palette, {
                    r = i * graystep,
                    g = i * graystep,
                    b = i * graystep,
                    a = 255
                })
            end
        else
            -- RGB color cube
            local colorqnum = math.floor(numberofcolors ^ (1 / 3)) -- Number of points on each edge on the RGB color cube
            local colorstep = math.floor(255 / (colorqnum - 1)) -- distance between points
            local rndnum = numberofcolors - ((colorqnum * colorqnum) * colorqnum) -- number of random colors
            for rcnt = 0, colorqnum - 1 do
                for gcnt = 0, colorqnum - 1 do
                    for bcnt = 0, colorqnum - 1 do
                        table.insert(palette, {
                            r = rcnt * colorstep,
                            g = gcnt * colorstep,
                            b = bcnt * colorstep,
                            a = 255
                        })
                    end
                end
            end
            -- Rest is random
            for rcnt = 0, rndnum - 1 do
                table.insert(palette, {
                    r = math.floor(math.random() * 255),
                    g = math.floor(math.random() * 255),
                    b = math.floor(math.random() * 255),
                    a = math.floor(math.random() * 255)
                })
            end
        end
        return palette
    end

    -- 2. Layer separation and edge detection
    -- Edge node types ( ▓: this layer or 1; ░: not this layer or 0 )
    -- 12  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓  ░░  ▓░  ░▓  ▓▓
    -- 48  ░░  ░░  ░░  ░░  ░▓  ░▓  ░▓  ░▓  ▓░  ▓░  ▓░  ▓░  ▓▓  ▓▓  ▓▓  ▓▓
    --     0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
    function obj:layeringstep(ii, cnum)
        -- Creating layers for each indexed color in arr
        local layer, ah, aw = {}, #ii.array + 1, #ii.array[0] + 1
        for j = 0, ah - 1 do
            layer[j] = {}
            for i = 0, aw - 1 do
                layer[j][i] = 0
            end
        end
        -- Looping through all pixels and calculating edge node type
        for j = 1, ah - 1 do
            for i = 1, aw - 1 do
                local l1 = ii.array[j - 1][i - 1] == cnum and 1 or 0
                local l2 = ii.array[j - 1][i - 0] == cnum and 2 or 0
                local l3 = ii.array[j - 0][i - 1] == cnum and 8 or 0
                local l4 = ii.array[j - 0][i - 0] == cnum and 4 or 0
                layer[j][i] = l1 + l2 + l3 + l4
            end
        end
        return layer
    end

    -- Point in polygon test
    function obj:pointinpoly(p, pa)
        local isin = false
        local j = #pa
        for i = 1, #pa do
            isin = (pa[i].y > p.y) ~= (pa[j].y > p.y) and p.x < (pa[j].x - pa[i].x) * (p.y - pa[i].y) / (pa[j].y - pa[i].y) + pa[i].x and not isin or isin
            j = i
        end
        return isin
    end

    -- 3. Walking through an edge node array, discarding edge node types 0 and 15 and creating paths from the rest.
    -- Walk directions (dir): 0 > ; 1 ^ ; 2 < ; 3 v
    function obj:pathscan(arr, pathomit)
        local paths, pacnt, pcnt, px, py, w, h, dir, pathfinished, holepath, lookuprow = {}, 1, 1, 0, 0, #arr[0] + 1, #arr + 1, 0, true, false, nil
        for j = 0, h - 1 do
            for i = 0, w - 1 do
                if arr[j][i] == 4 or arr[j][i] == 11 then --  Other values are not valid
                    px, py = i, j
                    paths[pacnt] = {}
                    paths[pacnt].points = {}
                    paths[pacnt].boundingbox = {px, py, px, py}
                    paths[pacnt].holechildren = {}
                    pathfinished = false
                    holepath = arr[j][i] == 11
                    pcnt, dir = 1, 1
                    -- Path points loop
                    while not pathfinished do
                        -- New path point
                        paths[pacnt].points[pcnt] = {}
                        paths[pacnt].points[pcnt].x = px - 1
                        paths[pacnt].points[pcnt].y = py - 1
                        paths[pacnt].points[pcnt].t = arr[py][px]
                        -- Bounding box
                        if px - 1 < paths[pacnt].boundingbox[1] then
                            paths[pacnt].boundingbox[1] = px - 1
                        end
                        if px - 1 > paths[pacnt].boundingbox[3] then
                            paths[pacnt].boundingbox[3] = px - 1
                        end
                        if py - 1 < paths[pacnt].boundingbox[2] then
                            paths[pacnt].boundingbox[2] = py - 1
                        end
                        if py - 1 > paths[pacnt].boundingbox[4] then
                            paths[pacnt].boundingbox[4] = py - 1
                        end
                        -- Next: look up the replacement, direction and coordinate changes = clear this cell, turn if required, walk forward
                        lookuprow = self.pathscan_combined_lookup[arr[py][px] + 1][dir + 1]
                        arr[py][px] = lookuprow[1]
                        dir = lookuprow[2]
                        px = px + lookuprow[3]
                        py = py + lookuprow[4]
                        -- Close path
                        if px - 1 == paths[pacnt].points[1].x and py - 1 == paths[pacnt].points[1].y then
                            pathfinished = true
                            -- Discarding paths shorter than pathomit
                            if #paths[pacnt].points < pathomit then
                                table.remove(paths)
                            else
                                paths[pacnt].isholepath = holepath and true or false
                                if holepath then
                                    local parentidx, parentbbox = 1, {-1, -1, w + 1, h + 1}
                                    for parentcnt = 1, pacnt do
                                        if not paths[parentcnt].isholepath and
                                            self:boundingboxincludes(paths[parentcnt].boundingbox, paths[pacnt].boundingbox) and
                                            self:boundingboxincludes(parentbbox, paths[parentcnt].boundingbox) and
                                            self:pointinpoly(paths[pacnt].points[1], paths[parentcnt].points) then
                                            parentidx = parentcnt
                                            parentbbox = paths[parentcnt].boundingbox
                                        end
                                    end
                                    table.insert(paths[parentidx].holechildren, pacnt)
                                end
                                pacnt = pacnt + 1
                            end
                        end
                        pcnt = pcnt + 1
                    end
                end
            end
        end
        return paths
    end

    function obj:boundingboxincludes(parentbbox, childbbox)
        return (parentbbox[1] < childbbox[1]) and (parentbbox[2] < childbbox[2]) and (parentbbox[3] > childbbox[3]) and (parentbbox[4] > childbbox[4])
    end

    -- 4. interpollating between path points for nodes with 8 directions ( East, SouthEast, S, SW, W, NW, N, NE )
    function obj:internodes(paths, options)
        local ins, palen, nextidx, nextidx2, previdx, previdx2 = {}, 1, 1, 1, 1, 1
        -- paths loop
        for pacnt = 1, #paths do
            ins[pacnt] = {}
            ins[pacnt].points = {}
            ins[pacnt].boundingbox = paths[pacnt].boundingbox
            ins[pacnt].holechildren = paths[pacnt].holechildren
            ins[pacnt].isholepath = paths[pacnt].isholepath
            palen = #paths[pacnt].points
            -- pathpoints loop
            for pcnt = 1, palen do
                -- next and previous point indexes
                nextidx = pcnt % palen + 1
                nextidx2 = (pcnt + 1) % palen + 1
                previdx = (pcnt - 2 + palen) % palen + 1
                previdx2 = (pcnt - 3 + palen) % palen + 1
                -- right angle enhance
                if options.rightangleenhance and self:testrightangle(paths[pacnt], previdx2, previdx, pcnt, nextidx, nextidx2) then
                    -- Fix previous direction
                    if #ins[pacnt].points > 1 then
                        ins[pacnt].points[#ins[pacnt].points].linesegment = self:getdirection(ins[pacnt].points[#ins[pacnt].points].x, ins[pacnt].points[#ins[pacnt].points].y, paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y)
                    end
                    -- This corner point
                    table.insert(ins[pacnt].points, {
                        x = paths[pacnt].points[pcnt].x,
                        y = paths[pacnt].points[pcnt].y,
                        linesegment = self:getdirection(paths[pacnt].points[pcnt].x, paths[pacnt].points[pcnt].y, (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2)
                    })
                end
                -- interpolate between two path points
                table.insert(ins[pacnt].points, {
                    x = (paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2,
                    y = (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2,
                    linesegment = self:getdirection((paths[pacnt].points[pcnt].x + paths[pacnt].points[nextidx].x) / 2, (paths[pacnt].points[pcnt].y + paths[pacnt].points[nextidx].y) / 2, (paths[pacnt].points[nextidx].x + paths[pacnt].points[nextidx2].x) / 2, (paths[pacnt].points[nextidx].y + paths[pacnt].points[nextidx2].y) / 2)
                })
            end
        end
        return ins
    end

    function obj:testrightangle(path, idx1, idx2, idx3, idx4, idx5)
        return (path.points[idx3].x == path.points[idx1].x and path.points[idx3].x == path.points[idx2].x and path.points[idx3].y == path.points[idx4].y and path.points[idx3].y == path.points[idx5].y) or (path.points[idx3].y == path.points[idx1].y and path.points[idx3].y == path.points[idx2].y and path.points[idx3].x == path.points[idx4].x and path.points[idx3].x == path.points[idx5].x)
    end

    function obj:getdirection(x1, y1, x2, y2)
        local val = 8
        if x1 < x2 then
            if y1 < y2 then -- SouthEast
                val = 1
            elseif y1 > y2 then -- NE
                val = 7
            else -- E
                val = 0
            end
        elseif x1 > x2 then
            if y1 < y2 then -- SW
                val = 3
            elseif y1 > y2 then -- NW
                val = 5
            else -- W
                val = 4
            end
        else
            if y1 < y2 then -- S
                val = 2
            elseif y1 > y2 then -- N
                val = 6
            else -- center, this should not happen
                val = 8
            end
        end
        return val
    end

    -- 5. tracepath() : recursively trying to fit straight and quadratic spline segments on the 8 direction internode path
    -- 5.1. Find sequences of points with only 2 segment types
    -- 5.2. Fit a straight line on the sequence
    -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
    -- 5.4. Fit a quadratic spline through errorpoint (project this to get controlpoint), then measure errors on every point in the sequence
    -- 5.5. If the spline fails (distance error > qtres), find the point with the biggest error, set splitpoint = fitting point
    -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
    function obj:tracepath(path, ltres, qtres)
        local pcnt = 1
        local smp = {}
        smp.segments = {}
        smp.boundingbox = path.boundingbox
        smp.holechildren = path.holechildren
        smp.isholepath = path.isholepath
        while pcnt < #path.points do
            -- 5.1. Find sequences of points with only 2 segment types
            local segtype1 = path.points[pcnt].linesegment
            local segtype2 = -1
            local seqend = pcnt + 1
            while (path.points[seqend].linesegment == segtype1 or path.points[seqend].linesegment == segtype2 or segtype2 == -1) and seqend < #path.points do
                if path.points[seqend].linesegment ~= segtype1 and segtype2 == -1 then
                    segtype2 = path.points[seqend].linesegment
                end
                seqend = seqend + 1
            end
            if seqend == #path.points then
                seqend = 1
            end
            -- 5.2. - 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
            smp.segments = zf.table(smp.segments):concat(self:fitseq(path, ltres, qtres, pcnt, seqend))
            -- forward pcnt
            if seqend > 1 then
                pcnt = seqend
            else
                pcnt = #path.points
            end
        end
        return smp
    end

    -- 5.2. - 5.6. recursively fitting a straight or quadratic line segment on this sequence of path nodes,
    -- called from tracepath()
    function obj:fitseq(path, ltres, qtres, seqstart, seqend)
        -- return if invalid seqend
        if seqend > #path.points or seqend < 1 then
            return {}
        end
        local errorpoint, errorval, curvepass = seqstart, 0, true
        local tl = seqend - seqstart
        if tl < 1 then
            tl = tl + #path.points
        end
        local vx = (path.points[seqend].x - path.points[seqstart].x) / tl
        local vy = (path.points[seqend].y - path.points[seqstart].y) / tl
        -- 5.2. Fit a straight line on the sequence
        local pcnt = seqstart % #path.points + 1
        while pcnt ~= seqend do
            local pl = pcnt - seqstart
            if pl < 1 then
                pl = pl + #path.points
            end
            local px = path.points[seqstart].x + vx * pl
            local py = path.points[seqstart].y + vy * pl
            local dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
            if dist2 > ltres then
                curvepass = false
            end
            if dist2 > errorval then
                errorpoint = pcnt - 1
                errorval = dist2
            end
            pcnt = pcnt % #path.points + 1
        end
        -- return straight line if fits
        if curvepass then
            return {
                {
                    type = "l",
                    x1 = path.points[seqstart].x, y1 = path.points[seqstart].y,
                    x2 = path.points[seqend].x, y2 = path.points[seqend].y
                }
            }
        end
        -- 5.3. If the straight line fails (distance error > ltres), find the point with the biggest error
        local fitpoint = errorpoint + 1
        curvepass, errorval = true, 0
        -- 5.4. Fit a quadratic spline through this point, measure errors on every point in the sequence
        -- helpers and projecting to get control point
        local t = (fitpoint - seqstart) / tl
        local t1 = (1 - t) * (1 - t)
        local t2 = 2 * (1 - t) * t
        local t3 = t * t
        local cpx = (t1 * path.points[seqstart].x + t3 * path.points[seqend].x - path.points[fitpoint].x) / -t2
        local cpy = (t1 * path.points[seqstart].y + t3 * path.points[seqend].y - path.points[fitpoint].y) / -t2
        -- Check every point
        pcnt = seqstart + 1
        while pcnt ~= seqend do
            t = (pcnt - seqstart) / tl
            t1 = (1 - t) * (1 - t)
            t2 = 2 * (1 - t) * t
            t3 = t * t
            local px = t1 * path.points[seqstart].x + t2 * cpx + t3 * path.points[seqend].x
            local py = t1 * path.points[seqstart].y + t2 * cpy + t3 * path.points[seqend].y
            local dist2 = (path.points[pcnt].x - px) * (path.points[pcnt].x - px) + (path.points[pcnt].y - py) * (path.points[pcnt].y - py)
            if dist2 > qtres then
                curvepass = false
            end
            if dist2 > errorval then
                errorpoint = pcnt - 1
                errorval = dist2
            end
            pcnt = pcnt % #path.points + 1
        end
        -- return spline if fits
        if curvepass then
            local x1, y1 = path.points[seqstart].x, path.points[seqstart].y
            local x2, y2 = cpx, cpy
            local x3, y3 = path.points[seqend].x, path.points[seqend].y
            return {
                {
                    type = "b",
                    x1 = x1, y1 = y1,
                    x2 = (x1 + 2 * x2) / 3, y2 = (y1 + 2 * y2) / 3,
                    x3 = (x3 + 2 * x2) / 3, y3 = (y3 + 2 * y2) / 3,
                    x4 = x3, y4 = y3
                }
            }
        end
        -- 5.5. If the spline fails (distance error>qtres), find the point with the biggest error
        local splitpoint = fitpoint -- Earlier: math.floor((fitpoint + errorpoint) / 2)
        -- 5.6. Split sequence and recursively apply 5.2. - 5.6. to startpoint-splitpoint and splitpoint-endpoint sequences
        return zf.table(self:fitseq(path, ltres, qtres, seqstart, splitpoint)):concat(self:fitseq(path, ltres, qtres, splitpoint, seqend))
    end

    -- 5. Batch tracing paths
    function obj:batchtracepaths(internodepaths, ltres, qtres)
        local btracedpaths = {}
        for k in pairs(internodepaths) do
            if not rawget(internodepaths, k) then
                goto continue
            end
            table.insert(btracedpaths, self:tracepath(internodepaths[k], ltres, qtres))
            ::continue::
        end
        return btracedpaths
    end

    -- Getting shape
    function obj:shape_path(tracedata, lnum, pathnum, options)
        local layer = tracedata.layers[lnum]
        local smp = layer[pathnum]
        local function round(n, d)
            return zf.math:round(n, d)
        end
        local function build_style(c)
            local color = ("\\c&H%02X%02X%02X&"):format(c.b, c.g, c.r)
            local alpha = ("\\alpha&H%02X&"):format(255 - c.a)
            local cbord = options.strokewidth > 0 and color:gsub("\\c", "\\3c") or ""
            return color, alpha, cbord
        end
        local color, alpha, cbord = build_style(tracedata.palette[lnum])
        -- Creating non-hole path string
        local shape = ("m %s %s "):format(
            round(smp.segments[1].x1 * options.scale, options.roundcoords),
            round(smp.segments[1].y1 * options.scale, options.roundcoords)
        )
        for pcnt = 1, #smp.segments do
            shape = shape .. ("%s %s %s "):format(
                smp.segments[pcnt].type,
                round(smp.segments[pcnt].x2 * options.scale, options.roundcoords),
                round(smp.segments[pcnt].y2 * options.scale, options.roundcoords)
            )
            if rawget(smp.segments[pcnt], "x4") then
                shape = shape .. ("%s %s %s %s "):format(
                    round(smp.segments[pcnt].x3 * options.scale, options.roundcoords),
                    round(smp.segments[pcnt].y3 * options.scale, options.roundcoords),
                    round(smp.segments[pcnt].x4 * options.scale, options.roundcoords),
                    round(smp.segments[pcnt].y4 * options.scale, options.roundcoords)
                )
            end
        end
        -- Hole children
        for hcnt = 1, #smp.holechildren do
            local hsmp = layer[smp.holechildren[hcnt]]
            -- Creating hole path string
            if rawget(hsmp.segments[#hsmp.segments], "x4") then
                shape = shape .. ("m %s %s "):format(
                    round(hsmp.segments[#hsmp.segments].x4 * options.scale),
                    round(hsmp.segments[#hsmp.segments].y4 * options.scale)
                )
            else
                shape = shape .. ("m %s %s "):format(
                    hsmp.segments[#hsmp.segments].x2 * options.scale,
                    hsmp.segments[#hsmp.segments].y2 * options.scale
                )
            end
            for pcnt = #hsmp.segments, 1, -1 do
                shape = shape .. hsmp.segments[pcnt].type .. " "
                if rawget(hsmp.segments[pcnt], "x4") then
                    shape = shape .. ("%s %s %s %s "):format(
                        round(hsmp.segments[pcnt].x2 * options.scale),
                        round(hsmp.segments[pcnt].y2 * options.scale),
                        round(hsmp.segments[pcnt].x3 * options.scale),
                        round(hsmp.segments[pcnt].y3 * options.scale)
                    )
                end
                shape = shape .. ("%s %s "):format(
                    round(hsmp.segments[pcnt].x1 * options.scale),
                    round(hsmp.segments[pcnt].y1 * options.scale)
                )
            end
        end
        return shape, color, alpha, cbord
    end

    -- 5. Batch tracing layers
    function obj:get_shape(tracedata, options)
        options = self:checkoptions(options)
        local shaper = {}
        for lcnt = 1, #tracedata.layers do
            for pcnt = 1, #tracedata.layers[lcnt] do
                if not tracedata.layers[lcnt][pcnt].isholepath then
                    local shape, color, alpha, cbord = self:shape_path(tracedata, lcnt, pcnt, options)
                    if alpha ~= "\\alpha&HFF&" then -- ignores invisible values
                        shaper[#shaper + 1] = {shape = shape, color = color, alpha = alpha, cbord = cbord}
                    end
                end
            end
        end
        local group, build = {}, {}
        for i = 1, #shaper do
            local v = shaper[i]
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
        for i = 1, #group do
            local shape = ""
            for j = 1, #group[i] do
                shape = shape .. group[i][j].shape
            end
            local wt = self.optionpresets.default.deletewhite
            local bk = self.optionpresets.default.deleteblack
            if (wt and group[i][1].color == "\\c&HFFFFFF&") then -- skip white
                goto continue
            end
            if (bk and group[i][1].color == "\\c&H000000&") then -- skip black
                goto continue
            end
            build[#build + 1] = ("{\\an7\\pos(0,0)%s\\bord%s\\shad0\\fscx100\\fscy100\\p1}%s"):format(
                group[i][1].color .. group[i][1].cbord .. group[i][1].alpha, options.strokewidth, shape
            )
            ::continue::
        end
        return build
    end
    return obj
end

return {image_tracer = image_tracer, png = png, jpg = jpg, bmp = bmp, gif = gif}