-- load external libs
import UTIL   from require "ZF.util"
import MATH   from require "ZF.math"
import TABLE  from require "ZF.table"
import BEZIER from require "ZF.bezier"

class SHAPE

    new: (shape, closed = true) =>
        is_Number = (v) ->
            assert type(v) == "number", "unknown shape"
            return v
        is_String = (v) -> tonumber(v) == nil
        is_Equal = (x1, y1, x2, y2) -> true if x1 != x2 or y1 != y2
        @paths = {}
        if type(shape) == "string"
            shape = UTIL\clip_to_draw(shape)
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
                    TABLE(v)\push({typer: "l", xf, yf}) if is_Equal(xf, yf, xl, yl)
        else
            @paths = shape.paths or shape
        return @

    -- splits the segments of the shape into small parts
    split: (size = 1, seg = "all", len_t) =>
        split = (t, typer) ->
            add = {}
            for i = 1, #t
                add[i] = {}
                for j = 1, #t[i]
                    cond = if typer == "m" then t[i][j].typer != typer else t[i][j].typer == typer
                    if cond
                        table.insert(t[i][j], 1, t[i][j - 1][#t[i][j - 1] - 0])
                        table.insert(t[i][j], 1, t[i][j - 1][#t[i][j - 1] - 1])
                        --
                        bz = BEZIER(t[i][j])
                        bz = bz\create(not len_t and bz\len! / size or len_t)
                        for k = 1, #bz
                            continue if bz[k][1] != bz[k][1] -- skip nan
                            TABLE(add[i])\push(bz[k])
                    else
                        TABLE(add[i])\push(t[i][j])
            return add
        @paths = switch seg
            when "line"   then split(@paths, "l")
            when "bezier" then split(@paths, "b")
            else               split(@paths, "m")
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
            return ("m %s %s l %s %s %s %s %s %s ")\format(l, t, r, t, r, b, l, b), l, t, r, b, n
        return l, t, r, b, n

    -- gets shape infos
    info: =>
        @minx, @miny, @maxx, @maxy, @points_len = @bounding!
        @w_shape, @h_shape = @maxx - @minx, @maxy - @miny
        @c_shape, @m_shape = @minx + @w_shape / 2, @miny + @h_shape / 2
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
        cx or= @c_shape
        cy or= @m_shape
        r = rad(angle)
        @filter (x, y) ->
            rx = cos(r) * (x - cx) - sin(r) * (y - cy) + cx
            ry = sin(r) * (x - cx) + cos(r) * (y - cy) + cy
            return rx, ry
        return @

    -- moves the shape points to their origin
    origin: (min) =>
        @info!
        @displace(-@minx, -@miny)
        return @, @minx, @miny if min
        return @

    -- moves the shape points to their center
    to_center: (min) =>
        @origin!
        @displace(-@w_shape / 2, -@h_shape / 2)
        return @

    -- moves the points of the shape to the position relative to the alignment 7
    org_points: (an = 7) =>
        @info!
        w, h = @w_shape, @h_shape
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
        w, h = @w_shape, @h_shape
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
        w, h = @w_shape, @h_shape
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
        @to_bezier!
        ctrl_p1 or= {
            {x: @minx, y: @miny}
            {x: @maxx, y: @miny}
            {x: @maxx, y: @maxy}
            {x: @minx, y: @maxy}
        }
        ctrl_p2 or= {
            {x: @minx - 100, y: @miny}
            {x: @maxx + 100, y: @miny}
            {x: @maxx, y: @maxy}
            {x: @minx, y: @maxy}
        }
        isNaN = (v) -> type(v) == "number" and v != v -- checks if the number is nan
        assert #ctrl_p1 == #ctrl_p2, "The control points must have the same quantity!"
        -- to avoid dividing by zero
        ctrl_b = 0.1
        for i = 1, #ctrl_p1
            ctrl_p1[i].x -= ctrl_b if ctrl_p1[i].x == @minx
            ctrl_p1[i].y -= ctrl_b if ctrl_p1[i].y == @miny
            ctrl_p1[i].x += ctrl_b if ctrl_p1[i].x == @maxx
            ctrl_p1[i].y += ctrl_b if ctrl_p1[i].y == @maxy
            --
            ctrl_p2[i].x -= ctrl_b if ctrl_p2[i].x == @minx
            ctrl_p2[i].y -= ctrl_b if ctrl_p2[i].y == @miny
            ctrl_p2[i].x += ctrl_b if ctrl_p2[i].x == @maxx
            ctrl_p2[i].y += ctrl_b if ctrl_p2[i].y == @maxy
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
            Ws = TABLE(W)\reduce (a, b) -> a + b
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
            assert p > 0 and p == floor(p)
            if p == 1
                return sx / 100, sy / 100
            else
                p -= 1
                sx /= 2
                sy /= 2
                return pf(sx, sy, p)
        @org_points(line.styleref.align)
        data = UTIL\find_coords(line, meta, true)
        frx = pi / 180 * data.rots.frx
        fry = pi / 180 * data.rots.fry
        frz = pi / 180 * data.rots.frz
        sx, cx = -sin(frx), cos(frx)
        sy, cy =  sin(fry), cos(fry)
        sz, cz = -sin(frz), cos(frz)
        xscale, yscale = pf(data.scale.x, data.scale.y, data.p)
        fax = data.rots.fax * xscale / yscale
        fay = data.rots.fay * yscale / xscale
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
                    TABLE(add[k])\push({typer: "l", x1, y1}, {typer: "b", pcx1, pcy1, pcx2, pcy2, x2, y2})
                else
                    TABLE(add[k])\push(@paths[k][j])
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

{:SHAPE}