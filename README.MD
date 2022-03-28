# Aegisub Macros

### Dependencies
Version of Aegisub that supports Luajit.

- [Yutils](https://github.com/Youka/Yutils)
- [requireffi](https://github.com/TypesettingTools/ffi-experiments/tree/master/requireffi)

### Additional dependencies
These additional dependencies do not interfere with the loading of the macros, but do interfere with the functioning of some of their functions, for example in the **Eveything Shape** macro, in the **Stroke** section, you will not be able to use this section because you do not have the polyclipping library loaded.

- [Lua-clipper](https://github.com/zerefxx/Lua-clipper)
- [giflib](https://github.com/mirrorer/giflib)
- [libjpeg-turbo](https://github.com/libjpeg-turbo/libjpeg-turbo)
- [lodepng](https://github.com/lvandeve/lodepng)

### How can I build these libraries?
In the [build](https://github.com/zerefxx/Aegisub-macros/tree/build) branche, you will find step by step how to do this.