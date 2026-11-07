@echo off
if exist "%~dp0builds\windows\JuicioLogico8Bit.exe" (
    start "" "%~dp0builds\windows\JuicioLogico8Bit.exe"
) else (
    set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
    if exist "%GODOT_EXE%" (
        "%GODOT_EXE%" --path "%~dp0godot_project"
    ) else (
        godot --path "%~dp0godot_project"
    )
)
