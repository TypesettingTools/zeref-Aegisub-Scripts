-- load external libs
import MATH from require "ZF.math"
import TAGS from require "ZF.tags"

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
                s = MATH\round(UTIL\interpolation(pct, nil, fs[j], ls[j]), 2)
                j += 1
                return s
            return f
        -- interpolation type
        ipol_f = switch tp
            when "number" then interpolate
            when "color" then interpolate_color
            when "alpha" then interpolate_alpha
            when "shape" then interpolate_shape
        pct = clamp(pct, 0, 1) * (#values - 1)
        valor_i = values[floor(pct) + 1]
        valor_f = values[floor(pct) + 2] or values[floor(pct) + 1]
        return ipol_f(pct - floor(pct), valor_i, valor_f)

    -- readjusts the style values using values set on the line
    tags2styles: (subs, line) =>
        tags, text = nil, line.text
        meta, styles = karaskel.collect_head subs
        for k = 1, styles.n
            styles[k].margin_l = line.margin_l if line.margin_l > 0
            styles[k].margin_r = line.margin_r if line.margin_r > 0
            styles[k].margin_v = line.margin_t if line.margin_t > 0
            styles[k].margin_v = line.margin_b if line.margin_b > 0
            tags = text\match "%b{}"
            if tags
                styles[k].align     = tonumber tags\match "\\an%s*(%d)"             if tags\match "\\an%s*%d"
                styles[k].fontname  = tags\match "\\fn%s*([^\\}]*)"                 if tags\match "\\fn%s*[^\\}]*"
                styles[k].fontsize  = tonumber tags\match "\\fs%s*(%d[%.%d]*)"      if tags\match "\\fs%s*%d[%.%d]*"
                styles[k].scale_x   = tonumber tags\match "\\fscx%s*(%d[%.%d]*)"    if tags\match "\\fscx%s*%d[%.%d]*"
                styles[k].scale_y   = tonumber tags\match "\\fscy%s*(%d[%.%d]*)"    if tags\match "\\fscy%s*%d[%.%d]*"
                styles[k].spacing   = tonumber tags\match "\\fsp%s*(%-?%d[%.%d]*)"  if tags\match "\\fsp%s*%-?%d[%.%d]*"
                styles[k].outline   = tonumber tags\match "\\bord%s*(%d[%.%d]*)"    if tags\match "\\bord%s*%d[%.%d]*"
                styles[k].shadow    = tonumber tags\match "\\shad%s*(%d[%.%d]*)"    if tags\match "\\shad%s*%d[%.%d]*"
                styles[k].angle     = tonumber tags\match "\\frz?%s*(%-?%d[%.%d]*)" if tags\match "\\frz?%s*%-?%d[%.%d]*"
                styles[k].color1    = tags\match "\\1?c%s*(&?[Hh]%x+&?)"            if tags\match "\\1?c%s*&?[Hh]%x+&?"
                styles[k].color2    = tags\match "\\2c%s*(&?[Hh]%x+&?)"             if tags\match "\\2c%s*&?[Hh]%x+&?"
                styles[k].color3    = tags\match "\\3c%s*(&?[Hh]%x+&?)"             if tags\match "\\3c%s*&?[Hh]%x+&?"
                styles[k].color4    = tags\match "\\4c%s*(&?[Hh]%x+&?)"             if tags\match "\\4c%s*&?[Hh]%x+&?"
                styles[k].bold      = true                                          if tags\match "\\b%s*1"
                styles[k].italic    = true                                          if tags\match "\\i%s*1"
                styles[k].underline = true                                          if tags\match "\\u%s*1"
                styles[k].strikeout = true                                          if tags\match "\\s%s*1"
        return meta, styles

    -- find coordinates
    find_coords: (line, meta, ogp) =>
        coords = {
            pos:   {x: 0, y: 0}
            move:  {x1: 0, y1: 0, x2: 0, y2: 0}
            org:   {x: 0, y: 0}
            rots:  {frz: line.styleref.angle, fax: 0, fay: 0, frx: 0, fry: 0}
            scale: {x: line.styleref.scale_x, y: line.styleref.scale_y}
            p: 1
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
            if line.text\match "\\p%s*%d"
                p = line.text\match "\\p%s*(%d)"
                coords.p = tonumber p
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
                if ogp
                    coords.org.x = tonumber px
                    coords.org.y = tonumber py
            if line.text\match "\\move%b()"
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
        return coords

    -- transforms html colors to rgb or the other way around
    html_color: (color, mode = "to_rgb") =>
        local c
        switch mode
            when "to_rgb"  then color\gsub "(%x%x)(%x%x)(%x%x)", (b, g, r) -> c = "&H#{r}#{g}#{b}&"
            when "to_html" then color_from_style(color)\gsub "&?[hH](%x%x)(%x%x)(%x%x)&?", (r, g, b) -> c = "##{b}#{g}#{r}"
        return c

    -- gets the clip content
    clip_to_draw: (clip) =>
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

    -- gets the prev and next value of the text division
    headtail: (s, div) =>
        a, b, head, tail = s\find "(.-)#{div}(.*)"
        if a then head, tail else s, ""

    -- splits text into tags and text
    split_text: (text) =>
        solve_tags = (prev, curr) ->
            tags = TAGS\get(false)
            for t, tag in pairs tags
                val_prev = prev\gsub("\\t%b()", "")\match tag
                val_curr = curr\gsub("\\t%b()", "")\match tag
                if val_prev and not val_curr
                    curr = val_prev .. curr
            return "{#{curr}}"
        text = text\gsub("{}", "")\gsub("\\h", " ")\match("^%s*(.-)%s*$")
        hast = text\gsub("%s+", "")\find "%b{}"
        text = hast != 1 and "{}#{text}" or text
        v = {tags: {}, text: {}}
        with v
            .tags = [t for t in text\gmatch "%b{}"]
            for k = 2, #.tags
                prev = .tags[k - 1]\sub 2, -2
                curr = .tags[k - 0]\sub 2, -2
                .tags[k] = solve_tags(prev, curr)
            while text != ""
                c, d = @headtail(text, "%b{}")
                .text[#.text + 1] = c
                text = d
            table.remove(.text, 1) if .text[1] == ""
        return v

{:UTIL}