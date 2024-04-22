@echo off
setlocal

set "LOGIN_URL=https://net2.sharif.edu/login"
set "INFO_FILE=info"
set "FILE_PATH=%USERPROFILE%\.local\bin\"

setlocal enabledelayedexpansion
echo "!PATH!" | findstr /C:"%FILE_PATH%" >nul
if errorlevel 1 (
    setx PATH "%PATH%;%FILE_PATH%" 
)

@REM set "found=false"
@REM for %%I in (%PATH%) do (
@REM     echo "%%~I"
@REM     if /i "%%~I"=="%FILE_PATH%" (
@REM         set "found=true"
@REM     )
@REM )
@REM if "%found%"=="false" (
@REM     setx PATH "%PATH%;%FILE_PATH%"
@REM )

if "%1"=="install" (
    if "%2"=="--help" (
        echo.
        echo Install the script to make it usable from any PATH
        echo.
        echo Usage:
        echo   sut_login install
        echo.
        echo Flags:
        echo   -h, --help   help for install
        echo.
        echo Use "sut_login [command] --help" for more information about a command.
        echo.
    )
    mkdir "%USERPROFILE%\.local\bin\" 2>nul
    copy "%~f0" "%USERPROFILE%\.local\bin\sut_login.bat" 2>nul
    @REM icacls "%USERPROFILE%\.local\bin\sut_login" /inheritance:r /grant:r "%USERNAME%:(CI)(OI)F" /t
    attrib +h "%USERPROFILE%\.local"
    setx PATH "%PATH%;%FILE_PATH%"


    @REM rmdir /s /q "%USERPROFILE%\.local"

) else if "%1"=="uninstall" (
    rmdir /s /q "%USERPROFILE%\.local"
    
) else if "%1"=="create_profile" (
    if "%2"=="--help" (
        echo.
        echo Store your username and password to never ask again
        echo.
        echo Usage:
        echo   sut_login create_profile
        echo.
        echo Flags:
        echo   -h, --help   help for install
        echo.
        echo Use "sut_login [command] --help" for more information about a command.
        echo.
    )
    call :create_info_file

) else if "%1"=="remove_profile" (
    if "%2"=="--help" (
        echo.
        echo Remove the stored username and password file
        echo.
        echo Usage:
        echo   sut_login remove_profile
        echo.
        echo Flags:
        echo   -h, --help   help for install
        echo.
        echo Use "sut_login [command] --help" for more information about a command.
        echo.
    )
    echo "%1"
    call :remove_info_file

) else if "%1"=="update_profile" (
    call :remove_info_file
    echo "Now please enter the new information"
    call :create_info_file

) else if "%1"=="logout" (
    curl -s -o nul -X GET "http://net2.sharif.ir/logout"
) else if "%1"=="" (
    color 0A
    echo "If you are not N00B, run it from cmd. U can use -h to see it's help :)"
    color 0F
    if not exist "%USERPROFILE%\.local\bin\sut_login" (
        mkdir "%USERPROFILE%\.local\bin\" 2>nul >nul
        copy "%~f0" "%USERPROFILE%\.local\bin\sut_login.bat" 2>nul >nul
        @REM icacls "%USERPROFILE%\.local\bin\sut_login" /inheritance:r /grant:r "%USERNAME%:(CI)(OI)F" /t
        attrib +h "%USERPROFILE%\.local"
    )
    if not exist "%FILE_PATH%%INFO_FILE%" (
        color 0A
        set /P "choice=Do you want to proceed? (Y/n): "
        color 0F
        if /I not "%choice%"=="N" (
            echo "you need enter your username password just this time :)"
            call :create_info_file
        )
    )
    
    call :login
    pause
) else (
    echo.
    echo This is a simple script that helps you to login easier :D
    echo.
    echo Usage:
    echo   sut_login [command]
    echo.
    echo Available Commands:
    echo   install           Install the script to make it usable from any PATH
    echo   uninstall         Uninstall the script to make your system clean
    echo   create_profile    Store your username and password to never ask again
    echo   update_profile    Update your username and password to never ask again
    echo   remove_profile    Remove the stored username and password file
    echo   logout            For logging out from `http://net2.sharif.ir/logout`
    echo   help              Help about any command
    echo.
    echo Use "sut_login [command] --help" for more information about a command.
    echo.
)

endlocal
goto :eof

:create_info_file
set /p USERNAME=Enter your username:
echo Enter your password:
for /f "delims=" %%a in ('powershell -Command "$pwd = read-host -AsSecureString; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)"') do set "PASSWORD=%%a"
mkdir "%USERPROFILE%\.local\bin\" 2>nul
attrib +h "%USERPROFILE%\.local"
copy /y nul "%FILE_PATH%%INFO_FILE%" > nul

echo %USERNAME%> "%FILE_PATH%%INFO_FILE%"
echo %PASSWORD%>> "%FILE_PATH%%INFO_FILE%"

@REM icacls "%FILE_PATH%%INFO_FILE%" /inheritance:r /grant:r "%USERNAME%:(CI)(OI)F" /remove Everyone
echo Credentials saved to %INFO_FILE%
goto :eof


:remove_info_file
if exist "%FILE_PATH%%INFO_FILE%" (
    del /q "%FILE_PATH%%INFO_FILE%"
    echo Your credentials removed.
) else (
    echo No credentials found to remove.
)
goto :eof


:login
setlocal enabledelayedexpansion
@REM echo "%FILE_PATH%%INFO_FILE%"
if exist "%FILE_PATH%%INFO_FILE%" (
    set "counter=0"
    for /f "usebackq tokens=*" %%a in ("%FILE_PATH%%INFO_FILE%") do (
        set /a counter+=1
        if !counter! equ 1 (
            set "USERNAME=%%a"
        ) else if !counter! equ 2 (
            set "PASSWORD=%%a"
        )
    )
) else (
    set /p "USERNAME=Enter your username: "
    
    echo Enter your password:
    for /f "delims=" %%a in ('powershell -Command "$pwd = read-host -AsSecureString; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)"') do set "PASSWORD=%%a"
)

@REM curl -s -o nul -X POST -d "username=%USERNAME%&password=%PASSWORD%" %LOGIN_URL%
@REM echo %http_code%

set "response_file=response.txt"

curl -s -o nul -w "%%{http_code}" -X POST -d "username=%USERNAME%&password=%PASSWORD%" %LOGIN_URL% > %response_file% 2>nul

set /p response=<%response_file%
del %response_file%

if %response% neq 200 (
    echo Login failed!
    exit /b 1
)

echo Login successful!
exit /b