/************************************************************************
 * @description Help GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/09/03
 * @version 1.7.0
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowHelpGUI(*) {
	static MyGui := ""
	if MyGui
		return WinActivate(MyGui)

    MyGuiTitle := "Help"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
	DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    offset := 10

    if IsSet(CustomTitleBar) {
        MyGui.Opt("-Caption")
        titlebar := CustomTitleBar.Attach(MyGui, {
            Title: MyGuiTitle,
            ShowIcon: false,
            Min: true,
            Max: false,
            Close: true
        })
        offset := 60
    }

    if (UseAcrylicGUI := IsSet(FrostedTheme))
        offset := 60

    ; Color Constants
	TextNormalColor				:= Settings.Theme.%CurrentActualTheme%.TextSmooth
	TextHoverColor				:= Settings.Theme.%CurrentActualTheme%.TextDefault
	BGroundNormalColor			:= Settings.Theme.%CurrentActualTheme%.Bg
	BGroundHoverColor			:= Settings.Theme.%CurrentActualTheme%.BgHover
	GitNormalColor				:= "5865F2"
	GitHoverColor				:= "5896f2"

	if UseAcrylicGUI {
		TextNormalColor			:= "CCCCCC"
		TextHoverColor			:= "FFFFFF"
		BGroundNormalColor		:= "1b1b1b"
		BGroundHoverColor		:= "313131"
		GitNormalColor			:= "5865F2"
		GitHoverColor			:= "5896f2"
	}

    ; Define layout constants
    GuiWidth            := 640
    BtnWidth            := 100
    MyGui.MarginX       := 50
    MyGui.MarginY       := 30

    ; 1. Icon
    try {
        MyGui.Add("Picture", "xm y" offset " w32 h32", App.Icon)
    } catch {
        MyGui.SetFont("s15 w500")
        MyGui.Add("Text", "y" offset " w32 h32", "[ i ]")
    }

    ; 2. Title and Version
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w700")
    MyGui.Add("Text", "x+15 yp vStrong_Title", App.Name)

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w400 ")
    MyGui.Add("Text", "y+2 vSmooth_Version", "Version " App.Version)

    ; 3. Content
    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "xm y+30 w" . (GuiWidth - (MyGui.MarginX * 2)), "HotKey")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Block/ unblock Internet access from any active program`nusing the shortkey defined in the tray menu.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Select from Running Programs")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Pick from curretly running process.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Select Any Program File")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Use file browser to select a program to block/unblock.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Manage Active Block Rules")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Find all currently blocked programs.")

    MyGui.SetFont("s" Settings.GuiFontSizeBig " w400")
    MyGui.Add("Text", "w" . (GuiWidth - (MyGui.MarginX * 2)), "Start on Boot")

    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")
    MyGui.Add("Text", "y+2 w" . (GuiWidth - (MyGui.MarginX * 2)), "Launch this script when Windows user login.")

    MyGui.SetFont("s" Settings.GuiFontSizeSmall " w300")
    MyGui.Add("Text", "y+20 vSmooth_Disclaimer w" . (GuiWidth - (MyGui.MarginX * 2)), "It requires administrator rights.*")
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300")

    ; 4. Button
;	btnX := MyGui.MarginX ; left
;	btnX := (GuiWidth - BtnWidth) // 2 ; center
	btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right


    if UseAcrylicGUI {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " CWhite w700", Settings.GuiFontName)
        btnSave := MyGui.Add("Text", "x" btnX " y+10 w" BtnWidth " h25 Center 0x0200 Background" BGroundNormalColor " +Border", "OK")
        btnSave.BypassTheme := true

    } else {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := MyGui.AddButton("x" btnX " y+10 w" BtnWidth " h25 Default", "&OK")
    }

    btnSave.OnEvent("Click", CleanDestroy)
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

	if IsSet(GuiTracker) {
		tracker := GuiTracker()
		tracker.AddGui := MyGui

		tracker.RegisterControl(btnSave, Map(
			"OnEnter", (ctrl) => (ctrl.SetFont("c" TextHoverColor), ctrl.Opt("+Background" BGroundHoverColor)),
			"OnLeave", (ctrl) => (ctrl.SetFont("c" TextNormalColor), ctrl.Opt("+Background" BGroundNormalColor))
		))
	}

    ; Apply Themes
    if UseAcrylicGUI {
        IsSet(ApplyThemeToGui) ? ApplyThemeToGui(MyGui, "Dark") : 0
        IsSet(FrostedTheme) ? FrostedTheme.Apply(MyGui) : 0
		ApplyHDRFontQuality(MyGui)
    } else {
        IsSet(ApplyThemeToGui) ? ApplyThemeToGui(MyGui) : 0
        IsSet(WatchedGUIs) ? WatchedGUIs.Push(MyGui) : 0
    }

    MyGui.Show("w" GuiWidth)

    CleanDestroy(*) {
        IsSet(RemoveGuiFromArray) ? RemoveGuiFromArray(MyGui) : 0
        MyGui.Destroy()
		MyGui := ""
    }
}
