# External Command
command-line wrapper for batch and shell

---------
# Licensing
extcmd is licensed under the Apache License, Version 2.0. See
[LICENSE](https://github.com/binave/extcmd/blob/master/LICENSE) for the full
license text.

---------
# New!
clipTransfer.vbs

        Copy file or folder between two Windows OS by clipboard
        通过剪贴板，在两个 windows 之间复制小文件。将目标文件或文件夹拖动到脚本上，提示完成后，在远程桌面上双击远端的脚本即可。


lib gpkg

        Get apk file from AppStore
        截获 AppStore 的原版安装包。完成后会放到 Download 文件夹中。
        对于小文件下载非常有效。
        支持批量监听。
        可以设置监听时间，默认监听 60 秒。
        在监听时间内，新建下载和正在下载的 app 都会被纳入监控。
        当监听结束后，脚本不会退出，会持续跟踪文件的下载状态，直到所有 app 都下载完成。
        你可以随时使用 control + C 退出此命令。新启动的 gpkg 命令会处理上次遗留的 app。
        （未来会加入下载失败的提示）

lib ip --find, -f

        Search IPv4 by MAC or Host name
        通过 MAC 地址或别名搜索 IP 。（仅搜索本网段最后 255 个）
        （别名请参考 ini 文本文件格式，放入脚本所在路径或 HOME 路径下）

lib hosts

        (win mac)
        Update hosts by ini
        通过 ini 配置文件，自动更新 hosts。

.lib _map _set

        map for shell
        基于 hash 算法实现的 map 。
        与基于 map 实现的 set。
        用于 shell 脚本内部调用，可以简化逻辑设计。

--------
Framework:
框架：

    If the function names conform to the specifications:
        External call function. (cmd will support short name completion)
        Error handling.
        Display help information.
        Print the functions list.

    对符合规范的函数提供：（包括 sh、cmd、vbs）
        外部调用 (cmd 格式的脚本支持通过短名称访问，类似自动补齐)。
        错误处理。
        输出帮助信息。
        输出函数列表。
        (lib 3rd 名称的脚本均支持以上特性。)

    e.g.
        ::: "[brief_introduction]" "" "[description_1]" "[description_2]" ...
        :::: "[error_description_1]" "[error_description_2]" ...
        :[script_name_without_suffix]\[function_name]
            ...
            [function_body]
            ...
            REM exit and display [error_description_1]
            exit /b 1
            ...
            REM return false status
            exit /b 10


--------

lib.cmd

        1.  Some cmd function.
            一些批处理函数，放到环境变量中即可直接使用。

        2.  Support for /f command.
            支持在 for /f 中使用，进行判断操作时需要使用 call 命令。

        3.  Support sort function name.
            函数支持简名，会从左逐个字符进行命令匹配，直到匹配唯一的命令。
                如 call lib addpath ， a 是全局唯一，可用 call lib a 来代替。
                注意：简化命令会增加执行时间，请在其他脚本中调用时使用全名。

        4.  HELP: lib -h or lib [func] -h
            有关函数用法，使用 lib.cmd -h 或 lib.cmd ［函数名］-h。

dis.cmd

        集中了一些对磁盘和 wim 的操作。
        可以放到 samba 路径中直接执行。
        e.g.
            \\192.168.1.2\shared\dis.cmd --help


lib.vbs

        使用 lib.cmd vbs 命令进行调用。


lib     (shell script)

        注意权限是否为可执行。
