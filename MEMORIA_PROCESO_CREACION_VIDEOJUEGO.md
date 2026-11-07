# ⚖️ Memoria Técnica y de Diseño: Proceso de Creación de *«¡OBJECIÓN! CÓDIGO DE HONOR»*

**Título Oficial del Videojuego:** `⚖️ ¡OBJECIÓN! CÓDIGO DE HONOR ⚖️` (*Crónicas del Estrado*)  
**Motor Gráfico:** Godot Engine 4.7.2 (`gl_compatibility` — 2D Pixel-Art Procedural 8-Bit)  
**Motor Lógico Dual:** Orquestador Cloud (`FastAPI` + `LiteLLM`) + Motor Autónomo Embebido (`CasesDatabase.gd` / `cases_data.py`)  
**Repositorio Oficial:** [`https://github.com/uBri3l/juegoFilosofia`](https://github.com/uBri3l/juegoFilosofia)

---

## 1. Visión General y Concepción Pedagógica

El proyecto nació con el objetivo de transformar el estudio de la **Lógica Informal (identificación y refutación de falacias)** y la **Ética y Deontología Profesional** en una experiencia interactiva de combate dialéctico por turnos en 2D con estética retro **8-bit**, inspirada en clásicos de tribunales como *Ace Attorney*.

### Objetivos de Diseño
1. **Aprendizaje Activo por Decisiones:** En lugar de memorizar definiciones teóricas, el jugador asume el rol de **Abogado Defensor** frente a un fiscal implacable y un Juez que evalúa el rigor ético y lógico de cada intervención.
2. **Doble Mecánica de Combate Dialéctico:**
   - **Defensa Activa (Detección de Falacias):** Evaluar si el alegato recién pronunciado por el fiscal contiene una falacia lógica y presionar el botón **`¡OBJECIÓN! MARCAR DECLARACIÓN COMO FALACIA`** en el momento oportuno.
   - **Contraataque Argumentativo (4 Opciones):** Elegir entre 4 líneas argumentales barajadas dinámicamente en cada turno:
     - `1` **Argumento Infalible** (basado en principios deontológicos universales: no maleficencia, beneficencia, independencia profesional, veracidad documental).
     - `2` **Argumentos Medios** (tibios, utilitaristas o meramente burocráticos).
     - `1` **Falacia Lógica Trampa** (*Ad Hominem*, *Ad Populum*, *Falso Dilema*, *Pendiente Resbaladiza*, *Apelación a la Autoridad*, *Hombre de Pajaro*, etc.).
3. **Disponibilidad Universal (Cero Bloqueos y Multi-Dispositivo):** El juego debía poder aprovechar modelos LLM gratuitos a través de **LiteLLM** cuando estuviera conectado al servidor local y, al mismo tiempo, funcionar **100% offline y sin servidor** como un ejecutable autónomo (`.exe` y `Web HTML5/WASM`) para poder compartirlo con amigos en cualquier dispositivo.

---

## 2. Arquitectura del Sistema (Doble Motor Híbrido)

```mermaid
flowchart LR
    subgraph Cliente["Cliente Godot 4 (¡OBJECIÓN! CÓDIGO DE HONOR)"]
        UI["MainCourtroom.gd\n(Menú, HUD, Barras HP, Opciones)"]
        STAGE["PixelCourtStage.gd\n(Escenario 8-Bit Procedural @ 60 FPS)"]
        DB_GD["CasesDatabase.gd\n(Motor Autónomo Embebido en .exe/.pck)"]
        UI --> STAGE
        UI -->|Fallback instantáneo 0.0s\nsin servidor| DB_GD
    end

    subgraph Backend["Servidor Local Opcional (127.0.0.1:8000)"]
        API["backend/server.py\n(FastAPI + Middleware OWASP)"]
        PROMPT["backend/prompts.py\n(System & Turn Prompts)"]
        DB_PY["backend/cases_data.py\n(Respaldo Determinista en Español)"]
        API --> PROMPT
        API -->|Timeout > 3.2s o sin API Key| DB_PY
    end

    subgraph Cloud["Proveedores Gratuitos vía LiteLLM"]
        LLM["OpenRouter / Gemini / Groq / Cerebras / Mistral"]
    end

    UI -->|HTTP POST /turno\n(Watchdog 5.8s / Ping 0.5s)| API
    API -->|ThreadPoolExecutor 3.2s| LLM
```

### Componentes Principales Creados
- **Capa Visual y de Interfaz en Godot 4 (`godot_project/`):**
  - [`godot_project/project.godot`](godot_project/project.godot): Configuración de ventana (`900x540`, modo `canvas_items`, renderizador `gl_compatibility` para compatibilidad inmediata con cualquier GPU integrada o WebAssembly).
  - [`godot_project/scenes/MainCourtroom.tscn`](godot_project/scenes/MainCourtroom.tscn): Escena raíz del tribunal.
  - [`godot_project/scripts/MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd): Controlador central de la máquina de estados (Menú Principal, Juzgado por Turnos, Barras de Credibilidad HP, Sondeo de Servidor con indicador discreto `●` verde/rojo, Watchdog Anti-Bloqueo y Pantallas de Victoria/Derrota).
  - [`godot_project/scripts/PixelCourtStage.gd`](godot_project/scripts/PixelCourtStage.gd): Motor de renderizado pixel-art 8-bit 100% procedural (mediante primitivas `_draw()` sin depender de texturas externas que pudieran corromperse), dibujando al Juez con peluca y mazo animado, al Abogado Defensor, al Fiscal Rival, las bancadas, la balanza de la justicia y los carteles dinámicos (`¡OBJECIÓN!`, `🏆 ¡VICTORIA MAGISTRAL!`, `⚖️ DERROTA EN EL TRIBUNAL`).
  - [`godot_project/scripts/CasesDatabase.gd`](godot_project/scripts/CasesDatabase.gd): Base de datos autónoma compilada en bytecode dentro del `.exe`/`.pck` para garantizar funcionamiento en cualquier PC o celular sin necesidad de Python ni servidor.
- **Capa de Orquestación Backend (`backend/`):**
  - [`backend/server.py`](backend/server.py): Servidor REST en FastAPI con enrutamiento mediante `litellm.completion`, validación de idioma español (`es_respuesta_en_espanol`), normalización matemática de daños (`_normalizar_danos_turno`), memoria de penalización de modelos caídos (`MODELOS_PENALIZADOS`) y middleware de seguridad OWASP (`middleware_seguridad_http`).
  - [`backend/prompts.py`](backend/prompts.py): Ingeniería de prompts (`SYSTEM_PROMPT_JUICIO` y `build_turn_user_prompt`) que instruye al modelo a actuar simultáneamente como Fiscal y Juez devolviendo un contrato JSON estricto en español.
  - [`backend/cases_data.py`](backend/cases_data.py): Catálogo completo de los 4 expedientes éticos y generador determinista `generar_turno_respaldo_local`.

---

## 3. Diseño de los 4 Expedientes Éticos y Reglas de Combate

Se diseñaron **4 casos inspirados en dilemas reales de ética profesional**, cada uno con su propio fiscal especializado, banco de alegatos falaces, argumentos válidos y baterías de 4 opciones por turno:

| ID del Caso | Título del Expediente | Eje Ético / Deontológico | Fiscal Rival |
| :--- | :--- | :--- | :--- |
| `caso_algoritmo_medico` | **Caso 1: El Algoritmo de Triaje Clínico** | Ingeniería de Software, Secreto Industrial (NDA) vs. Bioética y Derecho a la Vida | Fiscal V. Krugger |
| `caso_vertido_quimico` | **Caso 2: El Informe Hidrogeológico Oculto** | Secreto Profesional y Lealtad al Cliente vs. Salud Pública Ambiental (Principio de No Maleficencia) | Fiscal M. Vance |
| `caso_auditoria_contable` | **Caso 3: La Auditoría de Fondos de Pensiones** | Independencia Profesional, Fe Pública y Conflicto de Interés Familiar | Fiscal D. Sterling |
| `caso_ia_periodismo` | **Caso 4: Fuentes Fabricadas con IA en Investigación** | Ética Periodística, Rigor Documental y Deber de Veracidad Informativa | Fiscal L. Valmont |

### Matriz Matemática de Daños y Dificultades (`FACIL`, `NORMAL`, `DIFICIL`)

| Acción del Jugador | Condición / Tipo | Daño a Fiscalía (`hp_rival`) | Daño a Defensa (`hp_jugador`) | Regla Pedagógica Aplicada |
| :--- | :--- | :---: | :---: | :--- |
| **`¡OBJECIÓN!` (`MARCAR_FALACIA`)** | El alegato del fiscal **SÍ** era falacia (`es_falacia = true`) | **`-25 HP`** | `0 HP` | El Juez da lugar a la objeción y expone la falacia del fiscal. |
| **`¡OBJECIÓN!` (`MARCAR_FALACIA`)** | El alegato del fiscal **NO** era falacia (`es_falacia = false`) | `0 HP` | **`-20 HP`** | Penalización por interrupción temeraria ante un argumento válido. |
| **Argumentar (`ARGUMENTAR`)** | Opción **`INFALIBLE`** | **`-25 HP`** | `0 HP` | Golpe directo por fundamentación ética y deontológica irrefutable. |
| **Argumentar (`ARGUMENTAR`)** | Opción **`MEDIO`** | `0 HP` | `0` (`FACIL`) / **`-10`** (`NORMAL`) / **`-15`** (`DIFICIL`) | Argumento tibio: en dificultades media y alta el fiscal penaliza la falta de contundencia. |
| **Argumentar (`ARGUMENTAR`)** | Opción **`FALACIA`** | `0 HP` | **`-25 HP`** *(según detección: `50%` Fácil, `80%` Normal, `95%` Difícil)* | Si el jugador intenta usar una falacia, el fiscal la detecta y el Juez sanciona a la defensa. |

---

## 4. Cronología Detallada de las 7 Fases de Desarrollo

### Fase 1: Prototipo Fundacional y Conexión LiteLLM (`Commits ee01045 .. 4a36545`)
1. Se estructuró el proyecto separando el cliente gráfico en `godot_project/` y el orquestador en `backend/`.
2. Se implementó el escenario 2D 8-bit procedural en [`PixelCourtStage.gd`](godot_project/scripts/PixelCourtStage.gd) con paleta de 16 colores estilo NES/PICO-8 y animaciones a 60 FPS (parpadeo, boca hablante según quién tiene la palabra, golpe de mazo del Juez y destello rojo de daño).
3. Se configuró `preload("res://scripts/PixelCourtStage.gd")` en [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd) para que el juego pudiera ejecutarse inmediatamente sin requerir caché previa del editor de Godot.

### Fase 2: Optimización Gráfica, Layout `900x540` y Filtro de Idioma Español (`Commits d44418e .. 30e84b7`)
1. **Cambio a `gl_compatibility`:** En Windows el compilador de shaders Vulkan (`forward_plus`) demoraba varios segundos en el primer arranque; al cambiar a `gl_compatibility` en [`project.godot`](godot_project/project.godot), la apertura de la ventana pasó a ser instantánea (`< 0.3s`).
2. **Ajuste de Geometría sin Recortes:** Se redimensionó la ventana a `900x540` centrada dinámicamente en el monitor (`_centrar_ventana_en_pantalla()`) con auto-wrap inteligente (`AUTOWRAP_WORD_SMART`) en todos los botones y diálogos para evitar que cualquier texto largo se cortara a la derecha.
3. **Garantía de Idioma 100% Español:** Algunos modelos gratuitos en la nube respondían ocasionalmente en inglés a pesar del prompt. Se programó el validador léxico [`es_respuesta_en_espanol`](backend/server.py) que descarta en tiempo real cualquier salida con marcadores en inglés y activa al instante el respaldo en español.

### Fase 3: Menú Principal, Pantallas de Fin de Juicio y Anti-Bloqueo (`Commit d523fae`)
1. Se construyó el **Menú Principal 8-Bit** (`_construir_menu_principal()` en [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd)) permitiendo elegir cualquiera de los 4 casos éticos, leer su expediente completo y seleccionar entre las 3 dificultades (`SENCILLA`, `NORMAL`, `DIFÍCIL`).
2. Se añadieron las pantallas interactivas y animaciones de **`🏆 ¡VICTORIA MAGISTRAL!`** (lluvia de confeti pixelado de 40 partículas y derrota del fiscal) y **`⚖️ DERROTA EN EL TRIBUNAL`** (lluvia sombría y mazo implacable del Juez), con botones de revancha y retorno al menú.
3. **Arquitectura Anti-Bloqueo de Doble Capa:**
   - En el servidor ([`backend/server.py`](backend/server.py)): `ThreadPoolExecutor` con timeout rígido de `3.2s` por turno y lista `MODELOS_PENALIZADOS` en memoria para no volver a consultar proveedores caídos o sin cuota.
   - En el cliente Godot ([`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd)): Watchdog en `_process(delta)` (`TIEMPO_MAX_ESPERA = 5.8s`) + sondeo rápido `/health` (`0.5s`) al abrir el menú para conmutar a latencia `0.0s` cuando no hay servidor.

### Fase 4: Empaquetado Multi-Dispositivo (`Windows .exe` y `Web HTML5/WASM`) (`Commits 0896365 .. e678db1`)
1. Se portó toda la lógica y banco de casos de Python a GDScript nativo en [`CasesDatabase.gd`](godot_project/scripts/CasesDatabase.gd).
2. Se configuraron las plantillas oficiales de exportación de Godot 4.7.2 en [`export_presets.cfg`](godot_project/export_presets.cfg) generando:
   - **Ejecutable Portátil Windows x86_64:** `builds/windows/JuicioLogico8Bit.exe` y `builds/JuicioLogico8Bit_Windows_Portable.zip`.
   - **Versión Web Multiplataforma (PC, Android, iOS, macOS, Linux):** `builds/web/index.html` (`index.wasm` + `index.pck`) y `builds/JuicioLogico8Bit_Web.zip`.

### Fase 5: Ingeniería de Testing Exhaustivo (Caja Blanca, Caja Negra y Playtesting Visual/Caos) (`Commits de77660 .. 62c56b7`)
Se sometió el videojuego a tres niveles completos de aseguramiento de calidad (QA):

1. **Testing de Caja Blanca (Estructural Método por Método):**
   - Documentado en [`REPORTE_TESTING_CAJA_BLANCA.md`](REPORTE_TESTING_CAJA_BLANCA.md).
   - Suites creadas: [`tests/test_caja_blanca_backend.py`](tests/test_caja_blanca_backend.py) (`9/9` métodos de Python, `52/52` aserciones `PASS`) y [`godot_project/scripts/TestCajaBlancaGodot.gd`](godot_project/scripts/TestCajaBlancaGodot.gd) (`31/31` métodos de GDScript, `59/59` aserciones `PASS`).
2. **Testing de Caja Negra (Funcional, Valores Límite, Tablas de Decisión, Fuzzing y Estrés Concurrente):**
   - Documentado en [`REPORTE_TESTING_CAJA_NEGRA.md`](REPORTE_TESTING_CAJA_NEGRA.md).
   - Suites creadas: [`tests/test_caja_negra_sistema.py`](tests/test_caja_negra_sistema.py) (`17/17` casos de prueba del sistema, **24 hilos concurrentes**, `3,165 / 3,165` aserciones `PASS`) y [`godot_project/scripts/TestCajaNegraGodot.gd`](godot_project/scripts/TestCajaNegraGodot.gd) (`8/8` flujos E2E de usuario, `59/59` aserciones `PASS`).
3. **Playtesting Visual en Pantalla y Pruebas de Caos (*Monkey Testing*):**
   - Mediante [`PlaytestVisualYCaos.gd`](godot_project/scripts/PlaytestVisualYCaos.gd) y [`PartidaEnVivoPantalla.gd`](godot_project/scripts/PartidaEnVivoPantalla.gd), se jugaron partidas reales renderizadas en pantalla hasta `0 HP` y se descubrieron y corrigieron **4 bugs sutiles**:
     - **Bug 1 (Animación hablante y destello congelado):** Se sincronizó `stage.speaker_state = "RIVAL"` al recibir el alegato fiscal y se limpiaron `flash_player_timer`/`flash_rival_timer` al terminar el juicio.
     - **Bug 2 (Solapamiento del cartel superior con la peluca del Juez):** Se reajustó la geometría de los carteles en [`PixelCourtStage.gd`](godot_project/scripts/PixelCourtStage.gd) (`y = 8`, `alto = 34px`, ocultando la balanza mientras hay cartel) dejando el rostro del Juez 100% despejado.
     - **Bug 3 (Exploit de Spam Infinito del botón `¡OBJECIÓN!`):** Antes, objetar no avanzaba `turno_idx` ni bloqueaba la objeción en el turno siguiente. Se añadió `turno_idx += 1` y enfriamiento de 1 turno (`"OBJECIÓN USADA (ELIGE ARGUMENTO 1-4)"`), obligando al jugador a alternar objeción con argumentación ética.
     - **Bug 4 (Relleno residual en barra de vida a `0 HP`):** Se eliminó el margen interno (`pad = 0`) del `StyleBoxFlat` en las barras de vida para que `0 / 100 HP` se vea visualmente vacío al 100%.

### Fase 6: Identidad Visual y Pulido de Interfaz (`Commits 1711214 .. ca1c3cd`)
1. **Inmersión Narrativa sin Rastros de IA:** Se eliminaron de la interfaz todos los textos técnicos que mencionaban inteligencia artificial (`[IA: ...]`, `Contrincante IA`, `Motor-Autónomo-MultiDispositivo`), sustituyéndolos por un único indicador visual discreto (`●`) en la esquina superior derecha:
   - **Punto Verde (`●` `#38b764`):** Conectado al servidor local.
   - **Punto Rojo (`●` `#e43b44`):** Servidor apagado (ejecutándose en modo autónomo local).
2. **Título Oficial del Juego:** Se bautizó el juego en el Menú Principal y en la ventana de Godot como **`⚖️  ¡OBJECIÓN! CÓDIGO DE HONOR  ⚖️`** (*Crónicas del Estrado — Elige el Expediente y el Nivel del Tribunal*).

### Fase 7: Endurecimiento de Seguridad y Privacidad Pre-Distribución (`Commits 23f5f72 .. ae9e42e`)
Documentado en [`REPORTE_SEGURIDAD_PRE_DISTRIBUCION.md`](REPORTE_SEGURIDAD_PRE_DISTRIBUCION.md) y verificado por [`tests/test_seguridad_pre_distribucion.py`](tests/test_seguridad_pre_distribucion.py) (`199 / 199` aserciones de seguridad `PASS`):
1. Se eliminó `_guardar_captura_verificacion()` en [`MainCourtroom.gd`](godot_project/scripts/MainCourtroom.gd) y cualquier ruta local del equipo del desarrollador.
2. Se excluyeron todos los scripts de prueba (`scripts/Test*`, `scripts/Playtest*`, `scripts/PartidaEnVivo*`) y archivos `.env*` del empaquetado de producción en [`export_presets.cfg`](godot_project/export_presets.cfg).
3. Se blindó [`backend/server.py`](backend/server.py) cerrando `/docs`, `/redoc` y `/openapi.json` (`HTTP 404`), añadiendo 5 cabeceras de seguridad OWASP, bloqueando cargas útiles mayores a `128 KB` (`HTTP 413`) y suprimiendo cualquier filtración de excepciones internas.
4. Se escaneó byte a byte el binario `JuicioLogico8Bit.exe` y el paquete `index.pck` comprobando **0 fugas** de claves API, rutas privadas o código de prueba.

---

## 5. Resumen Global de Métricas de Calidad del Proyecto

| Dimensión Evaluada | Suite / Herramienta | Elementos Evaluados | Aserciones Superadas | Estado Final |
| :--- | :--- | :--- | :---: | :---: |
| **Caja Blanca (Backend Python)** | [`tests/test_caja_blanca_backend.py`](tests/test_caja_blanca_backend.py) | `9 / 9` métodos (`100%` cobertura de ramas) | `52 / 52` | ✅ **100% PASS** |
| **Caja Blanca (Cliente Godot 4)** | [`godot_project/scripts/TestCajaBlancaGodot.gd`](godot_project/scripts/TestCajaBlancaGodot.gd) | `31 / 31` métodos en 3 clases GDScript | `59 / 59` | ✅ **100% PASS** |
| **Caja Negra (Sistema & Estrés)** | [`tests/test_caja_negra_sistema.py`](tests/test_caja_negra_sistema.py) | `17 / 17` casos (EP, BVA, Tablas, Fuzzing, 24 hilos) | `3,165 / 3,165` | ✅ **100% PASS** |
| **Caja Negra (Flujos E2E Jugador)** | [`godot_project/scripts/TestCajaNegraGodot.gd`](godot_project/scripts/TestCajaNegraGodot.gd) | `8 / 8` escenarios de partida de extremo a extremo | `59 / 59` | ✅ **100% PASS** |
| **Playtesting Visual y Caos** | [`godot_project/scripts/PlaytestVisualYCaos.gd`](godot_project/scripts/PlaytestVisualYCaos.gd) | `7 / 7` escenarios visuales y ataques de mono | `100%` (4 bugs corregidos) | ✅ **100% PASS** |
| **Seguridad Pre-Distribución** | [`tests/test_seguridad_pre_distribucion.py`](tests/test_seguridad_pre_distribucion.py) | `4 / 4` dominios STRIDE / OWASP (Binarios, Sandbox, Git, API) | `199 / 199` | ✅ **100% PASS** |
| **TOTAL ACUMULADO** | **6 Suites Automatizadas** | **Código, UI, Red, Concurrencia y Binarios** | **`3,534 / 3,534`** | 🏆 ** CERTIFICADO** |
