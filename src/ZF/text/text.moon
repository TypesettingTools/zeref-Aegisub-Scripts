import MATH  from require "ZF.util.math"
import UTIL  from require "ZF.util.util"
import SHAPE from require "ZF.2D.shape"
import TABLE from require "ZF.util.table"
import TAGS  from require "ZF.text.tags"

class TEXT

    version: "1.0.0"

    -- @param subs userdata
    -- @param line table
    -- @param text string
    -- @param decs number
    new: (subs, line, text, decs = 2) =>
        @subs = subs
        @line = line
        @text = text or @line.text_stripped
        @decs = decs
        @style = @setStyle!

    -- @param line table
    -- @return table
    setStyle: (line = @line) =>
        with line.styleref
            @style = {
                .fontname
                .bold
                .italic
                .underline
                .strikeout
                .fontsize
                .scale_x / 100
                .scale_y / 100
                .spacing
            }
        return @style

    -- builds extensions, metrics and shape relative to the font and the text
    -- @param text string
    -- @return table, table, string
    buildFont: (text) =>
        font    = Yutils.decode.create_font unpack @style
        extents = font.text_extents text
        metrics = font.metrics!
        shape   = font.text_to_shape text
        return extents, metrics, shape\gsub " c", ""

    -- gets extensions, metrics and shape relative to the font and the text in a table
    -- @param text string
    -- @return table
    getFont: (text) =>
        extents, metrics, shape = @buildFont text
        return {
            :shape
            width:            tonumber extents.width
            height:           tonumber extents.height
            ascent:           tonumber metrics.ascent
            descent:          tonumber metrics.descent
            internal_leading: tonumber metrics.internal_leading
            external_leading: tonumber metrics.external_leading
        }

    -- gets values for all characters contained in the text
    -- @param an integer
    -- @return table
    chars: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        isTG = line.tags != nil
        decs = @decs

        chars, left = {n: 0}, line.left
        for c, char in Yutils.utf8.chars @text
            text                                     = char
            tags                                     = isTG and line.tags or ""
            text_stripped                            = text

            width, height, descent, ext_lead         = aegisub.text_extents line.styleref, text_stripped
            left                                     = MATH\round left, decs
            center                                   = MATH\round left + width / 2, decs
            right                                    = MATH\round left + width, decs
            top                                      = MATH\round line.top, decs
            middle                                   = MATH\round line.middle, decs
            bottom                                   = MATH\round line.bottom, decs

            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time

            x = switch an
                when 1, 4, 7 then left
                when 2, 5, 8 then isTG and center + line.offsetx or center
                when 3, 6, 9 then isTG and right + line.offsetx * 2 or right

            y = switch an
                when 7, 8, 9 then isTG and line.y or top
                when 4, 5, 6 then isTG and line.y or middle
                when 1, 2, 3 then isTG and line.y or bottom

            x = MATH\round x, decs
            y = MATH\round y, decs

            unless UTIL\isBlank text_stripped
                chars.n += 1
                chars[chars.n] = {
                    :text, :tags, :text_stripped, :width, :height, :descent, :ext_lead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration, i: chars.n
                }
            left = MATH\round left + width, decs
        return chars

    -- gets values for all words contained in the text
    -- @param an integer
    -- @return table
    words: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        isTG = line.tags != nil
        decs = @decs

        words, left, spaceW = {n: 0}, line.left, aegisub.text_extents line.styleref, " "
        for prevspace, word, postspace in @text\gmatch "(%s*)(%S+)(%s*)"
            text                                     = word
            tags                                     = isTG and line.tags or ""
            text_stripped                            = text

            prevspace                                = prevspace\len!
            postspace                                = postspace\len!

            width, height, descent, ext_lead         = aegisub.text_extents line.styleref, text_stripped
            left                                     = MATH\round left + prevspace * spaceW, decs
            center                                   = MATH\round left + width / 2, decs
            right                                    = MATH\round left + width, decs
            top                                      = MATH\round line.top, decs
            middle                                   = MATH\round line.middle, decs
            bottom                                   = MATH\round line.bottom, decs

            x = switch an
                when 1, 4, 7 then left
                when 2, 5, 8 then isTG and center + line.offsetx or center
                when 3, 6, 9 then isTG and right + line.offsetx * 2 or right

            y = switch an
                when 7, 8, 9 then isTG and line.y or top
                when 4, 5, 6 then isTG and line.y or middle
                when 1, 2, 3 then isTG and line.y or bottom

            x = MATH\round x, decs
            y = MATH\round y, decs

            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time

            words.n += 1
            words[words.n] = {
                :text, :tags, :text_stripped, :width, :height, :descent, :ext_lead
                :center, :left, :right, :top, :middle, :bottom, :x, :y
                :start_time, :end_time, :duration, i: words.n
            }
            left = MATH\round left + width + postspace * spaceW, decs
        return words

    -- gets values against all line breaks contained in the text
    -- @param an integer
    -- @return table
    breaks: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        temp = UTIL\splitBreaks @text
        decs = @decs

        breaks, left = {n: 0}, line.left
        breakv, extra = line.styleref.fontsize * line.styleref.scale_y / 100, 0
        for b, brk in ipairs temp
            text                                     = brk
            tags                                     = text\match("%b{}")\sub 2, -2
            text_stripped                            = text\gsub "%b{}", ""

            width, height, descent, ext_lead         = aegisub.text_extents line.styleref, text_stripped
            left                                     = MATH\round left, decs
            center                                   = MATH\round left + width / 2, decs
            right                                    = MATH\round left + width, decs
            top                                      = MATH\round line.top, decs
            middle                                   = MATH\round line.middle, decs
            bottom                                   = MATH\round line.bottom, decs

            text_stripped                            = text\gsub "%b{}", "", 1
            text_stripped_non_tags                   = text_stripped\gsub "%b{}", ""

            extra -= text_stripped == "" and breakv / 2 or 0

            x = switch an
                when 1, 4, 7 then line.left
                when 2, 5, 8 then line.center
                when 3, 6, 9 then line.right

            y = switch an
                when 7, 8, 9 then top + (b - 1) * breakv + extra
                when 4, 5, 6 then (middle - (#temp - 1) * breakv / 2) + (b - 1) * breakv + extra
                when 1, 2, 3 then bottom - ((#temp + 1 - b) - 1) * breakv + extra

            x = MATH\round x, decs
            y = MATH\round y, decs

            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time

            breaks.n += 1
            breaks[breaks.n] = {
                :text, :tags, :text_stripped, :text_stripped_non_tags, :width, :height, :descent, :ext_lead
                :center, :left, :right, :top, :middle, :bottom, :x, :y
                :start_time, :end_time, :duration
            }
            left = MATH\round left + width, decs
        -- fix empty line breaks
        fixed = {n: 0}
        for b, brk in ipairs breaks
            unless UTIL\isBlank brk
                brk.y = switch an
                    when 4, 5, 6 then brk.y - extra / 2
                    when 1, 2, 3 then brk.y - extra
                fixed.n += 1
                brk.i = fixed.n
                fixed[brk.i] = brk
        return fixed

    -- gets values against all tags contained in the text
    -- @param an integer
    -- @return table
    tags: (an = @line.styleref.align) =>
        index, decs = {n: 0}, @decs
        with UTIL\splitText @text
            left, offsetx, offsety = @line.left, 0, 0
            for i = 1, #.tags
                line = TABLE(@line)\copy!
                line.text = .tags[i] .. .text[i]

                line.prevspace = UTIL\fixText .text[i], "spaceL"
                line.postspace = UTIL\fixText .text[i], "spaceR"
                line.prevspace = line.prevspace\len!
                line.postspace = line.postspace\len!

                temp = UTIL\fixText .text[i], "both"
                line.text_stripped = temp\gsub("\\[nN]", "")\gsub "\\h", " "
                line.styleref = nil

                meta, styles = UTIL\tags2Styles @subs, line
                karaskel.preproc_line @subs, meta, styles, line
                spaceW = aegisub.text_extents line.styleref, " "

                line.text_stripped_non_tags = temp

                left                     += line.prevspace * spaceW
                index.n                  += 1
                index[index.n]           = line
                index[index.n].tags      = TAGS\remBarces .tags[i]
                index[index.n].left      = left
                index[index.n].center    = left + index[index.n].width / 2
                index[index.n].right     = left + index[index.n].width
                left                     += index[index.n].width + line.postspace * spaceW

                -- https://www.cairographics.org/tutorial/
                -- cairo_move_to (cr, i + 0.5 - te.x_bearing - te.width / 2, 0.5 - fe.descent + fe.height / 2);
                index[index.n].offsety = switch an
                    when 7, 8, 9 then 0.5 - line.descent + line.height
                    when 4, 5, 6 then 0.5 - line.descent + line.height / 2
                    when 1, 2, 3 then 0.5 - line.descent

                offsety = an > 3 and math.max(offsety, index[index.n].offsety) or math.min(offsety, index[index.n].offsety)

            -- Fixes values with respect to the X-axis and Y-axis
            offsetx = (@line.width - (left - @line.left)) / 2
            for t, tag in ipairs index
                tag.offsetx = offsetx

                tag.x = switch an
                    when 1, 4, 7 then tag.left
                    when 2, 5, 8 then tag.center + tag.offsetx
                    when 3, 6, 9 then tag.right + tag.offsetx * 2

                tag.y = switch an
                    when 7, 8, 9 then tag.top - tag.offsety + offsety
                    when 4, 5, 6 then tag.middle - tag.offsety + offsety
                    when 1, 2, 3 then tag.bottom - tag.offsety + offsety

                tag.x = MATH\round tag.x, decs
                tag.y = MATH\round tag.y, decs

                tag.offsetyF = offsety
        return index

    -- organize positioning in tags
    -- @param coords table
    -- @param tag table
    -- @param line table
    -- @return table, table
    orgPos: (coords, tag, line) =>
        local vx, vy, isMove, x1, y1, x2, y2
        with coords
            vx, vy, isMove = if .move.x2 then .move.x1, .move.y1, true else .pos.x, .pos.y

        lx = switch line.styleref.align
            when 1, 4, 7 then line.left
            when 2, 5, 8 then line.center
            when 3, 6, 9 then line.right

        ly = switch line.styleref.align
            when 7, 8, 9 then line.top
            when 4, 5, 6 then line.middle
            when 1, 2, 3 then line.bottom

        fr = tag.tags\match "\\fr[xyz]*%-?%d[%.%d]*"
        x1, y1 = tag.x - lx + vx, tag.y - ly + vy
        if isMove
            x2, y2 = tag.x - lx + coords.move.x2, tag.y - ly + coords.move.y2

        pos = isMove and {x1, y1, x2, y2, coords.move.ts, coords.move.te} or {x1, y1}
        org = fr and {coords.org.x, coords.org.y} or {}
        return pos, org

    -- converts a text to shape
    -- @param an integer
    -- @param px number
    -- @param py number
    -- @return table
    toShape: (an = @line.styleref.align, px = 0, py = 0) =>
        breaks = @breaks!

        breaks.clip = ""
        for b, brk in ipairs breaks
            font = @getFont brk.text_stripped_non_tags
            brk.shape = font.shape
            shape = SHAPE font.shape

            temp = switch an
                when 1, 4, 7 then shape\move px
                when 2, 5, 8 then shape\move px - font.width / 2
                when 3, 6, 9 then shape\move px - font.width

            temp = switch an
                when 7, 8, 9 then temp\move 0, py + brk.y - brk.top
                when 4, 5, 6 then temp\move 0, py + brk.y - brk.middle - font.height / 2
                when 1, 2, 3 then temp\move 0, py + brk.y - brk.bottom - font.height

            brk.clip = temp\build!
            breaks.clip ..= brk.clip

        breaks.shape = SHAPE(breaks.clip)\setPosition(an, "ucp", px, py)\build!
        return breaks

{:TEXT}