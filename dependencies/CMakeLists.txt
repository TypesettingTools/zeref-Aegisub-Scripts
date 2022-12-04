cmake_minimum_required(VERSION 3.10)
option(BUILD_SHARED_LIBS "Build Shared Libs" ON)

# libpolyclipping
project(polyclipping LANGUAGES CXX)
set(CLIPPER_SRC subprojects/libpolyclipping/clipper.cpp clipper.wrap.cpp)
add_library(polyclipping SHARED ${CLIPPER_SRC})
target_include_directories(polyclipping PUBLIC subprojects/libpolyclipping)
target_compile_options(polyclipping PRIVATE -w -O3)

# lodepng
project(lodepng LANGUAGES C)
set(LODEPNG_SRC subprojects/lodepng/lodepng.c)
add_library(lodepng SHARED ${LODEPNG_SRC})
target_compile_options(lodepng PRIVATE -W -Wall -Wextra -ansi -pedantic -O3)

# giflib
project(giflib_wrap LANGUAGES C)
set(GIFLIB_SRC
    subprojects/giflib/lib/dgif_lib.c
    subprojects/giflib/lib/egif_lib.c
    subprojects/giflib/lib/gif_err.c
    subprojects/giflib/lib/gif_font.c
    subprojects/giflib/lib/gif_hash.c
    subprojects/giflib/lib/gifalloc.c
    subprojects/giflib/lib/quantize.c
)
add_library(giflib SHARED ${GIFLIB_SRC})
target_compile_options(giflib PRIVATE -w -fno-builtin -g -c -W -Wreturn-type -Wcomment -O3)

if (NOT UNIX)
    target_link_libraries(polyclipping lodepng giflib PUBLIC -static)
endif (UNIX)

install(TARGETS polyclipping lodepng giflib
    RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}"
    LIBRARY DESTINATION "${CMAKE_SOURCE_DIR}"
)