cmake_minimum_required(VERSION 3.10)
option(BUILD_SHARED_LIBS "Build Shared Libs" ON)

# libpolyclipping
project(polyclipping LANGUAGES CXX)
set(CLIPPER_SRC libpolyclipping/clipper.cpp clipper.wrap.cpp)
add_library(polyclipping SHARED ${CLIPPER_SRC})
target_include_directories(polyclipping PUBLIC libpolyclipping)
if (NOT MSVC)
    target_compile_options(polyclipping PRIVATE -w -O3)
    if (NOT UNIX)
        target_link_libraries(polyclipping PUBLIC -static)
    endif (UNIX)
else()
    target_compile_options(polyclipping PRIVATE /W3 /O2)
endif (MSVC)

install(TARGETS polyclipping
    RUNTIME DESTINATION "${CMAKE_SOURCE_DIR}"
    LIBRARY DESTINATION "${CMAKE_SOURCE_DIR}"
)