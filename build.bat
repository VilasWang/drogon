@echo off
setlocal enabledelayedexpansion

REM Store the script directory and change to it
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"
echo current work directory is "%SCRIPT_DIR%"

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Administrator privileges required to install to C:\Program Files
    echo Please right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

REM Default build type
set BUILD_TYPE=Release
set BUILD_TESTING=off
set INSTALL_PREFIX="C:\Program Files\drogon"

REM Parse command line arguments
:parse_args
if "%1"=="" goto end_parse
if /i "%1"=="-debug" (
    set BUILD_TYPE=Debug
    shift
    goto parse_args
)
if /i "%1"=="-release" (
    set BUILD_TYPE=Release
    shift
    goto parse_args
)
if /i "%1"=="-t" (
    set BUILD_TESTING=on
    shift
    goto parse_args
)
if /i "%1"=="-install" (
    set INSTALL_PREFIX=%2
    shift
    shift
    goto parse_args
)
echo Unknown option: %1
echo Usage: %0 [-debug|-release] [-t] [-install path]
echo   -debug     Build debug version
echo   -release   Build release version (default)
echo   -t         Enable testing
echo   -install   Set install prefix (default: C:\Program Files\drogon)
exit /b 1
:end_parse

echo Building Drogon with configuration:
echo   Build Type: %BUILD_TYPE%
echo   Testing: %BUILD_TESTING%
echo   Install Prefix: %INSTALL_PREFIX%
echo.

REM Create build directory
if exist build (
    echo Removing existing build directory...
    rmdir /s /q build
)
echo Creating build directory...
mkdir build
cd build

REM Check if conan is available
where conan >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Conan is not installed or not in PATH
    cd ..
    exit /b 1
)

REM Initialize conan profile
echo Initializing Conan profile...
conan profile detect --force
if %errorlevel% neq 0 (
    echo Error: Failed to initialize Conan profile
    cd ..
    exit /b 1
)

REM Install dependencies
echo Installing dependencies with Conan...
conan install .. -s compiler="msvc" -s compiler.version=194 -s compiler.cppstd=20 -s build_type=%BUILD_TYPE% --output-folder . --build=missing
if %errorlevel% neq 0 (
    echo Error: Failed to install dependencies
    cd ..
    pause
    exit /b 1
)
pause

REM Configure CMake
echo Configuring CMake...
cmake .. -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_CXX_STANDARD=20 -DBUILD_TESTING=%BUILD_TESTING% -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake" -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_INSTALL_PREFIX=%INSTALL_PREFIX%
if %errorlevel% neq 0 (
    echo Error: CMake configuration failed
    cd ..
    pause
    exit /b 1
)
pause

REM Build and install
echo Building and installing Drogon...
cmake --build . --parallel --target install --config %BUILD_TYPE%
if %errorlevel% neq 0 (
    echo Error: Build failed
    cd ..
    pause
    exit /b 1
)

echo Build completed successfully!
cd ..
pause