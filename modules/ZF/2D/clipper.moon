import CPP, has_loaded, version from require "zpclipper.clipper"

import POINT   from require "ZF.2D.point"
import SEGMENT from require "ZF.2D.segment"
import PATH    from require "ZF.2D.path"
import SHAPE   from require "ZF.2D.shape"

class CLIPPER

    version: "1.1.4"

    -- @param subj string || SHAPE
    -- @param clip string || SHAPE
    -- @param close boolean
    new: (subj, clip, close = false) =>
        unless has_loaded
            libError "Clipper2"

        assert subj, "subject expected"
        subj = SHAPE(subj, close)\flatten nil, nil, 1, "b"
        clip = clip and SHAPE(clip, close)\flatten(nil, nil, 1, "b") or nil

        createPaths = (paths) ->
            createPath = (path) ->
                newPath = CPP.path.new!
                if path[1]
                    {a, b} = path[1]["segment"]
                    newPath\add a.x, a.y
                    newPath\add b.x, b.y
                for i = 2, #path
                    c = path[i]["segment"][2]
                    newPath\add c.x, c.y
                return newPath
            newPaths = CPP.paths.new!
            for p in *paths
                newPaths\add createPath p.path
            return newPaths

        @cls = close
        @sbj = createPaths subj.paths
        @clp = clip and createPaths(clip.paths) or nil

    -- removes useless vertices from a shape
    -- @return CLIPPER
    simplify: (fr) =>
        c = CPP.clipper.new!
        c\add_paths @sbj, @sbj
        @sbj = c\execute "union"
        return @

    -- creates a run for the clipper
    -- @param fr string
    -- @param ct string
    -- @return CLIPPER
    clipper: (ct = "intersection", fr = "non_zero") =>
        assert @clp, "expected clip"
        c = CPP.clipper.new!
        c\add_paths @sbj, @clp
        @sbj = c\execute ct, fr
        return @

    -- creates a run for clipper offset
    -- @param size number
    -- @param jt string
    -- @param et string
    -- @param mtl number
    -- @param act number
    -- @return CLIPPER
    offset: (size, jt = "round", et = "polygon", mtl = 2, act = 0.25) =>
        jt = jt\lower!
        o = CPP.offset.new mtl, act
        o\add_paths @sbj, jt, et
        @sbj = o\execute size
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
        offs = CLIPPER @offset(size, jt, mode == "center" and "joined" or nil, mtl, act)\build!

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
    clip: (iclip) => iclip and @clipper("difference") or @clipper "intersection"

    -- builds the shape
    -- @param simplifyType string
    -- @param precision integer
    -- @param decs integer
    -- @return string
    build: (simplifyType, precision = 1, decs = 3) =>
        new = SHAPE!
        for i = 1, @sbj\len!
            path = @sbj\get i
            new.paths[i] = PATH!
            for j = 2, path\len!
                a = path\get j - 1
                b = path\get j - 0
                p = POINT a.x, a.y
                c = POINT b.x, b.y
                new.paths[i]\push SEGMENT p, c
            if simplifyType
                new.paths[i] = new.paths[i]\simplify simplifyType, precision, precision * 3
        return new\build decs

{:CLIPPER}