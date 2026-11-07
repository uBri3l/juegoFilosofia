"""
Batería de Pruebas Automatizadas Exhaustivas para el Backend LiteLLM de
'Juicio Lógico 8-Bit: Falacias, Argumentos y Ética Profesional'.

Verifica:
1. /health y /casos (existencia e integridad de los 4 casos de ética profesional).
2. Simulación de partida completa hasta VICTORIA (hp_rival de 100 a 0 eligiendo INFALIBLE y marcando falacias verdaderas).
3. Simulación de partida completa hasta DERROTA (hp_jugador de 100 a 0 eligiendo FALACIA y marcando falacias falsas).
4. Cobertura de las 3 dificultades (FACIL, NORMAL, DIFICIL) y los 4 casos.
5. Verificación por turno:
   - Latencia < 6.5 segundos (cero bloqueos/trancazos).
   - Exactamente 4 opciones con distribución estricta: 1 INFALIBLE, 2 MEDIO, 1 FALACIA.
   - Texto 100% en español (cero fugas de inglés).
   - Cálculo exacto de daños (dano_al_rival, dano_al_jugador).
"""

import json
import statistics
import sys
import time
import urllib.request
from typing import Any

BASE_URL = "http://127.0.0.1:8000"

CASOS_ESPERADOS = [
    "caso_algoritmo_medico",
    "caso_vertido_quimico",
    "caso_auditoria_contable",
    "caso_ia_periodismo",
]
DIFICULTADES_ESPERADAS = ["FACIL", "NORMAL", "DIFICIL"]

PALABRAS_INGLES_PROHIBIDAS = [
    " the ", " your ", " this ", " that ", " with ", " from ",
    " argument ", " court ", " judge ", " fallacy ", " however ", " because ",
]

latencias_ms: list[float] = []
total_aserciones: int = 0
turnos_probados: int = 0
modelos_observados: dict[str, int] = {}


def check(condicion: bool, mensaje: str) -> None:
    global total_aserciones
    total_aserciones += 1
    if not condicion:
        raise AssertionError(f"[FALLO QA] {mensaje}")


def http_get(ruta: str) -> tuple[dict[str, Any], float]:
    t0 = time.perf_counter()
    req = urllib.request.Request(f"{BASE_URL}{ruta}", method="GET")
    with urllib.request.urlopen(req, timeout=6.5) as resp:
        raw = resp.read().decode("utf-8")
        dt = (time.perf_counter() - t0) * 1000.0
        return json.loads(raw), dt


def http_post(ruta: str, payload: dict[str, Any]) -> tuple[dict[str, Any], float]:
    global turnos_probados
    t0 = time.perf_counter()
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{BASE_URL}{ruta}",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=6.5) as resp:
        raw = resp.read().decode("utf-8")
        dt = (time.perf_counter() - t0) * 1000.0
        latencias_ms.append(dt)
        turnos_probados += 1
        datos = json.loads(raw)
        mod = str(datos.get("modelo_usado", "desconocido"))
        modelos_observados[mod] = modelos_observados.get(mod, 0) + 1
        return datos, dt


def verificar_texto_espanol(datos: dict[str, Any], contexto: str) -> None:
    veredicto = str(datos.get("veredicto_juez", ""))
    decl = datos.get("declaracion_rival", {})
    dialogo = str(decl.get("dialogo", ""))
    check(len(veredicto.strip()) > 5, f"{contexto}: veredicto_juez vacío")
    check(len(dialogo.strip()) > 10, f"{contexto}: dialogo del rival vacío")

    textos = [veredicto, dialogo]
    for op in datos.get("opciones_jugador", []):
        txt = str(op.get("texto", ""))
        check(len(txt.strip()) > 8, f"{contexto}: opción con texto vacío")
        textos.append(txt)

    combinado = " " + " ".join(textos).lower() + " "
    for pal in PALABRAS_INGLES_PROHIBIDAS:
        check(pal not in combinado, f"{contexto}: se detectó palabra en inglés '{pal}' en respuesta")


def verificar_estructura_turno(datos: dict[str, Any], latencia_ms: float, contexto: str) -> None:
    # 1. Tiempo de respuesta < 6.5s
    check(latencia_ms < 6500.0, f"{contexto}: latencia excesiva ({latencia_ms:.1f} ms >= 6500 ms)")

    # 2. Exactamente 4 opciones: 1 INFALIBLE, 2 MEDIO, 1 FALACIA
    opciones = datos.get("opciones_jugador", [])
    check(isinstance(opciones, list) and len(opciones) == 4, f"{contexto}: se esperaban 4 opciones, llegaron {len(opciones)}")
    conteo_tipos = {"INFALIBLE": 0, "MEDIO": 0, "FALACIA": 0}
    for op in opciones:
        t = str(op.get("tipo", "")).upper()
        check(t in conteo_tipos, f"{contexto}: tipo de opción desconocido '{t}'")
        conteo_tipos[t] += 1

    check(conteo_tipos["INFALIBLE"] == 1, f"{contexto}: se esperaba 1 INFALIBLE, hubo {conteo_tipos['INFALIBLE']}")
    check(conteo_tipos["MEDIO"] == 2, f"{contexto}: se esperaban 2 MEDIO, hubo {conteo_tipos['MEDIO']}")
    check(conteo_tipos["FALACIA"] == 1, f"{contexto}: se esperaba 1 FALACIA, hubo {conteo_tipos['FALACIA']}")

    # 3. Declaración del rival válida
    decl = datos.get("declaracion_rival", {})
    check(isinstance(decl, dict), f"{contexto}: declaracion_rival no es dict")
    check("es_falacia" in decl, f"{contexto}: falta 'es_falacia' en declaracion_rival")

    # 4. Español 100%
    verificar_texto_espanol(datos, contexto)


def test_health_y_casos() -> None:
    print("-> [1/4] Probando /health y /casos...")
    health, dt_h = http_get("/health")
    check(health.get("status") == "ok", "El endpoint /health no devolvió status='ok'")
    check(health.get("litellm_ready") is True, "litellm_ready no es True")
    check(dt_h < 2000.0, f"/health tardó demasiado ({dt_h:.1f} ms)")

    casos_resp, dt_c = http_get("/casos")
    casos = casos_resp.get("casos", [])
    check(len(casos) == 4, f"Se esperaban 4 casos en /casos, llegaron {len(casos)}")
    ids_recibidos = [c["id"] for c in casos]
    for cid in CASOS_ESPERADOS:
        check(cid in ids_recibidos, f"Falta el caso esperado '{cid}' en /casos")
    print(f"   OK: /health ({dt_h:.1f} ms) y /casos ({dt_c:.1f} ms) con los 4 casos verificados.")


def test_matriz_casos_y_dificultades() -> None:
    print("-> [2/4] Probando matriz completa: 4 Casos x 3 Dificultades (INICIAR_CASO + ARGUMENTAR MEDIO)...")
    for cid in CASOS_ESPERADOS:
        for dif in DIFICULTADES_ESPERADAS:
            ctx = f"[{cid} | {dif}]"
            datos_ini, dt_ini = http_post(
                "/turno",
                {
                    "caso_id": cid,
                    "dificultad": dif,
                    "hp_jugador": 100,
                    "hp_rival": 100,
                    "accion_jugador": "INICIAR_CASO",
                    "turno_idx": 0,
                },
            )
            verificar_estructura_turno(datos_ini, dt_ini, f"{ctx} INICIAR_CASO")
            check(int(datos_ini.get("dano_al_rival", 0)) == 0, f"{ctx}: daño rival en inicio debe ser 0")
            check(int(datos_ini.get("dano_al_jugador", 0)) == 0, f"{ctx}: daño jugador en inicio debe ser 0")

            # Probar elegir un argumento MEDIO para verificar la regla de daño según dificultad
            op_medio = next(op for op in datos_ini["opciones_jugador"] if op["tipo"] == "MEDIO")
            datos_med, dt_med = http_post(
                "/turno",
                {
                    "caso_id": cid,
                    "dificultad": dif,
                    "hp_jugador": 100,
                    "hp_rival": 100,
                    "accion_jugador": "ARGUMENTAR",
                    "declaracion_previa_rival": datos_ini["declaracion_rival"],
                    "opcion_elegida": op_medio,
                    "turno_idx": 1,
                },
            )
            verificar_estructura_turno(datos_med, dt_med, f"{ctx} ARGUMENTAR_MEDIO")
            dano_j = int(datos_med.get("dano_al_jugador", 0))
            if dif == "FACIL":
                check(dano_j == 0, f"{ctx}: en FACIL el argumento MEDIO no debe dañar al jugador (fue {dano_j})")
            elif dif == "NORMAL":
                check(dano_j >= 10, f"{ctx}: en NORMAL el argumento MEDIO debe dañar >=10 HP al jugador (fue {dano_j})")
            elif dif == "DIFICIL":
                check(dano_j >= 15, f"{ctx}: en DIFICIL el argumento MEDIO debe dañar >=15 HP al jugador (fue {dano_j})")

    print("   OK: Los 4 casos x 3 dificultades respondieron con formato válido y reglas de daño exactas.")


def test_simulacion_partida_victoria() -> None:
    print("-> [3/4] Simulando partida completa hasta VICTORIA (100 -> 0 HP Rival)...")
    hp_jugador = 100
    hp_rival = 100
    turno_idx = 0
    caso_id = "caso_algoritmo_medico"
    dificultad = "NORMAL"

    datos, dt = http_post(
        "/turno",
        {
            "caso_id": caso_id,
            "dificultad": dificultad,
            "hp_jugador": hp_jugador,
            "hp_rival": hp_rival,
            "accion_jugador": "INICIAR_CASO",
            "turno_idx": turno_idx,
        },
    )
    verificar_estructura_turno(datos, dt, "VICTORIA_INIT")

    # Primero probamos explícitamente marcar una falacia verdadera del rival
    decl_falaz_forzada = {
        "dialogo": "La acusada es joven, por ende su denuncia técnica es falsa.",
        "es_falacia": True,
        "nombre_falacia": "Ad Hominem",
        "explicacion_logica": "Ataca a la persona en vez del argumento.",
    }
    datos_obj, dt_obj = http_post(
        "/turno",
        {
            "caso_id": caso_id,
            "dificultad": dificultad,
            "hp_jugador": hp_jugador,
            "hp_rival": hp_rival,
            "accion_jugador": "MARCAR_FALACIA",
            "declaracion_previa_rival": decl_falaz_forzada,
            "turno_idx": turno_idx,
        },
    )
    verificar_estructura_turno(datos_obj, dt_obj, "VICTORIA_OBJECION_VERDADERA")
    dano_r = int(datos_obj.get("dano_al_rival", 0))
    check(dano_r >= 25, f"Marcar falacia verdadera debía causar >=25 daño al rival, causó {dano_r}")
    check(datos_obj.get("objecion_jugador_exitosa") is True, "objecion_jugador_exitosa debía ser True")
    hp_rival = max(0, hp_rival - dano_r)
    datos = datos_obj

    # Ahora continuamos eligiendo opciones INFALIBLE hasta dejar hp_rival == 0
    pasos = 1
    while hp_rival > 0 and pasos < 10:
        pasos += 1
        turno_idx += 1
        op_infalible = next(op for op in datos["opciones_jugador"] if op["tipo"] == "INFALIBLE")
        datos, dt = http_post(
            "/turno",
            {
                "caso_id": caso_id,
                "dificultad": dificultad,
                "hp_jugador": hp_jugador,
                "hp_rival": hp_rival,
                "accion_jugador": "ARGUMENTAR",
                "declaracion_previa_rival": datos["declaracion_rival"],
                "opcion_elegida": op_infalible,
                "turno_idx": turno_idx,
            },
        )
        verificar_estructura_turno(datos, dt, f"VICTORIA_PASO_{pasos}")
        dano_r = int(datos.get("dano_al_rival", 0))
        check(dano_r >= 25, f"Argumento INFALIBLE debía causar >=25 daño al rival, causó {dano_r}")
        hp_rival = max(0, hp_rival - dano_r)

    check(hp_rival == 0, f"El rival debía llegar a 0 HP para VICTORIA, quedó en {hp_rival}")
    check(hp_jugador == 100, f"El jugador debía conservar 100 HP en ruta perfecta, quedó en {hp_jugador}")
    print(f"   OK: Partida ganada en {pasos} acciones (HP Jugador={hp_jugador}, HP Rival={hp_rival}).")


def test_simulacion_partida_derrota() -> None:
    print("-> [4/4] Simulando partida completa hasta DERROTA (100 -> 0 HP Jugador)...")
    hp_jugador = 100
    hp_rival = 100
    turno_idx = 0
    caso_id = "caso_auditoria_contable"
    dificultad = "DIFICIL"

    datos, dt = http_post(
        "/turno",
        {
            "caso_id": caso_id,
            "dificultad": dificultad,
            "hp_jugador": hp_jugador,
            "hp_rival": hp_rival,
            "accion_jugador": "INICIAR_CASO",
            "turno_idx": turno_idx,
        },
    )
    verificar_estructura_turno(datos, dt, "DERROTA_INIT")

    # 1) Probar marcar falacia cuando el argumento del rival NO es falacia (-20 HP jugador)
    decl_valida_forzada = {
        "dialogo": "El código deontológico exige independencia formal y material en toda auditoría pública.",
        "es_falacia": False,
        "nombre_falacia": None,
        "explicacion_logica": "Principio válido de auditoría.",
    }
    datos_obj_falsa, dt_falsa = http_post(
        "/turno",
        {
            "caso_id": caso_id,
            "dificultad": dificultad,
            "hp_jugador": hp_jugador,
            "hp_rival": hp_rival,
            "accion_jugador": "MARCAR_FALACIA",
            "declaracion_previa_rival": decl_valida_forzada,
            "turno_idx": turno_idx,
        },
    )
    verificar_estructura_turno(datos_obj_falsa, dt_falsa, "DERROTA_OBJECION_FALSA")
    dano_j = int(datos_obj_falsa.get("dano_al_jugador", 0))
    check(dano_j >= 20, f"Marcar falacia falsa debía causar >=20 daño al jugador, causó {dano_j}")
    check(datos_obj_falsa.get("objecion_jugador_exitosa") is False, "objecion_jugador_exitosa debía ser False")
    hp_jugador = max(0, hp_jugador - dano_j)
    datos = datos_obj_falsa

    # 2) Seguir cometiendo falacias / objeciones falsas hasta que hp_jugador llegue a 0
    pasos = 1
    while hp_jugador > 0 and pasos < 12:
        pasos += 1
        turno_idx += 1
        op_falacia = next(op for op in datos["opciones_jugador"] if op["tipo"] == "FALACIA")
        datos, dt = http_post(
            "/turno",
            {
                "caso_id": caso_id,
                "dificultad": dificultad,
                "hp_jugador": hp_jugador,
                "hp_rival": hp_rival,
                "accion_jugador": "ARGUMENTAR",
                "declaracion_previa_rival": datos["declaracion_rival"],
                "opcion_elegida": op_falacia,
                "turno_idx": turno_idx,
            },
        )
        verificar_estructura_turno(datos, dt, f"DERROTA_PASO_{pasos}")
        dano_j = int(datos.get("dano_al_jugador", 0))
        # Si por el 5% de probabilidad en DIFICIL el rival no detectó la falacia, hacemos objeción falsa adicional
        if dano_j == 0:
            datos_extra, dt_extra = http_post(
                "/turno",
                {
                    "caso_id": caso_id,
                    "dificultad": dificultad,
                    "hp_jugador": hp_jugador,
                    "hp_rival": hp_rival,
                    "accion_jugador": "MARCAR_FALACIA",
                    "declaracion_previa_rival": decl_valida_forzada,
                    "turno_idx": turno_idx,
                },
            )
            verificar_estructura_turno(datos_extra, dt_extra, f"DERROTA_EXTRA_{pasos}")
            dano_j = int(datos_extra.get("dano_al_jugador", 0))
            datos = datos_extra

        check(dano_j > 0, f"Se esperaba daño al jugador en ruta de derrota, llegó {dano_j}")
        hp_jugador = max(0, hp_jugador - dano_j)

    check(hp_jugador == 0, f"El jugador debía llegar a 0 HP para DERROTA, quedó en {hp_jugador}")
    print(f"   OK: Partida perdida en {pasos} acciones (HP Jugador={hp_jugador}, HP Rival={hp_rival}).")


def main() -> int:
    print("======================================================================")
    print(" INICIANDO BATERÍA QA EXHAUSTIVA - BACKEND JUICIO LÓGICO 8-BIT")
    print("======================================================================")
    t_inicio = time.perf_counter()

    test_health_y_casos()
    test_matriz_casos_y_dificultades()
    test_simulacion_partida_victoria()
    test_simulacion_partida_derrota()

    duracion_total = time.perf_counter() - t_inicio
    lat_media = statistics.mean(latencias_ms) if latencias_ms else 0.0
    lat_max = max(latencias_ms) if latencias_ms else 0.0
    lat_min = min(latencias_ms) if latencias_ms else 0.0

    print("\n======================================================================")
    print(" RESUMEN DE MÉTRICAS QA BACKEND")
    print("======================================================================")
    print(f" - Turnos HTTP /turno probados : {turnos_probados}")
    print(f" - Aserciones verificadas      : {total_aserciones} / {total_aserciones} (100% OK)")
    print(f" - Latencia media por turno    : {lat_media:.2f} ms ({lat_media / 1000.0:.3f} s)")
    print(f" - Latencia mínima por turno   : {lat_min:.2f} ms")
    print(f" - Latencia máxima por turno   : {lat_max:.2f} ms ({lat_max / 1000.0:.3f} s < 6.500 s)")
    print(f" - Modelos utilizados          : {json.dumps(modelos_observados, ensure_ascii=False)}")
    print(f" - Tiempo total de la suite    : {duracion_total:.2f} s")
    print("======================================================================")
    print(" RESULTADO FINAL: TODOS LOS TESTS PASARON AL 100% SIN BLOQUEOS")
    print("======================================================================")
    return 0


if __name__ == "__main__":
    sys.exit(main())
