project('builds', 'c', 'cpp',
    license: 'ISC',
    meson_version: '>=0.55.0',
    default_options: ['c_std=c99', 'cpp_std=c++14', 'warning_level=2', 'buildtype=release', 'b_ndebug=if-release'],
)

cmake = import('cmake')

libjpeg = cmake.subproject('libjpeg-turbo')

lua_builder = find_program('build_lua.py')
moonc = find_program('moonc', required: false)
lua_builder_command = [lua_builder, '@INPUT@', '@OUTPUT@']
if moonc.found()
    lua_builder_command += ['--moonc', moonc]
else
    warning('moonc not found, building only the native components')
endif

subdir('giflib')
subdir('lodepng')
subdir('lua-polyclipping')