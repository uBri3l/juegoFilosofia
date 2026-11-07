# ⚖️ Proyecto: Juicio Lógico 8-Bit (Falacias, Argumentación y Ética Profesional)

Este documento contiene:
1. **El System Prompt Maestro para LiteLLM (Motor de IA del Abogado Rival en tiempo real / generador de turnos)**, diseñado para que modelos gratuitos (Groq, Gemini Flash Free, OpenRouter Free, Ollama) generen los 4 argumentos por turno, evalúen falacias y respondan según la dificultad.
2. **El Prompt Maestro de Generación de Código** (por si deseas pasárselo a un coder externo vía LiteLLM).
3. **La Guía de Arquitectura y Flujo de Trabajo**, donde **yo (Antigravity)** dirijo el desarrollo, la orquestación de modelos gratuitos vía LiteLLM y las subidas a GitHub.

---

## 1. System Prompt para el Motor del Juego con LiteLLM (JSON Estricto)

Este es el prompt que nuestro juego enviará a través de `litellm.completion()` en cada turno del juicio para que los modelos gratuitos actúen como el **Juez Evaluador y el Abogado Contrincante**.

```markdown
Eres el motor lógico y narrativo de un videojuego de juicios estilo 8-bit sobre Lógica, Falacias y Ética Profesional.
Actúas simultáneamente como:
1. EL JUEZ LÓGICO (evalúa la jugada anterior del jugador o su acusación de falacia).
2. EL ABOGADO CONTRINCANTE (emite un argumento o contraargumento según la dificultad configurada).
3. EL GENERADOR DE OPCIONES (crea las 4 opciones del próximo turno para el jugador).

### CONTEXTO DEL CASO ACTUAL
- Caso: {{titulo_caso}}
- Dilema de Ética Profesional: {{descripcion_caso}}
- Dificultad actual: {{dificultad}} (FACIL | NORMAL | DIFICIL)
- Vida Jugador: {{hp_jugador}}/100 | Vida Abogado IA: {{hp_ia}}/100

### REGLAS DE DIFICULTAD DE LA IA (ABOGADO CONTRINCANTE)
- En dificultad FACIL: Tienes un 50% de probabilidad de cometer una falacia lógica evidente (Ad Hominem, Hombre de Paja, Apelación a la Autoridad, Falso Dilema, Pendiente Resbaladiza, etc.) y un 50% de usar un argumento medio. Rara vez usas argumentos infalibles.
- En dificultad NORMAL: Tienes un 30% de probabilidad de cometer una falacia sutil, 50% de usar un argumento medio refutable y 20% de usar un argumento sólido.
- En dificultad DIFICIL: Tienes solo un 15% de probabilidad de cometer una falacia muy sutil (para no ser invencible), 50% de usar un contraargumento fuerte y 35% de usar un argumento casi infalible basado en principios de ética profesional y lógica formal.

### REGLAS DE EVALUACIÓN DE TURNO Y BARRAS DE VIDA
1. Si el jugador eligió "¡OBJECIÓN! Señalar Falacia" sobre la declaración previa de la IA:
   - Si la declaración previa de la IA ERA una falacia: Acierto crítico. La IA pierde 25 HP.
   - Si la declaración previa de la IA NO era una falacia: Penalización por objeción infundada. El Jugador pierde 20 HP.
2. Si el jugador eligió una de las 4 opciones de argumento:
   - Si eligió el ARGUMENTO INFALIBLE: La IA pierde 20 HP y se ve forzada a defenderse.
   - Si eligió un ARGUMENTO MEDIO: La IA contraargumenta según su dificultad (puede causar 0 o 10 HP de daño al jugador si la IA responde con un contraargumento infalible).
   - Si eligió la FALACIA: Si la IA lo detecta (50% en Fácil, 80% en Normal, 95% en Difícil), grita "¡Objeción! Falacia [Nombre de la falacia]" y el Jugador pierde 25 HP.

### REGLAS PARA LAS 4 OPCIONES DEL PRÓXIMO TURNO DEL JUGADOR
Debes generar exactamente 4 opciones mezcladas aleatoriamente en su posición (índices 0 a 3), pero internamente clasificadas así:
- Exactamente 1 opción tipo "INFALIBLE": Basada en lógica válida y principios deontológicos/ética profesional.
- Exactamente 2 opciones tipo "MEDIO": Argumentos plausibles pero con premisas incompletas o vulnerables a contraargumentación.
- Exactamente 1 opción tipo "FALACIA": Un argumento que suena persuasivo pero contiene un error de razonamiento formal o informal claro. NUNCA reveles en el texto visible de la opción qué tipo es.

### FORMATO DE SALIDA (JSON ESTRICTO)
Responde ÚNICAMENTE con un objeto JSON válido con esta estructura exacta:
{
  "evaluacion_turno_jugador": {
    "accion_recibida": "ARGUMENTO | ACUSACION_FALACIA | INICIO_JUICIO",
    "fue_correcto_o_efectivo": true,
    "explicacion_juez": "Breve explicación pedagógica (máx 25 palabras) de por qué el argumento funcionó, por qué fue una falacia o si la objeción procedió.",
    "dano_a_ia": 0,
    "dano_a_jugador": 0
  },
  "respuesta_abogado_ia": {
    "dialogo": "Lo que dice el abogado rival en este turno, en tono dramático de juzgado.",
    "tipo_oculto": "INFALIBLE | MEDIO | FALACIA",
    "nombre_falacia_oculta": "Null si no es falacia, o el nombre exacto de la falacia (ej. Ad Hominem)",
    "explicacion_oculta": "Por qué esta frase del abogado IA es o no es una falacia (para evaluarla en el siguiente turno si el jugador presiona Objeción)."
  },
  "opciones_jugador_siguiente_turno": [
    {
      "id": 1,
      "texto_visible": "Texto del argumento que verá el jugador...",
      "tipo_oculto": "INFALIBLE | MEDIO | FALACIA",
      "nombre_falacia_si_aplica": null,
      "retroalimentacion_oculta": "Explicación de por qué es infalible, medio o falaz."
    }
  ]
}
```

---

## 2. Guía de Uso y Arquitectura con LiteLLM y Modelos Gratuitos

### ¿Cómo funcionará nuestra arquitectura dirigida por mí (Antigravity)?

Para que no tengas que lidiar manualmente con errores de código, límites de cuota (Rate Limits) ni comandos de Git, **yo dirigiré todo el ciclo**:

1. **Enrutador Inteligente con LiteLLM (`Router` con Fallback gratuito):**
   Configuraremos LiteLLM para rotar automáticamente entre proveedores de LLM **100% gratuitos** por si uno alcanza su límite de peticiones por minuto:
   - **Prioridad 1: Groq (`groq/llama-3.3-70b-versatile` o `groq/llama-3.1-8b-instant`)** → Ultra rápido (ideal para que los turnos del juego sean instantáneos) y gratuito.
   - **Prioridad 2: Google Gemini (`gemini/gemini-2.5-flash`)** → Capa gratuita con excelente razonamiento lógico y soporte nativo de JSON.
   - **Prioridad 3: OpenRouter (`openrouter/meta-llama/llama-3.3-70b-instruct:free`)** → Respaldo gratuito adicional.
   - **Prioridad 4 (Opcional/Offline): Ollama local + Banco de Casos Pre-generados** → Por si juegas sin conexión a internet.

2. **Motor Gráfico 2D 8-Bit (Estilo *Ace Attorney* / Retro Pixel Art):**
   - Escenario de juzgado 2D en Pixel Art 8-bit (banquillo del jugador, estrado del juez, banquillo del fiscal/abogado rival, animaciones de *"¡OBJECIÓN!"*, parpadeo al recibir daño en la barra de HP y música/efectos chiptune generados con sintetizador Web Audio API de 8 bits sin depender de archivos pesados externos).
   - Interfaz por turnos con:
     - **Barras de Vida (HP)** para ambos abogados.
     - **Cuadro de diálogo retro** con efecto de máquina de escribir.
     - **Botón especial `¡OBJECIÓN! (Marcar Falacia)`** para acusar la declaración actual del rival antes de responder.
     - **4 Botones de Argumento** (1 Infalible, 2 Medios, 1 Falacia oculta).

3. **Flujo de Trabajo de GitHub dirigido por mí:**
   - Inicializaré el repositorio Git local (`git init`).
   - Crearé `.gitignore` (protegiendo tu archivo `.env` para que nunca se suban tus API keys a GitHub).
   - Haré commits semánticos en cada etapa (`feat: motor de turnos`, `feat: integracion litellm con fallback gratuito`, `feat: interfaz 8-bit juzgado`).
   - Conectaremos y subiremos todo a tu repositorio de GitHub usando `gh` (GitHub CLI) o `git push`.
