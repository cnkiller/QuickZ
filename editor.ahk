﻿#Persistent
#SingleInstance, force
SetBatchLines, -1

QZM.Listen(A_ScriptDir "\ui", 5210)
; Gui Add, ActiveX, x0 y0 w980 h640 vWB, Shell.Explorer  ; The final parameter is the name of the ActiveX component.
; Gui Show, w980 h640, QuickZ 配置
; WB.Navigate("http://127.0.0.1:5210/")  ; This is specific to the web browser control.

return

Class QZM {

    static _instance := new QZM.instance()

    class instance {
        __new() {
            this.rootdir := dir
            this.config := A_ScriptDir "\user\config.json"
            this.port := 0
            this.paths := {}
            this.routes := {}
            this.server := {}
        }
    }

    Listen(dir, port:=8000) {
        QZM._instance.rootdir := dir
        QZM._instance.port := port 
        QZM._instance.server := new HttpServer()
        QZM._instance.server.LoadMimes(A_ScriptDir . "/lib/mime.types")
        QZM._instance.server.serve(port)
        ; 设置路由
        QZM._instance.routes.push({path: "/api", func: objBindMethod(QZM, "API")})
        QZM._instance.routes.push({path: "/", func: objBindMethod(QZM, "File")})
        QZM._instance.server.SetRoutes(QZM._instance.routes)
    }

    File(ByRef req, ByRef res, ByRef server) {
        file := QZM._instance.rootdir ( req.path == "/" ? "/index.html" : StrReplace(req.path, "/", "\") )
        if (FileExist(file)) {
            server.ServeFile(res, file)
            res.status := 200
        }
        else {
            res.SetBodyText("not found")
            res.status := 404
        }
    }

    /*
        /api/start
        /api/stop
        /api/config
        /api/geticon
        /api/FileSelectFile
        /api/FileSelectFolder
    */

    API(ByRef req, ByRef res, ByRef server) {
        if (req.path == "/api/config") {
            QZM.Config(req, res, server)
        }
        else if (req.path == "/api/fileselectfile") {
            QZM.FileSelectFile(req, res, server)
        }
        else if (req.path == "/api/fileselectfolder") {
            QZM.FileSelectFolder(req, res, server)
        }
        else if (req.path == "/api/generateicon") {
            QZM.GenerateIcon(req, res, server)
        }
        else {
            res.NotFound()
        }
    }

    FileSelectFile(byRef req, byRef res, byRef server) {
        res.SetBodyText("waiting")
        FileSelectFile, filepath, , % A_ScriptDir, 选择文件
        res.SetBodyText(filePath)
        res.status := 200
    }

    FileSelectFolder(byRef req, byRef res, byRef server) {
        res.SetBodyText("waiting")
        FileSelectFolder, folderPath, , , 选择目录
        res.SetBodyText(folderPath)
        res.status := 200
    }

    GenerateIcon(byRef req, byRef res, byRef server) {
        res.SetBodyText("")
        if (req.method == "GET") {
            filepath := req.queries["filepath"]
            IconNumber := req.queries["number"] is integer ? req.queries["number"] : 0
            if (FileExist(filepath)) {
                SplitPath, filePath, filename, , ext
                iconByResources:= A_ScriptDir "\ui\ico\" md5(filepath "|" iconNumber) ".png"
                iconByFileType := A_ScriptDir "\ui\ico\" ext ".png"
                if (InStr(",exe,ico,dll,icl,", "," ext ",")) {
                    iconFile := iconByResources
                    if (not FileExist(iconByResources)) {
                        gdip_tokent := Gdip_StartUp()
                        pbitmap := Gdip_createBitmapFromFile(filePath, iconNumber)
                        Gdip_SaveBitmapToFile(pBitmap, iconFile, 100)
                        Gdip_ShutDown(gdip_tokent)
                    }
                }
                else {
                    iconFile := iconByFileType
                    if (not FileExist(iconByFileType)) {
                        gdip_tokent := Gdip_StartUp()
                        SHGFI_TYPENAME = 0x000000400
                        SHGFI_DISPLAYNAME = 0x000000200
                        SHGFI_ICON = 0x000000100
                        SHGFI_ATTRIBUTES = 0x000000800
                        MAX_PATH := 260
                        SHFILEINFO := "
                        (
                        INT_PTR hIcon;
                        DWORD   iIcon;
                        DWORD   dwAttributes;
                        WCHAR   szDisplayName[" MAX_PATH "];
                        WCHAR   szTypeName[80];
                        )"
                        SHFO := Struct(SHFILEINFO)
                        DllCall("Shell32\SHGetFileInfo" . (A_IsUnicode ? "W":"A"), "str", FilePath, "uint", 0, "ptr", SHFO[""], "uint", sizeof(SHFILEINFO), "uint", SHGFI_TYPENAME|SHGFI_DISPLAYNAME|SHGFI_ICON|SHGFI_ATTRIBUTES)
                        pBitmap := Gdip_createBitmapFromHICON(SHFO.hIcon)
                        Gdip_SaveBitmapToFile(pBitmap, iconFile, 100)
                        Gdip_ShutDown(gdip_tokent)
                    }
                }
                server.ServeFile(res, iconFile)
            }
            else {
                res.status := 404
            }
        }
        res.status := 200
    }

    Config(byRef req, byRef res, byRef server) {
        if (req.method == "GET") {
            if (not FileExist(QZM._instance.config)) {
                body := json.dump({})
                FileAppend, % body , % QZM._instance.config
            }
            else {
                FileRead, body, % QZM._instance.config
            }
            res.SetBodyText(body)
            res.status := 200
        }
        else if (req.method == "POST") {
            FileDelete, % QZM._instance.config
            FileAppend, % req.body , % QZM._instance.config
            res.status := 200
        }
    }

}

!z::reload

#include, lib\AHKhttp.ahk
#include, lib\AHKsock.ahk
#include, lib\Path_API.ahk
#include, lib\class_json.ahk
