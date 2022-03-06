import MATH   from require "ZF.util.math"
import TABLE  from require "ZF.util.table"
import POINT  from require "ZF.2D.point"
import BEZIER from require "ZF.2D.bezier"
import PATH   from require "ZF.2D.path"

class SHAPE

    -- @param shape string || SHAPE
    -- @param close boolean
    new: (shape = {}, close = true) =>
        -- checks if the value is a number, otherwise it returns an invalid error
        isNumber = (v) ->
            if v = tonumber v
                return v
            else
                error "unknown shape"

        @paths, @l, @t, @r, @b = {}, math.huge, math.huge, -math.huge, -math.huge
        if type(shape) == "string"
            -- indexes all values that are different from a space
            i, data = 1, [s for s in shape\gmatch "%S+"]
            while i <= #data
                switch data[i]
                    when "m"
                        -- creates a new path layer
                        TABLE(@paths)\push PATH!
                        i += 2
                    when "l"
                        j = 1
                        while tonumber(data[i + j]) != nil
                            last = @paths[#@paths]
                            path, p0 = last.path, POINT!
                            if #path == 0 and data[i - 3] == "m"
                                p0.x = isNumber data[i - 2]
                                p0.y = isNumber data[i - 1]
                            else
                                bz = path[#path].bz
                                p0 = POINT bz[#bz]
                            -- creates the new line points and
                            -- checks if they are really a number
                            p1 = POINT!
                            p1.x = isNumber data[i + j + 0]
                            p1.y = isNumber data[i + j + 1]
                            -- adds the bezier to the path
                            last\push p0, p1
                            -- finds the line bounding box
                            minx, miny, maxx, maxy = last\boudingBox!
                            @l, @t = min(@l, minx), min(@t, miny)
                            @r, @b = max(@r, maxx), max(@b, maxy)
                            j += 2
                        i += j - 1
                    when "b"
                        j = 1
                        while tonumber(data[i + j]) != nil
                            last = @paths[#@paths]
                            path, p0 = last.path, POINT!
                            if #path == 0 and data[i - 3] == "m"
                                p0.x = isNumber data[i - 2]
                                p0.y = isNumber data[i - 1]
                            else
                                bz = path[#path].bz
                                p0 = POINT bz[#bz]
                            -- creates the new bezier points and
                            -- checks if they are really a number
                            p1, p2, p3 = POINT!, POINT!, POINT!
                            p1.x = isNumber data[i + j + 0]
                            p1.y = isNumber data[i + j + 1]
                            p2.x = isNumber data[i + j + 2]
                            p2.y = isNumber data[i + j + 3]
                            p3.x = isNumber data[i + j + 4]
                            p3.y = isNumber data[i + j + 5]
                            -- adds the bezier to the path
                            last\push p0, p1, p2, p3
                            -- finds the bezier bounding box
                            minx, miny, maxx, maxy = last\boudingBox!
                            @l, @t = min(@l, minx), min(@t, miny)
                            @r, @b = max(@r, maxx), max(@b, maxy)
                            j += 6
                        i += j - 1
                    else -- if the (command | letter) is other than "m", "l" and "b", that shape is unknown
                        error "unknown shape"
                i += 1
        else
            @paths = shape.paths and shape\copy!.paths or {}
            @boudingBox!

        -- checks whether to close or open the shape
        if close == true or close == "close"
            @close!
        elseif close == "open"
            @open!

        -- defines some shape information
        @w = @r - @l -- width
        @h = @b - @t -- height
        @c = @l + @w / 2 -- center
        @m = @t + @h / 2 -- middle

    -- copies the entire contents of the class
    -- @param path boolean
    -- @return SHAPE
    copy: (path = true) =>
        new = SHAPE!
        with new
            {l: .l, t: .t, r: .r, b: .b, w: .w, h: .h, c: .c, m: .m} = @
            if path
                for p = 1, #@paths
                    .paths[p] = PATH @paths[p]
        return new

    -- opens all paths
    -- @return SHAPE
    open: =>
        for i = 1, #@paths
            @paths[i]\open!
        return @

    -- closes all paths
    -- @return SHAPE
    close: =>
        for i = 1, #@paths
            @paths[i]\close!
        return @

    -- finds the coordinates of the rectangle gives bb
    -- @return SHAPE
    boudingBox: =>
        for path in *@paths
            l, t, r, b = path\boudingBox!
            @l, @t = min(@l, l), min(@t, t)
            @r, @b = max(@r, r), max(@b, b)
        -- recalculates the values
        @w = @r - @l
        @h = @b - @t
        @c = @l + @w / 2
        @m = @t + @h / 2
        return @

    -- gets the coordinates of the rectangle gives bb
    -- @return SHAPE, number, number, number, number
    getBoudingBox: => @, @l, @t, @r, @b

    -- gets the rectangle shape gives bb
    -- @return SHAPE
    getBoudingBoxShape: =>
        {:l, :t, :r, :b} = @
        return SHAPE ("m %s %s l %s %s %s %s %s %s ")\format l, t, r, t, r, b, l, b

    -- transform all linear points into bezier points
    -- @return SHAPE
    allCubic: =>
        for i = 1, #@paths
            @paths[i]\allCubic!
        return @

    -- runs through all the points gives shape
    -- @param fn function
    -- @return SHAPE
    filter: (fn = (x, y, p) -> x, y) =>
        for i = 1, #@paths
            @paths[i]\filter fn
        return @

    -- moves shape points
    -- @param px number
    -- @param py number
    -- @return SHAPE
    move: (px = 0, py = 0) =>
        @filter (x, y) ->
            x += px
            y += py
            return x, y
        return @

    -- scales shape points
    -- @param sx number
    -- @param sy number
    -- @param inCenter boolean
    -- @return SHAPE
    scale: (sx = 100, sy = 100, inCenter) =>
        sx /= 100
        sy /= 100
        {c: cx, m: cy} = @
        @filter (x, y) ->
            if inCenter
                x = sx * (x - cx) + cx
                y = sy * (y - cy) + cy
            else
                x *= sx
                y *= sy
            return x, y
        return @

    -- rotates shape points
    -- @param angle number
    -- @param cx number
    -- @param cy number
    -- @return SHAPE
    rotate: (angle, cx = @c, cy = @m) =>
        theta = rad angle
        cs = cos theta
        sn = sin theta
        @filter (x, y) ->
            dx = x - cx
            dy = y - cy
            rx = cs * dx - sn * dy + cx
            ry = sn * dx + cs * dy + cy
            return rx, ry
        return @

    -- moves the shape points to their origin
    -- @return SHAPE
    toOrigin: => @move -@l, -@t

    -- moves the shape points to their center
    -- @return SHAPE
    toCenter: => @move -@l - @w / 2, -@t - @h / 2

    -- sets the position the shape will be
    -- @param an integer
    -- @param mode string
    -- @param px number
    -- @param py number
    -- @return SHAPE
    setPosition: (an = 7, mode = "ply", px = 0, py = 0) =>
        {:w, :h} = @
        switch an
            when 1
                switch mode
                    when "ply" then @move 0, -h
                    when "tcp" then @move px, py - h
                    when "ucp" then @move -px, -py + h
            when 2
                switch mode
                    when "ply" then @move -w / 2, -h
                    when "tcp" then @move px - w / 2, py - h
                    when "ucp" then @move -px + w / 2, -py + h
            when 3
                switch mode
                    when "ply" then @move -w, -h
                    when "tcp" then @move px - w, py - h
                    when "ucp" then @move -px + w, -py + h
            when 4
                switch mode
                    when "ply" then @move 0, -h / 2
                    when "tcp" then @move px, py - h / 2
                    when "ucp" then @move -px, -py + h / 2
            when 5
                switch mode
                    when "ply" then @move -w / 2, -h / 2
                    when "tcp" then @move px - w / 2, py - h / 2
                    when "ucp" then @move -px + w / 2, -py + h / 2
            when 6
                switch mode
                    when "ply" then @move -w, -h / 2
                    when "tcp" then @move px - w, py - h / 2
                    when "ucp" then @move -px + w, -py + h / 2
            when 7
                switch mode
                    -- when "ply" then @move 0, 0
                    when "tcp" then @move px, py
                    when "ucp" then @move -px, -py
            when 8
                switch mode
                    when "ply" then @move -w / 2
                    when "tcp" then @move px - w / 2, py
                    when "ucp" then @move -px + w / 2, -py
            when 9
                switch mode
                    when "ply" then @move -w
                    when "tcp" then @move px - w, py
                    when "ucp" then @move -px + w, -py
        return @

    -- does a perspective transformation in the shape
    -- @param mesh table
    -- @param ep number
    -- @return SHAPE
    perspective: (mesh, ep = 1e-2) =>
        mesh or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }

        real = {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }

        {x: rx1, y: ry1} = real[1]
        {x: rx3, y: ry3} = real[3]
        {x: mx1, y: my1} = mesh[1]
        {x: mx2, y: my2} = mesh[2]
        {x: mx3, y: my3} = mesh[3]
        {x: mx4, y: my4} = mesh[4]

        mx3 += ep if mx2 == mx3
        mx4 += ep if mx1 == mx4
        mx2 += ep if mx1 == mx2
        mx3 += ep if mx4 == mx3

        a1 = (my2 - my3) / (mx2 - mx3)
        a2 = (my1 - my4) / (mx1 - mx4)
        a3 = (my1 - my2) / (mx1 - mx2)
        a4 = (my4 - my3) / (mx4 - mx3)

        a2 += ep if a1 == a2
        b1 = (a1 * mx2 - a2 * mx1 + my1 - my2) / (a1 - a2)
        b2 = a1 * (b1 - mx2) + my2

        a4 += ep if a3 == a4
        c1 = (a3 * mx2 - a4 * mx3 + my3 - my2) / (a3 - a4)
        c2 = a3 * (c1 - mx2) + my2

        c1 += ep if b1 == c1
        c3 = (b2 - c2) / (b1 - c1)

        a3 += ep if c3 == a3
        d1 = (c3 * mx4 - a3 * mx1 + my1 - my4) / (c3 - a3)
        d2 = c3 * (d1 - mx4) + my4

        a1 += ep if c3 == a1
        e1 = (c3 * mx4 - a1 * mx2 + my2 - my4) / (c3 - a1)
        e2 = c3 * (e1 - mx4) + my4
        @filter (x, y) ->
            f1 = (ry3 - y) / (ry3 - ry1)
            f2 = (x - rx1) / (rx3 - rx1)

            g1 = (d1 - mx4) * f1 + mx4
            g2 = (d2 - my4) * f1 + my4

            h1 = (e1 - mx4) * f2 + mx4
            h2 = (e2 - my4) * f2 + my4

            g1 += ep if c1 == g1
            h1 += ep if b1 == h1
            i1 = (c2 - g2) / (c1 - g1)
            i2 = (b2 - h2) / (b1 - h1)
            i2 += ep if i1 == i2

            px = (i1 * c1 - i2 * b1 + b2 - c2) / (i1 - i2)
            py = i1 * (px - g1) + g2
            return px, py
        return @

    -- does a envelope transformation in the shape
    -- @param mesh table
    -- @param real table
    -- @param ep number
    -- @return SHAPE
    envelopeDistort: (mesh, real, ep = 1e-2) =>
        @allCubic!
        mesh or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }
        real or= {
            POINT @l, @t
            POINT @r, @t
            POINT @r, @b
            POINT @l, @b
        }
        assert #real == #mesh, "The control points must have the same quantity!"
        for i = 1, #real
            with real[i]
                .x -= ep if .x == @l
                .y -= ep if .y == @t
                .x += ep if .x == @r
                .y += ep if .y == @b
            with mesh[i]
                .x -= ep if .x == @l
                .y -= ep if .y == @t
                .x += ep if .x == @r
                .y += ep if .y == @b
        A, W = {}, {}
        @filter (x, y, pt) ->
            -- Find Angles
            for i = 1, #real
                vi, vj = real[i], real[i % #real + 1]
                r0i = pt\distance vi
                r0j = pt\distance vj
                rij = vi\distance vj
                r = (r0i ^ 2 + r0j ^ 2 - rij ^ 2) / (2 * r0i * r0j)
                A[i] = r != r and 0 or acos max -1, min r, 1
            -- Find Weights
            for i = 1, #real
                j = (i > 1 and i or #real + 1) - 1
                r = real[i]\distance pt
                W[i] = (tan(A[j] / 2) + tan(A[i] / 2)) / r
            -- Normalise Weights
            Ws = TABLE(W)\reduce (a, b) -> a + b
            -- Reposition
            nx, ny = 0, 0
            for i = 1, #real
                L = W[i] / Ws
                with mesh[i]
                    nx += L * .x
                    ny += L * .y
            return nx, ny
        return @

    -- transforms the points from perspective tags [fax, fay...]
    -- https://github.com/Alendt/Aegisub-Scripts/blob/0e897aeaab4eb11855cd1d83474616ef06307268/macros/alen.Shapery.moon#L3787
    -- @param line table
    -- @param data table
    -- @return SHAPE
    expand: (line, data) =>
        pf = (sx = 100, sy = 100, p = 1) ->
            assert p > 0 and p == floor p
            if p == 1
                sx / 100, sy / 100
            else
                p -= 1
                sx /= 2
                sy /= 2
                pf sx, sy, p
        with data
            .p = .p == "text" and 1 or .p

            frx = pi / 180 * .frx
            fry = pi / 180 * .fry
            frz = pi / 180 * line.styleref.angle

            sx, cx = -sin(frx), cos(frx)
            sy, cy =  sin(fry), cos(fry)
            sz, cz = -sin(frz), cos(frz)

            xscale, yscale = pf line.styleref.scale_x, line.styleref.scale_y, .p

            fax = .fax * xscale / yscale
            fay = .fay * yscale / xscale

            x1 = {1, fax, .pos.x - .org.x}
            y1 = {fay, 1, .pos.y - .org.y}

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

            offs_x = .org.x - .pos.x
            offs_y = .org.y - .pos.y

            matrix = [{} for i = 1, 3]
            for i = 1, 3
                matrix[1][i] = z4[i] * offs_x + x4[i] * dist
                matrix[2][i] = z4[i] * offs_y + y3[i] * dist
                matrix[3][i] = z4[i]

            @filter (x, y) ->
                v = [(matrix[m][1] * x * xscale) + (matrix[m][2] * y * yscale) + matrix[m][3] for m = 1, 3]
                w = 1 / max v[3], 0.1
                return v[1] * w, v[2] * w
        return @

    -- linearly flattens the parts of the shape
    -- @param srt integer
    -- @param len integer
    -- @param red integer
    -- @param seg string
    -- @param fix boolean
    -- @return SHAPE
    flatten: (srt, len, red, seg, fix) =>
        new = @copy false
        for k, v in ipairs @paths
            new.paths[k] = v\flatten srt, len, red, seg, fix
        return new

    -- gets all lengths of the shape
    -- @return table
    getLengths: =>
        lengths = {sum: {}, max: 0}
        for k, v in ipairs @paths
            lengths[k] = v\getLength!
            lengths.max += lengths[k].max
            lengths.sum[k] = lengths.max
        return lengths

    -- gets the total length of the shape
    -- @return number
    length: => @getLengths!["max"]

    -- splits the shape path into two
    -- @param t number
    -- @return table
    splitPath: (t) =>
        a = @splitPathInInterval 0, t
        b = @splitPathInInterval t, 1
        return {a, b}

    -- splits the shape path into an interval
    -- @param s number
    -- @param e number
    -- @return SHAPE
    splitPathInInterval: (s, e) =>
        new = @copy false
        for k, v in ipairs @paths
            new.paths[k] = v\splitInInterval s, e
        return new

    -- splits the shape paths into two
    -- @param t number
    -- @return table
    splitPaths: (t) =>
        a = @splitPathsInInterval 0, t
        b = @splitPathsInInterval t, 1
        return {a, b}

    -- splits the shape paths into an interval
    -- @param s number
    -- @param e number
    -- @return SHAPE
    splitPathsInInterval: (s = 0, e = 1) =>
        -- clamps the time values between "0 ... 1"
        s = MATH\clamp s, 0, 1
        e = MATH\clamp e, 0, 1

        -- if the start value is greater than the end value, reverses the values
        s, e = e, s if s > e

        -- gets the required lengths
        lens = @getLengths!
        slen = s * lens.max
        elen = e * lens.max

        spt, inf, new = nil, nil, @copy false
        for i = 1, #lens.sum
            -- if the sum is less than the final value
            if lens.sum[i] >= elen
                -- gets the start index
                k = 1
                for i = 1, #lens.sum
                    if lens.sum[i] >= slen
                        k = i
                        break
                -- splits the initial part of the path
                val = @paths[k]
                u = (lens.sum[k] - slen) / val\length!
                u = 1 - u
                -- if the split is on a different path
                if i != k
                    spt = val\splitInInterval u, 1
                    TABLE(new.paths)\push spt
                -- if not initial, add the parts that will not be damaged
                if i > 1
                    for j = k + 1, i - 1
                        TABLE(new.paths)\push @paths[j]
                -- splits the final part of the path
                val = @paths[i]
                t = (lens.sum[i] - elen) / val\length!
                t = 1 - t
                -- if the split is on a different path
                if i != k
                    spt = val\splitInInterval 0, t
                    TABLE(new.paths)\push spt
                else
                    spt = val\splitInInterval u, t
                    TABLE(new.paths)\push spt
                -- gets useful information
                inf = {:i, :k, :u, :t}
                break

        return new, inf

    -- gets the normal tangent of a time gives shape
    -- @param t number
    -- @param inverse boolean
    -- @return POINT, POINT, number
    getNormal: (t, inverse) =>
        new, inf = @splitPathsInInterval 0, t
        return @paths[inf.i]\getNormal inf.t, inverse

    -- distorts a shape into a clip
    -- http://www.planetclegg.com/projects/WarpingTextToSplines.html
    -- @param an integer
    -- @param clip string || SHAPE
    -- @param mode string
    -- @param leng integer
    -- @param offset number
    -- @return SHAPE
    inClip: (an = 7, clip, mode = "left", leng, offset = 0) =>
        mode = mode\lower!

        @toOrigin!
        clip = SHAPE clip, false
        leng or= clip\length!
        size = leng - @w

        @ = @flatten nil, nil, 2
        @filter (x, y) ->
            y = switch an
                when 7, 8, 9 then y - @h
                when 4, 5, 6 then y - @h / 2
                -- when 1, 2, 3 then y
            x = switch mode
                -- when 1, "left" then x
                when 2, "center" then x + size / 2
                when 3, "right"  then x + size
            -- gets time
            t = (x + offset) / leng
            -- gets normal tangent
            tan, pnt, t = clip\getNormal t, true
            -- reescale tangent
            tan.x = pnt.x + y * tan.x
            tan.y = pnt.y + y * tan.y
            return tan
        return @

    -- rounds the corners of the shape
    -- @param radius number
    -- @return SHAPE
    roundCorners: (radius) =>
        lengths = @getLengths!
        for i = 1, #@paths
            -- sorts so that the order is from the shortest length to the longest
            table.sort lengths[i], (a, b) -> a < b
            -- replaces the paths for paths with rounded corners 
            @paths[i] = @paths[i]\roundCorners radius, lengths[i][1] / 2
        return @

    -- concatenates all the points
    -- @param dec number
    -- @return string
    __tostring: (dec) =>
        conc = ""
        for k, v in ipairs @paths
            conc ..= v\__tostring dec
        return conc

    -- same as __tostring
    build: (dec) => @__tostring dec

{:SHAPE}