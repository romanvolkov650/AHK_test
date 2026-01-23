#Requires AutoHotkey v2.0
#SingleInstance Force

; ====== НАСТРОЙКИ ======
appDir        := "C:\Users\Administrator\Downloads\vm"   ; папка программы (важно)
logFile       := "C:\Users\Administrator\Downloads\vm\log.txt"
needle        := "TooManyRetriesError"
appTitle      := "msedge"                    ; часть заголовка окна

checkMs        := 2000                 ; проверка лога
restartDelayMs := 2 * 60 * 1000        ; 2 минуты
idleLimitMs    := 5 * 60 * 1000       ; 5 минут без записей = рестарт
; =======================

lastSize      := 0
lastWriteTick := A_TickCount
isRestarting  := false

SetTimer(CheckLog, checkMs)

CheckLog() {
    global logFile, needle, lastSize, lastWriteTick, idleLimitMs, isRestarting

    if isRestarting
        return

    if !FileExist(logFile)
        return

    size := FileGetSize(logFile)

    ; лог был обрезан/перезаписан
    if (size < lastSize)
        lastSize := 0

    ; появились новые данные
    if (size > lastSize) {
        f := FileOpen(logFile, "r")
        f.Pos := lastSize
        text := f.Read()
        f.Close()

        lastSize := size
        lastWriteTick := A_TickCount

        if InStr(text, needle) {
            RestartApp("keyword")
            return
        }
    }

    ; лог не пишет слишком долго
    if (A_TickCount - lastWriteTick > idleLimitMs) {
        RestartApp("idle")
    }
}

RestartApp(reason) {
    global appDir, appTitle, restartDelayMs, isRestarting, lastWriteTick

    isRestarting := true
    KillProcessesInDir(appDir)

    ; 3) Ждём паузу
    Sleep restartDelayMs

    ; 4) Находим EXE и запускаем
    exePath := FindLaunchExe(appDir)
    if exePath != "" {
        Run exePath
    }

    lastWriteTick := A_TickCount
    isRestarting := false
}

; --- Находит EXE для запуска в appDir ---
; Подход: берём "лучший кандидат" по эвристике:
; - исключаем uninstall/updater/helper/crash и т.п.
; - берём самый "свежий" по времени модификации (или самый большой — можно переключить)
FindLaunchExe(dir) {
    bestPath := ""
    bestScore := -1

    ; Рекурсивно: если EXE может лежать в подпапках — оставь "R"
    Loop Files dir "\*.exe" {
        p := A_LoopFileFullPath
        name := StrLower(A_LoopFileName)

        ; фильтры-исключения (подстрой под свой софт)
        if InStr(name, "unins") || InStr(name, "uninstall")
            || InStr(name, "update") || InStr(name, "updater")
            || InStr(name, "helper") || InStr(name, "crash")
            || InStr(name, "cef") || InStr(name, "chromium") {
            continue
        }

        ; Эвристика скоринга:
        ; 1) Чем свежее файл — тем выше балл
        ; 2) Чем больше размер — тем выше балл (с небольшим весом)
        m := FileGetTime(p, "M")
        s := FileGetSize(p)

        score := (m / 10000000000) + (s / 1000000000)  ; грубая нормализация
        if (score > bestScore) {
            bestScore := score
            bestPath := p
        }
    }

    return bestPath
}

; --- Завершает процессы, у которых ExecutablePath начинается с appDir ---
KillProcessesInDir(dir) {
    dir := RTrim(dir, "\") "\"
    wmi := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")

    ; Берём все процессы с путём (ExecutablePath может быть пустым для системных процессов)
    for p in wmi.ExecQuery("SELECT ProcessId, ExecutablePath, Name FROM Win32_Process") {
        try {
            path := p.ExecutablePath
            if !path
                continue

            ; сравнение без учёта регистра
            if (SubStr(StrLower(path), 1, StrLen(StrLower(dir))) = StrLower(dir)) {
                ; мягко попросить завершиться можно через p.Terminate()
                p.Terminate()
            }
        }
    }
}
