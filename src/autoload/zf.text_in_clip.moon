export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "0.0.3"
-- LIB
zf = require "ZF.main"

class PyointaBezier

    new: (line, shape, char_x, char_y, mode, offset = 0) =>
        l_width, l_left = line.width, line.left
        pos_Bezier, vec_Bezier, paths, PtNo = {}, {}, {}, {}
        nN, Blength, lineoffset = 8, 0, 0
        paths = @getCoords(shape)
        for m in *paths
            for p in *m
                Blength += @getBezierLength(p, 0, 1, nN)
        lineoffset = switch mode
            when 2 then offset
            when 3 then (Blength - l_width) - offset
            when 4 then (Blength - l_width) * offset
            when 5 then (Blength - l_width) * (1 - offset)
            else        (Blength - l_width) / 2 + offset
        targetLength, angle = 0, 0
        PtNo, targetLength = @length2PtNo(paths, lineoffset + char_x - l_left, nN)
        if PtNo != false
            tb = @length2t(PtNo, targetLength, nN)
            if tb != false
                pos_Bezier = @getBezierPos(PtNo, tb)
                vec_Bezier = @normal2P(PtNo, tb)
                angle = -math.deg(math.atan2(vec_Bezier[2], vec_Bezier[1])) - 90
        else
            pos_Bezier[1] = char_x
            pos_Bezier[2] = char_y
        @out = "\\pos(#{zf.math\round(pos_Bezier[1])},#{zf.math\round(pos_Bezier[2])})\\fr#{zf.math\round(angle < -180 and angle + 360 or angle)}"

    tangential2P: (Pnts, t_) =>
        tanVec, XY = {}, @difference(Pnts)
        dpos = @tDifferential(XY, t_)
        for i = 1, 2
            tanVec[i] = dpos[2][i] / math.sqrt(dpos[2][1] ^ 2 + dpos[2][2] ^ 2)
        return tanVec

    normal2P: (Pnts, t_) =>
        normalVec = @tangential2P(Pnts, t_)
        normalVec[1], normalVec[2] = normalVec[2], -normalVec[1]
        return normalVec

    difference: (Pnts) =>
        DVec = {}
        DVec[1] = {Pnts[2][1] - Pnts[1][1], Pnts[2][2] - Pnts[1][2]}
        DVec[2] = {Pnts[3][1] - Pnts[2][1], Pnts[3][2] - Pnts[2][2]}
        DVec[3] = {Pnts[4][1] - Pnts[3][1], Pnts[4][2] - Pnts[3][2]}
        DVec[4] = {DVec[2][1] - DVec[1][1], DVec[2][2] - DVec[1][2]}
        DVec[5] = {DVec[3][1] - DVec[2][1], DVec[3][2] - DVec[2][2]}
        DVec[6] = {DVec[5][1] - DVec[4][1], DVec[5][2] - DVec[4][2]}
        {
            {Pnts[1][1], Pnts[1][2]}
            {DVec[1][1], DVec[1][2]}
            {DVec[4][1], DVec[4][2]}
            {DVec[6][1], DVec[6][2]}
        }

    tDifferential: (XY, ta) =>
        {
            {XY[4][1] * ta ^ 3 + 3 * XY[3][1] * ta ^ 2 + 3 * XY[2][1] * ta + XY[1][1], XY[4][2] * ta ^ 3 + 3 * XY[3][2] * ta ^ 2 + 3 * XY[2][2] * ta + XY[1][2]}
            {3 * (XY[4][1] * ta ^ 2 + 2 * XY[3][1] * ta + XY[2][1]), 3 * (XY[4][2] * ta ^ 2 + 2 * XY[3][2] * ta + XY[2][2])}
            {6 * (XY[4][1] * ta + XY[3][1]), 6 * (XY[4][2] * ta + XY[3][2])}
        }

    getBezierLength: (p, ta, tb, nN) =>
        t_, XY = {}, @difference(p)
        for i = 1, 2 * nN + 1
            t_[i] = ta + (i - 1) * (tb - ta) / (2 * nN)
        dpos = @tDifferential(XY, t_[1])
        Ft1 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        dpos = @tDifferential(XY, t_[2 * nN + 1])
        Ft2 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt1 = 0
        for i = 1, nN
            dpos = @tDifferential(XY, t_[2 * i])
            SFt1 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt2 = 0
        for i = 1, nN - 1
            dpos = @tDifferential(XY, t_[2 * i + 1])
            SFt2 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        return ((tb - ta) / (2 * nN) / 3) * ((Ft1 + Ft2) + (4 * SFt1) + (2 * SFt2))

    length2t: (Pnts, Ltarget, nN) =>
        ll = {0}
        ni, tb, t_ = 1 / nN, 0, 0
        for i = 2, nN + 1
            tb += ni
            ll[i] = @getBezierLength(Pnts, 0, tb, nN * 2)
        return false if Ltarget > ll[nN + 1]
        for i = 1, nN
            if (Ltarget >= ll[i]) and (Ltarget <= ll[i + 1])
                t_ = (i - 1) / nN + (Ltarget - ll[i]) / (ll[i + 1] - ll[i]) * (1 / nN)
                break
        return t_

    length2PtNo: (Pnts, Ltarget, nN) =>
        local cpoint, leng
        for h = 1, #Pnts
            bl = {0}
            for i = 2, #Pnts[h] + 1
                bl[i] = bl[i - 1] + @getBezierLength(Pnts[h][i - 1], 0, 1.0, nN)
            if Ltarget > bl[#bl]
                Ltarget -= bl[#bl]
            else
                for k = 1, #Pnts[h]
                    if (Ltarget >= bl[k]) and (Ltarget <= bl[k + 1])
                        cpoint = Pnts[h][k]
                        leng = Ltarget - bl[k]
                        break
            if leng
                break
        if leng
            return cpoint, leng
        return false

    getBezierPos: (Pnts, t_) =>
        XY, pos_Bzr = @difference(Pnts), {}
        for i = 1, 2
            pos_Bzr[i] = XY[4][i] * t_ ^ 3 + 3 * XY[3][i] * t_ ^ 2 + 3 * XY[2][i] * t_ + XY[1][i]
        return pos_Bzr

    getCoords: (shape) =>
        coords, paths = {}, zf.shape(shape, false)\to_bezier!.paths
        for i = 1, #paths
            coords[i] = {}
            for j = 1, #paths[i]
                if paths[i][j].typer != "m"
                    coords[i][#coords[i] + 1] = {
                        {paths[i][j - 1][#paths[i][j - 1] - 1], paths[i][j - 1][#paths[i][j - 1] - 0]}
                        {paths[i][j][1], paths[i][j][2]}
                        {paths[i][j][3], paths[i][j][4]}
                        {paths[i][j][5], paths[i][j][6]}
                    }
        return coords

main = (subs, sel) ->
    inter = zf.config\load(zf.config\interface(script_name)!, script_name)
    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
        inter = switch buttons
            when "Save"
                zf.config\save(inter, elements, script_name, script_version)
                zf.config\load(inter, script_name)
            when "Reset"
                zf.config\interface(script_name)!
        break if buttons == "Ok" or buttons == "Cancel"
    -- get frame duration
    msa, msb, j, mds = aegisub.ms_from_frame(1), aegisub.ms_from_frame(101), 0, 1
    frame_dur = msb and zf.math\round((msb - msa) / 100, 3) or 41.708
    if buttons == "Ok"
        aegisub.progress.task "Generating..."
        for _, i in ipairs sel
            aegisub.progress.set i / #sel * 100
            l = subs[i + j]
            l.comment = true
            -- sets up the entire input structure
            meta, styles = zf.util\tags2styles(subs, l)
            karaskel.preproc_line(subs, meta, styles, l)
            coords = zf.util\find_coords(l, meta)
            --
            shape = zf.util\clip_to_draw(l.text)
            src_tg = zf.tags(l.text)\find!
            detect = zf.tags\remove("full", l.text)
            -- checks if it has the \clip tag and if it is text
            assert src_tg\match("\\clip%b()"), "clip expected"
            assert not detect\match("m%s+%-?%d[%.%-%d mlb]*"), "text expected"
            line = zf.table(l)\copy!
            subs[i + j] = l
            -- deletes the selected lines if true
            if elements.chk == true
                subs.delete(i + j)
                j -= 1
            -- sets the output mode of the function CharsBezier
            mds = switch elements.mds
                when "Center" then 1
                when "Left"   then 2
                when "Right"  then 3
            tags = zf.text(subs, line, line.text)\tags!
            -- gets new width
            get_width = (tags) -> zf.table(tags)\arithmetic_op ((v) -> v.width), "+"
            -- gets the difference
            dif = get_width(tags) - line.width
            -- adds difference in real width
            line.width += dif
            for t, tag in ipairs tags
                rtags = zf.tags\remove("text_in_clip", tag.tags\sub(2, -2))
                for c, char in ipairs tag.chars
                    tag.comment = false
                    px, py = switch tag.styleref.align
                        when 1 then char.left,   tag.bottom
                        when 2 then char.center, tag.bottom
                        when 3 then char.right,  tag.bottom
                        when 4 then char.left,   tag.middle
                        when 5 then char.center, tag.middle
                        when 6 then char.right,  tag.middle
                        when 7 then char.left,   tag.top
                        when 8 then char.center, tag.top
                        when 9 then char.right,  tag.top
                    -- adds the difference / 2 on the X axis
                    px += math.ceil dif / 2
                    bezier = PyointaBezier(line, shape, px, py, mds, elements.off)
                    cs, cd = char.start_time, char.duration
                    switch elements.mds
                        when "Around"
                            bezier = PyointaBezier(line, shape, px, py, 4, (c - 1) / (char.n - 1))
                            tag.text = "#{zf.tags\clean("{#{bezier.out .. rtags}}")}#{char.text_stripped}"
                            subs.insert(i + j + 1, tag)
                            j += 1
                        when "Animated - Start to End", "Animated - End to Start"
                            elements.off = 1 if elements.off <= 0
                            mode = elements.mds == "Animated - End to Start" and 5 or 4
                            loop = zf.math\round(tag.duration / (frame_dur * elements.off), 3)
                            for k = 1, loop
                                bezier = PyointaBezier(line, shape, px, py, mode, (k - 1) / (loop - 1))
                                tag.start_time = cs + cd * (k - 1) / loop
                                tag.end_time = cs + cd * k / loop
                                tag.text = "#{zf.tags\clean("{#{bezier.out .. rtags}}")}#{char.text_stripped}"
                                subs.insert(i + j + 1, tag)
                                j += 1
                        else
                            tag.text = "#{zf.tags\clean("{#{bezier.out .. rtags}}")}#{char.text_stripped}"
                            subs.insert(i + j + 1, tag)
                            j += 1

aegisub.register_macro script_name, script_description, main