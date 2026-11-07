@echo off
title Servidor Web Local - Objecion Codigo de Honor
echo ===============================================================
echo   SERVIDOR WEB HTML5 - ¡OBJECION! CODIGO DE HONOR
echo   Escuchando de forma segura solo en http://127.0.0.1:8080
echo ===============================================================
start "" "http://127.0.0.1:8080"
python -m http.server 8080 --bind 127.0.0.1 --directory "%~dp0builds\web"
pause
