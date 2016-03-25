echo on
SetLocal EnableDelayedExpansion

REM This is the recommended way to choose the toolchain version, according to
REM Appveyor's documentation.
SET PATH=C:\Program Files (x86)\MSBuild\%TOOLCHAIN_VERSION%\Bin;%PATH%

set VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio %TOOLCHAIN_VERSION%\VC\vcvarsall.bat"

if [%Platform%] NEQ [x64] goto win32
set BITS=64
set TARGET_ARCH=x86_64
set TARGET_PROGRAM_FILES=%ProgramFiles%
call %VCVARSALL% amd64
if %ERRORLEVEL% NEQ 0 exit 1
goto download

:win32
echo on
if [%Platform%] NEQ [Win32] exit 1
set BITS=32
set TARGET_ARCH=i686
set TARGET_PROGRAM_FILES=%ProgramFiles(x86)%
call %VCVARSALL% amd64_x86
if %ERRORLEVEL% NEQ 0 exit 1
goto download

:download
REM vcvarsall turns echo off
echo on
set RUST_URL=https://static.rust-lang.org/dist/rust-%RUST%-%TARGET_ARCH%-pc-windows-msvc.msi
echo Downloading %RUST_URL%...
mkdir build
powershell -Command "(New-Object Net.WebClient).DownloadFile('%RUST_URL%', 'build\rust-%RUST%-%TARGET_ARCH%-pc-windows-msvc.msi')"
if %ERRORLEVEL% NEQ 0 (
  echo ...downloading failed.
  exit 1
)

start /wait msiexec /i build\rust-%RUST%-%TARGET_ARCH%-pc-windows-msvc.msi INSTALLDIR="%TARGET_PROGRAM_FILES%\Rust %RUST%" /quiet /qn /norestart
if %ERRORLEVEL% NEQ 0 exit 1

set PATH="%TARGET_PROGRAM_FILES%\Rust %RUST%\bin";%PATH%

set OPENSSL_URL="http://slproweb.com/download/Win${env:BITS}OpenSSL-1_0_2g.exe"
powershell -Command "(New-Object Net.WebClient).DownloadFile('%OPENSSL_URL%', 'build\Win%BITS%OpenSSL-1_0_2g.exe')"
build\Win%BITS%OpenSSL-1_0_2g.exe /SILENT /VERYSILENT /SP- /DIR="C:\OpenSSL"
SET PATH=%PATH%;C:\Program Files (x86)\Rust\bin
SET PATH=%PATH%;C:\MinGW\bin


if [%Configuration%] == [Release] set CARGO_MODE=--release

set

link /?
cl /?
rustc --version
cargo --version

cargo build --verbose %CARGO_MODE%
if %ERRORLEVEL% NEQ 0 exit 1

cargo test --verbose %CARGO_MODE%
if %ERRORLEVEL% NEQ 0 exit 1

cargo doc --verbose
if %ERRORLEVEL% NEQ 0 exit 1

cargo clean --verbose
if %ERRORLEVEL% NEQ 0 exit 1
