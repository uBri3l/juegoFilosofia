"""
Servidor LiteLLM para el videojuego 'Juicio Lógico 8-Bit' en Godot.
Enruta peticiones a múltiples proveedores gratuitos de LLM (Groq, Gemini, OpenRouter,
Cerebras, Mistral, GitHub Models, Ollama) con fallback automático y validación de JSON.
"""

import json
import os
import random
import subprocess
from typing import Any

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import litellm
from pydantic import BaseModel

from cases_data import CASOS_DISPONIBLES, generar_turno_respaldo_local
from prompts import SYSTEM_PROMPT_JUICIO, build_turn_user_prompt

load_dotenv()

# Silenciar telemetría innecesaria de LiteLLM
litellm.telemetry = False
litellm.drop_params = True

app = FastAPI(
    title="Juicio Lógico 8-Bit - LiteLLM Engine",
    description="Backend orquestador de modelos gratuitos de LLM para el juego en Godot.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


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
    Construye la lista ordenada de modelos gratuitos según las API keys presentes en `.env`.
    """
    modelos: list[str] = []

    if os.getenv("OPENROUTER_API_KEY"):
        modelos.extend([
            "openrouter/cohere/north-mini-code:free",
            "openrouter/nvidia/nemotron-3.5-lightning:free",
            "openrouter/xingchen-agi/xing4.0-29b-a4b:free",
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
            "cerebras/llama3.1-8b",
        ])

    if os.getenv("MISTRAL_API_KEY"):
        modelos.append("mistral/open-mistral-nemo")

    # Si el usuario configuró GITHUB_API_KEY
    if os.getenv("GITHUB_API_KEY"):
        modelos.append("github/gpt-4o-mini")

    return modelos


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
    # Asegurar que las 4 opciones estén mezcladas y numeradas del 0 al 3
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
    palabras_ingles = [" the ", " your ", " this ", " that ", " with ", " from ", " argument ", " court ", " judge ", " fallacy ", " however ", " because "]
    conteo_ingles = sum(1 for p in palabras_ingles if p in combinado)
    return conteo_ingles == 0


@app.get("/health")
def health_check() -> dict[str, Any]:
    modelos = detectar_modelos_gratuitos_disponibles()
    return {
        "status": "ok",
        "litellm_ready": True,
        "free_models_configured": modelos,
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
    modelos = detectar_modelos_gratuitos_disponibles()

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
            respuesta = litellm.completion(
                model=modelo,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT_JUICIO},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.7,
                max_tokens=2500,
                timeout=25,
            )
            contenido = respuesta.choices[0].message.content
            datos = limpiar_y_parsear_json(contenido)
            if (
                "declaracion_rival" in datos
                and len(datos.get("opciones_jugador", [])) == 4
                and es_respuesta_en_espanol(datos)
            ):
                datos["modelo_usado"] = modelo
                return datos
            errores_proveedores.append(f"{modelo}: Respuesta descartada por idioma o formato incompleto")
        except Exception as exc:
            errores_proveedores.append(f"{modelo}: {exc!s}")

    # Si no hay API keys configuradas aún o todos los proveedores gratuitos dieron timeout/rate-limit,
    # usamos el motor lógico local para garantizar que el juego funcione sin interrupciones.
    respaldo = generar_turno_respaldo_local(
        caso_id=req.caso_id,
        dificultad=req.dificultad,
        accion_jugador=req.accion_jugador,
        declaracion_previa_rival=req.declaracion_previa_rival,
        opcion_elegida=req.opcion_elegida,
        turno_idx=req.turno_idx,
    )
    respaldo["modelo_usado"] = "motor-local-8bit (agrega tu API key en .env para IA infinita con LiteLLM)"
    if errores_proveedores:
        respaldo["avisos_litellm"] = errores_proveedores
    return respaldo


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
