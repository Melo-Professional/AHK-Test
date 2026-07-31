#Requires AutoHotkey v2.0

class AutoUpdater {
    App := ""
    LatestVersion := ""
    DownloadUrl := ""
    
    ; Constructor - Must have TWO leading underscores
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
            
            if RegExMatch(json, '"tag_name"\s*:\s*"([^"]+)"', &tagMatch)
                this.LatestVersion := tagMatch[1]

            if RegExMatch(json, '"browser_download_url"\s*:\s*"([^"]+)"', &dlMatch) {
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
            MsgBox("No download URL found for the update.", "Update Error", "48")
            return
        }

        ext := A_IsCompiled ? ".exe" : ".ahk"
        tempFile := A_Temp . "\app_update_temp" . ext
        targetFile := A_ScriptFullPath

        try {
            ToolTip("Downloading update...")
            Download(this.DownloadUrl, tempFile)
            ToolTip()
        } catch Error as err {
            ToolTip()
            MsgBox("Failed to download update file.`n" . err.Message, "Download Failed", "48")
            return
        }

        cmdScript := A_Temp . "\ahk_updater_" . A_TickCount . ".cmd"
        pid := ProcessExist()
        
        cmdLines := [
            "@echo off",
            "timeout /t 1 /nobreak > nul",
            ":wait",
            'tasklist /FI "PID eq ' . pid . '" 2>nul | find /I "' . pid . '" > nul',
            "if %ERRORLEVEL%==0 (",
            "    timeout /t 1 /nobreak > nul",
            "    goto wait",
            ")",
            'copy /y "' . tempFile . '" "' . targetFile . '"',
            'del "' . tempFile . '"',
            'start "" "' . targetFile . '"',
            'del "%~f0"'
        ]
        
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
        updGui.AddText("x+5 w150 Bold", this.App.Version)
        
        updGui.AddText("x10 w100", "Latest Version:")
        lblLatest := updGui.AddText("x+5 w150 Bold", this.LatestVersion != "" ? this.LatestVersion : "Not checked")

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
            this.App.UpdateAuto := chkAuto.Value,
            this.App.UpdateFrequencyDays := Integer(numFreq.Value),
            updGui.Destroy()
        ))

        updGui.Show()
    }
}