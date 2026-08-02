/************************************************************************
 * @description Vars_Custom
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/01
 * @version 1.1.0
 ***********************************************************************/

;@region VARS
; CUSTOM VARIABLES
App.Github := "https://github.com/Melo-Professional/AHK-Test"
/*
Global General := {
    BTDetect:                   true,
    WheelSpeed:                 10,
    gainStepsMin:               2,
    gainStepsMax:               20
}
*/

;ResetSettings       := Settings.Clone()
;ResetGeneral        := General.Clone()
;ResetOSDSettings    := OSDSettings.Clone()

;App.NameCutted := "Template`nBigName"
;Settings.SplashScreen := "Icon"
;Debug := true
;@endregion

if App.HasOwnProp("Github")  && App.Github != "" {
	App.UpdateAuto := true
	App.UpdateFrequencyDays := 7
	App.UpdateLastCheck := ""
	SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")
}



;@region INI
;SaveToINI.Push("Settings.SplashScreen")     ; add more to INI file
SaveToINI.Push("App.UpdateAuto", "App.UpdateFrequencyDays", "App.UpdateLastCheck")     ; add more to INI file
RegisterArrayItems(SaveToINI)
LoadINI()
;@endregion

;Settings.DesiredTheme := "Light"