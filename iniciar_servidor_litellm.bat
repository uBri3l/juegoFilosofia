@echo off
title Juicio Logico 8-Bit (LiteLLM + Godot 4)
echo ===============================================================
echo   INICIANDO SERVIDOR LITELLM Y JUEGO EN GODOT 4
echo ===============================================================

if not exist ".env" (
    copy ".env.example" ".env" >nul
)

if not exist ".venv" (
    echo [1/3] Creando entorno virtual de Python...
    python -m venv .venv
    call .venv\Scripts\activate
    pip install -q -r backend\requirements.txt
) else (
    call .venv\Scripts\activate
)

echo [2/3] Abriendo ventana del juego en Godot 4...
set "GODOT_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if exist "%GODOT_EXE%" (
    start "" "%GODOT_EXE%" --path "%~dp0godot_project"
) else (
    start "" godot --path "%~dp0godot_project"
)

echo [3/3] Servidor LiteLLM escuchando en http://127.0.0.1:8000 ...
python backend\server.py
pause
