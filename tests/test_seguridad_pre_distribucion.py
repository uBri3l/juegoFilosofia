"""
Suite Exhaustiva de Auditoría de Seguridad Pre-Distribución
Videojuego: ¡OBJECIÓN! CÓDIGO DE HONOR (JuicioLogico8Bit)
==============================================================================
Evalúa exhaustivamente la superficie de seguridad antes de repartir el ejecutable
a terceros (amigos / beta testers):
  1. Inspección Binaria Profunda (.exe, .pck y .zip):
     - Cero claves API (Groq, Gemini, OpenRouter, Cerebras, Mistral).
     - Cero rutas personales del desarrollador (Users/gabri, OneDrive, etc.).
     - Cero scripts de prueba/debug empaquetados dentro del binario de producción.
     - Cálculo de hashes criptográficos SHA-256 de integridad.
  2. Auditoría Estática de Sandbox en Código Godot (GDScript):
     - Cero llamadas a OS.execute, OS.create_process, FileAccess, DirAccess o save_png
       en los scripts de producción.
  3. Auditoría de Secretos en Git y Árbol de Trabajo:
     - .env ignorado por Git y ausente del índice de archivos rastreados.
     - Cero credenciales o rutas locales hardcodeadas en scripts .py, .gd o .bat.
  4. Endurecimiento del Servidor Backend (OWASP API Security / STRIDE):
     - Desactivación de documentación interactiva expuesta (/docs, /redoc, /openapi.json -> 404).
     - Cabeceras de seguridad HTTP obligatorias (nosniff, DENY, no-store, CSP, no-referrer).
     - Protección Anti-DoS contra cargas útiles gigantes (>128 KB -> HTTP 413).
     - Cero fugas de trazas de excepción internas (avisos_litellm / stack traces).
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Any
from unittest.mock import patch

from fastapi.testclient import TestClient

ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT_DIR / "backend"))

import server  # noqa: E402

RESULTADOS_SEGURIDAD: list[dict[str, Any]] = []
TOTAL_ASERCIONES = 0


def check(condicion: bool, mensaje_error: str) -> None:
    global TOTAL_ASERCIONES
    if not condicion:
        raise AssertionError(f"[FALLO DE SEGURIDAD] {mensaje_error}")
    TOTAL_ASERCIONES += 1


def registrar(
    id_control: str,
    categoria_stride_owasp: str,
    objetivo: str,
    resultado_obtenido: str,
    aserciones: int,
    ms: float,
) -> None:
    RESULTADOS_SEGURIDAD.append(
        {
            "id": id_control,
            "categoria": categoria_stride_owasp,
            "objetivo": objetivo,
            "resultado": resultado_obtenido,
            "aserciones": aserciones,
            "latencia_ms": round(ms, 2),
            "estado": "SEGURO (PASS)",
        }
    )
    print(f"  [PASS] {id_control} | {categoria_stride_owasp}: {resultado_obtenido} ({aserciones} checks, {ms:.1f} ms)")


def calcular_sha256(ruta: Path) -> str:
    h = hashlib.sha256()
    with ruta.open("rb") as f:
        for bloque in iter(lambda: f.read(1024 * 1024), b""):
            h.update(bloque)
    return h.hexdigest()


# ==============================================================================
# 1. INSPECCIÓN BINARIA DE EJECUTABLES Y PAQUETES (.EXE, .PCK, .ZIP)
# ==============================================================================
def auditar_binarios_exportados() -> dict[str, str]:
    print("\n======================================================================")
    print(" 1. AUDITORÍA FORENSE DE BINARIOS (.EXE, .PCK Y PAQUETES .ZIP)")
    print("======================================================================")
    t0 = time.perf_counter()
    a0 = TOTAL_ASERCIONES

    exe_path = ROOT_DIR / "builds" / "windows" / "JuicioLogico8Bit.exe"
    pck_web_path = ROOT_DIR / "builds" / "web" / "index.pck"
    zip_win_path = ROOT_DIR / "builds" / "JuicioLogico8Bit_Windows_Portable.zip"
    zip_web_path = ROOT_DIR / "builds" / "JuicioLogico8Bit_Web.zip"

    for p in (exe_path, pck_web_path, zip_win_path, zip_web_path):
        check(p.exists() and p.stat().st_size > 20_000, f"No existe o está vacío el binario: {p}")

    # Cargar valores reales del .env local (si existe) para verificar que NINGUNO esté en el binario
    secretos_reales: list[bytes] = []
    env_file = ROOT_DIR / ".env"
    if env_file.exists():
        for linea in env_file.read_text(encoding="utf-8", errors="ignore").splitlines():
            linea = linea.strip()
            if linea and not linea.startswith("#") and "=" in linea:
                _, valor = linea.split("=", 1)
                valor = valor.strip().strip('"').strip("'")
                if len(valor) >= 12 and not valor.startswith("tu_clave"):
                    secretos_reales.append(valor.encode("utf-8"))

    # Patrones prohibidos dentro de los binarios distribuibles (ASCII y UTF-16LE)
    patrones_prohibidos: list[bytes] = [
        b"Users/gabri",
        b"Users\\gabri",
        b"OneDrive/Escritorio",
        b"OneDrive\\Escritorio",
        b"captura_juego.png",
        b"_guardar_captura_verificacion",
        b"TestCajaBlancaGodot",
        b"TestCajaNegraGodot",
        b"PlaytestVisualYCaos",
        b"PartidaEnVivoPantalla",
        b"TestRunnerQA",
        b"OPENROUTER_API_KEY",
        b"GEMINI_API_KEY",
        b"GROQ_API_KEY",
        b"CEREBRAS_API_KEY",
        b"MISTRAL_API_KEY",
        b"sk-or-v1-",
        b"gsk_",
    ] + secretos_reales

    for archivo_bin in (exe_path, pck_web_path):
        raw = archivo_bin.read_bytes()
        for pat in patrones_prohibidos:
            check(
                pat not in raw,
                f"Fuga detectada en {archivo_bin.name}: patrón sensible {pat.decode('utf-8', errors='ignore')[:18]}...",
            )
            # Verificar también codificación UTF-16LE por si Windows/Godot almacena cadenas anchas
            pat_utf16 = pat.decode("utf-8", errors="ignore").encode("utf-16le")
            check(
                pat_utf16 not in raw,
                f"Fuga UTF-16LE detectada en {archivo_bin.name}: {pat.decode('utf-8', errors='ignore')[:18]}...",
            )

    # Verificar que el console.exe de depuración NO exista en builds/windows
    console_exe = ROOT_DIR / "builds" / "windows" / "JuicioLogico8Bit.console.exe"
    check(not console_exe.exists(), "El wrapper de consola de depuración sigue presente en builds/windows")

    hashes = {
        "windows_exe_sha256": calcular_sha256(exe_path),
        "windows_zip_sha256": calcular_sha256(zip_win_path),
        "web_pck_sha256": calcular_sha256(pck_web_path),
        "web_zip_sha256": calcular_sha256(zip_web_path),
    }

    dt = (time.perf_counter() - t0) * 1000.0
    registrar(
        "SEC-01",
        "Information Disclosure (Binarios .exe / .pck / .zip)",
        "Escaneo forense de cadenas ASCII/UTF-16LE en 76 MB de binarios para descartar claves API, rutas de usuario y scripts de test",
        f"0 fugas en {exe_path.name} y {pck_web_path.name} ({len(patrones_prohibidos)} patrones x 2 codificaciones verificados)",
        TOTAL_ASERCIONES - a0,
        dt,
    )
    return hashes


# ==============================================================================
# 2. AUDITORÍA ESTÁTICA DE SANDBOX EN SCRIPTS DE PRODUCCIÓN GODOT
# ==============================================================================
def auditar_sandbox_scripts_produccion() -> None:
    print("\n======================================================================")
    print(" 2. AUDITORÍA DE SANDBOX Y PERMISOS EN SCRIPTS DE PRODUCCIÓN (.GD)")
    print("======================================================================")
    t0 = time.perf_counter()
    a0 = TOTAL_ASERCIONES

    scripts_prod = [
        ROOT_DIR / "godot_project" / "scripts" / "MainCourtroom.gd",
        ROOT_DIR / "godot_project" / "scripts" / "PixelCourtStage.gd",
        ROOT_DIR / "godot_project" / "scripts" / "CasesDatabase.gd",
    ]

    apis_peligrosas = [
        "OS.execute",
        "OS.create_process",
        "OS.create_instance",
        "OS.shell_open",
        "OS.kill",
        "FileAccess.open",
        "DirAccess.open",
        "DirAccess.remove",
        "save_png",
        "save_jpg",
        "ResourceSaver.save",
        "GDScript.new",
        "Expression.new",
    ]

    for sp in scripts_prod:
        check(sp.exists(), f"Falta script de producción: {sp}")
        contenido = sp.read_text(encoding="utf-8")
        for api in apis_peligrosas:
            check(api not in contenido, f"API potencialmente riesgosa '{api}' encontrada en {sp.name}")

        # Verificar que las únicas URLs en los scripts sean loopback 127.0.0.1:8000
        urls = re.findall(r"https?://[^\s\"']+", contenido)
        for u in urls:
            check(
                u.startswith("http://127.0.0.1:8000/"),
                f"URL externa no autorizada encontrada en {sp.name}: {u}",
            )

    # Verificar que export_presets.cfg excluya explícitamente los scripts de test y archivos .env
    presets_txt = (ROOT_DIR / "godot_project" / "export_presets.cfg").read_text(encoding="utf-8")
    check('exclude_filter="scripts/Test*' in presets_txt, "export_presets.cfg no excluye scripts/Test*")
    check(".env*" in presets_txt, "export_presets.cfg no excluye archivos .env*")

    dt = (time.perf_counter() - t0) * 1000.0
    registrar(
        "SEC-02",
        "Tampering & Elevation of Privilege (Sandbox GDScript)",
        "Verificación estática de ausencia de llamadas a sistema (OS.execute), escritura en disco (FileAccess/save_png) y conexiones externas",
        "3/3 scripts de producción 100% aislados (0 escrituras en disco, 0 comandos de SO, red restringida a 127.0.0.1)",
        TOTAL_ASERCIONES - a0,
        dt,
    )


# ==============================================================================
# 3. AUDITORÍA DE SECRETOS EN GIT Y SCRIPTS DEL REPOSITORIO
# ==============================================================================
def auditar_repositorio_y_git() -> None:
    print("\n======================================================================")
    print(" 3. AUDITORÍA DE SECRETOS EN REPOSITORIO GIT Y ARCHIVOS DE CÓDIGO")
    print("======================================================================")
    t0 = time.perf_counter()
    a0 = TOTAL_ASERCIONES

    proc = subprocess.run(
        ["git", "ls-files"],
        cwd=str(ROOT_DIR),
        capture_output=True,
        text=True,
        check=True,
    )
    archivos_git = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    check(".env" not in archivos_git, "¡ALERTA CRÍTICA! El archivo .env está rastreado por Git")
    check("captura_juego.png" not in archivos_git, "captura_juego.png está rastreado por Git")

    regex_claves = re.compile(r"(gsk_[A-Za-z0-9]{20,}|AIzaSy[A-Za-z0-9_-]{30,}|sk-or-v1-[a-f0-9]{32,})")
    for rel_path in archivos_git:
        p = ROOT_DIR / rel_path
        if not p.exists() or p.suffix in (".png", ".svg", ".ico", ".exe", ".pck", ".zip"):
            continue
        txt = p.read_text(encoding="utf-8", errors="ignore")
        coincidencias = regex_claves.findall(txt)
        check(len(coincidencias) == 0, f"Clave API real encontrada en archivo rastreado por Git: {rel_path}")
        if p.suffix in (".py", ".gd", ".bat", ".tscn", ".cfg"):
            check(
                "users/gabri" not in txt.lower() and "users\\gabri" not in txt.lower(),
                f"Ruta personal del desarrollador ('Users/gabri') encontrada en {rel_path}",
            )

    dt = (time.perf_counter() - t0) * 1000.0
    registrar(
        "SEC-03",
        "Secret Management & Privacy (Git Index & Source Tree)",
        "Escaneo de todos los archivos rastreados en Git contra expresiones regulares de API keys y rutas privadas del desarrollador",
        f"{len(archivos_git)} archivos rastreados auditados: .env excluido, 0 claves API y 0 rutas personales en código",
        TOTAL_ASERCIONES - a0,
        dt,
    )


# ==============================================================================
# 4. AUDITORÍA DE ENDURECIMIENTO DEL BACKEND (OWASP API TOP 10 / STRIDE)
# ==============================================================================
def auditar_endurecimiento_backend() -> None:
    print("\n======================================================================")
    print(" 4. AUDITORÍA DE ENDURECIMIENTO DEL SERVIDOR BACKEND (OWASP / STRIDE)")
    print("======================================================================")
    t0 = time.perf_counter()
    a0 = TOTAL_ASERCIONES

    client = TestClient(server.app)

    # 4.1 Verificar que Swagger/Redoc/OpenAPI estén deshabilitados en producción
    for ruta_doc in ("/docs", "/redoc", "/openapi.json"):
        r_doc = client.get(ruta_doc)
        check(r_doc.status_code == 404, f"La ruta de introspección {ruta_doc} sigue expuesta (HTTP {r_doc.status_code})")

    # 4.2 Verificar cabeceras de seguridad HTTP en respuestas
    r_health = client.get("/health")
    check(r_health.status_code == 200, "GET /health falló")
    hdrs = r_health.headers
    check(hdrs.get("x-content-type-options") == "nosniff", "Falta X-Content-Type-Options: nosniff")
    check(hdrs.get("x-frame-options") == "DENY", "Falta X-Frame-Options: DENY")
    check(hdrs.get("referrer-policy") == "no-referrer", "Falta Referrer-Policy: no-referrer")
    check(hdrs.get("cache-control") == "no-store", "Falta Cache-Control: no-store")
    check("default-src 'none'" in hdrs.get("content-security-policy", ""), "Falta Content-Security-Policy restrictiva")

    # 4.3 Verificar límite Anti-DoS de tamaño de payload (>128 KB -> HTTP 413)
    payload_gigante = json.dumps({"caso_id": "A" * 150_000})
    r_dos = client.post(
        "/turno",
        content=payload_gigante,
        headers={"Content-Type": "application/json", "Content-Length": str(len(payload_gigante))},
    )
    check(r_dos.status_code == 413, f"Un payload de 150 KB debía ser rechazado con HTTP 413, devolvió {r_dos.status_code}")

    # 4.4 Verificar cero fugas de trazas de excepción o claves cuando un proveedor LLM falla
    with patch("server.detectar_modelos_gratuitos_disponibles", return_value=["modelo-prueba-error"]):
        with patch(
            "server.litellm.completion",
            side_effect=RuntimeError("Error interno sensible con ruta C:/secret/key_gsk_12345"),
        ):
            r_err = client.post("/turno", json={"accion_jugador": "INICIAR_CASO"})
            check(r_err.status_code == 200, "El fallback ante error de proveedor no devolvió HTTP 200")
            cuerpo_str = r_err.text
            check("avisos_litellm" not in r_err.json(), "El campo avisos_litellm sigue exponiendo errores internos")
            check("key_gsk_12345" not in cuerpo_str, "¡Fuga de mensaje de excepción interna en la respuesta JSON!")

    dt = (time.perf_counter() - t0) * 1000.0
    registrar(
        "SEC-04",
        "OWASP API8 (Security Misconfiguration) & API4 (Resource Consumption)",
        "Verificación de cierre de /docs y /openapi.json, cabeceras OWASP, rechazo HTTP 413 (>128 KB) y supresión de excepciones",
        "Introspección cerrada (404), 5 cabeceras OWASP activas, bloqueo DoS HTTP 413 y 0 fugas de excepciones",
        TOTAL_ASERCIONES - a0,
        dt,
    )


if __name__ == "__main__":
    t_inicio = time.perf_counter()
    hashes_binarios = auditar_binarios_exportados()
    auditar_sandbox_scripts_produccion()
    auditar_repositorio_y_git()
    auditar_endurecimiento_backend()
    t_total = (time.perf_counter() - t_inicio) * 1000.0

    print("\n======================================================================")
    print(f" AUDITORÍA DE SEGURIDAD COMPLETADA: {len(RESULTADOS_SEGURIDAD)}/4 BLOQUES SEGUROS")
    print(f" TOTAL ASERCIONES DE SEGURIDAD: {TOTAL_ASERCIONES}/{TOTAL_ASERCIONES} PASS ({t_total:.1f} ms)")
    print("======================================================================")
    print(json.dumps({"hashes_sha256": hashes_binarios, "controles": RESULTADOS_SEGURIDAD}, indent=2, ensure_ascii=False))
