"""
Suite de Pruebas de Caja Blanca (White-Box Testing) para el Backend de
'Juicio Lógico 8-Bit: Falacias, Argumentos y Ética Profesional'.

Evalúa método por método y rama por rama (cobertura de decisiones, límites y excepciones)
todos los módulos de Python:
1. backend/prompts.py
2. backend/cases_data.py
3. backend/server.py
"""

import json
import os
import random
import sys
import time
from typing import Any
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "backend")))

import cases_data
import prompts
import server

RESULTADOS_METODOS: list[dict[str, Any]] = []


def registrar_resultado(
    modulo: str,
    metodo: str,
    ramas_probadas: list[str],
    aserciones: int,
    tiempo_ms: float,
    estado: str = "PASS",
) -> None:
    RESULTADOS_METODOS.append(
        {
            "modulo": modulo,
            "metodo": metodo,
            "ramas_probadas": ramas_probadas,
            "aserciones": aserciones,
            "tiempo_ms": round(tiempo_ms, 3),
            "estado": estado,
        }
    )


def test_build_turn_user_prompt() -> None:
    t0 = time.perf_counter()
    ramas = []

    # Rama 1: historial_resumido vacío -> debe insertar "Inicio del juicio"
    p_vacio = prompts.build_turn_user_prompt(
        caso_titulo="Caso Test",
        caso_contexto="Contexto Ético Test",
        dificultad="FACIL",
        hp_jugador=100,
        hp_rival=100,
        declaracion_previa_rival={},
        accion_jugador="INICIAR_CASO",
        opcion_elegida=None,
        historial_resumido=[],
    )
    assert "Inicio del juicio" in p_vacio
    assert "Caso Test" in p_vacio
    assert "FACIL" in p_vacio
    ramas.append("Rama 1: historial_resumido vacío ('Inicio del juicio')")

    # Rama 2: historial_resumido con >4 elementos -> debe truncar a los últimos 4 ([-4:])
    hist = ["T1", "T2", "T3", "T4", "T5", "T6"]
    p_hist = prompts.build_turn_user_prompt(
        caso_titulo="Caso Test 2",
        caso_contexto="Contexto 2",
        dificultad="DIFICIL",
        hp_jugador=75,
        hp_rival=50,
        declaracion_previa_rival={"dialogo": "Test"},
        accion_jugador="ARGUMENTAR",
        opcion_elegida={"tipo": "INFALIBLE"},
        historial_resumido=hist,
    )
    assert "T1" not in p_hist and "T2" not in p_hist
    assert "T3 | T4 | T5 | T6" in p_hist
    assert "75/100" in p_hist and "50/100" in p_hist
    ramas.append("Rama 2: historial_resumido > 4 elementos (ventana deslizante [-4:])")

    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/prompts.py", "build_turn_user_prompt", ramas, 6, dt)


def test_generar_turno_respaldo_local() -> None:
    t0 = time.perf_counter()
    ramas = []
    aserciones = 0

    # Rama 1: INICIAR_CASO + caso_id inexistente (fallback a CASOS_DISPONIBLES[0])
    r_ini = cases_data.generar_turno_respaldo_local(
        caso_id="id_inexistente",
        dificultad="NORMAL",
        accion_jugador="INICIAR_CASO",
        declaracion_previa_rival=None,
        opcion_elegida=None,
        turno_idx=0,
    )
    assert r_ini["dano_al_rival"] == 0 and r_ini["dano_al_jugador"] == 0
    assert len(r_ini["opciones_jugador"]) == 4
    aserciones += 2
    ramas.append("Rama 1: INICIAR_CASO + fallback de caso_id inexistente")

    # Rama 2: MARCAR_FALACIA con es_falacia=True -> dano_al_rival=25, objecion_jugador_exitosa=True
    r_obj_ok = cases_data.generar_turno_respaldo_local(
        caso_id="caso_algoritmo_medico",
        dificultad="NORMAL",
        accion_jugador="MARCAR_FALACIA",
        declaracion_previa_rival={
            "es_falacia": True,
            "nombre_falacia": "Ad Hominem",
            "explicacion_logica": "Ataque personal.",
        },
        opcion_elegida=None,
        turno_idx=1,
    )
    assert r_obj_ok["dano_al_rival"] == 25
    assert r_obj_ok["dano_al_jugador"] == 0
    assert r_obj_ok["objecion_jugador_exitosa"] is True
    assert "¡HA LUGAR!" in r_obj_ok["veredicto_juez"]
    aserciones += 4
    ramas.append("Rama 2: MARCAR_FALACIA verdadera (-25 HP rival, objeción exitosa)")

    # Rama 3: MARCAR_FALACIA con es_falacia=False -> dano_al_jugador=20, objecion_jugador_exitosa=False
    r_obj_fail = cases_data.generar_turno_respaldo_local(
        caso_id="caso_algoritmo_medico",
        dificultad="NORMAL",
        accion_jugador="MARCAR_FALACIA",
        declaracion_previa_rival={
            "es_falacia": False,
            "explicacion_logica": "Argumento válido.",
        },
        opcion_elegida=None,
        turno_idx=1,
    )
    assert r_obj_fail["dano_al_rival"] == 0
    assert r_obj_fail["dano_al_jugador"] == 20
    assert r_obj_fail["objecion_jugador_exitosa"] is False
    assert "¡NO HA LUGAR!" in r_obj_fail["veredicto_juez"]
    aserciones += 4
    ramas.append("Rama 3: MARCAR_FALACIA falsa (-20 HP jugador, objeción rechazada)")

    # Rama 4: ARGUMENTAR con tipo="INFALIBLE"
    r_inf = cases_data.generar_turno_respaldo_local(
        caso_id="caso_vertido_quimico",
        dificultad="DIFICIL",
        accion_jugador="ARGUMENTAR",
        declaracion_previa_rival=None,
        opcion_elegida={"tipo": "INFALIBLE", "explicacion": "Deontología pura."},
        turno_idx=0,
    )
    assert r_inf["dano_al_rival"] == 25 and r_inf["dano_al_jugador"] == 0
    aserciones += 1
    ramas.append("Rama 4: ARGUMENTAR opción INFALIBLE (-25 HP rival)")

    # Rama 5, 6, 7: ARGUMENTAR con tipo="MEDIO" en FACIL (0), NORMAL (10), DIFICIL (15)
    for dif, dano_esp in [("FACIL", 0), ("NORMAL", 10), ("DIFICIL", 15)]:
        r_med = cases_data.generar_turno_respaldo_local(
            caso_id="caso_auditoria_contable",
            dificultad=dif,
            accion_jugador="ARGUMENTAR",
            declaracion_previa_rival=None,
            opcion_elegida={"tipo": "MEDIO", "explicacion": "Parcial."},
            turno_idx=0,
        )
        assert r_med["dano_al_jugador"] == dano_esp
        aserciones += 1
    ramas.append("Ramas 5-7: ARGUMENTAR opción MEDIO en FACIL (0 HP), NORMAL (-10 HP) y DIFICIL (-15 HP)")

    # Rama 8 y 9: ARGUMENTAR con tipo="FALACIA" (detectada vs no detectada usando mock de random.random)
    with patch("cases_data.random.random", return_value=0.10):
        r_fal_det = cases_data.generar_turno_respaldo_local(
            caso_id="caso_ia_periodismo",
            dificultad="FACIL",
            accion_jugador="ARGUMENTAR",
            declaracion_previa_rival=None,
            opcion_elegida={"tipo": "FALACIA", "nombre_falacia": "Ad Populum", "explicacion": "Error."},
            turno_idx=0,
        )
        assert r_fal_det["rival_detecto_falacia_jugador"] is True
        assert r_fal_det["dano_al_jugador"] == 25
        assert r_fal_det["declaracion_rival"]["tipo_argumento_rival"] == "FALACIA"
        aserciones += 3
    ramas.append("Rama 8: ARGUMENTAR FALACIA detectada por rival (-25 HP jugador) + selección rival FALACIA")

    with patch("cases_data.random.random", return_value=0.90):
        r_fal_nodet = cases_data.generar_turno_respaldo_local(
            caso_id="caso_ia_periodismo",
            dificultad="DIFICIL",
            accion_jugador="ARGUMENTAR",
            declaracion_previa_rival=None,
            opcion_elegida={"tipo": "FALACIA", "nombre_falacia": "Ad Populum", "explicacion": "Error."},
            turno_idx=0,
        )
        # En DIFICIL umbral es 0.95, probemos con 0.98 para no detectada y selección INFALIBLE
    with patch("cases_data.random.random", return_value=0.98):
        r_fal_nodet = cases_data.generar_turno_respaldo_local(
            caso_id="caso_ia_periodismo",
            dificultad="DIFICIL",
            accion_jugador="ARGUMENTAR",
            declaracion_previa_rival=None,
            opcion_elegida={"tipo": "FALACIA", "nombre_falacia": "Ad Populum", "explicacion": "Error."},
            turno_idx=0,
        )
        assert r_fal_nodet["rival_detecto_falacia_jugador"] is False
        assert r_fal_nodet["dano_al_jugador"] == 0
        assert r_fal_nodet["declaracion_rival"]["tipo_argumento_rival"] == "INFALIBLE"
        aserciones += 3
    ramas.append("Rama 9: ARGUMENTAR FALACIA no detectada (0 HP) + selección rival INFALIBLE en DIFICIL")

    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/cases_data.py", "generar_turno_respaldo_local", ramas, aserciones, dt)


def test_detectar_modelos_gratuitos_disponibles() -> None:
    t0 = time.perf_counter()
    ramas = []
    server.MODELOS_PENALIZADOS.clear()

    # Rama 1: Todas las variables activas
    env_mock = {
        "OPENROUTER_API_KEY": "k1",
        "GEMINI_API_KEY": "k2",
        "GROQ_API_KEY": "k3",
        "CEREBRAS_API_KEY": "k4",
        "MISTRAL_API_KEY": "k5",
    }
    with patch.dict(os.environ, env_mock, clear=True):
        mods = server.detectar_modelos_gratuitos_disponibles()
        assert "openrouter/cohere/north-mini-code:free" in mods
        assert "gemini/gemini-3.8-flash" in mods
        assert "groq/llama-3.3-70b-versatile" in mods
        assert "cerebras/llama-3.3-70b" in mods
        assert "mistral/open-mistral-nemo" in mods
    ramas.append("Rama 1: Detección con las 5 variables de entorno activas")

    # Rama 2: Filtrado de MODELOS_PENALIZADOS
    server.MODELOS_PENALIZADOS.add("gemini/gemini-3.8-flash")
    with patch.dict(os.environ, env_mock, clear=True):
        mods_f = server.detectar_modelos_gratuitos_disponibles()
        assert "gemini/gemini-3.8-flash" not in mods_f
    ramas.append("Rama 2: Exclusión de modelos incluidos en MODELOS_PENALIZADOS")

    # Rama 3: Sin variables de entorno
    with patch.dict(os.environ, {}, clear=True):
        mods_vacio = server.detectar_modelos_gratuitos_disponibles()
        assert mods_vacio == []
    ramas.append("Rama 3: Sin API keys en el entorno (lista vacía)")

    server.MODELOS_PENALIZADOS.clear()
    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/server.py", "detectar_modelos_gratuitos_disponibles", ramas, 7, dt)


def test_limpiar_y_parsear_json() -> None:
    t0 = time.perf_counter()
    ramas = []

    # Rama 1: JSON envuelto en bloque markdown ```json ... ``` y con 4 opciones
    raw_md = """```json
    {
      "veredicto_juez": "Correcto",
      "opciones_jugador": [{"texto": "A"}, {"texto": "B"}, {"texto": "C"}, {"texto": "D"}]
    }
    ```"""
    d1 = server.limpiar_y_parsear_json(raw_md)
    assert d1["veredicto_juez"] == "Correcto"
    assert [op["id"] for op in d1["opciones_jugador"]] == [0, 1, 2, 3]
    ramas.append("Rama 1: Extracción de bloque ```json ... ``` y reindexación de 4 opciones")

    # Rama 2: JSON con texto basura antes y después de las llaves
    raw_pref = 'Aquí tienes tu respuesta:\n{"veredicto_juez": "Vale", "opciones_jugador": []}\nFin.'
    d2 = server.limpiar_y_parsear_json(raw_pref)
    assert d2["veredicto_juez"] == "Vale"
    ramas.append("Rama 2: Recorte de texto externo mediante búsqueda de '{' y '}'")

    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/server.py", "limpiar_y_parsear_json", ramas, 3, dt)


def test_es_respuesta_en_espanol() -> None:
    t0 = time.perf_counter()
    ramas = []

    # Rama 1: Texto íntegramente en español -> True
    datos_es = {
        "veredicto_juez": "El juez acepta la objeción presentada por la defensa.",
        "declaracion_rival": {"dialogo": "Mi cliente cumplió el reglamento interno."},
        "opciones_jugador": [{"texto": "La ética prevalece sobre el contrato."}],
    }
    assert server.es_respuesta_en_espanol(datos_es) is True
    ramas.append("Rama 1: Texto 100% en español retorna True")

    # Rama 2: Texto con palabras prohibidas en inglés -> False
    datos_en = {
        "veredicto_juez": "The judge accepts your argument in the court.",
        "declaracion_rival": {"dialogo": "This is a fallacy."},
        "opciones_jugador": [{"texto": "However that is false."}],
    }
    assert server.es_respuesta_en_espanol(datos_en) is False
    ramas.append("Rama 2: Texto con marcadores léxicos en inglés retorna False")

    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/server.py", "es_respuesta_en_espanol", ramas, 2, dt)


def test_normalizar_danos_turno() -> None:
    t0 = time.perf_counter()
    ramas = []
    aserciones = 0

    # Rama 1: MARCAR_FALACIA verdadera cuando LLM devolvió dano 0 -> normaliza a 25
    req1 = server.TurnRequest(
        accion_jugador="MARCAR_FALACIA",
        declaracion_previa_rival={"es_falacia": True},
    )
    d1 = server._normalizar_danos_turno(req1, {"dano_al_rival": 0, "dano_al_jugador": 0})
    assert d1["dano_al_rival"] == 25 and d1["objecion_jugador_exitosa"] is True
    aserciones += 1
    ramas.append("Rama 1: Normalización MARCAR_FALACIA verdadera -> dano_al_rival=25")

    # Rama 2: MARCAR_FALACIA falsa cuando LLM devolvió dano 0 -> normaliza a 20
    req2 = server.TurnRequest(
        accion_jugador="MARCAR_FALACIA",
        declaracion_previa_rival={"es_falacia": False},
    )
    d2 = server._normalizar_danos_turno(req2, {"dano_al_rival": 0, "dano_al_jugador": 0})
    assert d2["dano_al_jugador"] == 20 and d2["objecion_jugador_exitosa"] is False
    aserciones += 1
    ramas.append("Rama 2: Normalización MARCAR_FALACIA falsa -> dano_al_jugador=20")

    # Rama 3: ARGUMENTAR INFALIBLE -> dano_al_rival=25
    req3 = server.TurnRequest(accion_jugador="ARGUMENTAR", opcion_elegida={"tipo": "INFALIBLE"})
    d3 = server._normalizar_danos_turno(req3, {"dano_al_rival": 0, "dano_al_jugador": 0})
    assert d3["dano_al_rival"] == 25
    aserciones += 1
    ramas.append("Rama 3: Normalización ARGUMENTAR INFALIBLE -> dano_al_rival=25")

    # Rama 4: ARGUMENTAR FALACIA detectada -> dano_al_jugador=25
    req4 = server.TurnRequest(
        accion_jugador="ARGUMENTAR", dificultad="DIFICIL", opcion_elegida={"tipo": "FALACIA"}
    )
    with patch("server.random.random", return_value=0.05):
        d4 = server._normalizar_danos_turno(req4, {"dano_al_rival": 0, "dano_al_jugador": 0})
        assert d4["dano_al_jugador"] == 25 and d4["rival_detecto_falacia_jugador"] is True
        aserciones += 1
    ramas.append("Rama 4: Normalización ARGUMENTAR FALACIA detectada -> dano_al_jugador=25")

    # Rama 5: ARGUMENTAR MEDIO en NORMAL (10) y DIFICIL (15)
    for dif, esp in [("NORMAL", 10), ("DIFICIL", 15)]:
        req_m = server.TurnRequest(
            accion_jugador="ARGUMENTAR", dificultad=dif, opcion_elegida={"tipo": "MEDIO"}
        )
        dm = server._normalizar_danos_turno(req_m, {"dano_al_rival": 0, "dano_al_jugador": 0})
        assert dm["dano_al_jugador"] == esp
        aserciones += 1
    ramas.append("Rama 5: Normalización ARGUMENTAR MEDIO en NORMAL (10 HP) y DIFICIL (15 HP)")

    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado("backend/server.py", "_normalizar_danos_turno", ramas, aserciones, dt)


def test_endpoints_y_procesar_turno() -> None:
    t0 = time.perf_counter()
    ramas = []
    aserciones = 0

    # 1. health_check() y listar_casos()
    hc = server.health_check()
    assert hc["status"] == "ok" and hc["litellm_ready"] is True
    lc = server.listar_casos()
    assert len(lc["casos"]) == 4
    aserciones += 2
    ramas.append("Rama 1: Endpoints health_check() y listar_casos() (4 casos)")

    # 2. procesar_turno() cuando el modelo cloud responde JSON válido en español (Mock LiteLLM)
    server.MODELOS_PENALIZADOS.clear()
    json_valido = json.dumps(
        {
            "veredicto_juez": "Excelente argumento ético presentado ante el tribunal.",
            "dano_al_rival": 25,
            "dano_al_jugador": 0,
            "rival_detecto_falacia_jugador": False,
            "objecion_jugador_exitosa": None,
            "declaracion_rival": {
                "dialogo": "Protesto señoría, el contrato seguía vigente.",
                "es_falacia": False,
                "tipo_argumento_rival": "MEDIO",
                "nombre_falacia": None,
                "explicacion_logica": "Argumento contractual.",
            },
            "opciones_jugador": [
                {"texto": "Opción 1 en español", "tipo": "INFALIBLE", "nombre_falacia": None, "explicacion": "E1"},
                {"texto": "Opción 2 en español", "tipo": "MEDIO", "nombre_falacia": None, "explicacion": "E2"},
                {"texto": "Opción 3 en español", "tipo": "MEDIO", "nombre_falacia": None, "explicacion": "E3"},
                {"texto": "Opción 4 en español", "tipo": "FALACIA", "nombre_falacia": "Ad Hominem", "explicacion": "E4"},
            ],
        }
    )
    mock_resp = MagicMock()
    mock_resp.choices = [MagicMock(message=MagicMock(content=json_valido))]

    with patch("server.detectar_modelos_gratuitos_disponibles", return_value=["modelo-mock-1"]):
        with patch("server.litellm.completion", return_value=mock_resp):
            res_ok = server.procesar_turno(server.TurnRequest(accion_jugador="INICIAR_CASO"))
            assert res_ok["modelo_usado"] == "modelo-mock-1"
            assert len(res_ok["opciones_jugador"]) == 4
            aserciones += 2
    ramas.append("Rama 2: procesar_turno() éxito directo desde proveedor LiteLLM en español")

    # 3. procesar_turno() cuando el modelo responde en inglés -> lo penaliza y usa fallback local
    json_ingles = json.dumps(
        {
            "veredicto_juez": "The judge rules in your favor in this court.",
            "declaracion_rival": {"dialogo": "This argument is a fallacy."},
            "opciones_jugador": [{"texto": "A"}, {"texto": "B"}, {"texto": "C"}, {"texto": "D"}],
        }
    )
    mock_resp_en = MagicMock()
    mock_resp_en.choices = [MagicMock(message=MagicMock(content=json_ingles))]
    with patch("server.detectar_modelos_gratuitos_disponibles", return_value=["modelo-ingles"]):
        with patch("server.litellm.completion", return_value=mock_resp_en):
            res_fb = server.procesar_turno(server.TurnRequest(accion_jugador="INICIAR_CASO"))
            assert res_fb["modelo_usado"] == "motor-rapido-espanol"
            assert "modelo-ingles" in server.MODELOS_PENALIZADOS
            aserciones += 2
    ramas.append("Rama 3: procesar_turno() descarte por idioma inglés, penalización y fallback")

    # 4. procesar_turno() cuando el modelo lanza excepción / timeout -> lo penaliza y usa fallback
    with patch("server.detectar_modelos_gratuitos_disponibles", return_value=["modelo-caido"]):
        with patch("server.litellm.completion", side_effect=RuntimeError("Timeout simulado")):
            res_err = server.procesar_turno(server.TurnRequest(accion_jugador="INICIAR_CASO"))
            assert res_err["modelo_usado"] == "motor-rapido-espanol"
            assert "modelo-caido" in server.MODELOS_PENALIZADOS
            aserciones += 2
    ramas.append("Rama 4: procesar_turno() captura de excepción/timeout, penalización y fallback")

    server.MODELOS_PENALIZADOS.clear()
    dt = (time.perf_counter() - t0) * 1000
    registrar_resultado(
        "backend/server.py", "health_check, listar_casos, procesar_turno", ramas, aserciones, dt
    )


if __name__ == "__main__":
    test_build_turn_user_prompt()
    test_generar_turno_respaldo_local()
    test_detectar_modelos_gratuitos_disponibles()
    test_limpiar_y_parsear_json()
    test_es_respuesta_en_espanol()
    test_normalizar_danos_turno()
    test_endpoints_y_procesar_turno()

    print(json.dumps(RESULTADOS_METODOS, indent=2, ensure_ascii=False))
