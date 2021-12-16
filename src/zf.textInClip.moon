export script_name        = "Text in Clip"
export script_description = "Causes the characters in your text to go through the coordinates of your clip!"
export script_author      = "Zeref"
export script_version     = "1.0.0"
-- LIB
zf = require "ZF.main"

import POINT from require "ZF.2D.point"
import SHAPE from require "ZF.2D.shape"

-- https://github.com/KaraEffect0r/Kara_Effector/blob/2a0a9cae4a0ebd7a254cfa360f52fcdd5fb61f03/Effector4/effector-auto4.lua#L5069
class PyointaBezier

    new: (line, shape, px, py, mode, offset = 0) =>
        lWidth, lLeft, nN, bLen, lineOffset, pBezier, vBezier, paths, PtNo = line.width, line.left, 8, 0, 0, {}, {}, {}, {}

        paths = @getCoords shape
        for m in *paths
            for p in *m
                bLen += @getBezierLength p, 0, 1, nN

        lineOffset = switch mode
            when 2 then offset
            when 3 then (bLen - lWidth) - offset
            when 4 then (bLen - lWidth) * offset
            when 5 then (bLen - lWidth) * (1 - offset)
            else        (bLen - lWidth) / 2 + offset

        targetLength, angle = 0, 0
        PtNo, targetLength = @length2PtNo paths, lineOffset + px - lLeft, nN
        if PtNo != false
            tb = @length2t PtNo, targetLength, nN
            if tb != false
                pBezier = @getBezierPos PtNo, tb
                vBezier = @normal2P PtNo, tb
                angle = -deg(atan2(vBezier[2], vBezier[1])) - 90
        else
            pBezier[1] = px
            pBezier[2] = py

        @out = {
            zf.math\round pBezier[1]
            zf.math\round pBezier[2]
            a: zf.math\round angle < -180 and angle + 360 or angle
        }

    tangential2P: (Pnts, t_) =>
        tanVec, XY = {}, @difference Pnts
        dpos = @tDifferential XY, t_
        for i = 1, 2
            tanVec[i] = dpos[2][i] / sqrt(dpos[2][1] ^ 2 + dpos[2][2] ^ 2)
        return tanVec

    normal2P: (Pnts, t_) =>
        normalVec = @tangential2P Pnts, t_
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
        t_, XY = {}, @difference p
        for i = 1, 2 * nN + 1
            t_[i] = ta + (i - 1) * (tb - ta) / (2 * nN)
        dpos = @tDifferential XY, t_[1]
        Ft1 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        dpos = @tDifferential XY, t_[2 * nN + 1]
        Ft2 = (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt1 = 0
        for i = 1, nN
            dpos = @tDifferential XY, t_[2 * i]
            SFt1 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        SFt2 = 0
        for i = 1, nN - 1
            dpos = @tDifferential XY, t_[2 * i + 1]
            SFt2 += (dpos[2][1] ^ 2 + dpos[2][2] ^ 2) ^ 0.5
        return ((tb - ta) / (2 * nN) / 3) * ((Ft1 + Ft2) + (4 * SFt1) + (2 * SFt2))

    length2t: (Pnts, Ltarget, nN) =>
        ll = {0}
        ni, tb, t_ = 1 / nN, 0, 0
        for i = 2, nN + 1
            tb += ni
            ll[i] = @getBezierLength Pnts, 0, tb, nN * 2
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
                bl[i] = bl[i - 1] + @getBezierLength Pnts[h][i - 1], 0, 1, nN
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
        coords, paths = {}, SHAPE(shape, false)\toBezier!.paths
        for i = 1, #paths
            coords[i] = {}
            for j = 2, #paths[i]
                zf.table(coords[i])\push {
                    {paths[i][j][1].x, paths[i][j][1].y}
                    {paths[i][j][2].x, paths[i][j][2].y}
                    {paths[i][j][3].x, paths[i][j][3].y}
                    {paths[i][j][4].x, paths[i][j][4].y}
                }
        return coords

interface = ->
    items = {"Center", "Left", "Right", "Around", "Animated - Start to End", "Animated - End to Start"}
    hints = {
        items: "Position of the text relative to the text",
        offset: "The offset value of the position of the text \nrelative to the clip. \nIn case of animations, the value is a natural \nnumber that equals the frame step."
    }
    {
        {class: "label", label: "Modes:", x: 0, y: 0}
        {class: "dropdown", name: "mds", :items, hint: hints.items, x: 0, y: 1, value: items[1]}
        {class: "checkbox", name: "wwd", label: "With Words?", x: 0, y: 2, value: false}
        {class: "label", label: "\nOffset:", x: 0, y: 3}
        {class: "intedit", name: "off", hint: hints.offset, x: 0, y: 4, value: 0}
        {class: "checkbox", name: "remove", label: "Remove selected layers?", x: 0, y: 5, value: true}
    }

main = (subs, selected) ->
    gui = zf.config\loadGui interface!, script_name

    local buttons, elements
    while true
        buttons, elements = aegisub.dialog.display gui, {"Ok", "Reset", "Cancel"}, close: "Cancel"
        gui = switch buttons
            when "Reset"  then interface!
            when "Cancel" then return
            else               break

    zf.config\saveGui elements, script_name

    n, i = selected[#selected], 0
    for s, sel in ipairs selected
        aegisub.progress.set 100 * sel / n
        aegisub.progress.task "Processing line: #{s}"

        l = subs[sel + i]

        coords = zf.util\setPreprocLine subs, l
        px, py = coords.pos.x, coords.pos.y

        continue if not zf.util\runMacro(l) or zf.util\isShape coords, l.text\gsub "%b{}", ""

        l.comment = true

        subs[sel + i] = l

        line = zf.table(l)\copy!
        line.comment = false

        rawTag = zf.tags\getTag line.text
        zf.tags\dependency rawTag, "clips"

        -- gets frame duration
        msa, msb, j = aegisub.ms_from_frame(1), aegisub.ms_from_frame(101), 0
        frameDur = msb and (msb - msa) / 100 or 41.708

        with elements

            if .remove
                subs.delete sel + i
                i -= 1

            mds = switch .mds
                when "Center" then 1
                when "Left"   then 2
                when "Right"  then 3
                when "Around" then 4

            call = zf.text(subs, line, line.text)\tags!

            sumWidth = zf.table(call)\arithmeticOp ((val) -> val.width), "+"
            dffWidth = sumWidth - line.width

            line.width += dffWidth

            for t, tag in ipairs call

                rawTag = zf.tags\getTag tag.text
                clip = zf.util\clip2Draw rawTag
                rawTag = zf.tags\clear tag, rawTag, "To Clip"

                textId = zf.text subs, tag
                values = .wwd and textId\words! or textId\chars!

                for key, value in ipairs values
                    value.x += ceil dffWidth / 2
                    cs, cd = value.start_time, value.duration

                    if .mds == "Animated - Start to End" or .mds == "Animated - End to Start"
                        .off = 1 if .off <= 0

                        mode = .mds == "Animated - End to Start" and 5 or 4
                        loop = zf.math\round tag.duration / (frameDur * .off), 0

                        for j = 1, loop
                            tag.start_time = cs + cd * (j - 1) / loop
                            tag.end_time = cs + cd * j / loop

                            result = PyointaBezier(line, clip, value.x, value.y, mode, (j - 1) / (loop - 1)).out

                            tags = zf.tags\replaceT rawTag, "pos", result
                            tags = zf.tags\merge tags, "\\frz#{result.a}"

                            tag.text = tags .. value.text_stripped

                            subs.insert sel + i + 1, tag
                            i += 1
                    else
                        result = PyointaBezier(line, clip, value.x, value.y, mds, .mds == "Around" and (key - 1) / (value.n - 1) or nil).out

                        tags = zf.tags\replaceT rawTag, "pos", result
                        tags = zf.tags\merge tags, "\\frz#{result.a}"

                        tag.text = tags .. value.text_stripped

                        subs.insert sel + i + 1, tag
                        i += 1

aegisub.register_macro script_name, script_description, main