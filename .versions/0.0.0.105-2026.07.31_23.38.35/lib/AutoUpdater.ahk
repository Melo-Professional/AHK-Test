/************************************************************************
 * @description Autod Updater
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/31
 * @version 1.1.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

for arg in A_Args {
    if RegExMatch(arg, "i)^--signal-update-success=(.+)$", &match) {
        signalFileUpdate := Trim(match[1], '"')
        try FileOpen(signalFileUpdate, "w").Write("OK")
        break
    }
}

updater := AutoUpdater(App)
updater.CheckOnStartup(FirstRun)

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

		if Debug {
			tooltip("`n" . "has update auto: " this.App.HasOwnProp("UpdateAuto") .
					"`n" . "update auto: " this.App.UpdateAuto .
					"`n" . "has update frequency days: " this.App.HasOwnProp("UpdateFrequencyDays") .
					"`n" . "frequency days: " this.App.UpdateFrequencyDays .
					"`n" . "has update last check: " this.App.HasOwnProp("UpdateAuto") .
					"`n" . "last check: " this.App.UpdateLastCheck .
					"`n ."
			)
		}
    }

    CheckOnStartup(isFirstRun := false) {
        if (!this.App.UpdateAuto || !this.App.HasOwnProp("Github") || this.App.Github == "")
            return
            
        lastCheck := StrReplace(this.App.UpdateLastCheck, "-", "") . "000000"
        if (StrLen(lastCheck) < 14 || !IsTime(lastCheck))
            lastCheck := "19700101000000"

        diffDays := DateDiff(A_Now, lastCheck, "Days")
        
        if (isFirstRun || diffDays >= this.App.UpdateFrequencyDays) {
            SetTimer(() => this.PerformStartupCheck(isFirstRun), -100)
        }
    }

    PerformStartupCheck(isFirstRun) {
        hasUpdate := this.CheckForUpdates(true)
        if (hasUpdate) {
            if isFirstRun {
                ; First run: Prompt user with GUI to toggle settings or update
                this.ShowGUI()
            } else {
                ; Subsequent run: Update silently in background
                this.ApplyUpdate(true)
            }
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
            
            if RegExMatch(json, '"tag_name"\s*:\s*"([^"]+)"', &tagMatch)
                this.LatestVersion := tagMatch[1]

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
                return true
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

    ApplyUpdate(silent := false) {
        if (this.DownloadUrl == "") {
            if !silent
                MsgBox("No download URL found for this release on GitHub.", "Update Error", "48")
            return
        }

        ; 1. Update Last Check Date & Save to prevent infinite loop on rollback
        this.App.UpdateLastCheck := FormatTime(A_Now, "yyyy-MM-dd")
        if (this.App.HasOwnProp("UpdateLastCheck"))
            App.UpdateLastCheck := this.App.UpdateLastCheck
        if (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure")
            SaveINI()

        isZip := RegExMatch(this.DownloadUrl, "i)\.zip(\?|$)") || RegExMatch(this.DownloadUrl, "i)/zipball/")
        
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
            if !silent
                ToolTip("Downloading update...")
            Download(this.DownloadUrl, dlFile)
            if !silent
                ToolTip()
        } catch Error as err {
            if !silent {
                ToolTip()
                MsgBox("Failed to download update file.`n" . err.Message, "Download Failed", "48")
            }
            return
        }

        if isZip {
            if !silent
                ToolTip("Extracting update...")
            extractDir := A_Temp . "\ahk_update_ext_" . A_TickCount
            DirCreate(extractDir)
            
            psCmd := "powershell -NoProfile -WindowStyle Hidden -Command `"Expand-Archive -LiteralPath '" dlFile "' -DestinationPath '" extractDir "' -Force`""
            RunWait(psCmd, , "Hide")
            
            try FileDelete(dlFile)

            searchExt := A_IsCompiled ? "exe" : "ahk"
            
            hasRootFile := false
            Loop Files, extractDir . "\*." . searchExt {
                hasRootFile := true
                break
            }
            
            if hasRootFile {
                sourceDir := extractDir
            } else {
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

            Loop Files, sourceDir . "\" . A_ScriptName, "R" {
                newExeName := A_LoopFileName
                break
            }

            if (newExeName == "") {
                Loop Files, sourceDir . "\*." . searchExt, "R" {
                    newExeName := A_LoopFileName
                    break
                }
            }

            if !silent
                ToolTip()

            if (newExeName == "") {
                if !silent
                    MsgBox("Failed to locate an updated ." . searchExt . " file inside the downloaded zip archive.", "Update Error", "48")
                try DirDelete(extractDir, true)
                return
            }
        } else {
            payloadFile := dlFile
            
            if RegExMatch(this.DownloadUrl, "[^/]+\.[a-zA-Z0-9]+(?=\?|$)", &fileNameMatch) {
                newExeName := fileNameMatch[0]
            } else {
                newExeName := A_ScriptName
            }
        }

        cmdScript := A_Temp . "\ahk_updater_" . A_TickCount . ".cmd"
        signalFile := A_Temp . "\ahk_upd_ok_" . A_TickCount . ".tmp"
        pid := ProcessExist()
        
        if !RegExMatch(newExeName, "i)\.(exe|ahk)$") {
            newExeName .= (A_IsCompiled ? ".exe" : ".ahk")
        }

        newTargetPath := targetDir . "\" . newExeName
        
        SplitPath(targetFile, &targetName, &targetDir, &targetExt, &targetNameNoExt)
        backupFileName := targetNameNoExt . "_v" . this.App.Version . "." . targetExt . ".bak"
        backupFilePath := targetDir . "\" . backupFileName
        failedFileName := targetNameNoExt . "_FAILED." . targetExt

        cmdLines := [
            "@echo off",
            
            "; --- STEP 1: Wait for current process to completely exit ---",
            ":wait_exit",
            'tasklist /FI "PID eq ' . pid . '" 2>nul | find /I "' . pid . '" > nul',
            "if %ERRORLEVEL%==0 (",
            "    timeout /t 1 /nobreak > nul",
            "    goto wait_exit",
            ")",

            "; --- STEP 2: Clear old backup/failed files ---",
            'if exist "' . backupFilePath . '" del /f /q "' . backupFilePath . '"',
            'if exist "' . targetDir . '\' . failedFileName . '" del /f /q "' . targetDir . '\' . failedFileName . '"',

            "; --- STEP 3: Backup active file ---",
            'ren "' . targetFile . '" "' . backupFileName . '"'
        ]

        if isZip {
            cmdLines.Push('robocopy "' . sourceDir . '" "' . targetDir . '" /E /IS /IT /NJH /NJS /nc /ns /np > nul')
            cmdLines.Push('rmdir /s /q "' . extractDir . '"')
        } else {
            cmdLines.Push('copy /y "' . payloadFile . '" "' . newTargetPath . '" > nul')
            cmdLines.Push('del /f /q "' . payloadFile . '"')
        }

        ; --- STEP 4: Ensure new EXE is in place before executing start ---
        cmdLines.Push(':wait_file')
        cmdLines.Push('if not exist "' . newTargetPath . '" (')
        cmdLines.Push('    timeout /t 1 /nobreak > nul')
        cmdLines.Push('    goto wait_file')
        cmdLines.Push(')')

        ; --- STEP 5: Launch updated version and check health ---
        if A_IsCompiled {
            cmdLines.Push('start "" "' . newTargetPath . '" "--signal-update-success=' . signalFile . '"')
        } else {
            cmdLines.Push('start "" "' . A_AhkPath . '" "' . newTargetPath . '" "--signal-update-success=' . signalFile . '"')
        }
        
        cmdLines.Push('set "counter=0"')
        cmdLines.Push(':check_health')
        cmdLines.Push('timeout /t 1 /nobreak > nul')
        cmdLines.Push('if exist "' . signalFile . '" goto update_success')
        cmdLines.Push('set /a counter+=1')
        cmdLines.Push('if %counter% LSS 8 goto check_health')

        ; --- STEP 6: ROLLBACK (If health signal wasn't received within 8 seconds) ---
        cmdLines.Push(':update_failed')
        cmdLines.Push('if exist "' . newTargetPath . '" ren "' . newTargetPath . '" "' . failedFileName . '"')
        cmdLines.Push('if exist "' . backupFilePath . '" ren "' . backupFilePath . '" "' . targetName . '"')
        cmdLines.Push('msg * "Update failed to launch properly. Restoring previous working version."')
        
        if A_IsCompiled {
            cmdLines.Push('start "" "' . targetFile . '"')
        } else {
            cmdLines.Push('start "" "' . A_AhkPath . '" "' . targetFile . '"')
        }
        cmdLines.Push('goto cleanup')

        ; --- STEP 7: SUCCESS ---
        cmdLines.Push(':update_success')
        cmdLines.Push('if exist "' . signalFile . '" del /f /q "' . signalFile . '"')
        cmdLines.Push('if exist "' . backupFilePath . '" del /f /q "' . backupFilePath . '"') ; <--- Delete old backup file on success

        ; --- STEP 8: CLEANUP ---
        cmdLines.Push(':cleanup')
        cmdLines.Push('del "%~f0"')

        cmdContent := ""
        for line in cmdLines
            cmdContent .= line . "`r`n"

        FileOpen(cmdScript, "w").Write(cmdContent)
        
        Run(A_ComSpec . ' /c "' . cmdScript . '"', , "Hide")
        ExitApp()
    }

ShowGUI() {
        hasUpdate := (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion))

        MyGuiTitle := App.Name . " - Update"
        MyGuiOptions := "+LastFound -SysMenu"
        MyGui := Gui(MyGuiOptions, MyGuiTitle)
        MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
        offset := 5

        if IsFunctionDefined("CustomTitleBar") {
            MyGui.Opt("-Caption")
            titlebar := %"CustomTitleBar"%.Attach(MyGui, {
                Title: MyGuiTitle,
                ShowIcon: false,
                Min: false,
                Max: false,
                Close: true
            })
            offset := 40
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
        }

        MyGui.MarginX := 34
        MyGui.MarginY := 20

        ; Persistent Banner Text Control Handles
        txtBannerTitle := MyGui.AddText("vStrong_01 xm w320", "")
        ;txtBannerSub   := MyGui.AddText("vSmooth_01 xm w320 y+4", "")
        txtBannerSub   := MyGui.AddText("xm w320 y+4", "")

        ; Helper function to update the top banner dynamically
        UpdateBannerUI() {
            if (this.LatestVersion != "" && this.IsNewerVersion(this.App.Version, this.LatestVersion)) {
                txtBannerTitle.SetFont("s11 bold c0x008000", "Segoe UI")
                txtBannerTitle.Value := "A new update is available!"
                ;txtBannerSub.SetFont("s9 Norm c0x555555", "Segoe UI")
                txtBannerSub.SetFont("s9 Norm", "Segoe UI")
                txtBannerSub.Value := "Version " . this.LatestVersion . " is ready to install."
            } else if (this.LatestVersion != "") {
                txtBannerTitle.SetFont("s11 bold c0x2B579A", "Segoe UI")
                txtBannerTitle.Value := "✓ You're up to date"
                ;txtBannerSub.SetFont("s9 Norm c0x555555", "Segoe UI")
                txtBannerSub.SetFont("s9 Norm", "Segoe UI")
                txtBannerSub.Value := "You are running the latest version."
            } else {
                ;txtBannerTitle.SetFont("s11 bold c0x333333", "Segoe UI")
                txtBannerTitle.SetFont("s11 bold c0x8b8b8b", "Segoe UI")
                txtBannerTitle.Value := "Update Preferences"
                ;txtBannerSub.SetFont("s9 Norm c0x555555", "Segoe UI")
                txtBannerSub.SetFont("s9 Norm", "Segoe UI")
                txtBannerSub.Value := "Check and manage application updates."
            }
			;txtBannerTitle.BypassTheme := true
			;txtBannerSub.BypassTheme := true
        }

        ; Initialize Banner Text
        UpdateBannerUI()

        ; Version Info Grid
        MyGui.SetFont("s9 Norm", "Segoe UI")
        
        MyGui.AddText("xm w120 y+40 c0x666666", "Current Version:")
        MyGui.SetFont("s9 bold")
        MyGui.AddText("vStrong_03 x+10 w180 c0x222222", this.App.Version)

        MyGui.SetFont("s9 Norm")
        MyGui.AddText("xm y+10 w120 c0x666666", "Latest Version:")
        MyGui.SetFont("s9 bold")
        lblLatest := MyGui.AddText("vStrong_04 x+10 w180 c0x222222", this.LatestVersion != "" ? this.LatestVersion : "Not checked")

        MyGui.SetFont("s9 Norm")
        MyGui.AddText("xm y+10 w120 c0x666666", "Last Checked:")
        lblLastCheck := MyGui.AddText("x+10 w180 c0x222222", this.App.UpdateLastCheck)

        ; Settings Section
        chkAuto := MyGui.AddCheckbox("xm y+40 Checked" . (this.App.UpdateAuto ? "1" : "0"), " Enable Automatic Updates")
        
        lblFreq := MyGui.AddText("xm y+14 c0x444444", "Check frequency (days):")
        numFreq := MyGui.AddEdit("x+12 w60 Number Center", this.App.UpdateFrequencyDays)
        updUpDown := MyGui.AddUpDown("Range1-90", this.App.UpdateFrequencyDays)

        ; Enable/Disable Frequency Control based on Checkbox state
        ToggleFreqControls(enabled) {
            lblFreq.Enabled := enabled
            numFreq.Enabled := enabled
            updUpDown.Enabled := enabled
        }
        
        ; Initial State Sync
        ToggleFreqControls(this.App.UpdateAuto)
        chkAuto.OnEvent("Click", (*) => ToggleFreqControls(chkAuto.Value != 0))

        ; Action Buttons
        btnCheck := MyGui.AddButton("xm y+40 w155 h32", "Check for Updates")
        btnUpdate := MyGui.AddButton("x+10 w155 h32 " . (hasUpdate ? "" : "Disabled"), "Install Update")

        btnSave := MyGui.AddButton("xm y+12 w320 h34", "Save & Close")

        ; --- Events ---
        btnCheck.OnEvent("Click", (*) => (
            btnCheck.Enabled := false,
            btnCheck.Text := "Checking...",
            hasUpdate := this.CheckForUpdates(false),
            lblLastCheck.Value := this.App.UpdateLastCheck,
            lblLatest.Value := this.LatestVersion != "" ? this.LatestVersion : "Unknown",
            UpdateBannerUI(), ; <--- Refresh banner text & styles dynamically
            btnUpdate.Enabled := hasUpdate,
            btnCheck.Text := "Check for Updates",
            btnCheck.Enabled := true
        ))

        btnUpdate.OnEvent("Click", (*) => this.ApplyUpdate(false))

        btnSave.OnEvent("Click", (*) => (
            this.App.UpdateAuto := (chkAuto.Value != 0),
            this.App.UpdateFrequencyDays := Integer(numFreq.Value),
            App.UpdateAuto := this.App.UpdateAuto,
            App.UpdateFrequencyDays := this.App.UpdateFrequencyDays,
            App.UpdateLastCheck := this.App.UpdateLastCheck,
            (Type(SaveINI) == "Func" || Type(SaveINI) == "Closure") ? SaveINI() : "",
            MyGui.Destroy()
        ))

        ApplyThemeToGui(MyGui)
        WatchedGUIs.Push(MyGui)
        MyGui.Show()




            btnCheck.Enabled := false,
            btnCheck.Text := "Checking...",
            hasUpdate := this.CheckForUpdates(false),
            lblLastCheck.Value := this.App.UpdateLastCheck,
            lblLatest.Value := this.LatestVersion != "" ? this.LatestVersion : "Unknown",
            UpdateBannerUI(), ; <--- Refresh banner text & styles dynamically
            btnUpdate.Enabled := hasUpdate,
            btnCheck.Text := "Check for Updates",
            btnCheck.Enabled := true
;		UpdateBannerUI()

        IsFunctionDefined(Name) {
            try return HasMethod(%Name%)
            return false
        }

    }
}
