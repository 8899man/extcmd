@echo off
REM     Copyright 2017 bin jin
REM
REM     Licensed under the Apache License, Version 2.0 (the "License");
REM     you may not use this file except in compliance with the License.
REM     You may obtain a copy of the License at
REM
REM         http://www.apache.org/licenses/LICENSE-2.0
REM
REM     Unless required by applicable law or agreed to in writing, software
REM     distributed under the License is distributed on an "AS IS" BASIS,
REM     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM     See the License for the specific language governing permissions and
REM     limitations under the License.

REM Framework:
REM
REM     If the function names conform to the specifications:
REM         External call function. (Support short name completion)
REM         Error handling.
REM         Display help information.
REM         Print the functions list.
REM
REM     e.g.
REM         ::: "[brief_introduction]" "" "[description_1]" "[description_2]" ...
REM         :::: "[error_description_1]" "[error_description_2]" ...
REM         :[script_name_without_suffix]\[function_name]
REM             ...
REM             [function_body]
REM             ...
REM             REM exit and display [error_description_1]
REM             exit /b 1
REM             ...
REM             REM return false status
REM             exit /b 10

REM Thread:
REM     e.g.
REM         \\:[function_name] [args1] [args2] ...
REM ...
REM :[function_name]
REM ...
REM goto :eof

::::::::::::::::::::::::::
:: some basic functions ::
::::::::::::::::::::::::::

REM For thread
if "%~d1"=="\\" call :thread "%*" & exit

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

REM :lib\g* -> get
REM :lib\i* -> if is
REM :lib\s* -> set
REM :lib\u* -> un

REM init errorlevel
set errorlevel=

REM Help
setlocal
    set _12=%~1%~2
    if not defined _12 set _12=-
    set _12=%_12:--help=%
    set _12=%_12:-h=%
endlocal & if "%~1%~2" neq "%_12%" (
    if "%~2"=="" (call :this\annotation) else call :this\annotation :%~n0\%~1
    goto :eof
)

call :%~n0\%* 2>nul
REM Test type function
if errorlevel 10 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :%~n0\serrlv %errorlevel%
    for /f "usebackq skip=90 tokens=1,2* delims=\ " %%a in (
        "%~f0"
    ) do (
        REM Set annotation, errorlevel will reset after some times
        if %errorlevel% geq 1 (
            if /i "%%~a"=="::::" set _tmp=%errorlevel% %%b %%c
        ) else if /i "%%~a"==":::" set _tmp=%%b %%c

        if /i "%%~a"==":%~n0" (
            REM Display func info or error
            if /i "%%~a\%%~b"=="%~1" (
                if %errorlevel% geq 1 (
                    REM Inherit errorlevel
                    call :%~n0\serrlv %errorlevel%
                    call %0\error %%~a\%%~b !_tmp!
                ) else call %0\more !_tmp!
                goto :eof
            )
            REM init func var, for display all func, or show sort func name
            set _args\%%~b=!_tmp! ""
            REM Clean var
            set _tmp=
        )
    )

    REM Foreach func list
    call :%~n0\gcols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `set _args\%~n1 2^>nul`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a _i+=1
        set _target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :%~n0\rpad !_tmp! %_col%
        if !_i! geq 2 call :%~n0\rpad %%~nxa %_col%
    ) else call :%~n0\2la %%~nxa "%%~b"
    REM Close rpad
    if !_i! gtr 0 call :%~n0\rpad 0 0
    REM Display func or call func
    endlocal & if %_i% gtr 1 (
        echo.
        >&2 echo Warning: function sort name conflict
        exit /b 1
    ) else if %_i%==0 (
        if "%~1" neq "" >&2 echo Error: No function found& exit /b 1
    ) else if %_i%==1 call :%~n0\%_target% || call %0 :%~n0\%_target%
    goto :eof

:this\annotation\error
    for /l %%a in (1,1,%2) do shift /2
    if "%~2"=="" goto :eof
    REM color 0c
    >&2 echo.Error: %~2 (%~s0%~1)
    goto :eof

:this\annotation\more
    echo.%~1
    shift /1
    if "%~1%~2" neq "" goto %0
    exit /b 0

::: "Make the second column left-aligned" "" "    default size is 15" "usage: %~n0 2la [str_1] [str_2]"
:::: "input string is empty"
:lib\2la
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

::: "Use right pads spaces, make all column left-aligned" "" "usage: %~n0 rpad [str] [[col_size]]" "       %~n0 rpad 0 0" "       close command" "       col_size is cols / 15" "       print nobr, but auto LF by col_size"
:::: "input string is empty"
:lib\rpad
    if "%~1"=="" exit /b 1
    if "%~2" neq "" if 1%~2 lss 12 (if defined _rpad echo. & set _rpad=) & exit /b 0
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    if "%~2" neq "" if 1%_rpad% geq 1%~2 echo. & set /a _rpad-=%~2-1
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    >&3 set /p=%~1!_spaces:~0,%_len%!<nul
    set /a _rpad+=1
    if "%~2" neq "" if 1%_rpad% geq 1%~2 echo. & set _rpad=
    endlocal & set _rpad=%_rpad%
    exit /b 0

REM for :lib\2la and :lib\rpad and
:strModulo
    set /a _rpad+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

::: "Get cmd cols" "" "usage: %~n0 gcols [[var_name]]"
:lib\gcols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

::: "Set errorlevel variable"
:lib\serrlv
    if "%~1"=="" goto :eof
    exit /b %1

REM start /b [command...]
:thread
    call %~pnx1
    goto :eof

:: :: :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::


::: "Search file in $env:path" "" "usage: %~n0 search [file_name]" "       support wildcards: * ?" "       e.g. %~n0 Search *ja?a"
:::: "first args is empty"
:lib\search
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    call :lib\gcols _col
    set /a _i=0, _col/=16
    call :lib\trimpath path
    for /f "usebackq delims==" %%a in (
        `dir /a-d /b "!path:;=\%~1*" "!\%~1*" 2^>nul`
    ) do if "%pathext%" neq "!pathext:%%~xa=!" (
        set /a _i+=1
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :lib\rpad !_tmp! %_col%
        if !_i! geq 2 call :lib\rpad %%~nxa %_col%
    )
    REM Close rpad
    call :lib\rpad 0 0
    endlocal & if %_i% gtr 1 (
        echo.
        echo.Find %_i% exec file.
    ) else if %_i%==0 (
        echo.No exec file found.
    ) else call :lib\which %_tmp%
    exit /b 0

::: "Locate a program file in the user's path" "" "usage: %~n0 which [file_full_name]"
:lib\which
    if not defined _p (
        setlocal enabledelayedexpansion
        call :lib\trimpath path
        set _p=!path:;=\;!\
    )
    if "%~a$_p:1"=="" endlocal & exit /b 0
    echo %~$_p:1
    set _p=!_p:%~dp$_p:1=!
    goto %0

::: "Get UUID" "" "usage: %~n0 guuid [[var_name]]"
:lib\guuid
    setlocal enabledelayedexpansion
        for /l %%a in (
            1,1,8
        ) do (
            set /a _1=!random!%%16,_2=!random!%%16,_3=!random!%%16,_4=!random!%%16
            set _0=!_0!!_1!.!_2!.!_3!.!_4!.
            if %%a gtr 1 if %%a lss 6 set _0=!_0!-
        )
        set _0=%_0:10.=a%
        set _0=%_0:11.=b%
        set _0=%_0:12.=c%
        set _0=%_0:13.=d%
        set _0=%_0:14.=e%
        set _0=%_0:15.=f%
    endlocal & if "%~1"=="" (
        echo %_0:.=%
    ) else set %~1=%~2%_0:.=%%~3
    exit /b 0

::: "Get sid by username" "" "usage: %~n0 gsid [user_name] [[var_name]]"
:::: "first parameter is empty"
:lib\gsid
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1" %%a in (
        `wmic.exe useraccount where name^='%1' get sid`
    ) do for %%b in (%%a) do if "%~2"=="" (
        echo.%%b
    ) else set %~2=%%b
    exit /b 0

::: "Get string length" "" "usage: %~n0 glen [string] [[var_name]]"
:::: "string is empty"
:lib\glen
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _len=
    set _str=%~1fedcba9876543210
    if "%_str:~31,1%" neq "" (
        for %%a in (
            4096 2048 1024 512 256 128 64 32 16 8 4 2 1
        ) do if !_str:~%%a^,1!. neq . set /a _len+=%%a & set _str=!_str:~%%a!
        set /a _len-=15
    ) else set /a _len=0x!_str:~15^,1!
    endlocal & if "%~2"=="" (
        echo %_len%
    ) else set %~2=%_len%
    exit /b 0

::: "Get first path foreach Partiton" "" "usage: %~n0 gfirstpath [path_name] [[var_name]]"
:::: "The first parameter is empty" "Target path not found"
:lib\gfirstpath
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1 tokens=1,2" %%a in (
        `wmic.exe logicaldisk get Caption`
    ) do if "%%~aa" neq "" if exist "%%a\%~1" (
        if "%~2"=="" (
            echo %%a\%~1
        ) else set "%~2=%%a\%~1"
        exit /b 0
    )
    exit /b 2

::: "Get Unused Device Id" "" "usage: %~n0 gfreeletter [[var_name]]"
:lib\gfreeletter
    setlocal enabledelayedexpansion
    set _di=zyxwvutsrqponmlkjihgfedcba
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk get DeviceID`
    ) do set _di=!_di:%%a=!
    endlocal & if "%~1"=="" (
        echo.%_di:~0,1%:
    ) else set %~1=%_di:~0,1%:
    exit /b 0

::: "Get Device IDs" "" "usage: %~n0 gletters [var_name] [[l/r/n]]" "       no param view all" "       l: Local Fixed Disk" "       r: CD-ROM Disc" "       n: Network Connection"
:::: "variable name is empty" "type command not support"
:lib\gletters
::: "Get Device IDs DESC" "" "usage: %~n0 grettels [var_name] [[l/r/n]]" "       no param view all" "       l: Local Fixed Disk" "       r: CD-ROM Disc" "       n: Network Connection"
:::: "variable name is empty" "type command not support"
:lib\grettels
    :::::::::::::::::::::::::::::::::::::::
    :: [WARNING] Not support nano server ::
    :::::::::::::::::::::::::::::::::::::::
    if "%~1"=="" exit /b 1
    set _var=
    setlocal enabledelayedexpansion
    set _desc=
    REM Test sort
    for %%a in (%0) do if "%%~na"=="grettels" set _desc=1
    REM add where conditions
    if "%~2" neq "" (
        set _DriveType=
        if /i "%~2"=="l" set _DriveType=3
        if /i "%~2"=="r" set _DriveType=5
        if /i "%~2"=="n" set _DriveType=4
        if not defined _DriveType exit /b 2
        set "_DriveType=where DriveType^^=!_DriveType!"
    )
    REM main
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk %_DriveType% get DeviceID`
    ) do if defined _desc (
        set "_var=%%a !_var!"
    ) else set "_var=!_var! %%a"
    if defined _var set _var=%_var:~1,-2%
    endlocal & set %~1=%_var%
    exit /b 0

::: "Get OS language bit and version" "" "usage: %~n0 gosinf [os_path] [[var_name]]" "       return [var].lang [var].bit [var].ver"
:::: Not OS path or Low OS version"
:lib\gosinf
    if not exist %~1\Windows\servicing exit /b 1

    for /d %%a in (
        %~1\Windows\servicing\Version\*
    ) do (
        REM OS version
        for /f "tokens=1,2 delims=." %%b in (
            "%%~na"
        ) do if "%~2"=="" (
            setlocal enabledelayedexpansion
            set /a _ver=%%b*10+%%c
            >&3 set /p=ver:!_ver!, <nul
            endlocal
        ) else set /a %2.ver=%%b*10+%%c

        REM OS bit
        if exist %%a\amd64_installed (
            if "%~2"=="" (
                >&3 set /p=bin:amd64, <nul
            ) else set %2.bit=amd64
        ) else if "%~2"=="" (
            >&3 set /p=bin:x86, <nul
        ) else set %2.bit=x86
    )
    REM OS language
    for /d %%a in (
        %~1\Windows\servicing\??-??
    ) do if "%~2"=="" (
        set /p=lang:%%~na<nul
    ) else set %2.lang=%%~na

    if "%~2"=="" echo.
    exit /b 0

::: "Test path is directory" "" "usage: call %~n0 idir [path]"
:lib\idir
    setlocal
    set _path=%~a1-
    REM quick return
    set _code=10
    if %_path:~0,1%==d set _code=0
    endlocal & exit /b %_code%

::: "Test path is Symbolic Link" "" "usage: call %~n0 iln [file_path]" "       e.g. call %~n0 iln C:\Test"
:lib\iln
    for /f "usebackq delims=" %%a in (
        `dir /al /b "%~dp1" 2^>nul`
    ) do if "%%a"=="%~n1" exit /b 0
    REM quick return
    exit /b 10

::: "Test directory is empty" "" "usage: call %~n0 ifreedir [dir_path]"
:::: "Not directory"
:lib\ifreedir
    call :lib\idir %1 || exit /b 1
    for /d %%a in ("%~1\*") do exit /b 10
    for /r %1 %%a in (*.*) do exit /b 10
    exit /b 0

::: "Test string if Num" "" "usage: call %~n0 inum [string]"
:lib\inum
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    REM quick return
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

::: "Test string if ip" "" "usage: call %~n0 iip [string]"
:::: "first parameter is empty"
:lib\iip
    if "%~1"=="" exit /b 1
    REM [WARN] use usebackq will set all variable global, by :lib\hosts
    for /f "tokens=1-4 delims=." %%a in (
        "%~1"
    ) do (
        if "%~1" neq "%%a.%%b.%%c.%%d" exit /b 10
        for %%e in (
            "%%a" "%%b" "%%c" "%%d"
        ) do (
            call :lib\inum %%~e || exit /b 10
            if %%~e lss 0 exit /b 10
            if %%~e gtr 255 exit /b 10
        )
    )
    exit /b 0

REM Test mac addr
:this\imac
    setlocal enabledelayedexpansion
    set "_macs=%~1"
    for %%z in (
        %_macs:|= %
    ) do for /f "usebackq tokens=1-6 delims=-:" %%a in (
        '%%z'
    ) do (
        if "%%z" neq "%%a-%%b-%%c-%%d-%%e-%%f" if "%%z" neq "%%a:%%b:%%c:%%d:%%e:%%f" exit /b 10
        for %%g in (
            "%%a" "%%b" "%%c" "%%d" "%%e" "%%f"
        ) do (
            set /a _hx=0x%%~g 2>nul || exit /b 10
            if !_hx! gtr 255 exit /b 10
        )
    )
    endlocal
    exit /b 0

::: "Test script run after pipe"
:lib\ipipe
::: "Test script start at GUI"
:lib\igui
    setlocal
    set cmdcmdline=
    set _cmdcmdline=%cmdcmdline:"='%
    rem "
    set _code=0
    if /i "%0"==":lib\ipipe" if "%_cmdcmdline%"=="%_cmdcmdline:  /S /D /c' =%" set _code=10
    if /i "%0"==":lib\igui" if "%_cmdcmdline%"=="%_cmdcmdline: /c ''=%" set _code=10
    REM if /i "%0"==":lib\igui" for %%a in (%cmdcmdline%) do if /i %%~a==/c set _code=0
    endlocal & exit /b %_code%

::: "Test this system version" "" "usage: call %~n0 ivergeq [version]"
:::: "Parameter is empty or Not a float"
:lib\ivergeq
    if "%~x1"=="" exit /b 1
    setlocal
    if exist %windir%\servicing\Version\*.* (
        for /f "usebackq tokens=1,2 delims=." %%a in (
            `dir /ad /b %windir%\servicing\Version\*.*`
        ) do for /f "usebackq tokens=1,2 delims=." %%c in (
            '%~1'
        ) do set /a _tmp=%%a*10+%%b-%%c*10-%%d
    ) else for /f "usebackq delims=" %%a in (
        `ver`
    ) do for %%b in (%%a) do if "%%~xb" neq "" for /f "usebackq tokens=1-4 delims=." %%c in (
        '%~1.%%b'
    ) do set /a _tmp=%%e*10+%%f-%%c*10-%%d
    endlocal & if %_tmp% geq 0 exit /b 0
    exit /b 10

::: "Test exe if live" "" "usage: %~n0 irun [exec_name]"
:::: "First parameter is empty"
:lib\irun
    REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 1
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (
        `wmic.exe process where caption^="%~n1.exe" get commandline /value 2^>nul`
    ) do for %%b in (
        %%a
    ) do if "%%~nb"=="%~n1" exit /b 0
    REM "
    exit /b 10

::: "Kill process" "" "usage: %~n0 lib kill [process_name...]"
:::: "first parameter is empty"
:lib\kill
    if "%~1"=="" exit /b 1
    for %%a in (
        %*
    ) do wmic.exe process where name="%%a.exe" delete

    REM for /f "usebackq skip=1" %%a in (
    REM     `wmic.exe process where "commandline like '%*'" get processid 2^>nul`
    REM ) do for %%b in (%%a) do >nul wmic.exe process where processid="%%b" delete

    REM start "" /b "%~f0" %*

    REM taskkill.exe /f /im %~1.exe
    exit /b 0

::: "Delete empty directory" "" "usage: %~n0 trimdir [dir_path]"
:::: "target not found" "target not a directory"
:lib\trimdir
    if not exist "%~1" exit /b 1
    call :lib\idir %1 || exit /b 2
    if exist %windir%\system32\sort.exe (
        call :trimdir\rdNullDirWithSort %1
    ) else call :trimdir\rdNullDir %1
    exit /b 0

REM for :lib\trimdir
:trimdir\rdNullDir
    if "%~1"=="" exit /b 0
    if "%~2"=="" (
        call %0 "%~dp1" .
        exit /b 0
    ) else for /d %%a in (
        %1*
    ) do (
        rmdir "%%~a" 2>nul || call %0 "%%~a\" .
        call %0 "%%~a\" .
    )
    exit /b 0

REM for :lib\trimdir
:trimdir\rdNullDirWithSort
    if "%~1"=="" exit /b 1
    for /f "usebackq delims=" %%a in (
        `dir /ad /b /s %1 ^| sort.exe /r`
    ) do 2>nul rmdir "%%~a"
    exit /b 0

::: "Get some backspace (erases previous character)" "" "usage: %~n0 gbs [var_name]"
:::: "string length is empty"
:lib\gbs
    if "%~1"=="" exit /b 1
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set %~1=%%a
    exit /b 0

::: "Unset variable, where variable name left contains" "" "usage: %~n0 uset [var_left_name]"
:::: "The parameter is empty"
:lib\uset
    if "%~1"=="" exit /b 1
    for /f "usebackq delims==" %%a in (
        `set %1 2^>nul`
    ) do set %%a=
    exit /b 0

::: "Uncompress msi file" "" "usage: %~n0 umsi [msi_file_path]"
:::: "file not found" "file format not msi" "output directory already exist"
:lib\umsi
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".msi" exit /b 2
    mkdir ".\%~n1" 2>nul || exit /b 3
    setlocal
    REM Init
    call :lib\gfreeletter _letter
    subst.exe %_letter% ".\%~n1"

    REM Uncompress msi file
    start /wait msiexec.exe /a %1 /qn targetdir=%_letter%
    erase "%_letter%\%~nx1"
    REM for %%a in (".\%~n1") do echo output: %%~fa

    subst.exe %_letter% /d
    endlocal
    exit /b 0

::: "Uncompress chm file" "" "usage: %~n0 uchm [chm_path]"
:::: "chm file not found" "not chm file" "out put file allready exist"
:lib\uchm
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".chm" exit /b 2
    if exist ".\%~sn1" exit /b 3
    start /wait hh.exe -decompile .\%~sn1 %~s1
    exit /b 0

::: "Set environment variable" "" "usage: %~n0 senvar [key] [value]"
:::: "key is empty" "value is empty"
:lib\senvar
    if "%~1"=="" exit /b 1
    if "%~2"=="" exit /b 2
    for %%a in (setx.exe) do if "%%~$path:a" neq "" setx.exe %~1 %2 /m >nul & exit /b 0
    if defined %~1 wmic.exe environment where name="%~1" set VariableValue="%~2"
    if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

REM ::: "Delete Login Notes"
REM :lib\delLoginNote
REM     net.exe use * /delete
REM     exit /b 0

::: "Reset default path environment variable"
:lib\repath
    for /f "usebackq tokens=2 delims==" %%a in (
        `wmic.exe ENVIRONMENT where "name='path'" get VariableValue /format:list`
    ) do set path=%%a
    REM Trim unprint char
    set path=%path%
    exit /b 0

::: "Run As Administrator" "" "usage: %~n0 a [*]"
:lib\a
    REM net.exe user administrator /active:yes
    REM net.exe user administrator ???
    runas.exe /savecred /user:administrator "%*"
    exit /b 0

::: "Calculating time intervals, print use time" "" "must be run it before and after function"
:lib\centiTime
    setlocal
    set time=
    for /f "tokens=1-4 delims=:." %%a in (
        "%time%"
    ) do set /a _tmp=%%a*360000+1%%b%%100*6000+1%%c%%100*100+1%%d%%100
    if defined _centiTime (
        set /a _tmp-=_centiTime
        set /a _h=_tmp/360000,_min=_tmp%%360000/6000,_s=_tmp%%6000/100,_cs=_tmp%%100
        set _tmp=
    )
    if defined _centiTime echo %_h%h %_min%min %_s%s %_cs%cs
    endlocal & set _centiTime=%_tmp%
    exit /b 0

::: "Update hosts by ini"
:::: "no ini file found"
:lib\hosts
    setlocal enabledelayedexpansion
    REM load ini config
    call :this\load_ini hosts 1 || exit /b 1
    REM get key array
    call :map -ks _keys 1
    REM override mac to ipv4
    for /f "usebackq tokens=1*" %%a in (
        `call lib.cmd ip -f %_keys%`
    ) do if not defined _set\%%a (
        call :map -p %%a %%b 1 && call :lib\2la %%~a %%b
        set _set\%%a=-
    )

    REM replace hosts in cache
    REM use tokens=2,3 will replace %%a
    for /f "usebackq tokens=1* delims=]" %%a in (
        `type %windir%\System32\drivers\etc\hosts ^| find.exe /n /v ""`
    ) do for /f "usebackq tokens=1-3" %%c in (
        '. %%b'
    ) do call :lib\iip %%d && (
        if defined _MAP1\%%e (
            for %%f in (
                !_MAP1\%%e!
            ) do call :lib\iip "%%~f" && (
                set _line=%%b
                call :page -p !_line:%%d=%%f!
            ) || call :page -p %%b
            set _MAP1\%%e=
        ) else call :page -p %%b
    ) || call :page -p %%b

    call :map -a _arr 1

    for %%a in (
        %_arr%
    ) do (
        call :lib\iip %%a && (
            call :page -p %%~a   !_key!
        )
        set _key=%%~a
    )

    call :page -s > %windir%\System32\drivers\etc\hosts

    endlocal
    goto :eof

::: "Ipv4" "" "usage: %~n0 ip [option]" "-l         Show this ipv4" "-f [MAC]   Search IPv4 by MAC or Host name"
:::: "MAC addr or Host name is empty" "args not mac addr" "args is empty"
:lib\ip
    if "%~1"=="" exit /b 3
    call :this\ip\%* 2>nul
    goto :eof

:this\ip\-l
:this\ip\--list
    setlocal
    REM Get router ip
    call :this\grouteIp _route
    REM "
    for %%a in (
        %_route%
    ) do for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%b in (
        `wmic.exe NicConfig get IPAddress`
    ) do if "%%~nb"=="%%~na" echo %%b
    endlocal
    exit /b 0

:this\ip\-f
:this\ip\--find
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion

    REM get config
    call :this\load_ini sip_setting
    call :map -g route _routes
    call :map -g range _range
    call :map -c
    if not defined _range set _range=1-127

    call :this\load_ini hosts

    set _macs=

    for %%a in (
        %*
    ) do (
        set _arg=
        REM Get value
        call :map -g %%a _arg
        if defined _arg (
            set "_mac=!_arg: =!"
        ) else set _mac=%%a
        REM Format
        set "_mac=!_mac::=-!"
        REM Test is mac addr
        call :this\imac "!_mac!" && (
            set "_macs=!_macs! !_mac:|=\!"
            if defined _arg set "_macs=!_macs!.%%a"
        )
    )

    REM [MAC]\[MAC]\.[NAME] ...
    if not defined _macs exit /b 0

    REM Get router ip
    call :this\grouteIp _grouteIp
    for %%a in (
        %_routes% %_grouteIp%
    ) do if not defined _tmp\%%~na (
        set _tmp\%%~na=-
        set "_route=!_route! %%a"
    )

    REM Clear arp cache
    arp.exe -d
    REM Search MAC
    for %%a in (
        %_route%
    ) do for /l %%b in (
        %_range:-=,1,%
    ) do (
        call :this\thread_valve 50 cmd.exe --find
        start /b lib.cmd \\:ip\--find %%~na.%%b %_macs%
    )
    endlocal
    exit /b 0

REM nbtstat
REM For thread sip
:ip\--find
    REM some ping will fail, but arp success
    ping.exe -n 1 -w 1 %1 >nul 2>nul
    setlocal enabledelayedexpansion
    for /f "usebackq skip=3 tokens=1,2" %%a in (
        `arp.exe -a %1`
    ) do for %%c in (
        %*
    ) do for /f "usebackq tokens=1* delims=." %%d in (
        '%%c'
    ) do (
        set "_macs=%%d"
        set "_macs=!_macs:\= !"
        for %%f in (
            !_macs!
        ) do if /i "%%b"=="%%f" if "%%e"=="" (
            call :lib\2la %%f %%a
        ) else call :lib\2la %%e %%a
    )

    endlocal
    exit /b 0

REM thread valve, usage: :this\thread_valve [count] [name] [commandline]
:this\thread_valve
    set /a _thread\count+=1
    if %_thread\count% lss %~1 exit /b 0
    :thread_valve\loop
        set _thread\count=0
        for /f "usebackq" %%a in (
            `wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid 2^>nul ^| %windir%\System32\find.exe /c /v ""`
        ) do set /a _thread\count=%%a - 2
        if %_thread\count% gtr %~1 goto thread_valve\loop
    exit /b 0

REM Map
:map
    call :this\map\%*
    goto :eof

:this\map\--put
:this\map\-p
    if "%~2"=="" exit /b 0
    set "_MAP%~3\%~1=%~2"
    exit /b 0

:this\map\--get
:this\map\-g
    if "%~2"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _value=
    if defined _MAP%~3\%~1 call set "_value=!_MAP\%~1!"
    endlocal & set "%~2=%_value%"
    exit /b 0

:this\map\--remove
:this\map\-r
    set _MAP%~2\%~1=
    exit /b 0

:this\map\--keys
:this\map\-ks
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _keys=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _MAP%~2\ 2^>nul`
    ) do set "_keys=!_keys! "%%~nxa""
    endlocal & set %~1=%_keys%
    exit /b 0

:this\map\--values
:this\map\-vs
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _values=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _MAP%~2\ 2^>nul`
    ) do set "_values=!_values! "%%~b""
    endlocal & set %~1=%_values%
    exit /b 0

:this\map\--arr
:this\map\-a
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _kv=
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _MAP%~2\ 2^>nul`
    ) do set "_kv=!_kv! "%%~nxa" "%%~b""
    endlocal & set %~1=%_kv%
    exit /b 0

:this\map\--size
:this\map\-s
    setlocal
    set _count=0
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _MAP%~1\ 2^>nul`
    ) do set /a _count+=1
    endlocal & exit /b %_count%

:this\map\--clear
:this\map\-c
    call :lib\uset _MAP%~1\
    exit /b 0

REM page
:page
    call :this\page\%*
    goto :eof

:this\page\--put
:this\page\-p
    if not defined _page set _page=1000000000
    set /a _page+=1
    if .%1==. (
        set _page\%_page%=.
    ) else set _page\%_page%=.%*
    exit /b 0

:this\page\--show
:this\page\-s
    for /f "usebackq tokens=1* delims==" %%a in (
        `set _page\`
    ) do echo%%b
    exit /b 0

:this\pads\--clear
:this\page\-c
    call :lib\uset _page
    exit /b 0

REM load .*.ini config
:this\load_ini
    if "%~1"=="" exit /b 1
    set _tag=
    for /f "usebackq delims=; 	" %%a in (
        `type "%~dp0.*.ini" "%userprofile%\.*.ini" 2^>nul ^| findstr.exe /v "^;"`
    ) do for /f "usebackq tokens=1,2 delims==" %%b in (
        '%%a'
    ) do if "%%c"=="" (
        if "%%b"=="[%~1]" (
            set _tag=true
        ) else set _tag=
    ) else if defined _tag set "_MAP%~2\%%b=%%c"
    set _tag=

    REM REM Load
    REM for /f "usebackq tokens=1* delims==" %%a in (
    REM     `set`
    REM ) do if "%%~da" neq "\\" (
    REM     call :this\imac %%~b && set _MAP%~2\%%a=%%~b
    REM     call :lib\iip %%~b && set _MAP%~2\%%a=%%~b
    REM )

    call :map -s %~2 && exit /b 1
    exit /b 0

REM Get router ip
:this\grouteIp
    if "%~1"=="" exit /b 1
    REM "
    for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%a in (
        `wmic.exe NicConfig get DefaultIPGateway`
    ) do set %1=%%a
    exit /b 0

::: "Display Time at [YYYYMMDDhhmmss]" "" "usage: %~n0 gnow [var_name] [[head_string]] [[tail_string]]"
:::: "variable name is empty"
:lib\gnow
    if "%~1"=="" exit /b 1
::: "Display Time at [YYYY-MM-DD hh:mm:ss]" "" "usage: %~n0 now [[string]]" "      nobr"
REM :lib\now
REM en zh
    set date=
    set time=
    for /f "tokens=1-8 delims=-/:." %%a in (
      "%time: =%.%date: =.%"
    ) do if %%e gtr 1970 (
        REM if /i "%0"==":lib\gnow" (
            set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
        REM ) else >&3 set /p=%*[%%e-%%f-%%g %%a:%%b:%%c]<nul
    ) else if %%g gtr 1970 (
        REM if /i "%0"==":lib\gnow" (
            set %~1=%~2%%g%%e%%f%%a%%b%%c%~3
        REM ) else >&3 set /p=%*[%%g-%%e-%%f %%a:%%b:%%c]<nul
    )
    exit /b 0

::: "Path Standardize" "" "usage: %~n0 trimpath [var_name]"
:::: "variable name is empty" "variable name not defined"
:lib\trimpath
    if "%~1"=="" exit /b 1
    if not defined %~1 exit /b 2
    setlocal enabledelayedexpansion
    REM todo get var value in path
    REM Trim quotes
    set _var=!%~1:"=!
    REM " Trim head/tail semicolons
    if "%_var:~0,1%"==";" set _var=%_var:~1%
    if "%_var:~-1%"==";" set _var=%_var:~0,-1%
    REM Replace slash end of path
    set _var=%_var:\;=;%;
    REM Delete path if not exist
    call :this\trimpath "%_var:;=" "%"
    endlocal & set %~1=%_var:~0,-1%
    exit  /b 0

REM for :lib\trimpath, delete path if not exist
:this\trimpath
    if "%~1"=="" exit /b 0
    if not exist %1 set _var=!_var:%~1;=!
    shift /1
    goto %0

::: "Change file/directory owner !username!" "" "usage: %~n0 own [path]"
:::: "path not found"
:lib\own
    if not exist "%~1" exit /b 1
    call :lib\idir %1 && takeown.exe /f %1 /r /d y && icacls.exe %1 /grant:r %username%:f /t /q
    call :lib\idir %1 || takeown.exe /f %1 && icacls.exe %1 /grant:r %username%:f /q
    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download something" "" "usage: %~n0 download [url] [output]"
:::: "url is empty" "output path is empty" "powershell version is too old"
:lib\download
    if "%~1"=="" exit /b 1
    REM if "%~2"=="" exit /b 2
    call :this\gpsv
    if errorlevel 3 PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" & exit /b 0
    call :lib\vbs get %1 %2
    exit /b 0

::: "Print the last some lines of FILE to standard output." "" "usage: %~n0 tail [-[count]]"
:::: "powershell version is too old" "args error"
:lib\tail
    call :this\gpsv
    if not errorlevel 3 exit /b 1
    call :this\lines -Last %*|| exit /b 2
    goto :eof

::: "Print the first some lines of FILE to standard output." "" "usage: %~n0 head [-[count]]"
:::: "powershell version is too old" "args error"
:lib\head
    call :this\gpsv
    if not errorlevel 3 exit /b 1
    call :this\lines -first %*|| exit /b 2
    goto :eof

REM for head tail
:this\lines
    setlocal
    if "%~2"=="" exit /b 1
    set _count=%~2
    set _count=%_count:-=%
    call :lib\inum %_count% || exit /b 1
    if exist "%~3" (
        PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Get-Content \"%~3\" %~1 %_count%"
    ) else PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$Input | Select-Object %~1 %_count%"
    endlocal
    goto :eof


::: "Print or check MD5 (128-bit) checksums." "" "usage: %~n0 md5 [file]"
:::: "powershell error"
:lib\MD5
::: "Print or check SHA1 (160-bit) checksums." "" "usage: %~n0 sha1 [file]"
:::: "powershell error"
:lib\SHA1
::: "Print or check SHA256 (256-bit) checksums." "" "usage: %~n0 sha256 [file]"
:::: "powershell error"
:lib\SHA256
::: "Print or check SHA512 (512-bit) checksums." "" "usage: %~n0 sha512 [file]"
:::: "powershell error"
:lib\SHA512
    for %%a in (%0) do call :this\hash %%~na %1|| exit /b 1
    shift /1
    if exist "%~1" call %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
    exit /b 0

:this\hash
    if exist "%~2" for /f "usebackq tokens=1,2" %%a in (
        `certutil.exe -hashfile %2 %~1`
    ) do if "%%b"=="" echo %%a   %2& exit /b 0
    setlocal
    call :this\gpsv
    if not errorlevel 2 exit /b 1
    REM set _arg=-
    REM if exist "%~2" (
    REM     set "_arg=%~2"
    REM     for /f "usebackq" %%a in (
    REM         `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([System.IO.File]::Open(\"%2\",[System.IO.Filemode]::Open,[System.IO.FileAccess]::Read))).ToString() -replace \"-\""`
    REM     ) do set _hash=%%a
    REM ) else
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.%~1CryptoServiceProvider).ComputeHash([Console]::OpenStandardInput())).ToString() -replace \"-\""`
    ) do set _hash=%%a
    if "%_hash%"=="" exit /b 2
    set _hash=%_hash:A=a%
    set _hash=%_hash:B=b%
    set _hash=%_hash:C=c%
    set _hash=%_hash:D=d%
    set _hash=%_hash:E=e%
    set _hash=%_hash:F=f%
    endlocal & echo %_hash%   -
    exit /b 0

::: "Test PowerShell version" "" "Return errorlevel"
:this\gpsv
    for %%a in (PowerShell.exe) do if "%%~$path:a"=="" exit /b 0
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$PSVersionTable.WSManStackVersion.Major" 2^>nul`
    ) do exit /b %%a
    exit /b 0

::: "Run PowerShell script" "" "usage: %~n0 ps1 [ps1_script_path]"
:::: "ps1 script not found" "file suffix error"
:lib\ps1
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".ps1" exit /b 2
    PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %*
    goto :eof

::: "Encode password to base64 string for unattend.xml" "" "usage: %~n0 gbase64pw [string] [[var_name]]"
:::: "System version is too old" "Args is empty"
:lib\gbase64pw
    call :lib\ivergeq 6.1 || exit /b 1
    if "%~1"=="" exit /b 2
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"`
    ) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

::::::::::::::
:: VBScript ::
::::::::::::::

::: "Run some command at background"
:::: "The first parameter is empty"
:lib\vbhide
    if "%~1"=="" exit /b 1
    REM mshta.exe VBScript:CreateObject("WScript.Shell").Run("""%~1"" %~2", 0)(Window.close)
    REM see https://msdn.microsoft.com/en-us/library/windows/desktop/gg537745(v=vs.85).aspx?cs-save-lang=1&cs-lang=vb#code-snippet-1
    REM mshta.exe VBScript:CreateObject("Shell.Application").ShellExecute("%~1","%2 %3 %4 %5 %6 %7 %8 %9","","open",0)(window.close)
    call :lib\vbs vbhide "%~1"
    exit /b 0

REM screnc.exe from http://download.microsoft.com/download/0/0/7/0073477f-bbf9-4510-86f9-ba51282531e3/sce10en.exe
REM if /i "%~x1"==".vbs" screnc.exe %1 ./%~n1.vbe

::: "Run VBScript library from lib.vbs" "" "usage: %~n0 vbs [[command...]]"
:::: "lib.vbs not found"
:lib\vbs
    REM cscript.exe //nologo //e:vbscript.encode %*
    for %%a in (lib.vbs) do if "%%~$path:a"=="" (
        exit /b 1
    ) else cscript.exe //nologo "%%~$path:a" %* 2>&3 || exit /b 10
    goto :eof

::: "Tag date time each line" "" "usage: %~n0 log [strftime format]"
:lib\log
    call :lib\vbs log %*
    goto :eof

::: "Zip or unzip" "" "usage: %~n0 zip [source_path] [[target_path]]"
:lib\zip
    if not exist "%~1" exit /b 1
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    REM zip
    if /i "%~x1" neq ".zip" call :lib\vbs zip "%~f1" "%_output%.zip"
    REM unzip
    if /i "%~x1"==".zip" call :lib\vbs unzip "%~f1" "%_output%"
    endlocal
    REM >.\zip.ZFSendToTarget (
    REM     echo [Shell]
    REM     echo Command=2
    REM     echo IconFile=explorer.exe,3
    REM     echo [Taskbar]
    REM     echo Command=ToggleDesktop
    REM )
    exit /b 0

::::::::::::::::::

::: "Create cab package"
:::: "cabarc.exe file not found"
:lib\cab
    for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 1

    REM By directory
    if "%~2"=="" call :lib\idir %1 && cabarc.exe -m LZX:21 n ".\%~n1.tmp" "%~1\*"&& goto cab\eof

    REM uncab
    pushd %cd%
    if "%~2"=="" if "%~x1"==".cab" mkdir ".\%~n1" && chdir /d ".\%~n1" && cabarc.exe x %1 *& goto cab\eof

    REM By file
    popd
    cabarc.exe -m LZX:21 n ".\%~n1.tmp" %*

    REM Complete
    :cab\eof
	if exist ".\%~n1.tmp" rename ".\%~n1.tmp" "%~n1.cab"
    exit /b 0


::: "Create iso file from directory" "" "usage: %~n0 udf [dir_path]"
:::: "target not directory" "not support driver" "need etfsboot.com or efisys.bin"
 :lib\udf
    for %%a in (oscdimg.exe) do if "%%~$path:a"=="" call :init\oscdimg >nul
    call :lib\idir %1 ||  exit /b 1
    if /i "%~d1\"=="%~1" exit /b 2

    REM empty name
    if "%~n1"=="" (
        setlocal enabledelayedexpansion
        set _args=%~1
        if "!_args:~-1!" neq "\" (
            call :lib\serrlv 2
        ) else call %0 "!_args:~0,-1!"
        endlocal & goto :eof
    )

    if exist "%~1\sources\boot.wim" (
        REM winpe iso
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 3
        if not exist %windir%\Boot\DVD\EFI\en-US\efisys.bin exit /b 3
        REM echo El Torito udf %~nx1
        >%temp%\bootorder.txt type nul
        for %%a in (
            bootmgr
            boot\bcd
            boot\boot.sdi
            efi\boot\bootx64.efi
            efi\microsoft\boot\bcd
            sources\boot.wim
        ) do if exist "%~1\%%a" >>%temp%\bootorder.txt echo %%a
        oscdimg.exe -bootdata:2#p0,e,b%windir%\Boot\DVD\PCAT\etfsboot.com#pEF,e,b%windir%\Boot\DVD\EFI\en-US\efisys.bin -yo%temp%\bootorder.txt -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
        erase %temp%\bootorder.txt
    ) else if exist "%~1\I386\NTLDR" (
        REM winxp iso
        REM echo El Torito %~nx1
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 3
        oscdimg.exe -b%windir%\Boot\DVD\PCAT\etfsboot.com -k -l"%~nx1" -m -n -o -w1 %1 ".\%~nx1.tmp"
    ) else (
        REM normal iso
        REM echo oscdimg udf
        oscdimg.exe -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
    )
    rename "./%~nx1.tmp" "*.iso"
    exit /b 0

REM from Window 10 aik, will download oscdimg.exe at script path
:init\oscdimg
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk bbf55224a0290f00676ddc410f004498 fild40c79d789d460e48dc1cbd485d6fc2e

    REM x86
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk 5d984200acbde182fd99cbfbe9bad133 fil720cc132fbb53f3bed2e525eb77bdbc1
    exit /b 0

REM for :init\?
:this\getCab [file_name] [uri_sub] [cab] [file]
    call :lib\download http://download.microsoft.com/download/%~2/Installers/%~3.cab %temp%\%~1.cab
    expand.exe %temp%\%~1.cab -f:%~4 %temp%
    erase %temp%\%~1.cab
    move %temp%\%~4 %~dp0%~1.exe
    exit /b 0

::: "Print text skip some line" "" "usage: %~n0 skiprint [source_file_path] [skip_line_num] [target_flie_path]"
:::: "source file not found" "skip number error" "target file not found"
:lib\skiprint
    if not exist "%~1" exit /b 1
    call :lib\inum %~2 || exit /b 2
    if not exist "%~3" exit /b 3
    REM >%3 type nul
    REM for /f "usebackq skip=%~2 delims=" %%a in (
    REM     "%~f1"
    REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

::: "Output text or read config" "" "usage: %~n0 execline [text_file_path] [skip_line]" "       need enabledelayedexpansion" "       skip must reset" "       text format: EOF [output_target] [command]"
:::: "skip line is empty" "file not found"
:lib\execline
    if "%~1"=="" exit /b 1
    if not exist "%~2" exit /b 2
    set _log=nul
    set "_exec=REM "
    for /f "usebackq skip=%~2 delims=" %%a in (
        "%~f1"
    ) do for /f "tokens=1,2*" %%b in (
        "%%a"
    ) do if "%%b"=="EOF" (
        if "%%c"=="%%~fc" if not exist "%%~dpc" (
            mkdir "%%~dpc"
        ) else if exist "%%~c" erase "%%~c"
        set "_log=%%~c"
        set "_exec=%%~d"
    ) else >>!_log! !_exec!%%~a
    set _log=
    set _exec=
    exit /b 0

REM text format for :lib\execline
EOF !temp!\!_now!.log "echo "
some codes
EOF nul set
a=1
EOF nul "rem "

;:: set /a 0x7FFFFFFF
;:: 2147483647 ~ -2147483647
;:: PowerShell : hyper-v install-windowsfeature server-gui-shell
;:: data:application/cab;base64,

REM :lib\sexport
REM     SecEdit.exe /export /cfg .\hisecws.inf
REM     exit /b 0
REM     SecEdit.exe /configure /db c:\Windows\Temp\hisecws.sdb /cfg c:\Windows\Temp\hisecws.inf /log c:\Windows\Temp\hisecws.log /quiet
