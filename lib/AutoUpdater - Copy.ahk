/************************************************************************
 * @description Auto Updater from Github
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/31
 * @version 1.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

class AutoUpdater {
    App := ""
    LatestVersion := ""
    DownloadUrl := ""
    
    static Call(args*) {
        return super.Call(args*)
    }

    __New(appObject) {
        this.App := appObject
        if !this.App.HasOwnProp("UpdateAuto")
            this.App.UpdateAuto := true
        if !this.App.HasOwnProp("UpdateFrequencyDays")
            this.App.UpdateFrequencyDays := 7
        if !this.App.HasOwnProp("UpdateLastCheck") || this.App.UpdateLastCheck == ""
            this.App.UpdateLastCheck := "1970-01-01"
    }

    CheckOnStartup() {
        if (!this.App.UpdateAuto || !this.App.HasOwnProp("Github") || this.App.Github == "")
            return
            
        lastCheck := StrReplace(this.App.UpdateLastCheck, "-", "") . "000000"
        if (StrLen(lastCheck) < 14 || !IsTime(lastCheck))
            lastCheck := "19700101000000"

        diffDays := DateDiff(A_Now, lastCheck, "Days")
        
        if (diffDays >= this.App.UpdateFrequencyDays) {
            SetTimer(() => this.CheckForUpdates(true), -100)
        }
    }

    CheckForUpdates(silent := false) {
        if (!this.App.HasOwnProp("Github") || this.App.Github == "") {
            if !silent
                MsgBox("No GitHub repository specified for this app.", "Update Error", "48")
            return false
        }

        if !RegExMatch(this.App.Github, "github\.com/([^/]+)/([^/]+)", &m) {
            if !silent
                MsgBox("Invalid GitHub URL format.", "Update Error", "48")
            return false
        }
        
        apiUrl := "https://api.github.com/repos/" . m[1] . "/" . m[2] . "/releases/latest"

        try {
            whr := ComObject("WinHttp.WinHttpRequest.5.1")
            whr.Open("GET", apiUrl, true)
            whr.SetRequestHeader("User-Agent", "AHK-AutoUpdater")
            whr.Send()
            whr.WaitForResponse()
            
            if (whr.Status != 200)
                throw Error("HTTP " . whr.Status)
                
            json := whr.ResponseText
            
            ; 1. Get latest release tag
            if RegExMatch(json, '"tag_name"\s*:\s*"([^"]+)"', &tagMatch)
                this.LatestVersion := tagMatch[1]

            ; 2. Determine best download URL (prefer direct binary, fallback to zip)
            targetExt := A_IsCompiled ? "\.exe" : "\.ahk"
            
            if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+' . targetExt . ')"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+\.zip)"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+)"', &dlMatch) {
                this.DownloadUrl := dlMatch[1]
            } else if RegExMatch(json, '"zipball_url"\s*:\s*"([^"]+)"', &zipMatch) {
                this.DownloadUrl := zipMatch[1]
            }

            this.App.UpdateLastCheck := FormatTime(A_Now, "yyyy-MM-dd")

            if (this.IsNewerVersion(this.App.Version, this.LatestVersion)) {
                if silent {
                    if (MsgBox("A new version (" . this.LatestVersion . ") is available for " . A_ScriptName . "!`n`nWould you like to update now?", "Update Available", "YesNo Iconi") == "Yes") {
                        this.ApplyUpdate()
                    }
                } else {
                    return true
                }
            } else if !silent {
                MsgBox("You are running the latest version (" . this.App.Version . ").", "Up to Date", "64")
            }
        } catch Error as err {
            if !silent
                MsgBox("Failed to check for updates.`nError: " . err.Message, "Update Error", "48")
        }
        return false
    }

    IsNewerVersion(current, latest) {
        cClean := RegExReplace(current, "[^\d.]")
        lClean := RegExReplace(latest, "[^\d.]")
        
        cParts := StrSplit(cClean, ".")
        lParts := StrSplit(lClean, ".")
        maxParts := Max(cParts.Length, lParts.Length)
        
        Loop maxParts {
            cP := A_Index <= cParts.Length ? Integer(cParts[A_Index]) : 0
            lP := A_Index <= lParts.Length ? Integer(lParts[A_Index]) : 0
            
            if (lP > cP)
                return true
            if (lP < cP)
                return false
        }
        return false
    }

    ApplyUpdate() {
        if (this.DownloadUrl == "") {
            MsgBox("No download URL found for this release on GitHub.", "Update Error", "48")
            return
        }

        isZip := RegExMatch(this.DownloadUrl, "i)\.zip(\?|$)") || RegExMatch(this.DownloadUrl, "i)/zipball/")
        
        ; Extract original file extension from URL if available, fallback to compiled state
        urlExt := A_IsCompiled ? ".exe" : ".ahk"
        if RegExMatch(this.DownloadUrl, "i)\.([a-z0-9]+)(\?|$)", &extMatch) {
            urlExt := "." . extMatch[1]
        }
        
        dlFile := A_Temp . "\app_update_dl_" . A_TickCount . (isZip ? ".zip" : urlExt)
        targetFile := A_ScriptFullPath
        targetDir := A_ScriptDir
        newExeName := ""
        payloadFile := ""
        extractDir := ""
        sourceDir := ""

        try {
            ToolTip("Downloading update...")
            Download(this.DownloadUrl, dlFile)
            ToolTip()
        } catch Error as err {
            ToolTip()
            MsgBox("Failed to download update file.`n" . err.Message, "Download Failed", "48")
            return
        }

        ; Handle ZIP extraction if needed
        if isZip {
            ToolTip("Extracting update...")
            extractDir := A_Temp . "\ahk_update_ext_" . A_TickCount
            DirCreate(extractDir)
            
            psCmd := "powershell -NoProfile -WindowStyle Hidden -Command `"Expand-Archive -Path '" dlFile "' -DestinationPath '" extractDir "' -Force`""
            RunWait(psCmd, , "Hide")
            
            try FileDelete(dlFile)

            searchExt := A_IsCompiled ? "exe" : "ahk"
            
            ; 1. Check if files are located in root extract directory
            hasRootFile := false
            Loop Files, extractDir . "\*." . searchExt {
                hasRootFile := true
                break
            }
            
            if hasRootFile {
                sourceDir := extractDir
            } else {
                ; 2. Fall back to searching inside wrapper directories
                Loop Files, extractDir . "\*", "D" {
                    subDir := A_LoopFileFullPath
                    Loop Files, subDir . "\*." . searchExt, "R" {
                        sourceDir := subDir
                        break 2
                    }
                }
                
                if (sourceDir == "")
                    sourceDir := extractDir
            }

            ; Locate the updated target executable/script inside sourceDir
            ; Priority 1: Match current script name
            Loop Files, sourceDir . "\" . A_ScriptName, "R" {
                newExeName := A_LoopFileName
                break
            }

            ; Priority 2: Fall back to first matching executable/script if filename changed
            if (newExeName == "") {
                Loop Files, sourceDir . "\*." . searchExt, "R" {
                    newExeName := A_LoopFileName
                    break
                }
            }

            ToolTip()

            if (newExeName == "") {
                MsgBox("Failed to locate an updated ." . searchExt . " file inside the downloaded zip archive.", "Update Error", "48")
                try DirDelete(extractDir, true)
                return
            }
        } else {
            payloadFile := dlFile
            
            ; Parse the remote filename from the URL, or default to script name
            if RegExMatch(this.DownloadUrl, "[^/]+\.[a-zA-Z0-9]+(?=\?|$)", &fileNameMatch) {
                newExeName := fileNameMatch[0]
            } else {
                newExeName := A_ScriptName
            }
        }

        ; Self-deleting command script handles replacement of files & app restart
        cmdScript := A_Temp . "\ahk_updater_" . A_TickCount . ".cmd"
        pid := ProcessExist()
        
        ; Ensure newExeName retains extension
        if !RegExMatch(newExeName, "i)\.(exe|ahk)$") {
            newExeName .= (A_IsCompiled ? ".exe" : ".ahk")
        }

        ; Build launch path pointing to the new file name
        newTargetPath := targetDir . "\" . newExeName
        relaunchCmd := A_IsCompiled ? '"' . newTargetPath . '"' : '"' . A_AhkPath . '" "' . newTargetPath . '"'
        
        cmdLines := [
            "@echo off",
            "timeout /t 1 /nobreak > nul",
            ":wait",
            'tasklist /FI "PID eq ' . pid . '" 2>nul | find /I "' . pid . '" > nul',
            "if %ERRORLEVEL%==0 (",
            "    timeout /t 1 /nobreak > nul",
            "    goto wait",
            ")"
        ]

        if isZip {
            ; Copy all files and subdirectories from the ZIP payload into the app directory
            cmdLines.Push('xcopy /s /e /y /q "' . sourceDir . '\*" "' . targetDir . '\"')
            
            ; If the filename changed, delete the old executable so it isn't left behind
            if (StrLower(A_ScriptName) != StrLower(newExeName)) {
                cmdLines.Push('del /f /q "' . targetFile . '"')
            }
            
            cmdLines.Push('rmdir /s /q "' . extractDir . '"')
        } else {
            ; Single binary copy
            cmdLines.Push('copy /y "' . payloadFile . '" "' . newTargetPath . '"')
            
            if (StrLower(A_ScriptName) != StrLower(newExeName)) {
                cmdLines.Push('del /f /q "' . targetFile . '"')
            }
            
            cmdLines.Push('del "' . payloadFile . '"')
        }

        cmdLines.Push('start "" ' . relaunchCmd)
        cmdLines.Push('del "%~f0"')
        
        cmdContent := ""
        for line in cmdLines
            cmdContent .= line . "`r`n"

        FileOpen(cmdScript, "w").Write(cmdContent)
        
        Run(A_ComSpec . ' /c "' . cmdScript . '"', , "Hide")
        ExitApp()
    }

    ShowGUI() {
        updGui := Gui("+AlwaysOnTop -MinimizeBox", "Update Settings - " . A_ScriptName)
        updGui.SetFont("s9", "Segoe UI")

        updGui.AddText("w100", "Current Version:")
        ;updGui.AddText("x+5 w150 Bold", this.App.Version)
        updGui.AddText("x+5 w150", this.App.Version)
        
        updGui.AddText("x10 w100", "Latest Version:")
        ;lblLatest := updGui.AddText("x+5 w150 Bold", this.LatestVersion != "" ? this.LatestVersion : "Not checked")
        lblLatest := updGui.AddText("x+5 w150", this.LatestVersion != "" ? this.LatestVersion : "Not checked")

        updGui.AddText("x10 w100", "Last Checked:")
        lblLastCheck := updGui.AddText("x+5 w150", this.App.UpdateLastCheck)

        updGui.AddText("x10 h1 w280 0x10")

        chkAuto := updGui.AddCheckbox("x10 Checked" . (this.App.UpdateAuto ? "1" : "0"), " Enable Automatic Updates")
        
        updGui.AddText("x10 y+10", "Check frequency (days):")
        numFreq := updGui.AddEdit("x+10 w50 Number", this.App.UpdateFrequencyDays)
        updGui.AddUpDown("Range1-90", this.App.UpdateFrequencyDays)

        btnCheck := updGui.AddButton("x10 y+15 w130", "Check for Updates")
        btnUpdate := updGui.AddButton("x+10 w130 Disabled", "Install Update")
        
        if (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion))
            btnUpdate.Enabled := true

        btnSave := updGui.AddButton("x10 y+15 w270", "Save & Close")

        btnCheck.OnEvent("Click", (*) => (
            btnCheck.Enabled := false,
            btnCheck.Text := "Checking...",
            hasUpdate := this.CheckForUpdates(false),
            lblLastCheck.Value := this.App.UpdateLastCheck,
            lblLatest.Value := this.LatestVersion != "" ? this.LatestVersion : "Unknown",
            btnUpdate.Enabled := hasUpdate,
            btnCheck.Text := "Check for Updates",
            btnCheck.Enabled := true
        ))

        btnUpdate.OnEvent("Click", (*) => this.ApplyUpdate())

        btnSave.OnEvent("Click", (*) => (
            this.App.UpdateAuto := (chkAuto.Value != 0),
            this.App.UpdateFrequencyDays := Integer(numFreq.Value),
            updGui.Destroy()
        ))

        updGui.Show()
    }
}