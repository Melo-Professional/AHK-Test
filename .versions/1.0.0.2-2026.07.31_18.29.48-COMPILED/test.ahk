#Requires AutoHotkey v2.0

class AutoUpdater {
    __New(appObject) {
        MsgBox("Success! Current version: " . appObject.Version)
    }
}

App := { Version: "1.0.0.0" }
Updater := AutoUpdater(App)