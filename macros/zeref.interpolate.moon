export script_name        = "Interpolate Master"
export script_description = "Does a linear interpolation between values of the first and last selected line"
export script_author      = "Zeref"
export script_version     = "1.0.3"
-- LIB
zf = require "ZF.utils"

tags_full = {
    "bord", "xbord", "ybord", "be", "shad", "xshad", "yshad", "blur"
    "fs", "fscx", "fscy", "fsp"
    "frx", "fry", "frz", "fax", "fay"
    "_c", "_2c", "_3c", "_4c", "_1a", "_2a", "_3a", "_4a", "alpha"
    "pos", "org", "clip"
}

interface = ->
    gui = {}
    tags_mask = [zf.table\slice(tags_full, k, k + 4) for k = 1, #tags_full, 5]
    for k = 1, #tags_mask
        for j = 1, #tags_mask[k]
            gui[#gui + 1] = {
                class: "checkbox"
                label: tags_mask[k][j]\gsub("_", "")
                name: tags_mask[k][j]
                x: (k - 1)
                y: (j - 1)
                value: false
            }
    gui[#gui + 1] = {class: "checkbox", label: "Ignore Text", name: "igt", x: 0, y: 6, value: false}
    gui[#gui + 1] = {class: "label", label: "::Accel::", x: 0, y: 7}
    gui[#gui + 1] = {class: "floatedit", name: "acc", min: 0, x: 0, y: 8, value: 1}
    return gui

SAVECONFIG = (gui, elements) ->
    ngui = table.copy(gui)
    vals_write = "INTERPOLATE MASTER - VERSION #{script_version}\n\n"
    for k = 1, #tags_full
        ngui[k].value = elements[tags_full[k]]
    ngui[30].value = elements["igt"]
    ngui[32].value = elements["acc"]
    for k, v in ipairs ngui
        vals_write ..= "{#{v.name} = #{v.value}}\n" if v.name
    dir = aegisub.decode_path("?user")
    unless zf.util\file_exist("#{dir}\\zeref-cfg", true)
        os.execute("mkdir #{dir .. "\\zeref-cfg"}") -- create folder zeref-cfg
    cfg_save = "#{dir}\\zeref-cfg\\interpolate_master.cfg"
    file = io.open cfg_save, "w"
    file\write vals_write
    file\close!
    return

READCONFIG = (filename) ->
    SEPLINES = (val) ->
        sep_vals = {n: {}, v: {}}
        for k = 1, #val
            sep_vals.n[k] = val[k]\gsub "(.+) %= .+", (vls) ->
                vls\gsub "%s+", ""
            rec_names = sep_vals.n[k]
            sep_vals.v[rec_names] = val[k]\gsub ".+ %= (.+)", (vls) ->
                vls\gsub "%s+", ""
        return sep_vals
    if filename
        arq = io.open filename, "r"
        if arq != nil
            read = arq\read "*a"
            io.close arq
            lines = [k for k in read\gmatch "(%{[^\n]+%})"]
            for j = 1, #lines do lines[j] = lines[j]\sub(2, -2)
            return SEPLINES(lines), true
    return _, false

LOADCONFIG = (gui) ->
    load_config = aegisub.decode_path("?user") .. "\\zeref-cfg\\interpolate_master.cfg"
    read_config, rdn = READCONFIG load_config
    new_gui = table.copy gui
    if rdn != false
        for k = 1, #tags_full
            new_gui[k].value = (read_config.v[tags_full[k]] == "true") and true or false
        new_gui[30].value = (read_config.v.igt == "true") and true or false
        new_gui[32].value = tonumber read_config.v.acc
    return new_gui

split_tags = (text) -> -- Divide o texto em textos e tags
    values = {tags: {}, text: {}}
    values.tags = [t for t in text\gmatch "%b{}"]
    string.headtail = (s, div) ->
        a, b, head, tail = s\find("(.-)#{div}(.*)")
        if a then head, tail else s, ""
    while text != ""
        c, d = text\headtail("%b{}")
        values.text[#values.text + 1] = c
        text = d
    return values

concat_4 = (t) -> -- Concatenates tables that have subtables
    re_index = {}
    sizes = [#t[i] for i = 1, #t]
    table.sort(sizes, (a, b) -> a > b)
    for i = 1, sizes[1] or 0
        re_index[i] = ""
        for k = 1, #t
            re_index[i] ..= (t[k][i] or "")
    return re_index

interpolation = (first, last, loop, accel = 1, tags = "") -> -- Interpolates any possible tag
    t, ipol = {tostring(first),  tostring(last)}, {}
    interpolate_shape = (pct, f, l) ->
        fs = [tonumber(s) for s in f\gmatch "%-?%d[%.%d]*"]
        ls = [tonumber(s) for s in l\gmatch "%-?%d[%.%d]*"]
        if #fs != #ls
            error("The shapes must have the same stitch length")
        else
            j = 1
            f = f\gsub "%-?%d[%.%d]*", (s) ->
                s = zf.math\interpolation(pct, fs[j], ls[j])
                j += 1
                return s
            return f
    pol = (pct, first, last) -> zf.math\interpolation(pct, first, last)
    for k = 1, #t
        if t[k]\match "&?[Hh]%x%x%x%x%x%x&?"
            pol = interpolate_color
        elseif t[k]\match "&?[Hh]%x%x&?"
            pol = interpolate_alpha
    if t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")
        fx, fy = t[1]\match "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        lx, ly = t[2]\match "\\pos%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        fx, fy, lx, ly = tonumber(fx), tonumber(fy), tonumber(lx), tonumber(ly)
        for k = 1, loop
            px = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fx, lx)
            py = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fy, ly)
            ipol[#ipol + 1] = "\\pos(#{px},#{py})"
    elseif (not t[1]\match("\\pos%b()") and t[2]\match("\\pos%b()")) or (t[1]\match("\\pos%b()") and not t[2]\match("\\pos%b()"))
        error("You must have the \\pos in both positions")
    elseif t[1]\match("\\org%b()") and t[2]\match("\\org%b()")
        fx, fy = t[1]\match "\\org%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        lx, ly = t[2]\match "\\org%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        fx, fy, lx, ly = tonumber(fx), tonumber(fy), tonumber(lx), tonumber(ly)
        for k = 1, loop
            px = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fx, lx)
            py = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fy, ly)
            ipol[#ipol + 1] = "\\org(#{px},#{py})"
    elseif (not t[1]\match("\\org%b()") and t[2]\match("\\org%b()")) or (t[1]\match("\\org%b()") and not t[2]\match("\\org%b()"))
        error("You must have the \\org in both positions")
    elseif t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")
        first_cp, last_cp = {}, {}
        _type_ = (t[1]\match("\\iclip") or t[2]\match("\\iclip")) and "iclip" or "clip"
        cap_rectangle = "\\i?clip%(%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*,%s*(%-?%d[%.%d]*)%s*%)"
        cap_vector = "\\i?clip%((m%s+%-?%d+[%.%d]*%s+%-?%d+[%.%-%dmlb ]*)%)"
        if not t[1]\match(cap_vector) and not t[2]\match(cap_vector)
            fl, ft, fr, fb = t[1]\match(cap_rectangle)
            ll, lt, lr, lb = t[2]\match(cap_rectangle)
            fl, ft, fr, fb = tonumber(fl), tonumber(ft), tonumber(fr), tonumber(fb)
            ll, lt, lr, lb = tonumber(ll), tonumber(lt), tonumber(lr), tonumber(lb)
            for k = 1, loop
                l = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fl, ll)
                t = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, ft, lt)
                r = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fr, lr)
                b = zf.math\interpolation((k - 1) ^ accel / (loop - 1) ^ accel, fb, lb)
                ipol[#ipol + 1] = "\\#{_type_}(#{l},#{t},#{r},#{b})"
        elseif not t[1]\match(cap_vector) and t[2]\match(cap_vector)
            f = zf.util\clip_to_draw t[1]\match("\\i?clip%b()")
            l = t[2]\match(cap_vector)
            for k = 1, loop
                s = interpolate_shape((k - 1) ^ accel / (loop - 1) ^ accel, f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
        elseif t[1]\match(cap_vector) and not t[2]\match(cap_vector)
            f = t[1]\match(cap_vector)
            l = zf.util\clip_to_draw t[2]\match("\\i?clip%b()")
            for k = 1, loop
                s = interpolate_shape((k - 1) ^ accel / (loop - 1) ^ accel, f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
        else
            f = t[1]\match(cap_vector)
            l = t[2]\match(cap_vector)
            for k = 1, loop
                s = interpolate_shape((k - 1) ^ accel / (loop - 1) ^ accel, f, l)
                ipol[#ipol + 1] = "\\#{_type_}(#{s})"
    elseif (not t[1]\match("\\i?clip%b()") and t[2]\match("\\i?clip%b()")) or (t[1]\match("\\i?clip%b()") and not t[2]\match("\\i?clip%b()"))
        error("You must have the (\\clip - \\iclip) in both positions")
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
                            ivf = ivf\gsub("\\1c%s*&?[Hh]%x%x%x%x%x%x&?", "") if i == "c"
                    elseif (i == "pos") or (i == "org") or (i == "clip")
                        tif = ivf\match("\\i?#{i}%b()")
                        ivf = ivf\gsub("\\i?#{i}%b()", "")
                    else
                        tif = ivf\match("\\#{i}%s*%-?%d[%.%d]*") and tonumber(ivf\match("\\#{i}%s*(%-?%d[%.%d]*)")) or nil
                        ivf = ivf\gsub("\\#{i}%s*%-?%d[%.%d]*", "")
                        ivf = ivf\gsub("\\fr%s*%-?%d[%.%d]*", "") if i == "frz"
                    t[i] = tif
            return ivf
        for j = 1, #@info_v.old
            @info_v.backup_t[j] = {}
            for k = 1, #@info_v.old[j].tags
                ivf = @info_v.old[j].tags[k]
                @info_v.backup_t[j][k] = {}
                @info_v.backup_t[j][k] = [t for t in ivf\gmatch "\\t%b()"]
                ivf = ivf\gsub "\\t%b()", ""
                ivf = split({}, ivf)
                @info_v.old[j].tags[k] = ivf
        for k = 1, #@info_v.f.tags
            ivf = @info_v.f.tags[k]
            @tags_id.f[k] = {}
            split(@tags_id.f[k], ivf)
        for k = 1, #@info_v.l.tags
            ivf = @info_v.l.tags[k]
            @tags_id.l[k] = {}
            split(@tags_id.l[k], ivf)

    tags_ipol: => -- interpolates the selected tags
        @tags_splitter!
        interpol, len = {}, #@tags_id.f > #@tags_id.l and #@tags_id.f or #@tags_id.l
        for i = 1, len
            @tags_id.ipol[i] = {}
            if @tags_id.f[i]
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
        ps = #@info_v.f.text > #@info_v.l.text and @info_v.f.text or @info_v.l.text
        table.remove(ps, 1) if ps[1] == ""
        for i = 1, #ps
            tags[i], final[i] = {}, ""
            if (@tags_id.ipol[i] and zf.table\len(@tags_id.ipol[i], "other") == 0) or not @tags_id.ipol[i]
                tags[i][#tags[i] + 1] = interpolation(nil, nil, @tags_id.n)
            else
                tags[i][#tags[i] + 1] = v for k, v in pairs(@tags_id.ipol[i])
            tags[i] = concat_4 tags[i]
            for j = 1, #tags[i]
                if @tags_id.elements.igt
                    old_tags = (@info_v.old[j].tags[i] or "")\sub(2, -2)
                    old_tags ..= table.concat(@info_v.backup_t[j][i] or {})
                    tags[i][j] = ("{#{tags[i][j] .. old_tags}}#{ps[i]}")\gsub("{}", "", 1)
        if not @tags_id.elements.igt
            for i = 1, #tags[1]
                text = @info_v.mac[i]
                a = text\gsub("%s+", "")\find("%b{}")
                text = (a != 1) and "{}#{text}" or text
                old_tags = (@info_v.old[i].tags[1] or "")\sub(2, -2)
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
        inter, add = LOADCONFIG(interface!), 0
        local button, elements
        while true
            button, elements = aegisub.dialog.display(inter, {"Run", "Run - Save", "Reset", "Close"}, {close: "Close"})
            inter = interface! if button == "Reset"
            break if button == "Run" or button == "Run - Save" or button == "Close"
        make_ipol = ipol(@sel_first.text, @sel_last.text, #@sel_lines, @style_values, elements, @text_ref!, @text_ref(true))
        split, box_true = make_ipol\make_tags!, {}
        box_true[#box_true + 1] = (v == true) or nil for k, v in pairs elements
        if (button == "Run") or (button == "Run - Save")
            SAVECONFIG(inter, elements) if (button == "Run - Save")
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
return
