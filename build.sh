#!/bin/sh

# captures git repository name with HTTPS protocol
git_HTTPS="https://github.com/.+/(.+)\.git"

# shortcut to subprojects and additional folders
bin="binaries/"
rel="release/"
aut="release/autoload/"
inc="release/include/"
sub="dependencies/subprojects/"

# check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ext=".so"
    add="lib"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ext=".dylib"
    add="lib"
elif [[ "$OSTYPE" == "cygwin" ]]; then
    ext=".dll"
elif [[ "$OSTYPE" == "msys" ]]; then
    ext=".dll"
elif [[ "$OSTYPE" == "win32" ]]; then
    ext=".dll"
fi

# creates folders
[ ! -d $sub ] && mkdir -p $sub
[ ! -d $rel ] && mkdir -p $rel
[ ! -d $aut ] && mkdir -p $aut
[ ! -d $inc ] && mkdir -p $inc

# copies macros/ZF and modules/ZF to release
cp -rf "macros/." $aut
cp -rf "modules/ZF" $inc

# sets flags
flags="-Wall -Wextra -fPIC -O3"

# calls additional dependencies
while read -u3 rep; do
    if [[ $rep =~ $git_HTTPS ]]; then
        rep_name=${BASH_REMATCH[1]}
        rep_dir="$sub$rep_name"
        rm -rf $rep_dir
        git clone $rep $rep_dir
        if [ $rep_name = "ffi-experiments" ]; then
            # creates $inc/requireffi
            ffi_dir="$inc/requireffi"
            [ ! -d $ffi_dir ] && mkdir -p $ffi_dir
            # copies the files to release
            cp -f "$sub/ffi-experiments/requireffi/requireffi.moon" $ffi_dir
            continue
        elif [ $rep_name = "Yutils" ]; then
            # copies the files to release
            cp -f "$sub/Yutils/src/Yutils.lua" $inc
            continue
        elif [ $rep_name = "Clipper2" ]; then
            cpp_dir="dependencies/subprojects/Clipper2/CPP/Clipper2Lib"
            cpp_rel="release/include/zpclipper/clipper"
            c_files="$cpp_dir/clipper.engine.cpp $cpp_dir/clipper.offset.cpp $cpp_dir/clipper.wrap.cpp"

            # required files and folders
            cp -f "dependencies/clipper.wrap.cpp" $cpp_dir
            cp -rf "dependencies/additional/zpclipper" $inc
            mkdir -p $cpp_rel

            if [[ $ext = ".dylib" ]]; then
                clang++ -std=c++11 $flags -c $c_files
                clang++ -shared *.o -o "$cpp_rel/libclipper${ext}"
            else
                g++ $flags -c $c_files
                g++ -shared *.o -o "$cpp_rel/${add}clipper${ext}"
            fi
        elif [ $rep_name = "lodepng" ]; then
            ldp_dir="dependencies/subprojects/lodepng"
            ldp_rel="release/include/zlodepng/lodepng"
            c_files="$ldp_dir/lodepng.c"

            # required files and folders
            cp -f "$ldp_dir/lodepng.cpp" $c_files
            cp -rf "dependencies/additional/zlodepng" $inc
            mkdir -p $ldp_rel

            gcc $flags -ansi -pedantic -c $c_files
            gcc -shared *.o -o "$ldp_rel/${add}lodepng${ext}"
        elif [ $rep_name = "giflib" ]; then
            gif_dir="dependencies/subprojects/giflib/lib"
            gif_rel="release/include/zgiflib/giflib"

            # required files and folders
            cp -rf "dependencies/additional/zgiflib" $inc
            mkdir -p $gif_rel

            gcc $flags -w -c $gif_dir/*.c
            gcc -shared *.o -o "$gif_rel/${add}giflib${ext}"
        elif [ $rep_name = "libjpeg-turbo" ]; then
            peg_dir="dependencies/subprojects/libjpeg-turbo"
            peg_rel="release/include/zturbojpeg/turbojpeg"
            peg_bld="$peg_dir/build"

            # required files and folders
            cp -rf "dependencies/additional/zturbojpeg" $inc
            mkdir -p $peg_rel

            cmake $peg_dir -DCMAKE_C_COMPILER=gcc -G "Unix Makefiles" -B $peg_bld
            make -C $peg_bld
            cp -f "$peg_bld/libturbojpeg${ext}" "$peg_rel/${add}turbojpeg${ext}"
        fi
        # removes the object files after the build
        rm -rf *.o
    fi
done 3< "dependencies/list.txt"

if [[ $ext = ".dll" ]]; then
    # downloads moonscript binaries
    curl -L -O https://github.com/leafo/moonscript/releases/download/win32-v0.5.0/moonscript-187bac54ee5a7450013e9c38e005a0e671b76f45.zip
    unzip moonscript-187bac54ee5a7450013e9c38e005a0e671b76f45.zip -d moonscript
    "moonscript/moon.exe" "scripts/moon2lua.moon"
fi