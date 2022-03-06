import MATH  from require "ZF.util.math"
import TABLE from require "ZF.util.table"
import POINT from require "ZF.2D.point"

bit = require "bit"

class BEZIER

    -- @param ... POINT || BEZIER
    new: (...) =>
        args, @bz = {...}, {POINT!, POINT!, t: "l"}
        switch #args
            when 1
                val = args[1].bz and args[1].bz or args[1]
                for k = 1, #val
                    @bz[k] = POINT val[k]
            when 2, 4, 8
                condition = #args >= 4 and type(args[1]) == "number"
                for k = 1, condition and #args / 2 or #args
                    @bz[k] = condition and POINT(args[k * 2 - 1], args[k * 2]) or POINT args[k]
        @bz.t = #@bz == 2 and "l" or "b"

    unpack: => @bz[1], @bz[2], @bz[3], @bz[4]

    -- @param t string
    -- @return BEZIER
    assert: (t) =>
        len, msg = #@bz, "The paths do not correspond with a"
        if t == "linear"
            assert len == 2, "#{msg} Linear Bezier"
        elseif t == "cubic"
            assert len == 4, "#{msg} Cubic Bezier"
        return @

    -- @param p number || POINT
    -- @return BEZIER
    __add: (p = 0) =>
        a, b, c, d = @unpack!
        BEZIER a + p, b + p, c and c + p or nil, d and d + p or nil

    -- @param p number || POINT
    -- @return BEZIER
    __sub: (p = 0) =>
        a, b, c, d = @unpack!
        BEZIER a - p, b - p, c and c - p or nil, d and d - p or nil

    -- @param p number || POINT
    -- @return BEZIER
    __mul: (p = 1) =>
        a, b, c, d = @unpack!
        BEZIER a * p, b * p, c and c * p or nil, d and d * p or nil

    -- @param p number || POINT
    -- @return BEZIER
    __div: (p = 1) =>
        a, b, c, d = @unpack!
        BEZIER a / p, b / p, c and c / p or nil, d and d / p or nil

    -- @param p number || POINT
    -- @return BEZIER
    __mod: (p = 1) =>
        a, b, c, d = @unpack!
        BEZIER a % p, b % p, c and c % p or nil, d and d % p or nil

    -- @param p number || POINT
    -- @return BEZIER
    __pow: (p = 1) =>
        a, b, c, d = @unpack!
        BEZIER a ^ p, b ^ p, c and c ^ p or nil, d and d ^ p or nil

    -- @param len number
    -- @return string
    __tostring: (len = #@bz) =>
        a, b, c, d = @unpack!
        switch len
            when 1 then "#{a.x} #{a.y} "
            when 2 then "#{b.x} #{b.y} "
            when 4 then "#{b.x} #{b.y} #{c.x} #{c.y} #{d.x} #{d.y} "

    -- rounds the points
    -- @param dec number
    -- @return BEZIER
    round: (dec = 0) =>
        for p, path in ipairs @bz
            path\round dec
        return @

    -- inverts the order of the segment
    -- @return BEZIER
    inverse: =>
        p = {@unpack!}
        for k = 1, #p
            @bz[k] = p[#p + 1 - k]
        return @

    -- gets the point on the linear segment through time
    -- @param t number
    -- @return POINT
    linear: (t) =>
        @assert "linear"
        a, b = @unpack!

        x = (1 - t) * a.x + t * b.x
        y = (1 - t) * a.y + t * b.y
        return POINT x, y

    -- gets the point on the bezier segment through time
    -- @param t number
    -- @return POINT
    cubic: (t) =>
        @assert "cubic"
        a, b, c, d = @unpack!

        x = (1 - t) ^ 3 * a.x + 3 * t * (1 - t) ^ 2 * b.x + 3 * t ^ 2 * (1 - t) * c.x + t ^ 3 * d.x
        y = (1 - t) ^ 3 * a.y + 3 * t * (1 - t) ^ 2 * b.y + 3 * t ^ 2 * (1 - t) * c.y + t ^ 3 * d.y
        return POINT x, y

    -- rotates the segment
    -- @param c POINT
    -- @param angle number
    -- @return BEZIER
    rotate: (c = @getMidPoint!, angle) =>
        for i = 1, #@bz
            @bz[i]\rotate c, angle
        return @

    -- rotates the segment
    -- @param t number
    -- @param fix boolean
    -- @return POINT
    getPoint: (t, fix) =>
        switch #@bz
            when 2 then @linear t
            when 4 then fix and @fixCasteljauPoint(t) or @cubic t
            else error "expected a linear bezier or a cubic bezier"

    -- gets the midpoint of the segment
    -- @return POINT
    getMidPoint: => @getPoint 0.5, true

    -- gets the normalized tangent through time
    -- @param t number
    -- @param inverse boolean
    -- @return POINT, POINT, number
    getNormal: (t, inverse) =>
        @allCubic!
        t = @fixCasteljauMap t
        pnt = @getPoint t
        tan = @cubicDerivative t
        with tan
            if inverse
                .x, .y = -.y, .x
            else
                .x, .y = .y, -.x
            tan /= tan\vecDistanceSqrt!
        return tan, pnt, t

    -- gets the angle of the linear segment
    -- @return number
    linearAngle: =>
        @assert "linear"
        a, b = @unpack!

        p = b - a
        return atan2 p.y, p.x

    -- https://gamedev.stackexchange.com/a/5427
    -- @param len integer
    -- @return table, number
    fixCasteljau: (len = 100) =>
        arcLens, o, sum = {0}, @getPoint(0), 0
        for i = 1, len
            p = @getPoint i * (1 / len)
            d = o - p
            sum += d\vecDistanceSqrt!
            arcLens[i + 1] = sum
            o = p
        return arcLens, len

    -- gets a new uniformed time
    -- @param u number
    -- @param len integer
    -- @return number
    fixCasteljauMap: (u, len) =>
        arcLens, len = @fixCasteljau len

        tLen = u * arcLens[len]
        low, i, high = 0, 0, len

        while low < high
            i = low + bit.bor (high - low) / 2, 0
            if arcLens[i + 1] < tLen
                low = i + 1
            else
                high = i

        if arcLens[i + 1] > tLen
            i -= 1

        lenB, last = arcLens[i + 1], len - 1
        return lenB == tLen and i / last or (i + (tLen - lenB) / (arcLens[i + 2] - lenB)) / last

    -- gets the bezier point with uniform time
    -- @param u number
    -- @return POINT
    fixCasteljauPoint: (u) => @getPoint @fixCasteljauMap u

    -- flattens the segment
    -- @param srt integer
    -- @param len integer
    -- @param red integer
    -- @param fix boolean
    -- @return table
    casteljau: (srt = 0, len = @length!, red = 1, fix = true) =>
        points, len = {}, MATH\round len / red, 0
        for i = srt, len
            TABLE(points)\push @getPoint i / len, fix
        return points

    -- transforms a linear segment into a bezier segment
    -- @return BEZIER
    linear2cubic: =>
        @assert "linear"
        a, d = @unpack!

        b = POINT (2 * a.x + d.x) / 3, (2 * a.y + d.y) / 3
        c = POINT (a.x + 2 * d.x) / 3, (a.y + 2 * d.y) / 3
        return BEZIER a, b, c, d

    -- transforms a linear segment into a bezier segment
    -- @return BEZIER
    allCubic: =>
        @ = #@bz == 2 and @linear2cubic! or @
        return @

    -- splits the segment into two parts
    -- @param t number
    -- @return table
    split: (t = 0.5) =>
        t = MATH\clamp t, 0, 1
        a, b, c, d = @unpack!
        switch #@bz
            when 2
                v1 = a\lerp b, t
                {
                    BEZIER a, v1
                    BEZIER v1, b
                }
            when 4
                v1 = a\lerp b, t
                v2 = b\lerp c, t
                v3 = c\lerp d, t
                v4 = v1\lerp v2, t
                v5 = v2\lerp v3, t
                v6 = v4\lerp v5, t
                {
                    BEZIER a, v1, v4, v6
                    BEZIER v6, v5, v3, d
                }

    -- splits the segment in a time interval
    -- @param s number
    -- @param e number
    -- @return BEZIER
    splitInInterval: (s = 0, e = 1) =>
        s = MATH\clamp s, 0, 1
        e = MATH\clamp e, 0, 1
        s, e = e, s if s > e

        u = (e - s) / (1 - s)
        u = u != u and e or u

        a = @split s
        b = a[2]\split u
        return b[1]

    -- transforms points into bezier segments
    -- @param points table
    -- @param tension number 
    -- @return table
    spline: (points, tension = 1) =>
        splines = {}
        for i = 1, #points - 1
            p1 = i > 1 and points[i - 1] or points[1]
            p2 = points[i]
            p3 = points[i + 1]
            p4 = (i != #points - 1) and points[i + 2] or p2

            cp1x = p2.x + (p3.x - p1.x) / 6 * tension
            cp1y = p2.y + (p3.y - p1.y) / 6 * tension
            cp1 = POINT cp1x, cp1y

            cp2x = p3.x - (p4.x - p2.x) / 6 * tension
            cp2y = p3.y - (p4.y - p2.y) / 6 * tension
            cp2 = POINT cp2x, cp2y

            TABLE(splines)\push BEZIER i > 1 and splines[i - 1].bz[4] or points[1], cp1, cp2, p2
        return splines

    -- gets the cubic coefficient of the bezier segment
    -- @return table
    cubicCoefficient: =>
        @assert "cubic"
        a, b, c, d = @unpack!
        {
            POINT d.x - a.x + 3 * (b.x - c.x), d.y - a.y + 3 * (b.y - c.y)
            POINT 3 * a.x - 6 * b.x + 3 * c.x, 3 * a.y - 6 * b.y + 3 * c.y
            POINT 3 * (b.x - a.x), 3 * (b.y - a.y)
            POINT a.x, a.y
        }

    -- gets the cubic derivative of the bezier segment
    -- @param t number
    -- @param coef table
    -- @return POINT
    cubicDerivative: (t, coef = @cubicCoefficient!) =>
        @assert "cubic"
        a, b, c = unpack coef
        x = c.x + t * (2 * b.x + 3 * a.x * t)
        y = c.y + t * (2 * b.y + 3 * a.y * t)
        return POINT x, y

    -- gets the real length of the segment through time
    -- @param t number
    -- @return number
    length: (t = 1) =>

        abscissas = {
            -0.0640568928626056299791002857091370970011, 0.0640568928626056299791002857091370970011
            -0.1911188674736163106704367464772076345980, 0.1911188674736163106704367464772076345980
            -0.3150426796961633968408023065421730279922, 0.3150426796961633968408023065421730279922
            -0.4337935076260451272567308933503227308393, 0.4337935076260451272567308933503227308393
            -0.5454214713888395626995020393223967403173, 0.5454214713888395626995020393223967403173
            -0.6480936519369755455244330732966773211956, 0.6480936519369755455244330732966773211956
            -0.7401241915785543579175964623573236167431, 0.7401241915785543579175964623573236167431
            -0.8200019859739029470802051946520805358887, 0.8200019859739029470802051946520805358887
            -0.8864155270044010714869386902137193828821, 0.8864155270044010714869386902137193828821
            -0.9382745520027327978951348086411599069834, 0.9382745520027327978951348086411599069834
            -0.9747285559713094738043537290650419890881, 0.9747285559713094738043537290650419890881
            -0.9951872199970213106468008845695294439793, 0.9951872199970213106468008845695294439793
        }

        weights = {
            0.1279381953467521593204025975865079089999, 0.1279381953467521593204025975865079089999
            0.1258374563468283025002847352880053222179, 0.1258374563468283025002847352880053222179
            0.1216704729278033914052770114722079597414, 0.1216704729278033914052770114722079597414
            0.1155056680537255991980671865348995197564, 0.1155056680537255991980671865348995197564
            0.1074442701159656343712356374453520402312, 0.1074442701159656343712356374453520402312
            0.0976186521041138843823858906034729443491, 0.0976186521041138843823858906034729443491
            0.0861901615319532743431096832864568568766, 0.0861901615319532743431096832864568568766
            0.0733464814110802998392557583429152145982, 0.0733464814110802998392557583429152145982
            0.0592985849154367833380163688161701429635, 0.0592985849154367833380163688161701429635
            0.0442774388174198077483545432642131345347, 0.0442774388174198077483545432642131345347
            0.0285313886289336633705904233693217975087, 0.0285313886289336633705904233693217975087
            0.0123412297999872001830201639904771582223, 0.0123412297999872001830201639904771582223
        }

        len = 0
        switch #@bz
            when 2
                len += @bz[1]\distance @bz[2]
            when 4
                coef, Z = @cubicCoefficient!, t / 2
                for i = 1, #abscissas
                    fixT = Z * abscissas[i] + Z
                    derv = @cubicDerivative fixT, coef
                    len += weights[i] * derv\hypot!
                len *= Z

        return len

    -- checks if the point is on the line segment
    -- @param c POINT
    -- @param ep number
    -- @return boolean
    pointIsOnLine: (c, ep = 1e-6) =>
        @assert "linear"
        a, b = @unpack!
        dab = a\distance b
        dac = a\distance c
        dbc = b\distance c
        dff = dab - dac + dbc
        return -ep < dff and dff < ep

    -- offsets the linear segment
    -- @param size number
    -- @return BEZIER
    linearOffset: (size = 0) =>
        @assert "linear"
        a, b = @unpack!

        d = POINT -(b.y - a.y), b.x - a.x
        k = size / @length!

        a -= d * k
        b -= d * k
        return BEZIER a, b

    -- gets the linear bounding box
    -- @return number, number, number, number
    linearBoudingBox: =>
        @assert "linear"
        p1, p2 = @unpack!

        {x: x1, y: y1} = p1
        {x: x2, y: y2} = p2

        l = x2 < x1 and x2 or x1
        t = y2 < y1 and y2 or y1
        r = x2 > x1 and x2 or x1
        b = y2 > y1 and y2 or y1

        return l, t, r, b

    -- gets the bezier bounding box
    -- https://stackoverflow.com/a/34882840
    -- @param ep number
    -- @return number, number, number, number
    cubicBoudingBox: (ep = 1e-12) =>
        @assert "cubic"
        p1, p2, p3, p4 = @unpack!

        vt = {}
        for axi in *{"x", "y"}
            a = -3 * p1[axi] + 9 * p2[axi] - 9 * p3[axi] + 3 * p4[axi]
            b = 6 * p1[axi] - 12 * p2[axi] + 6 * p3[axi]
            c = 3 * p2[axi] - 3 * p1[axi]

            if abs(a) < ep
                if abs(b) < ep
                    continue
                t = -c / b
                if 0 < t and t < 1
                    TABLE(vt)\push t
                continue

            delta = b ^ 2 - 4 * c * a

            if delta < 0
                if abs(delta) < ep
                    t = -b / (2 * a)
                    if 0 < t and t < 1
                        TABLE(vt)\push t
                continue

            bhaskara = {
                (-b + sqrt(delta)) / (2 * a)
                (-b - sqrt(delta)) / (2 * a)
            }

            for _, t in ipairs bhaskara
                if 0 < t and t < 1
                    TABLE(vt)\push t

        l, t, r, b = BEZIER(p1, p4)\linearBoudingBox!
        for v in *vt
            with @cubic v
                l = min l, .x
                t = min t, .y
                r = max r, .x
                b = max b, .y

        return l, t, r, b

    -- gets the bounding box
    -- @param typer string
    -- @return number, number, number, number
    boudingBox: (typer) =>
        if typer == "real"
            switch #@bz
                when 2 then @linearBoudingBox!
                when 4 then @cubicBoudingBox!
        else
            l, t, r, b = math.huge, math.huge, -math.huge, -math.huge
            for {:x, :y} in *@bz
                l, t = min(l, x), min(t, y)
                r, b = max(r, x), max(b, y)
            return l, t, r, b

    -- finds intersections between linear segments
    -- @param linear BEZIER
    -- @return string, POINT
    l2lIntersection: (linear) =>
        @assert "linear"
        {x: x1, y: y1}, {x: x2, y: y2} = @bz[1], @bz[2]
        {x: x3, y: y3}, {x: x4, y: y4} = linear.bz[1], linear.bz[2]

        d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        t = (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)
        u = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)

        status = "parallel"
        if d != 0
            t /= d
            u /= d
            if 0 <= t and t <= 1 and 0 <= u and u <= 1
                status = "intersected"
                return status, @bz[1]\lerp @bz[2], t
            else
                status = "not intersected"
        elseif t == 0 or u == 0
            status = "coincide"

        return status

    -- finds intersections between bezier segments and linear segments
    -- @param linear BEZIER
    -- @return string, table
    c2lIntersection: (linear) =>
        @assert "cubic"
        p1, p2, p3, p4 = @unpack!

        result, status = {}, "not intersected"
        {a1, a2} = linear.bz

        pmin = a1\min a2
        pmax = a1\max a2

        coef = @cubicCoefficient!

        N = POINT a1.y - a2.y, a2.x - a1.x
        C = a1.x * a2.y - a2.x * a1.y

        P = {
            N\dot(coef[1])
            N\dot(coef[2])
            N\dot(coef[3])
            N\dot(coef[4]) + C
        }

        roots = MATH\cubicRoots unpack P
        for _, t in ipairs roots
            p5  = p1\lerp p2, t
            p6  = p2\lerp p3, t
            p7  = p3\lerp p4, t
            p8  = p5\lerp p6, t
            p9  = p6\lerp p7, t
            p10 = p8\lerp p9, t
            if a1.x == a2.x
                if pmin.y <= p10.y and p10.y <= pmax.y
                    status = "intersected"
                    TABLE(result)\push p10
            elseif a1.y == a2.y
                if pmin.x <= p10.x and p10.x <= pmax.x
                    status = "intersected"
                    TABLE(result)\push p10
            elseif pmin.x <= p10.x and p10.x <= pmax.x and pmin.y <= p10.y and p10.y <= pmax.y
                status = "intersected"
                TABLE(result)\push p10

        return status, result

{:BEZIER}