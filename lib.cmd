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
    if "%*"=="" call :this\annotation %0 & goto :eof
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
REM         `dir /a-d /b "!path:;=\%~1*" "!\%~1*" 2^>nul`
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
        `wmic.exe ENVIRONMENT where "name='path'" get VariableValue /format:list`
    ) do set path=%%a
    REM Trim unprint char
    set path=%path%
    exit /b 0

::: "Variable tool" "" "usage: %~n0 var [option] [...]" "" "    --unset, -u   [[var_name]]      Unset variable, where variable name left contains" "    --env,   -e   [key] [value]     Set environment variable" "    --errlv, -el  [num]             Set errorlevel variable"
:::: "invalid option" "key is empty" "value is empty" "The parameter is empty"
:lib\var
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\var\%*
    goto :eof

:this\var\-u
:this\var\--unset
    if "%~1"=="" exit /b 4
    for /f "usebackq delims==" %%a in (
        `set %1 2^>nul`
    ) do set %%a=
    exit /b 0

:this\var\-e
:this\var\--env
    if "%~1"=="" exit /b 2
    if "%~2"=="" exit /b 3
    for %%a in (setx.exe) do if "%%~$path:a" neq "" setx.exe %~1 %2 /m >nul & exit /b 0
    if defined %~1 wmic.exe environment where name="%~1" set VariableValue="%~2"
    if not defined %~1 wmic.exe environment create name="%~1",username="<system>",VariableValue="%~2"
    exit /b 0

:this\var\-el
:this\var\--errlv
    if "%~1"=="" goto :eof
    exit /b %1


::: "Run by ..." "" "usage: %~n0 run [option]" "" "    --admin,  -a  [...]    Run As Administrator" "    --vbhide, -q  [...]    Run some command at background"
:::: "invalid option" "The first parameter is empty"
:lib\run
    if "%*"=="" call :this\annotation %0 & goto :eof
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
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\ps\%*
    goto :eof

:this\ps\-t
:this\ps\--test
    REM tasklist.exe /v /FI "imagename eq %~n1.exe"
    if "%~1"=="" exit /b 2
    for /f usebackq^ tokens^=2^ delims^=^=^" %%a in (
        `wmic.exe process where caption^="%~n1.exe" get commandline /value 2^>nul`
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
    REM     `wmic.exe process where "commandline like '%*'" get processid 2^>nul`
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
        `call lib.cmd ip --find %_keys%`
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
    if "%*"=="" call :this\annotation %0 & goto :eof
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
        start /b lib.cmd \\:ip\--find %%~na.%%b %_macs%
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


::: "Create string" "" "usage: %~n0 str [option] ..." "" "    --now,  -n [var_name] [[head_str]] [[tail_str]]    Display Time at [YYYYMMDDhhmmss]" "    --uuid, -u [[var_name]]                            Get UUID string"
:::: "invalid option" "variable name is empty"
:lib\str
    if "%*"=="" call :this\annotation %0 & goto :eof
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

::: "Print text to standard output." "" "usage: %~n0 txt [option] [...]" "" "    --head, -e  [-[count]]          Print the first some lines of FILE to standard output." "    --tail, -t  [-[count]]          Print the last some lines of FILE to standard output." "    --skip, -j  [source_file_path] [skip_line_num] [target_flie_path]     Print text skip some line" "    --line, -l  [text_file_path] [skip_line]         Output text or read config"  "                                                     need enabledelayedexpansion" "                                                     skip must reset" "                                                     text format: EOF [output_target] [command]"
:::: "invalid option" "source file not found" "skip number error" "target file not found" "skip line is empty" "file not found" "powershell version is too old" "args error"
:lib\txt
    if "%*"=="" call :this\annotation %0 & goto :eof
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
    if not exist "%~1" exit /b 2
    call :lib\inum %~2 || exit /b 3
    if not exist "%~3" exit /b 4
    REM >%3 type nul
    REM for /f "usebackq skip=%~2 delims=" %%a in (
    REM     "%~f1"
    REM ) do >> %3 echo %%a
    < "%~f1" more.com +%~2 >%3
    exit /b 0

:this\txt\--line
    if "%~1"=="" exit /b 5
    if not exist "%~2" exit /b 6
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

REM ::: "Delete Login Notes"
REM :lib\delLoginNote
REM     net.exe use * /delete
REM     exit /b 0

::: "Test PowerShell version" "" "Return errorlevel"
:this\psv
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

;:: set /a 0x7FFFFFFF
;:: 2147483647 ~ -2147483647
;:: PowerShell : hyper-v install-windowsfeature server-gui-shell
;:: data:application/cab;base64,

REM :lib\sexport
REM     SecEdit.exe /export /cfg .\hisecws.inf
REM     exit /b 0
REM     SecEdit.exe /configure /db c:\Windows\Temp\hisecws.sdb /cfg c:\Windows\Temp\hisecws.inf /log c:\Windows\Temp\hisecws.log /quiet

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

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
            `wmic.exe process where "name='%~2' and commandline like '%%%~3%%'" get processid 2^>nul ^| %windir%\System32\find.exe /c /v ""`
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
    call :this\var\--unset _MAP%~1\
    exit /b 0


::::: page :::::
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
    call :this\var\--unset _page
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
        `set _args\%~n1 2^>nul`
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
