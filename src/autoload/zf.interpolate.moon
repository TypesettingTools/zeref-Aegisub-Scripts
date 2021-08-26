export script_name        = "Interpolate Tags"
export script_description = "Interpolates values of selected tags"
export script_author      = "Zeref"
export script_version     = "0.0.3"
-- LIB
zf = require "ZF.main"

-- captures of all interpolable tags
tagsIpol = {
    fs:   "\\fs%s*(%d[%.%d]*)",      fsp:   "\\fsp%s*(%-?%d[%.%d]*)",   fscx:  "\\fscx%s*(%d[%.%d]*)"
    fscy: "\\fscy%s*(%d[%.%d]*)",    frz:   "\\frz%s*(%-?%d[%.%d]*)",   frx:   "\\frx%s*(%-?%d[%.%d]*)"
    fry:  "\\fry%s*(%-?%d[%.%d]*)",  fax:   "\\fax%s*(%-?%d[%.%d]*)",   fay:   "\\fay%s*(%-?%d[%.%d]*)"
    bord: "\\bord%s*(%d[%.%d]*)",    xbord: "\\xbord%s*(%d[%.%d]*)",    ybord: "\\ybord%s*(%d[%.%d]*)"
    shad: "\\shad%s*(%-?%d[%.%d]*)", xshad: "\\xshad%s*(%-?%d[%.%d]*)", yshad: "\\yshad%s*(%-?%d[%.%d]*)"
    "1c": "\\1c%s*(&?[Hh]%x+&?)",    "2c":  "\\2c%s*(&?[Hh]%x+&?)",     "3c":  "\\3c%s*(&?[Hh]%x+&?)"
    "4c": "\\4c%s*(&?[Hh]%x+&?)",    "1a":  "\\1a%s*(&?[Hh]%x+&?)",     "2a":  "\\2a%s*(&?[Hh]%x+&?)"
    "3a": "\\3a%s*(&?[Hh]%x+&?)",    "4a":  "\\4a%s*(&?[Hh]%x+&?)",     alpha: "\\alpha%s*(&?[Hh]%x+&?)"
    pos:  "\\pos%b()",               move:  "\\move%b()",               org:   "\\org%b()"
    clip: "\\i?clip%b()"
}

-- interpolates all selected tags
ipolTags = (firstLine, lastLine, length, selectedTags, accel, layer) ->
    -- if no tag is selected, returns nil
    return nil if #selectedTags <= 0

    -- gets the tag type
    getTyper = (tag) ->
        if tag\match "%dc"
            return "color"
        elseif tag\match("%da") or tag == "alpha"
            return "alpha"
        elseif tag == "pos" or tag == "move" or tag == "org" or tag == "clip"
            return "other"
        return "number"

    -- does the interpolation from two values
    makeIpol = (first, last, tag, typer = "number") ->
        -- transforms values between commas into numbers
        toNumber = (value, tagCurr) ->
            args = {}
            value = value\gsub("%s+", "")\gsub("\\#{tagCurr}%((.-)%)", "%1")\gsub "[^,]*", (i) ->
                args[#args + 1] = tonumber i
            return unpack args
        if typer != "other"
            ipol = {}
            for k = 1, length
                t = (k - 1) ^ accel / (length - 1) ^ accel
                val = zf.util\interpolation(t, typer, first, last)
                val = (typer != "color" and typer != "alpha") and zf.math\round(val) or val
                ipol[#ipol + 1] = "\\#{tag}#{val}"
            return ipol
        interpol = {}
        switch tag
            when "pos"
                assert first and last, "expected tag \" \\pos \""
                fx, fy = toNumber(first, "pos")
                lx, ly = toNumber(last, "pos")
                for k = 1, length
                    t = (k - 1) ^ accel / (length - 1) ^ accel
                    px = zf.math\round zf.util\interpolation(t, "number", fx, lx)
                    py = zf.math\round zf.util\interpolation(t, "number", fy, ly)
                    interpol[k] = "\\pos(#{px},#{py})"
            when "org"
                assert first and last, "expected tag \" \\org \""
                fx, fy = toNumber(first, "org")
                lx, ly = toNumber(last, "org")
                for k = 1, length
                    t = (k - 1) ^ accel / (length - 1) ^ accel
                    px = zf.math\round zf.util\interpolation(t, "number", fx, lx)
                    py = zf.math\round zf.util\interpolation(t, "number", fy, ly)
                    interpol[k] = "\\org(#{px},#{py})"
            when "move"
                -- gets the start and end time of the move tag
                getTime = (args) -> if args[1] then args[1], args[2] elseif args[3] then args[3], args[4]
                assert first and last, "expected tag \" \\move \""
                fx1, fy1, fx2, fy2, ft1, ft2 = toNumber(first, "move")
                lx1, ly1, lx2, ly2, lt1, lt2 = toNumber(last, "move")
                tms, tme = getTime({ft1, ft2, lt1, lt2})
                for k = 1, length
                    t = (k - 1) ^ accel / (length - 1) ^ accel
                    px1 = zf.math\round zf.util\interpolation(t, "number", fx1, lx1)
                    py1 = zf.math\round zf.util\interpolation(t, "number", fy1, ly1)
                    px2 = zf.math\round zf.util\interpolation(t, "number", fx2, lx2)
                    py2 = zf.math\round zf.util\interpolation(t, "number", fy2, ly2)
                    mve = "\\move(#{px1},#{py1},#{px2},#{py2}"
                    interpol[k] = (tms and tme) and "#{mve},#{tms},#{tme})" or "#{mve})"
            when "clip"
                assert first and last, "expected tag \" \\i?clip \""
                cp = first\match("\\iclip") and "\\iclip" or "\\clip"
                fv = zf.util\clip_to_draw first
                lv = zf.util\clip_to_draw last
                for k = 1, length
                    t = (k - 1) ^ accel / (length - 1) ^ accel
                    shape = zf.util\interpolation(t, "shape", fv, lv)
                    interpol[k] = "#{cp}(#{shape})"
        return interpol

    -- sets up the interpolation specifically
    interpolations = {}
    for s, sel in pairs selectedTags
        for tag, cap in pairs tagsIpol
            if tag == sel
                typer = getTyper tag
                getFirst = firstLine.tags\gsub("\\t%b()", "")\match cap
                getLast = lastLine.tags\gsub("\\t%b()", "")\match cap
                if typer != "other"
                    if getFirst and not getLast
                        getLast = lastLine.style[tag]
                    elseif getLast and not getFirst
                        getFirst = firstLine.style[tag]
                    interpolations[s] = (getFirst and getLast) and makeIpol(getFirst, getLast, tag, typer) or {}
                else
                    interpolations[s] = makeIpol(getFirst, getLast, tag, "other") if layer == 1

    -- concatenates the interpolated tag layers
    concatIpol = {}
    lens = [interpolations[k] and #interpolations[k] or 0 for k = 1, #interpolations]
    table.sort lens, (a, b) -> a > b
    len = lens[1] or 0

    for k = 1, len
        concatIpol[k] = ""
        for i = 1, #interpolations
            concatIpol[k] ..= interpolations[i] and (interpolations[i][k] or "") or ""

    return concatIpol

-- Creates the entire structure for the interpolation
class CreateIpol

    new: (subs, sel, selectedTags, elements) =>
        @subs, @sel = subs, sel
        @selectedTags = selectedTags
        @ignoreText = elements.igt
        @acc = elements.acc

    -- index all selected lines
    allLines: =>
        lines = {}
        for _, i in ipairs @sel
            l = @subs[i]
            -- checks if the lines are really text
            text = zf.tags\remove("full", l.text)
            assert not text\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"
            assert text\gsub("%s+", "") != "", "text expected"
            -- gets text metrics
            meta, styles = zf.util\tags2styles(@subs, l)
            karaskel.preproc_line(@subs, meta, styles, l)
            -- fixes problems for different tags with equal values
            l.text = l.text\gsub("\\c%s*(&?[Hh]%x+&?)", "\\1c%1")
            l.text = l.text\gsub("\\fr%s*(%-?%d[%.%d]*)", "\\frz%1")
            lines[#lines + 1] = l
        return lines

    -- get all selected lines
    getLines: => @lines = @allLines!

    -- splits the lines into tags and text and adds the style 
    sptLines: =>
        @getLines!
        cfs, afs = util.color_from_style, util.alpha_from_style
        for k = 1, #@lines
            splited = zf.text(@subs, @lines[k], @lines[k].text)\tags(false)
            @lines[k] = {}
            for t, tag in ipairs splited
                @lines[k][t] = {
                    tags: tag.tags
                    text: tag.text_stripped_with_space
                    style: {
                        "fs":    tag.styleref.fontsize
                        "fsp":   tag.styleref.spacing
                        "fscx":  tag.styleref.scale_x
                        "fscy":  tag.styleref.scale_y
                        "frz":   tag.styleref.angle
                        "bord":  tag.styleref.outline
                        "xbord": 0
                        "ybord": 0
                        "shad":  tag.styleref.shadow
                        "xshad": 0
                        "yshad": 0
                        "frx":   0
                        "fry":   0
                        "fax":   0
                        "fay":   0
                        "1c":    cfs tag.styleref.color1
                        "2c":    cfs tag.styleref.color2
                        "3c":    cfs tag.styleref.color3
                        "4c":    cfs tag.styleref.color4
                        "1a":    afs tag.styleref.color1
                        "2a":    afs tag.styleref.color2
                        "3a":    afs tag.styleref.color3
                        "4a":    afs tag.styleref.color4
                        "alpha": afs tag.styleref.color1
                    }
                }

    -- gets the interpolation for all tag layers
    getIpol: =>
        @sptLines! -- gets the split line values
        -- @param len = length of the line
        -- @param lenTL = length of the line tag layers
        @interpolatedTags, len, lenTL = {}, #@lines, nil
        if @ignoreText
            lenTL = math.max(#@lines[1], #@lines[len])
            for k = 1, lenTL
                first = @lines[1][k] or @lines[1][#@lines[1]]
                last = @lines[len][k] or @lines[len][#@lines[len]]
                @interpolatedTags[k] = ipolTags(first, last, len, @selectedTags, @acc, k)
        else
            lenTL = math.min(#@lines[1], #@lines[len])
            for k = 1, lenTL
                first = @lines[1][k]
                last = @lines[len][k]
                @interpolatedTags[k] = ipolTags(first, last, len, @selectedTags, @acc, k)

    -- configures and concatenates all output
    concat: =>
        @getIpol!
        -- deletes the origin tags that were interpolated
        deleteOld = (src, new) ->
            for t, tag in pairs tagsIpol
                -- hides transformations
                src = src\gsub "\\t%b()", (v) ->
                    v = v\gsub "\\", "\\XT"
                    return v
                if src\match(tag) and new\match(tag)
                    src = src\gsub tag, ""
            return new .. src\gsub "\\XT", "\\"
        @result = {}
        for k, i in ipairs @sel
            l = @subs[i]
            @result[k] = {}
            if @ignoreText
                -- gets the line that has the most tag layers
                mostTags = #@lines[1] > #@lines[#@lines] and @lines[1] or @lines[#@lines]
                for t, tag in ipairs mostTags
                    inTag = @interpolatedTags[t] and (@interpolatedTags[t][k] or "") or ""
                    srTag = (@lines[k][t] and @lines[k][t].tags or "")\sub(2, -2)
                    nwTag = deleteOld(srTag, inTag)
                    @result[k][t] = "{#{nwTag}}" .. tag.text
            else
                for t, tag in ipairs @lines[k]
                    inTag = @interpolatedTags[t] and (@interpolatedTags[t][k] or "") or ""
                    srTag = tag.tags\sub(2, -2)
                    nwTag = deleteOld(srTag, inTag)
                    @result[k][t] = "{#{nwTag}}" .. tag.text
            l.text = table.concat(@result[k])\gsub "{}", ""
            @subs[i] = l
        return @subs

main = (subs, sel) ->
    inter = zf.config\load(zf.config\interface(script_name)(tagsIpol), script_name)
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                zf.config\interface(script_name)(tagsIpol)
        break if buttons == "Ok" or buttons == "Cancel"
    selecteds = {}
    for e, element in pairs elements
        if e != "igt" and e != "acc"
            selecteds[#selecteds + 1] = element == true and e or nil
    aegisub.progress.task "Processing..."
    subs = CreateIpol(subs, sel, selecteds, elements)\concat! if buttons == "Ok"

aegisub.register_macro script_name, script_description, main, (subs, sel) -> #sel > 1