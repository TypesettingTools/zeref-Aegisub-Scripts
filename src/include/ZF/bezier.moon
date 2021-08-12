-- load external libs
import MATH from require "ZF.math"

-- bezier curve implementation
-- https://en.wikipedia.org/wiki/B%C3%A9zier_curve
class BEZIER

    new: (...) => @paths = (type(...) == "table" and ... or {...})

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

{:BEZIER}