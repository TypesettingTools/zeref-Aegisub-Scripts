class TAGS

    new: (tags) => @tags = tags

    -- returns the contents of a tag
    find: => if @tags\match("%b{}") then @tags\match("%b{}")\sub(2, -2) else ""

    -- cleans the tags
    clean: (text) =>
        require "cleantags"
        return cleantags text

    -- returns a table containing tag captures
    get: (full = true) ->
        list_0 = {
            fn: "\\fn%s*[^\\}]*",               fs: "\\fs%s*%d[%.%d]*",          fsp: "\\fsp%s*%-?%d[%.%d]*"
            fscx: "\\fscx%s*%d[%.%d]*",         fscy: "\\fscy%s*%d[%.%d]*",      b: "\\b%s*%d"
            i: "\\i%s*%d",                      s: "\\s%s*%d",                   u: "\\u%s*%d"
            p: "\\p%s*%d",                      an: "\\an%s*%d",                 fr: "\\frz?%s*%-?%d+[%.%d]*"
            frx: "\\frx%s*%-?%d+[%.%d]*",       fry: "\\fry%s*%-?%d+[%.%d]*",    fax: "\\fax%s*%-?%d+[%.%d]*"
            fay: "\\fay%s*%-?%d+[%.%d]*",       pos: "\\pos%b()",                org: "\\org%b()"
            _1c: "\\1?c%s*&?[Hh]%x+&?",         _2c: "\\2c%s*&?[Hh]%x+&?",       _3c: "\\3c%s*&?[Hh]%x+&?"
            _4c: "\\4c%s*&?[Hh]%x+&?",          bord: "\\[xy]?bord%s*%d[%.%d]*", clip: "\\i?clip%b()"
            shad: "\\[xy]?shad%s*%-?%d[%.%d]*", move:"\\move%b()",               transform: "\\t%b()"
        }
        list_1 = {
            list_0.fn, list_0.fs, list_0.fsp, list_0.fscx, list_0.fscy, list_0.b
            list_0.i, list_0.s, list_0.u, list_0.an, list_0.fr, list_0.frx, list_0.fry
            list_0.fax, list_0.fay, list_0._1c, list_0._2c, list_0._3c, list_0._4c
            list_0.bord, list_0.shad, list_0.transform
        }
        return full and list_0 or list_1

    -- removes some tags by need
    remove: (modes = "full", tags) =>
        @tags = tags or @find!
        caps = @get!
        switch modes
            when "shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")
                @tags = @tags\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "envelope"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")
                @tags = @tags\gsub(caps.an, "\\an7")\gsub(caps.b, "")\gsub(caps.i, "")
                @tags = @tags\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1"  unless @tags\match(caps.p)
            when "shape_poly"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.an, "\\an7")\gsub(caps.b, "")\gsub(caps.i, "")
                @tags = @tags\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1"  unless @tags\match(caps.p)
            when "text_gradient"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")
                @tags = @tags\gsub(caps.bord, "\\bord0")\gsub(caps._1c, "")\gsub(caps.b, "")
                @tags = @tags\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags = @tags\gsub(caps.shad, "\\shad0")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\shad0" unless @tags\match(caps.shad)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
            when "shape_gradient"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.bord, "\\bord0")\gsub(caps._1c, "")\gsub(caps.b, "")
                @tags = @tags\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags = @tags\gsub(caps.shad, "\\shad0")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\shad0" unless @tags\match(caps.shad)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
            when "text_shape"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")\gsub(caps.b, "")
                @tags = @tags\gsub(caps.i, "")\gsub(caps.s, "")\gsub(caps.u, "")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\fscx100" unless @tags\match(caps.fscx)
                @tags ..= "\\fscy100" unless @tags\match(caps.fscy)
                @tags ..= "\\p1"      unless @tags\match(caps.p)
            when "shape_clip"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.b, "")\gsub(caps.i, "")
                @tags = @tags\gsub(caps.s, "")\gsub(caps.u, "")\gsub(caps.transform, "")
                @tags ..= "\\p1" unless @tags\match(caps.p)
            when "text_clip"
                @tags = @tags\gsub(caps.clip, "")
            when "shape_expand"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.frx, "")\gsub(caps.fry, "")
                @tags = @tags\gsub(caps.b, "")\gsub(caps.i, "")\gsub(caps.s, "")
                @tags = @tags\gsub(caps.u, "")\gsub(caps.fay, "")\gsub(caps.fax, "")
                @tags = @tags\gsub(caps.org, "")\gsub(caps.an, "\\an7")\gsub(caps.p, "\\p1")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7" unless @tags\match(caps.an)
                @tags ..= "\\p1"  unless @tags\match(caps.p)
            when "full"
                @tags = @tags\gsub("%b{}", "")\gsub("\\h", " ")
            when "text_in_clip"
                @tags = @tags\gsub(caps.clip, "")\gsub(caps.pos, "")\gsub(caps.move, "")
                @tags = @tags\gsub(caps.fr, "")\gsub(caps.fsp, "")\gsub(caps.transform, "")
            when "text_offset"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps.fscx, "\\fscx100")\gsub(caps.fscy, "\\fscy100")\gsub(caps._1c, "")
                @tags = @tags\gsub(caps.bord, "\\bord0")\gsub(caps.an, "\\an7")\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
            when "shape_offset"
                @tags = @tags\gsub(caps.fn, "")\gsub(caps.fs, "")\gsub(caps.fsp, "")
                @tags = @tags\gsub(caps._1c, "")\gsub(caps.bord, "\\bord0")\gsub(caps.an, "\\an7")
                @tags = @tags\gsub(caps.transform, "")
                @tags ..= "\\an7"   unless @tags\match(caps.an)
                @tags ..= "\\bord0" unless @tags\match(caps.bord)
                @tags ..= "\\p1"    unless @tags\match(caps.p)
        return @tags

{:TAGS}