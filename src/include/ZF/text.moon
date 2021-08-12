-- load external libs
import MATH  from require "ZF.math"
import UTIL  from require "ZF.util"
import SHAPE from require "ZF.shape"
import TABLE from require "ZF.table"

class TEXT

    new: (subs, line, text, dec = 2) =>
        @subs = subs
        @line = line
        @text = text or @line.text_stripped
        @dec = dec

    -- converts a text to shape
    to_shape: =>
        with {text: {}, shape: {}, w: {}, h: {}}
            while @text != ""
                c, d = UTIL\headtail(@text, "\\N")
                .text[#.text + 1] = c\match("^%s*(.-)%s*$")
                @text = d
            style = {
                @line.styleref.fontname
                @line.styleref.bold
                @line.styleref.italic
                @line.styleref.underline
                @line.styleref.strikeout
                @line.styleref.fontsize
                @line.styleref.scale_x / 100
                @line.styleref.scale_y / 100
                @line.styleref.spacing
            }
            for k = 1, #.text
                font = Yutils.decode.create_font unpack(style)
                extents = font.text_extents .text[k]
                .shape[k] = font.text_to_shape(.text[k])\gsub(" c", "")
                .shape[k] = SHAPE(.shape[k])\displace(0, (k - 1) * style[6] * style[8])\build!
                .w[k], .h[k] = tonumber(extents.width), tonumber(extents.height)

    -- converts a text to clip
    to_clip: (an = @line.styleref.align, px = 0, py = 0) =>
        val = @to_shape!
        break_line, extra = (@line.styleref.fontsize * @line.styleref.scale_y / 100), 0
        with val
            for k = 1, #.shape
                if .text[k] == ""
                    py -= break_line / 2
                    extra -= break_line / 2
                .shape[k] = SHAPE(.shape[k])
                .shape[k] = switch an
                    when 1 then .shape[k]\displace(px, py - .h[k] - break_line * (#.shape - 1))
                    when 2 then .shape[k]\displace(px - .w[k] / 2, py - .h[k] - break_line * (#.shape - 1))
                    when 3 then .shape[k]\displace(px - .w[k], py - .h[k] - break_line * (#.shape - 1))
                    when 4 then .shape[k]\displace(px, py - .h[k] / 2 - break_line * (#.shape - 1) / 2)
                    when 5 then .shape[k]\displace(px - .w[k] / 2, (py - .h[k] / 2 - break_line * (#.shape - 1) / 2))
                    when 6 then .shape[k]\displace(px - .w[k], py - .h[k] / 2 - break_line * (#.shape - 1) / 2)
                    when 7 then .shape[k]\displace(px, py)
                    when 8 then .shape[k]\displace(px - .w[k] / 2, py)
                    when 9 then .shape[k]\displace(px - .w[k], py)
                .shape[k] = .shape[k]\build!
            new_shape = SHAPE table.concat(.shape)
            new_shape = switch an
                when 1, 2, 3 then new_shape\displace(0, -extra)\build!
                when 4, 5, 6 then new_shape\displace(0, -extra / 2)\build!
            return new_shape

    -- organize positioning in tags
    org_pos: (coord, tag, line) =>
        ox, oy, vx, vy = coord.org.x, coord.org.y, coord.pos.x, coord.pos.y
        tx, ty, lx, ly = switch tag.styleref.align
            when 1 then tag.left,   tag.bottom, line.left,   line.bottom
            when 2 then tag.center, tag.bottom, line.center, line.bottom
            when 3 then tag.right,  tag.bottom, line.right,  line.bottom
            when 4 then tag.left,   tag.middle, line.left,   line.middle
            when 5 then tag.center, tag.middle, line.center, line.middle
            when 6 then tag.right,  tag.middle, line.right,  line.middle
            when 7 then tag.left,   tag.top,    line.left,   line.top
            when 8 then tag.center, tag.top,    line.center, line.top
            when 9 then tag.right,  tag.top,    line.right,  line.top
        frz = tag.tags\match "\\frz?%-?%d[%.%d]*"
        frx = tag.tags\match "\\frx%-?%d[%.%d]*"
        fry = tag.tags\match "\\fry%-?%d[%.%d]*"
        org = (frz or frx or fry) and "\\org(#{ox},#{oy})" or ""
        return MATH\round(tx - lx + vx), MATH\round(ty - ly + vy), org

    -- gets character information from a text
    chars: =>
        line = TABLE(@line)\copy!
        chars, left = {n: 0}, line.left
        for c, char in Yutils.utf8.chars @text
            text                                     = char
            text_stripped                            = text
            width, height, descent, ext_lead         = aegisub.text_extents(line.styleref, text_stripped)
            left                                     = MATH\round(left, @dec)
            center                                   = MATH\round(left + width / 2, @dec)
            right                                    = MATH\round(left + width, @dec)
            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time
            if text_stripped != " "
                -- adds values in table
                chars.n += 1
                chars[chars.n] = {
                    :text, :text_stripped, :width, :descent, :ext_lead
                    :center, :left, :right, :start_time, :end_time, :duration
                }
            left += width
        return chars

    -- gets words information from a text
    words: =>
        line = TABLE(@line)\copy!
        words, left, space_width = {n: 0}, line.left, aegisub.text_extents(line.styleref, " ")
        for prev_space, word, post_space in @text\gmatch "(%s*)(%S+)(%s*)"
            text                                     = word
            text_stripped                            = text
            prev_space                               = prev_space\len!
            post_space                               = post_space\len!
            width, height, descent, ext_lead         = aegisub.text_extents(line.styleref, text_stripped)
            left                                     += prev_space * space_width
            center                                   = MATH\round(left + width / 2, @dec)
            right                                    = MATH\round(left + width, @dec)
            start_time                               = line.start_time
            end_time                                 = line.end_time
            duration                                 = end_time - start_time
            -- adds values in table
            words.n += 1
            words[words.n] = {
                :text, :text_stripped, :width, :descent, :ext_lead
                :center, :left, :right, :start_time, :end_time, :duration
            }
            left += width + post_space * space_width
        return words

    -- gets information from each tag layer
    tags: =>
        tags = {}
        with UTIL\split_text @text
            left = @line.left
            for k = 1, #.tags
                line = TABLE(@line)\copy!
                -- configures the new line
                line.tags = .tags[k]\gsub("\\t%b()", "")
                line.text = line.tags .. .text[k]\match("^%s*(.-)%s*$")
                line.prevspace, line.postspace = .text[k]\match("^(%s*).-(%s*)$")
                line.prevspace, line.postspace = line.prevspace\len!, line.postspace\len!
                line.text_stripped = .text[k]\match("^%s*(.-)%s*$")
                line.styleref = nil
                --
                meta, styles = UTIL\tags2styles(@subs, line)
                karaskel.preproc_line(@subs, meta, styles, line)
                coords = UTIL\find_coords(line, meta)
                space_width = aegisub.text_extents(line.styleref, " ")
                --
                left           += line.prevspace * space_width
                tags[k]        = line
                tags[k].tags   = .tags[k]
                tags[k].left   = left
                tags[k].center = left + tags[k].width / 2
                tags[k].right  = left + tags[k].width
                left           += tags[k].width + line.postspace * space_width
            -- fix values with respect to the X-axis
            offset = (@line.width - (left - @line.left)) / 2
            for t, tag in ipairs tags
                tag.left   += offset
                tag.center += offset
                tag.right  += offset
                -- adds chars and words infos to the tag values
                @line      = tag
                @text      = tag.text_stripped
                tag.chars  = @chars!
                tag.words  = @words!
            return tags

{:TEXT}