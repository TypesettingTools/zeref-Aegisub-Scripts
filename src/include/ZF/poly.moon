-- load internal libs
ffi = require "ffi"

-- load external libs
import MATH  from require "ZF.math"
import SHAPE from require "ZF.shape"

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

class POLY

    new: (subject, clip, simp, scale = 100) =>
        assert subject and (type(subject) == "string" or type(subject) == "table"), "subject expected"
        assert type(clip) == "string" or type(clip) == "table", "clip expected" if clip
        create_paths = (paths) ->
            create_path = (path) ->
                point = PATH.new!
                for p in *path
                    point\add(p[1], p[2])
                return point
            path = PATHS.new!
            for p in *paths
                path\add(create_path(p))
            return path
        subject = type(subject) == "string" and SHAPE(subject) or subject
        clip = clip and (type(clip) == "string" and SHAPE(clip) or clip) or nil
        @sbj = create_paths(subject\split(1, "bezier")\scale(scale * 100, scale * 100).paths)
        @clp = clip and create_paths(clip\split(1, "bezier")\scale(scale * 100, scale * 100).paths) or nil
        @smp = simp and (type(simp) != "string" and "full" or "") or nil
        @scl = scale

    -- removes useless vertices from a shape
    simplify: =>
        @sbj = type(@sbj) == "string" and POLY(@sbj).sbj or @sbj
        -- creates an external simplify --
        pc = CLIPPER.new!
        pc\add_paths(@sbj, "subject")
        @sbj = pc\execute("union", "even_odd")
        ----------------------------------
        return @

    -- creates a run for the clipper
    clipper: (fr = "even_odd", ct = "intersection") =>
        -- creates a clipper run --
        pc = CLIPPER.new!
        pc\add_paths(@sbj, "subject")
        pc\add_paths(@clp, "clip")
        @sbj = pc\execute(ct, fr)
        ---------------------------
        return @

    -- creates a run for clipper offset
    offset: (size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25) =>
        -- create clipper offset --
        po = OFFSET.new(mtl, act)
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

    -- builds the shape
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

{:POLY}