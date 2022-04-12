@echo off

cd src
g++ -Os -c clipper.cpp wrap.cpp
g++ -shared clipper.o wrap.o -o polyclipping.dll
del "*.o" /s /q
cd ..