import UTIL  from require "ZF.util.util"
import MATH  from require "ZF.util.math"
import TABLE from require "ZF.util.table"
import TAGS  from require "ZF.text.tags"
import TEXT  from require "ZF.text.text"

class FBF

    version: "1.0.0"

    new: (l, start_time = l.start_time, end_time = l.end_time) =>
        -- copys line
        @line = TABLE(l)\copy!
        -- set line times
        @lstart = start_time
        @lend = end_time
        @ldur = end_time - start_time
        -- converts time values in milliseconds to frames
        @sframe = aegisub.frame_from_ms start_time
        @eframe = aegisub.frame_from_ms end_time
        @dframe = @eframe - @sframe
        @iframe = -1 + aegisub.ms_from_frame 0
        @s, @e, @d = 0, end_time, end_time - start_time
        -- gets the transformation "t" through a time interval
        getTimeInInterval = (t1, t2, accel = 1, t) ->
            u = @s - @lstart
            if u < t1
                t = 0
            elseif u >= t2
                t = 1
            else
                t = (u - t1) ^ accel / (t2 - t1) ^ accel
            return t
        -- libass functions
        @util = {
            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L633
            transform: (...) ->
                args, t1, t2, accel = {...}, 0, @ldur, 1
                if #args == 3
                    {t1, t2, accel} = args
                elseif #args == 2
                    {t1, t2} = args
                elseif #args == 1
                    {accel} = args
                return getTimeInInterval t1, t2, accel

            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L452
            move: (x1, y1, x2, y2, t1, t2) ->
                if t1 and t2
                    if t1 > t2
                        t1, t2 = t2, t1
                else
                    t1, t2 = 0, 0
                if t1 <= 0 and t2 <= 0
                    t1, t2 = 0, @ldur
                t = getTimeInInterval t1, t2
                x = MATH\round (1 - t) * x1 + t * x2, 3
                y = MATH\round (1 - t) * y1 + t * y2, 3
                return x, y

            -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L585
            fade: (dec, ...) ->
                -- https://github.com/libass/libass/blob/0e0f9da2edc8eead93f9bf0ac4ef0336ad646ea7/libass/ass_parse.c#L196
                interpolate_alpha = (now, t1, t2, t3, t4, a1, a2, a3, a = a3) ->
                    if now < t1
                        a = a1
                    elseif now < t2
                        cf = (now - t1) / (t2 - t1)
                        a = a1 * (1 - cf) + a2 * cf
                    elseif now < t3
                        a = a2
                    elseif now < t4
                        cf = (now - t3) / (t4 - t3)
                        a = a2 * (1 - cf) + a3 * cf
                    return a
                args, a1, a2, a3, t1, t2, t3, t4 = {...}
                if #args == 2
                    -- 2-argument version (\fad, according to specs)
                    a1 = 255
                    a2 = 0
                    a3 = 255
                    t1 = 0
                    {t2, t3} = args
                    t4 = @ldur
                    t3 = t4 - t3
                elseif #args == 7
                    -- 7-argument version (\fade)
                    {a1, a2, a3, t1, t2, t3, t4} = args
                else
                    return ""
                return ass_alpha interpolate_alpha @s - @lstart, t1, t2, t3, t4, a1, dec or a2, a3
        }

    -- solves the transformations related to the \t tag
    solveTransformation: (tags) =>
        if tags\match "\\t%b()"
            split = TAGS\splitTags tags
            for tag in *split
                if tag.name == "t"
                    t = @util.transform tag.ts, tag.te, tag.ac
                    for trs in *tag.value
                        -- initial and final value
                        a, b = 0, trs.value
                        if fag = TAGS\tagsContainsTag split, trs.name
                            a = fag.value
                        unless trs.name == "clip" or trs.name == "iclip"
                            trs.value = UTIL\interpolation t, nil, a, b
                            if type(trs.value) == "number"
                                trs.value = MATH\round trs.value
                        else
                            -- if is a rectangular clip
                            if type(a) == "table" and type(b) == "table"
                                {a1, b1, c1, d1} = a
                                {a2, b2, c2, d2} = b
                                a3 = MATH\round UTIL\interpolation t, "number", a1, a2
                                b3 = MATH\round UTIL\interpolation t, "number", b1, b2
                                c3 = MATH\round UTIL\interpolation t, "number", c1, c2
                                d3 = MATH\round UTIL\interpolation t, "number", d1, d2
                                trs.value = {a3, b3, c3, d3}
                            else
                                -- if is a vector clip --> yes it works
                                trs.value = UTIL\interpolation t, nil, a, b
                    tags = TAGS\removeTag tags, tag.name, TAGS\remBarces tag.value.__tostring!
                    break
        return tags

    -- solves the transformations related to the \move tag
    solveMove: (tags) =>
        if tags\match "\\move%b()"
            for tag in *TAGS\splitTags tags
                if tag.name == "move"
                    px, py = @util.move unpack tag.value
                    tags = TAGS\removeTag tags, tag.name, "\\pos(#{px},#{py})"
                    break
        return tags

    -- solves the transformations related to the \fad or \fade tag
    solveFade: (tags, dec = 0) =>
        if tags\match "\\fade?%b()"
            for tag in *TAGS\splitTags tags
                if tag.name == "fad" or tag.name == "fade"
                    fade = @util.fade dec, unpack tag.value
                    tags = TAGS\removeTags tags, tag.name, {"alpha", "\\alpha#{fade}"}
                    break
        return tags

    -- performs all transformations on the frame
    perform: (subs, split) =>
        split = type(split) == "table" and split or TAGS\splitTextByTags split, false
        for i = 1, #split.tags
            tags, alpha = split.tags[i], nil
            -- performs \move tag transformation if \move is on the first tag layer
            if i == 1
                tags = @solveMove tags
            -- performs \t tag transformation one at a time
            while tags\match "\\t%b()"
                tags = @solveTransformation tags
            -- gets the alpha value contained in the frame and convert it to a number
            if alpha = TAGS\getTagInTags tags, "alpha"
                alpha = tonumber alpha\match("&?[hH](%x%x)&?"), 16
            -- performs \fad or \fade tag transformation
            tags = @solveFade tags, alpha
            -- removes style values ​​that are contained on the frame
            split.tags[i] = TAGS\clearStyleValues @line, tags, true
        -- removes equal values ​​that are contained on the frame
        return TAGS\clearEqualTags split.__tostring!

    -- iterate frame by frame
    iter: (step = 1) =>
        i = 0
        {:sframe, :eframe, :dframe, :iframe} = @
        ->
            i += (i == 0 and 1 or step)
            if i <= dframe -- i <= total frames
                add = i + step
                if add > dframe
                    while add > dframe + 1
                        add -= 1
                @s = iframe + aegisub.ms_from_frame sframe + i
                @e = iframe + aegisub.ms_from_frame sframe + add
                @d = @e - @s
                return @s, @e, @d, i, dframe

{:FBF}