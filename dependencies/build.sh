#!/bin/sh

# captures git repository name with HTTPS protocol
git_HTTPS="https://github.com/.+/(.+)\.git#.+"

# shortcut to subprojects and additional folders
inc="release"
sub="dependencies/subprojects"

# windows
ext=".dll"
lib=""

# check OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ext=".so"
    lib="lib"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    ext=".dylib"
    lib="lib"
fi

# creates folders
[ ! -d $sub ] && mkdir -p $sub
[ ! -d $inc ] && mkdir -p $inc

# sets flags
flags="-Wall -Wextra -fPIC -O3"

# calls additional dependencies
while read -u3 rep_path; do
    if [[ $rep_path =~ $git_HTTPS ]]; then
        # Clone repo and checkout correct commit
        rep="${rep_path%\#*}"
        commit="${rep_path#*\#}"
        rep_name=${BASH_REMATCH[1]}
        rep_dir="$sub/$rep_name"
        rm -rf $rep_dir

        git clone $rep $rep_dir
        cwd="$PWD"
        cd $rep_dir
        git checkout $commit
        cd $cwd

        if [ $rep_name = "Clipper2" ]; then
            cpp_dir="$sub/Clipper2/CPP/Clipper2Lib/src"
            cpp_rel="$inc/zpclipper"
            c_files="$cpp_dir/clipper.engine.cpp $cpp_dir/clipper.offset.cpp $cpp_dir/clipper.wrap.cpp"

            # required files and folders
            cp -f "dependencies/clipper.wrap.cpp" $cpp_dir
            mkdir -p $cpp_rel

            if [[ $ext = ".dylib" ]]; then
                clang++ $flags -std=c++17 "-I$sub/Clipper2/CPP/Clipper2Lib/include/" -c $c_files
                clang++ -shared *.o -o "$cpp_rel/${lib}clipper${ext}"
            else
                g++ $flags -std=c++17 "-I$sub/Clipper2/CPP/Clipper2Lib/include/" -c $c_files
                g++ -shared *.o -o "$cpp_rel/${lib}clipper${ext}"
            fi
        elif [ $rep_name = "lodepng" ]; then
            ldp_dir="$sub/lodepng"
            ldp_rel="$inc/zlodepng"
            c_files="$ldp_dir/lodepng.c"

            # required files and folders
            cp -f "$ldp_dir/lodepng.cpp" $c_files
            mkdir -p $ldp_rel

            gcc $flags -ansi -pedantic -c $c_files
            gcc -shared *.o -o "$ldp_rel/${lib}lodepng${ext}"
        elif [ $rep_name = "giflib" ]; then
            gif_dir="$sub/giflib/lib"
            gif_rel="$inc/zgiflib"

            # required files and folders
            mkdir -p $gif_rel

            gcc $flags -w -c $gif_dir/*.c
            gcc -shared *.o -o "$gif_rel/${lib}giflib${ext}"
        elif [ $rep_name = "libjpeg-turbo" ]; then
            peg_dir="$sub/libjpeg-turbo"
            peg_rel="$inc/zturbojpeg"
            peg_bld="$peg_dir/build"

            # required files and folders
            mkdir -p $peg_rel

            cmake $peg_dir -DCMAKE_C_COMPILER=gcc -G "Unix Makefiles" -B $peg_bld
            make -C $peg_bld
            cp -f "$peg_bld/libturbojpeg${ext}" "$peg_rel/${lib}turbojpeg${ext}"
        fi
        # removes the object files after the build
        rm -rf *.o
    fi
done 3< "dependencies/list.txt"
