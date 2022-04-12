giflib_src = files(
    'src/lib/dgif_lib.c',
    'src/lib/egif_lib.c',
    'src/lib/gif_err.c',
    'src/lib/gif_font.c',
    'src/lib/gif_hash.c',
    'src/lib/gifalloc.c',
    'src/lib/openbsd-reallocarray.c',
    'src/lib/quantize.c',
)
giflib = shared_library('giflib', giflib_src)
giflib_lua = custom_target('giflib',
    output: ['giflib.lua'],
    input: ['giflib.moon'],
    command: lua_builder_command,
    build_by_default: moonc.found()
)