-- Copyright (c) 2021 Zeref

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local *
pi, ln, sin, cos, tan, max, min  = math.pi, math.log, math.sin, math.cos, math.tan, math.max, math.min
abs, deg, rad, log, asin, sqrt   = math.abs, math.deg, math.rad, math.log10, math.asin, math.sqrt
acos, atan, sinh, cosh, tanh     = math.acos, math.atan, math.asin, math.cosh, math.tanh
rand, ceil, floor, atan2, format = math.random, math.ceil, math.floor, math.atan2, string.format

-- load internal libs
ffi = require "ffi"
bit = require "bit"

-- load external libs
Yutils = require "Yutils"
reqffi = require "requireffi.requireffi"
require "karaskel"

local CPP, PNG, JPG, GIF
switch ffi.os
    when "Windows"
        switch ffi.arch
            when "x64"
                CPP = reqffi "ZF.bin.win.clipper64"
                PNG = reqffi "ZF.bin.win.png64"
                JPG = reqffi "ZF.bin.win.jpg64"
                GIF = reqffi "ZF.bin.win.gif64"
            when "x86"
                CPP = reqffi "ZF.bin.win.clipper86"
                PNG = reqffi "ZF.bin.win.png86"
                JPG = reqffi "ZF.bin.win.jpg86"
                GIF = reqffi "ZF.bin.win.gif86"
    when "Linux"
        if ffi.arch == "x64"
            CPP = reqffi "ZF.bin.linux.libclipper64"
            PNG = reqffi "ZF.bin.linux.libpng64"
            JPG = reqffi "ZF.bin.linux.libjpg64"
            GIF = reqffi "ZF.bin.linux.libgif64"
    else
        error "Not compatible with your operating system!"

-- metatables
META = {
    PATH:     {}, PATHS:    {}, OFFSET:   {}, CLIPPER:  {}, COLOR_8:  {}
    COLOR_8A: {}, COLOR_16: {}, COLOR_24: {}, COLOR_32: {}, BBF8:     {}
    BBF8A:    {}, BBF16:    {}, BBF24:    {}, BBF32:    {}, BBF:      {}
}

-- Clipper defs
ffi.cdef [[
    typedef struct __zf_int_point { int64_t x, y; } zf_int_point;
    typedef struct __zf_int_rect { int64_t left; int64_t top; int64_t right; int64_t bottom; } zf_int_rect;
    typedef signed long long cInt;
    typedef struct __zf_path zf_path;
    typedef struct __zf_paths zf_paths;
    typedef struct __zf_offset zf_offset;
    typedef struct __zf_clipper zf_clipper;

    const char* zf_err_msg();
    zf_path* zf_path_new();
    void zf_path_free(zf_path *self);
    zf_int_point* zf_path_get(zf_path *self, int i);
    bool zf_path_add(zf_path *self, cInt x, cInt y);
    int zf_path_size(zf_path *self);

    zf_paths* zf_paths_new();
    void zf_paths_free(zf_paths *self);
    zf_path* zf_paths_get(zf_paths *self, int i);
    bool zf_paths_add(zf_paths *self, zf_path *path);
    int zf_paths_size(zf_paths *self);

    zf_offset* zf_offset_new(double miterLimit, double roundPrecision);
    void zf_offset_free(zf_offset *self);
    zf_paths* zf_offset_path(zf_offset *self, zf_path *subj, double delta, int jointType, int endType);
    zf_paths* zf_offset_paths(zf_offset *self, zf_paths *subj, double delta, int jointType, int endType);

    zf_clipper* zf_clipper_new();
    void zf_clipper_free(zf_clipper *CLP);
    bool zf_clipper_add_path(zf_clipper *CLP, zf_path *path, int pt, bool closed,const char *err);
    bool zf_clipper_add_paths(zf_clipper *CLP, zf_paths *paths, int pt, bool closed, const char *err);
    zf_paths* zf_clipper_execute(zf_clipper *CLP, int clipType, int subjFillType, int clipFillType);
]]

-- Blitbuffer defs
ffi.cdef [[
    typedef struct color_8 {
        uint8_t a;
    } color_8;
    typedef struct color_8A {
        uint8_t a;
        uint8_t alpha;
    } color_8A;
    typedef struct color_16 {
        uint16_t v;
    } color_16;
    typedef struct color_24 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
    } color_24;
    typedef struct color_32 {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t alpha;
    } color_32;
    typedef struct color_RGBA {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_RGBA;
    typedef struct buffer {
        int w;
        int h;
        int pitch;
        uint8_t *data;
        uint8_t config;
    } buffer;
    typedef struct buffer_8 {
        int w;
        int h;
        int pitch;
        color_8 *data;
        uint8_t config;
    } buffer_8;
    typedef struct buffer_8A {
        int w;
        int h;
        int pitch;
        color_8A *data;
        uint8_t config;
    } buffer_8A;
    typedef struct buffer_16 {
        int w;
        int h;
        int pitch;
        color_16 *data;
        uint8_t config;
    } buffer_16;
    typedef struct buffer_24 {
        int w;
        int h;
        int pitch;
        color_24 *data;
        uint8_t config;
    } buffer_24;
    typedef struct buffer_32 {
        int w;
        int h;
        int pitch;
        color_32 *data;
        uint8_t config;
    } buffer_32;
    void *malloc(int size);
    void free(void *ptr);
]]

-- LodePNG defs
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
]]

-- TurboJPEG defs
ffi.cdef [[
    typedef void *tjhandle;
    enum TJPF {
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
    };
    enum TJSAMP {
        TJSAMP_444 = 0,
        TJSAMP_422,
        TJSAMP_420,
        TJSAMP_GRAY,
        TJSAMP_440,
        TJSAMP_411
    };
    int tjDestroy(tjhandle handle);
    tjhandle tjInitDecompress(void);
    int tjDecompressHeader3(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, int *width, int *height, int *jpegSubsamp, int *jpegColorspace);
    int tjDecompress2(tjhandle handle, const unsigned char *jpegBuf, unsigned long jpegSize, unsigned char *dstBuf, int width, int pitch, int height, int pixelFormat, int flags);
]]

-- Gif defs
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

class MATH

    -- returns the distance between two points
    distance: (x1 = 0, y1 = 0, x2 = 0, y2 = 0) => @round sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), 3

    -- rounds numerical values
    round: (x, dec = 2) => Yutils.math.round(x, dec)

class TABLE

    new: (t) => @t = t

    -- makes a shallow copy of an table
    copy: =>
        new = {}
        for k, v in pairs @t
            if type(v) == "table"
                new[k] = TABLE(v)\copy!
            else
                new[k] = v
        return new

    -- concatenates values to the end of the table
    concat: (...) =>
        t = @copy!
        for val in *{...}
            if type(val) == "table"
                for k, v in pairs val
                    t[#t + 1] = v if type(k) == "number"
            else
                t[#t + 1] = val
        return t

    -- creates a new table populated with the results of calling a provided function on every element in the calling table
    map: (fn) => {k, fn(v, k, @t) for k, v in pairs @t}

    -- adds one or more elements to the end of the table
    push: (...) =>
        n = select("#", ...)
        for i = 1, n
            @t[#@t + 1] = select(i, ...)
        return ...

    -- executes a reducer function on each element of the table
    reduce: (fn, init) =>
        acc = init
        for k, v in pairs @t
            acc = (k == 1 and not init) and v or fn(acc, v) -- (accumulator, current_value)
        return acc

    -- Reverses all table values
    reverse: => [@t[#@t + 1 - i] for i = 1, #@t]

    -- returns a copy of part of an table from a subarray created between the start and end positions
    slice: (f, l, s) => [@t[i] for i = f or 1, l or #@t, s or 1]

    -- changes the contents of an table by removing or replacing existing elements and/or adding new elements
    splice: (start, delete, ...) =>
        args, removes, t_len = {...}, {}, #@t
        n_args, i_args = #args, 1
        start = start < 1 and 1 or start
        delete = delete < 0 and 0 or delete
        if start > t_len
            start = t_len + 1
            delete = 0
        delete = start + delete - 1 > t_len and t_len - start + 1 or delete
        for pos = start, start + min(delete, n_args) - 1
            table.insert(removes, @t[pos])
            @t[pos] = args[i_args]
            i_args += 1
        i_args -= 1
        for i = 1, delete - n_args
            table.insert(removes, table.remove(@t, start + i_args))
        for i = n_args - delete, 1, -1
            table.insert(@t, start + delete, args[i_args + i])
        return removes

    -- inserts new elements at the start of an table, and returns the new length of the table
    unshift: (...) =>
        args = {...}
        for k = #args, 1, -1
            table.insert(@t, 1, args[k])
        return #@t

    -- returns a string with the contents of the table
    view: (table_name = "table_unnamed", indent = "") =>
        cart, autoref = "", ""
        isemptytable = (t) -> next(t) == nil
        basicSerialize = (o) ->
            so = tostring(o)
            if type(o) == "function"
                info = debug.getinfo o, "S"
                return format "%q", so .. ", C function" if info.what == "C"
                format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
            elseif (type(o) == "number") or (type(o) == "boolean")
                return so
            format "%q", so
        addtocart = (value, table_name, indent, saved = {}, field = table_name) ->
            cart ..= indent .. field
            if type(value) != "table"
                cart ..= " = " .. basicSerialize(value) .. ";\n"
            else
                if saved[value]
                    cart ..= " = {}; -- #{saved[value]}(self reference)\n"
                    autoref ..= "#{table_name} = #{saved[value]};\n"
                else
                    saved[value] = table_name
                    if isemptytable(value)
                        cart ..= " = {};\n"
                    else
                        cart ..= " = {\n"
                        for k, v in pairs value
                            k = basicSerialize(k)
                            fname = "#{table_name}[ #{k} ]"
                            field = "[ #{k} ]"
                            addtocart v, fname, indent .. "	", saved, field
                        cart = "#{cart}#{indent}};\n"
        return "#{table_name} = #{basicSerialize(@t)}" if type(@t) != "table"
        addtocart @t, table_name, indent
        return cart .. autoref

-- simplify polylines to bezier segments
-- Copyright (c) 2015 Yuhta Nakajima --> https://github.com/ynakajima/polyline2bezier
class l2b

    bezier_segments = {}

    new: (x, y) =>
        @x = type(x) == "number" and x or 0
        @y = type(y) == "number" and y or 0

    Point: (x, y) => l2b(x, y)
    v2SquaredLength: (a) => (a.x * a.x) + (a.y * a.y)
    v2Length: (a) => math.sqrt(@v2SquaredLength(a))

    v2Negate: (v) =>
        result = @Point!
        result.x = -v.x
        result.y = -v.y
        return result

    v2Normalize: (v) =>
        result = @Point!
        len = @v2Length(v)
        if len != 0
            result.x = v.x / len
            result.y = v.y / len
        return result

    v2Scale: (v, newlen) =>
        result = @Point!
        len = @v2Length(v)
        if len != 0
            result.x = v.x * newlen / len
            result.y = v.y * newlen / len
        return result

    v2Add: (a, b) =>
        c = @Point!
        c.x = a.x + b.x
        c.y = a.y + b.y
        return c

    v2Dot: (a, b) => (a.x * b.x) + (a.y * b.y)

    v2DistanceBetween2Points: (a, b) =>
        dx = a.x - b.x
        dy = a.y - b.y
        return math.sqrt((dx * dx) + (dy * dy))

    v2AddII: (a, b) =>
        c = @Point!
        c.x = a.x + b.x
        c.y = a.y + b.y
        return c

    v2ScaleIII: (v, s) =>
        result = @Point!
        result.x = v.x * s
        result.y = v.y * s
        return result

    v2SubII: (a, b) =>
        c = @Point!
        c.x = a.x - b.x
        c.y = a.y - b.y
        return c

    computeMaxError: (d, first, last, bezCurve, u, splitPoint) =>
        P = @Point!
        v = @Point!
        splitPoint = (last - first + 1) / 2
        maxDist = 0
        for i = first + 1, last
            P = @bezierII(3, bezCurve, u[i - first])
            v = @v2SubII(P, d[i])
            dist = @v2SquaredLength(v)
            if dist >= maxDist
                maxDist = dist
                splitPoint = i
        return {
            maxError: maxDist
            splitPoint: splitPoint
        }

    chordLengthParameterize: (d, first, last) =>
        u = {}
        u[0] = 0
        for i = first + 1, last
            u[i - first] = u[i - first - 1] + @v2DistanceBetween2Points(d[i], d[i - 1])
        for i = first + 1, last
            u[i - first] = u[i - first] / u[last - first]
        return u

    computeCenterTangent: (d, center) =>
        V1 = @Point!
        V2 = @Point!
        tHatCenter = @Point!
        V1 = @v2SubII(d[center - 1], d[center])
        V2 = @v2SubII(d[center], d[center + 1])
        tHatCenter.x = (V1.x + V2.x) / 2
        tHatCenter.y = (V1.y + V2.y) / 2
        tHatCenter = @v2Normalize(tHatCenter)
        return tHatCenter

    computeLeftTangent: (d, __end) =>
        tHat1 = @Point!
        tHat1 = @v2SubII(d[__end + 1], d[__end])
        tHat1 = @v2Normalize(tHat1)
        return tHat1

    computeRightTangent: (d, __end) =>
        tHat2 = @Point!
        tHat2 = @v2SubII(d[__end - 1], d[__end])
        tHat2 = @v2Normalize(tHat2)
        return tHat2

    B0: (u) => (1 - u) * (1 - u) * (1 - u)
    B1: (u) => 3 * u * ((1 - u) * (1 - u))
    B2: (u) => 3 * u * u * (1 - u)
    B3: (u) => u * u * u

    bezierII: (degree, V, t) =>
        Vtemp = {}
        for i = 0, degree
            Vtemp[i] = @Point(V[i].x, V[i].y)
        for i = 1, degree
            for j = 0, (degree - i)
                Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
                Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y
        return @Point(Vtemp[0].x, Vtemp[0].y)

    newtonRaphsonRootFind: (_Q, _P, u) =>
        Q1 = {
            [0]: @Point!
            [1]: @Point!
            [2]: @Point!
        }
        Q2 = {
            [0]: @Point!
            [1]: @Point!
        }
        Q = {
            [0]: @Point(_Q[0].x, _Q[0].y)
            [1]: @Point(_Q[1].x, _Q[1].y)
            [2]: @Point(_Q[2].x, _Q[2].y)
            [3]: @Point(_Q[3].x, _Q[3].y)
        }
        P = @Point(_P.x, _P.y)
        Q_u = @bezierII(3, Q, u)
        for i = 0, 2
            Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
            Q1[i].y = (Q[i + 1].y - Q[i].y) * 3
        for i = 0, 1
            Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
            Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2
        Q1_u = @bezierII(2, Q1, u)
        Q2_u = @bezierII(1, Q2, u)
        numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
        denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)
        return u if denominator == 0
        uPrime = u - (numerator / denominator)
        return uPrime

    reparameterize: (d, first, last, u, bezCurve) =>
        uPrime = {}
        _bezCurve = {
            [0]: @Point(bezCurve[0].x, bezCurve[0].y),
            [1]: @Point(bezCurve[1].x, bezCurve[1].y),
            [2]: @Point(bezCurve[2].x, bezCurve[2].y),
            [3]: @Point(bezCurve[3].x, bezCurve[3].y)
        }
        for i = first, last
            uPrime[i - first] = @newtonRaphsonRootFind(_bezCurve, d[i], u[i - first])
        return uPrime

    generateBezier: (d, first, last, uPrime, tHat1, tHat2) =>
        A, C, X = {}, {[0]: {[0]: 0, 0}, {[0]: 0, 0}}, {[0]: 0, 0}
        tmp = @Point!
        bezCurve = {}
        nPts = last - first + 1
        for i = 0, nPts - 1
            v1 = @Point(tHat1.x, tHat1.y)
            v2 = @Point(tHat2.x, tHat2.y)
            v1 = @v2Scale(v1, @B1(uPrime[i]))
            v2 = @v2Scale(v2, @B2(uPrime[i]))
            A[i] = {[0]: v1, v2}
        for i = 0, nPts - 1
            C[0][0] += @v2Dot(A[i][0], A[i][0])
            C[0][1] += @v2Dot(A[i][0], A[i][1])
            C[1][0] = C[0][1]
            C[1][1] += @v2Dot(A[i][1], A[i][1])
            tmp = @v2SubII(d[first + i], @v2AddII(@v2ScaleIII(d[first], @B0(uPrime[i])), @v2AddII(@v2ScaleIII(d[first], @B1(uPrime[i])), @v2AddII(@v2ScaleIII(d[last], @B2(uPrime[i])), @v2ScaleIII(d[last], @B3(uPrime[i]))))))
            X[0] += @v2Dot(A[i][0], tmp)
            X[1] += @v2Dot(A[i][1], tmp)
        det_C0_C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1]
        det_C0_X  = C[0][0] * X[1] - C[1][0] * X[0]
        det_X_C1  = X[0] * C[1][1] - X[1] * C[0][1]
        alpha_l = (det_C0_C1 == 0) and 0 or det_X_C1 / det_C0_C1
        alpha_r = (det_C0_C1 == 0) and 0 or det_C0_X / det_C0_C1
        segLength = @v2DistanceBetween2Points(d[last], d[first])
        epsilon = 0.000001 * segLength
        if (alpha_l < epsilon) or (alpha_r < epsilon)
            dist = segLength / 3
            bezCurve[0] = d[first]
            bezCurve[3] = d[last]
            bezCurve[1] = @v2Add(bezCurve[0], @v2Scale(tHat1, dist))
            bezCurve[2] = @v2Add(bezCurve[3], @v2Scale(tHat2, dist))
            return bezCurve
        bezCurve[0] = d[first]
        bezCurve[3] = d[last]
        bezCurve[1] = @v2Add(bezCurve[0], @v2Scale(tHat1, alpha_l))
        bezCurve[2] = @v2Add(bezCurve[3], @v2Scale(tHat2, alpha_r))
        return bezCurve

    fitCubic: (d, first, last, tHat1, tHat2, ____error) =>
        u, uPrime = {}, {}
        maxIterations = 4
        tHatCenter = @Point!
        iterationError = ____error * ____error
        nPts = last - first + 1
        if nPts == 2
            dist = @v2DistanceBetween2Points(d[last], d[first]) / 3
            bezCurve = {}
            bezCurve[0] = d[first]
            bezCurve[3] = d[last]
            tHat1 = @v2Scale(tHat1, dist)
            tHat2 = @v2Scale(tHat2, dist)
            bezCurve[1] = @v2Add(bezCurve[0], tHat1)
            bezCurve[2] = @v2Add(bezCurve[3], tHat2)
            @drawBezierCurve(3, bezCurve)
            return
        u = @chordLengthParameterize(d, first, last)
        bezCurve = @generateBezier(d, first, last, u, tHat1, tHat2)
        resultMaxError = @computeMaxError(d, first, last, bezCurve, u, splitPoint)
        maxError = resultMaxError.maxError
        splitPoint = resultMaxError.splitPoint
        if maxError < ____error
            @drawBezierCurve(3, bezCurve)
            return
        if maxError < iterationError
            for i = 0, maxIterations
                uPrime = @reparameterize(d, first, last, u, bezCurve)
                bezCurve = @generateBezier(d, first, last, uPrime, tHat1, tHat2)
                resultMaxError = @computeMaxError(d, first, last, bezCurve, uPrime, splitPoint)
                maxError = resultMaxError.maxError
                splitPoint = resultMaxError.splitPoint
                if maxError < ____error
                    @drawBezierCurve(3, bezCurve)
                    return
                u = uPrime
        tHatCenter = @computeCenterTangent(d, splitPoint)
        @fitCubic(d, first, splitPoint, tHat1, tHatCenter, ____error)
        tHatCenter = @v2Negate(tHatCenter)
        @fitCubic(d, splitPoint, last, tHatCenter, tHat2, ____error)
        return

    fitCurve: (d, nPts, ____error) =>
        tHat1 = @Point!
        tHat2 = @Point!
        tHat1 = @computeLeftTangent(d, 0)
        tHat2 = @computeRightTangent(d, nPts - 1)
        @fitCubic(d, 0, nPts - 1, tHat1, tHat2, ____error)
        return

    drawBezierCurve: (n, curve) =>
        table.insert(bezier_segments, curve)
        return

    polyline2bezier: (polyline, ____error = 1) =>
        d, bezier_segments = {}, {}
        for i = 1, #polyline
            d[i - 1] = @Point(polyline[i].x, polyline[i].y)
        @fitCurve(d, #d + 1, ____error)
        return bezier_segments

    solution: (paths, dist = 3, ____error) =>
        assert type(paths) == "table", "paths expected"
        get_dist = (points) ->
            points[0] = points[2]
            state = @v2DistanceBetween2Points(points[1], points[2]) <= dist
            inpack = {}
            for i = 1, #points
                if @v2DistanceBetween2Points(points[i], points[i - 1]) <= dist == state
                    inpack[#inpack + 1] = {bezier: state and "ok" or nil}
                    state = not state
                inpack[#inpack][#inpack[#inpack] + 1] = points[i]
            for i = 1, #inpack - 1
                unless inpack[i].bezier
                    table.insert(inpack[i + 1], 1, inpack[i][#inpack[i]])
                    inpack[i][#inpack[i]] = nil
            return inpack
        make_solution = (dist) ->
            build_solution = (path, line) ->
                build = ""
                if line
                    for k = 1, #path
                        x1, y1 = MATH\round(path[k].x), MATH\round(path[k].y)
                        build ..= k < 3 and "l #{x1} #{y1} " or "#{x1} #{y1} "
                    return build
                else
                    x0, y0 = MATH\round(path[1][0].x), MATH\round(path[1][0].y)
                    for k = 1, #path
                        x1, y1 = MATH\round(path[k][1].x), MATH\round(path[k][1].y)
                        x2, y2 = MATH\round(path[k][2].x), MATH\round(path[k][2].y)
                        x3, y3 = MATH\round(path[k][3].x), MATH\round(path[k][3].y)
                        build ..= "b #{x1} #{y1} #{x2} #{y2} #{x3} #{y3} "
                    return "l #{x0} #{y0} #{build}"
            for k = 1, #paths
                paths[k] = get_dist(paths[k])
                for j = 1, #paths[k]
                    paths[k][j] = paths[k][j].bezier and build_solution(@polyline2bezier(paths[k][j], ____error)) or build_solution(paths[k][j], true)
                paths[k] = table.concat paths[k]
                paths[k] = paths[k]\gsub "l", "m", 1
            return table.concat paths
        return make_solution dist

-- simplify polylines
-- Copyright (c) 2017, Vladimir Agafonkin --> https://github.com/mourner/simplify-js
class l2l

    getSqDist: (p1, p2) =>
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        return dx * dx + dy * dy

    getSqSegDist: (p, p1, p2) =>
        x, y = p1.x, p1.y
        dx, dy = p2.x - x, p2.y - y
        if dx != 0 or dy != 0
            t = ((p.x - x) * dx + (p.y - y) * dy) / (dx * dx + dy * dy)
            if t > 1
                x = p2.x
                y = p2.y
            elseif t > 0
                x += dx * t
                y += dy * t
        dx = p.x - x
        dy = p.y - y
        return dx * dx + dy * dy

    simplifyRadialDist: (points, sqTolerance) =>
        local point
        prevPoint = points[1]
        newPoints = {prevPoint}
        for i = 2, #points
            point = points[i]
            if @getSqDist(point, prevPoint) > sqTolerance
                table.insert(newPoints, point)
                prevPoint = point
        table.insert(newPoints, point) if prevPoint != point
        return newPoints

    simplifyDPStep: (points, first, last, sqTolerance, simplified) =>
        local index
        maxSqDist = sqTolerance
        for i = first + 1, last
            sqDist = @getSqSegDist(points[i], points[first], points[last])
            if sqDist > maxSqDist
                index = i
                maxSqDist = sqDist
        if maxSqDist > sqTolerance
            @simplifyDPStep(points, first, index, sqTolerance, simplified) if index - first > 1
            table.insert(simplified, points[index])
            @simplifyDPStep(points, index, last, sqTolerance, simplified) if last - index > 1

    simplifyDouglasPeucker: (points, sqTolerance) =>
        simplified = {points[1]}
        @simplifyDPStep(points, 1, #points, sqTolerance, simplified)
        table.insert(simplified, points[#points])
        return simplified

    simplify: (points, tolerance, highestQuality = true, closed = true) =>
        return points if #points <= 2
        sqTolerance = tolerance != nil and tolerance * tolerance or 1
        points = highestQuality and points or @simplifyRadialDist(points, sqTolerance)
        points = @simplifyDouglasPeucker(points, sqTolerance)
        table.remove(points) unless closed
        return points

    solution: (points, tolerance = 0.1, highestQuality, closed) =>
        sol = [@simplify(v, tolerance, highestQuality, closed) for v in *points]
        shape = {}
        for i, part in ipairs sol
            shape[i] = ""
            for k, point in ipairs part
                x, y = MATH\round(point.x, dec), MATH\round(point.y, dec)
                shape[i] ..= k < 3 and "l #{x} #{y} " or "#{x} #{y} "
            shape[i] = shape[i]\gsub "l", "m", 1
        return table.concat shape

-- bezier curve implementation
-- https://en.wikipedia.org/wiki/B%C3%A9zier_curve
class BEZIER

    new: (...) => @paths = (type(...) == "table" and ... or {...})

    line: (t, b0, b1) => (1 - t) * b0 + t * b1
    quadratic: (t, b0, b1, b2) => (1 - t) ^ 2 * b0 + 2 * t * (1 - t) * b1 + t ^ 2 * b2
    cubic: (t, b0, b1, b2, b3) => (1 - t) ^ 3 * b0 + 3 * t * (1 - t) ^ 2 * b1 + 3 * t ^ 2 * (1 - t) * b2 + t ^ 3 * b3

    bernstein: (t, i, n) =>
        f = (n) ->
			k = 1
            for i = 2, n
                k *= i
			return k
        return f(n) / (f(i) * f(n - i)) * t ^ i * ((1 - t) ^ (n - i))

    -- returns a bezier at line points
    create: (len) =>
        len = MATH\round((not len and @len! or len), 0)
        pt, bz, pv = @paths, {}, {x: {}, y: {}}
        if #pt > 8
            for k = 1, #pt, 2
                pv.x[#pv.x + 1] = pt[k + 0]
                pv.y[#pv.y + 1] = pt[k + 1]
        for k = 0, len
            t = k / len
            switch #pt
                when 4
                    bz[#bz + 1] = {
                        @line(t, pt[1], pt[3])
                        @line(t, pt[2], pt[4])
                        typer: "l"
                    }
                when 6
                    bz[#bz + 1] = {
                        @quadratic(t, pt[1], pt[3], pt[5])
                        @quadratic(t, pt[2], pt[4], pt[6])
                        typer: "l"
                    }
                when 8
                    bz[#bz + 1] = {
                        @cubic(t, pt[1], pt[3], pt[5], pt[7])
                        @cubic(t, pt[2], pt[4], pt[6], pt[8])
                        typer: "l"
                    }
                else
                    px, py, n = 0, 0, #pv.x
                    for i = 1, n
                        b = @bernstein(t, i - 1, n - 1)
                        px += pv.x[i] * b
                        py += pv.y[i] * b
                    bz[#bz + 1] = {px, py, typer: "l"}
        return bz

    -- returns the length of a bezier segment
    len: (steps = 100) =>
        pt, pv, len = @paths, {x: {}, y: {}}, 0
        x, y = pt[1], pt[2]
        if #pt > 8
            for k = 1, #pt, 2
                pv.x[#pv.x + 1] = pt[k + 0]
                pv.y[#pv.y + 1] = pt[k + 1]
        for i = 0, steps
            t = i / steps
            local cx, cy, px, py, n
            switch #pt
                when 4
                    cx = @line(t, pt[1], pt[3], pt[5])
                    cy = @line(t, pt[2], pt[4], pt[6])
                when 6
                    cx = @quadratic(t, pt[1], pt[3], pt[5])
                    cy = @quadratic(t, pt[2], pt[4], pt[6])
                when 8
                    cx = @cubic(t, pt[1], pt[3], pt[5], pt[7])
                    cy = @cubic(t, pt[2], pt[4], pt[6], pt[8])
                else
                    px, py, n = 0, 0, #pv.x
                    for i = 1, n
                        b = @bernstein(t, i - 1, n - 1)
                        px += pv.x[i] * b
                        py += pv.y[i] * b
                    cx, cy = px, py
            ds = MATH\distance(x, y, cx, cy)
            x, y = cx, cy
            len += ds
        return len

class SHAPER

    new: (shape, closed = true) =>
        is_Number = (v) ->
            assert type(v) == "number", "unknown shape"
            return v
        is_String = (v) -> tonumber(v) == nil
        is_Equal = (x1, y1, x2, y2) -> true if x1 != x2 or y1 != y2
        @paths = {}
        if type(shape) == "string"
            shape = SUPPORT\clip_to_draw(shape)
            data = [is_String(v) and v or tonumber(v) for v in shape\gmatch "%S+"]
            for k = 1, #data
                if is_String(data[k])
                    switch data[k]
                        when "m"
                            p1 = is_Number(data[k + 1])
                            p2 = is_Number(data[k + 2])
                            @paths[#@paths + 1] = {
                                {typer: "m", p1, p2}
                            }
                        when "l"
                            i = 1
                            while type(data[k + i]) == "number"
                                p1 = is_Number(data[k + i + 0])
                                p2 = is_Number(data[k + i + 1])
                                @paths[#@paths][#@paths[#@paths] + 1] = {typer: "l", p1, p2}
                                i += 2
                        when "b"
                            i = 1
                            while type(data[k + i]) == "number"
                                p1 = is_Number(data[k + i + 0])
                                p2 = is_Number(data[k + i + 1])
                                p3 = is_Number(data[k + i + 2])
                                p4 = is_Number(data[k + i + 3])
                                p5 = is_Number(data[k + i + 4])
                                p6 = is_Number(data[k + i + 5])
                                @paths[#@paths][#@paths[#@paths] + 1] = {typer: "b", p1, p2, p3, p4, p5, p6}
                                i += 6
                        else
                            error "unknown shape"
            if closed
                for k, v in ipairs @paths
                    xf, yf = v[1][1], v[1][2]
                    xl, yl = v[#v][#v[#v] - 1], v[#v][#v[#v]]
                    v[#v + 1] = {typer: "l", xf, yf} if is_Equal(xf, yf, xl, yl)
        else
            @paths = shape.paths or shape
        return @

    -- splits the segments of the shape into small parts
    split: (size = 1, seg = "all", len_t) =>
        add = {}
        for i = 1, #@paths
            add[i] = {}
            switch seg
                when "line"
                    for j = 1, #@paths[i]
                        if @paths[i][j].typer == "l"
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 0])
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 1])
                            --
                            bz = BEZIER(@paths[i][j])
                            bz = bz\create(not len_t and bz\len! / size or len_t)
                            for k = 1, #bz
                                continue if bz[k][1] != bz[k][1] -- skip nan
                                add[i][#add[i] + 1] = bz[k]
                        else
                            add[i][#add[i] + 1] = @paths[i][j]
                when "bezier"
                    for j = 1, #@paths[i]
                        if @paths[i][j].typer == "b"
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 0])
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 1])
                            --
                            bz = BEZIER(@paths[i][j])
                            bz = bz\create(not len_t and bz\len! / size or len_t)
                            for k = 1, #bz
                                continue if bz[k][1] != bz[k][1] -- skip nan
                                add[i][#add[i] + 1] = bz[k]
                        else
                            add[i][#add[i] + 1] = @paths[i][j]
                else -- when "all"
                    for j = 1, #@paths[i]
                        if @paths[i][j].typer != "m"
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 0])
                            table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 1])
                            --
                            bz = BEZIER(@paths[i][j])
                            bz = bz\create(not len_t and bz\len! / size or len_t)
                            for k = 1, #bz
                                continue if bz[k][1] != bz[k][1] -- skip nan
                                add[i][#add[i] + 1] = bz[k]
                        else
                            add[i][#add[i] + 1] = @paths[i][j]
        @paths = add
        return @

    -- returns the shape bounding box
    bounding: (shaper) =>
        local l, t, r, b, n
        n = 0
        @filter (x, y) ->
            if l
                l, t, r, b = min(l, x), min(t, y), max(r, x), max(b, y)
            else
                l, t, r, b = x, y, x, y
            n += 1
            return x, y
        if shaper
            return ("m %s %s l %s %s l %s %s l %s %s ")\format(l, t, r, t, r, b, l, b), l, t, r, b, n
        return l, t, r, b, n

    -- gets shape infos
    info: =>
        export minx, miny, maxx, maxy, n_points = @bounding!
        export w_shape, h_shape = maxx - minx, maxy - miny
        export c_shape, m_shape = minx + w_shape / 2, miny + h_shape / 2
        return @

    -- makes transformations through the shape points
    filter: (fils = (x, y) -> x, y) =>
        fils = (type(fils) != "table" and {fils} or fils)
        for f in *fils
            for m in *@paths
                for p in *m
                    for k = 1, #p, 2
                        p[k], p[k + 1] = f(p[k], p[k + 1])
        return @

    -- moves shape points
    displace: (px = 0, py = 0) =>
        @filter (x, y) ->
            x += px
            y += py
            return x, y
        return @

    -- scales shape points
    scale: (sx = 100, sy = 100) =>
        @filter (x, y) ->
            x *= sx / 100
            y *= sy / 100
            return x, y
        return @

    -- rotates shape points
    rotate: (angle, cx, cy) =>
        @info!
        cx or= c_shape
        cy or= m_shape
        r = rad(angle)
        @filter (x, y) ->
            rx = cos(r) * (x - cx) - sin(r) * (y - cy) + cx
            ry = sin(r) * (x - cx) + cos(r) * (y - cy) + cy
            return rx, ry
        return @

    -- moves the shape points to their origin
    origin: (min) =>
        @info!
        @displace(-minx, -miny)
        return @, minx, miny if min
        return @

    -- moves the shape points to their center
    to_center: (min) =>
        @origin!
        @displace(-w_shape / 2, -h_shape / 2)
        return @

    -- moves the points of the shape to the position relative to the alignment 7
    org_points: (an = 7) =>
        @info!
        w, h = w_shape, h_shape
        switch an
            when 1 then @displace(nil, -h)
            when 2 then @displace(-w / 2, -h)
            when 3 then @displace(-w, -h)
            when 4 then @displace(nil, -h / 2)
            when 5 then @displace(-w / 2, -h / 2)
            when 6 then @displace(-w, -h / 2)
            when 8 then @displace(-w / 2)
            when 9 then @displace(-w)
        return @

    -- moves the points of the shape to the relative position of the clip
    to_clip: (an = 7, px = 0, py = 0) =>
        @info!
        w, h = w_shape, h_shape
        switch an
            when 1 then @displace(px, py - h)
            when 2 then @displace(px - w / 2, py - h)
            when 3 then @displace(px - w, py - h)
            when 4 then @displace(px, py - h / 2)
            when 5 then @displace(px - w / 2, py - h / 2)
            when 6 then @displace(px - w, py - h / 2)
            when 7 then @displace(px, py)
            when 8 then @displace(px - w / 2, py)
            when 9 then @displace(px - w, py)
        return @

    -- moves the clip points to the relative position of the shape
    unclip: (an = 7, px = 0, py = 0) =>
        @info!
        w, h = w_shape, h_shape
        switch an
            when 1 then @displace(-px, -py + h)
            when 2 then @displace(-px + w / 2, -py + h)
            when 3 then @displace(-px + w, -py + h)
            when 4 then @displace(-px, -py + h / 2)
            when 5 then @displace(-px + w / 2, -py + h / 2)
            when 6 then @displace(-px + w, -py + h / 2)
            when 7 then @displace(-px, -py)
            when 8 then @displace(-px + w / 2, -py)
            when 9 then @displace(-px + w, -py)
        return @

    -- generates a transformation in perspective
    -- http://jsfiddle.net/xjHUk/278/
    perspective: (destin) =>
        l, t, r, b = @bounding!
        source = {
            {x: l, y: t}
            {x: r, y: t}
            {x: r, y: b}
            {x: l, y: b}
        }
        destin or= {
            {x: l + 100, y: t}
            {x: r - 100, y: t}
            {x: r, y: b}
            {x: l, y: b}
        }
        @filter (xI, yI) ->
            add = 0.001 -- to avoid dividing by zero
            xA, yA   = source[1].x, source[1].y
            xC, yC   = source[3].x, source[3].y
            xAu, yAu = destin[1].x, destin[1].y
            xBu, yBu = destin[2].x, destin[2].y
            xCu, yCu = destin[3].x, destin[3].y
            xDu, yDu = destin[4].x, destin[4].y

            xCu += add if xBu == xCu
            xDu += add if xAu == xDu
            xBu += add if xAu == xBu
            xCu += add if xDu == xCu

            kBC = (yBu - yCu) / (xBu - xCu)
            kAD = (yAu - yDu) / (xAu - xDu)
            kAB = (yAu - yBu) / (xAu - xBu)
            kDC = (yDu - yCu) / (xDu - xCu)

            kAD += add if kBC == kAD
            xE = ((((kBC * xBu) - (kAD * xAu)) + yAu) - yBu) / (kBC - kAD)
            yE = (kBC * (xE - xBu)) + yBu

            kDC += add if kAB == kDC
            xF = ((((kAB * xBu) - (kDC * xCu)) + yCu) - yBu) / (kAB - kDC)
            yF = (kAB * (xF - xBu)) + yBu

            xF += add if xE == xF
            kEF = (yE - yF) / (xE - xF)

            kAB += add if kEF == kAB
            xG = ((((kEF * xDu) - (kAB * xAu)) + yAu) - yDu) / (kEF - kAB)
            yG = (kEF * (xG - xDu)) + yDu

            kBC += add if kEF == kBC
            xH = ((((kEF * xDu) - (kBC * xBu)) + yBu) - yDu) / (kEF - kBC)
            yH = (kEF * (xH - xDu)) + yDu
            rG = (yC - yI) / (yC - yA)
            rH = (xI - xA) / (xC - xA)
            xJ = ((xG - xDu) * rG) + xDu
            yJ = ((yG - yDu) * rG) + yDu
            xK = ((xH - xDu) * rH) + xDu
            yK = ((yH - yDu) * rH) + yDu

            xJ += add if xF == xJ
            xK += add if xE == xK
            kJF = (yF - yJ) / (xF - xJ)
            kKE = (yE - yK) / (xE - xK)

            kKE += add if kJF == kKE
            xIu = ((((kJF * xF) - (kKE * xE)) + yE) - yF) / (kJF - kKE)
            yIu = (kJF * (xIu - xJ)) + yJ
            return xIu, yIu
        return @

    -- transforms line points into bezier points
    to_bezier: =>
        for i = 1, #@paths
            for j = 1, #@paths[i]
                if @paths[i][j].typer == "l"
                    table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 0])
                    table.insert(@paths[i][j], 1, @paths[i][j - 1][#@paths[i][j - 1] - 1])
                    --
                    x1, y1 = @paths[i][j][1], @paths[i][j][2]
                    x2, y2 = @paths[i][j][3], @paths[i][j][4]
                    @paths[i][j] = {
                        typer: "b"
                        (2 * x1 + x2) / 3, (2 * y1 + y2) / 3
                        (x1 + 2 * x2) / 3, (y1 + 2 * y2) / 3
                        x2, y2
                    }
        return @

    -- generates a Envelope Distortion transformation
    -- https://codepen.io/benjamminf/pen/LLmrKN
    envelope_distort: (ctrl_p1, ctrl_p2) =>
        @info!
        ctrl_p1 or= {
            {x: minx, y: miny},
            {x: maxx, y: miny},
            {x: maxx, y: maxy},
            {x: minx, y: maxy},
        }
        ctrl_p2 or= {
            {x: minx - 100, y: miny},
            {x: maxx + 100, y: miny},
            {x: maxx, y: maxy},
            {x: minx, y: maxy},
        }
        isNaN = (v) -> type(v) == "number" and v != v -- checks if the number is nan
        assert #ctrl_p1 == #ctrl_p2, "The control points must have the same quantity!"
        -- to avoid dividing by zero
        ctrl_b = 0.1
        for i = 1, #ctrl_p1
            ctrl_p1[i].x -= ctrl_b if ctrl_p1[i].x == minx
            ctrl_p1[i].y -= ctrl_b if ctrl_p1[i].y == miny
            ctrl_p1[i].x += ctrl_b if ctrl_p1[i].x == maxx
            ctrl_p1[i].y += ctrl_b if ctrl_p1[i].y == maxy
            --
            ctrl_p2[i].x -= ctrl_b if ctrl_p2[i].x == minx
            ctrl_p2[i].y -= ctrl_b if ctrl_p2[i].y == miny
            ctrl_p2[i].x += ctrl_b if ctrl_p2[i].x == maxx
            ctrl_p2[i].y += ctrl_b if ctrl_p2[i].y == maxy
        @to_bezier!
        A, W, L, V1, V2 = {}, {}, nil, ctrl_p1, ctrl_p2
        @filter (x, y) ->
            -- Find Angles
            for i = 1, #V1
                j = i % #V1 + 1
                vi, vj = V1[i], V1[j]
                r0i = sqrt((x - vi.x) ^ 2 + (y - vi.y) ^ 2)
                r0j = sqrt((x - vj.x) ^ 2 + (y - vj.y) ^ 2)
                rij = sqrt((vi.x - vj.x) ^ 2 + (vi.y - vj.y) ^ 2)
                dn = 2 * r0i * r0j
                r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / dn
                A[i] = isNaN(r) and 0 or acos(max(-1, min(r, 1)))
            -- Find Weights
            for j = 1, #V1
                i = (j > 1 and j or #V1 + 1) - 1
                vj = V1[j]
                r = sqrt((vj.x - x) ^ 2 + (vj.y - y) ^ 2)
                W[j] = (tan(A[i] / 2) + tan(A[j] / 2)) / r
            -- Normalise Weights
            Ws = 0
            for k, v in ipairs(W) do Ws += v
            -- Reposition
            nx, ny = 0, 0
            for i = 1, #V1
                L = W[i] / Ws
                nx += L * V2[i].x
                ny += L * V2[i].y
            return nx, ny
        return @

    -- transforms the points from perspective tags [fax, fay...] 
    -- https://github.com/Alendt/Aegisub-Scripts
    expand: (line, meta) =>
        local pf
        pf = (sx = 100, sy = 100, p = 1) ->
            assert p > 0 or p == floor(p)
            if p == 1
                return sx / 100, sy / 100
            else
                p -= 1
                sx /= 2
                sy /= 2
                return pf(sx, sy, p)
        @org_points(line.styleref.align)
        data = SUPPORT\find_coords(line, meta, true)
        frx = pi / 180 * data.rots.frx
        fry = pi / 180 * data.rots.fry
        frz = pi / 180 * data.rots.frz
        sx, cx = -sin(frx), cos(frx)
        sy, cy =  sin(fry), cos(fry)
        sz, cz = -sin(frz), cos(frz)
        xscale, yscale = pf(data.scale.x, data.scale.y, data.p)
        fax = data.rots.fax * data.scale.x / data.scale.y
        fay = data.rots.fay * data.scale.y / data.scale.x
        x1 = {1, fax, data.pos.x - data.org.x}
        y1 = {fay, 1, data.pos.y - data.org.y}
        x2, y2 = {}, {}
        for i = 1, 3
            x2[i] = x1[i] * cz - y1[i] * sz
            y2[i] = x1[i] * sz + y1[i] * cz
        y3, z3 = {}, {}
        for i = 1, 3
            y3[i] = y2[i] * cx
            z3[i] = y2[i] * sx
        x4, z4 = {}, {}
        for i = 1, 3
            x4[i] = x2[i] * cy - z3[i] * sy
            z4[i] = x2[i] * sy + z3[i] * cy
        dist = 312.5
        z4[3] += dist
        offs_x = data.org.x - data.pos.x
        offs_y = data.org.y - data.pos.y
        matrix = [{} for k = 1, 3]
        for i = 1, 3
            matrix[1][i] = z4[i] * offs_x + x4[i] * dist
            matrix[2][i] = z4[i] * offs_y + y3[i] * dist
            matrix[3][i] = z4[i]
        @filter (x, y) ->
            v = [(matrix[m][1] * x * xscale) + (matrix[m][2] * y * yscale) + matrix[m][3] for m = 1, 3]
            w = 1 / max(v[3], 0.1)
            x = MATH\round(v[1] * w, 3)
            y = MATH\round(v[2] * w, 3)
            return x, y
        return @

    -- smooths the corners of a shape
    smooth_edges: (radius = 0) =>
        limit, add = {}, {}
        get_angle = (c, l) -> atan2(l[2] - c[2], l[1] - c[1])
        is_Equal = (p1, p2) -> p1.typer == "m" and p2.typer == "l" and p1[1] == p2[1] and p1[2] == p2[2]
        is_Corner = (p, j) ->
            if j
                p1, p2 = p[j], p[j + 1]
                p1.is_corner, p2.is_corner = true, true
                if p1.typer == "b"
                    p1.is_corner = false
                elseif p1.typer == "m" and p2 and p2.typer == "b"
                    p1.is_corner = false
                elseif p1.typer == "l" and p2 and p2.typer == "b"
                    p1.is_corner = false
                p[j] = p1
            else
                if p[#p].typer == "b"
                    p[1].is_corner = false
                    p[#p].is_corner = false
            return p
        for k = 1, #@paths
            limit[k] = {}
            table.remove(@paths[k]) if is_Equal(@paths[k][1], @paths[k][#@paths[k]])
            for j = 1, #@paths[k] - 1
                @paths[k] = is_Corner(@paths[k], j)
                for i = 1, #@paths[k][j], 2
                    if @paths[k][j].typer != "b"
                        p0, p1 = @paths[k][j], @paths[k][j + 1]
                        x0, y0 = p0[i], p0[i + 1]
                        x1, y1 = p1[i], p1[i + 1]
                        limit[k][#limit[k] + 1] = MATH\distance(x0, y0, x1, y1) / 2
            table.sort(limit[k], (a, b) -> a < b)
            @paths[k] = is_Corner(@paths[k])
        for k = 1, #@paths
            add[k] = {}
            -- Limits the smoothness to the smallest distance encountered
            r = limit[k][1] < radius and limit[k][1] or radius
            for j = 1, #@paths[k]
                if @paths[k][j].is_corner
                    -- index prev and next
                    p = j == 1 and #@paths[k] or j - 1
                    n = j == #@paths[k] and 1 or j + 1
                    -- angles first and last
                    af = get_angle(@paths[k][j], @paths[k][p])
                    al = get_angle(@paths[k][j], @paths[k][n])
                    -- px, py values
                    px = @paths[k][j][1]
                    py = @paths[k][j][2]
                    -- points values
                    x1 = px + r * cos(af)
                    y1 = py + r * sin(af)
                    x2 = px + r * cos(al)
                    y2 = py + r * sin(al)
                    -- control points values
                    pcx1, pcy1 = (x1 + 2 * px) / 3, (y1 + 2 * py) / 3
                    pcx2, pcy2 = (x2 + 2 * px) / 3, (y2 + 2 * py) / 3
                    -- adds the smooth
                    add[k][#add[k] + 1] = {typer: "l", x1, y1}
                    add[k][#add[k] + 1] = {typer: "b", pcx1, pcy1, pcx2, pcy2, x2, y2}
                else
                    add[k][#add[k] + 1] = @paths[k][j]
        @paths = add
        return @

    -- builds the shape
    build: (dec = 2) =>
        shape = {}
        for i = 1, #@paths
            shape[i] = {}
            for j = 1, #@paths[i]
                shape[i][j] = ""
                for k = 1, #@paths[i][j], 2
                    x, y = MATH\round(@paths[i][j][k], dec), MATH\round(@paths[i][j][k + 1], dec)
                    shape[i][j] ..= "#{x} #{y} "
                prev = @paths[i][j - 1]
                curr = @paths[i][j]
                shape[i][j] = prev and (prev.typer == curr.typer and shape[i][j]) or "#{curr.typer} #{shape[i][j]}"
            shape[i] = table.concat shape[i]
            shape[i] = shape[i]\find("l") == 1 and shape[i]\gsub("l", "m", 1) or shape[i]
        return table.concat shape

class POLY

    new: (subject, clip, simp, scale = 100) =>
        assert subject and (type(subject) == "string" or type(subject) == "table"), "subject expected"
        assert type(clip) == "string" or type(clip) == "table", "clip expected" if clip
        create_paths = (paths) ->
            create_path = (path) ->
                point = META.PATH.new!
                for p in *path
                    point\add(p[1], p[2])
                return point
            path = META.PATHS.new!
            for p in *paths
                path\add(create_path(p))
            return path
        subject = type(subject) == "string" and SHAPER(subject) or subject
        clip = clip and (type(clip) == "string" and SHAPER(clip) or clip) or nil
        @sbj = create_paths(subject\split(1, "bezier")\scale(scale * 100, scale * 100).paths)
        @clp = clip and create_paths(clip\split(1, "bezier")\scale(scale * 100, scale * 100).paths) or nil
        @smp = simp and (type(simp) != "string" and "full" or "") or nil
        @scl = scale

    -- removes useless vertices from a shape
    simplify: =>
        @sbj = type(@sbj) == "string" and POLY(@sbj).sbj or @sbj
        -- creates an external simplify --
        pc = META.CLIPPER.new!
        pc\add_paths(@sbj, "subject")
        @sbj = pc\execute("union", "even_odd")
        ----------------------------------
        return @

    -- creates a run for the clipper
    clipper: (fr = "even_odd", ct = "intersection") =>
        -- creates a clipper run --
        pc = META.CLIPPER.new!
        pc\add_paths(@sbj, "subject")
        pc\add_paths(@clp, "clip")
        @sbj = pc\execute(ct, fr)
        ---------------------------
        return @

    -- creates a run for clipper offset
    offset: (size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25) =>
        -- create clipper offset --
        po = META.OFFSET.new(mtl, act)
        @sbj = po\add_paths(@sbj, size * @scl, jt, et)
        --------------------------
        return @

    -- generates an outline of a shape
    to_outline: (size, jt = "Round", mode = "Center", mtl, act) =>
        assert size and size >= 0, "You need to add a size and it has to be bigger than 0."
        jt = jt\lower!
        size = mode == "Inside" and -size or size
        path = mode != "Center" and @simplify! or @
        path = POLY(path\build!)
        @smp or= "line"
        switch mode
            when "Outside"
                offs = @offset(size, jt, nil, mtl, act)
                @sbj = offs.sbj
                @clp = path.sbj
                oult = @clipper(nil, "difference")
                path.smp = @smp
                return oult, path
            when "Inside"
                offs = @offset(size, jt, nil, mtl, act)
                offs = POLY(offs\build!)
                @sbj = path.sbj
                @clp = offs.sbj
                oult = @clipper(nil, "difference")
                offs.smp = @smp
                return oult, offs
            when "Center"
                offs = @offset(size, jt, "closed_line", mtl, act)
                offs = POLY(offs\build!)
                @sbj = path.sbj
                @clp = offs.sbj
                oult = @clipper(nil, "difference")
                offs.smp = @smp
                return offs, oult

    -- cuts a shape through the \clip - \iclip tags
    clip: (iclip) =>
        @sbj = iclip and @clipper(nil, "difference").sbj or @clipper(nil, "intersection").sbj
        return @

    -- generates the result of a clipper library run
    get_solution: (shape) =>
        new = {}
        for i = 1, @sbj\size!
            new[i] = not shape and {} or ""
            path = @sbj\get(i)
            for k = 1, path\size!
                point = path\get(k)
                x = tonumber(point.x) / @scl
                y = tonumber(point.y) / @scl
                unless shape
                    new[i][k] = {:x, :y}
                else
                    new[i] ..= k < 3 and "l #{x} #{y} " or "#{x} #{y} "
            new[i] = not shape and new[i] or new[i]\gsub("l", "m", 1)
        return not shape and new or table.concat new

    build: (dec = 2, sc, tol = 1) =>
        @sbj = not sc and @sbj or @clp
        if type(@sbj) != "string"
            return switch @smp
                when "full"
                    l2b\solution(@get_solution!, tol)
                when "line"
                    l2l\solution(@get_solution!, tol / 10)
                else
                    @get_solution(true)
        return @sbj

class TEXT

    -- converts a text to shape
    to_shape: (line, text = line.text_stripped) =>
        val = {text: {}, shape: {}, w: {}, h: {}}
        while text != ""
            c, d = SUPPORT\headtail(text, "\\N")
            val.text[#val.text + 1] = c\match("^%s*(.-)%s*$")
            text = d
        style = {
            line.styleref.fontname
            line.styleref.bold
            line.styleref.italic
            line.styleref.underline
            line.styleref.strikeout
            line.styleref.fontsize
            line.styleref.scale_x / 100
            line.styleref.scale_y / 100
            line.styleref.spacing
        }
        for k = 1, #val.text
            font = Yutils.decode.create_font unpack(style)
            extents = font.text_extents val.text[k]
            val.shape[k] = font.text_to_shape(val.text[k])\gsub(" c", "")
            val.shape[k] = SHAPER(val.shape[k])\displace(0, (k - 1) * style[6] * style[8])\build!
            val.w[k], val.h[k] = tonumber(extents.width), tonumber(extents.height)
        return val

    -- converts a text to clip
    to_clip: (line, text = line.text_stripped, an = line.styleref.align, px = 0, py = 0) => -- converts your text into clip
        val = @to_shape(line, text)
        break_line, extra = (line.styleref.fontsize * line.styleref.scale_y / 100), 0
        for k = 1, #val.shape
            if val.text[k] == ""
                py -= break_line / 2
                extra -= break_line / 2
            val.shape[k] = switch an
                when 1 then SHAPER(val.shape[k])\displace(px, py - val.h[k] - break_line * (#val.shape - 1))\build!
                when 2 then SHAPER(val.shape[k])\displace(px - val.w[k] / 2, py - val.h[k] - break_line * (#val.shape - 1))\build!
                when 3 then SHAPER(val.shape[k])\displace(px - val.w[k], py - val.h[k] - break_line * (#val.shape - 1))\build!
                when 4 then SHAPER(val.shape[k])\displace(px, py - val.h[k] / 2 - break_line * (#val.shape - 1) / 2)\build!
                when 5 then SHAPER(val.shape[k])\displace(px - val.w[k] / 2, (py - val.h[k] / 2 - break_line * (#val.shape - 1) / 2))\build!
                when 6 then SHAPER(val.shape[k])\displace(px - val.w[k], py - val.h[k] / 2 - break_line * (#val.shape - 1) / 2)\build!
                when 7 then SHAPER(val.shape[k])\displace(px, py)\build!
                when 8 then SHAPER(val.shape[k])\displace(px - val.w[k] / 2, py)\build!
                when 9 then SHAPER(val.shape[k])\displace(px - val.w[k], py)\build!
        new_shape = table.concat(val.shape)
        new_shape = switch an
            when 1, 2, 3 then SHAPER(new_shape)\displace(0, -extra)\build!
            when 4, 5, 6 then SHAPER(new_shape)\displace(0, -extra / 2)\build!
        return new_shape

class SUPPORT

    -- interpolate n values
    interpolation: (pct = 0.5, tp = "number", ...) =>
        values = type(...) == "table" and ... or {...}
        -- interpolates two shape values if they have the same number of points
        interpolate_shape = (pct, f, l) ->
            fs = [tonumber(s) for s in f\gmatch "%-?%d[%.%d]*"]
            ls = [tonumber(s) for s in l\gmatch "%-?%d[%.%d]*"]
            assert #fs == #ls, "The shapes must have the same stitch length"
            j = 1
            f = f\gsub "%-?%d[%.%d]*", (s) ->
                s = MATH\round(SUPPORT\interpolation(pct, nil, fs[j], ls[j]), 2)
                j += 1
                return s
            return f
        -- interpolation type
        ipol_f = switch tp
            when "number" then interpolate
            when "color" then interpolate_color
            when "alpha" then interpolate_alpha
            when "shape" then interpolate_shape
        pct = clamp(pct, 0, 1) * (#values - 1)
        valor_i = values[floor(pct) + 1]
        valor_f = values[floor(pct) + 2] or values[floor(pct) + 1]
        return ipol_f(pct - floor(pct), valor_i, valor_f)

    -- readjusts the style values using values set on the line
    tags2styles: (subs, line) =>
        tags, vtext = "", line.text
        meta, styles = karaskel.collect_head subs
        for k = 1, styles.n
            styles[k].margin_l = line.margin_l if line.margin_l > 0
            styles[k].margin_r = line.margin_r if line.margin_r > 0
            styles[k].margin_v = line.margin_t if line.margin_t > 0
            styles[k].margin_v = line.margin_b if line.margin_b > 0
            if vtext\match "%b{}"
                tags = vtext\match "%b{}"
                styles[k].align     = tonumber tags\match "\\an%s*(%d)"             if tags\match "\\an%s*%d"
                styles[k].fontname  = tags\match "\\fn%s*([^\\}]*)"                 if tags\match "\\fn%s*[^\\}]*"
                styles[k].fontsize  = tonumber tags\match "\\fs%s*(%d[%.%d]*)"      if tags\match "\\fs%s*%d[%.%d]*"
                styles[k].scale_x   = tonumber tags\match "\\fscx%s*(%d[%.%d]*)"    if tags\match "\\fscx%s*%d[%.%d]*"
                styles[k].scale_y   = tonumber tags\match "\\fscy%s*(%d[%.%d]*)"    if tags\match "\\fscy%s*%d[%.%d]*"
                styles[k].spacing   = tonumber tags\match "\\fsp%s*(%-?%d[%.%d]*)"  if tags\match "\\fsp%s*%-?%d[%.%d]*"
                styles[k].outline   = tonumber tags\match "\\bord%s*(%d[%.%d]*)"    if tags\match "\\bord%s*%d[%.%d]*"
                styles[k].shadow    = tonumber tags\match "\\shad%s*(%d[%.%d]*)"    if tags\match "\\shad%s*%d[%.%d]*"
                styles[k].angle     = tonumber tags\match "\\frz?%s*(%-?%d[%.%d]*)" if tags\match "\\frz?%s*%-?%d[%.%d]*"
                styles[k].color1    = tags\match "\\1?c%s*(&?[Hh]%x+&?)"            if tags\match "\\1?c%s*&?[Hh]%x+&?"
                styles[k].color2    = tags\match "\\2c%s*(&?[Hh]%x+&?)"             if tags\match "\\2c%s*&?[Hh]%x+&?"
                styles[k].color3    = tags\match "\\3c%s*(&?[Hh]%x+&?)"             if tags\match "\\3c%s*&?[Hh]%x+&?"
                styles[k].color4    = tags\match "\\4c%s*(&?[Hh]%x+&?)"             if tags\match "\\4c%s*&?[Hh]%x+&?"
                styles[k].bold      = true                                          if tags\match "\\b%s*1"
                styles[k].italic    = true                                          if tags\match "\\i%s*1"
                styles[k].underline = true                                          if tags\match "\\u%s*1"
                styles[k].strikeout = true                                          if tags\match "\\s%s*1"
        return meta, styles

    -- find coordinates
    find_coords: (line, meta, ogp) =>
        coords = {
            pos:   {x: 0, y: 0}
            move:  {x1: 0, y1: 0, x2: 0, y2: 0}
            org:   {x: 0, y: 0}
            rots:  {frz: line.styleref.angle, fax: 0, fay: 0, frx: 0, fry: 0}
            scale: {x: line.styleref.scale_x, y: line.styleref.scale_y}
            p: 1
        }
        if meta
            an = line.styleref.align or 7
            switch an
                when 1
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = line.styleref.margin_l, meta.res_y - line.styleref.margin_v
                when 2
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y - line.styleref.margin_v
                when 3
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y - line.styleref.margin_v
                when 4
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, meta.res_y / 2
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, meta.res_y / 2
                    coords.org.x, coords.org.y = line.styleref.margin_l, meta.res_y / 2
                when 5
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), meta.res_y / 2
                when 6
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, meta.res_y / 2
                when 7
                    coords.pos.x, coords.pos.y = line.styleref.margin_l, line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = line.styleref.margin_l, line.styleref.margin_v
                    coords.org.x, coords.org.y = line.styleref.margin_l, line.styleref.margin_v
                when 8
                    coords.pos.x, coords.pos.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2), line.styleref.margin_v
                when 9
                    coords.pos.x, coords.pos.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
                    coords.move.x1, coords.move.y1 = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
                    coords.org.x, coords.org.y = meta.res_x - line.styleref.margin_r, line.styleref.margin_v
        if line.text\match "%b{}"
            if line.text\match "\\p%s*%d"
                p = line.text\match "\\p%s*(%d)"
                coords.p = tonumber p
            if line.text\match "\\frx%s*%-?%d[%.%d]*"
                frx = line.text\match "\\frx%s*(%-?%d[%.%d]*)"
                coords.rots.frx = tonumber frx
            if line.text\match "\\fry%s*%-?%d[%.%d]*"
                fry = line.text\match "\\fry%s*(%-?%d[%.%d]*)"
                coords.rots.fry = tonumber fry
            if line.text\match "\\fax%s*%-?%d[%.%d]*"
                fax = line.text\match "\\fax%s*(%-?%d[%.%d]*)"
                coords.rots.fax = tonumber fax
            if line.text\match "\\fay%s*%-?%d[%.%d]*"
                fay = line.text\match "\\fay%s*(%-?%d[%.%d]*)"
                coords.rots.fay = tonumber fay
            if line.text\match "\\pos%b()"
                px, py = line.text\match "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
                coords.pos.x = tonumber px
                coords.pos.y = tonumber py
                if ogp
                    coords.org.x = tonumber px
                    coords.org.y = tonumber py
            if line.text\match "\\move%b()"
                x1, y1, x2, y2, t1, t2 = line.text\match "\\move%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*"
                coords.move.x1 = tonumber x1
                coords.move.y1 = tonumber y1
                coords.move.x2 = tonumber x2
                coords.move.y2 = tonumber y2
                coords.pos.x   = tonumber x1
                coords.pos.y   = tonumber y1
            if line.text\match "\\org%b()"
                ox, oy = line.text\match "\\org%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
                coords.org.x = tonumber ox
                coords.org.y = tonumber oy
        return coords

    -- transforms html colors to rgb or the other way around
    html_color: (color, mode = "to_rgb") =>
        c = color
        switch mode
            when "to_rgb"
                color = color\gsub "(%x%x)(%x%x)(%x%x)", (b, g, r) ->
                    c = "&H#{r}#{g}#{b}&"
            when "to_html"
                rgb_color = util.color_from_style(rgb_color)
                rgb_color = rgb_color\gsub "&?[hH](%x%x)(%x%x)(%x%x)&?", (r, g, b) ->
                    c = "##{b}#{g}#{r}"
        return c

    -- gets the clip content
    clip_to_draw: (clip) =>
        local shape, caps
        caps = {
            v: "\\i?clip%((m%s+%-?%d[%.%-%d mlb]*)%)"
            r: "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        }
        if clip\match "\\i?clip%b()"
            if not clip\match caps.v
                l, t, r, b = clip\match caps.r
                shape = "m #{l} #{t} l #{r} #{t} l #{r} #{b} l #{l} #{b}"
            else
                shape = clip\match caps.v
        else
            shape = clip
        return shape

    -- gets the previous and upper value of the text division
    headtail: (s, div) =>
        a, b, head, tail = s\find("(.-)#{div}(.*)")
        if a then head, tail else s, ""

class CONFIG

    -- checks if a file or folder exists
    file_exist: (file, dir) =>
        file ..= "/" if dir
        ok, err, code = os.rename(file, file)
        unless ok
            return true if code == 13
        return ok, err

    -- gets the values line by line from the file
    read: (filename) =>
        split = (t) ->
            s = {n: {}, v: {}}
            for k = 1, #t
                s.n[k] = t[k]\gsub "(.+) %= .+", "%1"
                s.v[s.n[k]] = t[k]\gsub ".+ %= (.+)", "%1"
            return s
        if filename
            arq = io.open filename, "r"
            if arq != nil
                read = arq\read "*a"
                arq\close!
                lines = [k for k in read\gmatch "%{([^\n]+)%}"]
                return split(lines), true, #lines
        return _, false

    -- loads the lines contained in the saved file
    load: (GUI, macro_name) =>
        dir = aegisub.decode_path("?user") .. "\\zeref-cfg\\#{macro_name\lower!\gsub "%s", "_"}.cfg"
        read, has, len = @read dir
        new_gui = TABLE(GUI)\copy!
        if has
            for k, v in ipairs new_gui
                v.value = read.v[v.name] == "true" and true or read.v[v.name] if v.name
        return new_gui, read, len

    -- saves the contents of an interface to a file
    save: (GUI, elements, macro_name, macro_version) =>
        writing = "#{macro_name\upper!} - VERSION #{macro_version}\n\n"
        for k, v in ipairs GUI
            writing ..= "{#{v.name} = #{elements[v.name]}}\n" if v.name
        dir = aegisub.decode_path "?user"
        if not @file_exist "#{dir}\\zeref-cfg", true
            os.execute "mkdir #{dir}\\zeref-cfg"
        save = "#{dir}\\zeref-cfg\\#{macro_name\lower!\gsub "%s", "_"}.cfg"
        file = io.open save, "w"
        file\write writing
        file\close!
        return

class TAGS

    new: (tags) => @tags = tags

    -- returns the contents of a tag
    find: => if @tags\match("%b{}") then @tags\match("%b{}")\sub(2, -2) else ""

    -- cleans the tags
    clean: (text) =>
        require "cleantags"
        return cleantags(text)

    -- removes some tags by need
    remove: (modes = "full", tags) =>
        @tags = tags or @find!
        caps = {
            fn: "\\fn%s*[^\\}]*",               fs: "\\fs%s*%d[%.%d]*",          fsp: "\\fsp%s*%-?%d[%.%d]*"
            fscx: "\\fscx%s*%d[%.%d]*",         fscy: "\\fscy%s*%d[%.%d]*",      b: "\\b%s*%d"
            i: "\\i%s*%d",                      s: "\\s%s*%d",                   u: "\\u%s*%d"
            p: "\\p%s*%d",                      an: "\\an%s*%d",                 fr: "\\frz?%s*%-?%d+[%.%d]*"
            frx: "\\frx%s*%-?%d+[%.%d]*",       fry: "\\fry%s*%-?%d+[%.%d]*",    fax: "\\fax%s*%-?%d+[%.%d]*"
            fay: "\\fay%s*%-?%d+[%.%d]*",       pos: "\\pos%b()",                org: "\\org%b()"
            _1c: "\\1?c%s*&?[Hh]%x+&?",         _2c: "\\2c%s*&?[Hh]%x+&?",       _3c: "\\3c%s*&?[Hh]%x+&?"
            _4c: "\\4c%s*&?[Hh]%x+&?",          bord: "\\[xy]?bord%s*%d[%.%d]*", clip: "\\i?clip%b()"
            shad: "\\[xy]?shad%s*%-?%d[%.%d]*", move:"\\move%b()",               transform: "\\t%b()"
        }
        switch modes
            when "shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")
                @tags = @tags\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_poly"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.an, "\\an7")\gsub(caps.b, "")\gsub(caps.i, "")
                @tags = @tags\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1"  unless @tags\match(caps.p)
            when "shape_gradient"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.bord, "\\bord0")\gsub(caps._1c, "")\gsub(caps.b, "")
                @tags = @tags\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags = @tags\gsub(caps.shad, "\\shad0")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\shad0" unless @tags\match(caps.shad)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
            when "text_shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")\gsub(caps.b, "")
                @tags = @tags\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\fscx100" unless @tags\match(caps.fscx)
                @tags ..= "\\fscy100" unless @tags\match(caps.fscy)
                @tags ..= "\\p1"      unless @tags\match(caps.p)
            when "shape_clip"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.b, "")\gsub(caps.i, "")
                @tags = @tags\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "text_clip"
                @tags = @tags\gsub(caps.clip, "")
            when "shape_expand"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.frx, "")\gsub(caps.fry, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")
                @tags = @tags\gsub(caps.u, "")\gsub(caps.fay, "")\gsub(caps.fax, "")
                @tags = @tags\gsub(caps.org, "")\gsub(caps.an, "\\an7")\gsub(caps.p, "\\p1")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1"  unless @tags\match(caps.p)
            when "full"
                @tags = @tags\gsub("%b{}", "")\gsub("\\h", " ")
            when "bezier_text"
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.pos, "")\gsub(caps.move, "")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.fsp, "")\gsub(caps.transform, "")
            when "out"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps._1c, "")\gsub(caps.bord, "\\bord0")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
        return @tags

-- enums
clip_type = {intersection: 0, union: 1, difference: 2, xor: 3}
join_type = {square: 0, round: 1, miter: 2}
end_type  = {closed_polygon: 0, closed_line: 1, open_butt: 2, open_square: 3, open_round: 4}
poly_type = {subject: 0, clip: 1}
fill_type = {none: 0, even_odd: 1, non_zero: 2, positive: 3, negative: 4}

-- path objects
META.PATH.new = -> ffi.gc(CPP.zf_path_new!, CPP.zf_path_free)
META.PATH.add = (self, x, y) -> CPP.zf_path_add(self, x, y)
META.PATH.get = (self, i) -> CPP.zf_path_get(self, i - 1)
META.PATH.size = (self) -> CPP.zf_path_size(self)

-- paths objects
META.PATHS.new = -> ffi.gc(CPP.zf_paths_new!, CPP.zf_paths_free)
META.PATHS.add = (self, path) -> CPP.zf_paths_add(self, path)
META.PATHS.get = (self, i) -> CPP.zf_paths_get(self, i - 1)
META.PATHS.size = (self) -> CPP.zf_paths_size(self)

-- offset objects
META.OFFSET.new = (ml = 2, at = 0.25) ->
    co = CPP.zf_offset_new(ml, at)
    ffi.gc(co, CPP.zf_offset_free)

META.OFFSET.add_path = (self, path, delta, jt = "square", et = "open_butt") ->
    out = CPP.zf_offset_path(self, path, delta, join_type[jt], end_type[et])
    assert out, ffi.string(CPP.zf_err_msg!)
    return out

META.OFFSET.add_paths = (self, paths, delta, jt = "square", et = "open_butt") ->
    out = CPP.zf_offset_paths(self, paths, delta, join_type[jt], end_type[et])
    assert out, ffi.string(CPP.zf_err_msg!)
    return out

-- clipper objects
META.CLIPPER.new = (...) -> ffi.gc(CPP.zf_clipper_new!, CPP.zf_clipper_free)

META.CLIPPER.add_path = (self, path, pt, closed = true) -> CPP.zf_clipper_add_path(self, path, poly_type[pt], closed, err)

META.CLIPPER.add_paths = (self, paths, pt, closed = true) ->
    error ffi.string(CPP.zf_err_msg!) unless CPP.zf_clipper_add_paths(self, paths, poly_type[pt], closed, err)

META.CLIPPER.execute = (self, ct, sft = "even_odd", cft = "even_odd") ->
    out = CPP.zf_clipper_execute(self, clip_type[ct], fill_type[sft], fill_type[cft])
    assert out, ffi.string(CPP.zf_err_msg!)
    return out

ffi.metatype "zf_path",    {__index: META.PATH}
ffi.metatype "zf_paths",   {__index: META.PATHS}
ffi.metatype "zf_offset",  {__index: META.OFFSET}
ffi.metatype "zf_clipper", {__index: META.CLIPPER}

-- get types
color_8  = ffi.typeof "color_8"
color_8A = ffi.typeof "color_8A"
color_16 = ffi.typeof "color_16"
color_24 = ffi.typeof "color_24"
color_32 = ffi.typeof "color_32"
int_t    = ffi.typeof "int"
uint8pt  = ffi.typeof "uint8_t*"

META.COLOR_8.get_color_8  = (self) -> self
META.COLOR_8A.get_color_8 = (self) -> color_8(self.a)

META.COLOR_16.get_color_8 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return color_8(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14))

META.COLOR_24.get_color_8  = (self) -> color_8(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14))
META.COLOR_32.get_color_8  = META.COLOR_24.get_color_8
META.COLOR_8.get_color_8A  = (self) -> color_8A(self.a, 0)
META.COLOR_8A.get_color_8A = (self) -> self

META.COLOR_16.get_color_8A = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return color_8A(bit.rshift(39190 * r + 38469 * g + 14942 * b, 14), 0)

META.COLOR_24.get_color_8A = (self) -> color_8A(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), 0)
META.COLOR_32.get_color_8A = (self) -> color_8A(bit.rshift(4897 * self\get_r! + 9617 * self\get_g! + 1868 * self\get_b!, 14), self\get_a!)

META.COLOR_8.get_color_16 = (self) ->
    v = self\get_color_8!.a
    v5bit = bit.rshift(v, 3)
    return color_16(bit.lshift(v5bit, 11) + bit.lshift(bit.rshift(v, 0xFC), 3) + v5bit)

META.COLOR_8A.get_color_16 = META.COLOR_8.get_color_16
META.COLOR_16.get_color_16 = (self) -> self
META.COLOR_24.get_color_16 = (self) -> color_16(bit.lshift(bit.rshift(self.r, 0xF8), 8) + bit.lshift(bit.rshift(self.g, 0xFC), 3) + bit.rshift(self.b, 3))
META.COLOR_32.get_color_16 = META.COLOR_24.get_color_16

META.COLOR_8.get_color_24 = (self) ->
    v = self\get_color_8!
    return color_24(v.a, v.a, v.a)

META.COLOR_8A.get_color_24 = META.COLOR_8.get_color_24

META.COLOR_16.get_color_24 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return color_24(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2))

META.COLOR_24.get_color_24 = (self) -> self
META.COLOR_32.get_color_24 = (self) -> color_24(self.r, self.g, self.b)
META.COLOR_8.get_color_32  = (self) -> color_32(self.a, self.a, self.a, 0xFF)
META.COLOR_8A.get_color_32 = (self) -> color_32(self.a, self.a, self.a, self.alpha)

META.COLOR_16.get_color_32 = (self) ->
    r = bit.rshift(self.v, 11)
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    b = bit.rshift(self.v, 0x001F)
    return color_32(bit.lshift(r, 3) + bit.rshift(r, 2), bit.lshift(g, 2) + bit.rshift(g, 4), bit.lshift(b, 3) + bit.rshift(b, 2), 0xFF)

META.COLOR_24.get_color_32 = (self) -> color_32(self.r, self.g, self.b, 0xFF)
META.COLOR_32.get_color_32 = (self) -> self

META.COLOR_8.get_r = (self) -> self\get_color_8!.a
META.COLOR_8.get_g = META.COLOR_8.get_r
META.COLOR_8.get_b = META.COLOR_8.get_r
META.COLOR_8.get_a = (self) -> int_t(0xFF)

META.COLOR_8A.get_r = META.COLOR_8.get_r
META.COLOR_8A.get_g = META.COLOR_8.get_r
META.COLOR_8A.get_b = META.COLOR_8.get_r

META.COLOR_8A.get_a = (self) -> self.alpha

META.COLOR_16.get_r = (self) ->
    r = bit.rshift(self.v, 11)
    return bit.lshift(r, 3) + bit.rshift(r, 2)

META.COLOR_16.get_g = (self) ->
    g = bit.rshift(bit.rshift(self.v, 5), 0x3F)
    return bit.lshift(g, 2) + bit.rshift(g, 4)

META.COLOR_16.get_b = (self) ->
    b = bit.rshift(self.v, 0x001F)
    return bit.lshift(b, 3) + bit.rshift(b, 2)

META.COLOR_16.get_a = META.COLOR_8.get_a
META.COLOR_24.get_r = (self) -> self.r
META.COLOR_24.get_g = (self) -> self.g
META.COLOR_24.get_b = (self) -> self.b
META.COLOR_24.get_a = META.COLOR_8.get_a
META.COLOR_32.get_r = META.COLOR_24.get_r
META.COLOR_32.get_g = META.COLOR_24.get_g
META.COLOR_32.get_b = META.COLOR_24.get_b
META.COLOR_32.get_a = (self) -> self.alpha

META.BBF.get_rotation  = (self) -> bit.rshift(bit.band(0x0C, self.config), 2)
META.BBF.get_inverse   = (self) -> bit.rshift(bit.band(0x02, self.config), 1)
META.BBF.set_allocated = (self, allocated) -> self.config = bit.bor(bit.band(self.config, bit.bxor(0x01, 0xFF)), bit.lshift(allocated, 0))

META.BBF8.get_bpp  = (self) -> 8
META.BBF8A.get_bpp = (self) -> 8
META.BBF16.get_bpp = (self) -> 16
META.BBF24.get_bpp = (self) -> 24
META.BBF32.get_bpp = (self) -> 32

META.BBF.set_type = (self, type_id) -> self.config = bit.bor(bit.band(self.config, bit.bxor(0xF0, 0xFF)), bit.lshift(type_id, 4))

META.BBF.get_physical_coordinates = (self, x, y) ->
    return switch self\get_rotation!
        when 0 then x, y
        when 1 then self.w - y - 1, x
        when 2 then self.w - x - 1, self.h - y - 1
        when 3 then y, self.h - x - 1

META.BBF.get_pixel_p = (self, x, y) -> ffi.cast(self.data, ffi.cast(uint8pt, self.data) + self.pitch * y) + x

META.BBF.get_pixel = (self, x, y) ->
    px, py = self\get_physical_coordinates(x, y)
    color = self\get_pixel_p(px, py)[0]
    color = color\invert! if self\get_inverse! == 1
    return color

META.BBF.get_width  = (self) -> bit.band(1, self\get_rotation!) == 0 and self.w or self.h
META.BBF.get_height = (self) -> bit.band(1, self\get_rotation!) == 0 and self.h or self.w

for n, f in pairs META.BBF
    META.BBF8[n]  = f unless META.BBF8[n]
    META.BBF8A[n] = f unless META.BBF8A[n]
    META.BBF16[n] = f unless META.BBF16[n]
    META.BBF24[n] = f unless META.BBF24[n]
    META.BBF32[n] = f unless META.BBF32[n]

BUFFER8  = ffi.metatype "buffer_8",  {__index: META.BBF8}
BUFFER8A = ffi.metatype "buffer_8A", {__index: META.BBF8A}
BUFFER16 = ffi.metatype "buffer_16", {__index: META.BBF16}
BUFFER24 = ffi.metatype "buffer_24", {__index: META.BBF24}
BUFFER32 = ffi.metatype "buffer_32", {__index: META.BBF32}

ffi.metatype "color_8",  {__index: META.COLOR_8}
ffi.metatype "color_8A", {__index: META.COLOR_8A}
ffi.metatype "color_16", {__index: META.COLOR_16}
ffi.metatype "color_24", {__index: META.COLOR_24}
ffi.metatype "color_32", {__index: META.COLOR_32}

META.BUFFER = (width, height, buffertype = 1, dataptr, pitch) ->
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

class IMG

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
            buf = META.BUFFER width[0], height[0], 4
            format = JPG.TJPF_RGB
        else
            buf = META.BUFFER width[0], height[0], 1
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
        buf = META.BUFFER w[0], h[0], 5, ptr[0]
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
                    aegisub.progress.set 0 + 100 * i / (img.height * img.width - 1)
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
                    aegisub.progress.set 0 + 100 * i / (img.height * img.width - 1)
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
                aegisub.progress.task "Merging Shapes..."
                for k, v in pairs px
                    aegisub.progress.set 0 + 100 * (k - 1) / (#px - 1)
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
                aegisub.progress.set 0 + 100 * colornum / #ii.palette
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
            radius = math.floor(radius)
            return imgd if radius < 1
            radius = 5 if radius > 5
            delta = math.abs(delta)
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
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
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
                    imgd2.data[idx].r = math.floor(racc / wacc)
                    imgd2.data[idx].g = math.floor(gacc / wacc)
                    imgd2.data[idx].b = math.floor(bacc / wacc)
                    imgd2.data[idx].a = math.floor(aacc / wacc)
            -- Selective blur: loop through all pixels
            for j = 0, imgd.height - 1
                for i = 0, imgd.width - 1
                    idx = j * imgd.width + i
                    -- d is the difference between the blurred and the original pixel
                    d = math.abs(imgd2.data[idx].r - imgd.data[idx].r) + math.abs(imgd2.data[idx].g - imgd.data[idx].g) + math.abs(imgd2.data[idx].b - imgd.data[idx].b) + math.abs(imgd2.data[idx].a - imgd.data[idx].a)
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
                                r: math.floor(paletteacc[k].r / paletteacc[k].n)
                                g: math.floor(paletteacc[k].g / paletteacc[k].n)
                                b: math.floor(paletteacc[k].b / paletteacc[k].n)
                                a: math.floor(paletteacc[k].a / paletteacc[k].n)
                            }
                        -- Randomizing a color, if there are too few pixels and there will be a new cycle
                        if paletteacc[k].n / pixelnum < options.mincolorratio and cnt < options.colorquantcycles - 1
                            palette[k] = {
                                r: math.floor(math.random! * 255)
                                g: math.floor(math.random! * 255)
                                b: math.floor(math.random! * 255)
                                a: math.floor(math.random! * 255)
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
                idx = math.floor(math.random! * (imgd.width * imgd.height) / 4) * 4
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
            ni = math.ceil(math.sqrt(numberofcolors))
            nj = math.ceil(numberofcolors / ni)
            vx = imgd.width / (ni + 1)
            vy = imgd.height / (nj + 1)
            for j = 0, nj - 1
                for i = 0, ni - 1
                    if #palette == numberofcolors
                        break
                    else
                        idx = math.floor(((j + 1) * vy) * imgd.width + ((i + 1) * vx))
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
                graystep = math.floor(255 / (numberofcolors - 1))
                for i = 0, numberofcolors - 1
                    table.insert(palette, {
                        r: i * graystep
                        g: i * graystep
                        b: i * graystep
                        a: 255
                    })
            else
                -- RGB color cube
                colorqnum = math.floor(numberofcolors ^ (1 / 3)) -- Number of points on each edge on the RGB color cube
                colorstep = math.floor(255 / (colorqnum - 1)) -- distance between points
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
                        r: math.floor(math.random! * 255)
                        g: math.floor(math.random! * 255)
                        b: math.floor(math.random! * 255)
                        a: math.floor(math.random! * 255)
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
            splitpoint = fitpoint -- Earlier: math.floor((fitpoint + errorpoint) / 2)
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
            return shape, color, alpha

        -- 5. Batch tracing layers
        obj.get_shape = (tracedata, options) ->
            options = obj.checkoptions(options)
            shaper, build = {}, {}
            aegisub.progress.task "Processing Packages..."
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
            aegisub.progress.task "Building Shapes..."
            for i = 1, #group
                aegisub.progress.set 0 + 100 * (i - 1) / (#group - 1)
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
                point.y = math.floor(i / @w)
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
                img, ext = IMG(filename), type(filename) == "string" and filename\match("^.+%.(.+)$") or "gif"
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
                ddist = (p, q) -> math.sqrt((p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y))

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
                    s = math.sqrt(d)
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
                            if math.abs(cur.x) <= 1 and math.abs(cur.y) <= 1
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
                                j = math.floor(a / -b)
                            if d > 0
                                j = math.min(j, math.floor(-c / d))
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
                        return math.sqrt(s)
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
                        lambda2 = (a + c + math.sqrt((a - c) * (a - c) + 4 * b * b)) / 2
                        a -= lambda2
                        c -= lambda2
                        if math.abs(a) >= math.abs(c)
                            l = math.sqrt(a * a + b * b)
                            if l != 0
                                dir.x = -b / l
                                dir.y = a / l
                        else
                            l = math.sqrt(c * c + b * b)
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
                        dx = math.abs(w.x - s.x)
                        dy = math.abs(w.y - s.y)
                        if dx <= 0.5 and dy <= 0.5
                            path.curve.vertex[i] = Point(w.x + x0, w.y + y0)
                            continue
                        min, xmin, ymin = quadform(Q, s), s.x, s.y
                        if Q\at(0, 0) != 0
                            for z = 0, 1
                                w.y = s.y - 0.5 + z
                                w.x = -(Q\at(0, 1) * w.y + Q\at(0, 2)) / Q\at(0, 0)
                                dx = math.abs(w.x - s.x)
                                cand = quadform(Q, w)
                                if dx <= 0.5 and cand < min
                                    min, xmin, ymin = cand, w.x, w.y
                        if Q\at(1, 1) != 0
                            for z = 0, 1
                                w.x = s.x - 0.5 + z
                                w.y = -(Q\at(1, 0) * w.x + Q\at(1, 2)) / Q\at(1, 1)
                                dy = math.abs(w.y - s.y)
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
                            dd = math.abs(dd)
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
                        alpha = 2 - math.sqrt(4 - R / 0.3)
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
                            return 1 if math.abs(d1) > opttolerance
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
                    aegisub.progress.set 0 + 100 * i / #@pathlist
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
                    return build
                aegisub.progress.task "Building Shape..."
                shape = ""
                for i = 0, #@pathlist
                    aegisub.progress.set 0 + 100 * i / (#@pathlist - 1)
                    c = @pathlist[i].curve
                    shape ..= path(c)
                return shape
        return Potrace(@filename, ...)

return {
    math:   MATH
    table:  TABLE
    poly:   POLY
    shape:  SHAPER
    bezier: BEZIER
    text:   TEXT
    util:   SUPPORT
    config: CONFIG
    tags:   TAGS
    img:    IMG
    yut:    Yutils
}