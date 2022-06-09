import MATH  from require "ZF.util.math"
import UTIL  from require "ZF.util.util"
import SHAPE from require "ZF.2D.shape"
import TABLE from require "ZF.util.table"
import TAGS  from require "ZF.text.tags"

class TEXT

    version: "1.3.5"

    -- @param subs userdata
    -- @param line table
    -- @param text string
    -- @param decs number
    new: (subs, line, text) =>
        @subs = subs
        @line = line
        @text = text or @line.text
        @text_stripped = text or @line.text_stripped
        @coords, @meta, @styles, @old_styles = @preprocLine!

    -- @param line table
    -- @return table
    setStyle: (line = @line) =>
        if line.styleref
            with line.styleref
                @style = {.fontname, .bold, .italic, .underline, .strikeout, .fontsize, .scale_x / 100, .scale_y / 100, .spacing}
        else
            error "missing style values"
        return @style

    -- builds extensions, metrics and shape relative to the font and the text
    -- @param text string
    -- @return table, table, string
    buildFont: (text) =>
        font    = Yutils.decode.create_font unpack @style
        shape   = font.text_to_shape(text)\gsub " c", ""
        extents = font.text_extents text
        metrics = font.metrics!
        return shape, extents, metrics

    -- gets extensions, metrics and shape relative to the font and the text in a table
    -- @param text string
    -- @return table
    getFont: (text) =>
        shape, extents, metrics = @buildFont text
        return {
            :shape
            width:            tonumber extents.width
            height:           tonumber extents.height
            ascent:           tonumber metrics.ascent
            descent:          tonumber metrics.descent
            internal_leading: tonumber metrics.internal_leading
            external_leading: tonumber metrics.external_leading
        }

    -- sets additional information for the line
    -- @param line table
    -- @param findCoords boolean
    preprocLine: (line = @line, findCoords = true) =>
        meta, styles, old_styles = TAGS\toStyle @subs, line

        -- sets text and tags
        line.text = line.text and line.text or TAGS\blankText line.text
        line.tags = line.tags and line.tags or line.text\match "%b{}"
        line.text_stripped = line.text_stripped and line.text_stripped or line.text\gsub("%b{}", "")\gsub("\\h", " ")
	    line.duration = line.end_time - line.start_time

        -- sets style references
        if style = styles[line.style]
            line.styleref = style
        else
            aegisub.debug.out 2, "WARNING: Style not found: #{line.style}\n"
            line.styleref = styles[1]

        -- sets style references
        if style = old_styles[line.style]
            line.styleref_old = style
        else
            aegisub.debug.out 2, "WARNING: Style not found: #{line.style}\n"
            line.styleref_old = styles[1]

        -- gets align
        align = line.styleref.align

        -- adds the metric values to the line
        line.width, line.height, line.descent, line.extlead = aegisub.text_extents line.styleref, line.text_stripped
        line.space_width = aegisub.text_extents line.styleref, " "

        -- fixes the width value
        line.width *= meta.video_x_correct_factor
        line.space_width *= meta.video_x_correct_factor

        -- effective margins
        line.margin_v = line.margin_t
        line.eff_margin_l = line.margin_l > 0 and line.margin_l or line.styleref.margin_l
        line.eff_margin_r = line.margin_r > 0 and line.margin_r or line.styleref.margin_r
        line.eff_margin_t = line.margin_t > 0 and line.margin_t or line.styleref.margin_t
        line.eff_margin_b = line.margin_b > 0 and line.margin_b or line.styleref.margin_b
        line.eff_margin_v = line.margin_v > 0 and line.margin_v or line.styleref.margin_v

        switch align
            when 1, 4, 7
                -- Left aligned
                line.left = line.eff_margin_l
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.left
            when 2, 5, 8
                -- Centered aligned
                line.left = (meta.res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.center
            when 3, 6, 9
                -- Right aligned
                line.left = meta.res_x - line.eff_margin_r - line.width
                line.center = line.left + line.width / 2
                line.right = line.left + line.width
                line.x = line.right

        switch align
            when 7, 8, 9
                -- Top aligned
                line.top = line.eff_margin_t
                line.middle = line.top + line.height / 2
                line.bottom = line.top + line.height
                line.y = line.top
            when 4, 5, 6
                -- Mid aligned
                line.top = (meta.res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
                line.middle = line.top + line.height / 2
                line.bottom = line.top + line.height
                line.y = line.middle
            when 1, 2, 3
                -- Bottom aligned
                line.bottom = meta.res_y - line.eff_margin_b
                line.middle = line.bottom - line.height / 2
                line.top = line.bottom - line.height
                line.y = line.bottom

        line.meta = meta
        if findCoords
            return TAGS\findCoords(line, meta), meta, styles, old_styles

        return meta, styles, old_styles

    -- gets a new line for each tag division and calculates the new position values
    -- @param line table
    -- @param text string
    -- @param noblank boolean
    -- @return table
    tags2Lines: (line = @line, text = line.text, noblank = true) =>
        split = TAGS\splitTextByTags text
        data = {n: #split.tags, text: "", left: 0, width: 0, height: 0, offsety: 0, breaky: 0}
        for i = 1, data.n
            tag = split.tags[i]
            txt = split.text[i]

            -- removes hard spaces
            txt = txt\gsub "\\h", " "

            -- copies the table to new settings
            l = TABLE(line)\copy!
            l.isTags = true

            -- number of blanks at the beginning and the end
            l.prevspace = TAGS\blankText(txt, "spaceL")\len!
            l.postspace = TAGS\blankText(txt, "spaceR")\len!

            -- removes the blanks from the beginning and the end
            txt = TAGS\blankText txt

            -- sets text and tags values
            l.text = tag .. txt
            l.tags = tag
            l.text_stripped = txt

            -- sets preprocline
            @preprocLine l, false
            align, offsety = l.styleref.align

            -- calculates the value of the previous blank
            prevspace = l.prevspace * l.space_width
            data.left += prevspace

            switch align
                when 1, 4, 7
                    -- Left aligned
                    l.offsetx = 0
                    l.left = data.left + l.eff_margin_l
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width
                when 2, 5, 8
                    -- Centered aligned
                    l.offsetx = (@meta.res_x - l.eff_margin_l - l.eff_margin_r) / 2 + l.eff_margin_l
                    l.left = data.left
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width
                when 3, 6, 9
                    -- Right aligned
                    l.offsetx = @meta.res_x - l.eff_margin_r
                	l.left = data.left
                    l.center = l.left + l.width / 2
                    l.right = l.left + l.width

            switch align
                when 7, 8, 9
                    -- Top aligned
                    l.offsety = 0.5 - l.descent + l.height
                    l.top = l.eff_margin_t
                    l.middle = l.top + l.height / 2
                    l.bottom = l.top + l.height
                when 4, 5, 6
                    -- Mid aligned
                    l.offsety = 0.5 - l.descent + l.height / 2
                    l.top = (@meta.res_y - l.eff_margin_t - l.eff_margin_b - l.height) / 2 + l.eff_margin_t
                    l.middle = l.top + l.height / 2
                    l.bottom = l.top + l.height
                when 1, 2, 3
                    -- Bottom aligned
                    l.offsety = 0.5 - l.descent
                    l.bottom = @meta.res_y - l.eff_margin_b
                    l.middle = l.bottom - l.height / 2
                    l.top = l.bottom - l.height

            -- calculates the value of the next blank
            postspace = l.postspace * l.space_width
            data.left += l.width + postspace

            -- adds the text from tag
            data.text ..= l.text_stripped

            -- recalculates the metrics of the fonts according to the largest one for the respective settings
            data.width  += l.width + prevspace + postspace
            data.height  = math.max data.height, l.height
            data.descent = not data.descent and l.descent or math.max data.descent, l.descent
            data.extlead = not data.extlead and l.extlead or math.max data.extlead, l.extlead
            data.breaky  = math.max data.breaky, l.styleref.fontsize * l.styleref.scale_y / 100

            -- recalculates the value of the height difference to obtain the optimal value for the positioning return
            data.offsety = align > 3 and math.max(data.offsety, l.offsety) or math.min(data.offsety, l.offsety)
            data[i] = l

        {:width, :offsety} = data
        for i = 1, data.n
            l = data[i]

            -- fixes the problem regarding text width in different tag layers
            switch l.styleref.align
                when 1, 4, 7
                    l.x = l.left
                when 2, 5, 8
                    l.offsetx -= width / 2
                    l.center += l.offsetx
                    l.x = l.center
                when 3, 6, 9
                    l.offsetx -= width
                    l.right += l.offsetx
                    l.x = l.right

            -- fixes the problem regarding text height in different tag layers
            l.offsety = offsety - l.offsety
            switch l.styleref.align
                when 7, 8, 9
                    l.top += l.offsety
                    l.y = l.top
                when 4, 5, 6
                    l.middle += l.offsety
                    l.y = l.middle
                when 1, 2, 3
                    l.bottom += l.offsety
                    l.y = l.bottom

            -- not implemented
            -- if noblank and l.text != ""

        return data

    -- gets a new line for each line break and calculates the new position values
    -- @param line table
    -- @param text string
    -- @param noblank boolean
    -- @return table
    breaks2Lines: (line = @line, text = line.text, noblank = true) =>
        split = TAGS\splitTextByBreaks text
        slen, data, add = #split, {n: 0}, {n: {sum: 0}, r: {sum: 0}}

        -- gets the tag data values for each line break
        temp = [@tags2Lines line, split[i] for i = 1, slen]

        -- gets the offset for each line break
        for i = 1, slen
            -- adds normal
            {:text, :breaky} = temp[i]
            add.n[i] = add.n.sum
            add.n.sum += text == "" and breaky / 2 or breaky
            -- adds reverse
            j = slen - i + 1
            {:text, :breaky} = temp[j]
            add.r[j] = add.r.sum
            add.r.sum += text == "" and breaky / 2 or breaky

        -- repositions the Y-axis on the tag data
        for i = 1, slen
            brk = temp[i]
            for j = 1, brk.n
                tag = brk[j]
                tag.y = switch line.styleref.align
                    when 7, 8, 9 then tag.y + add.n[i]
                    when 4, 5, 6 then tag.y + (add.n[i] - add.r[i]) / 2
                    when 1, 2, 3 then tag.y - add.r[i]
            -- add only when it is not a blank
            if noblank and brk.text != ""
                data.n += 1
                data[data.n] = brk

        return data

    -- gets values for all characters contained in the text
    -- @param an integer
    -- @return table
    chars: (line = @line, noblank = true) =>
        {:tags, :styleref, :start_time, :end_time, :duration, :isTags} = line
        chars, left, align = {n: 0}, line.left, styleref.align
        for c, char in Yutils.utf8.chars line.text_stripped
            text = char
            text_stripped = char

            width, height, descent, extlead = aegisub.text_extents styleref, text_stripped
            center                          = left + width / 2
            right                           = left + width
            top                             = line.top
            middle                          = line.middle
            bottom                          = line.bottom

            addx = isTags and line.offsetx or 0
            x = switch align
                when 1, 4, 7 then left
                when 2, 5, 8 then center + addx
                when 3, 6, 9 then right + addx

            addy = isTags and line.y or nil
            y = switch align
                when 7, 8, 9 then addy or top
                when 4, 5, 6 then addy or middle
                when 1, 2, 3 then addy or bottom

            unless noblank and UTIL\isBlank text_stripped
                chars.n += 1
                chars[chars.n] = {
                    i: chars.n
                    :text, :tags, :text_stripped
                    :width, :height, :descent, :extlead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration
                }

            left += width
        return chars

    -- gets values for all characters contained in the text
    -- @param an integer
    -- @return table
    words: (line = @line, noblank = true) =>
        {:tags, :styleref, :space_width, :start_time, :end_time, :duration, :isTags} = line
        words, left, align = {n: 0}, line.left, styleref.align
        for prevspace, word, postspace in line.text_stripped\gmatch "(%s*)(%S+)(%s*)"
            text = word
            text_stripped = word

            prevspace                       = prevspace\len!
            postspace                       = postspace\len!

            width, height, descent, extlead = aegisub.text_extents styleref, text_stripped
            left                           += prevspace * space_width
            center                          = left + width / 2
            right                           = left + width
            top                             = line.top
            middle                          = line.middle
            bottom                          = line.bottom

            addx = isTags and line.offsetx or 0
            x = switch align
                when 1, 4, 7 then left
                when 2, 5, 8 then center + addx
                when 3, 6, 9 then right + addx

            addy = isTags and line.y or nil
            y = switch align
                when 7, 8, 9 then addy or top
                when 4, 5, 6 then addy or middle
                when 1, 2, 3 then addy or bottom

            unless noblank and UTIL\isBlank text_stripped
                words.n += 1
                words[words.n] = {
                    i: words.n
                    :text, :tags, :text_stripped
                    :width, :height, :descent, :extlead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration
                }

            left += width + postspace * space_width
        return words

    -- gets the correct \org and \pos tag values according to the coordinate values
    -- @param line table
    -- @param tag table
    -- @param coords table
    -- @return table, table
    orgPos: (line, tag, coords) =>
        local vx, vy, x1, y1, x2, y2, isMove
        with coords
            vx, vy, isMove = if .move[3] then .move[1], .move[2], true else .pos[1], .pos[2]
        x1 = MATH\round tag.x - line.x + vx
        y1 = MATH\round tag.y - line.y + vy
        pos = {x1, y1}
        if isMove
            x2 = MATH\round tag.x - line.x + coords.move[3]
            y2 = MATH\round tag.y - line.y + coords.move[4]
            pos = {x1, y1, x2, y2, coords.move[5], coords.move[6]}
        return pos, (tag.tags\match("\\fr[xyz]*[%-%.%d]*") or line.styleref.angle != 0) and coords.org or nil

    -- converts a text to shape
    -- @param an integer
    -- @param px number
    -- @param py number
    -- @return table
    toShape: (align = @line.styleref.align, px = 0, py = 0) =>
        {:left, :center, :rigth, :top, :middle, :bottom} = @line
        clip, breaks = {}, @breaks2Lines!
        for b, brk in ipairs breaks
            clip[b] = ""
            for t, tag in ipairs brk
                @setStyle tag
                {:shape, :width, :height} = @getFont tag.text_stripped
                shape = SHAPE shape
                temp = switch align
                    when 1, 4, 7 then shape\move px + tag.x - left
                    when 2, 5, 8 then shape\move px + tag.x - center - width / 2
                    when 3, 6, 9 then shape\move px + tag.x - rigth - width
                temp = switch align
                    when 7, 8, 9 then temp\move 0, py + tag.y - top
                    when 4, 5, 6 then temp\move 0, py + tag.y - middle - height / 2
                    when 1, 2, 3 then temp\move 0, py + tag.y - bottom - height
                clip[b] ..= temp\build!
        clip = table.concat clip
        shape = SHAPE(clip)\setPosition(align, "ucp", px, py)\build!
        return shape, clip

{:TEXT}