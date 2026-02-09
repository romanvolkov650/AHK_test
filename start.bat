@echo off
setlocal enabledelayedexpansion

:: Перейти в директорию скрипта
cd /d "%~dp0"

:: Найти первый .exe файл в текущей папке
for %%f in (*.exe) do (
    set "exeFile=%%f"
    goto :run
)

echo [!] .exe файл не найден
exit /b

:run
echo Start !exeFile!
start "" "!exeFile!"
