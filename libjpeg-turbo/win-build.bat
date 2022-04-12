@echo off

if not exist libjpeg-turbo\ (git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git)
if not exist libjpeg-turbo-build\ (mkdir libjpeg-turbo-build)

set make=0
set cmake=0

echo -- Checking if cmake.exe exists in the PATH...
for %%i in (%path%) do if exist "%%i\cmake.exe" set cmake="%%i\cmake.exe"
if %cmake%==0 (
    echo cmake.exe was not found
    set /p any="Press ENTER button to exit..."
    exit
) else (
    echo cmake.exe was found: %cmake%
)
echo:

cmake libjpeg-turbo -DCMAKE_C_COMPILER=gcc -G "Unix Makefiles" -B libjpeg-turbo-build
cd libjpeg-turbo-build

echo -- Checking if make.exe exists in the PATH...
for %%i in (%path%) do if exist "%%i\make.exe" set make="%%i\make.exe"
if %make%==0 (
    echo make.exe was not found
    set /p any="Press ENTER button to exit..."
    exit
) else (
    echo make.exe was found: %make%
)
echo:

make
cd ..