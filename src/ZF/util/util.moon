import MATH  from require "ZF.util.math"
import TABLE from require "ZF.util.table"
import TAGS  from require "ZF.text.tags"

class UTIL

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
                s = MATH\round UTIL\interpolation(pct, nil, fs[j], ls[j])
                j += 1
                return s
            return f
        -- interpolation type
        ipolF = switch tp
            when "number" then interpolate
            when "color"  then interpolate_color
            when "alpha"  then interpolate_alpha
            when "shape"  then interpolate_shape
        pct = clamp(pct, 0, 1) * (#values - 1)
        valor_i = values[floor(pct) + 1]
        valor_f = values[floor(pct) + 2] or values[floor(pct) + 1]
        return ipolF pct - floor(pct), valor_i, valor_f

    -- gets frame duration
    getFrameDur: (dec = 3) =>
        msa, msb, j = aegisub.ms_from_frame(1), aegisub.ms_from_frame(101), 0
        return MATH\round msb and (msb - msa) / 100 or 41.708, dec

    -- readjusts the style values using values set on the line
    tags2Styles: (subs, line) =>
        tag = line.text\match TAGS\caps(true)["tag"]
        meta, style = karaskel.collect_head subs
        oldStyle = TABLE(style)\copy!
        for k = 1, style.n
            with style[k]
                .margin_l = line.margin_l if line.margin_l > 0
                .margin_r = line.margin_r if line.margin_r > 0
                .margin_v = line.margin_t if line.margin_t > 0
                .margin_v = line.margin_b if line.margin_b > 0
                if tag
                    .align     = TAGS\findTag(tag, "an", "oun") or .align
                    .fontname  = TAGS\findTag(tag, "fn", "font") or .fontname
                    .fontsize  = TAGS\findTag(tag, "fs", "dec") or .fontsize
                    .scale_x   = TAGS\findTag(tag, "fscx", "dec") or .scale_x
                    .scale_y   = TAGS\findTag(tag, "fscy", "dec") or .scale_y
                    .spacing   = TAGS\findTag(tag, "fsp", "float") or .spacing
                    .outline   = TAGS\findTag(tag, "bord", "dec") or .outline
                    .shadow    = TAGS\findTag(tag, "shad", "dec") or .shadow
                    .angle     = TAGS\findTag(tag, "frz", "float") or .angle
                    .color1    = TAGS\findTag(tag, "1c", "hex") or .color1
                    .color2    = TAGS\findTag(tag, "2c", "hex") or .color2
                    .color3    = TAGS\findTag(tag, "3c", "hex") or .color3
                    .color4    = TAGS\findTag(tag, "4c", "hex") or .color4
                    .bold      = TAGS\findTag(tag, "b", "bool") or .bold
                    .italic    = TAGS\findTag(tag, "i", "bool") or .italic
                    .underline = TAGS\findTag(tag, "u", "bool") or .underline
                    .strikeout = TAGS\findTag(tag, "s", "bool") or .strikeout
        return meta, style, oldStyle

    -- gets preprocessed values from the style, saving the old one and setting a new one
    setPreprocLine: (subs, line) =>
        meta, style, oldStyle = @tags2Styles subs, line
        karaskel.preproc_line subs, meta, oldStyle, line

        line.stylerefOld = TABLE(line.styleref)\copy!
        line.styleref = nil

        karaskel.preproc_line subs, meta, style, line
        coords = @findCoords line, meta
        return coords, meta, style, oldStyle

    -- find coordinates
    findCoords: (line, meta, ogp = true) =>
        tag = line.text\match TAGS\caps(true)["tag"]
        with {pos: {}, move: {}, org: {}, fax: 0, fay: 0, frx: 0, fry: 0, p: "text"}
            if meta

                x = switch line.styleref.align
                    when 1, 4, 7 then line.styleref.margin_l
                    when 2, 5, 8 then meta.res_x / 2 + (-line.styleref.margin_r / 2 + line.styleref.margin_l / 2)
                    when 3, 6, 9 then meta.res_x - line.styleref.margin_r

                y = switch line.styleref.align
                    when 1, 2, 3 then meta.res_y - line.styleref.margin_v
                    when 4, 5, 6 then meta.res_y / 2
                    when 7, 8, 9 then line.styleref.margin_v

                .pos.x, .pos.y = x, y
                -- .move.x1, .move.y1, .move.x2, .move.y2 = x, y, x, y
                .org.x, .org.y = x, y

            if tag
                .p = TAGS\findTag(tag, "p", "int") or .p

                .frx = TAGS\findTag(tag, "frx", "float") or 0
                .fry = TAGS\findTag(tag, "fry", "float") or 0
                .fax = TAGS\findTag(tag, "fax", "float") or 0
                .fay = TAGS\findTag(tag, "fay", "float") or 0

                mPos = TAGS\findTag(tag, "pos", nil, false)
                mMov = TAGS\findTag(tag, "move", nil, false)
                mOrg = TAGS\findTag(tag, "org", nil, false)

                if mPos
                    .pos.x, .pos.y = @coNumber mPos, "pos"
                elseif mMov
                    .move.x1, .move.y1, .move.x2, .move.y2, .move.ts, .move.te = @coNumber mMov, "move"
                    .pos.x, .pos.y = .move.x1, .move.y1

                .org.x, .org.y = if not mOrg and ogp then .pos.x, .pos.y else @coNumber mOrg, "org"

    -- transforms html colors to rgb or the other way around
    htmlC: (color, mode = "to_rgb") =>
        local c
        switch mode
            when "to_rgb"  then color\gsub "(%x%x)(%x%x)(%x%x)", (b, g, r) -> c = "&H#{r}#{g}#{b}&"
            when "to_html" then color_from_style(color)\gsub "&?[hH](%x%x)(%x%x)(%x%x)&?", (r, g, b) -> c = "##{b}#{g}#{r}"
        return c

    -- gets the clip content
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

    -- returns numeric values between commas
    coNumber: (value, tag) =>
        args = {}
        value = value\gsub("%s+", "")\gsub("\\#{tag}%((.-)%)", "%1")\gsub "[^,]*", (i) ->
            TABLE(args)\push tonumber i
        return unpack args

    -- gets the prev and next value of the text division
    headTail: (s, div) =>
        a, b, head, tail = s\find "(.-)#{div}(.*)"
        if a then head, tail else s, ""

    -- gets the prev and next value of the text division
    getHeadTail: (s, div) =>
        add = {}
        while s != ""
            head, tail = UTIL\headTail s, div
            TABLE(add)\push head
            s = tail
        return add

    -- checks that the text is not just a hole
    isBlank: (t) =>
        if type(t) == "table"
            if t.duration <= 0 or t.text_stripped\len! <= 0
                return true
            t = t.text_stripped
        else
            t = t\gsub "[ \t\n\r]", ""
            t = t\gsub "　", ""
        return t\len! <= 0

    -- checks if the text is a shape
    isShape: (coords, text) =>
        shape = text\match "m%s+%-?%d[%.%-%d mlb]*"
        isShape = shape and coords.p != "text"
        return isShape, isShape and shape or nil

    -- checks if the macro can be started
    runMacro: (l) => l.comment == false and not @isBlank l

    -- removes the spaces at the beginning or end of the text
    fixText: (text, where = "both") =>
        switch where
            when "both"   then text\match "^%s*(.-)%s*$"
            when "start"  then text\match "^%s*(.-%s*)$"
            when "end"    then text\match "^(%s*.-)%s*$"
            when "spaceL" then text\match "^(%s*).-%s*$"
            when "spaceR" then text\match "^%s*.-(%s*)$"
            when "spaces" then text\match "^(%s*).-(%s*)$"

    -- adds an empty tag to the beginning of the text if needed
    addEmpty: (text) =>
        text = @fixText text\gsub("{}", ""), "both"
        hast = text\gsub("%s+", "")\find TAGS\caps!["tag"]
        text = hast != 1 and "{}#{text}" or text
        return text

    -- splits text from line breaks
    splitBreaks: (text) =>
        removeEquals = (value) ->
            fix = (prev, curr) ->
                tags, valt = TAGS\capTags!, ""
                for t, tag in pairs tags
                    preVal = prev\match tag
                    curVal = curr\match tag
                    if preVal and curVal
                        curr = curr\gsub tag, ""
                return "{#{curr}}"

            j, value = 0, value\gsub "\\t%(.-%)?", (v) -> v\gsub "\\", "\\x"
            splited = TAGS\getTags value
            for j = 2, #splited
                prev = splited[j - 1]\sub 2, -2
                curr = splited[j - 0]\sub 2, -2
                splited[j] = fix prev, curr
                splited[j] = splited[j]\gsub "\\x", "\\"

            value = value\gsub "%b{}", (t) ->
                j += 1
                splited[j]

            return value\gsub "\\x", "\\"

        fixTags = (value) ->
            for k = 1, #value - 1
                tags = TAGS\getTags value[k]
                value[k + 1] = (tags[#tags] or "") .. value[k + 1]
            for k = 1, #value
                value[k] = @splitText value[k]
                if #value[k].text > 1 and #value[k].tags > 1
                    val = ""
                    for j = 1, #value[k].text
                        continue if value[k].text[j] == ""
                        val ..= (value[k].tags[j] or "") .. value[k].text[j]
                    value[k] = val
                else
                    value[k] = (value[k].tags[#value[k].tags] or "") .. (value[k].text[#value[k].text] or "")
                value[k] = value[k]\gsub "{}", ""
                value[k] = @splitText value[k]
            return value

        concat, resul, values = "", {}, @splitText text
        for k = 1, #values.text
            concat ..= values.tags[k] .. values.text[k]

        index = fixTags @getHeadTail(concat, "\\N")
        for k = 1, #index
            resul[k] = ""
            for j = 1, #index[k].text
                resul[k] ..= index[k].tags[j] .. index[k].text[j]
            resul[k] = removeEquals resul[k]

        return resul

    -- splits text from tag layers
    splitText: (text) =>
        capt = TAGS\caps!["tag"]
        -- fixes problems regarding tags indexed on a line
        fixTags = (prev, curr) ->
            prev = prev\gsub "\\t%(.-%)?", (v) -> v\gsub "\\", "\\x"
            curr = curr\gsub "\\t%(.-%)?", (v) -> v\gsub "\\", "\\x"

            for t, tag in pairs TAGS\capTags!
                preVal = prev\match tag
                curVal = curr\match tag
                if preVal and not curVal
                    curr = preVal .. curr
            return "{#{curr\gsub("{}", "")\gsub "\\x", "\\"}}"
        -- adds an empty tag if needed
        text = @addEmpty text
        with {tags: {}, text: {}}
            .tags = TAGS\getTags text

            for k = 2, #.tags
                prev = .tags[k - 1]\sub 2, -2
                curr = .tags[k - 0]\sub 2, -2
                .tags[k] = fixTags prev, curr

            .text = @getHeadTail text, capt

            if #.text > 1
                table.remove(.text, 1) if .text[1] == ""

            .text[1] = @fixText .text[1], "start" if .text[1]
            .text[#.text] = @fixText .text[#.text], "end" if #.text > 1

{:UTIL}