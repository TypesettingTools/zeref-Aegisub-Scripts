# https://github.com/tamasmeszaros/libpolyclipping.git#784ff113071f1fa7832ebe74667f2fd0756c634f
# https://github.com/lvandeve/lodepng.git#997936fd2b45842031e4180d73d7880e381cf33f
# https://github.com/rcancro/giflib.git#4b0c893cfddf16421bd3f59207fdf65f06e9a10d
# https://github.com/libjpeg-turbo/libjpeg-turbo.git#8162eddf041e0be26f5c671bb6528723c55fed9d

pvd=$PWD

sub=$pvd/dependencies/subprojects
[ ! -d $sub ] && mkdir -p $sub

bin=$pvd/dependencies/binaries
[ ! -d $bin ] && mkdir -p $bin

if [ "$1" == "-all" ]; then
    bld=$pvd/dependencies/buildPC
    [ ! -d $bld ] && mkdir -p $bld

    plc=$pvd/dependencies/libpolyclipping
    git clone https://github.com/tamasmeszaros/libpolyclipping.git $plc/libpolyclipping && cd $plc/libpolyclipping
    git checkout 784ff113071f1fa7832ebe74667f2fd0756c634f
    cmake $plc -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B $bld
    cd $bld && make polyclipping
fi

if [ "$1" == "-all" ]; then
    bld=$pvd/dependencies/buildJP
    [ ! -d $bld ] && mkdir -p $bld

    git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git $sub/libjpeg-turbo && cd $sub/libjpeg-turbo
    git checkout 8162eddf041e0be26f5c671bb6528723c55fed9d
    cmake $pvd/dependencies/subprojects/libjpeg-turbo -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B $bld
    cd $bld && make
fi

bld=$pvd/dependencies/buildLG
[ ! -d $bld ] && mkdir -p $bld

git clone https://github.com/lvandeve/lodepng.git $sub/lodepng && cd $sub/lodepng
git checkout 997936fd2b45842031e4180d73d7880e381cf33f
cp -f $sub/lodepng/lodepng.cpp $sub/lodepng/lodepng.c

git clone https://github.com/rcancro/giflib.git $sub/giflib && cd $sub/giflib
git checkout 4b0c893cfddf16421bd3f59207fdf65f06e9a10d

cmake $pvd/dependencies -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -G "Unix Makefiles" -B $bld
cd $bld && make lodepng && make giflib