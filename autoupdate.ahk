;@region Setup
;@region Description
/************************************************************************
 * @description This is an auto updater for projects.
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/09/10
 * @releasedate 2026/04/24
 * @version 2.0.0.111
 ***********************************************************************/

AppName := "Auto Updater"
;@Ahk2Exe-Let U_AppName = %A_PriorLine%
AppVersion := "2.0.0.111"
;@Ahk2Exe-Let U_Version = %A_PriorLine%
AppDescription := "This is an auto updater for projects."
;@endregion

;_bkpMode := "AppVersionAndMinutes"

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
#Include *i <_SaveSettings>
#Include *i <_Config&Vars>
#Include *i <_HelperFuncs>
#Include *i <_MessageManager>
;#Include *i <_TrayIconHandler>
#Include *i <_Theme>
#Include *i <_FrostedTheme>
#Include *i <_TitleBar>
;#Include *i <_GuiTracker>
;#Include *i <_ModernSlider>
;#Include *i <_Color_Picker_Dialog>
;#Include *i <_ReloadWithArgs>
;#Include *i <_HotkeysRecorder>
;#Include *i <_ODColors>
#Include *i <_OSDCustom>
#Include *i <_AutoUpdater>
#Include *i <_SplashScreen>
#Include *i <_About>
#Include *i <_Help>
#Include *i <_Menu>

#Include *i <Vars_Custom>
#Include *i <Menu_Custom>


;@endregion

;@region Startup
if !A_Args.Length {
	if IsSet(SplashScreen) {
	    SplashScreen()
	} else if isSet(SplashScreenOSD) {
		SplashScreenOSD()
	}
}

IsSet(StartMenu) ? StartMenu() : 0
IsSet(Menu_Custom) ? Menu_Custom() : 0
IsSet(StartAutoUpdater) ? StartAutoUpdater() : 0
;@endregion
;@endregion

;@region Main

;@region Hotkeys
#HotIf !A_IsCompiled
^p::IsSet(ReloadClean) ? ReloadClean() : Reload()
#HotIf
;@endregion



;@endregion
IsSet(CheckReloadArgs) ? CheckReloadArgs() : 0

;throw Error('Message', A_ThisFunc, )
;a := "test"
;OutputDebug(a) ; debug tab
