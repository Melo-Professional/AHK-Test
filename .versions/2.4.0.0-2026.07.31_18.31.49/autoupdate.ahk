;@region Setup
;@region Description
/************************************************************************
 * @description This is a template as a starting point for your AutoHotKey projects.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/30
 * @releasedate 2026/04/24
 * @version 1.0.0.3
 ***********************************************************************/

AppName := "Spotify Control"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "2.4.0.0"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "This is a template as a starting point for your AutoHotKey projects. This is a template as a starting point for your AutoHotKey projects."
;@endregion

_bkpMode := "AppVersionAndMinutes"

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
A_MenuMaskKey := "vkFF"
; --- Optimization Settings ---
;ProcessSetPriority("High")
;ListLines(False)
;KeyHistory(0)
;A_MaxHotkeysPerInterval := 5000
;A_HotkeyInterval := 1000
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Backup>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
;#Include *i <_MessageManager>
#Include *i <_Theme>
#Include *i <_FrostedTheme>
#Include *i <_TitleBar>
;#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
;#Include *i <_HotkeysRecorder>
;#Include *i <_ODColors>
#Include *i <_OSDCustom>
#Include *i <_SplashScreen>
#Include *i <_About>
#Include *i <_Help>
#Include *i <_Menu>

#Include *i <Vars_Custom>
#Include *i <Menu_Custom>


;@endregion

;@region Startup
; SPLASHSCREEN
if (A_Args.Length == 0) && IsSet(SplashScreen){
    SplashScreen()
}

; TRAY ICON + MENU
StartMenu()
Menu_Custom()

;@endregion
;@endregion

;@region Main

;@endregion
;throw Error('Message', A_ThisFunc, )
;a := "test"
;OutputDebug(a) ; debug tab

#HotIf !A_ComputerName
^p::ReloadClean()
#HotIf





#Requires AutoHotkey v2.0

; App Configuration Object
;global App := Object()
;App.Version := "1.0.0.0"
;App.Github := "https://github.com/Melo-Professional/Repo"

#Include <AutoUpdater>


/* 
; Instantiate updater
global Updater := AutoUpdater(App)

; Check quietly on startup (only runs if UpdateFrequencyDays has elapsed)
;Updater.CheckOnStartup()

; 3. Run background check on startup (completely silent auto-update)
updater.CheckOnStartup(true)
 */


; Initialize Updater & Run Startup Check
updater := AutoUpdater(App)
updater.CheckOnStartup(FirstRun)



; Setup a hotkey or Tray Menu item to open the Update Settings GUI
A_TrayMenu.Add("Check for Updates", (*) => Updater.ShowGUI())

; --- Your Main Application Code Below ---
MsgBox("App is running!", "My App", "64")