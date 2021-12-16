import BEZIER from require "ZF.2D.bezier"
import MATH   from require "ZF.util.math"
import POINT  from require "ZF.2D.point"
import TABLE  from require "ZF.util.table"
import UTIL   from require "ZF.util.util"

class SHAPE

    new: (shape, close = true) =>
        isNumber = (v) -> type(v) == "number" and v or error "unknown shape"
        isString = (v) -> tonumber(v) == nil

        @paths = {}
        if type(shape) == "string"
            data = [isString(v) and v or tonumber(v) for v in shape\gmatch "%S+"]
            for k = 1, #data
                switch data[k]
                    when "m"
                        x1 = isNumber data[k + 1]
                        y1 = isNumber data[k + 2]
                        @paths[#@paths + 1] = {{POINT(x1, y1), t: "m"}}
                    when "l"
                        i = 1
                        while type(data[k + i]) == "number"
                            p0 = TABLE(@paths[#@paths][#@paths[#@paths]][#@paths[#@paths][#@paths[#@paths]]])\copy!
                            x1 = isNumber data[k + i + 0]
                            y1 = isNumber data[k + i + 1]
                            @paths[#@paths][#@paths[#@paths] + 1] = {p0, POINT(x1, y1), t: "l"}
                            i += 2
                    when "b"
                        i = 1
                        while type(data[k + i]) == "number"
                            p0 = TABLE(@paths[#@paths][#@paths[#@paths]][#@paths[#@paths][#@paths[#@paths]]])\copy!
                            x1 = isNumber data[k + i + 0]
                            y1 = isNumber data[k + i + 1]
                            x2 = isNumber data[k + i + 2]
                            y2 = isNumber data[k + i + 3]
                            x3 = isNumber data[k + i + 4]
                            y3 = isNumber data[k + i + 5]
                            @paths[#@paths][#@paths[#@paths] + 1] = {p0, POINT(x1, y1), POINT(x2, y2), POINT(x3, y3), t: "b"}
                            i += 6
        else
            @paths = shape.paths or shape
        @paths = close and @close! or @paths
        return @

    -- closes all parts of the shape
    close: =>
        isDiff = (x1, y1, x2, y2) -> x1 != x2 or y1 != y2
        for p, path in ipairs @paths
            first, last = path[1][1], path[#path][#path[#path]]
            xf, yf, xl, yl = first.x, first.y, last.x, last.y
            if isDiff xf, yf, xl, yl
                TABLE(path)\push {TABLE(last)\copy!, POINT(xf, yf), t: "l"}

    -- opens all parts of the shape
    open: =>
        isEqual = (p1, p2) -> (p1.t == "m" and p2.t == "l") and p1[1] == p2[#p2]
        for p, path in ipairs @paths
            if isEqual path[1], path[#path]
                TABLE(path)\pop!

    -- splits the segments of the shape into small parts
    split: (size = 1, segment = "m", extra) =>
        for m, move in ipairs @paths
            index = {}
            for p, path in ipairs move
                if path.t == (segment == "m" and (path.t == "m" and "l" or path.t) or segment)
                    points = BEZIER(path)\casteljau nil, extra, extra and nil or size
                    for i = 2, #points
                        TABLE(index)\push {points[i - 1], points[i], t: "l"}
                else
                    TABLE(index)\push path
            @paths[m] = index
        return @

    -- filters around all points of the shape
    filter: (fils = (x, y, p) -> p) =>
        fils = (type(fils) != "table" and {fils} or fils)
        for f in *fils
            for m in *@paths
                for p in *m
                    for k = 1, #p
                        nx, ny = f p[k].x, p[k].y, p[k]
                        p[k].x = ((nx and type(nx) == "table") and nx.x or nx) or p[k].x
                        p[k].y = ((nx and type(nx) == "table") and nx.y or ny) or p[k].y
        return @

    -- gets the points referring to the bounding box
    boudingBox: =>
        l, t = @paths[1][1][1].x, @paths[1][1][1].y
        r, b = @paths[1][1][1].x, @paths[1][1][1].y
        @filter (x, y) ->
            l, t = min(l, x), min(t, y)
            r, b = max(r, x), max(b, y)
        return @, l, t, r, b

    -- gets the bounding box of the shape, like shape
    boudingBoxShape: =>
        @, l, t, r, b = @boudingBox!
        return SHAPE ("m %s %s l %s %s %s %s %s %s ")\format l, t, r, t, r, b, l, b

    -- gets information about the shape
    getInfo: =>
        @, @minx, @miny, @maxx, @maxy = @boudingBox!
        @width  = @maxx - @minx
        @height = @maxy - @miny
        @center = @minx + @width / 2
        @middle = @miny + @height / 2
        return @

    -- moves shape points
    move: (px = 0, py = 0) =>
        @filter (x, y) ->
            x += px
            y += py
            return x, y
        return @

    -- scales shape points
    scale: (sx = 100, sy = 100) =>
        sx /= 100
        sy /= 100
        @filter (x, y) ->
            x *= sx
            y *= sy
            return x, y
        return @

    -- rotates shape points
    rotate: (angle, cx, cy) =>
        @getInfo!
        cx or= @center
        cy or= @middle
        angle = rad angle
        @filter (x, y) ->
            rx = cos(angle) * (x - cx) - sin(angle) * (y - cy) + cx
            ry = sin(angle) * (x - cx) + cos(angle) * (y - cy) + cy
            return rx, ry
        return @

    -- moves the shape points to their origin
    toOrigin: =>
        @getInfo!
        @move -@minx, -@miny
        return @

    -- moves the shape points to their center
    toCenter: =>
        @getInfo!
        @move -@minx - @width / 2, -@miny - @height / 2
        return @

    -- transforms line points into bezier points
    toBezier: =>
        for m, move in ipairs @paths
            for p, path in ipairs move
                if path.t == "l"
                    x1, y1 = path[1].x, path[1].y
                    x2, y2 = path[2].x, path[2].y
                    @paths[m][p] = {
                        t: "b"
                        POINT x1, y1
                        POINT (2 * x1 + x2) / 3, (2 * y1 + y2) / 3
                        POINT (x1 + 2 * x2) / 3, (y1 + 2 * y2) / 3
                        POINT x2, y2
                    }
        return @

    -- moves the shape points to clip, unclip and polygon positions
    displace: (an = 7, mode = "tog", px = 0, py = 0) =>
        @getInfo!
        w, h = @width, @height
        switch an
            when 1
                switch mode
                    when "tog" then @move 0, -h
                    when "tcp" then @move px, py - h
                    when "ucp" then @move -px, -py + h
            when 2
                switch mode
                    when "tog" then @move -w / 2, -h
                    when "tcp" then @move px - w / 2, py - h
                    when "ucp" then @move -px + w / 2, -py + h
            when 3
                switch mode
                    when "tog" then @move -w, -h
                    when "tcp" then @move px - w, py - h
                    when "ucp" then @move -px + w, -py + h
            when 4
                switch mode
                    when "tog" then @move 0, -h / 2
                    when "tcp" then @move px, py - h / 2
                    when "ucp" then @move -px, -py + h / 2
            when 5
                switch mode
                    when "tog" then @move -w / 2, -h / 2
                    when "tcp" then @move px - w / 2, py - h / 2
                    when "ucp" then @move -px + w / 2, -py + h / 2
            when 6
                switch mode
                    when "tog" then @move -w, -h / 2
                    when "tcp" then @move px - w, py - h / 2
                    when "ucp" then @move -px + w, -py + h / 2
            when 7
                switch mode
                    -- when "tog" then @move 0, 0
                    when "tcp" then @move px, py
                    when "ucp" then @move -px, -py
            when 8
                switch mode
                    when "tog" then @move -w / 2
                    when "tcp" then @move px - w / 2, py
                    when "ucp" then @move -px + w / 2, -py
            when 9
                switch mode
                    when "tog" then @move -w
                    when "tcp" then @move px - w, py
                    when "ucp" then @move -px + w, -py
        return @

    -- generates a transformation in perspective
    -- http://jsfiddle.net/xjHUk/278/
    perspective: (destin) =>
        @getInfo!
        source = {
            POINT @minx, @miny
            POINT @maxx, @miny
            POINT @maxx, @maxy
            POINT @minx, @maxy
        }
        destin or= {
            POINT @minx, @miny
            POINT @maxx, @miny
            POINT @maxx, @maxy
            POINT @minx, @maxy
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
            xE = (kBC * xBu - kAD * xAu + yAu - yBu) / (kBC - kAD)
            yE = kBC * (xE - xBu) + yBu

            kDC += add if kAB == kDC
            xF = (kAB * xBu - kDC * xCu + yCu - yBu) / (kAB - kDC)
            yF = kAB * (xF - xBu) + yBu

            xF += add if xE == xF
            kEF = (yE - yF) / (xE - xF)

            kAB += add if kEF == kAB
            xG = (kEF * xDu - kAB * xAu + yAu - yDu) / (kEF - kAB)
            yG = kEF * (xG - xDu) + yDu

            kBC += add if kEF == kBC
            xH = (kEF * xDu - kBC * xBu + yBu - yDu) / (kEF - kBC)
            yH = kEF * (xH - xDu) + yDu

            rG = (yC - yI) / (yC - yA)
            rH = (xI - xA) / (xC - xA)

            xJ = (xG - xDu) * rG + xDu
            yJ = (yG - yDu) * rG + yDu

            xK = (xH - xDu) * rH + xDu
            yK = (yH - yDu) * rH + yDu

            xJ += add if xF == xJ
            xK += add if xE == xK
            kJF = (yF - yJ) / (xF - xJ)
            kKE = (yE - yK) / (xE - xK)

            kKE += add if kJF == kKE
            xIu = (kJF * xF - kKE * xE + yE - yF) / (kJF - kKE)
            yIu = kJF * (xIu - xJ) + yJ
            return xIu, yIu
        return @

    -- generates a Envelope Distortion transformation
    -- https://codepen.io/benjamminf/pen/LLmrKN
    envelopeDistort: (P1, P2) =>
        @getInfo!
        @toBezier!
        P1 or= {
            POINT @minx, @miny
            POINT @maxx, @miny
            POINT @maxx, @maxy
            POINT @minx, @maxy
        }
        P2 or= {
            POINT @minx, @miny
            POINT @maxx, @miny
            POINT @maxx, @maxy
            POINT @minx, @maxy
        }
        assert #P1 == #P2, "The control points must have the same quantity!"
        buffer = 0.1
        for i = 1, #P1
            P1[i].x -= buffer if P1[i].x == @minx
            P1[i].y -= buffer if P1[i].y == @miny
            P1[i].x += buffer if P1[i].x == @maxx
            P1[i].y += buffer if P1[i].y == @maxy
            --
            P2[i].x -= buffer if P2[i].x == @minx
            P2[i].y -= buffer if P2[i].y == @miny
            P2[i].x += buffer if P2[i].x == @maxx
            P2[i].y += buffer if P2[i].y == @maxy
        A, W = {}, {}
        @filter (x, y) ->
            pt = POINT x, y
            -- Find Angles
            for i = 1, #P1
                vi, vj = P1[i], P1[i % #P1 + 1]
                r0i = pt\distance vi
                r0j = pt\distance vj
                rij = vi\distance vj
                r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / (2 * r0i * r0j)
                A[i] = r != r and 0 or acos(max(-1, min(r, 1)))
            -- Find Weights
            for i = 1, #P1
                j = (i > 1 and i or #P1 + 1) - 1
                r = P1[i]\distance pt
                W[i] = (tan(A[j] / 2) + tan(A[i] / 2)) / r
            -- Normalise Weights
            Ws = TABLE(W)\reduce (a, b) -> a + b
            -- Reposition
            nx, ny = 0, 0
            for i = 1, #P1
                L = W[i] / Ws
                nx += L * P2[i].x
                ny += L * P2[i].y
            return nx, ny
        return @

    -- transforms the points from perspective tags [fax, fay...]
    -- https://github.com/Alendt/Aegisub-Scripts
    expand: (line, data) =>
        data.p = data.p == "text" and 1 or data.p

        pf = (sx = 100, sy = 100, p = 1) ->
            assert p > 0 and p == floor(p)
            if p == 1
                sx / 100, sy / 100
            else
                p -= 1
                sx /= 2
                sy /= 2
                pf sx, sy, p

        frx = pi / 180 * data.frx
        fry = pi / 180 * data.fry
        frz = pi / 180 * line.styleref.angle

        sx, cx = -sin(frx), cos(frx)
        sy, cy =  sin(fry), cos(fry)
        sz, cz = -sin(frz), cos(frz)

        xscale, yscale = pf line.styleref.scale_x, line.styleref.scale_y, data.p

        fax = data.fax * xscale / yscale
        fay = data.fay * yscale / xscale

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
            w = 1 / max v[3], 0.1
            return v[1] * w, v[2] * w
        return @

    getLengths: =>
        @lengths = {}

        for i = 1, #@paths
            @lengths[i] = {0}
            for p, point in ipairs @paths[i]
                if point.t != "m"
                    len = BEZIER(point)\length!
                    @lengths[i][p] = len

        return @

    sortLengths: (fn = (a, b) -> a.len < b.len) =>
        @getLengths!

        sorted = {}
        for i = 1, #@paths
            sorted[i] = {}

            for l, length in ipairs @lengths[i]
                TABLE(sorted[i])\push {index: l, len: length}

            TABLE(sorted[i])\shift!
            table.sort sorted[i], fn

        return sorted

    roundCorners: (radius) =>

        isCorner = (currPath, nextPath, lastPath) ->
            if currPath.t == "b"
                return false
            elseif currPath.t == "m" and nextPath.t == "b"
                return false
            elseif currPath.t == "l" and nextPath.t == "b"
                return false
            elseif lastPath.t == "b"
                return false
            return true

        pathRound = (path, info) ->
            newPath, limit = {}, info.len / 2

            r = limit < radius and limit or radius
            for i = 2, #path
                j = i == #path and 2 or i + 1

                currPath = path[i]
                nextPath = path[j]

                if isCorner currPath, nextPath, path[#path]
                    prevPoint = currPath[1]
                    currPoint = currPath[2]
                    nextPoint = nextPath[2]

                    F = BEZIER currPoint, prevPoint
                    L = BEZIER currPoint, nextPoint

                    angleF = F\linearAngle!
                    angleL = L\linearAngle!

                    px, py = currPoint.x, currPoint.y

                    p1 = POINT px + r * cos(angleF), py + r * sin(angleF)
                    p4 = POINT px + r * cos(angleL), py + r * sin(angleL)

                    c1 = POINT (p1.x + 2 * px) / 3, (p1.y + 2 * py) / 3
                    c2 = POINT (p4.x + 2 * px) / 3, (p4.y + 2 * py) / 3

                    TABLE(newPath)\push (i == 2 and {t: "m", p1} or {t: "l", currPoint, p1}), {t: "b", p1, c1, c2, p4}
                else
                    TABLE(newPath)\push currPath

            if newPath[1].t == "l" or newPath[1].t == "b"
                TABLE(newPath)\unshift {t: "m", newPath[1][1]}

            return newPath

        infos = @sortLengths!
        for i = 1, #@paths
            @paths[i] = pathRound @paths[i], infos[i][1]

        return @

    -- builds the shape
    build: (dec = 3) =>
        shape = {}
        for i = 1, #@paths
            shape[i] = {}
            for j = 1, #@paths[i]
                shape[i][j] = ""
                prev = @paths[i][j - 1]
                curr = @paths[i][j]
                init = ((curr.t == "l" and #curr == 1) or (curr.t == "b" and #curr == 3)) and 1 or j == 1 and 1 or 2
                for k = init, #curr
                    curr[k]\round dec
                    shape[i][j] ..= "#{curr[k].x} #{curr[k].y} "
                shape[i][j] = prev and (prev.t == curr.t and shape[i][j]) or "#{curr.t} #{shape[i][j]}"
            shape[i] = table.concat shape[i]
        return table.concat shape

{:SHAPE}