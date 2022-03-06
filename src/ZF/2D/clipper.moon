ffi = require "ffi"

require "ZF.defs.headers"

import POINT from require "ZF.2D.point"
import PATH  from require "ZF.2D.path"
import SHAPE from require "ZF.2D.shape"
import TABLE from require "ZF.util.table"

-- enums
clip_type = {intersection: 0, union: 1, difference: 2, xor: 3}
join_type = {square: 0, round: 1, miter: 2}
end_type  = {closed_polygon: 0, closed_line: 1, open_butt: 2, open_square: 3, open_round: 4}
poly_type = {subject: 0, clip: 1}
fill_type = {none: 0, even_odd: 1, non_zero: 2, positive: 3, negative: 4}

__PATH = {
    new:  -> ffi.gc(CPP.zf_path_new!, CPP.zf_path_free)
    add:  (self, x, y) -> CPP.zf_path_add(self, x, y)
    get:  (self, i) -> CPP.zf_path_get(self, i - 1)
    size: (self) -> CPP.zf_path_size(self)
}

__PATHS = {
    new:  -> ffi.gc(CPP.zf_paths_new!, CPP.zf_paths_free)
    add:  (self, path) -> CPP.zf_paths_add(self, path)
    get:  (self, i) -> CPP.zf_paths_get(self, i - 1)
    size: (self) -> CPP.zf_paths_size(self)
}

__OFFSET = {
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

__CLIPPER = {
    new:       (...) -> ffi.gc(CPP.zf_clipper_new!, CPP.zf_clipper_free)
    add_path:  (self, path, pt, closed = true) -> CPP.zf_clipper_add_path(self, path, poly_type[pt], closed, err)
    add_paths: (self, paths, pt, closed = true) -> error ffi.string(CPP.zf_err_msg!) unless CPP.zf_clipper_add_paths(self, paths, poly_type[pt], closed, err)
    execute:   (self, ct, sft = "even_odd", cft = "even_odd") ->
        out = CPP.zf_clipper_execute(self, clip_type[ct], fill_type[sft], fill_type[cft])
        assert out, ffi.string(CPP.zf_err_msg!)
        return out
}

ffi.metatype "zf_path",    {__index: __PATH}
ffi.metatype "zf_paths",   {__index: __PATHS}
ffi.metatype "zf_offset",  {__index: __OFFSET}
ffi.metatype "zf_clipper", {__index: __CLIPPER}

class CLIPPER

    -- @param subj string || SHAPE
    -- @param clip string || SHAPE
    -- @param close boolean
    -- @param scale number
    new: (subj, clip, close = false, scale = 1000) =>
        assert hasCPP, "libclipper was not found"
        assert subj, "subject expected"

        subj = SHAPE(subj, close)\flatten nil, nil, 1, "b"
        clip = clip and SHAPE(clip, close)\flatten(nil, nil, 1, "b") or nil

        createPaths = (paths) ->
            createPath = (path) ->
                newPath = __PATH.new!
                for i = 1, #path
                    {a, b} = path[i].bz
                    if i == 1
                        newPath\add a.x * scale, a.y * scale
                        newPath\add b.x * scale, b.y * scale
                    else
                        newPath\add b.x * scale, b.y * scale
                return newPath
            newPaths = __PATHS.new!
            for p in *paths
                newPaths\add createPath p.path
            return newPaths

        @cls = close
        @scl = scale
        @sbj = createPaths subj.paths
        @clp = clip and createPaths(clip.paths) or nil

    -- removes useless vertices from a shape
    -- @return CLIPPER
    simplify: =>
        -- creates an external simplify --
        pc = __CLIPPER.new!
        pc\add_paths @sbj, "subject"
        @sbj = pc\execute "union", "even_odd"
        ----------------------------------
        return @

    -- creates a run for the clipper
    -- @param fr string
    -- @param ct string
    -- @return CLIPPER
    clipper: (fr = "even_odd", ct = "intersection") =>
        assert @clp, "expected clip"
        -- creates a clipper run --
        pc = __CLIPPER.new!
        pc\add_paths @sbj, "subject"
        pc\add_paths @clp, "clip"
        @sbj = pc\execute ct, fr
        ---------------------------
        return @

    -- creates a run for clipper offset
    -- @param size number
    -- @param jt string
    -- @param et string
    -- @param mtl number
    -- @param act number
    -- @return CLIPPER
    offset: (size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25) =>
        jt = jt\lower!
        -- create clipper offset --
        po = __OFFSET.new mtl, act
        @sbj = po\add_paths @sbj, size * @scl, jt, et
        --------------------------
        return @

    -- generates a stroke around the shape
    -- @param size number
    -- @param jt string
    -- @param mode string
    -- @param mtl number
    -- @param act number
    -- @return CLIPPER, CLIPPER
    toStroke: (size, jt = "round", mode = "center", mtl, act) =>
        assert size >= 0, "The size must be positive"

        mode = mode\lower!
        size = mode == "inside" and -size or size
        fill = CLIPPER (mode != "center" and @simplify! or @)\build!
        offs = CLIPPER @offset(size, jt, mode == "center" and "closed_line" or nil, mtl, act)\build!

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
    -- @param iclip boolean
    -- @return CLIPPER
    clip: (iclip) => iclip and @clipper(nil, "difference") or @clipper nil, "intersection"

    -- builds the shape
    -- @param simplifyType string
    -- @param precision integer
    -- @param decs integer
    -- @return string
    build: (simplifyType, precision = 1, decs = 3) =>
        new, rsc = SHAPE!, 1 / @scl
        for i = 1, @sbj\size!
            path = @sbj\get i
            new.paths[i] = PATH!
            for j = 2, path\size!
                prevPoint = path\get j - 1
                currPoint = path\get j - 0
                xp = tonumber(prevPoint.x) * rsc
                yp = tonumber(prevPoint.y) * rsc
                xc = tonumber(currPoint.x) * rsc
                yc = tonumber(currPoint.y) * rsc
                new.paths[i]\push POINT(xp, yp), POINT(xc, yc)
            if simplifyType
                new.paths[i] = new.paths[i]\simplify simplifyType
        return new\build decs

{:CLIPPER}