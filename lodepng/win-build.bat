@echo off

cd src
gcc -W -Wall -Wextra -ansi -pedantic -O3 -c lodepng.c
gcc -shared lodepng.o -o lodepng.dll
del "*.o" /s /q
cd ..