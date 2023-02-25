@echo off

set pvd=%cd%
set sub=%pvd%\dependencies\subprojects
set bin=%pvd%\dependencies\binaries
set plc=%pvd%\dependencies\libpolyclipping

if not exist %sub% ( mkdir %sub% )
if not exist %bin% ( mkdir %bin% )

git clone https://github.com/tamasmeszaros/libpolyclipping.git %plc%\libpolyclipping && cd %plc%\libpolyclipping
git checkout 784ff113071f1fa7832ebe74667f2fd0756c634f

cmake .. && cmake --build . --config Release --parallel
copy Release\polyclipping.dll ..\..\binaries\polyclipping.dll

git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git %sub%\libjpeg-turbo && cd %sub%\libjpeg-turbo
git checkout 8162eddf041e0be26f5c671bb6528723c55fed9d
mkdir build && cd build && cmake .. && cmake --build . --config Release --parallel
copy Release\turbojpeg.dll ..\..\..\binaries\turbojpeg.dll