/************************************************************************
 * @description This is a Splash Screen made of Custom OSD
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/08/08
 * @version 1.0.0.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

#Include ".\_OSDCustom.ahk"

If !IsSet(App) {
	App := {
		Name:                       "My App",
		Icon:                       A_ScriptDir "\app.png",
		Version:                    "1.0.0.0"
	}
}

SplashScreenOSD()

SplashScreenOSD() {
	Splash := OSDCustom()
	Splash.MinWidth := 400
	Splash.RowGap := 1
	Splash.FontSize := 14
	Splash.MarginX := 0
	Splash.MarginY := 34
	Splash.SlideDistance := 1
	Splash.FontWeight := 1000
	Splash.Opacity := 255
	Splash.TimeOut := 50
    Splash.TextDefaultLight := "5a5555"
    Splash.BgColorLight := "F5F9FB"
    Splash.ProgressFgLight := "0067C0"
    Splash.ProgressBgLight := "F5F9FB"
	Splash.TextDefaultDark := "FFFFFF"
	Splash.BgColorDark := "202020"
	Splash.ProgressFgDark := "0067C0"
	Splash.ProgressBgDark := "202020"


	Splash.SetCellText( 1, 5, " ", "Center")
	Splash.SetCellImage( 2, 5, App.Icon, "Left", 50, 1, 2)
	Splash.SetCellText( 2, 5, App.Name, "Center", 4, 1)
	Splash.SetCellText( 6, 5, " ")
	Splash.SetCellText( 2, 6, "Version " App.Version, "Center", {Fontsize: 8, FontColor: "888888", FontWeight: 100}, 4, 1)
	Splash.SetCellText( 6, 7, " ")
;	SplashProgress := Splash.SetCellProgress( 1, 8,,,,6)
	SplashProgress := Splash.SetCellProgress( 2, 8,,,,5)

	Splash.Show()

	SetTimer(addProgress, 15)

	addProgress() {
		;SplashOSD
		static value := 0
		value += 1
		
		Splash.UpdateProgressObject(SplashProgress, value)
		
		if (value >= 100) {
			SetTimer(addProgress, 0)
			Splash.ClearCells()
			Splash := ""
		}
	}
}
