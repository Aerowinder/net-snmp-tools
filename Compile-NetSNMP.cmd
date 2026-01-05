@ECHO OFF

net session >nul 2>&1
if %errorlevel% neq 0 (
    ECHO This script must be run as Administrator.
    PAUSE
    exit /b 1
)

REM Variables you will need to change
SET "ver_openssl=3.6.0"
SET "ver_netsnmp=5.9.5.2"
SET "dir_download=C:\Users\Adam\Downloads"

REM Variables you shouldn't need to change
SET "vcvars64=C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
SET "nasm=%programfiles%\NASM"
SET "sperl=C:\Strawberry\perl\bin"
SET "dir_openssl=C:\Program Files\OpenSSL"
SET "dir_netsnmp=C:\Program Files\Net-SNMP"
SET "tar_openssl=%dir_download%\openssl-%ver_openssl%.tar.gz"
SET "tar_netsnmp=%dir_download%\net-snmp-%ver_netsnmp%.tar.gz"
SET "file_zip=%dir_download%\netsnmp-%ver_netsnmp%-openssl-%ver_openssl%-win64.zip"

REM Rudimentary error handling
IF NOT EXIST "%vcvars64%" GOTO :ERROR
IF NOT EXIST "%nasm%" GOTO :ERROR
IF NOT EXIST "%sperl%" GOTO :ERROR
IF NOT EXIST "%tar_openssl%" GOTO :ERROR
IF NOT EXIST "%tar_netsnmp%" GOTO :ERROR

REM Cleanup previous failed run
IF EXIST "%dir_openssl%" RMDIR /Q /S "%dir_openssl%"
IF EXIST "%dir_netsnmp%" RMDIR /Q /S "%dir_netsnmp%"
IF EXIST "%file_zip%" DEL /Q "%file_zip%"
IF EXIST "%dir_download%\openssl-%ver_openssl%" RMDIR /Q /S "%dir_download%\openssl-%ver_openssl%"
IF EXIST "%dir_download%\net-snmp-%ver_netsnmp%" RMDIR /Q /S "%dir_download%\net-snmp-%ver_netsnmp%"

REM OpenSSL and Net-SNMP
call "%vcvars64%"
path=%path%;"%nasm%";"%sperl%"

REM OpenSSL
cd "%dir_download%"
tar -xzvf "%tar_openssl%"
cd "%dir_download%\openssl-%ver_openssl%"
perl Configure VC-WIN64A
nmake clean
nmake
nmake install

REM Net-SNMP
cd "%dir_download%"
tar -xzvf "%tar_netsnmp%"
cd "%dir_download%\net-snmp-%ver_netsnmp%\win32"
set Platform=x64
set TARGET_CPU=x64
set INCLUDE=%INCLUDE%;%dir_openssl%\include
set LIB=%LIB%;%dir_openssl%\lib
copy "%dir_openssl%\lib\libcrypto.lib" "%dir_openssl%\lib\libcrypto64md.lib"
copy "%dir_openssl%\lib\libssl.lib" "%dir_openssl%\lib\libssl64md.lib"
REM Check "<net-snmp-$ver.tar>\<net-snmp-$ver>\win32\Configure" for available compilation switches.
perl Configure --with-sdk --with-winextdll --with-ssl --with-ipv6 --enable-blumenthal-aes --config=release --linktype=static --prefix="%dir_netsnmp%"
nmake clean
nmake
nmake install
copy "%dir_openssl%\bin\libcrypto-3-x64.dll" "%dir_netsnmp%\bin\libcrypto-3-x64.dll"
copy "%dir_openssl%\bin\libssl-3-x64.dll" "%dir_netsnmp%\bin\libssl-3-x64.dll"

REM Zip Net-SNMP and place in download folder
ECHO Creating ZIP file %file_zip%...
cd "%dir_netsnmp%"
tar.exe -a -cf "%file_zip%" "*"

REM Cleanup
timeout /t 10 /nobreak > NUL
cd "%dir_download%"
IF EXIST "%dir_openssl%" RMDIR /Q /S "%dir_openssl%"
IF EXIST "%dir_netsnmp%" RMDIR /Q /S "%dir_netsnmp%"
IF EXIST "%dir_download%\openssl-%ver_openssl%" RMDIR /Q /S "%dir_download%\openssl-%ver_openssl%"
IF EXIST "%dir_download%\net-snmp-%ver_netsnmp%" RMDIR /Q /S "%dir_download%\net-snmp-%ver_netsnmp%"

GOTO :EOF

:ERROR
ECHO.
ECHO ERROR: Please ensure the following directories and files exist:
ECHO 	* %nasm%
ECHO 	* %sperl%
ECHO 	* %tar_openssl%
ECHO 	* %tar_netsnmp%
ECHO 	* %vcvars64%

REM Changelog
REM 2024-07-24 - AS - v1, Initial release.
REM 2024-07-25 - AS - v2, General improvements.
REM 2025-02-01 - AS - v3, Updated version strings (OpenSSL 3.4.0)
REM 2025-07-22 - AS - v4, Updated version strings (OpenSSL 3.5.1)
REM 2025-01-04 - AS - v5, Updated version strings (OpenSSL 3.6.0, Net-SNMP 5.9.5.2) and Visual Studio 2026 vcvars64.bat path
