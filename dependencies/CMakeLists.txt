cmake_minimum_required(VERSION 3.10)
option(BUILD_SHARED_LIBS "Build Shared Libs" ON)

# libpolyclipping
project(clipper_wrap LANGUAGES CXX)

set(CLIPPER_SRC
    subprojects/libpolyclipping/clipper.cpp
    clipper.wrap.cpp
)
set(CMAKE_INSTALL_LIBDIR ${CMAKE_SOURCE_DIR}/clipper_build)

add_library(clipper_wrap SHARED ${CLIPPER_SRC})
target_include_directories(clipper_wrap PUBLIC subprojects/libpolyclipping)
target_compile_options(clipper_wrap PRIVATE -w -O3)

if (NOT UNIX)
    target_link_libraries(clipper_wrap PUBLIC -static)
endif (UNIX)

# lodepng
project(lodepng_wrap LANGUAGES C)

set(LODEPNG_SRC subprojects/lodepng/lodepng.c)
set(CMAKE_INSTALL_LIBDIR ${CMAKE_SOURCE_DIR}/lodepng_build)

add_library(lodepng_wrap SHARED ${LODEPNG_SRC})
target_compile_options(lodepng_wrap PRIVATE -W -Wall -Wextra -ansi -pedantic -O3)

if (NOT UNIX)
    target_link_libraries(lodepng_wrap PUBLIC -static)
endif (UNIX)

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
set(CMAKE_INSTALL_LIBDIR ${CMAKE_SOURCE_DIR}/giflib_build)

add_library(giflib_wrap SHARED ${GIFLIB_SRC})
target_compile_options(giflib_wrap PRIVATE -w -fno-builtin -g -c -W -Wreturn-type -Wcomment -O3)

if (NOT UNIX)
    target_link_libraries(giflib_wrap PUBLIC -static)
endif (UNIX)

install(TARGETS clipper_wrap
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(TARGETS lodepng_wrap
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(TARGETS giflib_wrap
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)