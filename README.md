# ⚖️ Juicio Lógico 8-Bit: Falacias, Argumentación y Ética Profesional

Videojuego 2D estilo **8-bit Pixel Art** desarrollado en **Godot 4** con un motor de inteligencia artificial en **Python + LiteLLM** que orquesta modelos de lenguaje **100% gratuitos** (Groq, Google Gemini Flash, OpenRouter Free, Cerebras y Mistral) con rotación automática y respaldo offline.

---

## 🎮 Mecánicas del Videojuego

1. **Combate Dialéctico en un Juzgado (Barras de Vida de 100 HP):**
   - Te enfrentas como Abogado Defensor a un Fiscal controlado por IA en diversos casos de **Ética Profesional** (Ingeniería y Bioética, Secreto Profesional vs. Salud Ambiental, Independencia en Auditoría Contable).
   - Ambos tienen una **barra de credibilidad/vida (100 HP)**.
2. **4 Opciones de Argumento por Turno:**
   - En cada turno tienes **4 opciones generadas y mezcladas aleatoriamente**:
     - **1 Argumento Infalible:** Basado en principios deontológicos sólidos y lógica válida. Baja **25 HP** al abogado rival.
     - **2 Argumentos Medios:** Argumentos plausibles pero incompletos que el rival puede contraargumentar según la dificultad.
     - **1 Falacia:** Un error de razonamiento lógico (Ad Hominem, Hombre de Paja, Pendiente Resbaladiza, Falso Dilema, Ad Populum, etc.). Si la eliges y el rival lo detecta, pierdes **25 HP**.
3. **Botón `¡OBJECIÓN! Marcar como Falacia` en cada turno:**
   - Antes de responder, puedes acusar la declaración actual del abogado rival como **Falacia**.
   - Si aciertas y era una falacia: el rival pierde **25 HP**.
   - Si te equivocas y su argumento era válido: pierdes **20 HP** por objeción infundada.
4. **3 Niveles de Dificultad Dinámica:**
   - **Sencilla (`FACIL`):** La máquina se equivoca con frecuencia (~55-60% de probabilidad de emitir falacias) y rara vez detecta tus propias falacias.
   - **Normal (`NORMAL`):** Equilibrio entre falacias sutiles, argumentos medios y contraargumentos fuertes.
   - **Difícil (`DIFICIL`):** La máquina elige los mejores argumentos deontológicos y es muy difícil que emita falacias (~15% de probabilidad de falacia sutil, para que **no sea invencible**).

---

## 🔑 Guía Rápida (1 Minuto) para Obtener API Keys Gratuitas (Sin Tarjeta)

El motor `backend/server.py` usa **LiteLLM** para rotar automáticamente entre todos los proveedores gratuitos que configures en tu archivo `.env`:

1. **Groq (Recomendado #1 — Ultra rápido para juegos por turnos, gratis sin tarjeta):**
   - Entra a https://console.groq.com/keys
   - Inicia sesión con Google o GitHub → Clic en **Create API Key** → Pégala en `GROQ_API_KEY=` dentro de `.env`.
   - Modelos usados: `groq/llama-3.3-70b-versatile` y `groq/llama-3.1-8b-instant`.
2. **Google AI Studio / Gemini (Recomendado #2 — Excelente lógica formal, gratis sin tarjeta):**
   - Entra a https://aistudio.google.com/app/apikey
   - Clic en **Create API key** → Pégala en `GEMINI_API_KEY=` dentro de `.env`.
   - Modelos usados: `gemini/gemini-2.5-flash` y `gemini/gemini-2.0-flash`.
3. **OpenRouter (Recomendado #3 — Acceso a decenas de modelos `:free`):**
   - Entra a https://openrouter.ai/settings/keys
   - Crea una clave gratuita → Pégala en `OPENROUTER_API_KEY=` dentro de `.env`.
   - Modelos usados: `openrouter/meta-llama/llama-3.3-70b-instruct:free`, `openrouter/google/gemma-3-27b-it:free`.
4. **Cerebras Cloud (Opcional — Inferencia instantánea gratuita):**
   - Entra a https://cloud.cerebras.ai/ → Pégala en `CEREBRAS_API_KEY=`.

> **Nota:** Incluso si todavía no pegas ninguna API Key, el juego cuenta con un **Motor Lógico de Respaldo Local** tanto en el servidor Python como dentro de Godot para que puedas jugar inmediatamente.

---

## 🚀 Cómo Ejecutar el Videojuego

1. **Iniciar el motor LiteLLM:**
   - Haz doble clic en `iniciar_servidor_litellm.bat` (o ejecuta `python backend/server.py`).
2. **Abrir el juego en Godot 4:**
   - Abre **Godot Engine 4.x**, haz clic en **Importar** y selecciona `godot_project/project.godot`.
   - Presiona **F5** (Ejecutar proyecto).
