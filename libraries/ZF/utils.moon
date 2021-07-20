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

-- load external libs
require "karaskel"
export Yutils = require "Yutils" -- https://github.com/Youka/Yutils

-- import libs
import PATH, PATHS, CLIPPER, OFFSET, IMG from require "ZF.libs"

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
            maxError: maxDist,
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
        A, C, X = {}, {[0]: {}, [1]: {}}, {}
        tmp = @Point!
        bezCurve = {}
        nPts = last - first + 1
        for i = 0, nPts - 1
            v1 = @Point(tHat1.x, tHat1.y)
            v2 = @Point(tHat2.x, tHat2.y)
            v1 = @v2Scale(v1, @B1(uPrime[i]))
            v2 = @v2Scale(v2, @B2(uPrime[i]))
            A[i] = {}
            A[i][0] = v1
            A[i][1] = v2
        C[0][0] = 0
        C[0][1] = 0
        C[1][0] = 0
        C[1][1] = 0
        X[0] = 0
        X[1] = 0
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

    solution: (shape, dist = 3, ____error) =>
        shape = (type(shape) == "table" and SHAPER(shape)\build(true) or shape)
        get_dist = (shape) ->
            points = [{x: tonumber(x), y: tonumber(y)} for x, y in shape\gmatch "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"]
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
            paths = [m for m in shape\gmatch "m [^m]*"]
            build_solution = (path, line) ->
                build = ""
                if line
                    for i = 1, #path
                        build ..= "l #{path[i].x} #{path[i].y} "
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
                    if paths[k][j].bezier
                        paths[k][j] = build_solution(@polyline2bezier(paths[k][j], ____error))
                    else
                        paths[k][j] = build_solution(paths[k][j], true)
                paths[k] = table.concat(paths[k])
                paths[k] = paths[k]\gsub("l", "m", 1)
            return table.concat(paths)
        return make_solution(dist)

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
        if (dx != 0) or (dy != 0)
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
            @simplifyDPStep(points, first, index, sqTolerance, simplified) if (index - first > 1)
            table.insert(simplified, points[index])
            @simplifyDPStep(points, index, last, sqTolerance, simplified) if (last - index > 1)

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
        return SHAPER(sol)\build(true)

-- bezier curve implementation
-- https://en.wikipedia.org/wiki/B%C3%A9zier_curve
class BEZIER

    new: (...) =>
        @paths = (type(...) == "table" and ... or {...})

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
        @paths, i = {}, 0
        if type(shape) == "string"
            shape = SUPPORT\clip_to_draw(shape)
            shape = shape\gsub "m [^m]*", (p) ->
                p = p\gsub "m%s+(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)%s+m", "m %1 %2 l"
                if closed
                    v = p\reverse!\match("%d[%-?%.%d]*%s+%d[%-?%.%d]*")\reverse!
                    fx, fy = p\match "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"
                    lx, ly = v\match "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"
                    p ..= " l #{fx} #{fy} " if fx != lx or fy != ly
                return p
            paths = [s for s in shape\gmatch "%S+"]
            for k = 1, #paths
                typer = paths[k]
                switch typer
                    when "m"
                        table.insert(@paths, {
                            {
                                typer: "m",
                                tonumber(paths[k + 1]),
                                tonumber(paths[k + 2])
                            }
                        })
                    when "l"
                        i = 0
                        while paths[k + i + 1] and paths[k + i + 1]\match "%d+"
                            table.insert(@paths[#@paths], {
                                typer: "l",
                                tonumber(paths[k + i + 1]),
                                tonumber(paths[k + i + 2])
                            })
                            i += 2
                    when "b"
                        i = 0
                        while paths[k + i + 1] and paths[k + i + 1]\match "%d+"
                            table.insert(@paths[#@paths], {
                                typer: "b",
                                tonumber(paths[k + i + 1]),
                                tonumber(paths[k + i + 2]),
                                tonumber(paths[k + i + 3]),
                                tonumber(paths[k + i + 4]),
                                tonumber(paths[k + i + 5]),
                                tonumber(paths[k + i + 6])
                            })
                            i += 6
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

            xCu += add if (xBu == xCu)
            xDu += add if (xAu == xDu)
            xBu += add if (xAu == xBu)
            xCu += add if (xDu == xCu)

            kBC = (yBu - yCu) / (xBu - xCu)
            kAD = (yAu - yDu) / (xAu - xDu)
            kAB = (yAu - yBu) / (xAu - xBu)
            kDC = (yDu - yCu) / (xDu - xCu)

            kAD += add if (kBC == kAD)
            xE = ((((kBC * xBu) - (kAD * xAu)) + yAu) - yBu) / (kBC - kAD)
            yE = (kBC * (xE - xBu)) + yBu

            kDC += add if (kAB == kDC)
            xF = ((((kAB * xBu) - (kDC * xCu)) + yCu) - yBu) / (kAB - kDC)
            yF = (kAB * (xF - xBu)) + yBu

            xF += add if (xE == xF)
            kEF = (yE - yF) / (xE - xF)

            kAB += add if (kEF == kAB)
            xG = ((((kEF * xDu) - (kAB * xAu)) + yAu) - yDu) / (kEF - kAB)
            yG = (kEF * (xG - xDu)) + yDu

            kBC += add if (kEF == kBC)
            xH = ((((kEF * xDu) - (kBC * xBu)) + yBu) - yDu) / (kEF - kBC)
            yH = (kEF * (xH - xDu)) + yDu
            rG = (yC - yI) / (yC - yA)
            rH = (xI - xA) / (xC - xA)
            xJ = ((xG - xDu) * rG) + xDu
            yJ = ((yG - yDu) * rG) + yDu
            xK = ((xH - xDu) * rH) + xDu
            yK = ((yH - yDu) * rH) + yDu

            xJ += add if (xF == xJ)
            xK += add if (xE == xK)
            kJF = (yF - yJ) / (xF - xJ)
            kKE = (yE - yK) / (xE - xK)

            kKE += add if (kJF == kKE)
            xIu = ((((kJF * xF) - (kKE * xE)) + yE) - yF) / (kJF - kKE)
            yIu = (kJF * (xIu - xJ)) + yJ
            return xIu, yIu
        return @

    -- transforms line points into bezier points
    to_bezier: =>
        shape = @build!
        line_to_bezier = (x1, y1, x2, y2) ->
            x1, y1, (2 * x1 + x2) / 3, (2 * y1 + y2) / 3, (x1 + 2 * x2) / 3, (y1 + 2 * y2) / 3, x2, y2
        for i = 1, 2
			shape = shape\gsub "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)%s+l%s+(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)", (px1, py1, px2, py2) ->
                x1, y1, x2, y2, x3, y3, x4, y4 = line_to_bezier(tonumber(px1), tonumber(py1), tonumber(px2), tonumber(py2))
                return "#{x1} #{y1} b #{x2} #{y2} #{x3} #{y3} #{x4} #{y4}"
        return SHAPER(shape).paths

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
        @paths = @to_bezier!
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
            assert(p > 0 or p == floor(p))
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
        is_equal = (p1, p2) ->
            if p1.typer == "m" and p2.typer == "l" and p1[1] == p2[1] and p1[2] == p2[2]
                return true
            return false
        is_corner = (p, j) ->
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
            table.remove(@paths[k]) if is_equal(@paths[k][1], @paths[k][#@paths[k]])
            for j = 1, #@paths[k] - 1
                @paths[k] = is_corner(@paths[k], j)
                for i = 1, #@paths[k][j], 2
                    if (@paths[k][j].typer != "b")
                        p0, p1 = @paths[k][j], @paths[k][j + 1]
                        x0, y0 = p0[i], p0[i + 1]
                        x1, y1 = p1[i], p1[i + 1]
                        limit[k][#limit[k] + 1] = MATH\distance(x0, y0, x1, y1) / 2
            table.sort(limit[k], (a, b) -> a < b)
            @paths[k] = is_corner(@paths[k])
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
    build: (only_line, dec = 2) =>
        shape = {}
        if not only_line
            for i = 1, #@paths
                shape[i] = {}
                for j = 1, #@paths[i]
                    shape[i][j] = ""
                    for k = 1, #@paths[i][j], 2
                        x, y = MATH\round(@paths[i][j][k], dec), MATH\round(@paths[i][j][k + 1], dec)
                        shape[i][j] ..= "#{x} #{y} "
                    shape[i][j] = "#{@paths[i][j].typer} #{shape[i][j]}"
                shape[i] = table.concat(shape[i] or {})
                if shape[i]\find("l") == 1
                    shape[i] = shape[i]\gsub "l", "m", 1
                elseif shape[i]\find("b") == 1
                    shape[i] = shape[i]\gsub "b", "m", 1
            shape = table.concat(shape)
        else
            for i = 1, #@paths
                shape[i] = ""
                for j = 1, #@paths[i]
                    x, y = MATH\round(@paths[i][j].x, dec), MATH\round(@paths[i][j].y, dec)
                    shape[i] ..= "l #{x} #{y} "
                shape[i] = shape[i]\gsub "l", "m", 1
            shape = table.concat(shape)
        return shape

class POLY

    -- converts a shape to line points
    to_points: (shape, scale = 100000) =>
        shape = shape\match("b") and SHAPER(shape)\split(1, "bezier")\scale(scale, scale) or SHAPER(shape)\scale(scale, scale)
        return shape.paths

    -- converts line points to shape
    to_shape: (points, rescale = 0.001) =>
        new_shape = {}
        if type(points) != "table"
            for k = 1, points\size!
                new_shape[k] = ""
                path_parts = points\get(k)
                for p = 1, path_parts\size!
                    path_points = path_parts\get(p)
                    new_shape[k] ..= "l #{MATH\round(tonumber(path_points.x) * rescale)} #{MATH\round(tonumber(path_points.y) * rescale)} "
                new_shape[k] = new_shape[k]\gsub("l", "m", 1)
            return table.concat(new_shape)
        else
            return SHAPER(points)\build!

    -- creates line segment paths
    create_paths: (paths) =>
        create_path = (path) ->
            points = PATH!
            for p in *path
                points\add(p[1], p[2])
            return points
        points = PATHS!
        for p in *paths
            points\add(create_path(p))
        return points

    -- removes useless vertices from a shape
    simplify: (path, ass, tol = 1, sp) =>
        path = type(path) == "string" and @to_points(path) or path
        paths = @create_paths(path)
        -- creates an external simplify --
        pc = CLIPPER!
        pc\add_paths(paths, "subject")
        paths = pc\execute("union", "even_odd")
        ----------------------------------
        return @to_shape(paths) if sp
        return not ass and l2l\solution(@get_solution(paths), tol / 10) or l2b\solution(@get_solution(paths), tol)

    -- generates the result of a clipper library run
    get_solution: (path, rescale = 0.001) =>
        get_path_points = (path) ->
            result = {}
            for k = 1, path\size!
                point = path\get(k)
                result[k] = {x: tonumber(point.x) * rescale, y: tonumber(point.y) * rescale}
            return result
        result = {}
        for k = 1, path\size!
            result[#result + 1] = get_path_points(path\get(k))
        return result

    -- creates a run for the clipper
    clipper: (sbj, clp, fr = "even_odd", ct = "intersection", sp) =>
        sbj = type(sbj) == "string" and @to_points(sbj) or sbj
        clp = type(clp) == "string" and @to_points(clp) or clp
        sbj, clp = @create_paths(sbj), @create_paths(clp)
        -- creates a clipper run --
        pc = CLIPPER!
        pc\add_paths(sbj, "subject")
        pc\add_paths(clp, "clip")
        ---------------------------
        final = pc\execute(ct, fr)
        return @to_shape(final) if sp
        return l2l\solution(@get_solution(final), 0.1) -- simplify :()

    -- creates a run for clipper offset
    offset: (points, size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25, sp) =>
        points = type(points) == "string" and @to_points(points) or points
        -- create clipper offset --
        pp = @create_paths(points)
        po = OFFSET(mtl, act)
        final = po\add_paths(pp, size * 1000, jt, et)
        --------------------------
        return @to_shape(final) if sp
        return l2l\solution(@get_solution(final), 0.1) -- simplify :()

    -- generates an outline of a shape
    to_outline: (points, size, jt = "Round", mode = "Center", mtl, act, simp) =>
        assert size and size >= 0, "You need to add a size and it has to be bigger than 0."
        jt = jt\lower!
        size = mode == "Inside" and -size or size
        points = mode != "Center" and @simplify(points, nil, nil, simp) or points
        create_offset = switch mode
            when "Center"
                @offset(points, size, jt, "closed_line", mtl, act, simp)
            else
                @offset(points, size, jt, nil, mtl, act, simp)
        outline = switch mode
            when "Outside"
                @clipper(create_offset, points, nil, "difference", simp)
            else
                @clipper(points, create_offset, nil, "difference", simp)
        switch mode
            when "Outside"
                create_offset = points
            when "Center"
                if simp
                    return @simplify(create_offset, true, 3), @simplify(outline, true, 3)
                else
                    return create_offset, outline
        if simp
            return @simplify(outline, true, 3), @simplify(create_offset, true, 3)
        else
            return outline, create_offset

    -- cuts a shape through the \clip - \iclip tags
    clip: (subj, clip, x = 0, y = 0, iclip, simp) =>
        local shape
        if type(clip) == "table"
            shape = {}
            for k = 1, #clip
                clip[k] = SHAPER(clip[k])\displace(-x, -y)\build!
                shape[k] = iclip and @clipper(subj, clip[k], "even_odd", "difference", simp) or @clipper(subj, clip[k], "even_odd", "intersection", simp)
        else
            clip = SHAPER(clip)\displace(-x, -y)\build!
            shape = iclip and @clipper(subj, clip, "even_odd", "difference", simp) or @clipper(subj, clip, "even_odd", "intersection", simp)
        if simp
            return @simplify(shape, true, 3)
        else
            return shape

class TEXT

    -- converts a text to shape
    to_shape: (line, text = line.text_stripped) =>
        val = {text: {}, shape: {}, w: {}, h: {}}
        while text != ""
            c, d = SUPPORT\headtail(text, "\\N")
            val.text[#val.text + 1] = c\match("^%s*(.-)%s*$")
            text = d
        for k = 1, #val.text
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
}