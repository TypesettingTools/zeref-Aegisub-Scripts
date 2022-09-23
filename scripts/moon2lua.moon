import to_lua from require "moonscript.base"

compile = (file_name, remove_old_file) ->
    if file = io.open file_name, "r"
        code = file\read "*a"
        file\close!

        lua_code = to_lua code
        lua_file_name = file_name\gsub "%.moon", "%.lua"

        file = io.open lua_file_name, "w"
        file\write lua_code .. "\n"
        file\close!

        if remove_old_file
            os.remove file_name
    else
        error "file not found"

for file_name in *{
    "autoload/zf.allCharsTo.moon"
    "autoload/zf.everythingShape.moon"
    "autoload/zf.gradientCut.moon"
    "autoload/zf.line2fbf.moon"
    "autoload/zf.makeImage.moon"
    "autoload/zf.split.moon"
    "autoload/zf.textInClip.moon"

    "include/requireffi/requireffi.moon"
    "include/ZF/main.moon"

    "include/ZF/2D/clipper.moon"
    "include/ZF/2D/path.moon"
    "include/ZF/2D/paths.moon"
    "include/ZF/2D/point.moon"
    "include/ZF/2D/segment.moon"
    "include/ZF/2D/shape.moon"

    "include/ZF/ass/tags/layer.moon"
    "include/ZF/ass/tags/tags.moon"

    "include/ZF/ass/dialog.moon"
    "include/ZF/ass/fbf.moon"
    "include/ZF/ass/font.moon"
    "include/ZF/ass/line.moon"

    "include/ZF/img/bmp.moon"
    "include/ZF/img/buffer.moon"
    "include/ZF/img/gif.moon"
    "include/ZF/img/img.moon"
    "include/ZF/img/jpg.moon"
    "include/ZF/img/png.moon"
    "include/ZF/img/potrace.moon"

    "include/ZF/util/config.moon"
    "include/ZF/util/math.moon"
    "include/ZF/util/table.moon"
    "include/ZF/util/util.moon"

    "include/zgiflib/giflib.moon"
    "include/zlodepng/lodepng.moon"
    "include/zpclipper/clipper.moon"
    "include/zturbojpeg/turbojpeg.moon"
}
    unless ok = pcall compile, "release/#{file_name}", true
        continue