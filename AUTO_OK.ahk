#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode "2"   ; частичное совпадение

SetTimer CheckWarnings, 500

CheckWarnings() {
    titles := [
        "Low Available Memory",
        "Low Pagefile"
    ]

    for t in titles {
        hwnd := WinExist(t " ahk_class #32770")
        if hwnd {
            try ControlClick "Button1", "ahk_id " hwnd
        }
    }
}