-- Copyright (c) 2007, Niels Martin Hansen, Rodrigo Braz Monteiro
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

-- * Redistributions of source code must retain the above copyright notice,
--     this list of conditions and the following disclaimer.
-- * Redistributions in binary form must reproduce the above copyright notice,
--     this list of conditions and the following disclaimer in the documentation
--     and/or other materials provided with the distribution.
-- * Neither the name of the Aegisub Group nor the names of its contributors
--     may be used to endorse or promote products derived from this software
--     without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-- Aegisub Automation 4 Lua karaoke templater tool
-- Parse and apply a karaoke effect written in ASS karaoke template language
-- See help file and wiki for more information on this

export script_name            = "Karaoke Templater"
export script_description     = "Macro and export filter to apply karaoke effects using the template language"
export script_author          = "Niels Martin Hansen"
export script_version         = "2.1.7"

export script_mod_name        = "Karaoke Templater - Modified"
export script_mod_description = script_description
export script_mod_author      = "Zeref"
export script_mod_version     = "1.0.1"

local *
require "karaskel"

-- List of reserved words that can't be used as "line" template identifiers
template_modifiers = {"pre-line", "line", "syl", "furi", "char", "word", "bysyl", "bychar", "byword", "all", "repeat", "loop", "replay", "notext", "keeptags", "noblank", "multi", "fx", "fxgroup"}

-- Round numbers
round_number = (x, dec) ->
    if dec and dec >= 1
        dec = 10 ^ math.floor(dec)
        math.floor(x * dec + 0.5) / dec
    else
        math.floor(x + 0.5)

-- Find and parse/prepare all karaoke template lines
parse_templates = (subs) ->
    templates = {once: {}, line: {}, syl: {}, char: {}, word: {}, furi: {}, styles: {}}
    i = 1
    while i <= #subs
        aegisub.progress.set((i - 1) / #subs * 100)
        l = subs[i]
        i += 1
        if l.class == "dialogue" and l.comment
            fx, mods = string.headtail(l.effect)
            fx = fx\lower!
            switch fx
                when "code"
                    parse_code(l, templates, mods)
                when "template"
                    parse_template(l, templates, mods)
            templates.styles[l.style] = true
        elseif l.class == "dialogue" and l.effect == "fx"
            -- this is a previously generated effect line, remove it
            i -= 1
            subs.delete(i)
    aegisub.progress.set(100)
    return templates

parse_code = (line, templates, mods) ->
    template = {
        code: line.text,
        loops: {1, 1, 1},
        style: line.style
    }
    inserted = false
    rest = mods
	loop_p = rest\match("%b{}")
    rest = rest\gsub("%b{}", "")
    while rest != ""
        m, t = string.headtail(rest)
        rest = t
        m = m\lower!
        switch m
            when "once"
                aegisub.debug.out(5, "Found run-once code line: %s\n", line.text)
                table.insert(templates.once, template)
                inserted = true
            when "line"
                aegisub.debug.out(5, "Found per-line code line: %s\n", line.text)
                table.insert(templates.line, template)
                inserted = true
            when "syl"
                aegisub.debug.out(5, "Found per-syl code line: %s\n", line.text)
                table.insert(templates.syl, template)
                inserted = true
            when "char"
                aegisub.debug.out(5, "Found per-char code line: %s\n", line.text)
                table.insert(templates.char, template)
                inserted = true
            when "word"
                aegisub.debug.out(5, "Found per-word code line: %s\n", line.text)
                table.insert(templates.word, template)
                inserted = true
            when "furi"
                aegisub.debug.out(5, "Found per-syl code line: %s\n", line.text)
                table.insert(templates.furi, template)
                inserted = true
            when "all"
                template.style = nil
            when "noblank"
                template.noblank = true
            when "repeat", "loop", "replay"
                times, t = string.headtail(rest)
                loop_p = loadstring(("return (%s)")\format(loop_p))! or tonumber(times)
                template.loops = type(loop_p) == "number" and {loop_p, 1, 1} or loop_p
                unless template.loops
                    aegisub.debug.out(3, "Failed reading this repeat-count to a number: %s\nIn template code line: %s\nEffect field: %s\n\n", times, line.text, line.effect)
                    template.loops = {1, 1, 1}
                else
                    rest = t
            else
                aegisub.debug.out(3, "Unknown modifier in code template: %s\nIn template code line: %s\nEffect field: %s\n\n", m, line.text, line.effect)
    unless inserted
        aegisub.debug.out(5, "Found implicit run-once code line: %s\n", line.text)
        table.insert(templates.once, template)

parse_template = (line, templates, mods) ->
    template = {
        t: "",
        pre: "",
        style: line.style,
        loops: {1, 1, 1},
        layer: line.layer,
        addtext: true,
        keeptags: false,
        fxgroup: nil,
        fx: nil,
        multi: false,
        isline: false,
		bysyl: false,
		bychar: false,
		byword: false,
        noblank: false
    }
    inserted = false
    rest = mods
	loop_p = rest\match("%b{}")
    rest = rest\gsub("%b{}", "")
    while rest != ""
        m, t = string.headtail(rest)
        rest = t
        m = m\lower!
        if (m == "pre-line" or m == "line" or m == "bysyl" or m == "bychar" or m == "byword") and not inserted
            aegisub.debug.out(5, "Found line template '%s'\n", line.text)
            -- should really fail if already inserted
            id, t = string.headtail(rest)
            id = id\lower!
            -- check that it really is an identifier and not a keyword
            for _, kw in pairs(template_modifiers)
                if id == kw
                    id = nil
                    break
            id = nil if id == ""
            rest = t if id
            -- get old template if there is one
            if id and templates.line[id]
                template = templates.line[id]
            elseif id
                template.id = id
                templates.line[id] = template
            else
                table.insert(templates.line, template)
            inserted = true
            template.isline = true
			template.bysyl  = (m == "bysyl" or m == "pre-line" or m == "line")
			template.bychar = (m == "bychar")
            template.byword = (m == "byword")
            -- apply text to correct string
            if (m == "line") or (m == "bysyl") or (m == "bychar") or (m == "byword")
                template.t ..= line.text
            else -- must be pre-line
                template.pre ..= line.text
        elseif m == "syl" and not template.isline
            table.insert(templates.syl, template)
            inserted = true
        elseif (m == "char") and not template.isline
            table.insert(templates.char, template)
            inserted = true
		elseif (m == "word") and not template.isline
            table.insert(templates.word, template)
            inserted = true
        elseif m == "furi" and not template.isline
            table.insert(templates.furi, template)
            inserted = true
        elseif (m == "pre-line" or m == "line") and inserted
            aegisub.debug.out(2, "Unable to combine %s class templates with other template classes\n\n", m)
        elseif (m == "syl" or m == "furi" or m == "char" or m == "word") and template.isline
            aegisub.debug.out(2, "Unable to combine %s class template lines with line or pre-line classes\n\n", m)
        elseif m == "all"
            template.style = nil
        elseif (m == "repeat" or m == "loop" or m == "replay")
            times, t = string.headtail(rest)
            loop_p = loadstring(("return (%s)")\format(loop_p))! or tonumber(times)
            template.loops = type(loop_p) == "number" and {loop_p, 1, 1} or loop_p
            unless template.loops
                aegisub.debug.out(3, "Failed reading this repeat-count to a number: %s\nIn template code line: %s\nEffect field: %s\n\n", times, line.text, line.effect)
                template.loops = {1, 1, 1}
            else
                rest = t
        elseif m == "notext"
            template.addtext = false
        elseif m == "keeptags"
            template.keeptags = true
        elseif m == "multi"
            template.multi = true
        elseif m == "noblank"
            template.noblank = true
        elseif m == "fx"
            fx, t = string.headtail(rest)
            if fx != ""
                template.fx, rest = fx, t
            else
                aegisub.debug.out(3, "No fx name following fx modifier\nIn template line: %s\nEffect field: %s\n\n", line.text, line.effect)
                template.fx = nil
        elseif m == "fxgroup"
            fx, t = string.headtail(rest)
            if fx != ""
                template.fxgroup, rest = fx, t
            else
                aegisub.debug.out(3, "No fxgroup name following fxgroup modifier\nIn template linee: %s\nEffect field: %s\n\n", line.text, line.effect)
                template.fxgroup = nil
        else
            aegisub.debug.out(3, "Unknown modifier in template: %s\nIn template line: %s\nEffect field: %s\n\n", m, line.text, line.effect)
    table.insert(templates.syl, template) unless inserted
    template.t = line.text unless template.isline

-- Iterator function, return all templates that apply to the given line
matching_templates = (templates, line, tenv) ->
    lastkey = nil
    test_next = ->
        k, t = next(templates, lastkey)
        lastkey = k
        if not t
            return nil
        elseif (t.style == line.style or not t.style) and (not t.fxgroup or (t.fxgroup and tenv.fxgroup[t.fxgroup] != false))
            return t
        else
            return test_next!
    return test_next

-- Iterator function, run a loop using tenv.j and tenv.maxj as loop controllers
template_loop = (tenv, initmaxj, l_type) ->
    initmaxj or= 1
    oldmaxj = initmaxj
    tenv["max#{l_type}"] = initmaxj
    tenv[l_type] = 0
    itor = ->
        if tenv[l_type] >= tenv["max#{l_type}"] or aegisub.progress.is_cancelled!
            return nil
        else
            tenv[l_type] += 1
            if oldmaxj != tenv["max#{l_type}"]
                aegisub.debug.out(5, "Number of loop iterations changed from %d to %d\n", oldmaxj, tenv["max#{l_type}"])
                oldmaxj = tenv["max#{l_type}"]
            return tenv[l_type], tenv["max#{l_type}"]
    return itor

apply_templates = (meta, styles, subs, templates) ->
    -- the environment the templates will run in
    tenv = {
        meta: meta,
        -- put in some standard libs
        string: string,
        subs: subs,
        aegisub: aegisub,
		ke4: _G.ke4 and _G.ke4 or nil,
        math: math,
        _G: _G
    }
    tenv.tenv = tenv
    -- Define helper functions in tenv
    tenv.retime = (mode, addstart, addend) ->
        line, syl, char, word = tenv.line, tenv.syl, tenv.char, tenv.word
        newstart, newend = line.start_time, line.end_time
        addstart or= 0
        addend or= 0
        switch mode
            when "preline"
                newstart = line.start_time + addstart
                newend = line.start_time + addend
            when "line"
                newstart = line.start_time + addstart
                newend = line.end_time + addend
            when "postline"
                newstart = line.end_time + addstart
                newend = line.end_time + addend
            when "presyl"
                newstart = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addstart
                newend = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addend
            when "syl"
                newstart = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addstart
                newend = line.start_time + ((char and char.syl) and char.syl.end_time or syl.end_time) + addend
            when "postsyl"
                newstart = line.start_time + ((char and char.syl) and char.syl.end_time or syl.end_time) + addstart
                newend = line.start_time + ((char and char.syl) and char.syl.end_time or syl.end_time) + addend
            when "start2syl"
                newstart = line.start_time + addstart
                newend = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addend
            when "syl2end"
                newstart = line.start_time + ((char and char.syl) and char.syl.end_time or syl.end_time) + addstart
                newend = line.end_time + addend
            when "prechar"
                newstart = line.start_time + char.start_time + addstart
                newend = line.start_time + char.start_time + addend
            when "char"
                newstart = line.start_time + char.start_time + addstart
                newend = line.start_time + char.end_time + addend
            when "postchar"
                newstart = line.start_time + char.end_time + addstart
                newend = line.start_time + char.end_time + addend
            when "start2char"
                newstart = line.start_time + addstart
                newend = line.start_time + char.start_time + addend
            when "char2end"
                newstart = line.start_time + char.end_time + addstart
                newend = line.end_time + addend
            when "preword"
                newstart = line.start_time + word.start_time + addstart
                newend = line.start_time + word.start_time + addend
            when "word"
                newstart = line.start_time + word.start_time + addstart
                newend = line.start_time + word.end_time + addend
            when "postword"
                newstart = line.start_time + word.end_time + addstart
                newend = line.start_time + word.end_time + addend
            when "start2word"
                newstart = line.start_time + addstart
                newend = line.start_time + word.start_time + addend
            when "word2end"
                newstart = line.start_time + word.end_time + addstart
                newend = line.end_time + addend
            when "set" or mode == "abs"
                newstart = addstart
                newend = addend
            when "sylpct"
                newstart = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addstart * syl.duration / 100
                newend = line.start_time + ((char and char.syl) and char.syl.start_time or syl.start_time) + addend * syl.duration / 100
            when "charpct"
                newstart = line.start_time + char.start_time + addstart * char.duration / 100
                newend = line.start_time + char.start_time + addend * char.duration / 100
            when "wordpct"
                newstart = line.start_time + word.start_time + addstart * word.duration / 100
                newend = line.start_time + word.start_time + addend * word.duration / 100
                -- wishlist: something for fade-over effects,
                -- "time between previous line and this" and
                -- "time between this line and next"
        line.start_time = newstart
        line.end_time = newend
        line.duration = newend - newstart
        return ""

    tenv.fxgroup = {}
    tenv.relayer = (layer) ->
        tenv.line.layer = layer
        return ""

    tenv.restyle = (style) ->
        tenv.line.style = style
        tenv.line.styleref = styles[style]
        return ""

    tenv.maxloop = (newmaxj, newmaxi, newmaxk) ->
        tenv.maxj = newmaxj or 1
        tenv.maxi = newmaxi or 1
		tenv.maxk = newmaxk or 1
        return ""

    tenv.maxloops = tenv.maxloop
    tenv.loopctl = (newj, newmaxj, newi, newmaxi, newk, newmaxk) ->
        tenv.j, tenv.maxj = newj, newmaxj
        tenv.i, tenv.maxi = newi, newmaxi
		tenv.k, tenv.maxk = newk, newmaxk
        return ""

    tenv.recall = {}
    tenv.remember = (ref, val) ->
        tenv.recall[ref] = val
        return val

    -- run all run-once code snippets
    for k, t in pairs(templates.once)
        assert(t.code, "WTF, a 'once' template without code?")
        run_code_template(t, tenv)

    -- start processing lines
    i, j, n = 0, 1, #subs
    while i < n
        aegisub.progress.set(i / n * 100)
        i += 1
        l = subs[i]
        if l.class == "dialogue" and ((l.effect == "" and not l.comment) or l.effect\match("[Kk]araoke"))
            l.i = j
            j += 1
            l.comment = false
            karaskel.preproc_line(subs, meta, styles, l)
			l = dialog_extend(l)
            if apply_line(subs, l, templates, tenv)
                -- Some templates were applied to this line, make a karaoke timing line of it
                l.comment = true
                l.effect = "karaoke"
                subs[i] = l

make_set_ctx = (varctx, line, index, l) ->
    varctx["#{l}start"] = index.start_time
    varctx["#{l}end"] = index.end_time
    varctx["#{l}dur"] = index.duration
    varctx["#{l}mid"] = index.start_time + index.duration / 2
    varctx["#{l}n"] = index.n
    varctx["n"] = index.n
    varctx["start"] = varctx["#{l}start"]
    varctx["end"] = varctx["#{l}end"]
    varctx["dur"] = varctx["#{l}dur"]
    varctx["mid"] = varctx["#{l}mid"]
    varctx["#{l}i"] = index.i
    varctx["i"] = varctx["#{l}i"]
    if l == "s"
        varctx["skdur"] = index.duration / 10
        varctx["kdur"] = varctx["skdur"]
    varctx["#{l}left"] = round_number(index.left, 2)
    varctx["#{l}center"] = round_number(index.center, 2)
    varctx["#{l}right"] = round_number(index.right, 2)
    varctx["#{l}width"] = round_number(index.width, 2)
    if l == "s" and index.isfuri
        varctx["#{l}bottom"] = varctx.ltop
        varctx["#{l}top"] = round_number(varctx.ltop - index.height, 2)
        varctx["#{l}middle"] = round_number(varctx.ltop - index.height / 2, 2)
    else
        varctx["#{l}top"] = varctx.ltop
        varctx["#{l}middle"] = varctx.lmiddle
        varctx["#{l}bottom"] = varctx.lbottom
    varctx["#{l}height"] = index.height
    switch line["halign"]
        when "left"
            varctx["#{l}x"] = round_number(index.left, 2)
        when "center"
            varctx["#{l}x"] = round_number(index.center, 2)
        when "right"
            varctx["#{l}x"] = round_number(index.right, 2)
    switch line["valign"]
        when "top"
            varctx["#{l}y"] = varctx["#{l}top"]
        when "middle"
            varctx["#{l}y"] = varctx["#{l}middle"]
        when "bottom"
            varctx["#{l}y"] = varctx["#{l}sbottom"]
    varctx.left = varctx["#{l}left"]
    varctx.center = varctx["#{l}center"]
    varctx.right = varctx["#{l}right"]
    varctx.width = varctx["#{l}width"]
    varctx.top = varctx["#{l}top"]
    varctx.middle = varctx["#{l}middle"]
    varctx.bottom = varctx["#{l}bottom"]
    varctx.height = varctx["#{l}height"]
    varctx.x = varctx["#{l}x"]
    varctx.y = varctx["#{l}y"]

dialog_extend = (line, rd = 2) ->
    l = table.copy(line)
    l.chars, l.words, dur = {n: 0}, {n: 0}, 0
    space_width = aegisub.text_extents(l.styleref, " ")
    local word, char
    for pe, w, po in line.text_stripped\gmatch "(%s*)(%S+)(%s*)"
        word_d = unicode.len(w) * line.duration / unicode.len(line.text_stripped\gsub " ", "")
        word = {
            i: l.words.n + 1
            start_time: dur
            mid_time: dur + word_d / 2
            end_time: dur + word_d
            duration: word_d
            text: w
            text_stripped: w
            prespace: pe\len!
            postspace: po\len!
            style: l.styleref
        }
        dur += word.duration
        word.width, word.height, word.descent, word.external_leading = aegisub.text_extents(line.styleref, word.text)
        l.words.n += 1
        l.words[l.words.n] = word
    left = l.left
    for i = 1, l.words.n
        with l.words[i]
            left += .prespace * space_width
            .left = round_number left , rd
            .center = round_number .left + .width / 2, rd
            .right = round_number .left + .width, rd
            .top = round_number l.top, rd
            .middle = round_number l.middle, rd
            .bottom = round_number l.bottom, rd
            .n = l.words.n
            left += .width + .postspace * space_width
    dur = 0
    for c in unicode.chars(line.text_stripped)
        char_d = (c == "" or c == " ") and 0 or line.duration / unicode.len(line.text_stripped\gsub " ", "")
        char = {
            i: l.chars.n + 1
            start_time: dur
            mid_time: dur + char_d / 2
            end_time: dur + char_d
            duration: char_d
            text: c
            text_stripped: c
            style: l.styleref
        }
        dur += char.duration
        char.width, char.height, char.descent, char.external_leading = aegisub.text_extents(l.styleref, char.text)
        l.chars.n += 1
        l.chars[l.chars.n] = char
    left = l.left
    for i = 1, l.chars.n
        with l.chars[i]
            .left = round_number left, rd
            .center = round_number .left + .width / 2, rd
            .right = round_number .left + .width, rd
            .top = round_number l.top, rd
            .middle = round_number l.middle, rd
            .bottom = round_number l.bottom, rd
            .n = l.chars.n
            left += .width
    count = 0
    for i = 1, l.words.n
        with l.words[i]
            ipoli, ipoln = 0, unicode.len(.text_stripped)
            for c in unicode.chars(("%s%s%s")\format((" ")\rep(.prespace), .text, (" ")\rep(.postspace)))
                count += 1
                ipoli += 1
                char = l.chars[count]
                char.wi, char.wn = i, l.words.n
                char.wi_start_time = .start_time + .duration * (ipoli - 1) / ipoln
                char.wi_end_time = .start_time + .duration * ipoli / ipoln
                char.wi_duration = char.wi_end_time - char.wi_start_time
                char.wi_mid_time = char.wi_duration / 2
                char.word = l.words[i]
    if l.text\match("%{\\[kK][of]?(%d+)%}")
        count = 0
        for i = 1, l.kara.n
            with l.kara[i]
                .left = round_number .left + l.left, rd
                .center = round_number .center + l.left, rd
                .right = round_number .right + l.left, rd
                .n = l.kara.n
                ipoli, ipoln = 0, unicode.len(.text_stripped)
                for c in unicode.chars(.text_stripped)
                    count += 1
                    ipoli += 1
                    char = l.chars[count]
                    char.si, char.sn = .i, .n
                    char.start_time = .start_time
                    char.mid_time = .mid_time
                    char.end_time = .end_time
                    char.si_start_time = .start_time + .duration * (ipoli - 1) / ipoln
                    char.si_end_time = .start_time + .duration * ipoli / ipoln
                    char.si_duration = char.si_end_time - char.si_start_time
                    char.si_mid_time = char.si_duration / 2
                    char.syl = l.kara[i]
    return l

apply_line = (subs, line, templates, tenv) ->
    -- Tell whether any templates were applied to this line, needed to know whether the original line should be removed from input
    applied_templates = false
    -- General variable replacement context
    varctx = {
        layer: line.layer,
        lstart: line.start_time,
        lend: line.end_time,
        ldur: line.duration,
        lmid: line.start_time + line.duration / 2,
        style: line.style,
        actor: line.actor,
        margin_l: ((line.margin_l > 0) and line.margin_l) or line.styleref.margin_l,
        margin_r: ((line.margin_r > 0) and line.margin_r) or line.styleref.margin_r,
        margin_t: ((line.margin_t > 0) and line.margin_t) or line.styleref.margin_t,
        margin_b: ((line.margin_b > 0) and line.margin_b) or line.styleref.margin_b,
        margin_v: ((line.margin_t > 0) and line.margin_t) or line.styleref.margin_t,
        syln: line.kara.n,
        li: line.i,
        lleft: round_number(line.left, 2),
        lcenter: round_number(line.left + line.width / 2, 2),
        lright: round_number(line.left + line.width, 2),
        lwidth: round_number(line.width, 2),
        ltop: round_number(line.top, 2),
        lmiddle: round_number(line.middle, 2),
        lbottom: round_number(line.bottom, 2),
        lheight: round_number(line.height, 2),
        lx: round_number(line.x, 2),
        ly: round_number(line.y, 2)
    }
    tenv.orgline = line
    tenv.line = nil
    tenv.syl = nil
	tenv.char = nil
	tenv.word = nil
    tenv.basesyl = nil
	tenv.basechar = nil
	tenv.baseword = nil
    -- Apply all line templates
    aegisub.debug.out(5, "Running line templates\n")
    for t in matching_templates(templates.line, line, tenv)
        break if aegisub.progress.is_cancelled!
        -- Set varctx for per-line variables
        varctx["start"] = varctx.lstart
        varctx["end"] = varctx.lend
        varctx.dur = varctx.ldur
        varctx.kdur = math.floor(varctx.dur / 10)
        varctx.mid = varctx.lmid
        varctx.i = varctx.li
        varctx.left = varctx.lleft
        varctx.center = varctx.lcenter
        varctx.right = varctx.lright
        varctx.width = varctx.lwidth
        varctx.top = varctx.ltop
        varctx.middle = varctx.lmiddle
        varctx.bottom = varctx.lbottom
        varctx.height = varctx.lheight
        varctx.x = varctx.lx
        varctx.y = varctx.ly
		for k, maxk in template_loop(tenv, t.loops[3], "k")
			for i, maxi in template_loop(tenv, t.loops[2], "i")
				for j, maxj in template_loop(tenv, t.loops[1], "j")
					if t.code
						aegisub.debug.out(5, "Code template, %s\n", t.code)
						tenv.line = line
						-- Although run_code_template also performs template looping this works
						-- by "luck", since by the time the first loop of this outer loop completes
						-- the one run by run_code_template has already performed all iterations
						-- and has tenv.j and tenv.maxj in a loop-ending state, causing the outer
						-- loop to only ever run once.
						run_code_template(t, tenv)
					else
						aegisub.debug.out(5, "Line template, pre = '%s', t = '%s'\n", t.pre, t.t)
						applied_templates = true
						newline = table.copy(line)
						tenv.line = newline
						newline.layer = t.layer
						newline.text = ""
						newline.text ..= run_text_template(t.pre, tenv, varctx) if t.pre != ""
						if t.t != ""
							if t.bychar
								for i = 1, line.chars.n
									char = line.chars[i]
									tenv.char, tenv.basechar = char, char
									make_set_ctx(varctx, line, char, "c")
									newline.text ..= run_text_template(t.t, tenv, varctx)
									if t.addtext
										if t.keeptags
											newline.text ..= char.text
										else
											newline.text ..= char.text_stripped
							elseif t.byword
								for i = 1, line.words.n
									word = line.words[i]
									tenv.word, tenv.baseword = word, word
									make_set_ctx(varctx, line, word, "w")
									newline.text ..= run_text_template(t.t, tenv, varctx)
									if t.addtext
										if t.keeptags
											newline.text ..= word.text .. " "
										else
											newline.text ..= word.text_stripped .. " "
							elseif t.bysyl
								for i = 1, line.kara.n
									syl = line.kara[i]
                                    syl.n = line.kara.n
									tenv.syl, tenv.basesyl = syl, syl
									make_set_ctx(varctx, line, syl, "s")
									newline.text ..= run_text_template(t.t, tenv, varctx)
									if t.addtext
										if t.keeptags
											newline.text ..= syl.text
										else
											newline.text ..= syl.text_stripped
						else
							-- hmm, no main template for the line... put original text in
							if t.addtext
								if t.keeptags
									newline.text ..= line.text
								else
									newline.text ..= line.text_stripped
						newline.effect = "fx"
						subs.append(newline)
    aegisub.debug.out(5, "Done running line templates\n\n")

    -- Loop over syllables
    for i = 0, line.kara.n
        break if aegisub.progress.is_cancelled!
        syl = line.kara[i]
        aegisub.debug.out(5, "Applying templates to syllable: %s\n", syl.text)
        if apply_syllable_templates(syl, "syl", line, templates.syl, tenv, varctx, subs)
            applied_templates = true

	-- Loop over charlables
    for i = 1, line.chars.n
        break if aegisub.progress.is_cancelled!
        char = line.chars[i]
        tenv.syl = char.syl or nil
        tenv.word = char.word
        aegisub.debug.out(5, "Applying templates to charlable: %s\n", char.text)
        if apply_syllable_templates(char, "char", line, templates.char, tenv, varctx, subs)
            applied_templates = true

	-- Loop over wordlables
    for i = 1, line.words.n
        break if aegisub.progress.is_cancelled!
        word = line.words[i]
        aegisub.debug.out(5, "Applying templates to wordlable: %s\n", word.text)
        if apply_syllable_templates(word, "word", line, templates.word, tenv, varctx, subs)
            applied_templates = true

    -- Loop over furigana
    for i = 1, line.furi.n
        break if aegisub.progress.is_cancelled!
        furi = line.furi[i]
        aegisub.debug.out(5, "Applying templates to furigana: %s\n", furi.text)
        if apply_syllable_templates(furi, "syl", line, templates.furi, tenv, varctx, subs)
            applied_templates = true

    return applied_templates

run_code_template = (template, tenv) ->
    f, err = loadstring(template.code, "template code")
    unless f
        aegisub.debug.out(2, "Failed to parse Lua code: %s\nCode that failed to parse: %s\n\n", err, template.code)
    else
        pcall = pcall
        setfenv(f, tenv)
		for k, maxk in template_loop(tenv, template.loops[3], "k")
			for i, maxi in template_loop(tenv, template.loops[2], "i")
				for j, maxj in template_loop(tenv, template.loops[1], "j")
					res, err = pcall(f)
					aegisub.debug.out(2, "Runtime error in template code: %s\nCode producing error: %s\n\n", err, template.code) unless res

run_text_template = (template, tenv, varctx) ->
    res = template
    aegisub.debug.out(5, "Running text template '%s'\n", res)
    -- Replace the variables in the string (this is probably faster than using a custom function, but doesn't provide error reporting)
    if varctx
        aegisub.debug.out(5, "Has varctx, replacing variables\n")
        var_replacer = (varname) ->
            varname = varname\lower!
            aegisub.debug.out(5, "Found variable named '%s', ", varname)
            if varctx[varname] != nil
                aegisub.debug.out(5, "it exists, value is '%s'\n", varctx[varname])
                varctx[varname]
            else
                aegisub.debug.out(5, "doesn't exist\n")
                aegisub.debug.out(2, "Unknown variable name: %s\nIn karaoke template: %s\n\n", varname, template)
                "$#{varname}"
        res = res\gsub "$([%a_]+)", var_replacer
        aegisub.debug.out(5, "Done replacing variables, new template string is '%s'\n", res)
    -- Function for evaluating expressions
    expression_evaluator = (expression) ->
        f, err = loadstring(("return (%s)")\format(expression))
        if err != nil
            aegisub.debug.out(2, "Error parsing expression: %s\nExpression producing error: %s\nTemplate with expression: %s\n\n", err, expression, template)
            return "!#{expression}!"
        else
            setfenv(f, tenv)
            res, val = pcall(f)
            if res
                return val
            else
                aegisub.debug.out(2, "Runtime error in template expression: %s\nExpression producing error: %s\nTemplate with expression: %s\n\n", val, expression, template)
                return "!#{expression}!"
    -- Find and evaluate expressions
    aegisub.debug.out(5, "Now evaluating expressions\n")
    res = res\gsub "!(.-)!", expression_evaluator
    aegisub.debug.out(5, "After evaluation: %s\nDone handling template\n\n", res)
    return res

apply_syllable_templates = (syl, __type, line, templates, tenv, varctx, subs) ->
    __type or= "syl"
    applied = 0
    -- Loop over all templates matching the line style
    for t in matching_templates(templates, line, tenv)
        break if aegisub.progress.is_cancelled!
        tenv[__type] = syl
        tenv["base#{__type}"] = syl
        make_set_ctx(varctx, line, syl, __type\match "%a")
        applied += apply_one_syllable_template(syl, line, __type, t, tenv, varctx, subs, false)
    return applied > 0

is_syl_blank = (syl) ->
    return true if syl.duration <= 0
    -- try to remove common spacing characters
    t = syl.text_stripped
    return true if t\len! <= 0
    t = t\gsub("[ \t\n\r]", "") -- regular ASCII space characters
    t = t\gsub("　", "") -- fullwidth space
    return t\len! <= 0

apply_one_syllable_template = (syl, line, __type, template, tenv, varctx, subs, skip_multi) ->
    return 0 if aegisub.progress.is_cancelled!
    t, applied = template, 0
    aegisub.debug.out(5, "Applying template to one syllable with text: %s\n", syl.text)
    -- Check for right inline_fx
    if t.fx and t.fx != syl.inline_fx
        aegisub.debug.out(5, "Syllable has wrong inline-fx (wanted '%s', got '%s'), skipping.\n", t.fx, syl.inline_fx)
        return 0
    if t.noblank and is_syl_blank(syl)
        aegisub.debug.out(5, "Syllable is blank, skipping.\n")
        return 0
    -- Recurse to multi-hl if required
    if not skip_multi and t.multi
        aegisub.debug.out(5, "Doing multi-highlight effects...\n")
        hlsyl = table.copy(syl)
        tenv.syl = hlsyl
        idx = (syl.highlights == nil and syl.syl.highlights or syl.highlights)
        for hl = 1, idx.n
            hldata = idx[hl]
            hlsyl.start_time = hldata.start_time
            hlsyl.end_time = hldata.end_time
            hlsyl.duration = hldata.duration
            make_set_ctx(varctx, line, hlsyl, __type\match("%a"))
            applied += apply_one_syllable_template(hlsyl, line, __type, t, tenv, varctx, subs, true)
        return applied
    -- Regular processing
    if t.code
        aegisub.debug.out(5, "Running code line\n")
        tenv.line = line
        run_code_template(t, tenv)
    else
        aegisub.debug.out(5, "Running %d effect loops\n", t.loops)
		for k, maxk in template_loop(tenv, t.loops[3], "k")
			for i, maxi in template_loop(tenv, t.loops[2], "i")
				for j, maxj in template_loop(tenv, t.loops[1], "j")
					newline = table.copy(line)
					newline.styleref = syl.style
					newline.style = syl.style.name
					newline.layer = t.layer
					tenv.line = newline
					newline.text = run_text_template(t.t, tenv, varctx)
					if t.keeptags
						newline.text ..= syl.text
					elseif t.addtext
						newline.text ..= syl.text_stripped
					newline.effect = "fx"
					aegisub.debug.out(5, "Generated line with text: %s\n", newline.text)
					subs.append(newline)
					applied += 1
    return applied

-- Main function to do the templating
filter_apply_templates = (subs) ->
    aegisub.progress.task("Collecting header data...")
    meta, styles = karaskel.collect_head(subs, true)

    aegisub.progress.task("Parsing templates...")
    templates = parse_templates(subs)

    aegisub.progress.task("Applying templates...")
    apply_templates(meta, styles, subs, templates)

macro_apply_templates = (subs, sel) ->
    filter_apply_templates(subs)
    aegisub.set_undo_point("apply karaoke template")

macro_can_template = (subs) ->
    -- check if this file has templates in it, don't allow running the macro if it hasn't
    num_dia = 0
    for s in *subs
        with s
            if .class == "dialogue"
                num_dia += 1
                -- test if the line is a template
                return true if (string.headtail(.effect))\lower! == "template"
                -- don't try forever, this has to be fast
                return false if num_dia > 50
    false

aegisub.register_macro "Apply karaoke template - Mod", script_mod_description, macro_apply_templates, macro_can_template