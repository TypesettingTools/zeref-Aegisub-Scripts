import MATH  from require "ZF.util.math"
import TABLE from require "ZF.util.table"

class UTIL

    version: "1.2.6"

    -- interpolate n values
    -- @param t number
    -- @param interpolationType string
    -- @param ... string || number
    -- @return number || string
    interpolation: (t = 0.5, interpolationType = "auto", ...) =>
        values = type(...) == "table" and ... or {...}
        -- interpolates two shape values if they have the same number of points
        interpolate_shape = (u, f, l, j = 1) ->
            a = [tonumber(s) for s in f\gmatch "%-?%d[%.%d]*"]
            b = [tonumber(s) for s in l\gmatch "%-?%d[%.%d]*"]
            assert #a == #b, "The shapes must have the same stitch length"
            f = f\gsub "%-?%d[%.%d]*", (s) ->
                s = MATH\round UTIL\interpolation u, nil, a[j], b[j]
                j += 1
                return s
            return f
        -- interpolates the values contained in the tables as long as the number of elements is equal
        interpolate_table: (u, f, l, new = {}) ->
            assert #f == #l, "The interpolation depends on tables with the same number of elements"
            for i = 1, #f
                new[i] = UTIL\interpolation u, nil, f[j], l[j]
            return new
        -- gets function from interpolation type
        fn = switch interpolationType
            when "number" then interpolate
            when "color"  then interpolate_color
            when "alpha"  then interpolate_alpha
            when "shape"  then interpolate_shape
            when "table"  then interpolate_table
            when "auto"
                types = {}
                for k, v in ipairs values
                    if type(v) == "number"
                        types[k] = "number"
                    elseif type(v) == "table"
                        types[k] = "table"
                    elseif type(v) == "string"
                        if v\match "&?[hH]%x%x%x%x%x%x&?"
                            types[k] = "color"
                        elseif v\match "&?[hH]%x%x&?"
                            types[k] = "alpha"
                        elseif v\match "m%s+%-?%d[%.%-%d mlb]*"
                            types[k] = "shape"
                    assert types[k] == types[1], "The interpolation must be done on values of the same type"
                return UTIL\interpolation t, types[1], ...
        t = clamp(t, 0, 1) * (#values - 1)
        u = floor t
        return fn t - u, values[u + 1], values[u + 2] or values[u + 1]

    -- gets frame duration
    -- @param dec integer
    -- @return number
    getFrameDur: (dec = 3) =>
        msa, msb = aegisub.ms_from_frame(1), aegisub.ms_from_frame(101)
        return MATH\round msb and (msb - msa) / 100 or 41.708, dec

    -- inserts a line in the subtitles
    -- @param line table
    -- @param subs userdata
    -- @param sel integer
    -- @param selection table
    -- @param i integer
    -- @param j integer
    -- @return integer, integer
    insertLine: (line, subs, sel, selection, i, j, k = sel + i + 1) =>
        subs.insert k, line
        TABLE(selection)\push k
        return i + 1, j + 1

    -- delets a line in the subtitles
    -- @param subs userdata
    -- @param sel integer
    -- @param i integer
    -- @param j integer
    -- @return integer, integer
    deleteLine: (line, subs, sel, remove, i, j, k = sel + i) =>
        line.comment = true
        subs[k] = line
        if remove
            subs.delete k
            return i - 1, j - 1
        else
            return i, j

    -- gets the first subtitle dialog
    -- @param subs userdata
    -- @return integer, table
    getFirstLine: (subs) =>
        for i = 1, #subs
            if subs[i].class == "dialogue"
                return i, subs[i]

    -- gets the last subtitle dialog
    -- @param subs userdata
    -- @return integer, table
    getLastLine: (subs) => #subs, subs[#subs]

    -- checks if the macro can be started
    -- @param l table
    -- @return boolean
    runMacro: (l) => l.comment == false and not @isBlank l

    -- transforms html colors to rgb or the other way around
    -- @param color string
    -- @param mode string
    -- @return string
    convertColor: (color, mode = "html2ass") =>
        values = {}
        switch mode
            when "html2ass"
                color\gsub "#%s*(%x%x)(%x%x)(%x%x)", (b, g, r) ->
                    values[1] = "&H#{r}#{g}#{b}&"
            when "html2number"
                color\gsub "#%s*(%x%x)(%x%x)(%x%x)", (b, g, r) ->
                    values[1] = tonumber b, 16
                    values[2] = tonumber g, 16
                    values[3] = tonumber r, 16
            when "ass2html"
                color\gsub "&?[hH](%x%x)(%x%x)(%x%x)&?", (r, g, b) ->
                    values[1] = "##{b}#{g}#{r}"
            when "ass2number"
                color\gsub "&?[hH](%x%x)(%x%x)(%x%x)&?", (r, g, b) ->
                    values[1] = tonumber r, 16
                    values[2] = tonumber g, 16
                    values[3] = tonumber b, 16
        return unpack values

    -- gets the clip content
    -- @param clip string
    -- @return string
    clip2Draw: (clip) =>
        caps, shape = {
            v: "\\i?clip%((m%s+%-?%d[%.%-%d mlb]*)%)"
            r: "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        }, clip
        if clip\match "\\i?clip%b()"
            with caps
                unless clip\match .v
                    l, t, r, b = clip\match .r
                    shape = "m #{l} #{t} l #{r} #{t} #{r} #{b} #{l} #{b}"
                else
                    shape = clip\match .v
            return shape

    -- gets the class name provided by moonscript
    -- @param cls metatable
    -- @return string
    getClassName: (cls) =>
        if cls = getmetatable cls
            return cls.__class.__name

    -- gets the prev and next value of the text division
    -- @param s string
    -- @param div string || number
    -- @return string, string
    headTail: (s, div) =>
        a, b, head, tail = s\find "(.-)#{div}(.*)"
        if a then head, tail else s, ""

    -- gets the prev and next value of the text division
    -- @param s string
    -- @param div string || number
    -- @return table
    headTails: (s, div) =>
        add = {}
        while s != ""
            head, tail = UTIL\headTail s, div
            TABLE(add)\push head
            s = tail
        return add

    -- checks that the text is not just a hole
    -- @param t table || string
    -- @return boolean
    isBlank: (t) =>
        if type(t) == "table"
            if t.duration and t.text_stripped
                if t.duration <= 0 or t.text_stripped\len! <= 0
                    return true
                t = t.text_stripped
            else
                t = t.text\gsub "%b{}", ""
        else
            t = t\gsub "[ \t\n\r]", ""
            t = t\gsub "　", ""
        return t\len! <= 0

    -- checks if the text is a shape
    -- @param text string
    -- @return boolean, string
    isShape: (text) =>
        local isShape, shape
        if type(text) == "string"
            if shape = text\match "m%s+%-?%d[%.%-%d mlb]*"
                isShape = true
            return isShape and shape or nil

    -- warning log
    -- @param msg string
    -- @param n number
    warning: (msg = "", n = 1) =>
        aegisub.debug.out 2, "———— [Warning] ➔ Line \"[#{n}]\" skipped\n"
        aegisub.debug.out 2, "—— [Cause] ➔ " .. msg .. "\n\n"
        return

{:UTIL}