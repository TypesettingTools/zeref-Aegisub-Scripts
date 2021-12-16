import MATH, POLYNOMIAL from require "ZF.util.math"
import POINT from require "ZF.2D.point"
import TABLE from require "ZF.util.table"

class BEZIER

    new: (...) =>
        args, @paths = {...}, {POINT!, POINT!, t: "l"}
        switch #args
            when 1
                val = args[1].paths and args[1].paths or args[1]
                for k = 1, #val
                    @paths[k] = POINT val[k]
            when 2, 3, 4, 6, 8
                condition = #args >= 4 and type(args[1]) == "number"
                for k = 1, condition and #args / 2 or #args
                    @paths[k] = condition and POINT(args[k + (k - 1)], args[k + k]) or POINT args[k]
        @paths.t = #@paths == 2 and "l" or "b"

    pLen: => #@paths
    unpack: => @paths[1], @paths[2], @paths[3], @paths[4]

    assert: (t) =>
        len, msg = @pLen!, "The paths do not correspond with a"
        switch t
            when "linear"
                assert len == 2, "#{msg} Linear Bezier"
            when "quadratic"
                assert len == 3, "#{msg} Quadratic Bezier"
            when "cubic"
                assert len == 4, "#{msg} Cubic Bezier"
        return @

    __add: (p = 0) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 + p, p2 + p, p3 and p3 + p or nil, p4 and p4 + p or nil

    __sub: (p = 0) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 - p, p2 - p, p3 and p3 - p or nil, p4 and p4 - p or nil

    __mul: (p = 1) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 * p, p2 * p, p3 and p3 * p or nil, p4 and p4 * p or nil

    __div: (p = 1) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 / p, p2 / p, p3 and p3 / p or nil, p4 and p4 / p or nil

    __mod: (p = 1) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 % p, p2 % p, p3 and p3 % p or nil, p4 and p4 % p or nil

    __pow: (p = 1) =>
        p1, p2, p3, p4 = @unpack!
        BEZIER p1 ^ p, p2 ^ p, p3 and p3 ^ p or nil, p4 and p4 ^ p or nil

    __tostring: =>
        pt = @paths
        switch #pt
            when 2 then "m #{pt[1].x} #{pt[1].y} l #{pt[2].x} #{pt[2].y} "
            when 3 then "m #{pt[1].x} #{pt[1].y} b #{pt[2].x} #{pt[2].y} #{pt[2].x} #{pt[2].y} #{pt[3].x} #{pt[3].y} "
            when 4 then "m #{pt[1].x} #{pt[1].y} b #{pt[2].x} #{pt[2].y} #{pt[3].x} #{pt[3].y} #{pt[4].x} #{pt[4].y} "

    round: (dec = 0) =>
        for p, path in ipairs @paths
            path\round dec
        return @

    reverse: =>
        p = {@unpack!}
        for k = 1, #p
            @paths[k] = p[#p + 1 - k]
        return @

    linear: (t, b0, b1) => (1 - t) * b0 + t * b1
    quadratic: (t, b0, b1, b2) => (1 - t) ^ 2 * b0 + 2 * t * (1 - t) * b1 + t ^ 2 * b2
    cubic: (t, b0, b1, b2, b3) => (1 - t) ^ 3 * b0 + 3 * t * (1 - t) ^ 2 * b1 + 3 * t ^ 2 * (1 - t) * b2 + t ^ 3 * b3

    getPoint: (t) =>
        p1, p2, p3, p4, x, y = @unpack!

        switch @pLen!
            when 2
                x = @linear t, p1.x, p2.x
                y = @linear t, p1.x, p2.x
            when 3
                x = @quadratic t, p1.x, p2.x, p3.x
                y = @quadratic t, p1.y, p2.y, p3.y
            when 4
                x = @cubic t, p1.x, p2.x, p3.x, p4.x
                y = @cubic t, p1.y, p2.y, p3.y, p4.y

        return POINT x, y

    midPoint: => @getPoint 0.5

    linearAngle: =>
        @assert "linear"

        p1, p2 = @unpack!

        p = p2 - p1
        return atan2 p.y, p.x

    casteljau: (init = 0, len = @length!, reduce = 1) =>
        add, path, len = {}, @paths, MATH\round len / reduce, 0
        for k = init, len
            newPoint, t = POINT!, k / len
            switch #path
                when 2
                    newPoint.x = @linear t, path[1].x, path[2].x
                    newPoint.y = @linear t, path[1].y, path[2].y
                when 3
                    newPoint.x = @quadratic t, path[1].x, path[2].x, path[3].x
                    newPoint.y = @quadratic t, path[1].y, path[2].y, path[3].y
                when 4
                    newPoint.x = @cubic t, path[1].x, path[2].x, path[3].x, path[4].x
                    newPoint.y = @cubic t, path[1].y, path[2].y, path[3].y, path[4].y
            TABLE(add)\push newPoint
        return add

    rotate: (c = @midPoint!, angle) =>
        for i = 1, @pLen!
            @paths[i]\rotate c, angle
        return @

    linear2quadratic: =>
        @assert "linear"

        p1, p2 = @unpack!
        q1 = POINT p1
        q2 = POINT (p1.x + p2.x) / 2, (p1.y + p2.y) / 2
        q3 = POINT p2
        return BEZIER q1, q2, q3

    linear2cubic: =>
        @assert "linear"

        p1, p2 = @unpack!
        c1 = POINT p1
        c2 = POINT (2 * p1.x + p2.x) / 3, (2 * p1.y + p2.y) / 3
        c3 = POINT (p1.x + 2 * p2.x) / 3, (p1.y + 2 * p2.y) / 3
        c4 = POINT p2
        return BEZIER c1, c2, c3, c4

    quadratic2cubic: =>
        @assert "quadratic"

        p1, p2, p3 = @unpack!
        c1 = POINT p1
        c2 = POINT (p1.x + 2 * p2.x) / 3, (p1.y + 2 * p2.y) / 3
        c3 = POINT (p3.x + 2 * p2.x) / 3, (p3.y + 2 * p2.y) / 3
        c4 = POINT p3
        return BEZIER c1, c2, c3, c4

    split: (t) =>
        local p1, p2, p3, p4, p5, p6
        switch @pLen!
            when 2
                p1 = @paths[1]\lerp @paths[2], t
                {
                    BEZIER @paths[1], p1
                    BEZIER p1, @paths[2]
                }
            when 3
                p1 = @paths[1]\lerp @paths[2], t
                p2 = @paths[2]\lerp @paths[3], t
                p3 = p1\lerp p2, t
                {
                    BEZIER @paths[1], p1, p3
                    BEZIER p3, p2, @paths[3]
                }
            when 4
                p1 = @paths[1]\lerp @paths[2], t
                p2 = @paths[2]\lerp @paths[3], t
                p3 = @paths[3]\lerp @paths[4], t
                p4 = p1\lerp p2, t
                p5 = p2\lerp p3, t
                p6 = p4\lerp p5, t
                {
                    BEZIER @paths[1], p1, p4, p6
                    BEZIER p6, p5, p3, @paths[4]
                }

    splitInInterval: (s = 0, e = 1) =>
        u = (e - s) / (1 - s)

        s1 = @split s
        s2 = @split e
        s3 = s1[2]\split u

        return s3[1]

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

            TABLE(splines)\push BEZIER i > 1 and splines[i - 1].paths[4] or points[1], cp1, cp2, p2

        return splines

    coefficient: =>
        local p1, p2, p3, p4
        switch @pLen!
            when 3
                p1, p2, p3 = @unpack!
                {
                    POINT p1.x - 2 * p2.x + p3.x, p1.y - 2 * p2.y + p3.y
                    POINT 2 * (p2.x - p1.x), 2 * (p2.y - p1.y)
                    POINT p1.x, p1.y
                }
            when 4
                p1, p2, p3, p4 = @unpack!
                {
                    POINT p4.x - p1.x + 3 * (p2.x - p3.x), p4.y - p1.y + 3 * (p2.y - p3.y)
                    POINT 3 * p1.x - 6 * p2.x + 3 * p3.x, 3 * p1.y - 6 * p2.y + 3 * p3.y
                    POINT 3 * (p2.x - p1.x), 3 * (p2.y - p1.y)
                    POINT p1.x, p1.y
                }

    derivative: (t, coef) =>
        a, b, c = unpack coef
        switch @pLen!
            when 3 then POINT 2 * a.x * t + b.x, 2 * a.y * t + b.y
            when 4 then POINT c.x + t * (2 * b.x + 3 * a.x * t), c.y + t * (2 * b.y + 3 * a.y * t)

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
        switch @pLen!
            when 2
                len = @paths[1]\distance @paths[2]
            when 3, 4
                coef = @coefficient!

                Z = t / 2
                for i = 1, #abscissas
                    fixT = Z * abscissas[i] + Z
                    derv = @derivative fixT, coef
                    len += weights[i] * derv\hypot!

                len *= Z

        return len

    linearOffset: (size = 0) =>
        @assert "cubic"

        p1, p2 = @unpack!

        d = POINT -(p2.y - p1.y), p2.x - p1.x
        k = size / @length!

        p1 -= d * k
        p2 -= d * k

        return BEZIER p1, p2

    linearBoudingBox: =>
        p1, p2 = @unpack!

        left   = p2.x < p1.x and p2.x or p1.x
        top    = p2.y < p1.y and p2.y or p1.y
        right  = p2.x > p1.x and p2.x or p1.x
        bottom = p2.y > p1.y and p2.y or p1.y

        return left, top, right, bottom

    quadraticBoudingBox: =>
        cubic = @quadratic2cubic!
        return cubic\cubicBoudingBox!

    -- https://stackoverflow.com/a/34882840
    cubicBoudingBox: =>
        @assert "cubic"

        p1, p2, p3, p4 = @unpack!

        vt = {}
        for i = 1, 2
            axi = i == 1 and "x" or "y"

            a = -3 * p1[axi] + 9 * p2[axi] - 9 * p3[axi] + 3 * p4[axi]
            b = 6 * p1[axi] - 12 * p2[axi] + 6 * p3[axi]
            c = 3 * p2[axi] - 3 * p1[axi]

            if abs(a) < 1e-12
                if abs(b) < 1e-12
                    continue
                t = -c / b
                if 0 < t and t < 1
                    TABLE(vt)\push t
                continue

            delta = b ^ 2 - 4 * c * a

            if delta < 0
                if abs(delta) < 1e-12
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

        left   = p4.x < p1.x and p4.x or p1.x
        top    = p4.y < p1.y and p4.y or p1.y
        right  = p4.x > p1.x and p4.x or p1.x
        bottom = p4.y > p1.y and p4.y or p1.y

        for v, t in ipairs vt
            x = @cubic t, p1.x, p2.x, p3.x, p4.x
            y = @cubic t, p1.y, p2.y, p3.y, p4.y

            left   = min left, x
            top    = min top, y
            right  = max right, x
            bottom = max bottom, y

        return left, top, right, bottom

    -- https://stackoverflow.com/a/49402756
    cubicGetYbyX: (x = 0) =>
        @assert "cubic"

        p1, p2, p3, p4 = @unpack!

        a = -p1.x + 3 * p2.x - 3 * p3.x + p4.x
        b = 3 * p1.x - 6 * p2.x + 3 * p3.x
        c = -3 * p1.x + 3 * p2.x
        d = p1.x - x

        t, points = POLYNOMIAL(a, b, c, d)\cubicRoots!, {}

        for i = 1, #t
            px, py = x, @cubic t[i], p1.y, p2.y, p3.y, p4.y
            points[i] = POINT px, py

        return points

    l2lIntersection: (linear) =>
        x1, y1 = @paths[1].x, @paths[1].y
        x2, y2 = @paths[2].x, @paths[2].y
        x3, y3 = linear.paths[1].x, linear.paths[1].y
        x4, y4 = linear.paths[2].x, linear.paths[2].y

        d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        t = (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)
        u = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)

        status = "parallel"
        if d != 0
            t /= d
            u /= d
            if 0 <= t and t <= 1 and 0 <= u and u <= 1
                status = "intersected"
                return status, @paths[1]\lerp @paths[2], t
            else
                status = "not intersected"
        elseif t == 0 or u == 0
            status = "coincide"

        return status

    c2lIntersection: (linear) =>
        result, status = {}, "not intersected"

        p1, p2, p3, p4 = @unpack!

        a1 = linear.paths[1]
        a2 = linear.paths[2]

        pmin = a1\min a2
        pmax = a1\max a2

        coef = @coefficient!

        N = POINT a1.y - a2.y, a2.x - a1.x
        C = a1.x * a2.y - a2.x * a1.y

        P = {
            N\dot(coef[1])
            N\dot(coef[2])
            N\dot(coef[3])
            N\dot(coef[4]) + C
        }

        roots = POLYNOMIAL(P)\getRoots!
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