ffi = require "ffi"

require "ZF.defs.headers"

import POINT    from require "ZF.2D.point"
import SHAPE    from require "ZF.2D.shape"
import TABLE    from require "ZF.util.table"
import SIMPLIFY from require "ZF.2D.poly"

-- enums
clip_type = {intersection: 0, union: 1, difference: 2, xor: 3}
join_type = {square: 0, round: 1, miter: 2}
end_type  = {closed_polygon: 0, closed_line: 1, open_butt: 2, open_square: 3, open_round: 4}
poly_type = {subject: 0, clip: 1}
fill_type = {none: 0, even_odd: 1, non_zero: 2, positive: 3, negative: 4}

-- metatables
local PATH, PATHS, OFFSET, CLIPPER

PATH = {
    new:  -> ffi.gc(CPP.zf_path_new!, CPP.zf_path_free)
    add:  (self, x, y) -> CPP.zf_path_add(self, x, y)
    get:  (self, i) -> CPP.zf_path_get(self, i - 1)
    size: (self) -> CPP.zf_path_size(self)
}

PATHS = {
    new:  -> ffi.gc(CPP.zf_paths_new!, CPP.zf_paths_free)
    add:  (self, path) -> CPP.zf_paths_add(self, path)
    get:  (self, i) -> CPP.zf_paths_get(self, i - 1)
    size: (self) -> CPP.zf_paths_size(self)
}

OFFSET = {
    new: (ml = 2, at = 0.25) ->
        co = CPP.zf_offset_new(ml, at)
        ffi.gc(co, CPP.zf_offset_free)

    add_path: (self, path, delta, jt = "square", et = "open_butt") ->
        out = CPP.zf_offset_path(self, path, delta, join_type[jt], end_type[et])
        assert out, ffi.string(CPP.zf_err_msg!)
        return out

    add_paths: (self, paths, delta, jt = "square", et = "open_butt") ->
        out = CPP.zf_offset_paths(self, paths, delta, join_type[jt], end_type[et])
        assert out, ffi.string(CPP.zf_err_msg!)
        return out
}

CLIPPER = {
    new:       (...) -> ffi.gc(CPP.zf_clipper_new!, CPP.zf_clipper_free)
    add_path:  (self, path, pt, closed = true) -> CPP.zf_clipper_add_path(self, path, poly_type[pt], closed, err)
    add_paths: (self, paths, pt, closed = true) -> error ffi.string(CPP.zf_err_msg!) unless CPP.zf_clipper_add_paths(self, paths, poly_type[pt], closed, err)
    execute:   (self, ct, sft = "even_odd", cft = "even_odd") ->
        out = CPP.zf_clipper_execute(self, clip_type[ct], fill_type[sft], fill_type[cft])
        assert out, ffi.string(CPP.zf_err_msg!)
        return out
}

ffi.metatype "zf_path",    {__index: PATH}
ffi.metatype "zf_paths",   {__index: PATHS}
ffi.metatype "zf_offset",  {__index: OFFSET}
ffi.metatype "zf_clipper", {__index: CLIPPER}

-- simplifies the number of points by the distance between them
runSimplify = (path, simplifyType = "none", limit = 3) ->
    result = {}

    splitByLimit = (p, lm) ->
        -- get distances
        for i = 2, #p
            p[i].d = p[i - 1]\distance p[i]

        -- leaves the values that are between the limit in evidence
        add, i, j = {{p[1]}}, 2, 2
        while i <= #p
            add[j] = {}
            if p[i].d <= lm
                add[j].isB = true
                while p[i] and p[i].d <= lm
                    TABLE(add[j])\push p[i]
                    i += 1
                j += 1
            if p[i] and not (p[i].d <= lm)
                add[j] = {p[i]}
            i += 1
            j += 1

        -- adds the last point of the previous value to the current
        for i = 2, #add
            prev = add[i - 1]
            TABLE(add[i])\unshift TABLE(prev[#prev])\copy!

        return add

    simplifyType = simplifyType\lower!
    if simplifyType == "bezier"
        splited = splitByLimit path.pts, limit
        for i = 1, #splited
            split = splited[i]
            if split.isB
                split = SIMPLIFY(split, path.tol)\spLines2Bezier!
                for j = 1, #split
                    split[j].t = "b"
                    TABLE(result)\push split[j]
            else
                split.t = i == 1 and "m" or "l"
                TABLE(result)\push split
    else
        for p, point in ipairs simplifyType == "line" and path\spLines! or path.pts
            TABLE(result)\push {point, t: p == 1 and "m" or "l"}

    return result

class LIBCLIPPER

    new: (subj, clip, scale = 1000) =>
        assert hasCPP, "libclipper was not found"

        assert subj, "subject expected"
        subj = SHAPE(subj)\split 1, "b"
        clip = clip and SHAPE(clip)\split(1, "b") or nil

        createPaths = (paths) ->
            createPath = (path) ->
                point = PATH.new!
                for p in *path
                    pt = #p == 2 and p[2] or p[1]
                    point\add pt.x * scale, pt.y * scale
                return point
            path = PATHS.new!
            for p in *paths
                path\add createPath p
            return path

        @scl = scale
        @sbj = createPaths subj.paths
        @clp = clip and createPaths(clip.paths) or nil

    -- removes useless vertices from a shape
    simplify: =>
        -- creates an external simplify --
        pc = CLIPPER.new!
        pc\add_paths @sbj, "subject"
        @sbj = pc\execute "union", "even_odd"
        ----------------------------------
        return @

    -- creates a run for the clipper
    clipper: (fr = "even_odd", ct = "intersection") =>
        assert @clp, "expected clip"
        -- creates a clipper run --
        pc = CLIPPER.new!
        pc\add_paths @sbj, "subject"
        pc\add_paths @clp, "clip"
        @sbj = pc\execute ct, fr
        ---------------------------
        return @

    -- creates a run for clipper offset
    offset: (size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25) =>
        jt = jt\lower!
        -- create clipper offset --
        po = OFFSET.new mtl, act
        @sbj = po\add_paths @sbj, size * @scl, jt, et
        --------------------------
        return @

    -- generates a stroke around the shape
    toStroke: (size, jt = "round", mode = "center", mtl, act) =>
        assert size >= 0, "The size must be positive"

        mode = mode\lower!
        size = mode == "inside" and -size or size
        fill = LIBCLIPPER (mode != "center" and @simplify! or @)\build!
        offs = LIBCLIPPER @offset(size, jt, mode == "center" and "closed_line" or nil, mtl, act)\build!

        switch mode
            when "outside"
                @sbj = offs.sbj
                @clp = fill.sbj
                @clip(true), fill
            when "inside"
                @sbj = fill.sbj
                @clp = offs.sbj
                @clip(true), offs
            when "center"
                @sbj = fill.sbj
                @clp = offs.sbj
                offs, @clip(true)

    -- cuts a shape through the \clip - \iclip tags
    clip: (iclip) => iclip and @clipper(nil, "difference") or @clipper nil, "intersection"

    -- generates the result of a clipper library run
    build: (simplifyType, precision = 1, decs = 3) =>
        add = {}
        for i = 1, @sbj\size!
            add[i] = {}
            path = @sbj\get i
            for j = 1, path\size!
                point = path\get j
                x = tonumber(point.x) * (1 / @scl)
                y = tonumber(point.y) * (1 / @scl)
                add[i][j] = POINT x, y
            add[i] = runSimplify SIMPLIFY(add[i], precision), simplifyType
        return SHAPE(add)\build decs

{:LIBCLIPPER}