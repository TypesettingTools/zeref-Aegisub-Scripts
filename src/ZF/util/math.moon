-- globalize lib math
with math
    export pi, log, sin, cos, tan, max, min      = .pi, .log, .sin, .cos, .tan, .max, .min
    export abs, deg, rad, log10, asin, sqrt     = .abs, .deg, .rad, .log10, .asin, .sqrt
    export acos, atan, sinh, cosh, tanh, random = .acos, .atan, .asin, .cosh, .tanh, .random
    export ceil, floor, atan2, format, unpack   = .ceil, .floor, .atan2, string.format, table.unpack or unpack

import TABLE from require "ZF.util.table"

class MATH

    -- rounds numerical values
    round: (a, dec = 3) => dec >= 1 and floor(a * 10 ^ floor(dec) + 0.5) / 10 ^ floor(dec) or floor(a + 0.5)

    -- clamps the value in a rage
    clamp: (a, b, c) => max b, min(a, c)

    -- random values between a min and max value
    random: (a, b) => random! * (b - a) + a

-- https://stackoverflow.com/a/27176424
class POLYNOMIAL

    new: (...) =>
        @coefs, @roots, @EP = {}, {}, 1e-8
        coefs = type(...) == "table" and ... or {...}

        for i = 1, #coefs
            TABLE(@coefs)\push coefs[i]

    unpack: => @coefs[1], @coefs[2], @coefs[3], @coefs[4]

    linearRoots: =>
        @roots = abs(a) < @EP and {} or {-b / a}
        return @roots

    quadraticRoots: =>
        delta = b ^ 2 - 4 * a * c
        if abs(delta) < @EP
            @roots = {-b / (2 * a)}
        elseif delta > 0
            @roots = {
                (-b + sqrt(delta)) / (2 * a)
                (-b - sqrt(delta)) / (2 * a)
            }
        return @roots

    cubicRoots: =>
        cubeRoot = (x) ->
            y = abs(x) ^ (1 / 3)
            return x < 0 and -y or y

        a, b, c, d = @unpack!

        p = (3 * a * c - b * b) / (3 * a * a)
        q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a)

        if abs(p) < @EP
            @roots[1] = cubeRoot -q
        elseif abs(q) < @EP
            @roots[1] = 0
            @roots[2] = p < 0 and sqrt(-p) or nil
            @roots[3] = p < 0 and -sqrt(-p) or nil
        else
            D = q * q / 4 + p * p * p / 27
            if abs(D) < @EP
                @roots[1] = -1.5 * q / p
                @roots[2] = 3 * q / p
            elseif D > 0
                u = cubeRoot -q / 2 - sqrt(D)
                @roots[1] = u - p / (3 * u)
            else
                u = 2 * sqrt(-p / 3)
                t = acos(3 * q / p / u) / 3
                k = 2 * pi / 3
                @roots[1] = u * cos t
                @roots[2] = u * cos t - k
                @roots[3] = u * cos t - 2 * k

        for i = 1, #@roots
            @roots[i] -= b / (3 * a)

        for r, root in ipairs @roots
            unless 0 <= root and root <= 1
                table.remove @roots, r

        return @roots

    getRoots: =>
        switch #@coefs
            when 2 then @linearRoots!
            when 3 then @quadraticRoots!
            when 4 then @cubicRoots!
            else {}

{:MATH, :POLYNOMIAL}