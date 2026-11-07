@echo off
title Servidor Web Multi-Dispositivo (PC / Celular / Tablet)
echo ===============================================================
echo   SERVIDOR WEB HTML5 - JUICIO LOGICO 8-BIT
echo   Abre http://localhost:8080 en tu navegador o desde tu celular
echo   conectado a la misma red Wi-Fi usando la IP local de tu PC.
echo ===============================================================
start "" "http://localhost:8080"
python -m http.server 8080 --directory "%~dp0builds\web"
pause
