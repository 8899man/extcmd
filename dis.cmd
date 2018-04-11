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

:::::::::::::::::::::::::::
:: dis = dism & diskpart ::
:::::::::::::::::::::::::::

REM init errorlevel
set errorlevel=

REM Init PATH
for %%a in (%~nx0) do if "%%~$path:a"=="" set path=%path%;%~dp0

if "%~2"=="-h" call :this\annotation :%~n0\%~1 & exit /b 0
if "%~2"=="--help" call :this\annotation :%~n0\%~1 & exit /b 0

call :%~n0\%* 2>nul

REM Test type function
if errorlevel 10 exit /b 1
if errorlevel 1 call :this\annotation :%~n0\%* & goto :eof
exit /b 0

:dis\
:dis\-h
:dis\--help
    call :this\annotation
    exit /b 0

::: "Output version and exit"
:dis\version
    >&3 echo 0.18.3
    exit /b 0

::: "Directory tools" "" "usage: %~n0 dir [option] [...]" "" "    --isdir,  -id  [path]       Test path is directory" "    --islink, -il  [file_path]  Test path is Symbolic Link" "    --isfree, -if  [dir_path]   Test directory is empty" "    --trim,   -c   [dir_path]   Delete empty directory"
:::: "invalid option" "Not directory" "target not found" "target not a directory"
:dis\dir
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\dir\%*
    goto :eof

:this\dir\--isdir
:this\dir\-id
    setlocal
    set _path=%~a1-
    REM quick return
    set _code=10
    if %_path:~0,1%==d set _code=0
    endlocal & exit /b %_code%

:this\dir\--islink
:this\dir\-il
    for /f "usebackq delims=" %%a in (
        `dir /al /b "%~dp1" 2^>nul`
    ) do if "%%a"=="%~n1" exit /b 0
    REM quick return
    exit /b 10

:this\dir\--isfree
:this\dir\-if
    call :this\dir\--isdir %1 || exit /b 2
    for /d %%a in ("%~1\*") do exit /b 10
    for /r %1 %%a in (*.*) do exit /b 10
    exit /b 0

:this\dir\--trim
:this\dir\-c
    if not exist "%~1" exit /b 3
    call :this\dir\--isdir %1 || exit /b 4
    if exist %windir%\system32\sort.exe (
        call :this\dir\rdNullDirWithSort %1
    ) else call :this\dir\rdNullDir %1
    goto :eof

REM for :this\dir\--trim
:this\dir\rdNullDir
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

REM for :this\dir\--trim
:this\dir\rdNullDirWithSort
    if "%~1"=="" exit /b 2
    for /f "usebackq delims=" %%a in (
        `dir /ad /b /s %1 ^| sort.exe /r`
    ) do 2>nul rmdir "%%~a"
    exit /b 0


::: "Operating system settings" "" "usage: %~n0 oset [option] [...]" "" "    --vergeq,  -vg [version]                  Test this system version" "    --cleanup, -c  [[path]]                   Component Cleanup" "    --info,    -i  [os_path] [[var_name]]     Get OS language bit and version" "                   return" "                         [var].lang [var].bit [var].ver" "" "    --feature-info,   -fi                     Get Feature list" "    --feature-enable, -fe [name ...]          Enable Feature" "    --set-power,      -sp                     Set power config as server type"
:::: "invalid option" "Parameter is empty or Not a float" "not a directory" "Not OS path or Low OS version" "parameter is empty" "System version is too old"
:dis\oset
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\oset\%*
    goto :eof

:this\oset\-vg
:this\oset\--vergeq
    if "%~x1"=="" exit /b 2
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

:this\oset\--cleanup
:this\oset\-c
    if "%~1"=="" dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase & exit /b 0
    call :this\dir\--isdir "%~1" || exit /b 3
    dism.exe /Image:%1 /Cleanup-Image /StartComponentCleanup /ResetBase
    exit /b 0

:this\oset\-i
:this\oset\--info
    if not exist %~1\Windows\servicing exit /b 4

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

:this\oset\--feature-info
:this\oset\-fi
    for /f "usebackq tokens=1-4" %%a in (
        `dism.exe /English /Online /Get-Features`
    ) do (
        if "%%a%%b"=="FeatureName" call :this\lals %%d
        if "%%a"=="State" call :this\lals %%c & echo.
    )
    call :this\lals 0 0
    exit /b 0

:this\oset\--feature-enable
:this\oset\-fe
    if "%~1"=="" exit /b 5
    for %%a in (
        %*
    ) do dism.exe /English /Online /Enable-Feature /FeatureName:%%a /NoRestart
    exit /b 0

:this\oset\--set-power
:this\oset\-sp
    call :this\oset\--vergeq 6.0 || exit /b 6

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

::: "Letter info" "" "usage: %~n0 letter [option] [...]" "" "    --free, -e   [[var_name]]           Get Unused Device Id" "    --list, -l   [var_name] [[l/r/n]]   Get Device IDs" "    --tisl, --   [var_name] [[l/r/n]]   Get Device IDs DESC" "                                        no param view all" "                                     l: Local Fixed Disk" "                                     r: CD-ROM Disc" "                                     n: Network Connection" "    --firstpath, -fp  [path_name] [[var_name]]     Get first path foreach Partiton"
:::: "invalid option" "variable name is empty" "type command not support" "The first parameter is empty" "Target path not found"
:dis\letter
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\letter\%*
    goto :eof

:this\letter\-e
:this\letter\--free
    setlocal enabledelayedexpansion
    set _di=zyxwvutsrqponmlkjihgfedcba
    for /f "usebackq skip=1 delims=:" %%a in (
        `wmic.exe logicaldisk get DeviceID`
    ) do set _di=!_di:%%a=!
    endlocal & if "%~1"=="" (
        echo.%_di:~0,1%:
    ) else set %~1=%_di:~0,1%:
    exit /b 0

:this\letter\-l
:this\letter\--list
:this\letter\--
:this\letter\--tisl
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

:this\letter\-fp
:this\letter\--firstpath
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
:dis\cpwd
    call :this\oset\--vergeq 6.1 || exit /b 1
    if "%~1"=="" exit /b 2
    for /f "usebackq" %%a in (
        `PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(\"%1OfflineAdministratorPassword\"))"`
    ) do if "%~2"=="" (echo %%a) else set %~2=%%a
    exit /b 0

::: "Uncompress package" "" "usage: %~n0 un [target_path]"
:::: "Format not supported" "Target not found" "System version is too old" "chm file not found" "not chm file" "out put file allready exist" "file format not msi" "cabarc.exe file not found"
:dis\un
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
    call :this\oset\--vergeq 10.0 || exit /b 3
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
:dis\pkg
    if "%*"=="" call :this\annotation %0 & goto :eof
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

REM for :init\?
:this\getCab [file_name] [uri_sub] [cab] [file]
    call :dis\download http://download.microsoft.com/download/%~2/Installers/%~3.cab %temp%\%~1.cab
    expand.exe %temp%\%~1.cab -f:%~4 %temp%
    erase %temp%\%~1.cab
    move %temp%\%~4 %~dp0%~1.exe
    exit /b 0

::: "Change file/directory owner !username!" "" "usage: %~n0 own [path]"
:::: "path not found"
:dis\own
    if not exist "%~1" exit /b 1
    call :this\dir\--isdir %1 && takeown.exe /f %1 /r /d y && icacls.exe %1 /grant:r %username%:f /t /q
    call :this\dir\--isdir %1 || takeown.exe /f %1 && icacls.exe %1 /grant:r %username%:f /q
    exit /b 0

::::::::::::::::
:: PowerShell ::
::::::::::::::::

::: "Download something" "" "usage: %~n0 download [url] [output]"
:::: "url is empty" "output path is empty" "powershell version is too old"
:dis\download
    if "%~1"=="" exit /b 1
    REM if "%~2"=="" exit /b 2
    call :this\gpsv
    if errorlevel 3 PowerShell.exe -NoLogo -NonInteractive -ExecutionPolicy Unrestricted -Command "Invoke-WebRequest -uri %1 -OutFile %2 -UseBasicParsing" & exit /b 0
    call :lib\vbs get %1 %2
    exit /b 0

::: "Copy Window PE boot file from CDROM" "" "usage: %~n0 boof [target_letter]"
:::: "target_letter not exist" "Window PE CDROM not found"
:dis\boof
    if not exist "%~d1" exit /b 1
    for /l %%a in (0,1,9) do if exist \\?\CDROM%%a\boot\boot.sdi (
        for %%b in (
            \bootmgr
            \boot\bcd
            \boot\boot.sdi
            \efi\boot\bootx64.efi
            \efi\microsoft\boot\bcd
            \sources\boot.wim
        ) do (
            if not exist %~d1%%~pb mkdir %~d1%%~pb
            copy /y \\?\CDROM%%a%%b %~d1%%b
        )
        mkdir %~d1\support %~d1\sources\sxs
        copy /y \\?\CDROM%%a\sources\sxs\* %~d1\sources\sxs
        exit /b 0
    )
    exit /b 2

::: "Add or Remove Web Credential" "" "usage: %~n0 crede [option] [args...]" "" "    --add,    -a [user]@[ip or host] [[password]]" "    --remove, -r [ip or host]"
:::: "invalid option" "parameter not enough" "Command error" "ho ip or host"
:dis\crede
    if "%*"=="" call :this\annotation %0 & goto :eof
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
:dis\smb
    if "%*"=="" call :this\annotation %0 & goto :eof
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
:dis\nfs
    if "%*"=="" call :this\annotation %0 & goto :eof
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
    call :dis\ocsetup ServicesForNFS-ClientOnly; ClientForNFS-Infrastructure; NFS-Administration
    REM start /w Ocsetup.exe ServicesForNFS-ClientOnly;ClientForNFS-Infrastructure;NFS-Administration /norestart
    exit /b 0

::: "Lock / Unlock partition with BitLocker" "" "usage: %~n0 block [option] [args...]" "" "    --lock,   -l   [[passwd]]" "    --unlock, -u   [[passwd]]"
:::: "invalid option" "Partition not found"
:dis\block
    if "%*"=="" call :this\annotation %0 & goto :eof
    if not exist "%~1" exit /b 2
    call :this\bit\%*
    goto :eof

:this\bit\--lock
:this\bit\-l
    manage-bde.exe -on %~d1 -UsedSpaceOnly -Password %~2
    exit /b 0

:this\bit\--unlock
:this\bit\--u
    manage-bde.exe -on %~d1 -UsedSpaceOnly -RecoveryPassword %~2
    exit /b 0

:::::::::
:: vhd ::
:::::::::

::: "Virtual Hard Disk manager" "" "usage: %~n0 vhd [option] [args...]" "" "    --new,    -n  [new_vhd_path] [size[GB]] [[mount letter or path]]    Creates a virtual disk file." "    --mount,  -m  [vhd_path] [[letter]]                Mount vhd file" "    --umount, -u  [vhd_path]                           Unmount vhd file" "    --expand, -e  [vhd_path] [GB_size]                 Expands the maximum size available on a virtual disk." "    --differ, -d  [new_vhd_path] [source_vhd_path]     Create differencing vhd file by an existing virtual disk file" "    --merge,  -me  [chile_vhd_path] [[merge_depth]]    Merges a child disk with its parents" "    --rec,    -r                                       Recovery child vhd if have parent" "e.g." "    %~n0 vhd -n E:\nano.vhdx 30 V:"
:::: "invalid option" "file suffix not vhd/vhdx" "file not found" "no volume find" "vhd size is empty" "letter already use" "diskpart error:" "not a letter or path" "{UNUSE}" "size not num" "parent vhd not found" "new file allready exist"
:dis\vhd
    if "%*"=="" call :this\annotation %0 & goto :eof
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
    set /a _size=%2 * 1024 + 8
    >%tmp%\.diskpart (
        setlocal enabledelayedexpansion
        echo create vdisk file="%~f1" maximum=%_size% type=expandable
        endlocal
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
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--mount
:this\vhd\-m
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    if "%~2" neq "" (
        if /i "%~d2"=="%~2" if exist "%~2" exit /b 6
        if /i "%~d2" neq "%~2" if not exist "%~2" exit /b 8
    )
    >%tmp%\.diskpart (
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
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--umount
:this\vhd\-u
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    REM unmount vhd
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo detach vdisk
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--expand
:this\vhd\-e
    if not exist "%~1" exit /b 3
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    call :this\inum %~2 || exit /b 10
    REM unmount vhd
    call :dis\vumount %1 > nul
    setlocal
    set /a _size=%~2*1024+8
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo expand vdisk maximum=%_size%
    )
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    endlocal
    exit /b 0

:this\vhd\--differ
:this\vhd\-d
    if not exist "%~2" exit /b 11
    if exist "%~1" exit /b 12
    if /i ".vhd" neq "%~x1" if /i ".vhdx" neq "%~x1" exit /b 2
    >%tmp%\.diskpart echo create vdisk file="%~f1" parent="%~f2"
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:this\vhd\--merge
:this\vhd\-me
    if not exist "%~1" exit /b 3
    if /i "%~x1" neq ".vhd" if /i "%~x1" neq ".vhdx" exit /b 2
    setlocal
    set _depth=1
    if "%~2" neq "" set _depth=%~2
    >%tmp%\.diskpart (
        echo select vdisk file="%~f1"
        echo merge vdisk depth=%_depth%
    )
    endlocal
    diskpart.exe /s %tmp%\.diskpart || exit /b 7
    exit /b 0

:::
:this\vhd\--rec
:this\vhd\-r
    setlocal
    set /p _i=[Warning] Child vhd will be recovery, Yes^|No:
    if /i "%_i%" neq "y" if /i "%_i%" neq "yes" exit /b 0
    endlocal

    chcp.com 437 >nul

    REM Make vdisk info script
    >%tmp%\.diskpart type nul
    for /f "usebackq skip=1" %%a in (
        `wmic.exe logicaldisk where DriveType^=3 get name`
    ) do if exist %%a\*.vhd? for /f "usebackq delims=" %%b in (
        `dir /a /b %%a\*.vhd?`
    ) do >>%tmp%\.diskpart (
        echo select vdisk file="%%a\%%b"
        echo detail vdisk
    )

    REM Make create child vhd script
    for /f "usebackq tokens=1,2*" %%a in (
        `diskpart.exe /s %tmp%\.diskpart ^& ^>%tmp%\.diskpart type nul`
    ) do >>%tmp%\.diskpart (
        if "%%a"=="Filename:" set /p=create vdisk file="%%b"<nul
        if "%%a%%b"=="ParentFilename:" echo. parent="%%c"
    )

    move /y %tmp%\.diskpart %tmp%\.tmp

    REM Filter parent vhd, and delete child vhd
    for /f "usebackq delims=" %%a in (
        "%tmp%\.tmp"
    ) do for /f usebackq^ tokens^=2^,4^ delims^=^" %%b in (
        '%%a'
    ) do if "%%c"=="" (
        REM "
        move "%%b" "%%b.snapshot"
        >>%tmp%\.diskpart echo create vdisk file="%%b" parent="%%b.snapshot"
    ) else (
        erase /a /q %%b
        >>%tmp%\.diskpart echo %%a
    )

    REM Create new child vhd
    diskpart.exe /s %tmp%\.diskpart

    exit /b 0

::::::::::
:: dism ::
::::::::::

::: "Wim manager" "" "usage: %~n0 wim [option] [args ...]" "" "    --info,   -i [image_path]                                Displays information about images in a WIM file." "    --new,    -n [[compress level]] [target_dir_path] [[image_name]]            Capture file/directory to wim" "    --apply,  -a [wim_path] [[output_path] [image_index]]    Apply WIM file" "    --mount,  -m [wim_path] [mount_path] [[image_index]]     Mount wim" "    --umount, -u [mount_path]                                Unmount wim" "    --commit, -c [mount_path]                                Unmount wim with commit" "    --export, -e [source_wim_path] [target_wim_path] [image_index] [[compress_level]]    Export wim image" "                                   compress level: 0:none, 1:WIMBoot, 2:fast, 3:max, 4:recovery(esd)" "" "    --umountall, -ua                                         Unmount all wim" "    --rmountall, -ra                                         Recovers mount all orphaned wim"
:::: "invalid option" "recovery only support by --export option" "dism version is too old" "target not found" "need input image name" "dism error" "wim file not found" "not wim file" "output path allready use" "output path not found" "Not a path" "Target wim index not select" "compress level error"
:dis\wim
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\wim\%*
    goto :eof

:this\wim\--new
:this\wim\-n
    call :this\oset\--vergeq 6.3 || exit /b 3

    setlocal
    call :this\inum %~1 && call :wim\setCompress %~1 && shift

    if not exist "%~1" exit /b 4
    if "%~d1\"=="%~f1" if "%~2"=="" exit /b 5
    if /i "%_compress%"=="/Compress:recovery" exit /b 2

    set "_input=%~f1"
    REM trim path
    if "%_input:~-1%"=="\" set "_input=%_input:~0,-1%"

    REM wim name
    if "%~2" neq "" (
        set _name=%~2
    ) else for %%a in ("%_input%") do set "_name=%%~nxa"

    REM New or Append
    if exist ".\%_name%.wim" (set _create=Append) else set _create=Capture

    REM Create exclusion list
    call :this\str\--now _conf "%tmp%\" .log
    set _args=
    call :wim\ConfigFile "%_input%" > %_conf% && set _args=/ConfigFile:"%_conf%"

    REM input args
    for %%a in ("%_input%") do set "_input=%%~dpa"
    set "_input=%_input:~0,-1%"

    REM Do capture
    dism.exe /English /%_create%-Image /ImageFile:".\%_name%.wim" /CaptureDir:"%_input%" /Name:"%_name%" %_compress% /Verify %_args% || exit /b 6
    if exist "%_conf%" erase "%_conf%"
    endlocal
    exit /b 0

REM create exclusion list
:wim\ConfigFile
    if not exist "%~1" exit /b 1
    if "%~pnx1"=="\" exit /b 2
    echo [ExclusionList]
    for /f "usebackq delims=" %%a in (
        `dir /a /b "%~dp1"`
    ) do if "%%a" neq "%~nx1" echo \%%a
    exit /b 0

:this\wim\--apply
:this\wim\-a
    call :this\oset\--vergeq 6.3 || exit /b 3
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
    dism.exe /English /Apply-Image /ImageFile:"%~f1" /Index:%_index% /ApplyDir:"%_out%" /Verify || exit /b 6
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
    dism.exe /Mount-Wim /WimFile:"%~f1" /index:%_index% /MountDir:"%~f2" || exit /b 6
    endlocal
    exit /b 0

:this\wim\--umount
:this\wim\-u
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /discard
    exit /b 0

:this\wim\--commit
:this\wim\-c
    call :this\dir\--isdir %1 || exit /b 4
    dism.exe /Unmount-Wim /MountDir:"%~f1" /commit
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

    dism.exe /Export-Image /SourceImageFile:"%~f1" /SourceIndex:%3 /DestinationImageFile:"%~f2" %_compress% /CheckIntegrity
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
        if "%%~a%%~d"=="StatusRemount" if defined _m dism.exe /Remount-Wim /MountDir:"!_m!"
    )
    endlocal
    echo.complate.
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
:::: "invalid option" "OS path not found" "Not drivers name" "dism error" "drivers info file not found" "drivers path error"
:dis\drv
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\drv\%*
    goto :eof

REM Will install at \Windows\System32\DriverStore\FileRepository
:this\drv\-a
:this\drv\--add
    for %%a in (%*) do call :this\dir\--isdir %1 && (
        dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a /Recurse || REM
    ) || if /i "%%~xa"==".inf" dism.exe /Image:"%~f1" /Add-Driver /Driver:%%a || exit /b 4
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
    dism.exe /Image:"%~f1" /Remove-Driver /Driver:%~2 || exit /b 4
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
        `set _$ 2^>nul`
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
        call :this\vbs inftrim "%%~a" %_out%\!i!.tmp
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

::: "KMS Client" "" "usage: %~n0 kms [option] [args...]" "" "    --os     [[ipv4]]    Active OS" "    --office [[ipv4]]    Active office" "    e.g." "        %~n0 kms --os 192.168.1.1"
:::: "invalid option" "{UNUSE}" "Need ip or host" "OS not support" "No office found" "office not support"
:dis\kms
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\kms\%*
    goto :eof

REM OS
:this\kms\--os
    setlocal
    if "%~1"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~p0'
        ) do set _ip=%%a
    ) else set _ip=%1

    REM Get this OS version
    call :this\oset\--info %SystemDrive% _sd

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
    ) do if /i "%_sd.ver%_%_eid%"=="%%b" set _key=%%c

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
        "/skms %_ip%"
        /ato ::?"active"
        /xpr ::?"display expires time"
        /ckms ::?"rm key"
    ) do cscript.exe //nologo //e:vbscript %windir%\System32\slmgr.vbs %%~a

    endlocal
    exit /b 0

REM Office
:this\kms\--office
    setlocal
    if "%~1"=="" (
        if "%~d0" neq "\\" exit /b 3
        for /f "usebackq delims=\" %%a in (
            '%~p0'
        ) do set _ip=%%a
    ) else set _ip=%1

    REM Search kms key
    set _key=
    call :getOfficePath _office || exit /b 5
    if "%_office:~-1%"=="\" set _office=%_office:~0,-1%
    for %%a in (
        "%_office%"
    ) do for %%b in (
        Office15@YC7DK-G2NP3-2QQC3-J6H88-GVGXT
        Office15Visio@C2FG9-N6J68-H8BTJ-BW3QX-RM3B3
    ) do for /f "usebackq tokens=1,2 delims=@" %%c in (
        '%%b'
    ) do if /i "%%~na"=="%%c" set _key=%%d

    REM If not find key
    if not defined _key exit /b 6

    REM Active
    for %%a in (
        "/inpkey:%_key%"
        "/sethst:%_ip%"
        /act ::?"active"
        /dstatus ::?"display expires time"
        /remhst ::?"rm key"
    ) do cscript.exe //nologo //e:vbscript "%_office%\ospp.vbs" %%~a
    endlocal
    exit /b 0

REM for :dis\officekms
:getOfficePath
    if "%~1"=="" exit /b 1
    for /f "usebackq delims=" %%a in (
        `reg.exe query HKLM\Software\Microsoft\Office /f InstallRoot /s`
    ) do if "%%~na"=="InstallRoot" for /f "usebackq tokens=2*" %%b in (
        `reg.exe query "%%a" /v Path 2^>nul`
    ) do if exist "%%c\ospp.vbs" (
        set %~1=%%c
        exit /b 0
    )
    exit /b 1


:::::::::::
:: other ::
:::::::::::

::: "Support load %USERPROFILE%\.batchrc before cmd.exe run" "" "usage: %~n0 batrc [[-d]]"
:::: "{UNUSE}"
:dis\batrc
    call :this\batrc\%*
    goto :eof

:this\batrc\
    setlocal
    REM from lib.cmd
    for /f %%a in ('"prompt $h & for %%a in (.) do REM"') do set _bs=%%a
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

::: "Edit the Registry" "" "usage: %~n0 reg [option]" "" "    --intel-amd, -ia                         Run this before Chang CPU" "    --copy,      -p    [key] [file_path]     Copy reg to a reg file"
:::: "invalid option" "OS version is too low" "Not windows directory" "Reg key not exist" "Reg file not exist or Not reg format"
:dis\reg
    if "%*"=="" call :this\annotation %0 & goto :eof
    call :this\reg\%*
    goto :eof

:this\reg\--intel-amd
:this\reg\-ia
    call :this\oset\--vergeq 6.0 || exit /b 2

    if "%~1"=="" (
        setlocal
        set /p _i=[Warning] Reg vhd will be change, Yes^|No:
        if /i "%_i%" neq "y" if /i "%_i%" neq "yes" exit /b 0
        endlocal
        call :this\reg\delInteltag system
        exit /b 0
    )

    if not exist "%~f1"\Windows\System32\config\SYSTEM exit /b 3
    reg.exe load HKLM\tmp "%~f1"\Windows\System32\config\SYSTEM
    call :this\reg\delInteltag tmp
    reg.exe unload HKLM\tmp
    exit /b 0

REM for :this\reg\--intel-amd
:this\reg\delInteltag
    for /f "tokens=1,4 delims=x	 " %%a in (
		'reg.exe query HKLM\%1\Select'
	) do if /i "%%a"=="Default" reg.exe delete HKLM\%1\ControlSet00%%b\Services\intelppm /f 2>nul
    exit /b 0

:this\reg\--copy
:this\reg\-p
    reg.exe query %1 >nul 2>nul || exit /b 4
    reg.exe load HKLM\tmp %2 || exit /b 5
    setlocal
    if not defined _reg\ve for /f %%a in (
        'reg.exe query HKLM /ve'
    ) do set "_reg\ve=%%a"

    for /f "usebackq delims=" %%a in (
        `reg.exe query %1 /s`
    ) do for /f "tokens=1,2* delims=\" %%b in (
        "%%a"
    ) do if "%%b" neq "HKEY_LOCAL_MACHINE" (
        set "_tmp=%%a"
        rem set "_tmp=!_tmp:$Windows.~bt\=!"
        rem set "_tmp=!_tmp:\=\\!"
        rem set "_tmp=!_tmp:"=\"!"
        for /f "tokens=1,2* delims=`" %%e in (
            "!_tmp:    =`!"
        ) do if "%%e"=="%_reg\ve%" (
            reg.exe add "HKLM\tmp\!_temp!" /ve /t %%f /d "%%g" /f
        ) else reg.exe add "HKLM\tmp\!_temp!" /v "%%e" /t %%f /d "%%g" /f
    ) else set "_temp=%%d"
    endlocal
    reg.exe unload HKLM\tmp
    exit /b 0

REM REM from Window 10 aik, will download imagex.exe at script path
REM :init\imagex
REM     for %%a in (_%0) do if %processor_architecture:~-2%==64 (
REM         REM amd64
REM         call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk d2611745022d67cf9a7703eb131ca487 fil4927034346f01b02536bd958141846b2

REM     REM x86
REM     ) else call :this\getCab %%~na 0/A/A/0AA382BA-48B4-40F6-8DD0-BEBB48B6AC18/adk eacac0698d5fa03569c86b25f90113b5 fil6e1d5042624c9d5001511df2bfe4c40b
REM     exit /b 0

::::::::::::::::::
::     Base     ::
  :: :: :: :: ::

REM Test string if Num \* @see lib.cmd *\
:this\inum
    if "%~1"=="" exit /b 10
    setlocal
    set _tmp=
    REM quick return
    2>nul set /a _code=10, _tmp=%~1
    if "%~1"=="%_tmp%" set _code=0
    endlocal & exit /b %_code%

REM Test string if ip \* @see lib.cmd *\
:this\ip\--test
    if "%~1"=="" exit /b 1
    REM [WARN] use usebackq will set all variable global, by :lib\hosts
    for /f "tokens=1-4 delims=." %%a in (
        "%~1"
    ) do (
        if "%~1" neq "%%a.%%b.%%c.%%d" exit /b 10
        for %%e in (
            "%%a" "%%b" "%%c" "%%d"
        ) do (
            call :this\inum %%~e || exit /b 10
            if %%~e lss 0 exit /b 10
            if %%~e gtr 255 exit /b 10
        )
    )
    exit /b 0

REM Test target in $path \* @see lib.cmd *\
:this\path\--contain
    if "%~1" neq "" if "%~$path:1" neq "" exit /b 0
    exit /b 1

REM Display Time at [YYYYMMDDhhmmss] \* @see lib.cmd *\
REM en zh
:this\str\--now
    if "%~1"=="" exit /b 1
    set date=
    set time=
    for /f "tokens=1-8 delims=-/:." %%a in (
      "%time: =%.%date: =.%"
    ) do if %%e gtr 1970 (
        set %~1=%~2%%e%%f%%g%%a%%b%%c%~3
    ) else if %%g gtr 1970 set %~1=%~2%%g%%e%%f%%a%%b%%c%~3
    exit /b 0

REM Run VBScript library from lib.vbs \* @see lib.cmd *\
:this\vbs
    REM cscript.exe //nologo //e:vbscript.encode %*
    for %%a in (lib.vbs) do if "%%~$path:a"=="" (
        exit /b 1
    ) else cscript.exe //nologo "%%~$path:a" %* 2>&3 || exit /b 10
    goto :eof

  :: :: :: :: ::
::     Base     ::
::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::
::                 Framework                 ::
   :: :: :: :: :: :: :: :: :: :: :: :: :: ::

REM Show INFO or ERROR
:this\annotation
    setlocal enabledelayedexpansion & call :this\var\--errlv %errorlevel%
    for /f "usebackq skip=62 tokens=1,2* delims=\ " %%a in (
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
    call :this\cols _col
    set /a _i=0, _col/=16
    for /f usebackq^ tokens^=1^,2^ delims^=^=^" %%a in (
        `set _args\%~n1 2^>nul`
    ) do if "%~1" neq "" (
        REM " Sort func name expansion
        set /a _i+=1
        set _target=%%~nxa %2 %3 %4 %5 %6 %7 %8 %9
        if !_i!==1 set _tmp=%%~nxa
        if !_i!==2 call :this\lals !_tmp! %_col%
        if !_i! geq 2 call :this\lals %%~nxa %_col%
    ) else call :this\lali %%~nxa "%%~b"
    REM Close lals
    if !_i! gtr 0 call :this\lals 0 0
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

REM Make the second column left-aligned \* @see lib.cmd *\
:this\lali
    if "%~2"=="" exit /b 1
    setlocal enabledelayedexpansion
    set _str=%~10123456789abcdef
    if "%_str:~31,1%" neq "" call :strModulo
    set /a _len=0x%_str:~15,1%
    set "_spaces=                "
    echo %~1!_spaces:~0,%_len%!%~2
    endlocal
    exit /b 0

REM Use right pads spaces, make all column left-aligned \* @see lib.cmd *\
:this\lals
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

REM Get cmd cols \* @see lib.cmd *\
:this\cols
    for /f "usebackq skip=4 tokens=2" %%a in (`mode.com con`) do (
        if "%~1"=="" (
            echo %%a
        ) else set %~1=%%a
        exit /b 0
    )
    exit /b 0

REM Set errorlevel variable \* @see lib.cmd *\
:this\var\--errlv
    if "%~1"=="" goto :eof
    exit /b %1

   :: :: :: :: :: :: :: :: :: :: :: :: :: ::
::                 Framework                 ::
:::::::::::::::::::::::::::::::::::::::::::::::
