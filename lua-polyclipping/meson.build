lua_polyclipping_src = files('src/clipper.cpp', 'src/wrap.cpp')
lua_polyclipping = shared_library('polyclipping', lua_polyclipping_src)
lua_polyclipping_lua = custom_target('polyclipping',
    output: ['polyclipping.lua'],
    input: ['polyclipping.moon'],
    command: lua_builder_command,
    build_by_default: moonc.found()
)