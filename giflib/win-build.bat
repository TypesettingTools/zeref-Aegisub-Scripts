@echo off

cd src\lib
gcc -Os -c dgif_lib.c egif_lib.c gif_err.c gif_font.c gif_hash.c gifalloc.c openbsd-reallocarray.c quantize.c
gcc -shared dgif_lib.o egif_lib.o gif_err.o gif_font.o gif_hash.o gifalloc.o openbsd-reallocarray.o quantize.o -o giflib.dll
del "*.o" /s /q
cd ..\..\