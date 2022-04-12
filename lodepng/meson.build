lodepng_src = files('src/lodepng.c')
lodepng = shared_library('lodepng', lodepng_src)
lodepng_lua = custom_target('lodepng',
    output: ['lodepng.lua'],
    input: ['lodepng.moon'],
    command: lua_builder_command,
    build_by_default: moonc.found()
)