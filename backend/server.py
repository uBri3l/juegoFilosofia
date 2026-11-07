"""
Servidor LiteLLM para el videojuego 'Juicio Lógico 8-Bit' en Godot.
Enruta peticiones a múltiples proveedores gratuitos de LLM con timeout estricto (< 4.5s),
memoria de modelos caídos para evitar bloqueos y respaldo local instantáneo en español.
"""

from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
import json
import os
import random
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import litellm
from pydantic import BaseModel

from cases_data import CASOS_DISPONIBLES, generar_turno_respaldo_local
from prompts import SYSTEM_PROMPT_JUICIO, build_turn_user_prompt

load_dotenv()

litellm.telemetry = False
litellm.drop_params = True

app = FastAPI(
    title="Juicio Lógico 8-Bit - LiteLLM Engine",
    description="Backend orquestador de modelos gratuitos de LLM para el juego en Godot.",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Memoria en tiempo de ejecución de modelos con clave inválida o no encontrados
# para no volver a consultarlos y evitar cualquier bloqueo entre turnos.
MODELOS_PENALIZADOS: set[str] = set()


class TurnRequest(BaseModel):
    caso_id: str = "caso_algoritmo_medico"
    dificultad: str = "NORMAL"  # FACIL | NORMAL | DIFICIL
    hp_jugador: int = 100
    hp_rival: int = 100
    accion_jugador: str = "INICIAR_CASO"  # INICIAR_CASO | ARGUMENTAR | MARCAR_FALACIA
    declaracion_previa_rival: dict[str, Any] | None = None
    opcion_elegida: dict[str, Any] | None = None
    historial_resumido: list[str] = []
    turno_idx: int = 0


def detectar_modelos_gratuitos_disponibles() -> list[str]:
    """
    Construye la lista ordenada de modelos gratuitos activos excluyendo los que hayan
    fallado por credenciales o disponibilidad.
    """
    modelos: list[str] = []

    if os.getenv("OPENROUTER_API_KEY"):
        modelos.extend([
            "openrouter/cohere/north-mini-code:free",
            "openrouter/nvidia/nemotron-3.5-lightning:free",
            "openrouter/liquid/lfm-3-1.7b:free",
        ])

    if os.getenv("GEMINI_API_KEY"):
        modelos.extend([
            "gemini/gemini-3.8-flash",
        ])

    if os.getenv("GROQ_API_KEY"):
        modelos.extend([
            "groq/llama-3.3-70b-versatile",
            "groq/llama-3.1-8b-instant",
        ])

    if os.getenv("CEREBRAS_API_KEY"):
        modelos.extend([
            "cerebras/llama-3.3-70b",
        ])

    if os.getenv("MISTRAL_API_KEY"):
        modelos.append("mistral/open-mistral-nemo")

    return [m for m in modelos if m not in MODELOS_PENALIZADOS]


def limpiar_y_parsear_json(texto: str) -> dict[str, Any]:
    """Extrae el bloque JSON de la respuesta del modelo de forma segura."""
    limpio = texto.strip()
    if limpio.startswith("```"):
        lineas = limpio.splitlines()
        if lineas[0].startswith("```"):
            lineas = lineas[1:]
        if lineas and lineas[-1].startswith("```"):
            lineas = lineas[:-1]
        limpio = "\n".join(lineas).strip()

    inicio = limpio.find("{")
    fin = limpio.rfind("}")
    if inicio != -1 and fin != -1 and fin > inicio:
        limpio = limpio[inicio : fin + 1]

    datos = json.loads(limpio)
    opciones = datos.get("opciones_jugador", [])
    if isinstance(opciones, list) and len(opciones) == 4:
        random.shuffle(opciones)
        for idx, op in enumerate(opciones):
            op["id"] = idx
        datos["opciones_jugador"] = opciones
    return datos


def es_respuesta_en_espanol(datos: dict[str, Any]) -> bool:
    """Verifica que los textos generados por el LLM estén en español y no en inglés."""
    textos: list[str] = [
        str(datos.get("veredicto_juez", "")),
        str(datos.get("declaracion_rival", {}).get("dialogo", "")),
    ]
    for op in datos.get("opciones_jugador", []):
        textos.append(str(op.get("texto", "")))

    combinado = " " + " ".join(textos).lower() + " "
    palabras_ingles = [
        " the ", " your ", " this ", " that ", " with ", " from ",
        " argument ", " court ", " judge ", " fallacy ", " however ", " because "
    ]
    conteo_ingles = sum(1 for p in palabras_ingles if p in combinado)
    return conteo_ingles == 0


@app.get("/health")
def health_check() -> dict[str, Any]:
    modelos = detectar_modelos_gratuitos_disponibles()
    return {
        "status": "ok",
        "litellm_ready": True,
        "free_models_configured": modelos,
        "penalized_models": list(MODELOS_PENALIZADOS),
        "mode": "LITELLM_CLOUD" if modelos else "LOCAL_FALLBACK_READY",
    }


@app.get("/casos")
def listar_casos() -> dict[str, Any]:
    return {
        "casos": [
            {
                "id": c["id"],
                "titulo": c["titulo"],
                "subtitulo": c["subtitulo"],
                "abogado_rival": c["abogado_rival"],
                "descripcion": c["descripcion"],
            }
            for c in CASOS_DISPONIBLES
        ]
    }


@app.post("/turno")
def procesar_turno(req: TurnRequest) -> dict[str, Any]:
    caso = next((c for c in CASOS_DISPONIBLES if c["id"] == req.caso_id), CASOS_DISPONIBLES[0])
    # Probamos máximo 1 modelo rápido por turno con timeout corto para que el juego NUNCA se tranque
    modelos = detectar_modelos_gratuitos_disponibles()[:1]

    user_prompt = build_turn_user_prompt(
        caso_titulo=caso["titulo"],
        caso_contexto=caso["descripcion"],
        dificultad=req.dificultad,
        hp_jugador=req.hp_jugador,
        hp_rival=req.hp_rival,
        declaracion_previa_rival=req.declaracion_previa_rival or {},
        accion_jugador=req.accion_jugador,
        opcion_elegida=req.opcion_elegida,
        historial_resumido=req.historial_resumido,
    )

    errores_proveedores: list[str] = []

    for modelo in modelos:
        try:
            executor = ThreadPoolExecutor(max_workers=1)
            future = executor.submit(
                litellm.completion,
                model=modelo,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT_JUICIO},
                    {"role": "user", "content": user_prompt},
                ],
                max_tokens=900,
                timeout=2.8,
                num_retries=0,
            )
            try:
                respuesta = future.result(timeout=3.2)
            finally:
                executor.shutdown(wait=False, cancel_futures=True)

            contenido = respuesta.choices[0].message.content
            datos = limpiar_y_parsear_json(contenido)
            if (
                "declaracion_rival" in datos
                and len(datos.get("opciones_jugador", [])) == 4
                and es_respuesta_en_espanol(datos)
            ):
                # Garantizar que los daños siempre existan y sean consistentes con la acción
                datos = _normalizar_danos_turno(req, datos)
                datos["modelo_usado"] = modelo
                return datos
            errores_proveedores.append(f"{modelo}: Respuesta descartada por idioma o formato incompleto")
            MODELOS_PENALIZADOS.add(modelo)
        except (FuturesTimeoutError, Exception) as exc:
            msg = str(exc) or "Timeout superado (3.2s)"
            errores_proveedores.append(f"{modelo}: {msg}")
            MODELOS_PENALIZADOS.add(modelo)

    respaldo = generar_turno_respaldo_local(
        caso_id=req.caso_id,
        dificultad=req.dificultad,
        accion_jugador=req.accion_jugador,
        declaracion_previa_rival=req.declaracion_previa_rival,
        opcion_elegida=req.opcion_elegida,
        turno_idx=req.turno_idx,
    )
    respaldo["modelo_usado"] = "motor-rapido-espanol"
    if errores_proveedores:
        respaldo["avisos_litellm"] = errores_proveedores
    return respaldo


def _normalizar_danos_turno(req: TurnRequest, datos: dict[str, Any]) -> dict[str, Any]:
    """
    Garantiza que las reglas de daño a la barra de vida se cumplan matemáticamente
    incluso si el LLM olvidó asignar el entero de daño en el JSON.
    """
    dano_r = int(datos.get("dano_al_rival") or 0)
    dano_j = int(datos.get("dano_al_jugador") or 0)

    if req.accion_jugador == "MARCAR_FALACIA" and req.declaracion_previa_rival:
        era_falacia = bool(req.declaracion_previa_rival.get("es_falacia", False))
        if era_falacia and dano_r == 0:
            dano_r = 25
            datos["objecion_jugador_exitosa"] = True
        elif (not era_falacia) and dano_j == 0:
            dano_j = 20
            datos["objecion_jugador_exitosa"] = False

    elif req.accion_jugador == "ARGUMENTAR" and req.opcion_elegida:
        tipo = str(req.opcion_elegida.get("tipo", "MEDIO")).upper()
        if tipo == "INFALIBLE" and dano_r == 0:
            dano_r = 25
        elif tipo == "FALACIA" and dano_j == 0:
            prob_det = {"FACIL": 0.50, "NORMAL": 0.80, "DIFICIL": 0.95}.get(req.dificultad, 0.80)
            if random.random() < prob_det:
                dano_j = 25
                datos["rival_detecto_falacia_jugador"] = True
        elif tipo == "MEDIO" and dano_j == 0 and dano_r == 0:
            if req.dificultad == "NORMAL":
                dano_j = 10
            elif req.dificultad == "DIFICIL":
                dano_j = 15

    datos["dano_al_rival"] = dano_r
    datos["dano_al_jugador"] = dano_j
    return datos


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
