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

REM init errorlevel
set errorlevel=

REM For thread
if "%~d1"=="\\" call :thread "%*" & exit

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & exit /b 0
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & exit /b 0

call :%~n0\%* 2>nul

REM Test type function
if errorlevel 10 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:lib\
:lib\-h
:lib\--help
    call :this\annotation
    exit /b 0

::: "Output version and exit"
:lib\version
    >&3 echo 0.18.3
    exit /b 0

::: "$env:path operation" "" "usage: %~n0 path [option] [...]" "" "    --contain, -i  [file_name]         Test target in $env:path" "    --trim,    -t  [var_name]          Path Standardize" "    --reset,   -r                      Reset default path environment variable"
REM  "    --search,  -s  [file_name]         Search file in $env:path, and print path" "                                       support wildcards: * ?" "                                  e.g. " "                                       %~n0 path --search *ja?a" "    --which,   -w  [file_full_name]    Locate a program file in the user's path"
:::: "invalid option" "first args is empty" "variable name is empty" "variable name not defined"
:lib\path
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\path\%*
    goto :eof

:this\path\-i
:this\path\--contain
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 10

REM :this\path\-s
REM :this\path\--search
REM     if "%~1"=="" exit /b 2
REM     setlocal enabledelayedexpansion
REM     call :lib\cols _col
REM     set /a _i=0, _col/=16
REM     call :lib\trimpath path
REM     for /f "usebackq delims==" %%a in (
REM         `2^>nul dir /a-d /b "!path:;=\%~1*" "!\%~1*"`
REM     ) do if "%pathext%" neq "!pathext:%%~xa=!" (
REM         set /a _i+=1
REM         if !_i!==1 set _tmp=%%~nxa
REM         if !_i!==2 call :lib\lals !_tmp! %_col%
REM         if !_i! geq 2 call :lib\lals %%~nxa %_col%
REM     )
REM     REM Close lals
REM     call :lib\lals 0 0
REM     endlocal & if %_i% gtr 1 (
REM         echo.
REM         echo.Find %_i% exec file.
REM     ) else if %_i%==0 (
REM         echo.No exec file found.
REM     ) else call :this\path\--which %_tmp%
REM     exit /b 0

REM :this\path\-w
REM :this\path\--which
REM     if not defined _p (
REM         setlocal enabledelayedexpansion
REM         call :lib\trimpath path
REM         set _p=!path:;=\;!\
REM     )
REM     if "%~a$_p:1"=="" endlocal & exit /b 0
REM     echo %~$_p:1
REM     set _p=!_p:%~dp$_p:1=!
REM     goto %0

:this\path\-t
:this\path\--trim
    if "%~1"=="" exit /b 3
    if not defined %~1 exit /b 4
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
    call :this\path\trim "%_var:;=" "%"
    endlocal & set %~1=%_var:~0,-1%
    exit  /b 0

REM for :this\path\--trim, delete path if not exist
:this\path\trim
    if "%~1"=="" exit /b 0
    if not exist %1 set _var=!_var:%~1;=!
    shift /1
    goto %0

:this\path\-r
:this\path\--reset
    for /f "usebackq tokens=2 delims==" %%a in (
        `wmic.exe ENVIRONMENT where "Caption='<SYSTEM>\\Path'" get VariableValue /format:list`
    ) do call set path=%%a
    exit /b 0

::: "Variable tool" "" "usage: %~n0 var [option] [...]" "" "    --unset, -u   [[var_name]]      Unset variable, where variable name left contains" "    --env,   -e   [key] [value]     Set environment variable" "    --errlv, -el  [num]             Set errorlevel variable"
:::: "invalid option" "key is empty" "value is empty" "The parameter is empty"
:lib\var
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\var\%*
    goto :eof

:this\var\-u
:this\var\--unset
    if "%~1"=="" exit /b 4
    for /f "usebackq delims==" %%a in (
        `2^>nul set %1`
    ) do set %%a=
    exit /b 0

:this\var\-e
:this\var\--env
    if "%~1"=="" exit /b 2
    if "%~2"=="" exit /b 3
    REM for %%a in (setx.exe) do if "%%~$path:a" neq "" setx.exe %~1 %2 /m >nul & exit /b 0
    if defined %~1 wmic.exe environment where 'name="%~1" and username="<system>"' set VariableValue="%~2"
    if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

:this\var\-el
:this\var\--errlv
    if "%~1"=="" goto :eof
    exit /b %1


::: "Run by ..." "" "usage: %~n0 run [option]" "" "    --admin,  -a  [...]    Run As Administrator" "    --vbhide, -q  [...]    Run some command at background"
:::: "invalid option" "The first parameter is empty"
:lib\run
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\run\%*
    goto :eof

:this\run\-a
:this\run\--admin
    REM net.exe user administrator /active:yes
    REM net.exe user administrator ???
    runas.exe /savecred /user:administrator "%*"
    exit /b 0

:this\run\-q
:this\run\--vbhide
    if "%~1"=="" exit /b 2
    REM mshta.exe VBScript:CreateObject("WScript.Shell").Run("""%~1"" %~2", 0)(Window.close)
    REM see https://msdn.microsoft.com/en-us/library/windows/desktop/gg537745(v=vs.85).aspx?cs-save-lang=1&cs-lang=vb#code-snippet-1
    REM mshta.exe VBScript:CreateObject("Shell.Application").ShellExecute("%~1","%2 %3 %4 %5 %6 %7 %8 %9","","open",0)(window.close)
    call :lib\vbs vbhide "%~1"
    exit /b 0

::: "Get sid by username" "" "usage: %~n0 gsid [user_name] [[var_name]]"
:::: "first parameter is empty"
:lib\sid
    if "%~1"=="" exit /b 1
    for /f "usebackq skip=1" %%a in (
        `wmic.exe useraccount where name^='%1' get sid`
    ) do for %%b in (%%a) do if "%~2"=="" (
        echo.%%b
    ) else set %~2=%%b
    exit /b 0

::: "Get string length" "" "usage: %~n0 len [string] [[var_name]]"
:::: "string is empty"
:lib\len
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

::: "Test string if Num" "" "usage: call %~n0 inum [string]"
:lib\inum
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    REM quick return
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

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

::: "Process tools" ""  "usage: %~n0 ps [option] [...]" "" "    --kill, -k [process_name...]  kill process" "    --test, -t [exec_name]        Test exe if live"
:::: "invalid option" "first parameter is empty"
:lib\ps
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\ps\%*
    goto :eof

:this\ps\-t
:this\ps\--test
    REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 2
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (
        `2^>nul wmic.exe process where caption^="%~n1.exe" get commandline /value`
    ) do for %%b in (
        %%a
    ) do if "%%~nb"=="%~n1" exit /b 0
    REM "
    exit /b 10

:this\ps\-k
:this\ps\--kill
    if "%~1"=="" exit /b 2
    for %%a in (
        %*
    ) do wmic.exe process where name="%%a.exe" delete

    REM for /f "usebackq skip=1" %%a in (
    REM     `2^>nul wmic.exe process where "commandline like '%*'" get processid`
    REM ) do for %%b in (%%a) do >nul wmic.exe process where processid="%%b" delete

    REM start "" /b "%~f0" %*

    REM taskkill.exe /f /im %~1.exe
    exit /b 0

::: "Get some backspace (erases previous character)" "" "usage: %~n0 bs [var_name]"
:::: "string length is empty"
:lib\bs
    if "%~1"=="" exit /b 1
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set %~1=%%a
    exit /b 0

::: "Calculating time intervals, print use time" "" "must be run it before and after function"
:lib\ctime
    setlocal
    set time=
    for /f "tokens=1-4 delims=:." %%a in (
        "%time%"
    ) do set /a _tmp=%%a*360000+1%%b%%100*6000+1%%c%%100*100+1%%d%%100
    if defined _ctime (
        set /a _tmp-=_ctime
        set /a _h=_tmp/360000,_min=_tmp%%360000/6000,_s=_tmp%%6000/100,_cs=_tmp%%100
        set _tmp=
    )
    if defined _ctime echo %_h%h %_min%min %_s%s %_cs%cs
    endlocal & set _ctime=%_tmp%
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
        `call %~nx0 ip --find %_keys%`
    ) do if not defined _set\%%a (
        call :map -p %%a %%b 1 && call :lib\lali %%~a %%b
        set _set\%%a=-
    )

    REM replace hosts in cache
    REM use tokens=2,3 will replace %%a
    for /f "usebackq tokens=1* delims=]" %%a in (
        `type %windir%\System32\drivers\etc\hosts ^| find.exe /n /v ""`
    ) do for /f "usebackq tokens=1-3" %%c in (
        '. %%b'
    ) do call :this\ip\--test %%d && (
        if defined _MAP1\%%e (
            for %%f in (
                !_MAP1\%%e!
            ) do call :this\ip\--test "%%~f" && (
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
        call :this\ip\--test %%a && (
            call :page -p %%~a   !_key!
        )
        set _key=%%~a
    )

    call :page -s > %windir%\System32\drivers\etc\hosts

    endlocal
    goto :eof

::: "Ipv4 tools" "" "usage: %~n0 ip [option]" "" "    --test, -t [str]      Test string if ipv4" "    --list, -l            Show this ipv4" "    --find, -f [MAC] ...  Search IPv4 by MAC or Host name"
:::: "invalid option" "host name is empty" "args not mac addr"
:lib\ip
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\ip\%* 2>nul
    goto :eof

:this\ip\-t
:this\ip\--test
    if "%~1"=="" exit /b 2
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
    if "%~1"=="" exit /b 2
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
        call :this\testMACaddr "!_mac!" && (
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
        start /b %~nx0 \\:ip\--find %%~na.%%b %_macs%
    )
    endlocal
    exit /b 0

REM Test mac addr
:this\testMACaddr
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
            call :lib\lali %%f %%a
        ) else call :lib\lali %%e %%a
    )

    endlocal
    exit /b 0

REM Get router ip
:this\grouteIp
    if "%~1"=="" exit /b 1
    REM "
    for /f usebackq^ skip^=1^ tokens^=2^ delims^=^" %%a in (
        `wmic.exe NicConfig get DefaultIPGateway`
    ) do set %1=%%a
    exit /b 0


::: "Directory tools" "" "usage: %~n0 dir [option] [...]" "" "    --isdir,  -id  [path]       Test path is directory" "    --islink, -il  [file_path]  Test path is Symbolic Link" "    --trim,   -t   [letter:]    Trim SSD, HDD will return false" "    --isfree, -if  [dir_path]   Test directory is empty" "    --clean,  -c   [dir_path]   Delete empty directory"
:::: "invalid option" "Not directory" "target not found" "target not a directory"
:lib\dir
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\dir\%*
    goto :eof

:this\dir\--isdir
:this\dir\-id
    setlocal
    set _attribute=%~a1-
    REM quick return
    set _code=10
    if %_attribute:~0,1%==d set _code=0
    endlocal & exit /b %_code%

:this\dir\--islink
:this\dir\-il
    for /f "usebackq delims=" %%a in (
        `2^>nul dir /al /b "%~dp1"`
    ) do if "%%a"=="%~n1" exit /b 0
    REM quick return
    exit /b 10

:this\dir\--trim
:this\dir\-t
    if /f "%~1" neq "%~d1" exit /b 10
    if not exist "%~1" exit /b 10
    for /f "usebackq" %%a in (
        `defrag.exe %~d1 /l 2^>&1`
    ) do for %%b in (
        %%~a
    ) do if /i "%%b"=="(0x8900002A)" exit /b 0
    exit /b 10

:this\dir\--isfree
:this\dir\-if
    call :this\dir\--isdir %1 || exit /b 2
    for /f usebackq"" %%a in (
        `dir /a /b "%~1"`
    ) do exit /b 10
    exit /b 0

:this\dir\--clean
:this\dir\-c
    if not exist "%~1" exit /b 3
    call :this\dir\--isdir %1 || exit /b 4
    if exist %windir%\system32\sort.exe (
        call :dir\rdEmptyDirWithSort %1
    ) else call :dir\rdEmptyDir %1
    goto :eof

REM for :this\dir\--clean
:dir\rdEmptyDir
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

REM for :this\dir\--clean
:dir\rdEmptyDirWithSort
    if "%~1"=="" exit /b 2
    for /f "usebackq delims=" %%a in (
        `dir /ad /b /s %1 ^| sort.exe /r`
    ) do 2>nul rmdir "%%~a"
    exit /b 0


::: "Operating system ge[t] / se[t] / [t]ool" "" "usage: %~n0 ost [option] [...]" "" "    --vergeq,  -vg [version]                  Test current version is greater than the given value" "    --cleanup, -c  [[path]]                   Component Cleanup" "    --version, -v  [os_path] [[var_name]]     Get OS version" "    --bit,     -b  [os_path] [[var_name]]     Get OS bit" "    --install-lang,   -il  [os_path] [[var_name]]    Get OS install language" "    --current-lang,   -cl  [var_name] [[os_path]]    Get OS current language," "                                                     if not set path, will get online info" "    --feature-info,   -fi                            Get Feature list" "    --feature-enable, -fe  [name ...]                Enable Feature" "    --set-power,      -sp                            Set power config as server type"
:::: "invalid option" "Parameter is empty or Not a float" "not a directory" "Not OS path or Low OS version" "parameter is empty" "System version is too old" "not operating system directory" "not support"
:lib\ost
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\ost\%*
    goto :eof

:this\ost\-vg
:this\ost\--vergeq
    if "%~x1"=="" exit /b 2
    setlocal
    call :ost\this_version_x_10 _this_ver
    for /f "usebackq tokens=1,2 delims=." %%a in (
        '%~1'
    ) do set /a _ver=%_this_ver% - %%a * 10 - %%b
    endlocal & if %_ver% geq 0 exit /b 0
    exit /b 10

:ost\this_version_x_10 [variable_name]
    if "%~1"=="" exit /b 1
    for /f "usebackq delims=" %%a in (
        `ver`
    ) do for %%b in (%%a) do if "%%~xb" neq "" for /f "usebackq tokens=1,2 delims=." %%c in (
        '%%b'
    ) do set /a %~1=%%c * 10 + %%d
    exit /b 0

:this\ost\--cleanup
:this\ost\-c
    if "%~1"=="" dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase & exit /b 0
    call :this\dir\--isdir "%~1" || exit /b 3
    dism.exe /Image:%1 /Cleanup-Image /StartComponentCleanup /ResetBase
    exit /b 0

REM OS version
:this\ost\-v
:this\ost\--version
    if not exist "%~1" exit /b 3
    if "%~1"=="%~d1" (
        call :ost\version %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :ost\version "%~f1" %2
    ) else call :ost\version "%~f1\" %2
    goto :eof

:ost\version
    for /f "usebackq" %%a in (
        `2^>nul dir /ad /b %~1Windows\servicing\Version\*.*`
    ) do if "%~2"=="" (
        echo %%a& exit /b 0
    ) else set %~2=%%a& exit /b 0
    exit /b 4

:this\ost\--bit
:this\ost\-b
    if not exist "%~1" exit /b 3
    if "%~1"=="%~d1" (
        call :ost\bit %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :ost\bit "%~f1" %2
    ) else call :ost\bit "%~f1\" %2
    goto :eof

:ost\bit
    if not exist %~1Windows\servicing\Version exit /b 4
    for /d %%a in (
        %~1Windows\servicing\Version\*.*
    ) do if exist %%a\amd64_installed (
        if "%~2"=="" (
            echo amd64
        ) else set "%~2=amd64"
        exit /b 0
    ) else if exist %%a\x86_installed (
        if "%~2"=="" (
            echo x86
        ) else set "%~2=x86"
        exit /b 0
    )
    exit /b 6


REM OS language
:this\ost\--install-lang
:this\ost\-il
    if not exist "%~1" exit /b 3
    if "%~1"=="%~d1" (
        call :ost\install\lang %~1\ %2
    ) else if "%~dp1"=="%~f1" (
        call :ost\install\lang "%~f1" %2
    ) else call :ost\install\lang "%~f1\" %2
    goto :eof

:ost\install\lang
    for /d %%a in (
        %~1Windows\servicing\??-??
    ) do if "%~2"=="" (
        echo %%~na
    ) else set %~2=%%~na
    goto :eof

REM https://technet.microsoft.com/en-us/library/cc287874(v=office.12).aspx
REM https://docs.microsoft.com/en-us/previous-versions/commerce-server/ee825488(v=cs.20)
:this\ost\--current-lang
:this\ost\-cl
    setlocal
    if "%~2" neq "" (
        reg.exe load HKLM\load-point %~2\Windows\System32\config\DRIVERS || exit /b 7
        for /f "usebackq tokens=1,4 delims=x " %%a in (
            `reg.exe query HKLM\load-point\select`
        ) do if "%%b"=="Default" call :lang\current HKLM\load-point\ControlSet00%%b _lang || exit /b 8
        reg.exe unload HKLM\load-point
    ) else call :lang\current HKLM\SYSTEM\CurrentControlSet _lang || exit /b 8
    if "%~1"=="" echo.%_lang%
    endlocal & if "%~1" neq "" set %~1=%_lang%
    goto :eof

REM for :this\ost\--current-lang
:lang\current
    for /f "usebackq tokens=1,3" %%a in (
        `reg query %~1\Control\Nls\Language /v Default`
    ) do if "%%a"=="Default" for %%c in (
        af-ZA.0436 ar-AE.3801 ar-BH.3C01 ar-DZ.1401 ar-EG.0C01 ar-IQ.0801 ar-JO.2C01 ar-KW.3401 ar-LB.3001 ar-LY.1001 ar-MA.1801 ar-OM.2001 ar-QA.4001 ar-SA.0401 ar-SY.2801 ar-TN.1C01 ar-YE.2401
        be-BY.0423 bg-BG.0402
        ca-ES.0403 cs-CZ.0405 Cy-az-AZ.082C Cy-sr-SP.0C1A Cy-uz-UZ.0843
        da-DK.0406 de-AT.0C07 de-CH.0807 de-DE.0407 de-LI.1407 de-LU.1007 div-MV.0465
        el-GR.0408 en-AU.0C09 en-BZ.2809 en-CA.1009 en-CB.2409 en-GB.0809 en-IE.1809 en-JM.2009 en-NZ.1409 en-PH.3409 en-TT.2C09 en-US.0409 en-ZA.1C09 en-ZW.3009 es-AR.2C0A es-BO.400A es-CL.340A es-CO.240A
        es-CR.140A es-DO.1C0A es-EC.300A es-ES.0C0A es-GT.100A es-HN.480A es-MX.080A es-NI.4C0A es-PA.180A es-PE.280A es-PR.500A es-PY.3C0A es-SV.440A es-UY.380A es-VE.200A et-EE.0425 eu-ES.042D
        fa-IR.0429 fi-FI.040B fo-FO.0438 fr-BE.080C fr-CA.0C0C fr-CH.100C fr-FR.040C fr-LU.140C fr-MC.180C
        gl-ES.0456 gu-IN.0447
        he-IL.040D hi-IN.0439 hr-HR.041A hu-HU.040E hy-AM.042B
        id-ID.0421 is-IS.040F it-CH.0810 it-IT.0410
        ja-JP.0411
        ka-GE.0437 kk-KZ.043F kn-IN.044B kok-IN.0457 ko-KR.0412 ky-KZ.0440
        Lt-az-AZ.042C lt-LT.0427 Lt-sr-SP.081A Lt-uz-UZ.0443 lv-LV.0426
        mk-MK.042F mn-MN.0450 mr-IN.044E ms-BN.083E ms-MY.043E
        nb-NO.0414 nl-BE.0813 nl-NL.0413 nn-NO.0814
        pa-IN.0446 pl-PL.0415 pt-BR.0416 pt-PT.0816
        ro-RO.0418 ru-RU.0419
        sa-IN.044F sk-SK.041B sl-SI.0424 sq-AL.041C sv-FI.081D sv-SE.041D sw-KE.0441 syr-SY.045A
        ta-IN.0449 te-IN.044A th-TH.041E tr-TR.041F tt-RU.0444
        uk-UA.0422 ur-PK.0420
        vi-VN.042A
        zh-CHS.0004 zh-CHT.7C04 zh-CN.0804 zh-HK.0C04 zh-MO.1404 zh-SG.1004 zh-TW.0404
    ) do if /i ".%%~b"=="%%~xc" set "%~2=%%~nc"& exit /b 0
    exit /b 1

:this\ost\--feature-info
:this\ost\-fi
    for /f "usebackq tokens=1-4" %%a in (
        `dism.exe /English /Online /Get-Features`
    ) do (
        if "%%a%%b"=="FeatureName" call :%~n0\lals %%d
        if "%%a"=="State" call :%~n0\lals %%c & echo.
    )
    call :%~n0\lals 0 0
    exit /b 0

:this\ost\--feature-enable
:this\ost\-fe
    if "%~1"=="" exit /b 5
    for %%a in (
        %*
    ) do dism.exe /Online /Enable-Feature /FeatureName:%%a /NoRestart
    exit /b 0

:this\ost\--set-power
:this\ost\-sp
    call :this\ost\--vergeq 6.0 || exit /b 6

    REM powercfg
    powercfg.exe /h off

    for /f "usebackq skip=2 tokens=4" %%a in (
        `powercfg.exe /list`
    ) do for %%b in (
        ::?"while the system is powered by DC power"
        dc
        ::?"while the system is powered by AC power"
        ac
    ) do for %%c in (
        ::?"0: No action is taken when the system lid is opened."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt707941(v=vs.85).aspx"
        SUB_BUTTONS\LIDACTION\0

        ::?"3: The system shuts down when the power button is pressed."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608287(v=vs.85).aspx"
        SUB_BUTTONS\PBUTTONACTION\3

        ::?"0: No action is taken when the sleep button is pressed."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608289(v=vs.85).aspx"
        SUB_BUTTONS\SBUTTONACTION\0

        ::?"0: Never idle to sleep."
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608298(v=vs.85).aspx"
        SUB_SLEEP\STANDBYIDLE\0

        ::?"0 (Never power off the display.)"
        ::?"https://msdn.microsoft.com/en-us/library/windows/hardware/mt608277(v=vs.85).aspx"
        SUB_VIDEO\VIDEOIDLE\0

    ) do for /f "usebackq tokens=1-3 delims=\" %%d in (
        '%%c'
    ) do powercfg.exe /set%%bvalueindex %%a %%d %%e %%f
    exit /b 0

REM TODO
REM https://technet.microsoft.com/en-us/security/cc184924.aspx
:this\ost\--current-hotfix
:this\ost\-ch
    setlocal enabledelayedexpansion
    set _ost_uuid=8e16a4c7-dd28-4368-a83a-282c82fc212a

    call :ost\hot\setup %_ost_uuid%

    REM http://go.microsoft.com/fwlink/?LinkId=76054
    call :this\str\--now _odt_now

    if exist %temp%\%_ost_uuid%\wsusscn2.cab (
        for %%a in (
            %temp%\%_ost_uuid%\wsusscn2.cab
        ) do set _file_time=%%~ta
        set _file_time=!_file_time:/=!
        set _file_time=!_file_time::=!
        set _file_time=!_file_time: =!

        set /a _file_time=!_odt_now:~0,8! - !_file_time:~0,8!

        if !_file_time! gtr 7 erase %temp%\%_ost_uuid%\wsusscn2.cab
    )

    if not exist %temp%\%_ost_uuid%\wsusscn2.cab call :lib\download http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab %temp%\%_ost_uuid%\wsusscn2.cab || exit /b 2

    REM create results
    2>nul >"%temp%\results_%_odt_now%.xml" mbsacli.exe /xmlout /catalog "%temp%\%_ost_uuid%\wsusscn2.cab" /unicode /nvc

    2>nul erase "%temp%\%_ost_uuid%\wsusscn2.cab.dat"

    set _chot_kb=
    set _op=
    set _chot=chot.xml
    call :ost\this_version_x_10 _hot_ver
    if %_hot_ver%==51 (
        set _op=xp
        set _chot_kb=936929
    ) else if %_hot_ver%==52 (
        set _op=server2003
        set _chot_kb=914961
        if %processor_architecture:~-2%==64 set _op=server2003.windowsxp
    ) else if %_hot_ver%==60 (
        set _chot_kb=936330
    ) else if %_hot_ver%==61 (
        set _chot_kb=976932
    ) else set _chot=

    >%temp%\%_ost_uuid%\chot.xsl call :this\txt\--subtxt "%~f0" chot.xml 3000

    REM split xml -> log
    call :lib\vbs doxsl "%temp%\results_%_odt_now%.xml" %temp%\%_ost_uuid%\chot.xsl %temp%\hotlist_%_odt_now%.log || exit /b 1

    REM install lang
    set _lang=
    if %_hot_ver% lss 60 for /f "usebackq skip=1 tokens=1" %%a in (
        `wmic.exe os get OSLanguage`
    ) do for %%b in (
        cht.1028
        enu.1033
        jpn.1041
        kor.1042
        chs.2052
    ) do if ".%%a"=="%%~xb" set _lang=%%~nb

    REM support exfat
    if defined _lang for %%a in (
        A/6/E/A6EFFC03-F035-4604-9FB0-3B8169ED6BB6/WindowsXP-KB955704-x86-ENU
        E/8/A/E8AE6D10-0187-4B9C-AC00-AAB60A404E12/WindowsXP-KB955704-x86-CHS
        B/4/5/B4510A9E-00C5-4D99-8133-9B3172143B8C/WindowsXP-KB955704-x86-CHT
        F/4/2/F420EB1B-9C04-4B40-9424-5C4593628479/WindowsXP-KB955704-x86-JPN
        A/E/0/AE04BF31-41C3-4B70-847F-1ACF21E75898/WindowsXP-KB955704-x86-KOR
        3/5/1/3512CC64-57BD-4C97-AC83-6D5C6B2B0524/WindowsServer2003-KB955704-x86-ENU
        3/9/1/3917805C-FF96-4D6B-9F49-D4943B0A6AE5/WindowsServer2003-KB955704-x86-CHS
        3/8/3/38331E36-D3CD-4E14-A7F7-C746F6285975/WindowsServer2003-KB955704-x86-CHT
        9/C/D/9CD14BBA-B7EA-4EE0-9600-B1D136B1FC77/WindowsServer2003-KB955704-x86-JPN
        3/8/6/38697B60-193D-495C-882F-794AB8D86019/WindowsServer2003-KB955704-x86-KOR
        C/0/5/C0526146-E09A-41F7-B417-73BA1E561E40/WindowsServer2003.WindowsXP-KB955704-x64-ENU
        A/9/3/A9376498-CC5C-4566-8540-8B718025940C/WindowsServer2003.WindowsXP-KB955704-x64-CHS
        0/C/4/0C47C96D-F0D6-4142-B720-723D76B3E5B3/WindowsServer2003.WindowsXP-KB955704-x64-CHT
        7/B/C/7BC77A57-9310-41E4-9974-E75C8CC6E0C3/WindowsServer2003.WindowsXP-KB955704-x64-JPN
        E/3/2/E3237925-C9FF-4901-8A46-AFFAAC3AF602/WindowsServer2003.WindowsXP-KB955704-x64-KOR
    ) do if "%%~na"=="Windows%_op%-KB955704-x%processor_architecture:~-2%-%_lang%" >>%temp%\hotlist_%_odt_now%.log echo http://download.microsoft.com/download/%%a.exe

    sort.exe /+67 %temp%\hotlist_%_odt_now%.log

    erase %temp%\hotlist_%_odt_now%.log

    endlocal
    goto :eof

REM download and set in path
:ost\hot\setup
    for %%a in (mbsacli.exe) do if "%%~$path:a" neq "" exit /b 0

    set PATH=%temp%\%~1;%PATH%
    if not exist %temp%\%~1\mbsacli.exe (
        2>nul mkdir %temp%\%~1
        REM call :lib\download http://download.microsoft.com/download/A/1/0/A1052D8B-DA8D-431B-8831-4E95C00D63ED/MBSASetup-x%processor_architecture:~-2%-EN.msi %temp%\%~1\MBSASetup.msi || exit /b 1
        call :lib\download http://download.microsoft.com/download/8/E/1/8E16A4C7-DD28-4368-A83A-282C82FC212A/MBSASetup-x%processor_architecture:~-2%-EN.msi %temp%\%~1\MBSASetup.msi || exit /b 1
        pushd %cd%
            cd /d %temp%\%~1
            call :this\un\.msi %temp%\%~1\MBSASetup.msi
        popd
        REM mbsacli.exe wusscan.dll
        move /y "%temp%\%~1\MBSASetup\ProgramF\Microsoft Baseline Security Analyzer 2\??s?c??.???" %temp%\%~1
        rmdir /s /q %temp%\%~1\MBSASetup
    )

    exit /b 0

::: "Letter info" "" "usage: %~n0 letter [option] [...]" "" "    --free,   -u [[var_name]]           Get Unused Device Id" "    --change, -x [letter1:] [letter2:]  [DANGER^^^!] Change or exchange letters, need reboot system" "    --remove, -r [letter:]              [DANGER^^^!] Remove letter, need reboot system" "    --list,   -l [var_name] [[l/r/n]]   Get Device IDs" "    --tisl,   -- [var_name] [[l/r/n]]   Get Device IDs DESC" "                            no param view all" "                            l: Local Fixed Disk" "                            r: CD-ROM Disc" "                            n: Network Connection" "" "    --firstpath, -fp  [path_name] [[var_name]]" "                                        Get first path foreach Partiton" ""
:::: "invalid option" "variable name is empty" "type command not support" "The first parameter is empty" "Target path not found" "target not a letter or not support" "reg error" "letter not found"
:lib\letter
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\letter\%*
    goto :eof

:this\letter\--free
:this\letter\-u
    setlocal enabledelayedexpansion
    set _di=zyxwvutsrqponmlkjihgfedcba
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk get DeviceID`
    ) do set _di=!_di:%%a=!
    endlocal & if "%~1"=="" (
        echo.%_di:~0,1%:
    ) else set %~1=%_di:~0,1%:
    exit /b 0

:this\letter\--change
:this\letter\-x
    if "%~2"=="" exit /b 6
    if /i "%~1" neq "%~d1" exit /b 6
    if /i "%~2" neq "%~d2" exit /b 6
    if /i "%~d1"=="%SystemDrive%" exit /b 6
    if /i "%~d2"=="%SystemDrive%" exit /b 6
    setlocal enabledelayedexpansion
    set _%~d1=
    set _%~d2=
    for /f "usebackq tokens=1,3" %%a in (
        `reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*`
    ) do (
        if /i "%%~a"=="\DosDevices\%~d1" set "_%~d1=%%~b"
        if /i "%%~a"=="\DosDevices\%~d2" set "_%~d2=%%~b"
    )
    if not defined _%~d1 exit /b 6
    if defined _%~d2 (
        >&2 echo will exchange %~d1 with %~d2
        reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /t REG_BINARY /d !_%~d2! /f || exit /b 7
    ) else (
        >&2 echo will change %~d1 to %~d2
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d1" /f || exit /b 7
    )
    reg.exe add HKLM\SYSTEM\MountedDevices /v "\DosDevices\%~d2" /t REG_BINARY /d !_%~d1! /f || exit /b 7
    >&2 echo.
    >&2 echo Need reboot system.
    endlocal
    exit /b 0

:this\letter\--remove
:this\letter\-r
    if /i "%~1"=="" exit /b 6
    if /i "%~1" neq "%~d1" exit /b 6
    if /i "%~d1"=="%SystemDrive%" exit /b 6
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1,3" %%a in (
        `reg.exe query HKLM\SYSTEM\MountedDevices /v \DosDevices\*`
    ) do if /i "%%~a"=="\DosDevices\%~d1" (
        reg.exe delete HKLM\SYSTEM\MountedDevices /v "%%~a" /f || exit /b 7
        call :this\uuid _uuid
        reg.exe add HKLM\SYSTEM\MountedDevices /v #{!_uuid!} /t REG_BINARY /d %%b /f || exit /b 7
        >&2 echo.
        >&2 echo Need reboot system.
        exit /b 0
    )
    endlocal
    exit /b 8

REM mini uuid creater
:this\uuid
    if "%~1"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=
    set "_0f=0123456789abcdef"
    for /l %%a in (8,4,20) do set _%%a=1
    for /l %%a in (1,1,32) do (
        set /a _ran16=!random! %% 15
        call set "_str=!_str!%%_0f:~!_ran16!,1%%"
        if defined _%%a set "_str=!_str!-"
    )
    endlocal & set "%~1=%_str%"
    goto :eof

:this\letter\--list
:this\letter\-l
:this\letter\--tisl
:this\letter\--
    :::::::::::::::::::::::::::::::::::::::
    :: [WARNING] Not support nano server ::
    :::::::::::::::::::::::::::::::::::::::
    if "%~1"=="" exit /b 2
    set _var=
    setlocal enabledelayedexpansion
    set _desc=
    REM Test sort
    for %%a in (%0) do if "%%~na" neq "--list" if "%%~na" neq "-l" set _desc=1
    REM add where conditions
    if "%~2" neq "" (
        set _DriveType=
        if /i "%~2"=="l" set _DriveType=3
        if /i "%~2"=="r" set _DriveType=5
        if /i "%~2"=="n" set _DriveType=4
        if not defined _DriveType exit /b 3
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

:this\letter\--firstpath
:this\letter\-fp
    if "%~1"=="" exit /b 4
    for /f "usebackq skip=1 tokens=1,2" %%a in (
        `wmic.exe logicaldisk get Caption`
    ) do if "%%~aa" neq "" if exist "%%a\%~1" (
        if "%~2"=="" (
            echo %%a\%~1
        ) else set "%~2=%%a\%~1"
        exit /b 0
    )
    exit /b 5


::: "Encode password to base64 string for unattend.xml" "" "usage: %~n0 cpwd [string] [[var_name]]"
:::: "System version is too old" "Args is empty"
:lib\cpwd
    call :this\ost\--vergeq 6.1 || exit /b 1
    if "%~1"=="" exit /b 2
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"`
    ) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

::: "Uncompress package" "" "usage: %~n0 un [target_path]"
:::: "Format not supported" "Target not found" "System version is too old" "chm file not found" "not chm file" "out put file allready exist" "file format not msi" "cabarc.exe file not found"
:lib\un
    call :this\un\%~x1 %1
    goto :eof

:this\un\.cab
    mkdir ".\%~n1"
    expand.exe %1 -F:* ".\%~n1"
    REM for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 8
    REM pushd %cd%
    REM mkdir ".\%~n1" && chdir /d ".\%~n1" && cabarc.exe x %1 *
    REM popd
    exit /b 0

:this\un\.zip
    if not exist "%~1" exit /b 2
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    call :lib\vbs unzip "%~f1" "%_output%"
    endlocal
    exit /b 0

:this\un\.exe
    if not exist "%~1" exit /b 2
    call :this\ost\--vergeq 10.0 || exit /b 3
    compact.exe /u /exe /a /i /q /s:"%~f1"
    exit /b 0

REM "Uncompress chm file"
:this\un\.chm
    if not exist "%~1" exit /b 4
    if /i "%~x1" neq ".chm" exit /b 5
    if exist ".\%~sn1" exit /b 6
    start /wait hh.exe -decompile .\%~sn1 %~s1
    exit /b 0

REM "Uncompress msi file"
:this\un\.msi
    if not exist "%~1" exit /b 2
    if /i "%~x1" neq ".msi" exit /b 7
    mkdir ".\%~n1" 2>nul || exit /b 6
    setlocal
    REM Init
    call :this\letter\--free _letter
    subst.exe %_letter% ".\%~n1"

    REM Uncompress msi file
    start /wait msiexec.exe /a %1 /qn targetdir=%_letter%
    erase "%_letter%\%~nx1"
    REM for %%a in (".\%~n1") do echo output: %%~fa

    subst.exe %_letter% /d
    endlocal
    exit /b 0


::: "Compresses the specified files." "" "usage: %~n0 pkg [option]" "" "    --zip, -z  [source_path] [[target_path]]  make zip" "    --cab, -c  [targe_path]                   make cab" "    --udf, -u  [dir_path]                     Create iso file from directory" "    --exe, -e  [source_path]                  Use compression optimized for executable files " "                                              which are read frequently and not modified."
:::: "invalid option" "target not directory" "not support driver" "need etfsboot.com or efisys.bin"
:lib\pkg
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\pkg\%*
    goto :eof

:this\pkg\--zip
:this\pkg\-z
    setlocal
    set "_output=.\%~n1"
    if "%~2" neq "" set "_output=%~2"
    if /i "%~x1" neq ".zip" call :lib\vbs zip "%~f1" "%_output%.zip"
    endlocal
    REM >.\zip.ZFSendToTarget (
    REM     echo [Shell]
    REM     echo Command=2
    REM     echo IconFile=explorer.exe,3
    REM     echo [Taskbar]
    REM     echo Command=ToggleDesktop
    REM )
    goto :eof

:this\pkg\--cab
:this\pkg\-c
    for %%a in (cabarc.exe) do if "%%~$path:a"=="" exit /b 8
    REM By directory
    if "%~2"=="" call :this\dir\--isdir %1 && cabarc.exe -m LZX:21 n ".\%~n1.tmp" "%~1\*"
    REM By file
    call :this\dir\--isdir %1 || cabarc.exe -m LZX:21 n ".\%~n1.tmp" %*
    if exist ".\%~n1.tmp" rename ".\%~n1.tmp" "%~n1.cab"
    goto :eof

:this\pkg\--udf
:this\pkg\-u
    for %%a in (oscdimg.exe) do if "%%~$path:a"=="" call :init\oscdimg >nul
    call :this\dir\--isdir %1 ||  exit /b 2
    if /i "%~d1\"=="%~1" exit /b 3

    REM empty name
    if "%~n1"=="" (
        setlocal enabledelayedexpansion
        set _args=%~1
        if "!_args:~-1!" neq "\" (
            call :this\var\--errlv 3
        ) else call %0 "!_args:~0,-1!"
        endlocal & goto :eof
    )

    if exist "%~1\sources\boot.wim" (
        REM winpe iso
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 4
        if not exist %windir%\Boot\DVD\EFI\en-US\efisys.bin exit /b 4
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
        if not exist %windir%\Boot\DVD\PCAT\etfsboot.com exit /b 4
        oscdimg.exe -b%windir%\Boot\DVD\PCAT\etfsboot.com -k -l"%~nx1" -m -n -o -w1 %1 ".\%~nx1.tmp"
    ) else (
        REM normal iso
        REM echo oscdimg udf
        oscdimg.exe -l"%~nx1" -o -u2 -udfver102 %1 ".\%~nx1.tmp"
    )
    rename "./%~nx1.tmp" "*.iso"
    exit /b 0

:this\pkg\--exe
:this\pkg\-e
    compact.exe /c /exe /a /i /q /s:"%~f1"
    goto :eof


REM from Window 10 aik, will download oscdimg.exe at script path
:init\oscdimg
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk bbf55224a0290f00676ddc410f004498 fild40c79d789d460e48dc1cbd485d6fc2e
    REM x86
    ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk 5d984200acbde182fd99cbfbe9bad133 fil720cc132fbb53f3bed2e525eb77bdbc1
    exit /b 0

REM for :init\?, printf cab | md5sum -> 16ecfd64-586e-c6c1-ab21-2762c2c38a90
:this\getCab [file_name] [uri_sub] [cab] [file]
    2>nul mkdir %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    call :lib\download http://download.microsoft.com/download/%~2/Installers/%~3.cab %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab
    expand.exe %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab -f:%~4 %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    erase %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~1.cab
    rename %temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90\%~4 %~1.exe
    for %%a in (%~1.exe) do if "%%~$path:a"=="" set PATH=%PATH%;%temp%\16ecfd64-586e-c6c1-ab21-2762c2c38a90
    exit /b 0

::: "Change file/directory owner !username!" "" "usage: %~n0 own [path]"
:::: "path not found"
:lib\own
    if not exist "%~1" exit /b 1
    call :this\dir\--isdir %1 && takeown.exe /f %1 /r /d y && icacls.exe %1 /grant:r %username%:f /t /q
    call :this\dir\--isdir %1 || takeown.exe /f %1 && icacls.exe %1 /grant:r %username%:f /q
    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download something" "" "usage: %~n0 download [url] [output]"
:::: "url is empty" "output path is empty" "powershell version is too old" "download error"
:lib\download
    if "%~2"=="" exit /b 2
    REM windows 10 1803+
    for %%a in (curl.exe) do if "%%~$path:a" neq "" curl.exe -L --retry 10 -o %2 %1 && exit /b 0
    call :this\psv
    if errorlevel 3 PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" && exit /b 0
    call :lib\vbs get %1 %2 || exit /b 4
    exit /b 0

::: "Boot tools" "" "usage: %~n0 boot [option] [args...]" "" "    --file,    -f  [letter:]     Copy Window PE boot file from CDROM" "    --legacy,  -g  [[letter:]]   Set the old boot menu style" "    --winre,   -r  [file_path]   Setting Up recovery startup mirrors" "    --winpe,   -p  [file_path]   Create WinPE boot Menu" "    --rebuild, -rb [[letter:]]   Rebuilding the System boot Menu"
:::: "invalid option" "target_letter not exist" "Window PE CDROM not found" "target not found" "not wim file" "wim file must put in some directory"
:lib\boot
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\boot\%*
    goto :eof

:this\boot\--legacy
:this\boot\-g
    if "%~1"=="" (
        bcdedit.exe /set {default} bootmenupolicy legacy
    ) else (
        if exist "%~1" (
            bcdedit.exe /store "%~f1" /set {default} bootmenupolicy legacy
        ) else exit /b 4
    )
    goto :eof

:this\boot\--file
:this\boot\-f
    if not exist "%~d1" exit /b 2
    for /l %%a in (0,1,9) do if exist \\?\CDROM%%a\boot\boot.sdi (
        REM for macOS
        >%~d1\.metadata_never_index type nul
        attrib.exe +s +h %~d1\.metadata_never_index
        for %%b in (
            \bootmgr
            \boot\bcd
            \boot\boot.sdi
            \efi\boot\bootx64.efi
            \efi\microsoft\boot\bcd
            \sources\sxs\
            ::?\sources\acpi_hal\
            ::?\sources\pci\cc_01\
            ::?\sources\pci\cc_02\
            \support\
        ) do (
            if not exist %~d1%%~pb mkdir %~d1%%~pb
            if exist \\?\CDROM%%a%%b copy /y \\?\CDROM%%a%%b %~d1%%b
        )

        REM copy /y \\?\CDROM%%a\sources\sxs\* %~d1\sources\sxs
        exit /b 0
    )
    exit /b 3

REM error
:this\boot\--winre
:this\boot\-r
    if not exist "%~1" exit /b 4
    if /i "%~x1" neq ".wim" exit /b 5
    if "%~p1"=="\" exit /b 6
    reagentc.exe /disable
    reagentc.exe /setreimage /path "%~1"
    reagentc.exe /enable
    reagentc.exe /info
    REM attrib.exe +s +h +r "%~dp1" /d /s
    bcdedit.exe /set {default} bootmenupolicy legacy
    goto :eof

:this\boot\--winpe [wim]
:this\boot\-p
    if not exist "%~2" exit /b 4
    copy /y %windir%\Boot\DVD\PCAT\boot.sdi "%~dp1"
    2>nul mkdir %~d1\boot

    REM REM winpe boot from disk
    REM bcdedit.exe /createstore %~d1\boot\bcd
    REM bcdedit.exe /store %~d1\boot\bcd /create {bootmgr} /d "Boot Manager"
    REM bcdedit.exe /store %~d1\boot\bcd /set {bootmgr} device boot
    REM for /f "tokens=2 delims={}" %%a in (
    REM     'bcdedit.exe /store %~d1\boot\BCD /create /d "WINPE" /application osloader'
    REM ) do set GUID=%%a
    REM set GUID=%GUID:~0,-7%
    REM for %%c in (
    REM     "/set {%GUID%} osdevice boot"
    REM     "/set {%GUID%} device boot"
    REM     "/set {%GUID%} path \windows\system32\boot\winload.exe"
    REM     "/set {%GUID%} systemroot \windows"
    REM     "/set {%GUID%} winpe yes"
    REM     "/displayorder {%GUID%} /addlast"
    REM ) do bcdedit.exe /store %~d1\boot\bcd %%~c

    for /f "tokens=2 delims={}" %%a in (
        `bcdedit.exe /store "%~d1\boot\bcd" /create /d "winpe" /device`
    ) do for /f "tokens=2 delims={}" %%b in (
        `bcdedit.exe /store "%~d1\boot\bcd" /create /d "Windows Preinstallation or Recovery Environment" /application osloader`
    ) do for %%c in (
        "{%%a} ramdisksdidevice partition=%~d1"
        "{%%a} ramdisksdipath %~d1\boot\boot.sdi"
        "{%%b} device ramdisk=[%~d1]%~pnx1,{%%a}"
        ::?"{%%b} path \Windows\system32\winload.efi"
        "{%%b} path \Windows\system32\winload.exe"
        "{%%b} osdevice ramdisk=[%~d1]%~pnx1,{%%a}"
        "{%%b} systemroot \Windows"
        "{%%b} nx OptIn"
        "{%%b} winpe Yes"
    ) do bcdedit.exe /store "%~f1" /set %%~c

    goto :eof

REM new boot


:this\boot\--is-vhd-os
    >nul chcp 437
    for /f "usebackq tokens=1*" %%a in (
        `bcdedit.exe /v /enum {current}`
    ) do if .%%a==.osdevice for /f "tokens=2,3 delims=[,=]" %%c in (
        "%%b"
    ) do if %%d. neq . if exist "%%c%%d" (
        if /i .%%~xd neq ..vhd exit /b 0
        if /i .%%~xd neq ..vhdx exit /b 0
    )
    exit /b 10

:this\boot\--rebuild
:this\boot\-rb
    goto :eof

::: "Add or Remove Web Credential" "" "usage: %~n0 crede [option] [args...]" "" "    --add,    -a [user]@[ip or host] [[password]]" "    --remove, -r [ip or host]"
:::: "invalid option" "parameter not enough" "Command error" "ho ip or host"
:lib\crede
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\crede\%*
    goto :eof

:this\crede\--add
:this\crede\-a
    if "%~1"=="" exit /b 2
    setlocal
    set _prefix=
    set _suffix=
    for /f "usebackq tokens=1* delims=@" %%a in (
        '%~1'
    ) do set _prefix=%%a& set _suffix=%%b

    if not defined _suffix exit /b 4

    REM Clear Credential
    call :this\crede\-r %_suffix% >nul

    set _arg=
    if "%~2" neq "" set _arg=/pass:%~2
    REM Add credential
    echo cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg%
    >nul cmdkey.exe /add:%_suffix% /user:%_prefix% %_arg% || exit /b 3
    endlocal
    exit /b 0

:this\crede\--remove
:this\crede\-r
    if "%~1"=="" exit /b 2
    cmdkey.exe /delete:%~1
    exit /b 0


::: "Mount / Umount samba" "" "usage: %~n0 smb [option] [args...]" "" "    --mount,     -m  [ip or hosts] [path...]   Mount samba" "    --umount,    -u  [ip or --all]             Umount samba" "    --umountall, -ua                           Umount all samba"
:::: "invalid option" "parameter not enough" "Command error"
:lib\smb
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\smb\%*
    goto :eof

:this\smb\--mount
:this\smb\-m
    if "%~2"=="" exit /b 2
    for %%a in (%2 %3 %4 %5 %6 %7 %8 %9) do net.exe use * "\\%~1\%%~a" /savecred /persistent:yes || exit /b 3
    exit /b 0

:this\smb\--umount
:this\smb\-u
    if "%~1"=="" exit /b 2
    for /f "usebackq tokens=2,3" %%a in (`net.exe use`) do if "%%~pb"=="%~1\" net.exe use %%a /delete
    exit /b 0

:this\smb\--umountall
:this\smb\-ua
    net.exe use * /delete /y
    exit /b 0

::: "Mount / Umount NFS" "" "usage: %~n0 nfs [option] [args...]" "    --mount,  -m [ip]    Mount NFS" "    --umount, -u         Umount all NFS"
:::: "invalid option" "parameter is empty" "{UNUSE}" "parameter not a ip" "can not connect remote host"
:lib\nfs
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\nfs\%*
    exit /b 0

:this\nfs\--mount
:this\nfs\-m
    if "%~1"=="" exit /b 2
    call :this\ip\--test %~1 || exit /b 4
    >nul 2>nul ping.exe -n 1 -l 16 -w 100 %~1 || exit /b 5
    if not exist %windir%\system32\mount.exe call :nfs\initNfs
    for /f "usebackq skip=1" %%a in (
        `showmount.exe -e %~1`
    ) do mount.exe -o mtype=soft lang=ansi nolock \\%~1%%a *
    exit /b 0

:this\nfs\--umount
:this\nfs\-u
    if not exist %windir%\system32\umount.exe call :nfs\initNfs
    for /f "usebackq tokens=1,3 delims=:\" %%a in (
        `mount.exe`
    ) do umount.exe -f %%a:
    exit /b 0

REM Enable ServicesForNFS
:nfs\initNfs
    for %%a in (
        AnonymousUid AnonymousGid
    ) do reg.exe add HKLM\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default /v %%a /t REG_DWORD /d 0 /f
    call :lib\ocsetup ServicesForNFS-ClientOnly; ClientForNFS-Infrastructure; NFS-Administration
    REM start /w Ocsetup.exe ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure;NFS-Administration /norestart
    exit /b 0

::: "Lock / Unlock partition with BitLocker" "" "usage: %~n0 block [option] [args...]" "" "    --lock,   -l   [[passwd]]" "    --unlock, -u   [[passwd]]" "    --all,    -a   lock all partition, need usb drive"
:::: "invalid option" "Partition not found" "not support winpe" "USB drive not found"
:lib\block
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\bit\%*
    goto :eof

:this\bit\--all
:this\bit\-a
    if /i "%username%"=="System" exit /b 3
    setlocal
    for /f "usebackq tokens=1,2" %%a in (
        `wmic.exe logicaldisk get DeviceID^,DriveType`
    ) do if "%%b"=="2" if exist %%a\ set _ud=%%a

    if net defined _ud exit /b 4

    >>%_ud%\key.log (
        echo.
        echo ::::::::::::::::::::::::::::::::::::::::::::::::::
        echo %date% %time%
        wmic.exe baseboard get Manufacturer,Product,Version
        wmic.exe cpu get Name,NumberOfCores
        wmic.exe diskdrive get Index,InterfaceType,Model,SCSIPort,SerialNumber,Size
    )

    for /f "usebackq tokens=1,2" %%a in (
        `wmic.exe logicaldisk get DeviceID^,DriveType`
    ) do if "%%b"=="3" if /i "%homedrive%"=="%%a" >>%_ud%\key.log (

        REM Startup BitLocker
        REM gpedit.msc: Local Computer Policy - Computer Configuration - Administrative Templates - Windows Components - BitLocker Drive Encryption - Operating System Drives
        for %%c in (
            "UseAdvancedStartup /t REG_DWORD /d 1"
            "EnableBDEWithNoTPM /t REG_DWORD /d 1"
            "UseTPM /t REG_DWORD /d 2"
            "UseTPMPIN /t REG_DWORD /d 0"
            "UseTPMKey /t REG_DWORD /d 2"
            "UseTPMKeyPIN /t REG_DWORD /d 0"
        ) do >nul reg.exe add HKLM\Software\Policies\Microsoft\FVE /v %%~c /f

        REM remove right-mouse menu
        for %%c in (
            resume-bde resume-bde-elev
            unlock-bde
            manage-bde
            encrypt-bde encrypt-bde-elev
        ) do >nul reg.exe delete HKCR\Drive\shell\%%c /f

        manage-bde.exe -on %%a -Synchronous -UsedSpaceOnly -EncryptionMethod xts_aes128 -StartupKey %_ud%\ -SkipHardwareTest
        REM change drive ico
        >nul reg.exe add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\C\DefaultIcon /ve /t REG_SZ /d "%SystemRoot%\System32\imageres.dll,31" /f

    ) else if exist %%a >>%_ud%\key.log (
        manage-bde.exe -on %%a -Synchronous -UsedSpaceOnly -EncryptionMethod xts_aes128 -RecoveryKey %_ud%\ -SkipHardwareTest
        manage-bde.exe -autounlock -enable %%a

        REM change drive ico
        for /f "delims=:" %%c in (
            "%%a"
        ) do >nul reg.exe add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\DriveIcons\%%c\DefaultIcon /ve /t REG_SZ /d "%SystemRoot%\System32\imageres.dll,27" /f
    )

    endlocal

    attrib.exe -s -h -r %_ud%\*.bek
    exit /b 0

:this\bit\--lock
:this\bit\-l
    if not exist "%~1" exit /b 2
    manage-bde.exe -on %~d1 -UsedSpaceOnly -Synchronous -Password %~2
    exit /b 0

:this\bit\--unlock
:this\bit\--u
    if not exist "%~1" exit /b 2
    manage-bde.exe -on %~d1 -UsedSpaceOnly -RecoveryPassword %~2
    exit /b 0

:::::::::
:: vhd ::
:::::::::

::: "Virtual Hard Disk manager" "" "usage: %~n0 vhd [option] [args...]" "" "    --new,    -n  [new_vhd_path] [size[GB]] [[mount letter or path]]" "                                                       Creates a virtual disk file." "" "    --mount,  -m  [vhd_path] [[letter]]                Mount vhd file" "    --umount, -u  [vhd_path]                           Unmount vhd file" "    --expand, -e  [vhd_path] [GB_size]                 Expands the maximum size available on a virtual disk." "    --differ, -d  [new_vhd_path] [source_vhd_path]     Create differencing vhd file by an existing virtual disk file" "    --merge,  -me [chile_vhd_path] [[merge_depth]]     Merges a child disk with its parents"
REM  "    --rec,    -r                                       Recovery child vhd if have parent" "" "e.g." "    %~n0 vhd -n E:\nano.vhdx 30 V:"
:::: "invalid option" "file suffix not vhd/vhdx" "file not found" "no volume find" "vhd size is empty" "letter already use" "diskpart error:" "not a letter or path" "{UNUSE}" "size not num" "parent vhd not found" "new file allready exist"
:lib\vhd
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\vhd\%*
    goto :eof

:this\vhd\--new
:this\vhd\-n
    if "%~1"=="" exit /b 3
    if not exist "%~dp1" exit /b 4
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2"=="" exit /b 5
    if "%~3" neq "" (
        if /i "%~d3"=="%~3" if exist "%~d3" exit /b 6
        if /i "%~d3" neq "%~3" if not exist "%~3" exit /b 8
    )
    REM make vhd
    call set /a _size=%2 * 1024 + 8
    (
        echo create vdisk file="%~f1" maximum=%_size% type=expandable
        echo attach vdisk
        echo create partition primary
        echo format fs=ntfs quick
        if "%~3"=="" (
            echo assign
        ) else (
            if /i "%~d3"=="%~3" (
                echo assign letter=%~d3
            ) else echo assign mount="%~f3"
        )
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    echo complete.
    exit /b 0

:this\vhd\--mount
:this\vhd\-m
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2" neq "" (
        if /i "%~d2"=="%~2" if exist "%~2" exit /b 6
        if /i "%~d2" neq "%~2" if not exist "%~2" exit /b 8
    )
    (
        echo select vdisk file="%~f1"
        echo attach vdisk
        if "%~2" neq "" (
            echo select partition 1
            REM skip error
            echo remove all noerr
            if /i "%~d2"=="%~2" (
                echo assign letter=%~2
            ) else echo assign mount="%~f2"
        )
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    echo complete.
    exit /b 0

:this\vhd\--umount
:this\vhd\-u
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    REM unmount vhd
    (
        echo select vdisk file="%~f1"
        echo detach vdisk
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    echo complete.
    exit /b 0

:this\vhd\--expand
:this\vhd\-e
    if not exist "%~1" exit /b 3
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    call :lib\inum %~2 || exit /b 10
    REM unmount vhd
    call :lib\vumount %1 > nul
    setlocal
    set /a _size=%~2 * 1024 + 8
    (
        echo select vdisk file="%~f1"
        echo expand vdisk maximum=%_size%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    endlocal
    exit /b 0

:this\vhd\--differ
:this\vhd\-d
    if not exist "%~2" exit /b 11
    if exist "%~1" exit /b 12
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    echo create vdisk file="%~f1" parent="%~f2" | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    echo complete.
    exit /b 0

:this\vhd\--merge
:this\vhd\-me
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    setlocal
    call set _depth=1
    if "%~2" neq "" set _depth=%~2
    (
        echo select vdisk file="%~f1"
        echo merge vdisk depth=%_depth%
    ) | diskpart.exe | find.exe /i /v "DISKPART" || exit /b 7
    echo complete.
    endlocal
    exit /b 0

::::::::::
:: dism ::
::::::::::

::: "Wim manager" "" "usage: %~n0 wim [option] [args ...]" "" "    --info,   -i [image_path]                                Displays information about images in a WIM file." "    --new,    -n [[compress level]] [target_dir_path] [[image_name]]" "                                                             Capture file/directory to wim" "                                                      [WARN] if target path tail without '\', root path is parent directory" "" "    --apply,  -a [wim_path] [[output_path] [image_index]]    Apply WIM file" "    --mount,  -m [wim_path] [mount_path] [[image_index]]     Mount wim" "    --umount, -u [mount_path]                                Unmount wim" "    --commit, -c [mount_path]                                Unmount wim with commit" "    --export, -e [source_wim_path] [target_wim_path] [image_index] [[compress_level]]    Export wim image" "                                   compress level: 0:none, 1:WIMBoot, 2:fast, 3:max, 4:recovery(esd)" "" "    --umountall, -ua                                         Unmount all wim" "    --rmountall, -ra                                         Recovers mount all orphaned wim"
:::: "invalid option" "SCRATCH_DIR variable not set" "dism version is too old" "target not found" "need input image name" "dism error" "wim file not found" "not wim file" "output path allready use" "output path not found" "Not a path" "Target wim index not select" "compress level error"
:lib\wim
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 2
    2>nul mkdir %temp% %tmp%
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :this\wim\%*
    endlocal
    goto :eof

:this\wim\--new
:this\wim\-n
    call :this\ost\--vergeq 6.3 || exit /b 3

    setlocal enabledelayedexpansion
    call :lib\inum %~1 && call :wim\setCompress %~1 && shift

    if not exist "%~1" exit /b 4
    if "%~d1\"=="%~f1" if "%~2"=="" exit /b 5

    set _export=
    if /i "%_compress%"=="/Compress:recovery" (
        set _compress=/Compress:fast
        set _export=ture
    )

    set _iroot=
    set "_input=%~f1"
    REM trim path
    if "%_input:~-1%"=="\" set _iroot=true& set "_input=%_input:~0,-1%"

    REM wim name
    if "%~2" neq "" (
        set _name=%~2
    ) else for %%a in ("%_input%") do set "_name=%%~nxa"

    REM New or Append
    if exist ".\%_name%.wim" (set _create=Append) else set _create=Capture

    call :this\str\--now _conf "%tmp%\" .ini
    set _args=
    set _description=
    set _load_point=HKLM\load-point%random%
    REM Create exclusion list

    if exist "%_input%\Windows\System32\config\SYSTEM" (
        >%_conf% call :this\txt\--subtxt "%~f0" wim.ini 3000
        set _args=/ConfigFile:"%_conf%"
        REM /Description:Description

        REM [WARN] Windows 10 have ReleaseId
        >nul reg.exe load %_load_point% "%_input%\Windows\System32\config\SOFTWARE" || exit /b 6
        for /f "usebackq skip=1 tokens=2*" %%a in (
            `reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ProductName`
        ) do if "%%a"=="REG_SZ" for /f "usebackq skip=1 tokens=2*" %%c in (
            `reg.exe query "%_load_point%\Microsoft\Windows NT\CurrentVersion" /v ReleaseId`
        ) do if "%%c"=="REG_SZ" set _description=/Description:"%%b %%d"
        >nul reg.exe unload %_load_point%

    ) else if defined _iroot (
        echo.
        echo root path: '%_input%'
    ) else (
        >%_conf% call :wim\ConfigFile "%_input%" && set _args=/ConfigFile:"%_conf%"
        REM input args
        for %%a in ("%_input%") do set "_input=%%~dpa"
        set "_input=!_input:~0,-1!"
        echo.
        echo root path: '!_input!'
    )

    REM Do capture
    dism.exe /%_create%-Image /ImageFile:".\%_name%.wim" /CaptureDir:"%_input%" /Name:"%_name%" %_description% %_compress% /Verify %_args% %scratch_dir% || exit /b 6
    if exist "%_conf%" erase "%_conf%"

    call :getWimLastIndex ".\%_name%.wim" _index

    echo new index is: %_index%

    if defined _export dism.exe /Export-Image /SourceImageFile:".\%_name%.wim" /SourceIndex:%_index% /DestinationImageFile:".\%_name%.esd" /Compress:recovery /CheckIntegrity %scratch_dir% || exit /b 6

    endlocal
    exit /b 0

REM create exclusion list
:wim\ConfigFile
    if not exist "%~1" exit /b 1
    if "%~pnx1"=="\" exit /b 2
    echo [ExclusionList]
    REM parent directory
    for /f "usebackq delims=" %%a in (
        `dir /a /b "%~dp1"`
    ) do if "%%a" neq "%~nx1" echo \%%a
    echo.
    exit /b 0

:this\wim\--apply
:this\wim\-a
    call :this\ost\--vergeq 6.3 || exit /b 3
    if not exist "%~1" exit /b 7
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 8
    REM if "%~2"=="" mkdir ".\%~n1" 2>nul || exit /b 9
    setlocal
    set _out=.
    if "%~2" neq "" (
        call :this\dir\--isdir "%~2" || exit /b 10
        set _out=%~f2
    )
    REM Must trim path
    if "%_out:~-1%"=="\" set _out=%_out:~0,-1%
    if "%~3"=="" (
        call :getWimLastIndex %1 _index
    ) else set _index=%~3
    dism.exe /Apply-Image /ImageFile:"%~f1" /Index:%_index% /ApplyDir:"%_out%" /Verify || exit /b 6
    endlocal
    exit /b 0

REM for wim
:getWimLastIndex
    if "%~2"=="" exit /b 1
    for /f "usebackq tokens=1,3" %%a in (
         `dism.exe /English /Get-WimInfo /WimFile:"%~f1"`
     ) do if "%%a"=="Index" set /a %~2=%%b
    exit /b 0

:this\wim\--mount
:this\wim\-m
    if not exist "%~1" exit /b 7
    if /i "%~x1" neq ".wim" exit /b 8
    call :this\dir\--isdir %2 || exit /b 4
    setlocal
    if "%~3"=="" (
        call :getWimLastIndex %1 _index
    ) else set _index=%3
    dism.exe /Mount-Wim /WimFile:"%~f1" /index:%_index% /MountDir:"%~f2" %scratch_dir% || exit /b 6
    endlocal
    exit /b 0

:this\wim\--umount
:this\wim\-u
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /discard %scratch_dir% || exit /b 6
    exit /b 0

:this\wim\--commit
:this\wim\-c
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /commit %scratch_dir% || exit /b 6
    exit /b 0

:: 0->4 none|WIMBoot|fast|max|recovery(esd),
:: recovery only support '/Export-Image' option
:wim\setCompress
    set _compress=
    if "%~1"=="0" set _compress=/Compress:none
    if "%~1"=="1" set _compress=/WIMBoot
    if "%~1"=="2" set _compress=/Compress:fast
    if "%~1"=="3" set _compress=/Compress:max
    if "%~1"=="4" set _compress=/Compress:recovery
    if defined _compress exit /b 0
    exit /b 1

:this\wim\--export
:this\wim\-e
    if not exist %1 exit /b 7
    if /i "%~x1" neq ".wim" if /i "%~x1" neq ".esd" exit /b 8
    if "%~f2" neq "%~2" exit /b 11
    if /i "%~x2" neq ".wim" if /i "%~x2" neq ".esd" exit /b 8
    if "%~3"=="" exit /b 12
    setlocal

    call :wim\setCompress %~4

    REM test suffix
    if /i "%~x2"==".esd" if defined _compress if "%_compress:~-8%" neq "recovery" exit /b 13

    REM auto esd
    if /i "%~x2"==".esd" if not defined _compress set _compress=/Compress:recovery

    REM test size, TODO get image size by index
    set "_size=%~z1" 2>nul || exit /b 7
    REM 0x1fffffff = 536870911
    if "%_size:~9,1%"=="" if %_size% lss 536870911 if "%_compress%" neq "/WIMBoot" set "_compress=%_compress% /Bootable"

    dism.exe /Export-Image /SourceImageFile:"%~f1" /SourceIndex:%3 /DestinationImageFile:"%~f2" %_compress% /CheckIntegrity %scratch_dir% || exit /b 6
    endlocal
    exit /b 0

::: "Unmount all wim"
:this\wim\--umountall
:this\wim\-ua
    for /f "usebackq tokens=1-3*" %%a in (
        `dism.exe /English /Get-MountedWimInfo`
    ) do if "%%~a%%~b"=="MountDir" if exist "%%~d" call :this\wim\--umount "%%~d"
    dism.exe /Cleanup-Wim
    exit /b 0

::: "Recovers mount all orphaned wim"
:this\wim\--rmountall
:this\wim\-ra
    setlocal enabledelayedexpansion
    for /f "usebackq tokens=1-3*" %%a in (
        `dism.exe /English /Get-MountedWimInfo`
    ) do (
        if "%%~a"=="Mount" set _m=
        if "%%~a%%~b"=="MountDir" if exist "%%~d" set "_m=%%~d"
        if "%%~a%%~d"=="StatusRemount" if defined _m dism.exe /Remount-Wim /MountDir:"!_m!" %scratch_dir% || exit /b 6
    )
    endlocal
    echo.complete.
    exit /b 0

::: ""
:this\wim\-i
:this\wim\--info
    if not exist "%~1" exit /b 4
    for /f "usebackq tokens=1,2*" %%b in (
        `dism.exe /English /Get-WimInfo /WimFile:%1`
    ) do if "%%b"=="Index" (
        for /f "usebackq tokens=1,2*" %%f in (
            `dism.exe /English /Get-WimInfo /WimFile:%1 /Index:%%d`
        ) do if "%%h" neq "<undefined>" (
            if "%%f"=="Name" set /p=%%d. "%%h"<nul
            if "%%f"=="Size" call :this\wim\num %%h
            if "%%f%%g%%h"=="WIMBootable: Yes" set /p=, wimboot<nul
            if "%%f"=="Architecture" set /p=, %%h<nul
            if "%%f"=="Version" set /p=, %%h<nul
            if "%%f"=="Edition" set /p=, %%h<nul
            if "%%g"=="(Default)" set /p=, %%f <nul
        )
        echo.
    )
    exit /b 0

:this\wim\num
    setlocal
    set _num=%*
    set /p=, %_num:,=_%<nul
    endlocal
    goto :eof

::: "Drivers manager" "" "usage: %~n0 drv [option] [args...]" "" "    --add,    -a  [os_path] [drv_path ...]     Add drivers offline" "    --list,   -l  [[os_path]]                  Show OS drivers list" "    --remove, -r  [os_path] [[name].inf]       remove drivers, 3rd party drivers like oem1.inf" "    --get,    -g                               display hardware ids" "    --filter, -f [devinf_path] [drivers_path]  search device inf" "                                           e.g." "                                               %~n0 drv --get" "                                               %~n0 drv --filter D:\d.log D:\drv"
:::: "invalid option" "OS path not found" "Not drivers name" "dism error" "drivers info file not found" "drivers path error" "SCRATCH_DIR variable not set"
:lib\drv
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if /i "%username%"=="System" if not defined SCRATCH_DIR exit /b 7
    setlocal
    if /i "%username%" neq "System" set scratch_dir=
    if defined scratch_dir set "scratch_dir=/ScratchDir:%scratch_dir:/ScratchDir:=%"
    call :this\drv\%*
    endlocal
    goto :eof

REM Will install at \Windows\System32\DriverStore\FileRepository
:this\drv\-a
:this\drv\--add
    for %%a in (%*) do call :this\dir\--isdir %1 && (
        dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a /Recurse %scratch_dir% || REM
    ) || if /i "%%~xa"==".inf" dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a %scratch_dir% || exit /b 4
    exit /b 0

:this\drv\-l
:this\drv\--list
    if "%~1" neq "" call :this\dir\--isdir %1 || exit /b 2
    if "%~1"=="" (
        dism.exe /Online /Get-Drivers /all || exit /b 4
    ) else dism.exe /Image:"%~f1" /Get-Drivers /all || exit /b 4
    exit /b 0

:this\drv\-r
:this\drv\--remove
    call :this\dir\--isdir %1 || exit /b 2
    if /i "%~x2" neq ".inf" exit /b 3
    dism.exe /Image:"%~f1" /Remove-Driver /Driver:%~2 %scratch_dir% || exit /b 4
    exit /b 0

REM "Hardware ids manager"
:this\drv\--get
:this\drv\-g
    call :this\path\--contain devcon.exe || call :init\devcon >nul
    setlocal
    REM Trim Hardware and compatible ids
    for /f "usebackq tokens=1,2" %%a in (
        `devcon.exe hwids *`
    ) do if "%%b"=="" set "_$%%a=$"
    REM Print list
    for /f "usebackq tokens=2 delims==$" %%a in (
        `2^>nul set _$`
    ) do echo %%a
    endlocal
    exit /b 0

:this\drv\--filter
:this\drv\-f
    if not exist "%~1" exit /b 5
    call :this\dir\--isdir %2 || exit /b 6
    REM Create inf trim vbs
    setlocal enabledelayedexpansion
    call :this\str\--now _out %temp%\inf-
    mkdir %_out%
    set i=0
    for /r %2 %%a in (
        *.inf
    ) do (
        set /a i+=1
        REM Cache inf file path
        set _drv\inf\!i!=%%a
        REM trim file in a new path
        call :lib\vbs inftrim "%%~a" %_out%\!i!.tmp
        for %%b in (%_out%\!i!.tmp) do if "%%~zb"=="0" type "%%~a" > %_out%\!i!.tmp
    )
    REM Print hit file
    for /f "usebackq" %%a in (
        `findstr.exe /e /i /m /g:%1 %_out%\*.tmp`
    ) do echo !_drv\inf\%%~na!
    REM Clear temp file
    rmdir /s /q %_out%
    endlocal
    exit /b 0


:this\drv\--extract--env
:this\drv\-ee
    REM \Users\Default
    REM \Users\Default\NTUSER.DAT
    REM \Windows\servicing\Version\!_ver_drv!
    REM \Windows\servicing\Version\!_ver_drv!\amd64_installed
    REM \Windows\servicing\Version\!_ver_drv!\x86_installed
    REM \Windows\System32
    REM \Windows\System32\ntdll.dll
    REM \Windows\System32\SSShim.dll
    REM \Windows\System32\wdscore.dll
    REM \Windows\System32\config
    REM \Windows\System32\config\COMPONENTS 0kb
    REM \Windows\System32\config\DEFAULT    0kb
    REM \Windows\System32\config\DRIVERS
    REM \Windows\System32\config\SAM        0kb
    REM \Windows\System32\config\SECURITY   0kb
    REM \Windows\System32\config\SOFTWARE
    REM \Windows\System32\config\SYSTEM
    REM \Windows\System32\Dism
    REM \Windows\System32\Dism\CbsProvider.dll
    REM \Windows\System32\Dism\CompatProvider.dll
    REM \Windows\System32\Dism\DismCore.dll
    REM \Windows\System32\Dism\DismCorePS.dll
    REM \Windows\System32\Dism\DismHost.exe
    REM \Windows\System32\Dism\DismProv.dll
    REM \Windows\System32\Dism\DmiProvider.dll
    REM \Windows\System32\Dism\FolderProvider.dll
    REM \Windows\System32\Dism\GenericProvider.dll
    REM \Windows\System32\Dism\IBSProvider.dll
    REM \Windows\System32\Dism\ImagingProvider.dll
    REM \Windows\System32\Dism\IntlProvider.dll
    REM \Windows\System32\Dism\LogProvider.dll
    REM \Windows\System32\Dism\OSProvider.dll
    REM \Windows\System32\Dism\PEProvider.dll
    REM \Windows\System32\Dism\SmiProvider.dll
    REM \Windows\System32\Dism\UnattendProvider.dll
    REM \Windows\System32\Dism\VhdProvider.dll
    REM \Windows\System32\Dism\WimProvider.dll
    REM \Windows\System32\Dism\Wow64Provider.dll
    REM \Windows\System32\Dism\en-US
    REM \Windows\System32\Dism\en-US\CbsProvider.dll.mui
    REM \Windows\System32\Dism\en-US\CompatProvider.dll.mui
    REM \Windows\System32\Dism\en-US\DismCore.dll.mui
    REM \Windows\System32\Dism\en-US\DismProv.dll.mui
    REM \Windows\System32\Dism\en-US\DmiProvider.dll.mui
    REM \Windows\System32\Dism\en-US\FolderProvider.dll.mui
    REM \Windows\System32\Dism\en-US\GenericProvider.dll.mui
    REM \Windows\System32\Dism\en-US\IBSProvider.dll.mui
    REM \Windows\System32\Dism\en-US\ImagingProvider.dll.mui
    REM \Windows\System32\Dism\en-US\IntlProvider.dll.mui
    REM \Windows\System32\Dism\en-US\LogProvider.dll.mui
    REM \Windows\System32\Dism\en-US\OSProvider.dll.mui
    REM \Windows\System32\Dism\en-US\PEProvider.dll.mui
    REM \Windows\System32\Dism\en-US\SmiProvider.dll.mui
    REM \Windows\System32\Dism\en-US\UnattendProvider.dll.mui
    REM \Windows\System32\Dism\en-US\VhdProvider.dll.mui
    REM \Windows\System32\Dism\en-US\WimProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!
    REM \Windows\System32\Dism\!_lang_drv!\CbsProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\CompatProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DismCore.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DismProv.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\DmiProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\FolderProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\GenericProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\ImagingProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\IntlProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\LogProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\OSProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\PEProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\SmiProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\UnattendProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\VhdProvider.dll.mui
    REM \Windows\System32\Dism\!_lang_drv!\WimProvider.dll.mui
    REM \Windows\System32\DriverStore\FileRepository
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\CbsCore.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\DrUpdate.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\drvstore.dll
    REM \Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_!_ver_drv!_none_!_hash_drv!\wcp.dll

    goto :eof

REM from Window 10 wdk, will download devcon.exe at script path
:init\devcon
    for %%a in (_%0) do if %processor_architecture:~-2%==64 (
        REM amd64
        call :this\getCab %%~na 8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk 787bee96dbd26371076b37b13c405890 filbad6e2cce5ebc45a401e19c613d0a28f

    REM x86
    ) else call :this\getCab %%~na 8/1/6/816FE939-15C7-4185-9767-42ED05524A95/wdk 82c1721cd310c73968861674ffc209c9 fil5a9177f816435063f779ebbbd2c1a1d2
    exit /b 0


:::::::::
:: KMS ::
:::::::::

::: "KMS Client" "" "usage: %~n0 kms [option] [args...]" "" "    --os,  -s [[host[:port]]]     Active operating system" "    --odt, -o [[host[:port]]]     Active office, which install by Office Deployment Tool" "    e.g." "        %~n0 kms --os 192.168.1.1" "" "    --all, -a [[host[:port]]]     Active operating system and office"
:::: "invalid option" "ospp.vbs not found" "Need ip or host" "OS not support" "No office found" "office not support"
:lib\kms
    title kms
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    if "%~2"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~f0'
        ) do set _host=%%a
    ) else set _host=%2

    call :this\kms\%*
    endlocal
    goto :eof

:this\kms\--all
:this\kms\-a
    call :this\kms\--os %*
    call :this\kms\--odt %*
    exit /b 0

REM OS
:this\kms\--os
:this\kms\-s

    REM Get this OS version
    call :this\ost\--version %SystemDrive% _ver
    for /f "tokens=1,2 delims=." %%b in (
        "%_ver%"
    ) do set /a _ver=%%b * 10 + %%c

    REM Get this OS Edition ID
    for /f "usebackq tokens=3" %%a in (
        `reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "EditionID"`
    ) do set _eid=%%a

    REM Search kms key
    REM https://technet.microsoft.com/en-us/library/jj612867(v=ws.11).aspx
    REM https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys
    REM [EditionID]@[key] or "[[EditionID]@[key].[BuildLab_number]],[[EditionID]@[key].[BuildLab_number]], ..."
    for %%a in (
        100_ServerStandardACor@DPCNP-XQFKJ-BJF7R-FRC8D-GF6G4
        100_ServerDatacenterACor@6Y6KB-N82V8-D8CQV-23MJW-BWTG6
        100_ServerStandard@WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
        100_ServerDatacenter@CB7KF-BWN84-R7R2Y-793K2-8XDDG
        100_Education@NW6C2-QMPVW-D7KKK-3GKT6-VCFB2
        "100_EnterpriseS@WNMTR-4C88C-JK8YV-HQ7T2-76DF9.10240,DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ.14393"
        100_Enterprise@NPPR9-FWDCX-D2C8J-H872K-2YT43
        100_Professional@W269N-WFGWX-YVC9B-4J6C9-T83GX

        63_ServerStandard@D2N9P-3P6X9-2R39C-7RTCD-MDVJX
        63_ServerDatacenter@W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9
        63_Professional@GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
        63_Enterprise@MHF9N-XY6XB-WVXMC-BTDCT-MKKG7

        62_ServerStandard@XC9B7-NBPP2-83J2H-RHMBY-92BT4
        62_ServerDatacenter@48HP8-DN98B-MYWDG-T2DCC-8W83P
        62_Professional@NG4HW-VH26C-733KW-K6F98-J8CK4
        62_Enterprise@32JNW-9KQ84-P47T8-D8GGY-CWCK7

        61_ServerStandard@YC6KT-GKW9T-YTKYR-T4X34-R7VHC
        61_ServerEnterprise@489J6-VHDMP-X63PK-3K798-CPX3Y
        61_ServerDatacenter@74YFP-3QFB3-KQT8W-PMXWJ-7M648
        61_Enterprise@33PXH-7Y6KF-2VJC9-XBBR8-HVTHH
        61_Professional@FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4

        60_ServerStandard@TM24T-X9RMF-VWXK6-X8JC9-BFGM2
        60_ServerEnterprise@YQGMW-MPWTJ-34KDK-48M3W-X4Q6V
        60_ServerDatacenter@7M67G-PC374-GR742-YH8V4-TCBY3
        60_Enterprise@VKK3X-68KWM-X2YGT-QR4M6-4BWMV
        60_Business@YFKBB-PQJJV-G996G-VWGXY-2V3X8
    ) do for /f "usebackq tokens=1,2 delims=@" %%b in (
        '%%~a'
    ) do if /i "%_ver%_%_eid%"=="%%b" set _key=%%c

    REM If not find key
    if not defined _key exit /b 4

    REM Processing same EditionID by BuildLab number
    if "%_key:~30,1%" neq "" for /f "usebackq tokens=3 delims=. " %%a in (
        `reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v BuildLab`
    ) do for %%b in (
        %_key%
    ) do if ".%%a"=="%%~xb" set _key=%%~nb

    REM Not found key in same EditionID
    if "%_key:~30,1%" neq "" exit /b 4

    REM Active
    for %%a in (
        "/ipk %_key%"
        "/skms %_host%"
        ::?"active"
        /ato
        ::?"display expires time"
        /xpr
        ::?"rm key"
        /ckms
    ) do cscript.exe //nologo //e:vbscript %windir%\System32\slmgr.vbs %%~a

    exit /b 0

REM for Office Deployment Tool only
:this\kms\--odt
:this\kms\-o
    call :office\ClickToRun\InstallPath _officeInstallPath || exit /b 5

    for /r "%_officeInstallPath%" %%a in (
        ospp.vb?
    ) do set "_ospp=%%a"
    if not exist "%_ospp%" exit /b 2

    REM set kms key
    for /f "usebackq" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office`
    ) do for /f "usebackq" %%b in (
        `2^>nul reg.exe query HKLM\Software\Microsoft\Office\%%~nxa\ClickToRunStore\Applications`
    ) do if "%%~nb"=="%%~b" if /i "(Default)" neq "%%~b" 2>nul call :kms\gvlk\%%~na_%%b
    >nul set _gvlk\ || exit /b 6

    REM Active
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _gvlk\`
    ) do echo.& echo =======================================& echo.    %%bVolume& for %%c in (
        "/inpkey:%%~na"
        "/sethst:%_host%"
        /act ::?"active"
        /dstatus ::?"display expires time"
        /remhst ::?"rm key"
    ) do echo.& cscript.exe //nologo //e:vbscript "%_ospp%" %%~c

    exit /b 0

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: https://docs.microsoft.com/en-us/deployoffice/office2016/gvlks-for-office-2016 :::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM Office Professional Plus 2016
:kms\gvlk\16_Word
:kms\gvlk\16_Excel
:kms\gvlk\16_PowerPoint
:kms\gvlk\16_OneNote
:kms\gvlk\16_Outlook
:kms\gvlk\16_Access
:kms\gvlk\16_Publisher
    set _gvlk\XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99=Professional2016
    goto :eof

REM Visio Professional 2016
:kms\gvlk\16_Visio
    set _gvlk\PD3PC-RHNGV-FXJ29-8JK7D-RJRJK=VisioPro2016
    goto :eof

REM Project Professional 2016
:kms\gvlk\16_Project
    set _gvlk\YG9NW-3K39V-2T3HJ-93F3Q-G83KT=ProjectPro2016
    goto :eof

REM Skype for Business 2016
:kms\gvlk\16_Skype
    set _gvlk\869NQ-FJ69K-466HW-QYCP2-DDBV6=SkypeforBusiness2016
    goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: https://technet.microsoft.com/en-us/library/dn385360.aspx :::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM Office 2013 Professional Plus
:kms\gvlk\15_Word
:kms\gvlk\15_Excel
:kms\gvlk\15_PowerPoint
:kms\gvlk\15_OneNote
:kms\gvlk\15_Outlook
:kms\gvlk\15_Access
:kms\gvlk\15_Publisher
    set _gvlk\YC7DK-G2NP3-2QQC3-J6H88-GVGXT=Professional2013
    goto :eof

REM Visio 2013 Professional
:kms\gvlk\15_Visio
    set _gvlk\C2FG9-N6J68-H8BTJ-BW3QX-RM3B3=VisioPro2013
    goto :eof

REM Project 2013 Professional
:kms\gvlk\15_Project
    set _gvlk\FN8TT-7WMH6-2D4X9-M337T-2342K=ProjectPro2013
    goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: http://technet.microsoft.com/en-us/library/ee624355(office.14).aspx :::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM Office 2010 Professional Plus
:kms\gvlk\14_Word
:kms\gvlk\14_Excel
:kms\gvlk\14_PowerPoint
:kms\gvlk\14_OneNote
:kms\gvlk\14_Outlook
:kms\gvlk\14_Access
:kms\gvlk\14_Publisher
    set _gvlk\VYBBJ-TRJPB-QFQRF-QFT4D-H3GVB=Professional2010
    goto :eof

REM Visio 2010 Professional
:kms\gvlk\14_Visio
    set _gvlk\7MCW8-VRQVK-G677T-PDJCM-Q8TCP=VisioPro2010
    goto :eof

REM Project 2010 Professional
:kms\gvlk\14_Project
    set _gvlk\YGX6F-PGV49-PGW3J-9BTGG-VHKC6=ProjectPro2010
    goto :eof

:office\ClickToRun\InstallPath
    if "%~1"=="" exit /b 1
    REM 2^>nul reg.exe query HKLM\Software\Microsoft\Office /f InstallRoot /s | reg.exe query "%%a" /v Path`
    for /f "usebackq tokens=1,2*" %%a in (
        `2^>nul reg.exe query HKLM\Software\Microsoft\Office\ClickToRun /v InstallPath`
    ) do if /i "%%~a"=="InstallPath" if exist "%%~c" set "%~1=%%~c"&& exit /b 0
    exit /b 1

::: "Office Deployment Tool" "" "usage: %~n0 odt [option]" "    --deploy,  -d  [[path]]              Deployment Office Deployment Tool data" "    --install, -i  [[path]] [[names]]    Install office by names, will remove previous installation" "                                         default: 'base'" "" "      names:" "          base full" "          word excel powerpoint" "          access onenote outlook" "          project visio publisher" "" "      base:" "          word excel visio" "" "      full:" "          word excel powerpoint project visio"
:::: "invalid option" "target not found" "init fail" "must set office product ids" "install error" "setup error" "source not found"
:lib\odt
    title odt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    setlocal
    set "_odt_source_path=%cd%"
    if "%~d0"=="\\" set "_odt_source_path=%~dp0"
    if "%~2" neq "" if "%~n2" neq "%~2" (
        if not exist "%~2" exit /b 2
        set "_odt_source_path=%~2"
    )
    if "%_odt_source_path:~-1%"=="\" set _odt_source_path=%_odt_source_path:~0,-1%

    set _odt_update=
    call :this\ost\--current-lang _odt_lang || exit /b 2

    call :this\odt\%*
    endlocal
    goto :eof

:this\odt\--deploy
:this\odt\-d
    3>nul call :odt\pro\full
    >%temp%\odt_download.xml call :this\txt\--subtxt "%~f0" odt.xml 3000

    title Deployed to '%_odt_source_path%'
    >&3 echo Deployed to '%_odt_source_path%'
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 3
    odt.exe /download %temp%\odt_download.xml || exit /b 6
    erase %temp%\odt_download.xml
    goto :eof

:this\odt\--install
:this\odt\-i
    if not exist "%_odt_source_path%\Office\Data" exit /b 7

    REM shift can change %*
    if exist "%~1" shift /1

    if "%~1" neq "" (
        if /i "%~1"=="base" (
            shift /1
            call :odt\pro\base %1 %2 %3 %4 %5 %6 %7 %8 %9
        ) else if /i "%~1"=="full" (
            shift /1
            call :odt\pro\full %1 %2 %3 %4 %5 %6 %7 %8 %9
        ) else call :odt\install\var %*
    ) else call :odt\pro\base

    if errorlevel 4 exit /b 4

    >%temp%\odt_install.xml call :this\txt\--subtxt "%~f0" odt.xml 3000

    title Installing from %_odt_source_path%\Office
    >&3 echo Installing...
    call :odt\ext\setup 27af1be6-dd20-4cb4-b154-ebab8a7d4a7e || exit /b 3
    odt.exe /configure %temp%\odt_install.xml || exit /b 6
    erase %temp%\odt_install.xml

    call :this\ost\--vergeq 10.0 || goto odt\install\skip_compress

    >&3 echo compress '%ProgramFiles%\Microsoft Office'
    >nul call :this\pkg\--exe "%ProgramFiles%\Microsoft Office"

:odt\install\skip_compress

    >&3 echo convert to volume license
    setlocal
    REM get ospp path
    for /r "%ProgramFiles%\Microsoft Office" %%a in (
        ospp.vb?
    ) do set "_ospp=%%a"
    if not defined _ospp exit /b 5

    for /r "%ProgramFiles%\Microsoft Office" /d %%a in (
        License*
    ) do call :odt\install\clic "%%a" || exit /b 5
    endlocal
    >&3 echo.
    >&3 echo install complete.
    >&3 echo.

    REM active
    >&3 echo try to activate
    call :lib\kms --odt
    exit /b 0

REM convert to volume license
:odt\install\clic
    for /r %1 %%a in (
        ProPlusVL_KMS*.xrm-ms
        ProjectProVL_KMS*.xrm-ms
        VisioProVL_KMS*.xrm-ms
        client-issuance-*.xrm-ms
        pkeyconfig-office.xrm?ms
    ) do >&3 set /p=.<nul& >nul cscript.exe //nologo "%_ospp%" /inslic:"%%~a" || exit /b 1
    REM >nul cscript.exe //nologo %windir%\System32\slmgr.vbs /ilc "%%~a"
    exit /b 0

:odt\pro\base
    call :odt\install\var word excel visio %*
    goto :eof

:odt\pro\full
    call :odt\install\var word excel powerpoint project visio %*
    goto :eof

:odt\install\var
    REM clear variable
    for /f "usebackq delims==" %%a in (
        `2^>nul set _odt__`
    ) do set %%a=
    REM Comment office professionalretail
    set _odt_pro=odt.xml

    REM ExcludeApp
    for %%a in (
        access excel onenote outlook powerpoint publisher word
    ) do set _odt__%%a=odt.xml
    for %%a in (
        access excel onenote outlook powerpoint publisher word
    ) do for %%b in (
        %*
    ) do if "%%~a"=="%%~b" set "_odt__%%a=" & set _odt_pro=

    REM must install some thing
    >nul 2>&1 set _odt__ || exit /b 5

    >&3 set /p=will install: <nul
    for %%a in (
        word excel powerpoint onenote access outlook publisher
    ) do if not defined _odt__%%a >&3 set /p='%%a' <nul

    REM Product
    for %%a in (%*) do for %%b in (
        project visio
    ) do if "%%~a"=="%%~b" set _odt__%%a=odt.xml
    for %%a in (
        project visio
    ) do if defined _odt__%%a >&3 set /p='%%a' <nul

    >&3 echo.
    >&3 echo [WARN] will remove previous installation
    exit /b 0

REM download and set in path
:odt\ext\setup
    for %%a in (odt.exe) do if "%%~$path:a" neq "" exit /b 0
    set PATH=%temp%\%~1;%PATH%
    if exist %temp%\%~1\odt.exe exit /b 0
    2>nul mkdir %temp%\%~1
    call :lib\download https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_9119.3601.exe %temp%\%~1\officedeploymenttool16.exe || exit /b 1
    %temp%\%~1\officedeploymenttool16.exe /extract:%temp%\%~1 /quiet
    rename %temp%\%~1\setup.exe odt.exe
    erase %temp%\%~1\officedeploymenttool16.exe %temp%\%~1\*.xml
    exit /b 0

::: "Visual Studio Installer" "" "usage: %~n0 vsi [branch] [option] [args]" "    branch:" "        enterprise" "        professional" "        community" "        core         (build tools without IDE)" "" "    option:" "        --deploy,  -d [directory_path]      Deployment visual studio build tools data" "        --install, -i [[directory_path]]    Install visual studio build tools online" "                                            when script in deploy path, will install offline"
:::: "invalid option" "args is empty" "can not get current language" "vs_install download error" "vs_buildtools error" "create soft link error" "can not install at root path" ""

:lib\vsi
    title vsi
    if "%~1"=="" call :this\annotation %0 & goto :eof
    if "%~2"=="" exit /b 2
    setlocal
    call :this\vsi\%*

    if errorlevel 1 goto :eof

    if exist "%ProgramData%\Microsoft\VisualStudio\Packages" rmdir /s /q "%ProgramData%\Microsoft\VisualStudio\Packages"

    REM remove other parttition 'ProgramData' directory
    if "%~2" neq "" if exist %~d2\ProgramData\Microsoft\VisualStudio\Packages rmdir /s /q %~d2\ProgramData\Microsoft\VisualStudio\Packages
    call :this\dir\--clean %~d2\ProgramData
    call :this\dir\--isfree %~d2\ProgramData && rmdir /s /q %~d2\ProgramData
    endlocal
    exit /b 0

:this\vsi\enterprise
:this\vsi\professional
:this\vsi\community
:this\vsi\core
    set _install_args=--includeRecommended
    set _branch=
    for %%a in (%0) do set _branch=%%~na
    REM vs_buildtools: set _install_args=--add Microsoft.VisualStudio.Component.Static.Analysis.Tools --add Microsoft.VisualStudio.Component.VC.CoreBuildTools --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK --add Microsoft.VisualStudio.Component.TestTools.BuildTools --add Microsoft.VisualStudio.Component.Windows10SDK.17134 --add Microsoft.VisualStudio.Component.WinXP
    if "%_branch%"=="core" set "_branch=buildtools"& set _install_args=--add Microsoft.VisualStudio.Workload.VCTools;includeRecommended
    call :vsi\option\%*
    goto :eof

REM https://docs.microsoft.com/zh-cn/visualstudio/install/workload-component-id-vs-build-tools#visual-c-build-tools
:vsi\option\--deploy
:vsi\option\-d
    if "%~1"=="" exit /b 2
    2>nul mkdir "%~1"
    call :this\ost\--current-lang _vsi_lang || exit /b 3
    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% || exit /b 4

    REM error args: --allWorkloads
    start /wait vs_%_branch%.exe --wait --lang %_vsi_lang% --layout "%~1" %_install_args% || exit /b 5
    if not errorlevel 1 echo can use command '%~1\vs_setup.exe --passive --wait --norestart --nocache --noWeb'
    goto :eof

REM REM Debuggable Package Manager （可调试包管理器）
REM powershell.exe -NoExit -Command "& { Import-Module Appx; Import-Module .\AppxDebug.dll; Show-AppxDebug}"
REM %comspec% /k "%VSINSTALLDIR%\Common7\Tools\VsDevCmd.bat"                REM Developer Command Prompt for VS 2017 （VS 2017的开发人员命令提示符）
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars32.bat"           REM x86 Native Tools Command Prompt for VS 2017 （适用于 VS 2017 的 x86 本机工具命令提示）
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvars64.bat"           REM x64 Native Tools Command Prompt for VS 2017 （适用于 VS 2017 的 x64 本机工具命令提示）
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsx86_amd64.bat"    REM x86_x64 Cross Tools Command Prompt for VS 2017 （适用于 VS 2017 的 x86_x64 兼容工具命令提示）
REM %comspec% /k "%VSINSTALLDIR%\VC\Auxiliary\Build\vcvarsamd64_x86.bat"    REM x64_x86 Cross Tools Command Prompt for VS 2017 （VS 2017的 x64_x86 交叉工具命令提示符）
REM https://docs.microsoft.com/zh-cn/visualstudio/install/build-tools-container
:vsi\option\--install
:vsi\option\-i
    if "%~1" neq "" (
        if "%~d1\"=="%~dp1" exit /b 7
        call :this\dir\--isfree "%~1" || exit /b 8
        2>nul mkdir "%~dp1Kits" "%~1"
        mklink /j "%ProgramFiles(x86)%\Windows Kits" "%~dp1Kits" || exit /b 6
        set _install_args=--installPath "%~1" %_install_args%
    )

    call :vsi\ext\setup e64d79b4-0219-aea6-18ce-2fe10ebd5f0d %_branch% || exit /b 4
    start /wait vs_%_branch%.exe --passive --wait --norestart --nocache %_install_args% || exit /b 5
    goto :eof

REM https://aka.ms/vs/15/release/vs_buildtools.exe
REM https://aka.ms/vs/15/release/vs_enterprise.exe
REM https://aka.ms/vs/15/release/vs_professional.exe
REM https://aka.ms/vs/15/release/vs_community.exe
:vsi\ext\setup
    for %%a in (vs_%~2.exe) do if "%%~$path:a" neq "" exit /b 0
    set PATH=%temp%\%~1;%PATH%
    if exist %temp%\%~1\vs_%~2.exe exit /b 0
    2>nul mkdir %temp%\%~1
    call :lib\download https://aka.ms/vs/15/release/vs_%~2.exe %temp%\%~1\vs_%~2.exe || exit /b 1
    exit /b 0

:::::::::::
:: other ::
:::::::::::

::: "Support load %USERPROFILE%\.batchrc before cmd.exe run" "" "usage: %~n0 batrc [[-d]]"
:::: "{UNUSE}"
:lib\batrc
    call :this\batrc\%*
    goto :eof

:this\batrc\
    setlocal

    call :lib\bs _bs
    reg.exe add "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "if not defined BS set BS=%_bs%&& (for /f \"usebackq delims=\" %%a in (\"%%USERPROFILE%%\.batchrc\") do @call %%a)>nul 2>&1" /f
    if exist "%USERPROFILE%\.batchrc" endlocal & exit /b 0
    > "%USERPROFILE%\.batchrc" (
        echo ;use ^>^&3 in script can print
        echo set devmgr_show_nonpresent_devices=1
        echo set path=%%path%%;%~dp0
        echo.
        echo title Command Prompt
    )
    endlocal
    exit /b 0

:this\batrc\-d
:this\batrc\--delete
    REM erase "%USERPROFILE%\.batchrc"
    reg.exe delete "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /f
    exit /b 0

:::::::::::::
:: regedit ::
:::::::::::::

::: "Edit the Registry" "" "usage: %~n0 reg [option]" "" "    --intel-amd, -ia                   Run this before Chang CPU" "    --replace,   -x   [file_path] [src_str] [tag_str]" "                                       Replace reg string"
:::: "invalid option" "OS version is too low" "Not windows directory" "source string empty" "reg.exe error"
:lib\reg
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\reg\%*
    goto :eof

:this\reg\--intel-amd
:this\reg\-ia
    call :this\ost\--vergeq 6.0 || exit /b 2

    if "%~1"=="" (
        setlocal
        set /p _i=[Warning] Reg vhd will be change, Yes^|No:
        if /i "%_i%" neq "y" if /i "%_i%" neq "yes" exit /b 0
        endlocal
        call :this\reg\delInteltag system
        exit /b 0
    )

    setlocal
    set _target=%~f1
    if "%_target:~-1%"=="\" set _target=%_target:~0,-1%
    if not exist "%_target%\Windows\System32\config\SYSTEM" exit /b 3
    reg.exe load HKLM\tmp "%_target%\Windows\System32\config\SYSTEM"
    call :this\reg\delInteltag tmp
    reg.exe unload HKLM\tmp
    endlocal
    exit /b 0

REM for :this\reg\--intel-amd
:this\reg\delInteltag
    for /f "tokens=1,4 delims=x	 " %%a in (
        'reg.exe query HKLM\%1\Select'
    ) do if /i "%%a"=="Default" reg.exe delete HKLM\%1\ControlSet00%%b\Services\intelppm /f 2>nul
    exit /b 0

REM winpe \$windows.~bt -> ""
:this\reg\--replace
:this\reg\-x
    if "%~2"=="" exit /b 4
    setlocal

    REM valueName: (Default) -> /ve
    for /f "usebackq" %%a in (
        `reg.exe query HKLM /ve`
    ) do set "_ve=%%a"

    set _load_point=HKLM\load-point%random%
    if exist "%~1" (
        reg.exe load %_load_point% "%~1" || exit /b 5
        call :reg\replace %_load_point% %2 %3
        reg.exe unload %_load_point% || exit /b 5
    ) else call :reg\replace %1 %2 %3
    endlocal
    goto :eof

:reg\replace
    setlocal enabledelayedexpansion
    set _src=%~2
    set _src=%_src:"=\"%

    set _tag=%~3
    if defined _tag set _tag=!_tag:"=\"!

    set _count=0
    REM replace
    for /f "usebackq delims=" %%a in (
        `reg.exe query %1 /f %2 /s`
    ) do >nul (
        set _line=%%a
        if "!_line:\%~n1=!"=="!_line!" (
            set _line=!_line:    =`!
            REM /d "X:\" /f -> /d "X:\\" /f
            set _line=!_line:\`=\\`!
            REM /v "X:\" /t -> /v "X:\\" /t
            if "!_line:~-1!"=="\" set _line=!_line!\
            set _line=!_line:"=\"!
            for /f "tokens=1,2* delims=`" %%b in (
                "!_line:%_src%=%_tag%!"
            ) do if "%%c" neq "" (

                if "%%b" neq "%_ve%" (
                    reg.exe add "!_key!" /v "%%b" /t %%c /d "%%d" /f || exit /b 5

                    REM delete
                    for /f "delims=`" %%e in (
                        "!_line!"
                    ) do if "%%b" neq "%%e" reg.exe delete "!_key!" /v "%%e" /f || exit /b 5

                ) else reg.exe add "!_key!" /ve /t %%c /d "%%d" /f || exit /b 5

                set /a _count+=1
            )
        ) else set _key=!_line:HKEY_LOCAL_MACHINE=HKLM!
    )
    echo all '%_count%' change.
    endlocal
    goto :eof

REM REM from Window 10 aik, will download imagex.exe at script path
REM :init\imagex
REM     for %%a in (_%0) do if %processor_architecture:~-2%==64 (
REM         REM amd64
REM         call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk d2611745022d67cf9a7703eb131ca487 fil4927034346f01b02536bd958141846b2

REM     REM x86
REM     ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk eacac0698d5fa03569c86b25f90113b5 fil6e1d5042624c9d5001511df2bfe4c40b
REM     exit /b 0

::: "Create string" "" "usage: %~n0 str [option] ..." "" "    --now,  -n [var_name] [[head_str]] [[tail_str]]    Display Time at [YYYYMMDDhhmmss]" "    --uuid, -u [[var_name]]                            Get UUID string"
:::: "invalid option" "variable name is empty"
:lib\str
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\str\%*
    goto :eof

:this\str\-n
:this\str\--now
    if "%~1"=="" exit /b 2
    set date=
    set time=
    REM en zh
    for /f "tokens=1-8 delims=-/:." %%a in (
      "%time: =%.%date: =.%"
    ) do if %%e gtr 1970 (
        set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
    ) else if %%g gtr 1970 set %~1=%~2%%g%%e%%f%%a%%b%%c%~3
    exit /b 0

:this\str\-u
:this\str\--uuid
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

::: "Print text to standard output." "" "usage: %~n0 txt [option] [...]" "" "    --head,  -e  [-[count]]          Print the first some lines of FILE to standard output." "    --tail,  -t  [-[count]]          Print the last some lines of FILE to standard output." "    --skip,  -j  [source_file_path] [skip_line_num] [target_flie_path]" "                                     Print text skip some line" "" "    --subtxt, -o [source_path] [tag] [skip]" "                                     Show the subdocuments in the destination file by prefix" "                        subdocuments:" "                                     ::prefix: line 1" "                                     ::prefix: line 2" "                                     ::^^^!_var^^^!: line 3" "                                     ..." ""
:::: "invalid option" "source file not found" "skip number error" "target file not found" "skip line is empty" "file not found" "powershell version is too old" "args error" "prefix is empty"
:lib\txt
    if "%~1"=="" call :this\annotation %0 & goto :eof
    call :this\txt\%*
    goto :eof

:this\txt\-e
:this\txt\--head
    call :this\psv
    if not errorlevel 3 exit /b 7
    call :txt\ps1 -first %*|| exit /b 8
    goto :eof

:this\txt\-t
:this\txt\--tail
    call :this\psv
    if not errorlevel 3 exit /b 7
    call :txt\ps1 -Last %*|| exit /b 8
    goto :eof

REM for :this\txt\--head, :this\txt\--tail
:txt\ps1
    setlocal
    if "%~2"=="" exit /b 2
    set _count=%~2
    set _count=%_count:-=%
    call :lib\inum %_count% || exit /b 2
    if exist "%~3" (
        PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Get-Content \"%~3\" %~1 %_count%"
    ) else PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$Input | Select-Object %~1 %_count%"
    endlocal
    goto :eof

:this\txt\--skip
:this\txt\-j
    if not exist "%~1" exit /b 2
    call :lib\inum %~2 || exit /b 3
    if not exist "%~3" exit /b 4
    REM >%3 type nul
    REM for /f "usebackq skip=%~2 delims=" %%a in (
    REM     "%~f1"
    REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

:this\txt\--subtxt [source_path] [tag] [skip]
:this\txt\-o
    if not exist "%~1" exit /b 2
    if "%~2"=="" exit /b 9
    setlocal enabledelayedexpansion
    if "%~3" neq "" 2>nul set /a _skip=%~3
    if not defined _skip set _skip=10
    if %_skip% leq 0 set _skip=10

    for /f "usebackq skip=%_skip% tokens=2* delims=:" %%a in (
        "%~f1"
    ) do if "%%a"=="%~2" echo.%%b

    endlocal
    goto :eof

REM "    --line,  -l  [text_file_path] [skip_line] " "                                     Output text or read config"  "                                     need enabledelayedexpansion" "                                     skip must reset" "                                     text format: EOF [output_target] [command]"
REM :this\txt\--line
REM :this\txt\-l
REM     if "%~1"=="" exit /b 5
REM     if not exist "%~2" exit /b 6
REM     set _log=nul
REM     set "_exec=REM "
REM     for /f "usebackq skip=%~2 delims=" %%a in (
REM         "%~f1"
REM     ) do for /f "tokens=1,2*" %%b in (
REM         "%%a"
REM     ) do if "%%b"=="EOF" (
REM         if "%%c"=="%%~fc" if not exist "%%~dpc" (
REM             mkdir "%%~dpc"
REM         ) else if exist "%%~c" erase "%%~c"
REM         set "_log=%%~c"
REM         set "_exec=%%~d"
REM     ) else >>!_log! !_exec!%%~a
REM     set _log=
REM     set _exec=
REM     exit /b 0

REM REM text format for :lib\execline
REM EOF !temp!\!_now!.log "echo "
REM some codes
REM EOF nul set
REM a=1
REM EOF nul "rem "


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
    for /f "usebackq delims=" %%a in (
        `2^>nul dir /a-d /b /s %*`
    ) do for %%b in (%0) do call :this\hash %%~nb "%%~a" || exit /b 1
    exit /b 0

:this\hash
    if exist "%~2" for /f "usebackq tokens=1,2 delims=(h" %%a in (
        `certutil.exe -hashfile %2 %~1`
    ) do if "%%b"=="" call :hash\trim "%%a" %2& exit /b 0
    if exist "%~2" exit /b 1
    setlocal
    call :this\psv
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

:hash\trim
    setlocal
    set _str=%~1
    echo %_str: =%   %2
    endlocal
    goto :eof

REM ::: "Delete Login Notes"
REM :lib\delLoginNote
REM     net.exe use * /delete
REM     exit /b 0

REM Test PowerShell version, Return errorlevel
:this\psv
    for %%a in (PowerShell.exe) do if "%%~$path:a"=="" exit /b 0
    for /f "usebackq" %%a in (
        `2^>nul PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "$PSVersionTable.WSManStackVersion.Major"`
    ) do exit /b %%a
    exit /b 0

::: "Run PowerShell script" "" "usage: %~n0 ps1 [ps1_script_path]"
:::: "ps1 script not found" "file suffix error"
:lib\ps1
    if not exist "%~1" exit /b 1
    if /i "%~x1" neq ".ps1" exit /b 2
    PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -File %*
    goto :eof

::::::::::::::
:: VBScript ::
::::::::::::::

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

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

REM set /a 0x7FFFFFFF
REM -2147483647 ~ 2147483647

REM start /b [command...]
:thread
    call %~pnx1
    goto :eof

::::: thread valve :::::
REM usage: :this\thread_valve [count] [name] [commandline]
:this\thread_valve
    set /a _thread\count+=1
    if %_thread\count% lss %~1 exit /b 0
    :thread_valve\loop
        set _thread\count=0
        for /f "usebackq" %%a in (
            `2^>nul wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid ^| %windir%\System32\find.exe /c /v ""`
        ) do set /a _thread\count=%%a - 2
        if %_thread\count% gtr %~1 goto thread_valve\loop
    exit /b 0

::::: Map :::::
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
        `2^>nul set _MAP%~2\`
    ) do set "_keys=!_keys! "%%~nxa""
    endlocal & set %~1=%_keys%
    exit /b 0

:this\map\--values
:this\map\-vs
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _values=
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~2\`
    ) do set "_values=!_values! "%%~b""
    endlocal & set %~1=%_values%
    exit /b 0

:this\map\--arr
:this\map\-a
    if "%~1"=="" exit /b 0
    setlocal enabledelayedexpansion
    set _kv=
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~2\`
    ) do set "_kv=!_kv! "%%~nxa" "%%~b""
    endlocal & set %~1=%_kv%
    exit /b 0

:this\map\--size
:this\map\-s
    setlocal
    set _count=0
    for /f "usebackq tokens=1* delims==" %%a in (
        `2^>nul set _MAP%~1\`
    ) do set /a _count+=1
    endlocal & exit /b %_count%

:this\map\--clear
:this\map\-c
    call :this\var\--unset _MAP%~1\
    exit /b 0


::::: page :::::
:page
    call :this\page\%*
    goto :eof

:this\page\--put
:this\page\-p
    if not defined _page (
        set _page=1000000000
    ) else set /a _page+=1
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
    call :this\var\--unset _page
    exit /b 0

REM load .*.ini config
:this\load_ini
    if "%~1"=="" exit /b 1
    set _tag=
    REM trim ';' and cut it
    for /f "usebackq delims=" %%a in (
        `2^>nul type "%~dp0.*.ini" "%userprofile%\.*.ini"`
    ) do for /f "usebackq tokens=1 delims=;" %%b in (
        '%%a'
    ) do for /f "usebackq tokens=1* delims==" %%c in (
        '%%b'
    ) do if "%%d"=="" (
        if /i "%%c"=="[%~1]" (
            set _tag=true
        ) else set _tag=
    ) else if defined _tag set _MAP%~2\%%c=%%d
    set _tag=

    REM REM Load
    REM for /f "usebackq tokens=1* delims==" %%a in (
    REM     `set`
    REM ) do if "%%~da" neq "\\" (
    REM     call :this\testMACaddr %%~b && set _MAP%~2\%%a=%%~b
    REM     call :this\ip\--test %%~b && set _MAP%~2\%%a=%%~b
    REM )

    call :map -s %~2 && exit /b 1
    exit /b 0

  :: :: :: :: ::
::     Base     ::
::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :this\var\--errlv %errorlevel%
    for /f "usebackq skip=73 tokens=1,2* delims=\ " %%a in (
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
                    call :this\var\--errlv %errorlevel%
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
    call :%~n0\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `2^>nul set _args\%~n1`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a _i+=1
        set _target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :%~n0\lals !_tmp! %_col%
        if !_i! geq 2 call :%~n0\lals %%~nxa %_col%
    ) else call :%~n0\lali %%~nxa "%%~b"
    REM Close lals
    if !_i! gtr 0 call :%~n0\lals 0 0
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

::: "Make the second column left-aligned" "" "    default size is 15" "usage: %~n0 lali [str_1] [str_2]"
:::: "input string is empty"
:lib\lali
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

::: "Use right pads spaces, make all column left-aligned" "" "usage: %~n0 lals [str] [[col_size]]" "       %~n0 lals 0 0" "       close command" "       col_size is cols / 15" "       print nobr, but auto LF by col_size"
:::: "input string is empty"
:lib\lals
    if "%~1"=="" exit /b 1
    if "%~2" neq "" if 1%~2 lss 12 (if defined _lals echo. & set _lals=) & exit /b 0
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    if "%~2" neq "" if 1%_lals% geq 1%~2 echo. & set /a _lals-=%~2-1
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    >&3 set /p=%~1!_spaces:~0,%_len%!<nul
    set /a _lals+=1
    if "%~2" neq "" if 1%_lals% geq 1%~2 echo. & set _lals=
    endlocal & set _lals=%_lals%
    exit /b 0

REM for :lib\lali and :lib\lals and
:strModulo
    set /a _lals+=1
    set _str=%_str:~15%
    if "%_str:~31,1%"=="" exit /b 0
    goto %0

::: "Get cmd cols" "" "usage: %~n0 cols [[var_name]]"
:lib\cols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::


REM for :lib\odt
               ::odt.xml:<^!-- Office 365 client configuration file sample. To be used for Office 365 ProPlus 2016 apps,
               ::odt.xml:     Office 365 Business 2016 apps, Project Pro for Office 365 and Visio Pro for Office 365.
               ::odt.xml:
               ::odt.xml:     For detailed information regarding configuration options visit: http://aka.ms/ODT.
               ::odt.xml:     To use the configuration file be sure to remove the comments
               ::odt.xml:
               ::odt.xml:     For Office 365 client apps (verion 2013) you will need to use the 2013 version of the
               ::odt.xml:     Office Deployment Tool which can be downloaded from http://aka.ms/ODT2013
               ::odt.xml:
               ::odt.xml:     The following sample allows you to download and install Office 365 ProPlus 2016 apps
               ::odt.xml:     and Visio Pro for Office 365 directly from the Office CDN using the Current Channel
               ::odt.xml:     settings  -->
               ::odt.xml:
               ::odt.xml:<Configuration>
               ::odt.xml:
               ::odt.xml:    <^!--
               ::odt.xml:    <Remove All="TRUE">
               ::odt.xml:        <Product ID="AccessRetail" />
               ::odt.xml:        <Product ID="AccessRuntimeRetail" />
               ::odt.xml:        <Product ID="ExcelRetail" />
               ::odt.xml:        <Product ID="HomeBusinessRetail" />
               ::odt.xml:        <Product ID="HomeStudentRetail" />
               ::odt.xml:        <Product ID="InfoPathRetail" />
               ::odt.xml:        <Product ID="LyncEntryRetail" />
               ::odt.xml:        <Product ID="LyncRetail" />
               ::odt.xml:        <Product ID="O365BusinessRetail" />
               ::odt.xml:        <Product ID="O365HomePremRetail" />
               ::odt.xml:        <Product ID="O365ProPlusRetail" />
               ::odt.xml:        <Product ID="O365SmallBusPremRetail" />
               ::odt.xml:        <Product ID="OneNoteRetail" />
               ::odt.xml:        <Product ID="OutlookRetail" />
               ::odt.xml:        <Product ID="PowerPointRetail" />
               ::odt.xml:        <Product ID="ProfessionalRetail" />
               ::odt.xml:        <Product ID="ProjectProRetail" />
               ::odt.xml:        <Product ID="ProjectProXVolume" />
               ::odt.xml:        <Product ID="ProjectStdRetail" />
               ::odt.xml:        <Product ID="ProjectStdXVolume" />
               ::odt.xml:        <Product ID="PublisherRetail" />
               ::odt.xml:        <Product ID="SkypeforBusinessEntryRetail" />
               ::odt.xml:        <Product ID="SkypeforBusinessRetail" />
               ::odt.xml:        <Product ID="SPDRetail" />
               ::odt.xml:        <Product ID="VisioProRetail" />
               ::odt.xml:        <Product ID="VisioProXVolume" />
               ::odt.xml:        <Product ID="VisioStdRetail" />
               ::odt.xml:        <Product ID="VisioStdXVolume" />
               ::odt.xml:        <Product ID="WordRetail" />
               ::odt.xml:    </Remove>
               ::odt.xml:    -->
               ::odt.xml:
               ::odt.xml:    <Add SourcePath="!_odt_source_path!\" OfficeClientEdition="64" Channel="Broad">
               ::odt.xml:
            ::!_odt_pro!:    <^!--
               ::odt.xml:        <^!--  https://go.microsoft.com/fwlink/p/?LinkID=301891  -->
               ::odt.xml:        <Product ID="ProfessionalRetail">
               ::odt.xml:            <Language ID="!_odt_lang!" />
        ::!_odt__access!:            <ExcludeApp ID="Access" />
         ::!_odt__excel!:            <ExcludeApp ID="Excel" />
       ::!_odt__onenote!:            <ExcludeApp ID="OneNote" />
       ::!_odt__outlook!:            <ExcludeApp ID="Outlook" />
    ::!_odt__powerpoint!:            <ExcludeApp ID="PowerPoint" />
     ::!_odt__publisher!:            <ExcludeApp ID="Publisher" />
          ::!_odt__word!:            <ExcludeApp ID="Word" />
               ::odt.xml:        </Product>
            ::!_odt_pro!:    -->
               ::odt.xml:
         ::!_odt__visio!:        <Product ID="VisioProRetail">
         ::!_odt__visio!:            <Language ID="!_odt_lang!" />
         ::!_odt__visio!:        </Product>
         ::!_odt__visio!:
       ::!_odt__project!:        <Product ID="ProjectProRetail">
       ::!_odt__project!:            <Language ID="!_odt_lang!" />
       ::!_odt__project!:        </Product>
       ::!_odt__project!:
               ::odt.xml:    </Add>
               ::odt.xml:
         ::!_odt_update!:    <Updates Enabled="TRUE" UpdatePath="!_odt_source_path!\" Channel="Broad" />
         ::!_odt_update!:
               ::odt.xml:    <Display Level="Full" AcceptEULA="TRUE" />
               ::odt.xml:    <^!--  <Display Level="None" AcceptEULA="TRUE" />  -->
               ::odt.xml:
               ::odt.xml:    <Logging Path="%temp%" />
               ::odt.xml:    <^!--  <Property Name="AUTOACTIVATE" Value="1" />  -->
               ::odt.xml:
               ::odt.xml:</Configuration>

REM for :this\wim\--new
    ::wim.ini:[ExclusionList]
    ::wim.ini:\$*
    ::wim.ini:\boot*
; REM fix: \*.sys == *.sys
    ::wim.ini:\hiberfil.sys
    ::wim.ini:\pagefile.sys
    ::wim.ini:\swapfile.sys
    ::wim.ini:\ProgramData\Microsoft\Windows\SQM
    ::wim.ini:\System Volume Information
    ::wim.ini:\Users\*\AppData\Local\GDIPFONTCACHEV1.DAT
    ::wim.ini:\Users\*\AppData\Local\Temp\*
    ::wim.ini:\Users\*\NTUSER.DAT*.TM.blf
    ::wim.ini:\Users\*\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Users\*\NTUSER.DAT*.log*
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.TM.blf
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.regtrans-ms
    ::wim.ini:\Windows\AppCompat\Programs\Amcache.hve*.log*
    ::wim.ini:\Windows\CSC
    ::wim.ini:\Windows\Debug\*
    ::wim.ini:\Windows\Logs\*
    ::wim.ini:\Windows\Panther\*.etl
    ::wim.ini:\Windows\Panther\*.log
    ::wim.ini:\Windows\Panther\FastCleanup
    ::wim.ini:\Windows\Panther\img
    ::wim.ini:\Windows\Panther\Licenses
    ::wim.ini:\Windows\Panther\MigLog*.xml
    ::wim.ini:\Windows\Panther\Resources
    ::wim.ini:\Windows\Panther\Rollback
    ::wim.ini:\Windows\Panther\Setup*
    ::wim.ini:\Windows\Panther\UnattendGC
    ::wim.ini:\Windows\Panther\upgradematrix
    ::wim.ini:\Windows\Prefetch\*
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.TM.blf
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Windows\ServiceProfiles\LocalService\NTUSER.DAT*.log*
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.TM.blf
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.regtrans-ms
    ::wim.ini:\Windows\ServiceProfiles\NetworkService\NTUSER.DAT*.log*
    ::wim.ini:\Windows\System32\config\RegBack\*
    ::wim.ini:\Windows\System32\config\*.TM.blf
    ::wim.ini:\Windows\System32\config\*.regtrans-ms
    ::wim.ini:\Windows\System32\config\*.log*
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.TM.blf
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.regtrans-ms
    ::wim.ini:\Windows\System32\SMI\Store\Machine\SCHEMA.DAT*.log*
    ::wim.ini:\Windows\System32\sysprep\Panther
    ::wim.ini:\Windows\System32\winevt\Logs\*
    ::wim.ini:\Windows\System32\winevt\TraceFormat\*
    ::wim.ini:\Windows\Temp\*
    ::wim.ini:\Windows\TSSysprep.log
    ::wim.ini:

REM for current hotfix
    ::chot.xml:<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    ::chot.xml:    <xsl:output method="text"/><xsl:template match="/">
    ::chot.xml:        <xsl:for-each select="//References"><xsl:sort select="DownloadURL"/>
     ::!_chot!:            <xsl:if test="not(contains(DownloadURL, 'kb!_chot_kb!'))">
    ::chot.xml:            <xsl:value-of select="DownloadURL"/><xsl:text>&#10;</xsl:text>
     ::!_chot!:            </xsl:if>
    ::chot.xml:        </xsl:for-each>
    ::chot.xml:    </xsl:template>
    ::chot.xml:</xsl:transform>

REM for unattend.xml
        ::unattend.xml:<?xml version="1.0" encoding="utf-8"?>
        ::unattend.xml:<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
        ::unattend.xml:    <settings pass="oobeSystem">
    ::!_unattend_lang!:        <component name="Microsoft-Windows-International-Core" processorArchitecture="!_bit!" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    ::!_unattend_lang!:            <InputLocale>!_lang!</InputLocale>
    ::!_unattend_lang!:            <SystemLocale>!_lang!</SystemLocale>
    ::!_unattend_lang!:            <UILanguage>!_lang!</UILanguage>
    ::!_unattend_lang!:            <UILanguageFallback>!_lang!</UILanguageFallback>
    ::!_unattend_lang!:            <UserLocale>!_lang!</UserLocale>
    ::!_unattend_lang!:        </component>
        ::unattend.xml:        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="!_bit!" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
        ::unattend.xml:            <AutoLogon>
        ::unattend.xml:                <Enabled>true</Enabled>
        ::unattend.xml:                <LogonCount>1</LogonCount>
        ::unattend.xml:                <Username>!_user!</Username>
        ::unattend.xml:            </AutoLogon>
        ::unattend.xml:            <OOBE>
        ::unattend.xml:                <SkipMachineOOBE>true</SkipMachineOOBE>
        ::unattend.xml:            </OOBE>
    ::!_unattend_user!:            <UserAccounts>
    ::!_unattend_user!:                <LocalAccounts>
    ::!_unattend_user!:                    <LocalAccount wcm:action="add">
    ::!_unattend_user!:                        <Password>
    ::!_unattend_user!:                            <Value></Value>
    ::!_unattend_user!:                            <PlainText>true</PlainText>
    ::!_unattend_user!:                        </Password>
    ::!_unattend_user!:                        <Group>administrators;!_user!</Group>
    ::!_unattend_user!:                        <Name>!_user!</Name>
    ::!_unattend_user!:                    </LocalAccount>
    ::!_unattend_user!:                </LocalAccounts>
    ::!_unattend_user!:            </UserAccounts>
    ::!_unattend_lang!:            <TimeZone>!_standard_time!</TimeZone>
        ::unattend.xml:        </component>
        ::unattend.xml:    </settings>
        ::unattend.xml:</unattend>

REM hisecws.inf: Registry Values: 1:REG_SZ 2:REG_EXPAND_SZ 3:REG_BINARY 4:REG_DWORD 7:REG_MULTI_SZ
    ::hisecws.inf:[Unicode]
    ::hisecws.inf:Unicode=yes
    ::hisecws.inf:
    ::hisecws.inf:[System Access]
    ::hisecws.inf:MaximumPasswordAge = -1
    ::hisecws.inf:PasswordComplexity = 0
    ::hisecws.inf:
    ::hisecws.inf:[Registry Values]
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCAD=4,1
    ::hisecws.inf:MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun=4,255
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\**del.ShutdownReasonUI=1,""
    ::hisecws.inf:MACHINE\Software\Policies\Microsoft\Windows NT\Reliability\ShutdownReasonOn=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseAdvancedStartup=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\EnableBDEWithNoTPM=4,1
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPM=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMPIN=4,0
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKey=4,2
    ::hisecws.inf:;MACHINE\Software\Policies\Microsoft\FVE\UseTPMKeyPIN=4,0
    ::hisecws.inf:User\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoThumbnailCache=4,1
    ::hisecws.inf:User\Software\Policies\Microsoft\Windows\Explorer\DisableThumbsDBOnNetworkFolders=4,1
    ::hisecws.inf:
    ::hisecws.inf:[Version]
    ::hisecws.inf:signature="$CHICAGO$"
    ::hisecws.inf:Revision=1
    ::hisecws.inf:

    ::DefaultLayouts.xml:<?xml version="1.0" encoding="utf-8"?>
    ::DefaultLayouts.xml:<FullDefaultLayoutTemplate
    ::DefaultLayouts.xml:    xmlns="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    ::DefaultLayouts.xml:    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    ::DefaultLayouts.xml:    Version="1">
    ::DefaultLayouts.xml:    <StartLayoutCollection>
    ::DefaultLayouts.xml:        <StartLayout
    ::DefaultLayouts.xml:            GroupCellWidth="6"
    ::DefaultLayouts.xml:            PreInstalledAppsEnabled="false">
    ::DefaultLayouts.xml:            <start:Group Name="">
    ::DefaultLayouts.xml:                <start:Tile
    ::DefaultLayouts.xml:                    AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge"
    ::DefaultLayouts.xml:                    Size="4x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Administrative Tools\services.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="4"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationID="Microsoft.Windows.ControlPanel"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="1"/>
    ::DefaultLayouts.xml:                <start:Tile
    ::DefaultLayouts.xml:                    AppUserModelID="Microsoft.WindowsStore_8wekyb3d8bbwe!App"
    ::DefaultLayouts.xml:                    Size="4x2"
    ::DefaultLayouts.xml:                    Row="2"
    ::DefaultLayouts.xml:                    Column="2"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk"
    ::DefaultLayouts.xml:                    Size="1x1"
    ::DefaultLayouts.xml:                    Row="3"
    ::DefaultLayouts.xml:                    Column="1"/>
    ::DefaultLayouts.xml:            </start:Group>
    ::DefaultLayouts.xml:        </StartLayout>
    ::DefaultLayouts.xml:
    ::DefaultLayouts.xml:        <StartLayout
    ::DefaultLayouts.xml:            GroupCellWidth="6"
    ::DefaultLayouts.xml:            SKU="Server|ServerSolution">
    ::DefaultLayouts.xml:            <start:Group>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Server Manager.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="0"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="2"/>
    ::DefaultLayouts.xml:                <start:DesktopApplicationTile
    ::DefaultLayouts.xml:                    DesktopApplicationID="Microsoft.Windows.ControlPanel"
    ::DefaultLayouts.xml:                    Size="2x2"
    ::DefaultLayouts.xml:                    Row="0"
    ::DefaultLayouts.xml:                    Column="4"/>
    ::DefaultLayouts.xml:            </start:Group>
    ::DefaultLayouts.xml:        </StartLayout>
    ::DefaultLayouts.xml:    </StartLayoutCollection>
    ::DefaultLayouts.xml:</FullDefaultLayoutTemplate>
    ::DefaultLayouts.xml:
