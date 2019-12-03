﻿#NoEnv 
#SingleInstance, Force
SetBatchLines, -1
SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
SetKeyDelay, -1
SetControlDelay,-1


quickz.LoadPlugins()
quickz.InitPlugins()

vimd.setWin("et", { winClass: "EVERYTHING"
                                ,winExe: "everything.exe"
                                ,onBeforeKey: "et_BeforeKey"
                                ,maxCount: 999
                                ,timeOut: 500})
vimd.mapNum("et", "normal")
vimd.map("et", "normal", "j", "down")
vimd.map("et", "normal", "k", "up")
vimd.map("et", "normal", "r", "everything_rename")
vimd.map("et", "normal", "w", objBindMethod(menuz, "Active"))
vimd.map("et", "normal", "v1", "et_filter", "所有")
vimd.map("et", "normal", "v2", "et_filter", "音频")
vimd.map("et", "normal", "v3", "et_filter", "压缩文件")
vimd.map("et", "normal", "v4", "et_filter", "文档")
vimd.map("et", "normal", "v5", "et_filter", "可执行文件")
vimd.map("et", "normal", "v6", "et_filter", "文件夹")
vimd.map("et", "normal", "v7", "et_filter", "图片")
vimd.map("et", "normal", "v8", "et_filter", "视频")
vimd.map("et", "normal", ".", objBindMethod(vimd, "repeat"), "重复操作")
vimd.map("et", "normal", "q", objBindMethod(vimd, "record"), "录制宏")
vimd.map("et", "normal", "p", objBindMethod(vimd, "recordplay"), "播放宏")
vimd.map("et", "insert", "<esc>", "np_change_to_normal")
vimd.changeMode("et", "normal")
vimd.setWin("winword", {winExe: "winword.exe"
                                ,maxCount: 999
                                ,timeOut: 500})
vimd.mapNum("winword", "normal")
vimd.map("winword", "normal", "j", "down")
vimd.map("winword", "normal", "k", "up")
vimd.map("winword", "normal", "h", "left")
vimd.map("winword", "normal", "l", "right")
vimd.map("winword", "normal", "u", "winword_undo")
vimd.map("winword", "normal", "i", "winword_change_to_insert")
vimd.map("winword", "normal", "I", "winword_change_to_insert_LineHeader")
vimd.map("winword", "normal", "A", "winword_change_to_insert_LineEnd")
vimd.map("winword", "insert", "<esc>", "winword_change_to_normal")
vimd.changeMode("winword", "normal")

menuz.config({cliptimeout: 400
    ,onGetWin: ""
    ,onGetClip: "myGetClip"})
menuz.SetFilter("tt", "texttype")
menuz.setexec("sendtext", "sendtext")
menuz.setexec("copynamenoext", "copynamenoext")
menuz.settag("test", "tagtest")
menuz.settag("box", "tagbox")
menuz.setdynamic("firstmenu", objBindMethod(menuz, "firstmenu"))
return


et_filter(win) {
    Control, Choose, % win.keyLast, ComboBox1, A
}

et_BeforeKey() {
    WinGet, MenuID, ID, AHK_CLASS #32768
    if (MenuID) {
        vimd.SendRaw("et")
    }
    ControlGetFocus, focusCtrl, A
    if (focusCtrl == "Edit1") {
        vimd.SendRaw("et")
    }
}

tagtest(env, tag) {
    msgbox % tag ; {test: some}
    msgbox % env.file.name
}

tagbox(env, tag)  {
    if (InStr(tag, "folder")) {
        FileSelectFolder, folderPath, , , 选择文件夹
        return folderPath
    }
}

sendtext(env, item) {
    WinActivate, % "ahk_id " env.winHwnd
    SendRaw % menuz.ReplaceTag(item.param)
}

copynamenoext(env, item) {
    clipboard := env.file.namenoext
}


myGetClip(env, event) {
    if (event == "GetClip") {
        if (env.winExe == "gvim.exe") {
            clipBackup := ClipboardAll
            Clipboard := ""
            SendRaw "+y
            ClipWait, % env.config.ClipTimeOut, 1
            env.isWin := ErrorLevel
            clipData := Clipboard
            env.isGetClip := true
            env.isText := true
            env.text := clipData
        }
    }
}
filtertest(env, filter) {
    msgbox filter> %filter%
    return true
}
exectest(env, item) {
    msgbox exec
}


TextType(env, filter) {
    textTypeName := ""
    textRegexList := {url: "(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"}
    for textType, TypeRegex in textRegexList
    {
        if (RegExMatch(env.text, TypeRegex)) {
            textTypeName := textType
            break
        }
    }
    return env.TestRule(filter, textTypeName)
}

; myMenu :=   [{name: "<firstmenu>"}
;         ,{name: "Chrome打开URL"
;             ,icon: "%chrome%:0"
;             ,exec: "%chrome%"
;             ,param: """{text}"""
;             ,filter: "{tt:=url}"}
;         ,{name: ""
;             ,filter: "{tt:=url"}
;         ,{name: "运行CMD"
;             ,icon: "C:\windows\system32\cmd.exe:0"
;             ,filter: "{pos:x>800 y>600}"}
;         ,{name: "gvim>>"
;             ,icon: "%gvim%:0"
;             ,tcolor: 0xffff
;             ,bgcolor: "%black%"
;             ,exec: "%gvim%"
;             ,param: """{file:path}"""
;             ,workdir: """{file:dir}"""
;             ,filter: "{ext:=ahk, js, py}, {only:file}"}
;         ,{name: "quickz-ui"
;             ,icon: "%vscode%:0"
;             ,exec: "%vscode%"
;             ,param: """D:\git\ahk\quickz-ui"""}
;         ,{name: "quickz-design"
;             ,icon: "%vscode%:0"
;             ,exec: "%vscode%"
;             ,param: """D:\git\ahk\quickz-design"""}
;         ,{name: "切换到quickz-design"
;           ,exec: "<sendtext>"
;           ,param: "cd /d D:\git\ahk\quickz-design"
;           ,filter: "{winexe:=cmd.exe}"}
;         ,""
;         ,{name: "编辑配置"
;             ,exec: "%gvim%"
;             ,param: "D:\git\ahk\quickz-design\quickz.ahk"}]
        ;,{ name: "父菜单1"
        ;        ,sub:   [{name: "1"
        ;                        ,sub: [{name: "1.1"}]}
        ;            ,{name: "2"}]}
        ;,{ name: "父菜单2"
        ;        ,sub:   [{name: "2.1"}]}]
; msgbox % json.dump(menuz._instance.menuStructure, 2)
; return
; gui, add, edit, w200 h20 , %tomatch%
; gui, add, edit, w200 h20 ,%equation%
; gui, add, button, default gRegex,正则式
; gui, show

regex:
GuiControlGet, match, , edit1
GuiControlGet, string, , edit2
result := RegExMatch(string, match, m)
msgbox % result "`n" m
return

!x::reload
!q::menuz.Active()

#include lib\class_vimd.ahk
#include lib\class_menuz.ahk
#include lib\class_quickz.ahk
#include lib\class_json.ahk
#include lib\pum.ahk
#include lib\pum_api.ahk
#include lib\struct.ahk
#include lib\sizeof.ahk
#include lib\yaml.ahk
#include lib\Path_API.ahk
#include *i user\include.ahk
#include user\general\general.ahk
#include user\winword\winword.ahk
#include user\everything\everything.ahk