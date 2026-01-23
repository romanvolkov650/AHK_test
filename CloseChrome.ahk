#Requires AutoHotkey v2.0
#SingleInstance Force

SetTimer(CheckChrome, 1000) ; Проверять каждые 1 секунду

CheckChrome() {
    if ProcessExist("chrome.exe") {
        try {
            ProcessClose("chrome.exe")
        }
    }
}