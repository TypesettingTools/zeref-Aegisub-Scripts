@echo off

set gcc=0
set g++=0

echo -- Checking if gcc.exe exists in the PATH...
for %%i in (%path%) do if exist "%%i\gcc.exe" set gcc="%%i\gcc.exe"
if %gcc%==0 (
    echo gcc.exe was not found
    set /p any="Press ENTER button to exit..."
    exit
) else (
    echo gcc.exe was found: %gcc%
)
echo:

echo -- Checking if g++.exe exists in the PATH...
for %%i in (%path%) do if exist "%%i\g++.exe" set g++="%%i\g++.exe"
if %g++%==0 (
    echo g++.exe was not found
    set /p any="Press ENTER button to exit..."
    exit
) else (
    echo g++.exe was found: %g++%
)
echo:

echo -- Starting the giflib build
echo:

cd giflib
if exist win-build.bat (call win-build.bat)
cd ..

echo:
echo -- giflib build - SUCCESS
echo:

@rem ----------------------------------------

echo -- Starting the libjpeg-turbo build
echo:

cd libjpeg-turbo
if exist win-build.bat (call win-build.bat)
cd ..

echo:
echo -- libjpeg-turbo build - SUCCESS
echo:

@rem ----------------------------------------

echo -- Starting the lodepng build
echo:

cd lodepng
if exist win-build.bat (call win-build.bat)
cd ..

echo:
echo -- lodepng build - SUCCESS
echo:

@rem ----------------------------------------

echo -- Starting the lua-polyclipping build
echo:

cd lua-polyclipping
if exist win-build.bat (call win-build.bat)
cd ..

echo:
echo -- lua-polyclipping build - SUCCESS
echo:

if not exist binaries (mkdir binaries)
echo -- Getting binaries
copy /y giflib\src\lib\giflib.dll binaries\giflib.dll
copy /y libjpeg-turbo\libjpeg-turbo-build\libturbojpeg.dll binaries\libturbojpeg.dll
copy /y lodepng\src\lodepng.dll binaries\lodepng.dll
copy /y lua-polyclipping\src\polyclipping.dll binaries\polyclipping.dll

echo:
set /p any="Press ENTER button to exit..."
exit