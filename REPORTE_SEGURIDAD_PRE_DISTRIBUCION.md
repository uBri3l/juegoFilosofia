# 🔒 Reporte de Evaluación y Endurecimiento de Seguridad Pre-Distribución

**Videojuego:** `⚖️ ¡OBJECIÓN! CÓDIGO DE HONOR ⚖️` (*Crónicas del Estrado*)  
**Versión auditada:** `v1.2.0` (Build de Distribución Cerrada para Amigos / Beta Testers)  
**Suite de verificación automatizada:** [`tests/test_seguridad_pre_distribucion.py`](tests/test_seguridad_pre_distribucion.py) (`196/196` aserciones de seguridad `PASS`)

---

## 1. Resumen Ejecutivo: Elementos Cerrados, Eliminados y Blindados

Antes de compartir el ejecutable con amigos para pruebas externas, se realizó una limpieza forense y un endurecimiento completo de toda la superficie del sistema (binarios compilados, scripts GDScript, entorno operativo y servidor backend):

1. **Cierre de Procesos, Servidores y Tareas Programadas de Prueba:**
   - Se detuvo el servidor en segundo plano (`backend/server.py`) y cualquier instancia abierta de `JuicioLogico8Bit.exe` / `Godot`.
   - Se desregistraron y eliminaron del Programador de Tareas de Windows todas las tareas temporales creadas durante el testing visual (`ProbarExeAutonomoJuicio`, `JugarExeEnEscritorio`, `ClicEnExeAbierto`, `AbrirJuicioLogico8Bit`).
   - Se eliminaron del árbol de proyecto las capturas temporales de depuración (`captura_juego.png`, `capturas_playtest/`, `capturas_partida_real/`) y el ejecutable auxiliar de consola de depuración (`JuicioLogico8Bit.console.exe`).

2. **Eliminación de Rutas Personales y Escrituras en Disco en [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd):**
   - **Hallazgo Crítico Corregido:** El método de depuración `_guardar_captura_verificacion()` en [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd) contenía la ruta absoluta del equipo del desarrollador (`c:/Users/gabri/OneDrive/.../captura_juego.png`) e intentaba guardar un PNG en disco en cada turno.
   - **Mitigación:** Se eliminó por completo `_guardar_captura_verificacion()` y sus invocaciones. También se reemplazaron las rutas absolutas en [`jugar_ahora.bat`](jugar_ahora.bat), [`PlaytestVisualYCaos.gd`](godot_project/scripts/PlaytestVisualYCaos.gd) y [`PartidaEnVivoPantalla.gd`](godot_project/scripts/PartidaEnVivoPantalla.gd) por rutas relativas dinámicas (`%~dp0` y `ProjectSettings.globalize_path`).

3. **Exclusión Estricta de Scripts de QA/Testing del Ejecutable (`.exe` y `.pck`):**
   - **Hallazgo Medio Corregido:** La configuración previa de exportación incluía dentro del binario `.exe` y `.pck` los scripts de pruebas (`TestCajaBlancaGodot.gdc`, `TestCajaNegraGodot.gdc`, `PlaytestVisualYCaos.gdc`, `PartidaEnVivoPantalla.gdc`, `TestRunnerQA.gdc`).
   - **Mitigación:** Se configuró en [`export_presets.cfg`](godot_project/export_presets.cfg) la regla `exclude_filter="scripts/Test*, scripts/Playtest*, scripts/PartidaEnVivo*, *.md, .env*, *.env"`. El empaquetado final (`savepack`) incluye **únicamente** los 3 scripts de producción:
     - [`CasesDatabase.gd`](godot_project/scripts/CasesDatabase.gd)
     - [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd)
     - [`PixelCourtStage.gd`](godot_project/scripts/PixelCourtStage.gd)

4. **Endurecimiento del Servidor Local ([`backend/server.py`](backend/server.py)) y Servidor Web Local ([`abrir_version_web_local.bat`](abrir_version_web_local.bat)):**
   - **Cierre de Introspección Pública:** Se deshabilitaron las rutas interactivas `/docs`, `/redoc` y `/openapi.json` (`HTTP 404`).
   - **Supresión de Trazas Internas:** Se eliminó el campo `avisos_litellm` de la respuesta de `POST /turno` para que nunca se filtren mensajes crudos de excepción de proveedores al cliente.
   - **Protección Anti-DoS y Sanitización de Fronteras:** Se añadió `middleware_seguridad_http` en [`backend/server.py`](backend/server.py) que rechaza cargas útiles mayores a `128 KB` con `HTTP 413 Payload Too Large`, acota `hp_jugador`/`hp_rival` a `[0, 100]` y recorta el historial enviado al prompt.
   - **Cabeceras de Seguridad OWASP:** Todas las respuestas HTTP incluyen `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Cache-Control: no-store` y `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'`.
   - **Binding Exclusivo a Loopback:** Tanto [`backend/server.py`](backend/server.py) (`127.0.0.1:8000`) como [`abrir_version_web_local.bat`](abrir_version_web_local.bat) (`--bind 127.0.0.1`) escuchan exclusivamente en la interfaz local de bucle invertido, impidiendo accesos no autorizados desde redes Wi-Fi públicas.

---

## 2. Evaluación Exhaustiva de Amenazas (Modelo STRIDE & OWASP)

| ID Control | Categoría STRIDE / OWASP | Superficie Evaluada | Prueba Ejecutada | Aserciones | Estado |
| :--- | :--- | :--- | :--- | :---: | :---: |
| **`SEC-01`** | **Information Disclosure** *(Fuga de Información en Binarios)* | `JuicioLogico8Bit.exe` (109 MB) e `index.pck` (45 KB) | Escaneo forense byte a byte en codificación `ASCII`/`UTF-8` y `UTF-16LE` buscando claves reales de `.env`, prefijos (`gsk_`, `sk-or-v1-`, `AIza`), nombres de variables (`*_API_KEY`), rutas personales (`Users/gabri`, `OneDrive`) y nombres de scripts de prueba (`Test*`, `Playtest*`). | `89 / 89` | ✅ **SEGURO** |
| **`SEC-02`** | **Tampering & Elevation of Privilege** *(Sandbox de Ejecución)* | [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd), [`PixelCourtStage.gd`](godot_project/scripts/PixelCourtStage.gd), [`CasesDatabase.gd`](godot_project/scripts/CasesDatabase.gd) | Auditoría estática AST/léxica verificando **0 llamadas** a ejecución de comandos (`OS.execute`, `OS.create_process`, `OS.shell_open`), **0 escrituras/lecturas de archivos** (`FileAccess.open`, `DirAccess`, `save_png`), **0 evaluación dinámica** (`GDScript.new`, `Expression.new`) y red restringida exclusivamente a `http://127.0.0.1:8000/`. | `46 / 46` | ✅ **SEGURO** |
| **`SEC-03`** | **Secret Management & Privacy** *(Repositorio Git y Scripts)* | Índice Git (`49` archivos rastreados) | Verificación de exclusión de `.env` y `builds/` en [`.gitignore`](.gitignore), escaneo con expresiones regulares de credenciales de proveedores cloud y verificación de ausencia total de rutas locales del desarrollador en `.py`, `.gd`, `.bat`, `.tscn` y `.cfg`. | `48 / 48` | ✅ **SEGURO** |
| **`SEC-04`** | **OWASP API4 & API8** *(Consumo de Recursos y Configuración)* | [`backend/server.py`](backend/server.py) | Verificación de cierre de `/docs`, `/redoc` y `/openapi.json` (`404`), presencia de las 5 cabeceras de seguridad OWASP, rechazo `HTTP 413` ante payloads `>128 KB` y 0 fugas de excepciones internas ante fallos de red/proveedor. | `13 / 13` | ✅ **SEGURO** |
| **TOTAL** | **4 Dominios de Seguridad** | **Binarios + Cliente + Git + API** | **Ejecución automatizada en `1.67 s`** | **`196 / 196`** | ✅ **100% PASS** |

---

## 3. Hashes Criptográficos SHA-256 de Integridad (Builds Limpias)

Puedes compartir cualquiera de los paquetes de la carpeta `builds/` con tus amigos con total tranquilidad: **no contienen ninguna clave API tuya, ninguna ruta de tu PC, ningún script de depuración y funcionan 100% sin servidor**.

| Paquete / Archivo Distribuible | Tamaño | Hash SHA-256 de Integridad |
| :--- | :---: | :--- |
| `builds/JuicioLogico8Bit_Windows_Portable.zip` *(Recomendado para enviar a amigos en PC)* | `36.3 MB` | `65d1f5f572559da7a97c52e4c957bb6f984b39da79942754e881bc224142b7d7` |
| `builds/windows/JuicioLogico8Bit.exe` *(Ejecutable autónomo único)* | `104.2 MB` | `39123c20261999472127ab8d50bca42f74fa510401ab7b4cafd01792d3ad9b55` |
| `builds/JuicioLogico8Bit_Web.zip` *(Versión HTML5 / WebAssembly para navegador/móvil)* | `9.79 MB` | `6d318bcfb1186bd14bf85fd2bb509b02c9994f4baf4da17343976f47b1a2a568` |
| `builds/web/index.pck` *(Paquete de recursos Web limpio)* | `44.0 KB` | `c1b9bfce5b3f2d01612d7b0340fcb15fbe5e733b588a6d63ba4be75d6d1e0664` |

---

## 4. Guía Rápida para Compartir con Amigos (Beta Cerrada)

1. **Qué archivo enviar:** Comparte únicamente el archivo **`builds/JuicioLogico8Bit_Windows_Portable.zip`** (o **`builds/windows/JuicioLogico8Bit.exe`**). **Nunca envíes tu archivo `.env`**; tus amigos no lo necesitan porque el ejecutable incluye el motor autónomo completo de los 4 casos éticos (`CasesDatabase.gdc`) compilado dentro del `.exe`.
2. **Aviso de Windows SmartScreen (Normal en juegos indie sin certificado comercial EV):**
   - Como el ejecutable no está firmado con un certificado comercial de pago de Microsoft (que cuesta ~$300 USD/año), la primera vez que un amigo abra `JuicioLogico8Bit.exe` descargado de Internet, Windows Defender SmartScreen puede mostrar el cartel azul *"Windows protegió su PC"*.
   - Tus amigos solo deben hacer clic en **"Más información"** y luego en **"Ejecutar de todas formas"**.
3. **Privacidad y Seguridad para tus Amigos:**
   - El juego **no escribe ningún archivo** en sus discos, **no requiere permisos de administrador**, **no envía telemetría a Internet** y al detectar en `0.5s` que no tienen servidor local encendido (punto rojo `●` discreto en la esquina superior derecha), ejecuta toda la partida de forma instantánea (`0.0s` de espera).
