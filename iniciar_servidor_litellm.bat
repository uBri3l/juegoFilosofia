@echo off
title Servidor LiteLLM - Juicio Logico 8-Bit
echo ===============================================================
echo   INICIANDO MOTOR LITELLM (MODELOS GRATUITOS DE IA)
echo ===============================================================

if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo [INFO] Se creo el archivo .env a partir de .env.example.
    echo Puedes pegar tus API Keys gratuitas en el archivo .env cuando quieras.
)

if not exist ".venv" (
    echo [1/2] Creando entorno virtual de Python...
    python -m venv .venv
)

echo [2/2] Instalando/verificando dependencias (LiteLLM + FastAPI)...
call .venv\Scripts\activate
pip install -q -r backend\requirements.txt

echo.
echo ===============================================================
echo   Servidor corriendo en http://127.0.0.1:8000
echo   Ahora abre la carpeta 'godot_project' en Godot 4 y presiona F5
echo ===============================================================
python backend\server.py
pause
