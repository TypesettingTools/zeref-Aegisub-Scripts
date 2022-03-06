import TABLE from require "ZF.util.table"

class TAGS

    -- gets captures for all types of tag values
    -- @param getValues boolean
    -- @return table
    caps: (getValues) =>
        {
            font:  getValues and "%s*([^\\}]*)" or "%s*[^\\}]*"
            int:   getValues and "%s*(%d+)" or "%s*%d+"
            dec:   getValues and "%s*(%d[%.%d]*)" or "%s*%d[%.%d]*"
            float: getValues and "%s*(%-?%d[%.%d]*)" or "%s*%-?%d[%.%d]*"
            hex:   getValues and "%s*(&?[Hh]%x+&?)" or "%s*&?[Hh]%x+&?"
            bool:  getValues and "%s*([0-1])" or "%s*[0-1]"
            tag:   getValues and "%{(.-)%}" or "%b{}"
            prt:   getValues and "%((.-)%)" or "%b()"
            brk:   getValues and "%[(.-)%]" or "%b[]"
            oun:   getValues and "%s*([1-9])" or "%s*[1-9]" -- one until nine
            zut:   getValues and "%s*([0-3])" or "%s*[0-3]" -- zero until three
        }

    -- sets a table containing all tags and their set captures
    -- @param getValues boolean
    -- @return table
    capTags: (getValues) =>
        with @caps getValues
            @all = {
                fn: "\\fn#{.font}"
                fs: "\\fs#{.dec}"
                fsp: "\\fsp#{.float}"
                -- c: "\\c#{.hex}"
                ["1c"]: "\\1?c#{.hex}"
                ["2c"]: "\\2c#{.hex}"
                ["3c"]: "\\3c#{.hex}"
                ["4c"]: "\\4c#{.hex}"
                alpha: "\\alpha#{.hex}"
                ["1a"]: "\\1a#{.hex}"
                ["2a"]: "\\2a#{.hex}"
                ["3a"]: "\\3a#{.hex}"
                ["4a"]: "\\4a#{.hex}"
                pos: "\\pos#{.prt}"
                move: "\\move#{.prt}"
                org: "\\org#{.prt}"
                clip: "\\clip#{.prt}"
                iclip: "\\iclip#{.prt}"
                clips: "\\i?clip#{.prt}"
                fad: "\\fad#{.prt}"
                fade: "\\fade#{.prt}"
                t: "\\t#{.prt}"
                fscx: "\\fscx#{.dec}"
                fscy: "\\fscy#{.dec}"
                frx: "\\frx#{.float}"
                fry: "\\fry#{.float}"
                frz: "\\frz?#{.float}"
                -- fr: "\\fr#{.float}"
                fax: "\\fax#{.float}"
                fay: "\\fay#{.float}"
                be: "\\be#{.dec}"
                blur: "\\blur#{.dec}"
                bord: "\\bord#{.dec}"
                xbord: "\\xbord#{.float}"
                ybord: "\\ybord#{.float}"
                shad: "\\shad#{.dec}"
                xshad: "\\xshad#{.float}"
                yshad: "\\yshad#{.float}"
                an: "\\an#{.oun}"
                b: "\\b#{.bool}"
                i: "\\i#{.bool}"
                s: "\\s#{.bool}"
                u: "\\u#{.bool}"
                k: "\\[kK]^*[fo ]*#{.int}"
                q: "\\q#{.zut}"
                p: "\\p#{.int}"
            }
        return @all

    -- adds the values from the capTags function to array
    -- @param getValues boolean
    -- @return table
    array: (getValues) =>
        @capTags getValues
        array = [v for k, v in pairs @all]
        table.sort array
        return array

    -- gets the first tag of the text, if not it returns an empty tag
    -- @param value string
    -- @return string
    getTag: (value) => value\match("%b{}") or "{}"

    -- gets all the tags contained in the text
    -- @param value string
    -- @return table
    getTags: (value) => [t for t in value\gmatch "%b{}"]

    -- @param value string
    -- @param delete string
    -- @param replace string
    -- @return string
    deleteTag: (value, delete = "fscx", replace = "") =>
        @capTags!
        return value\gsub @all[delete], replace

    -- @param value string
    -- @param ... table
    -- @return string
    deleteTags: (value, ...) =>
        @capTags!
        for v in *{...}
            value = type(v) == "string" and @deleteTag(value, v) or @deleteTag value, v[1], v[2]
        return value

    -- removes the tag barces
    -- @param value string
    -- @return string
    remBarces: (value) => if value\match("%b{}") then value\gsub(@caps(true)["tag"], "%1") else value

    -- adds the tag barces
    -- @param value string
    -- @return string
    addBarces: (value) => if value\match("%b{}") then value else "{#{value}}"

    -- hides all transformations
    -- @param value string
    -- @return string
    hideT: (value = "") => value\gsub "\\t%b()", (v) -> v\gsub "\\", "\\&#&#&#%!@@@@%!&#&#&#"

    -- unhides all transformations
    -- @param value string
    -- @return string
    unhideT: (value = "") => value\gsub "\\&#&#&#%!@@@@%!&#&#&#", "\\"

    -- merges tags into a tag set
    -- @param value string
    -- @param ... string || table
    -- @return string
    merge: (value, ...) =>
        merge, value = "", @hideT @remBarces(value)
        for val in *{...}
            if type(val) == "table"
                replace = type(val[2]) == "table" and table.concat(val[2]) or val[2], 1
                if value\match val[1]
                    value = value\gsub val[1], replace, 1
                else
                    merge ..= replace
            else
                merge ..= val
        return @addBarces @unhideT(value) .. merge

    -- finds a tag within the text and returns its value
    -- @param value string
    -- @param tag string
    -- @param typ string
    -- @param getValues boolean
    -- @return string || number || boolean
    findTag: (value, tag, typ, getValues = true) =>
        @capTags getValues
        if value\match @all[tag]
            switch typ
                when "float", "int", "dec", "oun", "zut" then tonumber value\match(@all[tag])
                when "bool"                              then value\match(@all[tag]) == "1" and true or false
                else                                     value\match(@all[tag])

    -- finds all tags within the tag set and adds them to a table
    -- @param value string
    -- @param getValues boolean
    -- @return table
    findAllTags: (value, getValues) =>
        found = {}
        for name, pattern in pairs @all
            typ = switch name
                when "fsp", "frx", "fry", "frz", "fax", "fay", "xbord", "ybord", "xshad", "yshad" then "float"
                when "fs", "fscx", "fscy", "be", "blur", "bord", "shad"                           then "dec"
                when "b", "i", "s", "u"                                                           then "bool"
                when "k", "p"                                                                     then "int"
                when "q"                                                                          then "zut"
                when "an"                                                                         then "oun"
            found[name] = @findTag value, name, typ, getValues
        return found

    -- replaces values relative to coordinate tags
    -- @param value string
    -- @param posVals table
    -- @param orgVals table
    -- @return string
    replaceCoords: (value, posVals, orgVals) =>
        value = @remBarces value
        hasPos = value\match "\\pos%b()"
        hasMove = value\match "\\move%b()"
        if hasMove and #posVals >= 4
            times = posVals[5] and ",#{posVals[5]}" or ""
            times ..= posVals[6] and ",#{posVals[6]}" or ""
            pos = "\\move(#{posVals[1]},#{posVals[2]},#{posVals[3]},#{posVals[4]}#{times})"
            value = value\gsub "\\move%b()", pos, 1
        elseif not hasMove and #posVals == 2
            pos = "\\pos(#{posVals[1]},#{posVals[2]})"
            value = not hasPos and pos .. value or value\gsub "\\pos%b()", pos, 1
        if orgVals
            hasOrg = value\match "\\org%b()"
            org = #orgVals > 0 and "\\org(#{orgVals[1]},#{orgVals[2]})" or ""
            value = not hasOrg and org .. value or value\gsub "\\org%b()", org, 1
        return @addBarces value

    -- checks if the tag set has the dependent tag
    -- @param value string
    -- @return nil
    dependency: (value, ...) =>
        @capTags!
        for val in *{...}
            assert value\match(@all[val]), "#{val} not found"

    -- clears the unnecessary tags and replaces set tags
    -- @param line table
    -- @param tag string
    -- @param mode string
    -- @return string
    clear: (line, tag, mode) =>
        @capTags!
        tag = @hideT @remBarces(tag)
        with @all
            an7 = {.an, "\\an7"}
            patterns = switch mode
                when "Text"
                    {{.fscx, "\\fscx100"}, {.fscy, "\\fscy100"}, .fs, .fsp, .fn, .b, .i, .u, .s}
                when "Shape"
                    {{.fscx, "\\fscx100"}, {.fscy, "\\fscy100"}, {.p, "\\p1"}, .fs, .fsp, .fn, .b, .i, .u, .s}
                when "Shape To Clip"
                    {.clips}
                when "Shape In Clip"
                    {{.pos, "\\pos(0,0)"}, .move, an7, .clips}
                when "Shape Clipper"
                    {an7, .clips}
                when "To an7", "Shape Simplify", "Shape Round Corners"
                    {an7}
                when "Shape Expand"
                    {an7, {.fscx, "\\fscx100"}, {.fscy, "\\fscy100"}, {.frz, "\\frz0"}, {.p, "\\p1"}, .frx, .fry, .fax, .fay, .org}
                when "Clip To Shape"
                    {{.fscx, "\\fscx100"}, {.fscy, "\\fscy100"}, {.frz, "\\frz0"}, .frx, .fry, .fax, .fay, .clip, .iclip, .org}
                when "Stroke Panel"
                    {an7, {.bord, "\\bord0"}}
                when "Gradient Cut"
                    {an7, {.bord, "\\bord0"}, {.shad, "\\shad0"}, .xbord, .ybord, .xshad, .yshad}
            if patterns
                for p, pattern in ipairs patterns
                    ist = type(pattern) == "table"
                    pat = ist and pattern[1] or pattern
                    rpl = ist and pattern[2] or ""
                    if tag\match pat
                        tag = tag\gsub pat, rpl, 1
                    else
                        tag ..= rpl
        -- removes tags that are equal to the style
        patterns = @findAllTags tag
        for t in *{
            {"fn", "fontname"}, {"fs", "fontsize"}, {"fsp", "spacing"}
            {"fscx", "scale_x"}, {"fscy", "scale_y"}, {"frz", "angle"}
            {"bord", "outline"}, {"shad", "shadow"}, {"b", "bold"}
            {"i", "italic"}, {"u", "underline"}, {"s", "strikeout"}
        }
            {a, b} = t -- tag name and style name
            if patterns[a] and line.stylerefOld[b] == patterns[a]
                tag = tag\gsub @all[a], "", 1
        return @addBarces @unhideT tag

{:TAGS}