import TABLE from require "ZF.util.table"

class TAGS

    -- gets captures for all types of tag values
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
                clips: "\\clip#{.prt}"
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
    array: (getValues) =>
        @capTags getValues
        array = [v for k, v in pairs @all]
        table.sort array
        return array

    -- gets the first tag of the text, if not it returns an empty tag
    getTag: (value) => value\match("%b{}") or "{}"

    -- gets all the tags contained in the text
    getTags: (value) => [t for t in value\gmatch "%b{}"]

    -- removes the tag barces
    remBarces: (value) => if value\match("%b{}") then value\gsub(@caps(true).tag, "%1") else value

    -- adds the tag barces
    addBarces: (value) => if value\match("%b{}") then value else "{#{value}}"

    -- merges tags into a tag set
    merge: (tag, ...) =>
        merge, tag = "", @remBarces(tag)\gsub "\\t%(.-%)?", (v) -> v\gsub "\\", "\\x"
        for val in *{...}
            if type(val) == "table"
                replace = type(val[2]) == "table" and table.concat(val[2]) or val[2], 1
                if tag\match val[1]
                    tag = tag\gsub val[1], replace, 1
                else
                    merge ..= replace
            else
                merge ..= val
        return "{#{tag\gsub("\\x", "\\") .. merge}}"

    -- finds a tag within the text and returns its value
    findTag: (value, tag, typ, getValues = true) =>
        @capTags getValues
        if value\match @all[tag]
            switch typ
                when "float", "int", "dec", "oun", "zut" then tonumber value\match(@all[tag])
                when "bool"                              then value\match(@all[tag]) == "1" and true or false
                else                                     value\match(@all[tag])

    -- finds all tags within the tag set and adds them to a table
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
    replaceT: (value, tag, replace) =>
        found = @findTag value, tag, nil, false
        switch tag
            when "pos"
                local pos, isMove
                if #replace == 2
                    pos = "\\pos(#{replace[1]},#{replace[2]})"
                else
                    times = replace[5] and ",#{replace[5]}" or ""
                    times ..= replace[6] and ",#{replace[6]}" or ""
                    pos, isMove = "\\move(#{replace[1]},#{replace[2]},#{replace[3]},#{replace[4]}#{times})", true
                if found and not isMove
                    value\gsub "\\pos%b()", pos, 1
                elseif isMove
                    value\gsub "\\move%b()", pos, 1
                else
                    pos .. value
            when "org"
                org = #replace > 0 and "\\org(#{replace[1]},#{replace[2]})" or ""
                if found
                    value\gsub "\\org%b()", org
                else
                    org .. value

    -- checks if the tag set has the dependent tag
    dependency: (tag, ...) =>
        @capTags!
        for val in *{...}
            assert tag\match(@all[val]), "#{val} not found"

    -- clears the unnecessary tags and replaces set tags
    clear: (line, tag, mode) =>
        @capTags!
        tag = @remBarces tag
        with @all
            an7 = {.an, "\\an7"}
            patterns = switch mode
                when "text"
                    {{.fsp, "\\fsp0"}, {.fscx, "\\fscx100"}, {.fscy, "\\fscy100"}, {.fsp, "\\fsp0"}, .fs, .fn, .b, .i, .u, .s}
                when "Shape To Clip"
                    {.clips}
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
        matchs = @findAllTags tag
        styleValues = {
            {"fn", "fontname"}, {"fs", "fontsize"}, {"fsp", "spacing"}
            {"fscx", "scale_x"}, {"fscy", "scale_y"}, {"frz", "angle"}
            {"bord", "outline"}, {"shad", "shadow"}, {"b", "bold"}
            {"i", "italic"}, {"u", "underline"}, {"s", "strikeout"}
        }
        for _, t in ipairs styleValues
            tn, sn = t[1], t[2] -- tag name and style name
            if matchs[tn] and line.stylerefOld[sn] == matchs[tn]
                tag = tag\gsub @all[tn], "", 1
        return @addBarces tag

{:TAGS}