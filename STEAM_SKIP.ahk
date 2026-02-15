#Requires AutoHotkey v2.0
#Include UIA.ahk

SetTitleMatchMode 2

ClickSteamContinueError() {
    try {
        ; 1. Находим нужный документ (steamwebhelper с нужным заголовком/URL)
        ; Вариант А — по части названия окна
        hwnd := WinExist("Steam ahk_exe steamwebhelper.exe")
        
        if !hwnd {
            ; Вариант Б — более точный поиск по Chrome_RenderWidgetHostHWND и имени "Steam"
            for w in WinGetList("ahk_class Chrome_RenderWidgetHostHWND") {
                try {
                    title := WinGetTitle(w)
                    if InStr(title, "Steam") && InStr(title, "index.html") {
                        hwnd := w
                        break
                    }
                }
            }
        }

        if !hwnd {
            ;ToolTip "Окно steamwebhelper не найдено", 10, 10
            return false
        }

        ; 2. Получаем корневой UIA-элемент окна
        elRoot := UIA.ElementFromHandle(hwnd)

        errorDialog := elRoot.ElementExist({
            Type:"Custom", Name:"Error - Steam"
        })

        if !errorDialog {
            ; ToolTip "Не найдено ошибки", 10, 10
            return false
        }

        if continueBtn := errorDialog.ElementExist({
            Type:"Button", Name:"Continue"
        }) {
            continueBtn.Click()
        }

        ; MsgBox errorDialog.Highlight().Dump()

        ; continueBtn := errorDialog

        return false
    }
    catch as err {
        ; ToolTip "UIA ошибка: " err.Message, 10, 40
        return false
    }
}

Persistent

SetTimer CheckSteamErrorPopup, 2400

CheckSteamErrorPopup() {
    static lastClick := 0

    ; Не чаще чем раз в 8 секунд жмём (защита от зацикливания)
    if (A_TickCount - lastClick < 8000)
        return

    if ClickSteamContinueError()
        lastClick := A_TickCount
}