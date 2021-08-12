-- load external libs
import UTIL  from require "ZF.util"
import TABLE from require "ZF.table"

class CONFIG

    -- checks if a file or folder exists
    file_exist: (file, dir) =>
        file ..= "/" if dir
        ok, err, code = os.rename(file, file)
        unless ok
            return true if code == 13
        return ok, err

    -- gets the values line by line from the file
    read: (filename) =>
        split = (t) ->
            s = {n: {}, v: {}}
            for k = 1, #t
                s.n[k] = t[k]\gsub "(.+) %= .+", "%1"
                s.v[s.n[k]] = t[k]\gsub ".+ %= (.+)", "%1"
            return s
        if filename
            arq = io.open filename, "r"
            if arq != nil
                read = arq\read "*a"
                arq\close!
                lines = [k for k in read\gmatch "%{([^\n]+)%}"]
                return split(lines), #lines

    -- loads the lines contained in the saved file
    load: (GUI, macro_name) =>
        dir = aegisub.decode_path("?user") .. "\\zeref-cfg\\#{macro_name\lower!\gsub "%s", "_"}.cfg"
        read, len = @read dir
        new_gui = TABLE(GUI)\copy!
        if read
            for k, v in ipairs new_gui
                v.value = read.v[v.name] == "true" and true or read.v[v.name] if v.name
        return new_gui, read, len

    -- saves the contents of an interface to a file
    save: (GUI, elements, macro_name, macro_version) =>
        writing = "#{macro_name\upper!} - VERSION #{macro_version}\n\n"
        for k, v in ipairs GUI
            writing ..= "{#{v.name} = #{elements[v.name]}}\n" if v.name
        dir = aegisub.decode_path "?user"
        if not @file_exist "#{dir}\\zeref-cfg", true
            os.execute "mkdir #{dir}\\zeref-cfg"
        save = "#{dir}\\zeref-cfg\\#{macro_name\lower!\gsub "%s", "_"}.cfg"
        file = io.open save, "w"
        file\write writing
        file\close!
        return

    -- returns the macro interface
    interface: (macro_name) =>
        set_aegisub_version = ->
            items = {"Version 3.2.2 -", "Version 3.2.2 +"}
            {
                {class: "label", label: "Set Version:"}
                {class: "dropdown", name: "list", :items, x: 0, y: 1, value: items[2]}
            }
        gui, read = @load(set_aegisub_version!, "ZF - Set Aegisub Version")
        aegisub_v = gui[2].value == "Version 3.2.2 +"
        --
        switch macro_name
            when "ZF - Set Aegisub Version" then set_aegisub_version
            when "Envelope Distort"
                ->
                    hints = {
                        "Interpolation of the control points around the bounding box."
                        "Mesh, will generate the control points.\nWarp, will generate the distortion from the control points."
                        "Interpolation tolerance of the control points that are of Bezier type."
                        "Control points style type."
                    }
                    items = {
                        {"Bezier", "Line"}
                        {"Mesh", "Warp", "Perspective"}
                    }
                    if aegisub_v
                        {
                            {class: "label", label: "Control Points: ", x: 0, y: 0}
                            {class: "intedit", name: "siz", hint: hints[1], x: 0, y: 1, min: 1, value: 1}
                            {class: "label", label: "Generator: ", x: 0, y: 2}
                            {class: "dropdown", name: "gmw", items: items[2], hint: hints[2], x: 0, y: 3, value: items[2][1]}
                            {class: "label", label: "Tolerance:  ", x: 1, y: 0}
                            {class: "intedit", name: "tol", hint: hints[3], x: 1, y: 1, width: 7, min: 1, value: 50}
                            {class: "label", label: "Type:  ", x: 1, y: 2}
                            {class: "dropdown", name: "tpc", items: items[1], hint: hints[4], x: 1, y: 3, width: 7, value: items[1][2]}
                            {class: "checkbox", name: "rfl", label: "Remove selected layers?", x: 0, y: 4, value: true}
                        }
                    else
                        {
                            {class: "label", label: "Control Points: ", x: 0, y: 0}
                            {class: "intedit", name: "siz", hint: hints[1], x: 0, y: 1, width: 4, min: 1, value: 1}
                            {class: "label", label: "Generator: ", x: 0, y: 2}
                            {class: "dropdown", name: "gmw", items: items[2], hint: hints[2], x: 0, y: 3, width: 4, value: items[2][1]}
                            {class: "label", label: "Tolerance:  ", x: 4, y: 0}
                            {class: "intedit", name: "tol", hint: hints[3], x: 4, y: 1, width: 7, min: 1, value: 1}
                            {class: "label", label: "Type:  ", x: 4, y: 2}
                            {class: "dropdown", name: "tpc", items: items[1], hint: hints[4], x: 4, y: 3, width: 7, value: items[1][2]}
                            {class: "checkbox", name: "rfl", label: "Remove selected layers?   ", x: 0, y: 4, width: 4, value: true}
                        }
            when "Everything Shape"
                (modes) ->
                    list_0 = [v for k, v in pairs modes]
                    list_1 = {"Line Only", "Line and Bezier"}
                    list_2 = {"Full", "Line Only", "Bezier Only"}
                    table.sort(list_0)
                    if aegisub_v
                        {
                            {class: "label", label: "Mode List:", x: 0, y: 0}
                            {class: "dropdown", name: "modes", items: list_0, x: 0, y: 1, value: list_0[1]}
                            {class: "label", label: "Tolerance:", x: 0, y: 2}
                            {class: "floatedit", name: "tol", x: 0, y: 3, value: 1}
                            {class: "label", label: "X - Axis:", x: 1, y: 0}
                            {class: "floatedit", name: "px", width: 4, x: 1, y: 1, value: 0}
                            {class: "label", label: "Y - Axis:", x: 1, y: 2}
                            {class: "floatedit", name: "py", width: 4, x: 1, y: 3, value: 0}
                            {class: "label", label: "Simplify Modes:", x: 0, y: 4}
                            {class: "dropdown", name: "sym", items: list_1, x: 0, y: 5, value: list_1[2]}
                            {class: "label", label: "Split Modes:", x: 1, y: 4}
                            {class: "dropdown", name: "spm", items: list_2, width: 4, x: 1, y: 5, value: list_2[1]}
                            {class: "checkbox", name: "rfl", label: "Remove selected layers?", x: 0, y: 6, value: true}
                            {class: "checkbox", name: "smp", label: "Simplify?   ", x: 1, y: 6, value: true}
                        }
                    else
                        {
                            {class: "label", label: "Mode List:", x: 0, y: 0, width: 11}
                            {class: "dropdown", name: "modes", items: list_0, x: 0, y: 1, width: 11, value: list_0[1]}
                            {class: "label", label: "Tolerance:", x: 0, y: 2, width: 11}
                            {class: "floatedit", name: "tol", x: 0, y: 3, width: 11, value: 1}
                            {class: "label", label: "X - Axis:", x: 11, y: 0}
                            {class: "floatedit", name: "px", width: 7, x: 11, y: 1, value: 0}
                            {class: "label", label: "Y - Axis:", x: 11, y: 2}
                            {class: "floatedit", name: "py", width: 7, x: 11, y: 3, value: 0}
                            {class: "label", label: "Simplify Modes:", x: 0, y: 4, width: 11}
                            {class: "dropdown", name: "sym", items: list_1, x: 0, y: 5, width: 11, value: list_1[2]}
                            {class: "label", label: "Split Modes:", x: 11, y: 4}
                            {class: "dropdown", name: "spm", items: list_2, width: 7, x: 11, y: 5, value: list_2[1]}
                            {class: "checkbox", name: "rfl", label: "Remove selected layers? ", x: 0, y: 6, width: 11, value: true}
                            {class: "checkbox", name: "smp", label: "Simplify?   ", x: 11, y: 6, value: true}
                        }
            when "Gradient Cut"
                ->
                    items = {"Vertical", "Horizontal", "Diagonal 1", "Diagonal 2", "By Angle"}
                    if aegisub_v
                        {
                            {class: "dropdown", name: "mode", :items, x: 8, y: 1, value: items[1]}
                            {class: "label", label: "Gradient Types:", x: 8, y: 0}
                            {class: "label", label: "Gap Size: ", x: 8, y: 2}
                            {class: "intedit", name: "px", x: 8, y: 3, min: 1, value: 2}
                            {class: "label", label: "Accel: ", x: 8, y: 4}
                            {class: "floatedit", name: "ac", x: 8, y: 5, value: 1}
                            {class: "label", label: "Angle: ", x: 8, y: 6}
                            {class: "floatedit", name: "ag", x: 8, y: 7, value: 0}
                            {class: "checkbox", label: "Remove selected layers?", name: "act", x: 8, y: 8, value: true}
                            {class: "label", label: "\nColors: ", x: 8, y: 9}
                            {class: "color", name: "color1", x: 8, y: 10, height: 2, value: "#FFFFFF"}
                            {class: "color", name: "color2", x: 8, y: 12, height: 2, value: "#FF0000"}
                        }
                    else
                        {
                            {class: "dropdown", name: "mode", :items, x: 10, y: 1, value: items[1]}
                            {class: "label", label: "Gradient Types:", x: 10, y: 0}
                            {class: "label", label: "Gap Size: ", x: 10, y: 2}
                            {class: "intedit", name: "px", x: 10, y: 3, min: 1, value: 2}
                            {class: "label", label: "Accel: ", x: 10, y: 4}
                            {class: "floatedit", name: "ac", x: 10, y: 5, value: 1}
                            {class: "label", label: "Angle: ", x: 10, y: 6}
                            {class: "floatedit", name: "ag", x: 10, y: 7, value: 0}
                            {class: "checkbox", label: "Remove selected layers?   ", name: "act", x: 10, y: 8, value: true}
                            {class: "label", label: "\nColors: ", x: 10, y: 9}
                            {class: "color", name: "color1", x: 10, y: 10, height: 2, value: "#FFFFFF"}
                            {class: "color", name: "color2", x: 10, y: 12, height: 2, value: "#FF0000"}
                        }
            when "Interpolate Master"
                (tags_full) ->
                    gui = {}
                    tags = [TABLE(tags_full)\slice(k, k + 4) for k = 1, #tags_full, 5]
                    for k = 1, #tags
                        for j = 1, #tags[k]
                            gui[#gui + 1] = {
                                class: "checkbox"
                                label: tags[k][j]\gsub "_", ""
                                name: tags[k][j]
                                x: k - 1
                                y: j - 1
                                value: false
                            }
                    gui[#gui + 1] = {class: "checkbox", label: "Ignore Text", name: "igt", x: 0, y: 6, value: false}
                    gui[#gui + 1] = {class: "label", label: "::Accel::", x: 0, y: 7}
                    gui[#gui + 1] = {class: "floatedit", name: "acc", hint: "Relative interpolation acceleration.", min: 0, x: 0, y: 8, value: 1}
                    return gui
            when "Make Image"
                (typer = "tracer") ->
                    drops = {
                        presets: {"Custom", "Default", "Detailed", "Black and White", "Grayscale", "3 Colors", "6 Colors", "16 Colors", "Smoothed"}
                        modes:   {"Custom", "Color", "Black and White", "Grayscale"}
                        palette: {"Sampling", "Rectangular Grid", "Number of colors"}
                    }
                    switch typer
                        when "tracer"
                            {
                                -- Preset
                                {class: "label", label: "Preset:", x: 0, y: 0}
                                {class: "dropdown", name: "prst", items: drops.presets, x: 1, y: 0, value: drops.presets[1]}
                                -- Mode
                                {class: "label", label: "Mode:", x: 0, y: 1}
                                {class: "dropdown", name: "mds", items: drops.modes, x: 1, y: 1, value: drops.modes[1]}
                                -- Palette
                                {class: "label", label: "Palette:", x: 0, y: 2}
                                {class: "dropdown", name: plt, items: drops.palette, x: 1, y: 2, value: drops.palette[3]}
                                -- Color Quantization
                                {class: "label", label: "Number of Colors:", x: 2, y: 0}
                                {class: "intedit", name: "noc", x: 3, y: 0, min: 2, value: 16}
                                {class: "label", label: "Min Color Ratio:", x: 2, y: 1}
                                {class: "intedit", name: "cmin", x: 3, y: 1, value: 0}
                                {class: "label", label: "Color Quant Cycles:", x: 2, y: 2}
                                {class: "intedit", name: "cqcs", x: 3, y: 2, value: 3}
                                {class: "label", label: "- Advanced ----------", x: 1, y: 4}
                                -- Tracing
                                {class: "label", label: "Line Tres:", x: 0, y: 5}
                                {class: "floatedit", name: "lte", x: 1, y: 5, min: 0, value: 1}
                                {class: "label", label: "Bezier Tres:", x: 0, y: 6}
                                {class: "floatedit", name: "bte", x: 1, y: 6, min: 0, value: 1}
                                {class: "label", label: "Pathomit:", x: 0, y: 7}
                                {class: "intedit", name: "ptt", x: 1, y: 7, min: 0, value: 8}
                                {class: "label", label: "Round:", x: 0, y: 8}
                                {class: "intedit", name: "rud", x: 1, y: 8, min: 0, value: 2}
                                {class: "checkbox", label: "Right Angle ENH?", name: "rga", x: 3, y: 4, value: true}
                                -- Shape
                                {class: "label", label: "Stroke Size:", x: 2, y: 5}
                                {class: "floatedit", name: "skw", x: 3, y: 5, min: 0, value: 1}
                                {class: "label", label: "Scale:", x: 2, y: 6}
                                {class: "floatedit", name: "scl", x: 3, y: 6, min: 0, value: 1}
                                -- Blur
                                {class: "label", label: "Blur Radius:", x: 2, y: 7}
                                {class: "intedit", name: "brr", x: 3, y: 7, min: 0, max: 5, value: 0}
                                {class: "label", label: "Blur Delta:", min: 0, max: 1024, x: 2, y: 8}
                                {class: "intedit", name: "brd", x: 3, y: 8, min: 0, value: 20}
                                -- Ignore
                                {class: "checkbox", label: "Ignore White?", name: "igw", x: 1, y: 9, value: false}
                                {class: "checkbox", label: "Ignore Black?", name: "igb", x: 3, y: 9, value: false}
                            }
                        when "potrace"
                            items = {"right", "black", "white", "majority", "minority"}
                            if aegisub_v
                                {
                                    {class: "label", label: "Turnpolicy:", x: 0, y: 0}
                                    {class: "dropdown", name: "tpy", :items, x: 0, y: 1, value: "minority"}
                                    {class: "label", label: "Corner threshold:", x: 0, y: 2}
                                    {class: "intedit", name: "apm", x: 0, y: 3, min: 0, value: 1}
                                    {class: "label", label: "Delete until:\t\t\t\t\t\t\t\t\t\t ", x: 1, y: 0}
                                    {class: "floatedit", name: "tdz", x: 1, y: 1, value: 2}
                                    {class: "label", label: "Tolerance:", x: 1, y: 2}
                                    {class: "floatedit", name: "opt", x: 1, y: 3, min: 0, value: 0.2}
                                    {class: "checkbox", label: "Curve optimization?\t\t  ", name: "opc", x: 0, y: 4, value: true}
                                }
                            else
                                {
                                    {class: "label", label: "Turnpolicy:", x: 0, y: 0}
                                    {class: "dropdown", name: "tpy", :items, x: 0, y: 1, value: "minority"}
                                    {class: "label", label: "Corner threshold:", x: 0, y: 2}
                                    {class: "intedit", name: "apm", x: 0, y: 3, min: 0, value: 1}
                                    {class: "label", label: "Delete until:\t\t\t\t\t\t\t\t\t\t\t\t\t  ", x: 1, y: 0}
                                    {class: "floatedit", name: "tdz", x: 1, y: 1, value: 2}
                                    {class: "label", label: "Tolerance:", x: 1, y: 2}
                                    {class: "floatedit", name: "opt", x: 1, y: 3, min: 0, value: 0.2}
                                    {class: "checkbox", label: "Curve optimization?\t\t\t\t\t  ", name: "opc", x: 0, y: 4, value: true}
                                }
                        when "pixel"
                            items = {"All in one line", "On several lines - rec", "Pixel by Pixel"}
                            {
                                {class: "label", label: "Output Type:", x: 0, y: 0}
                                {class: "dropdown", name: "otp", :items, x: 0, y: 1, value: items[2]}
                            }
            when "Stroke Panel"
                (subs, sel) ->
                    hints = {
                        "The default ArcTolerance is 0.25 units. \nThis means that the maximum distance \nthe flattened path will deviate from the \n\"true\" arc will be no more than 0.25 units \n(before rounding)."
                        "Stroke Size."
                        "The default value for MiterLimit is 2 (ie twice delta). \nThis is also the smallest MiterLimit that's allowed. \nIf mitering was unrestricted (ie without any squaring), \nthen offsets at very acute angles would generate \nunacceptably long \"spikes\"."
                        "Returns only the offset."
                    }
                    items = {
                        {"Miter", "Round", "Square"}
                        {"Center", "Inside", "Outside"}
                    }
                    l = subs[sel[#sel]]
                    meta, styles = UTIL\tags2styles(subs, l)
                    karaskel.preproc_line(subs, meta, styles, l)
                    if aegisub_v
                        {
                            {class: "label", label: "Stroke Corner:", x: 0, y: 0}
                            {class: "label", label: "Align Stroke:",  x: 0, y: 3}
                            {class: "label", label: "Stroke Weight:", x: 1, y: 0}
                            {class: "label", label: "Miter Limit:",   x: 1, y: 3}
                            {class: "label", label: "Arc Tolerance:", x: 1, y: 6}
                            {class: "label", label: "Primary Color:", x: 0, y: 9}
                            {class: "label", label: "Stroke Color:",  x: 1, y: 9}
                            {class: "dropdown", name: "crn", items: items[1], x: 0, y: 1, height: 2, value: items[1][2]}
                            {class: "dropdown", name: "alg", items: items[2], x: 0, y: 4, height: 2, value: items[2][3]}
                            {class: "floatedit", name: "ssz", x: 1, y: 1, hint: hints[2], height: 2, min: 0, value: l.styleref.outline}
                            {class: "floatedit", name: "mtl", x: 1, y: 4, hint: hints[3], height: 2, min: 0, value: 2}
                            {class: "floatedit", name: "atc", x: 1, y: 7, hint: hints[1], height: 2, min: 0, value: 0.25}
                            {class: "coloralpha", name: "color1", x: 0, y: 10, width: 1, height: 2, value: l.styleref.color1}
                            {class: "coloralpha", name: "color3", x: 1, y: 10, width: 1, height: 2, value: l.styleref.color3}
                            {class: "checkbox", label: "Simplify?", name: "smp", x: 0, y: 6, value: true}
                            {class: "checkbox", label: "Remove selected layers?", name: "act", x: 0, y: 12, value: true}
                            {class: "checkbox", label: "Generate only offset?\t\t", name: "olf", x: 1, y: 12, hint: hints[4], value: false}
                        }
                    else
                        {
                            {class: "label", label: "Stroke Corner:", x: 0, y: 0}
                            {class: "label", label: "Align Stroke:",  x: 0, y: 3}
                            {class: "label", label: "Stroke Weight:", x: 1, y: 0}
                            {class: "label", label: "Miter Limit:",   x: 1, y: 3}
                            {class: "label", label: "Arc Tolerance:", x: 1, y: 6}
                            {class: "label", label: "Primary Color:", x: 0, y: 9}
                            {class: "label", label: "Stroke Color:",  x: 1, y: 9}
                            {class: "dropdown", name: "crn", items: items[1], x: 0, y: 1, height: 2, value: items[1][2]}
                            {class: "dropdown", name: "alg", items: items[2], x: 0, y: 4, height: 2, value: items[2][3]}
                            {class: "floatedit", name: "ssz", x: 1, y: 1, hint: hints[2], height: 2, min: 0, value: l.styleref.outline}
                            {class: "floatedit", name: "mtl", x: 1, y: 4, hint: hints[3], height: 2, min: 0, value: 2}
                            {class: "floatedit", name: "atc", x: 1, y: 7, hint: hints[1], height: 2, min: 0, value: 0.25}
                            {class: "coloralpha", name: "color1", x: 0, y: 10, width: 1, height: 2, value: l.styleref.color1}
                            {class: "coloralpha", name: "color3", x: 1, y: 10, width: 1, height: 2, value: l.styleref.color3}
                            {class: "checkbox", label: "Simplify?", name: "smp", x: 0, y: 6, value: true}
                            {class: "checkbox", label: "Remove selected layers?\t\t\t", name: "act", x: 0, y: 12, value: true}
                            {class: "checkbox", label: "Generate only offset?\t\t\t\t\t", name: "olf", x: 1, y: 12, hint: hints[4], value: false}
                        }
            when "Text in Clip"
                ->
                    items = {"Center", "Left", "Right", "Around", "Animated - Start to End", "Animated - End to Start"}
                    hints = {items: "Select a mode", offset: "Enter a offset value. \nIn cases of animation, \nthis will be the step."}
                    {
                        {class: "label", label: "Modes:", x: 0, y: 0}
                        {class: "dropdown", name: "mds", :items, hint: hints.items, x: 0, y: 1, value: items[1]}
                        {class: "label", label: "\nOffset:", x: 0, y: 2}
                        {class: "intedit", name: "off", hint: hints.offset, x: 0, y: 3, value: 0}
                        {class: "checkbox", name: "chk", label: "Remove selected layers?", x: 0, y: 4, value: true}
                    }

{:CONFIG}