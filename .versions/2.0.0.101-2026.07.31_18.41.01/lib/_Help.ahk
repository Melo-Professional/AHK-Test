/************************************************************************
 * @description Help GUI
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/07/20
 * @version 1.5.3 (Icon distance)
 ***********************************************************************/

#Requires AutoHotkey v2.0

ShowHelpGUI() {
    MyGuiTitle := "Help"
    MyGuiOptions := "+LastFound -SysMenu"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    offset := 10

    if IsFunctionDefined("CustomTitleBar") {
        MyGui.Opt("-Caption")
        titlebar := %"CustomTitleBar"%.Attach(MyGui, {
            Title: MyGuiTitle,
            ShowIcon: true,
            Min: true,
            Max: false,
            Close: true
        })
        offset := 60
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MyGui.Hwnd, "UInt", 33, "Int*", 2, "UInt", 4)
    }

    UseAcrylicGUI := false
    if IsFunctionDefined("FrostedTheme") {
        UseAcrylicGUI := true
        offset := 60
    }


    TextNormalColor := "CCCCCC"
    TextHoverColor  := "FFFFFF"
    BGroundNormalColor  := "1b1b1b"
    BGroundHoverColor  := "313131"
    isHovering := false

;    if UseAcrylicGUI {
;        MyGui.SetFont("c" TextNormalColor " s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
;    }

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
    MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
    ; 5.1 align
;        btnX := MyGui.MarginX ; left
;        btnX := (GuiWidth - BtnWidth) // 2 ; center
        btnX := GuiWidth - MyGui.MarginX - BtnWidth ; right
;    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", (*) => myGui.Destroy())
;    MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK").OnEvent("Click", CleanDestroy)


    if UseAcrylicGUI {
;        HoverSettingsGui.SetFont("s" Settings.GuiFontSizeBig " C727272 w700", Settings.GuiFontName)
        MyGui.SetFont("s" Settings.GuiFontSizeBig " CWhite w700", Settings.GuiFontName)
        btnSave := MyGui.Add("Text", "x" btnX " y+25 w" BtnWidth " h30 Center 0x0200 Background" BGroundNormalColor " +Border", "OK")
        btnSave.BypassTheme := true
    } else {
        MyGui.SetFont("s" Settings.GuiFontSizeMedium " w300", Settings.GuiFontName)
        btnSave := MyGui.AddButton("x" btnX " y+25 w" BtnWidth " h30 Default", "&OK")
    }

    btnSave.OnEvent("Click", CleanDestroy)
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    if UseAcrylicGUI {
        if IsFunctionDefined("ApplyThemeToGui")
            %"ApplyThemeToGui"%(MyGui, "Dark")
        if IsFunctionDefined("FrostedTheme")
            %"FrostedTheme"%.Apply(MyGui)
    } else {
        ApplyThemeToGui(MyGui)
        WatchedGUIs.Push(MyGui)
    }

    MyGui.Show("w" GuiWidth)

    if (App.Github || UseAcrylicGUI) {

        if IsSet(MessageManager) {
            MessageManager.Register(0x0200, OnMouseMoveMyGui)
        } else {
            OnMessage(0x0200, OnMouseMoveMyGui)
        }
    }

    OnMouseMoveMyGui(wParam, lParam, msg, hwnd) {
        try {
            if (!btnSave)
                return
        } catch {
            return
        }
        
        if (hwnd == btnSave.Hwnd) {

            ctrl := GuiCtrlFromHwnd(hwnd)

            if (!isHovering) {
                    isHovering := true
                    
                    TRACKMOUSEEVENT := Buffer(A_PtrSize == 8 ? 24 : 16, 0)
                    NumPut("UInt", TRACKMOUSEEVENT.Size, TRACKMOUSEEVENT, 0)
                    NumPut("UInt", 2,                    TRACKMOUSEEVENT, 4)
                    NumPut("Ptr",  ctrl.Hwnd,          TRACKMOUSEEVENT, A_PtrSize == 8 ? 8 : 8)
                    DllCall("TrackMouseEvent", "Ptr", TRACKMOUSEEVENT)
                    
                    if IsSet(MessageManager) {
                        MessageManager.Register(0x02A3, OnMouseLeaveMyGui)
                    } else {
                        OnMessage(0x02A3, OnMouseLeaveMyGui)
                    }
            }
            if UseAcrylicGUI {
                ctrl.SetFont("c" TextHoverColor)
                ctrl.Opt("+Background" BGroundHoverColor)
            }
        }
    }    

    OnMouseLeaveMyGui(wParam, lParam, msg, hwnd) {
        try {
            if (hwnd == btnSave.Hwnd && UseAcrylicGUI) {
                ctrl := GuiCtrlFromHwnd(hwnd)
                ctrl.SetFont("c" TextNormalColor)
                ctrl.Opt("+Background" BGroundNormalColor)
                isHovering := false
            }
        }
    }

    CleanDestroy(*) {
        if IsSet(MessageManager) {
            MessageManager.Unregister(0x0200, OnMouseMoveMyGui)
            MessageManager.Unregister(0x02A3, OnMouseLeaveMyGui)
        } else {
            OnMessage(0x0200, OnMouseMoveMyGui, 0)
            OnMessage(0x02A3, OnMouseLeaveMyGui, 0)
        }
        
        if IsFunctionDefined("RemoveGuiFromArray")
            %"RemoveGuiFromArray"%(MyGui)
        MyGui.Destroy()
    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}
