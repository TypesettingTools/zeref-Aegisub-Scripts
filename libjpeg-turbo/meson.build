turbojpeg_lua = custom_target('libjpeg-turbo',
    output: ['turbojpeg.lua'],
    input: ['turbojpeg.moon'],
    command: lua_builder_command,
    build_by_default: moonc.found()
)