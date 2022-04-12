# Aegisub-macros library builds

This is a fork from: [ffi-experiments](https://github.com/TypesettingTools/ffi-experiments).

Until then it had no support for macOS users, but I discovered the [TypesettingTools](https://github.com/TypesettingTools) ffi-experiments library and it made this happen.

To do the build, take a look at the instructions in the main ffi-experiments repository, but it's important to note that the build is only supported through the __meson__ tool if the operating system is other than windows.

Under windows you can build with either the meson tool, or through the command prompt. To build with meson, it's the same process as explained in the main ffi-experiments repository, but through the command prompt, you build by opening the `win-build.bat` file present in all repositories, for example `giflib/win-build.bat` or opening the `win-build.bat` file contained in the main folder, which will do a complete build of all libraries.