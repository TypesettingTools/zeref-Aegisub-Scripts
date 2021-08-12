export script_name        = "Interpolate Master"
export script_description = "Does a linear interpolation between values of the first and last selected line"
export script_author      = "Zeref"
export script_version     = "0.0.2"
-- LIB
zf = require "ZF.main"

tags_full = {
    "bord", "xbord", "ybord", "be", "shad", "xshad", "yshad", "blur"
    "fs", "fscx", "fscy", "fsp"
    "frx", "fry", "frz", "fax", "fay"
    "_c", "_2c", "_3c", "_4c", "_1a", "_2a", "_3a", "_4a", "alpha"
    "pos", "org", "clip"
}

split_tags = (text) -> -- Splits text into text and tags
    v = {tg: {}, tx: {}}
    v.tg = [t for t in text\gmatch "%b{}"]
    while text != ""
        c, d = zf.util\headtail(text, "%b{}")
        v.tx[#v.tx + 1] = c
        text = d
    return v

concat_4 = (t) -> -- Concatenates tables that have subtables
    nt = {}
    sizes = [#t[i] for i = 1, #t]
    table.sort(sizes, (a, b) -> a > b)
    for i = 1, sizes[1] or 0
        nt[i] = ""
        for k = 1, #t
            nt[i] ..= t[k][i] or ""
    return nt

table_len = (t) -> -- get the real length of the table
    count = 0
    for k, v in pairs t
        count += 1
    return count

interpolation = (first, last, loop, accel = 1, tags = "") -> -- Interpolates any possible tag
    t, ipol = {tostring(first),  tostring(last)}, {}
    pol = interpolate
    for v in *t
        if v\match "&?[Hh]%x%x%x%x%x%x&?"
            pol = interpolate_color
        elseif v\match "&?[Hh]%x%x&?"
            pol = interpolate_alpha
    if t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")
        fx, fy = t[1]\match "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        lx, ly = t[2]\match "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        fx, fy, lx, ly = tonumber(fx), tonumber(fy), tonumber(lx), tonumber(ly)
        for k = 1, loop
            px = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fx, lx)
            py = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fy, ly)
            ipol[#ipol + 1] = "\\pos(#{px},#{py})"
    elseif (not t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")) or (t[1]\match("\\pos%b()") and not t[2]\match("\\pos%b()"))
        error "You must have the \\pos in both positions"
    elseif t[1]\match("\\org%b()") and t[2]\match("\\org%b()")
        fx, fy = t[1]\match "\\org%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        lx, ly = t[2]\match "\\org%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        fx, fy, lx, ly = tonumber(fx), tonumber(fy), tonumber(lx), tonumber(ly)
        for k = 1, loop
            px = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fx, lx)
            py = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fy, ly)
            ipol[#ipol + 1] = "\\org(#{px},#{py})"
    elseif (not t[1]\match("\\org%b()") and t[2]\match("\\org%b()")) or (t[1]\match("\\org%b()") and not t[2]\match("\\org%b()"))
        error "You must have the \\org in both positions"
    elseif t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")
        first_cp, last_cp = {}, {}
        _type_ = (t[1]\match("\\iclip") or t[2]\match("\\iclip")) and "iclip" or "clip"
        cap_rectangle = "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        cap_vector = "\\i?clip%((m%s+%-?%d[%.%-%d mlb]*)%)"
        if not t[1]\match(cap_vector) and not t[2]\match(cap_vector)
            fl, ft, fr, fb = t[1]\match(cap_rectangle)
            ll, lt, lr, lb = t[2]\match(cap_rectangle)
            fl, ft, fr, fb = tonumber(fl), tonumber(ft), tonumber(fr), tonumber(fb)
            ll, lt, lr, lb = tonumber(ll), tonumber(lt), tonumber(lr), tonumber(lb)
            for k = 1, loop
                l = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fl, ll)
                t = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", ft, lt)
                r = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fr, lr)
                b = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "number", fb, lb)
                ipol[#ipol + 1] = "\\#{_type_}(#{l},#{t},#{r},#{b})"
        elseif not t[1]\match(cap_vector) and t[2]\match(cap_vector)
            f = zf.util\clip_to_draw t[1]\match("\\i?clip%b()")
            l = t[2]\match(cap_vector)
            for k = 1, loop
                s = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "shape", f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
        elseif t[1]\match(cap_vector) and not t[2]\match(cap_vector)
            f = t[1]\match(cap_vector)
            l = zf.util\clip_to_draw t[2]\match("\\i?clip%b()")
            for k = 1, loop
                s = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "shape", f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
        else
            f = t[1]\match(cap_vector)
            l = t[2]\match(cap_vector)
            for k = 1, loop
                s = zf.util\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, "shape", f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
    elseif (not t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")) or (t[1]\match("\\i?clip%b()") and not t[2]\match("\\i?clip%b()"))
        error "You must have the (\\clip - \\iclip) in both positions"
    else
        for k = 1, loop
            if not first and not last
                ipol[#ipol + 1] = ""
            else
                ipol[#ipol + 1] = tags .. pol((k - 1) ^ accel / (loop - 1) ^ accel, first, last)
    return ipol

class ipol -- Class for macro main settings

    new: (text_f, text_l, n, style_tags, elements, old, mac) =>
        text_f = text_f\gsub("\\1c", "\\c")\gsub("\\frz?", "\\frz")\gsub("\\t%b()", "")
        text_l = text_l\gsub("\\1c", "\\c")\gsub("\\frz?", "\\frz")\gsub("\\t%b()", "")
        a = text_f\gsub("%s+", "")\find("%b{}")
        b = text_l\gsub("%s+", "")\find("%b{}")
        text_f = (a != 1) and "{}#{text_f}" or text_f
        text_l = (b != 1) and "{}#{text_l}" or text_l
        @info_v = {:text_f, :text_l, :old, :mac, backup_t: {}}
        @info_v.f = split_tags(text_f)
        @info_v.l = split_tags(text_l)
        @tags_id = {f: {}, l: {}, ipol: {}, :n, :elements, styles: style_tags}

    tags_splitter: => -- Organizes the tags from the selected tags in the macro and removes the old values from them
        split = (t, ivf) ->
            for _, i in pairs(tags_full)
                if @tags_id.elements[i]
                    tif = t[i]
                    if i\match("_") or (i == "alpha")
                        i = i\gsub("_", "")
                        if i\match("\\%da") or (i == "alpha")
                            tif = ivf\match("\\#{i}%s*&?[Hh]%x%x&?") and ivf\match("\\#{i}%s*(&?[Hh]%x%x&?)") or nil
                            ivf = ivf\gsub("\\#{i}%s*&?[Hh]%x%x&?", "")
                        else
                            tif = ivf\match("\\#{i}%s*&?[Hh]%x%x%x%x%x%x&?") and ivf\match("\\#{i}%s*(&?[Hh]%x%x%x%x%x%x&?)") or nil
                            ivf = ivf\gsub("\\#{i}%s*&?[Hh]%x%x%x%x%x%x&?", "")
                            ivf = ivf\gsub("\\1c%s*&?[Hh]%x%x%x%x%x%x&?", "") if (i == "c")
                    elseif (i == "pos") or (i == "org") or (i == "clip")
                        tif = ivf\match("\\i?#{i}%b()")
                        ivf = ivf\gsub("\\i?#{i}%b()", "")
                    else
                        tif = ivf\match("\\#{i}%s*%-?%d[%.%d]*") and tonumber(ivf\match("\\#{i}%s*(%-?%d[%.%d]*)")) or nil
                        ivf = ivf\gsub("\\#{i}%s*%-?%d[%.%d]*", "")
                        ivf = ivf\gsub("\\fr%s*%-?%d[%.%d]*", "") if (i == "frz")
                    t[i] = tif
            return ivf
        for j = 1, #@info_v.old
            @info_v.backup_t[j] = {}
            for k = 1, #@info_v.old[j].tg
                ivf = @info_v.old[j].tg[k]
                @info_v.backup_t[j][k] = {}
                @info_v.backup_t[j][k] = [t for t in ivf\gmatch "\\t%b()"]
                ivf = ivf\gsub "\\t%b()", ""
                ivf = split({}, ivf)
                @info_v.old[j].tg[k] = ivf
        for k = 1, #@info_v.f.tg
            ivf = @info_v.f.tg[k]
            @tags_id.f[k] = {}
            split(@tags_id.f[k], ivf)
        for k = 1, #@info_v.l.tg
            ivf = @info_v.l.tg[k]
            @tags_id.l[k] = {}
            split(@tags_id.l[k], ivf)

    tags_ipol: => -- interpolates the selected tags
        @tags_splitter!
        interpol, len = {}, #@tags_id.f > #@tags_id.l and #@tags_id.f or #@tags_id.l
        for i = 1, len
            @tags_id.ipol[i] = {}
            if @tags_id.f[i]
                continue if @tags_id.ipol[i][k]
                for k, v in pairs(@tags_id.f[i])
                    k = k\gsub("_", "")
                    fix_color = (k\find("%d") == 1 or k == "c") and "_#{k}" or k
                    if (@tags_id.f[i][k] and not @tags_id.l[i]) or (@tags_id.f[i][k] and (@tags_id.l[i] and not @tags_id.l[i][k]))
                        @tags_id.ipol[i][k] = interpolation(@tags_id.f[i][k], @tags_id.styles.last[fix_color], @tags_id.n, @tags_id.elements.acc, "\\#{k}")
                    elseif @tags_id.f[i][k] and (@tags_id.l[i] and @tags_id.l[i][k])
                        @tags_id.ipol[i][k] = interpolation(@tags_id.f[i][k], @tags_id.l[i][k], @tags_id.n, @tags_id.elements.acc, "\\#{k}")
            if @tags_id.l[i]
                continue if @tags_id.ipol[i][k]
                for k, v in pairs(@tags_id.l[i])
                    k = k\gsub("_", "")
                    fix_color = (k\find("%d") == 1 or k == "c") and "_#{k}" or k
                    if (@tags_id.l[i][k] and not @tags_id.f[i]) or (@tags_id.l[i][k] and (@tags_id.f[i] and not @tags_id.f[i][k]))
                        @tags_id.ipol[i][k] = interpolation(@tags_id.styles.first[fix_color], @tags_id.l[i][k], @tags_id.n, @tags_id.elements.acc, "\\#{k}")
                    elseif @tags_id.l[i][k] and (@tags_id.f[i] and @tags_id.f[i][k])
                        @tags_id.ipol[i][k] = interpolation(@tags_id.f[i][k], @tags_id.l[i][k], @tags_id.n, @tags_id.elements.acc, "\\#{k}")

    make_tags: => -- Organizes the output of the ready-made tags
        @tags_ipol!
        tags, final = {}, {}
        ps = #@info_v.f.tx > #@info_v.l.tx and @info_v.f.tx or @info_v.l.tx
        table.remove(ps, 1) if ps[1] == ""
        for i = 1, #ps
            tags[i], final[i] = {}, ""
            if (@tags_id.ipol[i] and table_len(@tags_id.ipol[i]) == 0) or not @tags_id.ipol[i]
                tags[i][#tags[i] + 1] = interpolation(nil, nil, @tags_id.n)
            else
                tags[i][#tags[i] + 1] = v for k, v in pairs(@tags_id.ipol[i])
            tags[i] = concat_4 tags[i]
            if @tags_id.elements.igt
                for j = 1, #tags[i]
                    old_tags = (@info_v.old[j].tg[i] or "")\sub(2, -2)
                    old_tags ..= table.concat(@info_v.backup_t[j][i] or {})
                    tags[i][j] = ("{#{tags[i][j] .. old_tags}}#{ps[i]}")\gsub("{}", "", 1)
        if not @tags_id.elements.igt
            for i = 1, #tags[1]
                text = @info_v.mac[i]
                a = text\gsub("%s+", "")\find("%b{}")
                text = (a != 1) and "{}#{text}" or text
                old_tags = (@info_v.old[i].tg[1] or "")\sub(2, -2)
                old_tags ..= table.concat(@info_v.backup_t[i][1] or {})
                text = "{#{tags[1][i] .. old_tags}}" .. text\gsub("%b{}", "", 1)
                @info_v.mac[i] = text
            return @info_v.mac
        else
            return concat_4 tags

class build_macro -- Output function, just set some dependencies and return the build

    new: (subs, sel) =>
        @sb, @sl = subs, sel
        @sel_lines = [subs[i] for _, i in ipairs(sel)]
        @sel_first, @sel_last = @sel_lines[1], @sel_lines[#@sel_lines]

    style_ref: =>
        meta, styles = karaskel.collect_head(@sb)
        karaskel.preproc_line(@sb, meta, styles, @sel_first)
        karaskel.preproc_line(@sb, meta, styles, @sel_last)
        cfs, afs = util.color_from_style, util.alpha_from_style
        @style_values = {
            first: {
                bord: @sel_first.styleref.outline, xbord: 0, ybord: 0
                be: 0, shad: @sel_first.styleref.shadow, xshad: 0
                yshad: 0, blur: 0, fs: @sel_first.styleref.fontsize
                fscx: @sel_first.styleref.scale_x, fscy: @sel_first.styleref.scale_x
                fsp: @sel_first.styleref.spacing, frx: 0, fry: 0
                frz: @sel_first.styleref.angle, fax: 0, fay: 0
                _c:  cfs(@sel_first.styleref.color1)
                _2c: cfs(@sel_first.styleref.color2)
                _3c: cfs(@sel_first.styleref.color3)
                _4c: cfs(@sel_first.styleref.color4)
                _1a: afs(@sel_first.styleref.color1)
                _2a: afs(@sel_first.styleref.color2)
                _3a: afs(@sel_first.styleref.color3)
                _4a: afs(@sel_first.styleref.color4)
            }
            last: {
                bord: @sel_last.styleref.outline, xbord: 0, ybord: 0
                be: 0, shad: @sel_last.styleref.shadow, xshad: 0
                yshad: 0, blur: 0, fs: @sel_last.styleref.fontsize
                fscx: @sel_last.styleref.scale_x, fscy: @sel_last.styleref.scale_x
                fsp: @sel_last.styleref.spacing, frx: 0, fry: 0
                frz: @sel_last.styleref.angle, fax: 0, fay: 0
                _c:  cfs(@sel_last.styleref.color1)
                _2c: cfs(@sel_last.styleref.color2)
                _3c: cfs(@sel_last.styleref.color3)
                _4c: cfs(@sel_last.styleref.color4)
                _1a: afs(@sel_last.styleref.color1)
                _2a: afs(@sel_last.styleref.color2)
                _3a: afs(@sel_last.styleref.color3)
                _4a: afs(@sel_last.styleref.color4)
            }
        }

    text_ref: (other) =>
        local old
        if other
            old = [v.text for k, v in ipairs @sel_lines]
        else
            old = [split_tags(v.text) for k, v in ipairs @sel_lines]
        return old

    out: =>
        @style_ref!
        inter = zf.config\load(zf.config\interface(script_name)(tags_full), script_name)
        local buttons, elements
        while true
            buttons, elements = aegisub.dialog.display(inter, {"Ok", "Save", "Reset", "Cancel"}, {close: "Cancel"})
            inter = switch buttons
                when "Save"
                    zf.config\save(inter, elements, script_name, script_version)
                    zf.config\load(inter, script_name)
                when "Reset"
                    zf.config\interface(script_name)(tags_full)
            break if buttons == "Ok" or buttons == "Cancel"
        make_ipol = ipol(@sel_first.text, @sel_last.text, #@sel_lines, @style_values, elements, @text_ref!, @text_ref(true))
        split, box_true = make_ipol\make_tags!, {}
        box_true[#box_true + 1] = (v == true) or nil for k, v in pairs elements
        if buttons == "Ok"
            if #box_true > 0
                for k, v in ipairs @sl
                    l = @sb[v]
                    text = l.text
                    l.text = split[k]
                    @sb[v] = l
            else
                aegisub.cancel!
        else
            aegisub.cancel!
        return

main = (subs, sel) -> -- Only function to store the class construct for the Aegisub API to recognize
    build_macro(subs, sel)\out!
    return

enable = (subs, sel) -> -- Activates the macro when it has more than 2 or more selections
    return (#sel > 1) and true or false

aegisub.register_macro script_name, script_description, main, enable