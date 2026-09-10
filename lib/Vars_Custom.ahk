/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/16
 * @version 1.4.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.GitHubRepo			:= "https://github.com/Melo-Professional/AHK-Test/"
;App.NameCutted			:= "Template`nBigName"

/*
Global General := {
    BTDetect:                   true,
    WheelSpeed:                 10,
    gainStepsMin:               2,
    gainStepsMax:               20
}
*/
;ResetSettings			:= Settings.Clone()
;ResetGeneral			:= General.Clone()
;ResetOSDSettings		:= OSDSettings.Clone()
;Settings.DesiredTheme	:= "Light"
;Settings.SplashScreen	:= "Icon"
;Debug					:= true
;@endregion

;@region INI
SaveToINI := []
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file

if App.HasOwnProp("GitHubRepo")
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
if (IsSet(INIManager) && (SaveToINI != [])) {
	IsSet(RegisterArrayItems) ? RegisterArrayItems(SaveToINI) : 0
	IsSet(LoadINI) ? LoadINI() : 0
}
;@endregion
