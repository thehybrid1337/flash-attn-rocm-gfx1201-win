@echo off
setlocal
cls
title comfyui-rocm - Rebuild FlashAttention (CK backend for gfx1201)

for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "RED=%ESC%[31m"
set "CYAN=%ESC%[36m"
set "RESET=%ESC%[0m"

echo %CYAN%====================================================%RESET%
echo %CYAN%   comfyui-rocm - FlashAttention Wheel Builder%RESET%
echo %CYAN%====================================================%RESET%
echo.

set "INSTALL_DIR=%~dp0"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"
set "COMFY_PYTHON=%INSTALL_DIR%\python_env\python.exe"
set "PYTHON=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"

set "FA_ROOT=%USERPROFILE%\fa-ck-gfx1201"
set "WS=%FA_ROOT%\recipes"
set "FA=%FA_ROOT%\flash-attention"
set "DIST=%FA_ROOT%\dist"
set "MAX_JOBS=16"

echo %GREEN%[*]%RESET% Build Python : %PYTHON%
echo %GREEN%[*]%RESET% Comfy Python : %COMFY_PYTHON%
echo %GREEN%[*]%RESET% FA Source    : %FA%
echo %GREEN%[*]%RESET% Workspace    : %WS%
echo %GREEN%[*]%RESET% Output Dist  : %DIST%
echo.

if not exist "%PYTHON%" (
    echo %RED%[!]%RESET% System Python 3.12 not found at: %PYTHON%
    pause
    exit /b 1
)

if not exist "%COMFY_PYTHON%" (
    echo %RED%[!]%RESET% Comfy Python not found at: %COMFY_PYTHON%
    echo %RED%[!]%RESET% Run install.bat first.
    pause
    exit /b 1
)

if not exist "%WS%" (
    echo %RED%[!]%RESET% Recipes folder not found at: %WS%
    pause
    exit /b 1
)

:: x64 Native Tools: Hostx64 link.exe before coreutils
set "PATH=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;%PATH%"
set "DISTUTILS_USE_SDK=1"

echo %GREEN%[*]%RESET% Active linker:
where.exe link
echo.

set "DO_CLEAN=0"
if /I "%~1"=="--clean" set "DO_CLEAN=1"

if %DO_CLEAN%==1 (
    echo %YELLOW%[*]%RESET% --clean flag set: wiping old build artifacts...
    if exist "%DIST%" del /f /q "%DIST%\*.whl" 2>nul
    if exist "%FA%\build" rmdir /s /q "%FA%\build" 2>nul
    if exist "%FA%\flash_attn.egg-info" rmdir /s /q "%FA%\flash_attn.egg-info" 2>nul
) else (
    echo %GREEN%[*]%RESET% Resuming compile ^(Ninja cache preserved^). Run with --clean to start fresh.
    if exist "%DIST%" del /f /q "%DIST%\*.whl" 2>nul
)
if not exist "%DIST%" mkdir "%DIST%" 2>nul

set "NINJA_DIR=%FA%\build\temp.win-amd64-cpython-312\Release"
if exist "%NINJA_DIR%\build.ninja" (
    echo %GREEN%[*]%RESET% Resume ninja MAX_JOBS=%MAX_JOBS% ^(no setup.py^)
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $env:MAX_JOBS='%MAX_JOBS%'; . '%WS%\base\init-fa-build-env.ps1' -WorkspaceRoot '%WS%' -PythonExe '%PYTHON%' -OptDim '32,64,128,256'; Set-Location -LiteralPath '%NINJA_DIR%'; ninja -j %MAX_JOBS%; exit $LASTEXITCODE"
) else (
    echo %GREEN%[*]%RESET% Compile OPT_DIM=32,64,128,256 MAX_JOBS=%MAX_JOBS%
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $env:MAX_JOBS='%MAX_JOBS%'; . '%WS%\base\init-fa-build-env.ps1' -WorkspaceRoot '%WS%' -PythonExe '%PYTHON%' -OptDim '32,64,128,256'; Set-Location -LiteralPath '%FA%'; & '%PYTHON%' 'setup.py' build_ext -v; exit $LASTEXITCODE"
)
if errorlevel 1 (
    echo.
    echo %RED%[!]%RESET% Compile failed! Check messages above.
    pause
    exit /b 1
)

echo %GREEN%[*]%RESET% Linking wheel...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:MAX_JOBS='%MAX_JOBS%'; & '%WS%\build\7.wheel - build-bdist-wheel.ps1' -FaSrc '%FA%' -DistDir '%DIST%' -WorkspaceRoot '%WS%' -PythonExe '%PYTHON%'; exit $LASTEXITCODE"
if errorlevel 1 (
    echo.
    echo %RED%[!]%RESET% Wheel failed! Check messages above.
    pause
    exit /b 1
)

echo.
echo %GREEN%[*]%RESET% Installing wheel into python_env...
"%COMFY_PYTHON%" -m pip uninstall -y flash-attn
for %%F in ("%DIST%\flash_attn-*.whl") do (
    echo %GREEN%[*]%RESET% Installing: %%F
    "%COMFY_PYTHON%" -m pip install --no-deps "%%F" --force-reinstall
)

echo %GREEN%[*]%RESET% GPU smoke test...
powershell -NoProfile -ExecutionPolicy Bypass -File "%WS%\build\9.test - gpu-smoke-test.ps1" -WorkspaceRoot "%WS%" -PythonExe "%COMFY_PYTHON%"
if errorlevel 1 (
    echo.
    echo %RED%[!]%RESET% Smoke test failed!
    pause
    exit /b 1
)

echo.
echo %GREEN%====================================================%RESET%
echo %GREEN%  FlashAttention build, install, and smoke test complete!%RESET%
echo %GREEN%====================================================%RESET%
pause
