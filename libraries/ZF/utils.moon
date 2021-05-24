export Yutils, Poly

local *
pi, ln, sin, cos, tan, max, min  = math.pi, math.log, math.sin, math.cos, math.tan, math.max, math.min
abs, deg, rad, log, asin, sqrt   = math.abs, math.deg, math.rad, math.log10, math.asin, math.sqrt
acos, atan, sinh, cosh, tanh     = math.acos, math.atan, math.asin, math.cosh, math.tanh
rand, ceil, floor, atan2, format = math.random, math.ceil, math.floor, math.atan2, string.format

require "karaskel"
ffi = require "ffi"
Yutils = require "Yutils" -- https://github.com/Youka/Yutils

if (ffi.os != "Windows")
    error("This is not compatible with your operating system.")
else
    Poly = require "ZF.clipper.clipper"

class MATH

    round: (x, dec = 2) => -- round values
        Yutils.math.round(x, dec)

    distance: (x1 = 0, y1 = 0, x2 = 0, y2 = 0) => -- returns the distance between two points
        @round sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), 3

    interpolation: (pct, min, max) => -- interpolate two values
        if (pct <= 0) then min elseif (pct >= 1) then max else @round(pct * (max - min) + min, 2)

class TABLE

    push: (t, ...) => -- adds one or more elements to the end of an table
        n = select("#", ...)
        t = [select(i, ...) for i = 1, n]
        return ...

    slice: (t, f, l, s) => -- returns a copy of part of an array from a subarray created between the start and end positions
        sliced = [t[i] for i = f or 1, l or #t, s or 1]
        return sliced

    len: (t, table_type = "array") => -- get the real length of the table
        count = 0
        if (table_type == "array")
            count += 1 for k, v in ipairs t
        else
            count += 1 for k, v in pairs t
        return count

    view: (Table, table_name, indent) => -- get a table as string
        cart, autoref = "", ""
        isemptytable = (Table) -> next(Table) == nil
        basicSerialize = (o) ->
            so = tostring(o)
            if (type(o) == "function")
                info = debug.getinfo o, "S"
                return format "%q", so .. ", C function" if info.what == "C"
                format "%q, defined in (lines: %s - %s), ubication %s", so, info.linedefined, info.lastlinedefined, info.source
            elseif (type(o) == "number") or (type(o) == "boolean")
                return so
            format "%q", so
        addtocart = (value, table_name, indent, saved, field) ->
            indent or= ""
            saved or= {}
            field or= table_name
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
                        for k, v in pairs(value) do
                            k = basicSerialize(k)
                            fname = "#{table_name}[ #{k} ]"
                            field = "[ #{k} ]"
                            addtocart v, fname, indent .. "	", saved, field
                        cart = "#{cart}#{indent}};\n"
        table_name or= "table_unnamed"
        return "#{table_name} = #{basicSerialize(Table)}" if type(Table) != "table"
        addtocart Table, table_name, indent
        return cart .. autoref

class l2b

    bezier_segments = {}

    new: (x, y) =>
        @x = (type(x) == "number" and x or 0)
        @y = (type(y) == "number" and y or 0)

    Point: (x, y) =>
        return @(x, y)

    v2SquaredLength: (a) =>
        return (a.x * a.x) + (a.y * a.y)

    v2Length: (a) =>
        return math.sqrt(@v2SquaredLength(a))

    v2Negate: (v) =>
        result = @Point!
        result.x = -v.x
        result.y = -v.y
        return result

    v2Normalize: (v) =>
        result = @Point!
        len = @v2Length(v)
        if (len != 0)
            result.x = v.x / len
            result.y = v.y / len
        return result

    v2Scale: (v, newlen) =>
        result = @Point!
        len = @v2Length(v)
        if (len != 0)
            result.x = v.x * newlen / len
            result.y = v.y * newlen / len
        return result

    v2Add: (a, b) =>
        c = @Point!
        c.x = a.x + b.x
        c.y = a.y + b.y
        return c

    v2Dot: (a, b) =>
        return (a.x * b.x) + (a.y * b.y)

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
            if (dist >= maxDist)
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

    B0: (u) =>
        tmp = 1 - u
        return (tmp * tmp * tmp)

    B1: (u) =>
        tmp = 1 - u
        return (3 * u * (tmp * tmp))

    B2: (u) =>
        tmp = 1 - u
        return (3 * u * u * tmp)

    B3: (u) =>
        return (u * u * u)

    bezierII: (degree, V, t) =>
        Vtemp = {}
        for i = 0, degree
            Vtemp[i] = @Point(V[i].x, V[i].y)
        for i = 1, degree
            for j = 0, (degree - i)
                Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
                Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y
        Q = @Point(Vtemp[0].x, Vtemp[0].y)
        return Q

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
        if (nPts == 2)
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
        if (maxError < ____error)
            @drawBezierCurve(3, bezCurve)
            return
        if (maxError < iterationError)
            for i = 0, maxIterations
                uPrime = @reparameterize(d, first, last, u, bezCurve)
                bezCurve = @generateBezier(d, first, last, uPrime, tHat1, tHat2)
                resultMaxError = @computeMaxError(d, first, last, bezCurve, uPrime, splitPoint)
                maxError = resultMaxError.maxError
                splitPoint = resultMaxError.splitPoint
                if (maxError < ____error)
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

    solution: (shape, dist = math.pi, ____error) => -- by Itachi --> https://github.com/KaraEffect0r/Kara_Effector
        shape = (type(shape) == "table" and SHAPER(shape)\build(true) or shape)
        dis__one = (shape, dist) ->
            shapes = [s for s in shape\gmatch "m%s+%-?%d[%.%-%d l]*"]
            shape_simple = (shape) ->
                distance = (P1, P2) ->
                    return ((P1.x - P2.x) ^ 2 + (P1.y - P2.y) ^ 2) ^ 0.5
                inpack = {}
                points = [{x: tonumber(x), y: tonumber(y)} for x, y in shape\gmatch "(%-?%d[%.%d]*)%s+(%-?%d[%.%d]*)"]
                points[0] = points[2]
                state = distance(points[1], points[2]) <= dist
                for i = 1, #points
                    if distance(points[i], points[i - 1]) <= dist == state
                        inpack[#inpack + 1] = {bezier: state and "ok" or nil}
                        state = not state
                    inpack[#inpack][#inpack[#inpack] + 1] = points[i]
                for i = 1, #inpack - 1
                    unless inpack[i].bezier
                        table.insert(inpack[i + 1], 1, inpack[i][#inpack[i]])
                        inpack[i][#inpack[i]] = nil
                return inpack
            for i = 1, #shapes
                shapes[i] = shape_simple(shapes[i])
            return shapes

        make_shape = (shape, dist) ->
            sol = (points, bl = "bezier") ->
                shape = ""
                if bl == "line"
                    shape = "l "
                    for k = 1, #points
                        shape ..= "#{points[k].x} #{points[k].y} l "
                    return shape
                else
                    for k = 1, #points
                        x1 = MATH\round(points[k][1].x)
                        y1 = MATH\round(points[k][1].y)
                        x2 = MATH\round(points[k][2].x)
                        y2 = MATH\round(points[k][2].y)
                        x3 = MATH\round(points[k][3].x)
                        y3 = MATH\round(points[k][3].y)
                        shape ..= "b #{x1} #{y1} #{x2} #{y2} #{x3} #{y3} "
                    x0 = MATH\round(points[1][0].x)
                    y0 = MATH\round(points[1][0].y)
                    return "#{x0} #{y0} #{shape}"
            points = dis__one(shape, dist)
            for k = 1, #points
                for j = 1, #points[k]
                    if points[k][j].bezier
                        points[k][j] = @polyline2bezier(points[k][j], ____error)
                        points[k][j] = sol(points[k][j])
                    else
                        points[k][j] = #points[k][j] > 0 and sol(points[k][j], "line") or "l "
                points[k] = "m " .. table.concat(points[k])
                points[k] = points[k]\gsub("m l", "m")
                points[k] = points[k]\sub(-2, -2) == "l" and points[k]\sub(1, -3) or points[k]
            return table.concat(points)
        return make_shape(shape, dist)

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
            if (t > 1)
                x = p2.x
                y = p2.y
            elseif (t > 0)
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
            if (@getSqDist(point, prevPoint) > sqTolerance)
                table.insert(newPoints, point)
                prevPoint = point
        table.insert(newPoints, point) if (prevPoint != point)
        return newPoints

    simplifyDPStep: (points, first, last, sqTolerance, simplified) =>
        local index
        maxSqDist = sqTolerance
        for i = first + 1, last
            sqDist = @getSqSegDist(points[i], points[first], points[last])
            if (sqDist > maxSqDist)
                index = i
                maxSqDist = sqDist
        if (maxSqDist > sqTolerance)
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
        sqTolerance = (tolerance != nil) and tolerance * tolerance or 1
        points = highestQuality and points or @simplifyRadialDist(points, sqTolerance)
        points = @simplifyDouglasPeucker(points, sqTolerance)
        table.remove(points) unless closed
        return points

    solution: (points, tolerance = 0.1, highestQuality, closed) =>
        sol = [@simplify(v, tolerance, highestQuality, closed) for v in *points]
        return SHAPER(sol)\build(true)

class BEZIER

    new: (...) =>
        @points = (type(...) == "table" and ... or {...})

    line: (t, b0, b1) =>
        (1 - t) * b0 + t * b1

    quadratic: (t, b0, b1, b2) =>
        (1 - t) ^ 2 * b0 + 2 * t * (1 - t) * b1 + t ^ 2 * b2

    cubic: (t, b0, b1, b2, b3) =>
        (1 - t) ^ 3 * b0 + 3 * t * (1 - t) ^ 2 * b1 + 3 * t ^ 2 * (1 - t) * b2 + t ^ 3 * b3

    bernstein: (t, i, n) =>
        f = (n) ->
			k = 1
            for i = 2, n
                k *= i
			return k
        f(n) / (f(i) * f(n - i)) * t ^ i * ((1 - t) ^ (n - i))

    create: (len) =>
        len = MATH\round((not len and @len! or len), 0)
        pt, bz, pv = @points, {}, {x: {}, y: {}}
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

    len: (steps = 100) =>
        pt, pv, len = @points, {x: {}, y: {}}, 0
        x, y = pt[1], pt[2]
        if (#pt > 8)
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
        @points = {}
        if type(shape) == "string"
            shape = SUPPORT\clip_to_draw(shape)
            shape = shape\gsub "([bl]^*)(%s+%-?%d[%.%-%d ]*)", (bl, nums) ->
                i, k = (bl == "b" and 6 or 2), 0
                nums = nums\gsub "%-?%d[%.%d]*", (n) ->
                    k += 1
                    return (k % i == 0) and n .. " " .. bl or n
                return bl .. nums\sub(1, -3)
            for m in shape\gmatch("m [^m]*")
                if closed
                    fpx, fpy = m\match("(%-?%d[%.%d]*)%s*(%-?%d[%.%d]*)")
                    lpx, lpy = m\reverse!\match("%d[%.%-%d]*%s*%d[%.%-%d]*")\reverse!\match("(%-?%d[%.%d]*)%s*(%-?%d[%.%d]*)")
                    if (fpx != lpx) or (fpy != lpy)
                        m ..= "l #{fpx} #{fpy} "
                @points[#@points + 1] = {}
                for p in m\gmatch("[mbl]* [^mbl]*")
                    @points[#@points][#@points[#@points] + 1] = {typer: p\match("%a")}
                    for x, y in p\gmatch("(%-?%d[%.%d]*)%s*(%-?%d[%.%d]*)")
                        @points[#@points][#@points[#@points]][#@points[#@points][#@points[#@points]] + 1] = tonumber(x)
                        @points[#@points][#@points[#@points]][#@points[#@points][#@points[#@points]] + 1] = tonumber(y)
        else
            @points = shape.points or shape
        return @

    split: (size = 1, seg = "all", len_t) =>
        index = {}
        for i = 1, #@points
            for j = 1, #@points[i]
                if (seg == "line")
                    if (@points[i][j].typer == "l")
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 0])
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 1])
                elseif (seg == "bezier")
                    if (@points[i][j].typer == "b")
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 0])
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 1])
                else
                    if (@points[i][j].typer != "m")
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 0])
                        table.insert(@points[i][j], 1, @points[i][j - 1][#@points[i][j - 1] - 1])
            table.remove(@points[i], 1)
            if (@points[i][#@points[i]].typer == "l") and (@points[i][1][1] == @points[i][#@points[i]][1]) and (@points[i][1][2] == @points[i][#@points[i]][2])
                table.remove(@points[i])
        for i = 1, #@points
            index[i] = {}
            switch seg
                when "line"
                    for j = 1, #@points[i]
                        if (@points[i][j].typer == "l")
                            bz = BEZIER(@points[i][j])
                            len = bz\len!
                            bz = bz\create(not len_t and (len / size) or len_t)
                            for k = 1, #bz
                                index[i][#index[i] + 1] = bz[k]
                        else
                            index[i][#index[i] + 1] = @points[i][j]
                when "bezier"
                    for j = 1, #@points[i]
                        if (@points[i][j].typer == "b")
                            bz = BEZIER(@points[i][j])
                            len = bz\len!
                            bz = bz\create(not len_t and (len / size) or len_t)
                            for k = 1, #bz
                                index[i][#index[i] + 1] = bz[k]
                        else
                            index[i][#index[i] + 1] = @points[i][j]
                else -- when "all"
                    for j = 1, #@points[i]
                        if (@points[i][j].typer != "m")
                            bz = BEZIER(@points[i][j])
                            len = bz\len!
                            bz = bz\create(not len_t and (len / size) or len_t)
                            for k = 1, #bz
                                index[i][#index[i] + 1] = bz[k]
                        else
                            index[i][#index[i] + 1] = @points[i][j]
        @points = index
        return @

    bounding: (shaper) => -- returns the shape bounding box
        local l, t, r, b, n
        n = 1
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

    info: => -- export shape information
        export minx, miny, maxx, maxy, n_points = @bounding!
        export w_shape, h_shape = maxx - minx, maxy - miny
        export c_shape, m_shape = minx + w_shape / 2, miny + h_shape / 2

    filter: (fils = (x, y) -> x, y) => -- can do transformations with n-filters
        fils = (type(fils) != "table" and {fils} or fils)
        for f in *fils
            for m in *@points
                for p in *m
                    for k = 1, #p, 2
                        p[k], p[k + 1] = f(p[k], p[k + 1])
        return @

    displace: (px = 0, py = 0) => -- moves the shape from the values of x and y
        @filter (x, y) ->
            x += px
            y += py
            return x, y
        return @

    scale: (sx = 100, sy = 100) => -- scales a shape from the values of sx and sy
        @filter (x, y) ->
            x *= sx / 100
            y *= sy / 100
            return x, y
        return @

    rotate: (angle, cx, cy) => -- rotates the shape from the value of angle
        @info!
        cx or= c_shape
        cy or= m_shape
        r = rad(angle)
        @filter (x, y) ->
            rx = cos(r) * (x - cx) - sin(r) * (y - cy) + cx
            ry = sin(r) * (x - cx) + cos(r) * (y - cy) + cy
            return rx, ry
        return @

    origin: (min) => -- moves the points to their original position
        @info!
        @displace(-minx, -miny)
        return @, minx, miny if min
        return @

    org_points: (an = 7) => -- moves the points to positions relative to the alignment 7
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

    to_clip: (an = 7, px = 0, py = 0) => -- moves points to relative clip positions
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

    unclip: (an = 7, px = 0, py = 0) => -- moves the points to relative shape positions
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

    perspective: (destin) => -- http://jsfiddle.net/xjHUk/278/
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
            xA, yA = source[1].x, source[1].y
            xC, yC = source[3].x, source[3].y
            --
            xAu, yAu = destin[1].x, destin[1].y
            xBu, yBu = destin[2].x, destin[2].y
            xCu, yCu = destin[3].x, destin[3].y
            xDu, yDu = destin[4].x, destin[4].y
            -- if points are the same, have to add a "add" to avoid dividing by zero
            xCu += add if (xBu == xCu)
            xDu += add if (xAu == xDu)
            xBu += add if (xAu == xBu)
            xCu += add if (xDu == xCu)
            kBC = (yBu - yCu) / (xBu - xCu)
            kAD = (yAu - yDu) / (xAu - xDu)
            kAB = (yAu - yBu) / (xAu - xBu)
            kDC = (yDu - yCu) / (xDu - xCu)
            --
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
            --
            rG = (yC - yI) / (yC - yA)
            rH = (xI - xA) / (xC - xA)
            xJ = ((xG - xDu) * rG) + xDu
            yJ = ((yG - yDu) * rG) + yDu
            xK = ((xH - xDu) * rH) + xDu
            yK = ((yH - yDu) * rH) + yDu
            --
            xJ += add if (xF == xJ)
            xK += add if (xE == xK)
            kJF = (yF - yJ) / (xF - xJ)
            kKE = (yE - yK) / (xE - xK)
            --
            kKE += add if (kJF == kKE)
            xIu = ((((kJF * xF) - (kKE * xE)) + yE) - yF) / (kJF - kKE)
            yIu = (kJF * (xIu - xJ)) + yJ
            return xIu, yIu
        return @

    to_bezier: => -- transforms line points into bezier points
        shape = @build!
        line_to_bezier = (x1, y1, x2, y2) ->
            x1, y1, (2 * x1 + x2) / 3, (2 * y1 + y2) / 3, (x1 + 2 * x2) / 3, (y1 + 2 * y2) / 3, x2, y2
        for i = 1, 2
			shape = shape\gsub "(%-?%d[%.%d]*)%s*(%-?%d[%.%d]*)%s*l%s*(%-?%d[%.%d]*)%s*(%-?%d[%.%d]*)", (px1, py1, px2, py2) ->
                x1, y1, x2, y2, x3, y3, x4, y4 = line_to_bezier(tonumber(px1), tonumber(py1), tonumber(px2), tonumber(py2))
                return ("%s %s b %s %s %s %s %s %s")\format(x1, y1, x2, y2, x3, y3, x4, y4)
        return SHAPER(shape).points

    envelop_distort: (ctrl_p1, ctrl_p2) => -- https://codepen.io/benjamminf/pen/LLmrKN
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
        isNaN = (v) -> (type(v) == "number") and (v != v) -- checks if the number is nan
        error("The control points must have the same quantity!") if (#ctrl_p1 != #ctrl_p2)
        -- to avoid dividing by zero
        ctrl_b = 0.1
        for i = 1, #ctrl_p1
            ctrl_p1[i].x -= ctrl_b if (ctrl_p1[i].x == minx)
            ctrl_p1[i].y -= ctrl_b if (ctrl_p1[i].y == miny)
            ctrl_p1[i].x += ctrl_b if (ctrl_p1[i].x == maxx)
            ctrl_p1[i].y += ctrl_b if (ctrl_p1[i].y == maxy)
            --
            ctrl_p2[i].x -= ctrl_b if (ctrl_p2[i].x == minx)
            ctrl_p2[i].y -= ctrl_b if (ctrl_p2[i].y == miny)
            ctrl_p2[i].x += ctrl_b if (ctrl_p2[i].x == maxx)
            ctrl_p2[i].y += ctrl_b if (ctrl_p2[i].y == maxy)
        -- @split(2)
        @points = @to_bezier!
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
                A[i] = (isNaN(r) and 0 or acos(max(-1, min(r, 1))))
            -- Find Weights
            for j = 1, #V1
                i = (j > 1 and j or #V1 + 1) - 1
                vj = V1[j]
                r = sqrt((vj.x - x) ^ 2 + (vj.y - y) ^ 2)
                W[j] = (tan(A[i] / 2) + tan(A[j] / 2)) / r
            -- Normalise Weights
            Ws = 0
            for _, v in ipairs(W) do Ws += v
            -- Reposition
            nx, ny = 0, 0
            for i = 1, #V1
                L = W[i] / Ws
                nx += L * V2[i].x
                ny += L * V2[i].y
            return nx, ny
        return @

    expand: (line, meta) => -- expands the points of agreement with the values of tags some tags -- By Alen --> https://github.com/Alendt/Aegisub-Scripts
        @org_points(line.styleref.align)
        data = SUPPORT\find_coords(line, meta, true)
        frx = pi / 180 * data.rots.frx
        fry = pi / 180 * data.rots.fry
        frz = pi / 180 * data.rots.frz
        sx, cx = -sin(frx), cos(frx)
        sy, cy =  sin(fry), cos(fry)
        sz, cz = -sin(frz), cos(frz)
        xscale = data.scale.x / 100
        yscale = data.scale.y / 100
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

    smooth_edges: (radius = 0) => -- smooths the corners of a shape
        deps, build = {c: {}, l: {{}, {}}, counter: {}, dist: {}}, {}
        get_angle = (c, l) ->
            delta_x = l.x - c.x
            delta_y = l.y - c.y
            return atan2(delta_y, delta_x)
        for k = 1, #@points -- Does a configuration to check if the point can be a corner
            deps.counter[k] = {}
            for j = 1, #@points[k]
                deps.counter[k][#deps.counter[k] + 1] = (@points[k][j].typer == "m" or @points[k][j].typer == "l") or nil
                if @points[k][j].typer == "b"
                    @points[k][j].corner = false
                elseif (@points[k][j].typer == "m") and (@points[k][j + 1] and @points[k][j + 1].typer == "b")
                    @points[k][j].corner = false
                elseif (@points[k][j].typer == "l") and (@points[k][j + 1] and @points[k][j + 1].typer == "b")
                    @points[k][j].corner = false
                elseif (@points[k][j].typer == "l") and (@points[k][j - 1] and @points[k][j - 1].typer == "b")
                    @points[k][j].corner = false
                else
                    @points[k][j].corner = true
            if (@points[k][2].typer and @points[k][2].typer == "b") and (@points[k][#@points[k]].typer == "l")
                @points[k][#@points[k]].corner = false
            if (@points[k][#@points[k]].typer == "l") and (@points[k][1][1] == @points[k][#@points[k]][1]) and (@points[k][1][2] == @points[k][#@points[k]][2])
                table.remove(@points[k])
            if (@points[k][#@points[k]].typer == "b")
                @points[k][1].corner = false
        for k = 1, #@points
            deps.dist[k] = {}
            for j = 1, #@points[k] - 1
                for i = 1, #@points[k][j], 2
                    if (@points[k][j].typer != "b")
                        p0, p1 = @points[k][j], @points[k][j + 1]
                        x0, y0 = p0[i], p0[i + 1]
                        x1, y1 = p1[i], p1[i + 1]
                        deps.dist[k][#deps.dist[k] + 1] = MATH\distance(x0, y0, x1, y1) / 2
            table.sort(deps.dist[k], (a, b) -> a < b)
        for k = 1, #@points
            r = deps.dist[k][1] < radius and deps.dist[k][1] or radius -- Limits the smoothness to the smallest distance encountered
            build[k] = {}
            for j = 1, #@points[k]
                p = (j == 1 and #@points[k] or j - 1)
                n = (j == #@points[k] and 1 or j + 1)
                build[k][j] = {}
                for i = 1, #@points[k][j], 2
                    if @points[k][j].corner and (#deps.counter[k] > 4)
                        deps.c.x = MATH\round(@points[k][j][i + 0])
                        deps.c.y = MATH\round(@points[k][j][i + 1])
                        deps.l[1].x = @points[k][p][i + 0]
                        deps.l[1].y = @points[k][p][i + 1]
                        deps.l[2].x = @points[k][n][i + 0]
                        deps.l[2].y = @points[k][n][i + 1]
                        angle_f = get_angle(deps.c, deps.l[1])
                        angle_l = get_angle(deps.c, deps.l[2])
                        x1 = MATH\round(deps.c.x + r * cos(angle_f))
                        y1 = MATH\round(deps.c.y + r * sin(angle_f))
                        x2 = MATH\round(deps.c.x + r * cos(angle_l))
                        y2 = MATH\round(deps.c.y + r * sin(angle_l))
                        pcx1, pcy1 = MATH\round((x1 + 2 * deps.c.x) / 3), MATH\round((y1 + 2 * deps.c.y) / 3)
                        pcx2, pcy2 = MATH\round((x2 + 2 * deps.c.x) / 3), MATH\round((y2 + 2 * deps.c.y) / 3)
                        build[k][j][#build[k][j] + 1] = ("l %s %s b %s %s %s %s %s %s ")\format(x1, y1, pcx1, pcy1, pcx2, pcy2, x2, y2)
                    else
                        build[k][j][#build[k][j] + 1] = ("%s %s ")\format(@points[k][j][i + 0], @points[k][j][i + 1])
                        build[k][j][#build[k][j] + 1] = ""
                if #build[k][j] > 1
                    build[k][j] = ("%s %s")\format(@points[k][j].typer, table.concat(build[k][j]))
                else
                    build[k][j] = table.concat(build[k][j])
            build[k] = table.concat(build[k])
            build[k] = (build[k]\find("l") == 1 and build[k]\gsub("l", "m", 1) or build[k])
        return table.concat(build)

    build: (typer, dec = 2) => -- Builds the shape from the points
        shape = {}
        unless typer
            for i = 1, #@points
                shape[i] = {}
                for j = 1, #@points[i]
                    shape[i][j] = ""
                    local p0, p1, p2, x1, y1, x2, y2, x3, y3
                    if (@points[i][j].typer != "b")
                        p0, p1, p2 = @points[i][j], @points[i][j + 1], @points[i][j - 1]
                        -- Remove duplicate points
                        if p1 and (floor(p0[1]) == floor(p1[1])) and (floor(p0[2]) == floor(p1[2]))
                            continue
                        elseif p2 and p2.typer == "b" and (floor(p0[1]) == floor(p2[#p2 - 1])) and (floor(p0[2]) == floor(p2[#p2]))
                            continue
                        x1, y1 = MATH\round(p0[1], dec), MATH\round(p0[2], dec)
                        shape[i][j] ..= "#{p0.typer} #{x1} #{y1} "
                    else
                        p0, x1, y1, x2, y2, x3, y3 = @points[i][j]
                        if #p0 > 6
                            x1, y1 = MATH\round(p0[3], dec), MATH\round(p0[4], dec)
                            x2, y2 = MATH\round(p0[5], dec), MATH\round(p0[6], dec)
                            x3, y3 = MATH\round(p0[7], dec), MATH\round(p0[8], dec)
                        else
                            x1, y1 = MATH\round(p0[1], dec), MATH\round(p0[2], dec)
                            x2, y2 = MATH\round(p0[3], dec), MATH\round(p0[4], dec)
                            x3, y3 = MATH\round(p0[5], dec), MATH\round(p0[6], dec)
                        shape[i][j] ..= "b #{x1} #{y1} #{x2} #{y2} #{x3} #{y3} "
                shape[i] = table.concat(shape[i])
                if (shape[i]\find("l") == 1)
                    shape[i] = shape[i]\gsub("l", "m", 1)
                elseif (shape[i]\find("b") == 1)
                    shape[i] = shape[i]\gsub("b", "m", 1)
            shape = table.concat(shape)
        else
            for i = 1, #@points
                shape[i] = ""
                for j = 1, #@points[i]
                    x, y = MATH\round(@points[i][j].x, dec), MATH\round(@points[i][j].y, dec)
                    shape[i] ..= "l #{x} #{y} "
                shape[i] = shape[i]\gsub("l", "m", 1)
            shape = table.concat(shape)
        return shape

class POLY

    to_points: (shape, scale = 100000) => -- converts a shape to line points
        shape = shape\match("b") and SHAPER(shape)\split(1, "bezier")\scale(scale, scale) or SHAPER(shape)\scale(scale, scale)
        return shape.points

    to_shape: (points, rescale = 0.001) => -- converts line points to shape
        new_shape = {}
        if (type(points) != "table")
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

    create_path: (path) => -- adds path to the Poly data
        points = Poly.Path!
        for p in *path
            points\add(p[1], p[2])
        return points

    create_paths: (paths) => -- adds paths to the Poly data
        points = Poly.Paths!
        for p in *paths
            points\add(@create_path(p))
        return points

    simplify: (paths, ass, tol = 1, sp) => -- remove useless vertices from a polygon
        paths = (type(paths) == "string" and @to_points(paths) or paths)
        points = Poly.Paths!
        for p in *paths
            points\add(@create_path(p))
        points = points\simplify!
        return @to_shape(points) if sp
        return not ass and l2l\solution(@get_solution(points), tol / 10) or l2b\solution(@get_solution(points), tol)

    clean: (paths, sp) =>
        paths = (type(paths) == "string" and @to_points(paths) or paths)
        points = Poly.Paths!
        for p in *paths
            points\add(@create_path(p))
        points = points\clean_polygon!
        return @to_shape(points) if sp
        return l2l\solution(@get_solution(points), 0.1)

    get_solution: (path, rescale = 0.001) => -- returns the clipper library solution
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

    clipper: (sbj, clp, ft = "even_odd", ct = "intersection", sp) => -- returns a clipped shape, according to its set configurations
        sbj = (type(sbj) == "string" and @to_points(sbj) or sbj)
        clp = (type(clp) == "string" and @to_points(clp) or clp)
        ft_sbj = (type(ft) == "table" and ft[1] or ft)
        ft_clp = (type(ft) == "table" and ft[2] or ft)
        subj, clip = @create_paths(sbj), @create_paths(clp)
        pc = Poly.Clipper!
        pc\add_paths(subj, "subject")
        pc\add_paths(clip, "clip")
        final = pc\execute(ct, ft_sbj, ft_clp)
        return @to_shape(final) if sp
        return l2l\solution(@get_solution(final), 0.1) -- simplify :()

    offset: (points, size, jt = "round", et = "closed_polygon", mtl = 2, act = 0.25, sp) => -- returns a shape offseting, according to its set configurations
        points = (type(points) == "string" and @to_points(points) or points)
        po = Poly.ClipperOffset(mtl, act)
        pp = @create_paths(points)
        final = po\offset_paths(pp, size * 1000, jt, et)
        return @to_shape(final) if sp
        return l2l\solution(@get_solution(final), 0.1) -- simplify :()

    to_outline: (points, size, outline_type = "Round", mode = "Center", miter_limit = 2, arc_tolerance = 0.25) => -- returns an outline and the opposite of it, according to your defined settings
        error("You need to add a size and it has to be bigger than 0.") unless size or size < 0
        outline_type = outline_type\lower!
        size = (mode == "Inside" and -size or size)
        points = (mode != "Center" and @simplify(points, nil, nil, true) or points)
        local create_offset
        if (mode == "Center")
            create_offset = @offset(points, size, outline_type, "closed_line", miter_limit, arc_tolerance, true)
        else
            create_offset = @offset(points, size, outline_type, nil, miter_limit, arc_tolerance, true)
        outline = switch mode
            when "Outside"
                @clipper(create_offset, points, nil, "difference", true)
            else
                @clipper(points, create_offset, nil, "difference", true)
        switch mode
            when "Outside"
                create_offset = points
            when "Center"
                return @simplify(create_offset, true, 3), @simplify(outline, true, 3)
        return @simplify(outline, true, 3), @simplify(create_offset, true, 3)

    clip: (subj, clip, x = 0, y = 0, iclip) => -- the same thing as \clip and \iclip
        local shape
        if (type(clip) == "table")
            shape = {}
            for k = 1, #clip
                clip[k] = SHAPER(clip[k])\displace(-x, -y)\build!
                shape[k] = (iclip and @clipper(subj, clip[k], "even_odd", "difference", true) or @clipper(subj, clip[k], "even_odd", "intersection", true))
        else
            clip = SHAPER(clip)\displace(-x, -y)\build!
            shape = (iclip and @clipper(subj, clip, "even_odd", "difference", true) or @clipper(subj, clip, "even_odd", "intersection", true))
        return @simplify(shape, true, 3)

class TEXT

    to_shape: (line, text = line.text_stripped, raw) => -- converts your text into shape
        headtail = (s, div) ->
            a, b, head, tail = s\find("(.-)#{div}(.*)")
            if a then head, tail else s, ""
        texts, texts_shape, lwidth, lheight = {}, {}, {}, {}
        while text != ""
            c, d = headtail(text, "\\N")
            texts[#texts + 1] = c\match("^%s*(.-)%s*$")
            text = d
        for k = 1, #texts
            style_cfg = {
                line.styleref.fontname,
                line.styleref.bold,
                line.styleref.italic,
                line.styleref.underline,
                line.styleref.strikeout,
                line.styleref.fontsize,
                line.styleref.scale_x / 100,
                line.styleref.scale_y / 100,
                line.styleref.spacing
            }
            font = Yutils.decode.create_font unpack(style_cfg)
            extents = font.text_extents texts[k]
            texts_shape[k] = font.text_to_shape texts[k]
            texts_shape[k] = texts_shape[k]\gsub(" c", "")
            lwidth[k], lheight[k] = tonumber(extents.width), tonumber(extents.height)
            texts_shape[k] = SHAPER(texts_shape[k])\displace(0, (k - 1) * style_cfg[6] * style_cfg[8])\build!
        return texts_shape, texts, lwidth, lheight

    to_clip: (line, text = line.text_stripped, an = line.styleref.align, px = 0, py = 0) => -- converts your text into clip
        texts_shape, texts, lwidth, lheight = @to_shape(line, text)
        break_line, extra = (line.styleref.fontsize * line.styleref.scale_y / 100), 0
        for k = 1, #texts_shape
            if texts[k] == ""
                py -= break_line / 2
                extra -= break_line / 2
            texts_shape[k] = switch an
                when 1 then SHAPER(texts_shape[k])\displace(px, py - lheight[k] - break_line * (#texts_shape - 1))\build!
                when 2 then SHAPER(texts_shape[k])\displace(px - lwidth[k] / 2, py - lheight[k] - break_line * (#texts_shape - 1))\build!
                when 3 then SHAPER(texts_shape[k])\displace(px - lwidth[k], py - lheight[k] - break_line * (#texts_shape - 1))\build!
                when 4 then SHAPER(texts_shape[k])\displace(px, py - lheight[k] / 2 - break_line * (#texts_shape - 1) / 2)\build!
                when 5 then SHAPER(texts_shape[k])\displace(px - lwidth[k] / 2, (py - lheight[k] / 2 - break_line * (#texts_shape - 1) / 2))\build!
                when 6 then SHAPER(texts_shape[k])\displace(px - lwidth[k], py - lheight[k] / 2 - break_line * (#texts_shape - 1) / 2)\build!
                when 7 then SHAPER(texts_shape[k])\displace(px, py)\build!
                when 8 then SHAPER(texts_shape[k])\displace(px - lwidth[k] / 2, py)\build!
                when 9 then SHAPER(texts_shape[k])\displace(px - lwidth[k], py)\build!
        new_shape = table.concat(texts_shape)
        new_shape = switch an
            when 1, 2, 3 then SHAPER(new_shape)\displace(0, -extra)\build!
            when 4, 5, 6 then SHAPER(new_shape)\displace(0, -extra / 2)\build!
        return new_shape

class SUPPORT

    interpolation: (pct = 0.5, tp = "number", ...) =>
        values = (type(...) == "table" and ... or {...})
        --
        ipol_function = util.interpolate if (tp == "number")
        ipol_function = util.interpolate_color if (tp == "color")
        ipol_function = util.interpolate_alpha if (tp == "alpha")
        --
        pct = util.clamp(pct, 0, 1) * (#values - 1)
        valor_i = values[floor(pct) + 1]
        valor_f = values[floor(pct) + 2] or values[floor(pct) + 1]
        return ipol_function(pct - floor(pct), valor_i, valor_f)

    tags2styles: (subs, line) => -- makes its style values equal those of tags on the line
        tags, vtext = "", line.text
        meta, styles = karaskel.collect_head subs
        for k = 1, styles.n
            styles[k].margin_l = line.margin_l if (line.margin_l > 0)
            styles[k].margin_r = line.margin_r if (line.margin_r > 0)
            styles[k].margin_v = line.margin_t if (line.margin_t > 0)
            styles[k].margin_v = line.margin_b if (line.margin_b > 0)
            if vtext\match "%b{}"
                tags = vtext\match "%b{}"
                styles[k].align     = tonumber tags\match "\\an%s*(%d)" if tags\match "\\an%s*%d"
                styles[k].fontname  = tags\match "\\fn%s*([^\\}]*)" if tags\match "\\fn%s*[^\\}]*"
                styles[k].fontsize  = tonumber tags\match "\\fs%s*(%d[%.%d]*)" if tags\match "\\fs%s*%d[%.%d]*"
                styles[k].scale_x   = tonumber tags\match "\\fscx%s*(%d[%.%d]*)" if tags\match "\\fscx%s*%d[%.%d]*"
                styles[k].scale_y   = tonumber tags\match "\\fscy%s*(%d[%.%d]*)" if tags\match "\\fscy%s*%d[%.%d]*"
                styles[k].spacing   = tonumber tags\match "\\fsp%s*(%-?%d[%.%d]*)" if tags\match "\\fsp%s*%-?%d[%.%d]*"
                styles[k].outline   = tonumber tags\match "\\bord%s*(%d[%.%d]*)" if tags\match "\\bord%s*%d[%.%d]*"
                styles[k].shadow    = tonumber tags\match "\\shad%s*(%d[%.%d]*)" if tags\match "\\shad%s*%d[%.%d]*"
                styles[k].angle     = tonumber tags\match "\\frz?%s*(%-?%d[%.%d]*)" if tags\match "\\frz?%s*%-?%d[%.%d]*"
                styles[k].color1    = tags\match "\\1?c%s*(&?[Hh]%x+&?)" if tags\match "\\1?c%s*&?[Hh]%x+&?"
                styles[k].color2    = tags\match "\\2c%s*(&?[Hh]%x+&?)" if tags\match "\\2c%s*&?[Hh]%x+&?"
                styles[k].color3    = tags\match "\\3c%s*(&?[Hh]%x+&?)" if tags\match "\\3c%s*&?[Hh]%x+&?"
                styles[k].color4    = tags\match "\\4c%s*(&?[Hh]%x+&?)" if tags\match "\\4c%s*&?[Hh]%x+&?"
                styles[k].bold      = true if tags\match "\\b%s*1"
                styles[k].italic    = true if tags\match "\\i%s*1"
                styles[k].underline = true if tags\match "\\u%s*1"
                styles[k].strikeout = true if tags\match "\\s%s*1"
        return meta, styles

    find_coords: (line, meta, ogp) => -- finds coordinates of some tags
        coords = {
            pos:   {x: 0, y: 0}
            move:  {x1: 0, y1: 0, x2: 0, y2: 0}
            org:   {x: 0, y: 0}
            rots:  {frz: line.styleref.angle or 0, fax: 0, fay: 0, frx: 0, fry: 0}
            scale: {x: line.styleref.scale_x or 0, y: line.styleref.scale_y or 0}
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
            if line.text\match "\\move%(%s*%-?%d[%.%d]*%s*,%s*%-?%d[%.%d]*%s*,%s*%-?%d[%.%d]*%s*,%s*%-?%d[%.%d]*%s*"
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
        if ogp
            unless line.text\match "\\org%b()"
                coords.org.x = coords.pos.x
                coords.org.y = coords.pos.y
        return coords

    html_color: (color, mode = "to_rgb") => -- transform an html color to hexadecimal and the other way around
        c =  ""
        switch mode
            when "to_rgb"
                color = color\gsub "(%x%x)(%x%x)(%x%x)", (b, g, r) ->
                    c = "&H#{r}#{g}#{b}&"
            when "to_html"
                rgb_color = util.color_from_style(rgb_color)
                rgb_color = rgb_color\gsub "&[hH](%x%x)(%x%x)(%x%x)&", (r, g, b) ->
                    c = "##{b}#{g}#{r}"
        return c

    file_exist: (file, dir) =>
        file ..= "/" if dir
        ok, err, code = os.rename(file, file)
        unless ok
            return true if code == 13
        return ok, err

    clip_to_draw: (clip) => -- converts data from clip to shape
        local shape
        if clip\match("\\i?clip%b()")
            unless clip\match("\\i?clip%(m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*%)")
                l, t, r, b = clip\match "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
                shape = "m #{l} #{t} l #{r} #{t} l #{r} #{b} l #{l} #{b}"
            else
                shape = clip\match("\\i?clip%((m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)")
        else
            shape = clip
        return shape

class TAGS

    new: (tags) =>
        @tags = tags

    find: => -- finds and returns the raw tags
        if @tags\match("%b{}") then @tags\match("%b{}")\sub(2, -2) else ""

    clean: (text) => -- Aegisub Macro - Clean Tags
        ktag = "\\[kK][fo]?%d+"
        combineadjacentnotks = (block1, block2) ->
            if string.find(block1, ktag) and string.find(block2, ktag)
                "{#{block1}}#{string.char(1)}{#{block2}}"
            else
                "{#{block1}#{block2}}"
        while true
            return if aegisub.progress.is_cancelled!
            text, replaced = string.gsub(text, "{(.-)}{(.-)}", combineadjacentnotks)
            break if replaced == 0
        text = text\gsub(string.char(1), "")\gsub("{([^{}]-)(" .. ktag .. ")(.-)}", "{%2%1%3}")
        while true
            return if aegisub.progress.is_cancelled!
            text, replaced = text\gsub("{([^{}]-)(" .. ktag .. ")(\\[^kK][^}]-)(" .. ktag .. ")(.-)}", "{%1%2%4%3%5}")
            break if replaced == 0
        linetags = ""
        first = (pattern) ->
            p_s, _, p_tag = text\find(pattern)
            if p_s
                text = text\gsub(pattern, "")
                linetags ..= p_tag
        firstoftwo = (pattern1, pattern2) ->
            p1_s, _, p1_tag = text\find(pattern1)
            p2_s, _, p2_tag = text\find(pattern2)
            text = text\gsub(pattern1, "")\gsub(pattern2, "")
            if p1_s and (not p2_s or p1_s < p2_s)
                linetags ..= p1_tag
            elseif p2_s
                linetags ..= p2_tag
        first("(\\an?%d+)")
        first("(\\org%([^,%)]*,[^,%)]*%))")
        firstoftwo("(\\move%([^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*%))", "(\\pos%([^,%)]*,[^,%)]*%))")
        firstoftwo("(\\fade%([^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*,[^,%)]*%))", "(\\fad%([^,%)]*,[^,%)]*%))")
        if linetags\len! > 0
            if text\sub(1, 1) == "{" then text = "{#{linetags}#{text\sub(2)}" else text = "{#{linetags}}#{text}"
        comb = (a, b, c, d, e) ->
            if (c != "\\clip" and c != "\\iclip") or d\sub(-1)\find("[,%({]") or e\sub(1, 1)\find("[,%)}]") then
                a .. b .. d .. e
            else
                a .. b .. d .. string.char(2) .. e
        while true
            text, replaced2 = text\gsub("({[^}\\]*)([^}%s]*(\\[^%(}\\%s]*))%s*(%([^%s%)}]*)%s+([^}]*)", comb)
            break if replaced2 == 0
        text, _ = text\gsub(string.char(2), " ")
        text\gsub("{%s*}", "")

    remove: (modes = "full", tags) => -- only a tag removal repository
        @tags = tags or @find!
        caps = {
            fn: "\\fn%s*[^\\}]*", fs: "\\fs%s*%d[%.%d]*", fsp: "\\fsp%s*%-?%d[%.%d]*"
            fscx: "\\fscx%s*%d[%.%d]*", fscy: "\\fscy%s*%d[%.%d]*", b: "\\b%s*%d"
            i: "\\i%s*%d", s: "\\s%s*%d", u: "\\u%s*%d"
            p: "\\p%d", an: "\\an%d", fr: "\\fr%s*[z]?%-?%d+[%.%d]*"
            frx: "\\frx%s*%-?%d+[%.%d]*", fry: "\\fry%s*%-?%d+[%.%d]*", fax: "\\fax%s*%-?%d+[%.%d]*"
            fay: "\\fay%s*%-?%d+[%.%d]*", pos: "\\pos%b()", org: "\\org%b()"
            _1c: "\\1?c%s*&H%x+&", _2c: "\\2c%s*&H%x+&", _3c: "\\3c%s*&H%x+&"
            _4c: "\\4c%s*&H%x+&", bord: "\\[xy]?bord%s*%d[%.%d]*", clip: "\\i?clip%b()"
            shad: "\\[xy]?shad%s*%-?%d[%.%d]*", move:"\\move%b()"
        }
        switch modes
            when "shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_poly"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_gradient"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.bord, "\\bord0")\gsub(caps._1c, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.shad, "\\shad0")\gsub(caps.an, "\\an7")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\shad0" unless @tags\match(caps.shad)
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "text_shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.fscx, "\\fscx100")
                @tags = @tags\gsub(caps.fscy, "\\fscy100")\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "shape_clip"
                @tags ..= "\\p1" unless @tags\match(caps.p)
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.clip, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
            when "text_clip"
                @tags = @tags\gsub(caps.clip, "")
            when "shape_expand"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")\gsub(caps.fscx, "\\fscx100")
                @tags = @tags\gsub(caps.fscy, "\\fscy100")\gsub(caps.fr, "")\gsub(caps.frx, "")\gsub(caps.fry, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.fay, "")\gsub(caps.org, "")
                @tags = @tags\gsub(caps.fax, "")\gsub(caps.an, "\\an7")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "full"
                @tags = @tags\gsub("%b{}", "")\gsub("\\h", " ")
            when "bezier_text"
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.pos, "")\gsub(caps.move, "")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.fsp, "")
            when "out"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps._1c, "")\gsub(caps.bord, "\\bord0")\gsub(caps.an, "\\an7")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\p1" unless @tags\match(caps.p)
        @tags

return {
    math:  MATH
    table: TABLE
    poly:  POLY
    shape: SHAPER
    text:  TEXT
    util:  SUPPORT
    tags:  TAGS
}