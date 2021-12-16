import MATH  from require "ZF.util.math"
import UTIL  from require "ZF.util.util"
import SHAPE from require "ZF.2D.shape"
import TABLE from require "ZF.util.table"
import TAGS  from require "ZF.text.tags"

class TEXT

    new: (subs, line, text, decs = 2) =>
        @subs = subs
        @line = line
        @text = text or @line.text_stripped
        @decs = decs
        @style = @setStyle!

    -- sets some elements of the class
    setSubs: (@subs = subs) => @subs = subs
    setLine: (line = @line) => @line = line
    setText: (text = @text) => @text = text
    setDecs: (decs = @decs) => @decs = decs
    setStyle: (line = @line) =>
        with line
            @style = {
                .styleref.fontname
                .styleref.bold
                .styleref.italic
                .styleref.underline
                .styleref.strikeout
                .styleref.fontsize
                .styleref.scale_x / 100
                .styleref.scale_y / 100
                .styleref.spacing
            }
        return @style

    -- builds extensions, metrics and shape relative to the font and the text
    buildFont: (text) =>
        font    = Yutils.decode.create_font unpack(@style)
        extents = font.text_extents text
        metrics = font.metrics!
        shape   = font.text_to_shape text
        return extents, metrics, shape\gsub " c", ""

    -- gets extensions, metrics and shape relative to the font and the text in a table
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
    chars: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        isTG = line.tags != nil

        chars, left = {n: 0}, line.left
        for c, char in Yutils.utf8.chars @text
            text                                     = char
            tags                                     = isTG and line.tags or ""
            text_stripped                            = text

            width, height, descent, ext_lead         = aegisub.text_extents line.styleref, text_stripped
            left                                     = MATH\round(left, @decs)
            center                                   = MATH\round(left + width / 2, @decs)
            right                                    = MATH\round(left + width, @decs)
            top                                      = MATH\round(line.top, @decs)
            middle                                   = MATH\round(line.middle, @decs)
            bottom                                   = MATH\round(line.bottom, @decs)

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

            x, y = MATH\round(x, @decs), MATH\round(y, @decs)

            unless UTIL\isBlank text_stripped
                chars.n += 1
                chars[chars.n] = {
                    :text, :tags, :text_stripped, :width, :height, :descent, :ext_lead
                    :center, :left, :right, :top, :middle, :bottom, :x, :y
                    :start_time, :end_time, :duration
                }
            left = MATH\round(left + width, @decs)
        return chars

    -- gets values for all words contained in the text
    words: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        isTG = line.tags != nil

        words, left, spaceW = {n: 0}, line.left, aegisub.text_extents(line.styleref, " ")
        for prevspace, word, postspace in @text\gmatch "(%s*)(%S+)(%s*)"
            text                                     = word
            tags                                     = isTG and line.tags or ""
            text_stripped                            = text

            prevspace                                = prevspace\len!
            postspace                                = postspace\len!

            width, height, descent, ext_lead         = aegisub.text_extents(line.styleref, text_stripped)
            left                                     = MATH\round(left + prevspace * spaceW, @decs)
            center                                   = MATH\round(left + width / 2, @decs)
            right                                    = MATH\round(left + width, @decs)
            top                                      = MATH\round(line.top, @decs)
            middle                                   = MATH\round(line.middle, @decs)
            bottom                                   = MATH\round(line.bottom, @decs)

            x = switch an
                when 1, 4, 7 then left
                when 2, 5, 8 then isTG and center + line.offsetx or center
                when 3, 6, 9 then isTG and right + line.offsetx * 2 or right

            y = switch an
                when 7, 8, 9 then isTG and top - line.offsety + line.offsetyF or top
                when 4, 5, 6 then isTG and middle - line.offsety + line.offsetyF or middle
                when 1, 2, 3 then isTG and bottom - line.offsety + line.offsetyF or bottom

            x, y = MATH\round(x, @decs), MATH\round(y, @decs)

            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time

            words.n += 1
            words[words.n] = {
                :text, :tags, :text_stripped, :width, :height, :descent, :ext_lead
                :center, :left, :right, :top, :middle, :bottom, :x, :y
                :start_time, :end_time, :duration
            }
            left = MATH\round(left + width + postspace * spaceW, @decs)
        return words

    -- gets values against all line breaks contained in the text
    breaks: (an = @line.styleref.align) =>
        line = TABLE(@line)\copy!
        temp = UTIL\splitBreaks @text

        breaks, left = {n: 0}, line.left
        breakv, extra = line.styleref.fontsize * line.styleref.scale_y / 100, 0
        for b, brk in ipairs temp
            text                                     = brk
            tags                                     = text\match("%b{}")\sub 2, -2
            text_stripped                            = text\gsub "%b{}", ""

            width, height, descent, ext_lead         = aegisub.text_extents line.styleref, text_stripped
            left                                     = MATH\round(left, @decs)
            center                                   = MATH\round(left + width / 2, @decs)
            right                                    = MATH\round(left + width, @decs)
            top                                      = MATH\round(line.top, @decs)
            middle                                   = MATH\round(line.middle, @decs)
            bottom                                   = MATH\round(line.bottom, @decs)

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

            x, y = MATH\round(x, @decs), MATH\round(y, @decs)

            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time

            breaks.n += 1
            breaks[breaks.n] = {
                :text, :tags, :text_stripped, :text_stripped_non_tags, :width, :height, :descent, :ext_lead
                :center, :left, :right, :top, :middle, :bottom, :x, :y
                :start_time, :end_time, :duration
            }
            left = MATH\round(left + width, @decs)
        -- fix empty line breaks
        fixed = {n: 0}
        for b, brk in ipairs breaks
            continue if UTIL\isBlank brk

            brk.y = switch an
                when 4, 5, 6 then brk.y - extra / 2
                when 1, 2, 3 then brk.y - extra

            fixed.n += 1
            fixed[fixed.n] = brk
        return fixed

    -- gets values against all tags contained in the text
    tags: (an = @line.styleref.align) =>
        index = {n: 0}
        with UTIL\splitText @text
            left, offsetx, offsety = @line.left, 0, 0
            for k = 1, #.tags
                line = TABLE(@line)\copy!
                line.text = .tags[k] .. .text[k]

                line.prevspace = UTIL\fixText .text[k], "spaceL"
                line.postspace = UTIL\fixText .text[k], "spaceR"
                line.prevspace = line.prevspace\len!
                line.postspace = line.postspace\len!

                temp = UTIL\fixText .text[k], "both"
                line.text_stripped = temp\gsub("\\[nN]", "")\gsub "\\h", " "
                line.styleref = nil

                meta, styles = UTIL\tags2Styles @subs, line
                karaskel.preproc_line @subs, meta, styles, line
                spaceW = aegisub.text_extents line.styleref, " "

                line.text_stripped_non_tags = temp

                left                     += line.prevspace * spaceW
                index.n                  += 1
                index[index.n]           = line
                index[index.n].tags      = TAGS\remBarces .tags[k]
                index[index.n].left      = left
                index[index.n].center    = left + index[index.n].width / 2
                index[index.n].right     = left + index[index.n].width
                left                     += index[index.n].width + line.postspace * spaceW

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

                tag.x, tag.y = MATH\round(tag.x, @decs), MATH\round(tag.y, @decs)

                tag.offsetyF = offsety
        return index

    -- organize positioning in tags
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

        breaks.shape = SHAPE(breaks.clip)\displace(an, "ucp", px, py)\build!
        return breaks

{:TEXT}