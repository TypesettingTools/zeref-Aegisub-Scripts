import TABLE from require "ZF.util.table"
import UTIL from require "ZF.util.util"

class TAGS

    version: "2.0.0"

    new: (getValues) => @getPatternsTags getValues

    -- gets captures for all types of tag values
    -- @param getValues boolean
    -- @return table
    patterns: (getValues) =>
        @ptt = {
            font:  getValues and "%s*([^\\}]*)" or "%s*[^\\}]*"
            int:   getValues and "%s*(%d+)" or "%s*%d+"
            dec:   getValues and "%s*(%d[%.%d]*)" or "%s*%d[%.%d]*"
            float: getValues and "%s*(%-?%d[%.%d]*)" or "%s*%-?%d[%.%d]*"
            hex:   getValues and "%s*(&?[Hh]%x+&?)" or "%s*&?[Hh]%x+&?"
            bool:  getValues and "%s*([0-1])" or "%s*[0-1]"
            tag:   getValues and "%{(.-)%}" or "%b{}"
            prt:   getValues and "%((.-)%)" or "%b()"
            pmt:   getValues and "%((.+)%)" or "%b()"
            brk:   getValues and "%[(.-)%]" or "%b[]"
            oun:   getValues and "%s*([1-9])" or "%s*[1-9]" -- one until nine
            zut:   getValues and "%s*([0-3])" or "%s*[0-3]" -- zero until three
            shp:   "m%s+%-?%d[%.%-%d mlb]*"
        }
        return @ptt

    -- sets a table containing all tags and their set captures
    -- @param getValues boolean
    -- @return table
    getPatternsTags: (getValues) =>
        {:font, :int, :dec, :float, :hex, :prt, :pmt, :oun, :zut, :shp} = @patterns getValues
        @all = {
            fn:      {pattern: "\\fn#{font}",          type: "font"}
            fs:      {pattern: "\\fs#{float}",         type: "dec"}
            fsp:     {pattern: "\\fsp#{float}",        type: "float"}
            ["1c"]:  {pattern: "\\1?c#{hex}",          type: "hex"}
            ["2c"]:  {pattern: "\\2c#{hex}",           type: "hex"}
            ["3c"]:  {pattern: "\\3c#{hex}",           type: "hex"}
            ["4c"]:  {pattern: "\\4c#{hex}",           type: "hex"}
            alpha:   {pattern: "\\alpha#{hex}",        type: "hex"}
            ["1a"]:  {pattern: "\\1a#{hex}",           type: "hex"}
            ["2a"]:  {pattern: "\\2a#{hex}",           type: "hex"}
            ["3a"]:  {pattern: "\\3a#{hex}",           type: "hex"}
            ["4a"]:  {pattern: "\\4a#{hex}",           type: "hex"}
            pos:     {pattern: "\\pos#{prt}",          type: "prt"}
            move:    {pattern: "\\move#{prt}",         type: "prt"}
            org:     {pattern: "\\org#{prt}",          type: "prt"}
            clip:    {pattern: "\\clip#{prt}",         type: "prt", pattern_alt: "\\clip#{shp}",  type_alt: "shp"}
            iclip:   {pattern: "\\iclip#{prt}",        type: "prt", pattern_alt: "\\iclip#{shp}", type_alt: "shp"}
            fad:     {pattern: "\\fad#{prt}",          type: "prt"}
            fade:    {pattern: "\\fade#{prt}",         type: "prt"}
            t:       {pattern: "\\t#{pmt}",            type: "pmt"}
            fscx:    {pattern: "\\fscx#{dec}",         type: "dec"}
            fscy:    {pattern: "\\fscy#{dec}",         type: "dec"}
            frx:     {pattern: "\\frx#{float}",        type: "float"}
            fry:     {pattern: "\\fry#{float}",        type: "float"}
            frz:     {pattern: "\\frz?#{float}",       type: "float"}
            fax:     {pattern: "\\fax#{float}",        type: "float"}
            fay:     {pattern: "\\fay#{float}",        type: "float"}
            be:      {pattern: "\\be#{dec}",           type: "dec"}
            blur:    {pattern: "\\blur#{dec}",         type: "dec"}
            bord:    {pattern: "\\bord#{dec}",         type: "dec"}
            xbord:   {pattern: "\\xbord#{float}",      type: "float"}
            ybord:   {pattern: "\\ybord#{float}",      type: "float"}
            shad:    {pattern: "\\shad#{dec}",         type: "dec"}
            xshad:   {pattern: "\\xshad#{float}",      type: "float"}
            yshad:   {pattern: "\\yshad#{float}",      type: "float"}
            an:      {pattern: "\\an#{oun}",           type: "oun"}
            b:       {pattern: "\\b#{bool}",           type: "bool"}
            i:       {pattern: "\\i#{bool}",           type: "bool"}
            s:       {pattern: "\\s#{bool}",           type: "bool"}
            u:       {pattern: "\\u#{bool}",           type: "bool"}
            k:       {pattern: "\\[kK]^*[fo ]*#{int}", type: "int"}
            q:       {pattern: "\\q#{zut}",            type: "zut"}
            p:       {pattern: "\\p#{int}",            type: "int"}
        }
        -- tag name for the style
        @styleTags = {
            fn:     "fontname"
            fs:     "fontsize"
            fsp:    "spacing"
            fscx:   "scale_x"
            fscy:   "scale_y"
            frz:    "angle"
            bord:   "outline"
            shad:   "shadow"
            alpha:  "alpha"
            ["1a"]: "alpha1"
            ["2a"]: "alpha2"
            ["3a"]: "alpha3"
            ["4a"]: "alpha4"
            ["1c"]: "color1"
            ["2c"]: "color2"
            ["3c"]: "color3"
            ["4c"]: "color4"
            b:      "bold"
            i:      "italic"
            u:      "underline"
            s:      "strikeout"
        }
        -- tags that appear only once
        @once = {"an", "org", "pos", "move"}
        return @all

    -- removes the tag barces
    -- @param text string
    -- @return string
    remBarces: (text) => if text\match("%b{}") then text\gsub(@patterns(true)["tag"], "%1") else text

    -- adds the tag barces
    -- @param value string
    -- @return string
    addBarces: (value) => if value\match("%b{}") then value else "{#{value}}"

    -- hides all transformations
    -- @param value string
    -- @return string
    hidetr: (value) => value\gsub "\\t%b()", (v) -> v\gsub "\\", "\\@"

    -- unhides all transformations
    -- @param value string
    -- @return string
    unhidetr: (value) => value\gsub "\\@", "\\"

    -- moves transformations in transformations out
    -- @param value string
    -- @return string
    fixtr: (value) =>
        fix = (val) ->
            new = ""
            while val
                new ..= "\\t(#{val\gsub "\\t%b()", ""})"
                val = val\match "\\t%((.+)%)%}?"
            return new
        return value\gsub "\\t(%b())", (tr) -> fix tr\match "%((.+)%)"

    -- gets the text non tags
    -- @param value string
    -- @return string
    getRawText: (value) =>
        rawTag = value\match("%b{}") or "{}"
        rawTxt = value\gsub "%b{}", ""
        return rawTag, rawTxt

    -- gets the values in brackets
    -- @param value string
    -- @param tag string
    -- @return number
    inBrackets: (value, tag) =>
        arguments = {}
        value\gsub("%s+", "")\gsub("\\#{tag}%((.-)%)", "%1")\gsub "[^,]*", (i) ->
            TABLE(arguments)\push tonumber i
        return #arguments == 0 and value or arguments

    -- gets the last value that can be found in a capture
    -- @param value string
    -- @param pattern string
    -- @return string
    getLastTag: (value, pattern = "", last) =>
        for val in value\gmatch pattern
            last = val
        return last

    -- gets all the tag layers contained in the text
    -- @param value string
    -- @return table
    getTagLayers: (value) => [t for t in value\gmatch "%b{}"]

    -- adds a tag to the end of a tag layer
    -- @param value string
    -- @param tag string
    -- @param addBarces boolean
    -- @return string
    insertTag: (value, tag, addBarces = true) =>
        result = @remBarces(value) .. tag
        return not addBarces and result or @addBarces result

    -- adds one or more tags to the end of a tag layer
    -- @param value string
    -- @return string
    insertTags: (value, ...) =>
        for tag in *{...}
            value = @insertTag value, tag, false
        return @splitTags(value).__tostring!

    -- removes a tag from a tag layer
    -- @param value string
    -- @param delete string
    -- @param replace string
    -- @return string
    removeTag: (value, delete, replace = "", n) =>
        @getPatternsTags!
        return value\gsub @all[delete]["pattern"], replace, n

    -- removes one or more tags from a tag layer
    -- @param value string
    -- @param ... table
    -- @return string
    removeTags: (value, ...) =>
        for v in *{...}
            value = type(v) == "string" and @removeTag(value, v) or @removeTag value, v[1], v[2], v[3]
        return value

    -- checks if dependent tags are contained within the tags layer
    -- @param value string
    -- @return nil
    dependency: (value, ...) =>
        @getPatternsTags!
        for val in *{...}
            assert value\match(@all[val]["pattern"]), "#{val} not found"

    -- finds a tag within the text and returns its value
    -- @param value string
    -- @param tag string
    -- @param typ string
    -- @param getValues boolean
    -- @return string || number || boolean
    getTagInTags: (value, tagName) =>
        @getPatternsTags true
        if tagName == "clip" or tagName == "iclip"
            result = @hidetr value
            if a = @getLastTag result, @all[tagName]["pattern"]
                return @inBrackets a, tagName
            elseif b = @getLastTag result, @all[tagName]["pattern_alt"]
                return b
        else
            if result = @getLastTag @hidetr(value), @all[tagName]["pattern"]
                switch @all[tagName]["type"]
                    when "float", "int", "dec", "oun", "zut" then tonumber result
                    when "bool"                              then result == "1"
                    when "prt"                               then @inBrackets result, tagName
                    else                                     result

    -- removes the spaces at the beginning or end of the text
    -- @param text string
    -- @param where string
    -- @return string
    blankText: (text, where = "both") =>
        switch where
            when "both"   then text\match "^%s*(.-)%s*$"
            when "start"  then text\match "^%s*(.-%s*)$"
            when "end"    then text\match "^(%s*.-)%s*$"
            when "spaceL" then text\match "^(%s*).-%s*$"
            when "spaceR" then text\match "^%s*.-(%s*)$"
            when "spaces" then text\match "^(%s*).-(%s*)$"

    -- adds the first category tags to the first tag layer and removes them if they are found in other layers
    -- @param text string
    -- @return string
    firstCategory: (text) =>
        @getPatternsTags!
        firstCategory = (txt, pattern) ->
            i = 1
            for t in txt\gmatch "%b{}"
                if match = t\match pattern
                    if i > 1
                        txt = txt\gsub(pattern, "")\gsub "{(.-)}", "{%1#{match}}", 1
                    else
                        j = 1
                        txt = txt\gsub pattern, (p) ->
                            if j > 1
                                return ""
                            j += 1
                            return p
                    break
                i += 1
            return txt
        for name in *@once
            text = firstCategory text, @all[name]["pattern"]
        return text

    -- readjusts the style values using values set on the line
    -- @param subs userdata
    -- @param line table
    -- @return table, table, table
    toStyle: (subs, line) =>
        meta, style = karaskel.collect_head subs
        -- copies the old style and adds the alpha values into it
        old_style = TABLE(style)\copy!
        for i = 1, old_style.n
            with old_style[i]
                .alpha  = "&H00&"
                .alpha1 = alpha_from_style .color1
                .alpha2 = alpha_from_style .color2
                .alpha3 = alpha_from_style .color3
                .alpha4 = alpha_from_style .color4
                .color1 = color_from_style .color1
                .color2 = color_from_style .color2
                .color3 = color_from_style .color3
                .color4 = color_from_style .color4
        -- defines the new values for the style
        for i = 1, style.n
            with style[i]
                {:margin_l, :margin_r, :margin_t, :margin_b, :text} = line
                .margin_l = margin_l if margin_l > 0
                .margin_r = margin_r if margin_r > 0
                .margin_v = margin_t if margin_t > 0
                .margin_v = margin_b if margin_b > 0
                if rawTag = @hidetr @getRawText text
                    .align     = @getTagInTags(rawTag, "an") or .align
                    .fontname  = @getTagInTags(rawTag, "fn") or .fontname

                    -- fixes problem with fontsize being 0 or smaller than 0
                    if fontsize = @getTagInTags(rawTag, "fs")
                        .fontsize = fontsize <= 0 and .fontsize or fontsize

                    .scale_x   = @getTagInTags(rawTag, "fscx") or .scale_x
                    .scale_y   = @getTagInTags(rawTag, "fscy") or .scale_y
                    .spacing   = @getTagInTags(rawTag, "fsp")  or .spacing
                    .outline   = @getTagInTags(rawTag, "bord") or .outline
                    .shadow    = @getTagInTags(rawTag, "shad") or .shadow
                    .angle     = @getTagInTags(rawTag, "frz")  or .angle

                    .alpha     = @getTagInTags(rawTag, "alpha") or "&H00&"
                    .alpha1    = @getTagInTags(rawTag, "1a") or alpha_from_style .color1
                    .alpha2    = @getTagInTags(rawTag, "2a") or alpha_from_style .color2
                    .alpha3    = @getTagInTags(rawTag, "3a") or alpha_from_style .color3
                    .alpha4    = @getTagInTags(rawTag, "4a") or alpha_from_style .color4

                    .color1    = @getTagInTags(rawTag, "1c") or color_from_style .color1
                    .color2    = @getTagInTags(rawTag, "2c") or color_from_style .color2
                    .color3    = @getTagInTags(rawTag, "3c") or color_from_style .color3
                    .color4    = @getTagInTags(rawTag, "4c") or color_from_style .color4

                    .bold      = @getTagInTags(rawTag, "b") or .bold
                    .italic    = @getTagInTags(rawTag, "i") or .italic
                    .underline = @getTagInTags(rawTag, "u") or .underline
                    .strikeout = @getTagInTags(rawTag, "s") or .strikeout
        return meta, style, old_style

    -- find coordinates
    -- @param line table
    -- @param meta table
    -- @param ogp boolean
    -- @return table
    findCoords: (line, meta) =>
        line.text = @firstCategory line.text
        with {pos: {}, move: {}, org: {}, fax: 0, fay: 0, frx: 0, fry: 0, p: "text"}
            if meta
                {:res_x, :res_y} = meta
                {:align, :margin_l, :margin_r, :margin_v} = line.styleref
                x = switch align
                    when 1, 4, 7 then margin_l
                    when 2, 5, 8 then (res_x - margin_r + margin_l) / 2
                    when 3, 6, 9 then res_x - margin_r
                y = switch align
                    when 1, 2, 3 then res_y - margin_v
                    when 4, 5, 6 then res_y / 2
                    when 7, 8, 9 then margin_v
                .pos, .org = {x, y}, {x, y}
            if rawTag = @hidetr @getRawText line.text
                .p = @getTagInTags(rawTag, "p") or .p
                -- gets values from the perspective
                .frx = @getTagInTags(rawTag, "frx") or 0
                .fry = @getTagInTags(rawTag, "fry") or 0
                .fax = @getTagInTags(rawTag, "fax") or 0
                .fay = @getTagInTags(rawTag, "fay") or 0
                -- gets \pos or \move
                if mPos = @getTagInTags rawTag, "pos", false
                    .pos = mPos
                elseif mMov = @getTagInTags rawTag, "move", false
                    .move = mMov
                    .pos = {mMov[1], mMov[2]}
                -- gets \org
                if mOrg = @getTagInTags rawTag, "org", false
                    .org = mOrg
                else
                    .org = {.pos[1], .pos[2]}

    -- finds all tags within the tag set and adds them to a table
    -- @param value string
    -- @return table
    splitTags: (value = "") =>
        -- delete empty tags
        for name in *{"t", "pos", "org", "move", "fad", "fade", "i?clip"}
            value = value\gsub "\\#{name}%(%s*%)", ""
        -- fixes the problem of different tags having the same meaning
        value = value\gsub("\\c(#{@ptt["hex"]})", "\\1c%1")\gsub "\\fr(#{@ptt["float"]})", "\\frz%1"
        -- saves the original value for future changes
        split, copyValue = {}, value
        -- builds the tag
        buildTag = (tname, tvalue, notp) ->
            build = "\\" .. tname
            if type(tvalue) == "table"
                concat = ""
                for key, val in ipairs tvalue
                    concat ..= val .. (key == #tvalue and "" or ",")
                build ..= "(#{concat})"
            elseif UTIL\isShape tvalue
                build ..= notp and "#{tvalue}" or "(#{tvalue})"
            else
                build ..= type(tvalue) == "boolean" and (tvalue and "1" or "0") or tvalue
            return build, value\find build, 1, true
        -- builds the tags
        split.builder = ->
            add = {}
            for key, val in ipairs split
                {name: a, value: b} = val
                if type(b) == "table" and b.builder
                    with val
                        ts = .ts and .ts .. "," or ""
                        te = .te and .te .. "," or ""
                        ac = .ac and .ac .. "," or ""
                        result = "\\t(#{ts .. te .. ac}#{b.builder!})"
                        TABLE(add)\push result
                else
                    result = buildTag a, b
                    TABLE(add)\push result
            return table.concat add
        -- builds the tags permanently
        split.__tostring = -> @addBarces split.builder!
        for tagName in pairs @all
            if tagValue = @getTagInTags value, tagName
                build, i, j = buildTag tagName, tagValue
                TABLE(split)\push {value: tagValue, name: tagName, :build, :i, :j}
            elseif copyValue\match "\\t%b()"
                ts, te, ac, transform, tf = 0, 0, 1, "", ""
                fn = (t) ->
                    if tf = t\match "%(.+%)"
                        ts, te, ac, transform = tf\match "%(([%.%d]*)%,?([%.%d]*)%,?([%.%d]*)%,?(.+)%)"
                        ts = tonumber ts
                        te = tonumber te
                        ac = tonumber ac
                    return ""
                while copyValue\match "\\t%b()"
                    copyValue = copyValue\gsub "\\t%b()", fn, 1
                    build, i, j = buildTag "t", tf, true
                    TABLE(split)\push {value: @splitTags(transform), name: "t", :build, :ts, :te, :ac, :i, :j}
        -- sorts the table with the tag values at the position relative to the original line
        table.sort split, (a, b) -> a.i < b.i
        return split

    -- checks if a tag contains in another tag layer
    -- @param tags table || string
    -- @return table || boolean
    tagsContainsTag: (tags, tagName) =>
        tags = type(tags) == "table" and tags or @splitTags tags
        for t, tag in ipairs tags
            if tag.name == tagName
                return tag
        return false

    -- adds the tags contained in the style to the current tags
    -- @param line table
    -- @param tags string
    -- @param pos table
    -- @return string
    addStyleTags: (line, tags, pos) =>
        tags = @remBarces tags
        for name, style_name in pairs @styleTags
            unless @tagsContainsTag tags, name
                style_value = line.styleref_old[style_name]
                style_value = style_value == true and "1" or style_value == false and "0" or style_value
                tags = "\\" .. name .. style_value .. tags
        return not pos and @addBarces(tags) or @replaceCoords tags, pos

    -- splits text by tag layers
    -- @param text string
    -- @param addPendingTags boolean
    -- @param skipOnceBool boolean
    -- @return table
    splitTextByTags: (text, addPendingTags = true, skipOnceBool = false) =>
        text = @firstCategory text
        -- adds pending values in other tag layers
        addPending = (tags) ->
            skipOnce = (name) ->
                for sk in *@once
                    if name == sk
                        return true
                return false
            -- scans between all tag layers to eliminate repeated tags
            for i = 1, #tags
                tags[i] = @splitTags(tags[i]).__tostring!
            -- adds pending values
            for i = 2, #tags
                splitPrev = @splitTags tags[i - 1]
                for j = #splitPrev, 1, -1
                    with splitPrev[j]
                        if .name == "t" or not @tagsContainsTag tags[i], .name
                            unless skipOnceBool and skipOnce .name
                                tags[i] = @addBarces .build .. @remBarces tags[i]
            return tags
        -- adds an empty tag to the beginning of the text if there is no tag at the beginning
        text = @blankText text, "both"
        hast = text\gsub("%s+", "")\find "%b{}"
        text = hast != 1 and "{}#{text}" or text
        -- table that will index the text and tag values
        split = {tags: {}, text: {}}
        -- turn the table back to text
        split.__tostring = ->
            concat = ""
            for i = 1, #split.tags
                concat ..= split.tags[i] .. split.text[i]
            return concat
        with split
            .tags = @getTagLayers text
            if addPendingTags
                .tags = addPending .tags
            .text = UTIL\headTails text, "%b{}"
            if #.text > 1 and .text[1] == ""
                TABLE(.text)\shift!
            -- if the last tag contains no text, add some accompanying text
            if #.tags - #.text == 1
                TABLE(.text)\push ""
            -- removes the line start and end spacing
            .text[1] = @blankText .text[1], "start" if .text[1]
            .text[#.text] = @blankText .text[#.text], "end" if #.text > 1

    -- splits the text by line breaks
    -- @param value string
    -- @return table
    splitTextByBreaks: (value) =>
        split = UTIL\headTails value, "\\N"
        if #split >= 1
            split[1] = @splitTextByTags(split[1]).__tostring!
            for i = 2, #split
                result = @getLastTag(split[i - 1], "%b{}") .. split[i]
                result = result\gsub "}%s*{", ""
                split[i] = @splitTextByTags(result).__tostring!
        else
            split[1] = "{}"
        return split

    -- replaces values relative to coordinate tags
    -- @param value string
    -- @param posVals table
    -- @param orgVals table
    -- @return string
    replaceCoords: (value, posVals, orgVals) =>
        value = @remBarces value
        hasMove = value\match "\\move%b()"
        if hasMove and #posVals >= 4
            times = posVals[5] and ",#{posVals[5]}" or ""
            times ..= posVals[6] and ",#{posVals[6]}" or ""
            pos = "\\move(#{posVals[1]},#{posVals[2]},#{posVals[3]},#{posVals[4]}#{times})"
            value = value\gsub "\\move%b()", pos, 1
        elseif not hasMove and #posVals == 2
            pos = "\\pos(#{posVals[1]},#{posVals[2]})"
            hasPos = value\match "\\pos%b()"
            value = not hasPos and pos .. value or value\gsub "\\pos%b()", pos, 1
        if orgVals
            org = #orgVals > 0 and "\\org(#{orgVals[1]},#{orgVals[2]})" or ""
            hasOrg = value\match "\\org%b()"
            value = not hasOrg and org .. value or value\gsub "\\org%b()", org, 1
        return @addBarces value

    -- remove equal tags in tag layers
    -- @param text string
    -- @return string
    clearEqualTags: (text) =>
        split = @splitTextByTags text, false
        for i = 2, #split.tags
            prevTag = @splitTags split.tags[i - 1]
            currTag = @splitTags split.tags[i]
            tagsToRemove = {}
            for j = 1, #prevTag
                {name: prev_name, build: prev_build} = prevTag[j]
                if tag = @tagsContainsTag currTag, prev_name
                    if prev_build == tag.build
                        TABLE(tagsToRemove)\push prev_name
            split.tags[i] = @clearByPreset split.tags[i], tagsToRemove
        return split.__tostring!\gsub "{%s*}", ""

    -- removes tags from the line if they match the values defined in the style
    -- @param line table
    -- @param tags string
    -- @return string
    clearStyleValues: (line, tags, setToOld) =>
        i, split = 1, @splitTags tags
        {:styleTags} = @
        while i <= #split
            {name: sn, value: sv} = split[i]
            if styleTags[sn] and sv == line.styleref_old[styleTags[sn]]
                table.remove split, i
                i -= 1
            -- sets the current value to the old value
            if setToOld
                if val = line.styleref_old[styleTags[sn]]
                    line.styleref_old[styleTags[sn]] = val != sv and sv or val
            i += 1
        return split.__tostring!

    -- clears the tags from a preset
    -- @param tags string
    -- @param presetValue string
    -- @return string
    clearByPreset: (tags, presetValue = "To Text") =>
        -- checks if a tag contains in another tag layer
        tagsContainsTag = (t, name) ->
            for v in *t
                if (type(v) == "table" and v[1] or v) == name
                    return v
            return false
        -- function default presets
        presets = {
            ["To Text"]: {"fs", "fscx", "fscy", "fsp", "fn", "b", "i", "u", "s"}
            ["Clip To Shape"]: {"clip", "iclip", "fax", "fay", "frx", "fry", "frz", "org"}
            ["Shape Expand"]: {"an", "fscx", "fscy", "fax", "fay", "frx", "fry", "frz", "org"}
        }
        i, split = 1, @splitTags tags
        if preset = type(presetValue) == "table" and presetValue or presets[presetValue]
            if #preset >= 1
                while i <= #split
                    {name: sn, value: sv} = split[i]
                    if tag = tagsContainsTag preset, sn
                        -- if there is a value to replace, replace it, else, remove the tag
                        if tag[2]
                            split[i].value = tag[2]
                        else
                            table.remove split, i
                            i -= 1
                    i += 1
        return split.__tostring!

    -- clears the unnecessary tags and replaces set tags
    -- @param line table
    -- @param tags string
    -- @param preset string || table
    -- @return string
    clear: (line, tags, preset) => @clearStyleValues line, @clearByPreset tags, preset

{:TAGS}