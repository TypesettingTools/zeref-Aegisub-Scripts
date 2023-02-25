import LIBBMP from require "zimg.main.bitmap.bitmap"
import LIBJPG from require "zimg.main.turbojpeg.turbojpeg"
import LIBGIF from require "zimg.main.giflib.giflib"
import LIBPNG from require "zimg.main.lodepng.lodepng"

class IMG

    new: (filename) =>
        if filename and type(filename) == "string"
            @extension = filename\match "^.+%.(.+)$"
            @infos = switch @extension
                when "png"                               then LIBPNG(filename)\decode!
                when "jpeg", "jpe", "jpg", "jfif", "jfi" then LIBJPG(filename)\decode!
                when "bmp", "dib"                        then LIBBMP(filename)\decode!
                when "gif"                               then LIBGIF(filename)\decode!
                else error "Invalid image format", 2
        else
            error "Expected filename", 2

    setInfos: (frame = 1) =>
        infos = @extension == "gif" and @infos.frames[frame] or @infos
        if @extension == "gif"
            {delayMs: @delayMs, x: @x, y: @y} = infos
        @width = infos.width
        @height = infos.height
        @data = infos\getData!

{:IMG, :LIBBMP, :LIBJPG, :LIBGIF, :LIBPNG}