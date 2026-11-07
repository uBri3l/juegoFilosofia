extends Control
## Controlador principal del videojuego 'Juicio Lógico 8-Bit'.
## Incluye:
## 1) Menú Principal para elegir Tema/Caso y Dificultad e iniciar partida.
## 2) Juzgado por turnos con 4 opciones (1 Infalible, 2 Medios, 1 Falacia) y botón de Objeción.
## 3) Watchdog Anti-Bloqueo (5.8s máx) para que NUNCA se quede trancado esperando respuesta.
## 4) Animaciones y pantalla interactiva de VICTORIA y DERROTA.

const BACKEND_URL: String = "http://127.0.0.1:8000/turno"
const PixelCourtStageScript = preload("res://scripts/PixelCourtStage.gd")
const CasesDatabaseScript = preload("res://scripts/CasesDatabase.gd")

var servidor_local_disponible: bool = true

const INFO_CASOS: Array[Dictionary] = [
	{
		"id": "caso_algoritmo_medico",
		"titulo": "Caso 1: El Algoritmo de Triaje Clínico",
		"tema": "Ingeniería de Software, Secreto (NDA) y Bioética",
		"rival": "Fiscal V. Krugger",
		"descripcion": "Una desarrolladora senior filtró a las autoridades sanitarias que el algoritmo de triaje de su hospital descartaba pacientes mayores de 65 años sin seguro VIP. La empresa la demanda por violar el acuerdo de confidencialidad (NDA)."
	},
	{
		"id": "caso_vertido_quimico",
		"titulo": "Caso 2: El Informe Hidrogeológico Oculto",
		"tema": "Secreto Profesional vs. Salud Pública Ambiental",
		"rival": "Fiscal M. Vance",
		"descripcion": "Un perito químico contratado por una minera descubrió arsénico filtrándose al acuífero de un pueblo vecino. Al negarse a ocultar su informe y alertar al municipio, piden su inhabilitación por deslealtad al cliente."
	},
	{
		"id": "caso_auditoria_contable",
		"titulo": "Caso 3: La Auditoría de Fondos de Pensiones",
		"tema": "Independencia Profesional, Fe Pública y Conflicto de Interés",
		"rival": "Fiscal D. Sterling",
		"descripcion": "Un auditor contable aprobó los balances de un fondo de pensiones donde su propio hermano era director financiero, ocultando pérdidas millonarias. Representas al Comité de Ética que exige su sanción."
	},
	{
		"id": "caso_ia_periodismo",
		"titulo": "Caso 4: Fuentes Fabricadas con IA en Investigación",
		"tema": "Ética Periodística, Rigor Documental y Veracidad",
		"rival": "Fiscal L. Valmont",
		"descripcion": "Un periodista utilizó IA generativa para recrear declaraciones de un supuesto testigo sin advertir al público que eran sintéticas, provocando el cierre injusto de una cooperativa local."
	}
]

const INFO_DIFICULTADES: Array[Dictionary] = [
	{
		"id": "FACIL",
		"nombre": "SENCILLA (Aprendiz de Lógica)",
		"detalle": "La máquina comete falacias con frecuencia (~60%) y rara vez detecta tus errores. Ideal para practicar identificación de falacias."
	},
	{
		"id": "NORMAL",
		"nombre": "NORMAL (Abogado Litigante)",
		"detalle": "Equilibrio entre falacias sutiles (35%), argumentos medios (45%) y argumentos sólidos (20%). La IA detecta el 80% de tus falacias."
	},
	{
		"id": "DIFICIL",
		"nombre": "DIFÍCIL (Magistrado Supremo)",
		"detalle": "La máquina elige los mejores argumentos éticos y es difícil que emita falacias (~15% para no ser invencible). Detecta el 95% de tus errores."
	}
]

var indice_caso_seleccionado: int = 0
var indice_dificultad_seleccionada: int = 1
var caso_id_actual: String = "caso_algoritmo_medico"
var dificultad_actual: String = "NORMAL"

var hp_jugador: int = 100
var hp_rival: int = 100
var turno_idx: int = 0
var juicio_terminado: bool = false
var esperando_respuesta: bool = false
var ya_objeto_este_turno: bool = false

# Watchdog para evitar cualquier bloqueo si la red o el LLM tardan demasiado
var tiempo_espera_actual: float = 0.0
const TIEMPO_MAX_ESPERA: float = 5.8
var ultima_accion_pendiente: String = "INICIAR_CASO"
var ultima_opcion_pendiente: Dictionary = {}

var declaracion_rival_actual: Dictionary = {}
var opciones_actuales: Array = []
var historial_resumido: Array[String] = []

# Contenedores principales de pantalla
var menu_container: Control
var game_container: Control

# Nodos del Menú Principal
var lbl_menu_caso_titulo: Label
var lbl_menu_caso_tema: Label
var lbl_menu_caso_desc: Label
var lbl_menu_dif_desc: Label
var btns_menu_casos: Array[Button] = []
var btns_menu_difs: Array[Button] = []

# Nodos de la Partida (Juzgado)
var stage: Control
var lbl_titulo_partida: Label
var lbl_hp_jugador: Label
var bar_hp_jugador: ProgressBar
var lbl_hp_rival: Label
var bar_hp_rival: ProgressBar
var lbl_modelo_ia: Label
var lbl_juez_feedback: Label
var lbl_nombre_hablante: Label
var lbl_dialogo_rival: RichTextLabel
var btn_objecion_falacia: Button
var grid_opciones: GridContainer
var botones_opciones: Array[Button] = []
var endgame_panel: PanelContainer
var lbl_endgame_titulo: Label
var lbl_endgame_subtitulo: Label
var http_req: HTTPRequest


func _ready() -> void:
	_centrar_ventana_en_pantalla()
	http_req = HTTPRequest.new()
	http_req.timeout = 5.2
	add_child(http_req)
	http_req.request_completed.connect(_on_litellm_response)

	_construir_menu_principal()
	_construir_interfaz_juzgado()
	mostrar_menu_principal()


func _process(delta: float) -> void:
	# Watchdog Anti-Bloqueo: si esperando_respuesta lleva más de TIEMPO_MAX_ESPERA,
	# cancela la espera colgada y resuelve el turno inmediatamente sin trancar el juego.
	if esperando_respuesta:
		tiempo_espera_actual += delta
		if tiempo_espera_actual >= TIEMPO_MAX_ESPERA:
			tiempo_espera_actual = 0.0
			http_req.cancel_request()
			lbl_modelo_ia.text = "[IA: Respuesta Rápida Local]"
			_aplicar_respaldo_offline_en_godot(ultima_accion_pendiente, ultima_opcion_pendiente)


func _centrar_ventana_en_pantalla() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect()
	var win_size: Vector2i = Vector2i(900, 540)
	if screen_rect.size.x > 0 and screen_rect.size.y > 0:
		win_size.x = mini(900, screen_rect.size.x - 40)
		win_size.y = mini(540, screen_rect.size.y - 60)
		DisplayServer.window_set_size(win_size)
		var pos_x: int = screen_rect.position.x + int((screen_rect.size.x - win_size.x) / 2)
		var pos_y: int = screen_rect.position.y + int((screen_rect.size.y - win_size.y) / 2)
		DisplayServer.window_set_position(Vector2i(max(10, pos_x), max(10, pos_y)))
	DisplayServer.window_move_to_foreground()


func _guardar_captura_verificacion() -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_tex: ViewportTexture = get_viewport().get_texture()
	if viewport_tex:
		var img: Image = viewport_tex.get_image()
		if img:
			img.save_png("c:/Users/gabri/OneDrive/Escritorio/juegoFilosofia/captura_juego.png")


func _crear_estilo_caja(bg_hex: String, border_hex: String, border_w: int = 2, pad: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_hex)
	sb.border_color = Color(border_hex)
	sb.set_border_width_all(border_w)
	sb.set_content_margin_all(pad)
	return sb


# ============================================================================
# 1. MENÚ PRINCIPAL 8-BIT (SELECCIÓN DE TEMA/CASO Y DIFICULTAD)
# ============================================================================
func _construir_menu_principal() -> void:
	menu_container = PanelContainer.new()
	menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	menu_container.add_theme_stylebox_override("panel", _crear_estilo_caja("#121526", "#feae34", 3, 14))
	add_child(menu_container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	menu_container.add_child(vbox)

	# Encabezado retro del menú
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#1f2438", "#fee761", 2, 10))
	vbox.add_child(header_panel)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_panel.add_child(header_vbox)

	var lbl_titulo := Label.new()
	lbl_titulo.text = "⚖️ JUICIO LÓGICO 8-BIT: FALACIAS, ARGUMENTOS Y ÉTICA PROFESIONAL ⚖️"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_color_override("font_color", Color("#fee761"))
	lbl_titulo.add_theme_font_size_override("font_size", 18)
	header_vbox.add_child(lbl_titulo)

	var lbl_sub := Label.new()
	lbl_sub.text = "Selecciona el Tema de Ética Profesional y la Dificultad del Abogado Rival (IA con LiteLLM)"
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_color_override("font_color", Color("#2ce8f5"))
	lbl_sub.add_theme_font_size_override("font_size", 12)
	header_vbox.add_child(lbl_sub)

	# Cuerpo central del menú: Columna izquierda (Temas/Casos) y Columna derecha (Detalles + Dificultad)
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(body_hbox)

	# Columna Izquierda: Selección de Tema / Caso
	var casos_panel := PanelContainer.new()
	casos_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	casos_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#181c30", "#5a6988", 2, 10))
	body_hbox.add_child(casos_panel)

	var casos_vbox := VBoxContainer.new()
	casos_vbox.add_theme_constant_override("separation", 8)
	casos_panel.add_child(casos_vbox)

	var lbl_sel_caso := Label.new()
	lbl_sel_caso.text = "1. ELIGE EL TEMA / CASO DEL JUICIO:"
	lbl_sel_caso.add_theme_color_override("font_color", Color("#fee761"))
	lbl_sel_caso.add_theme_font_size_override("font_size", 13)
	casos_vbox.add_child(lbl_sel_caso)

	btns_menu_casos.clear()
	for i in range(INFO_CASOS.size()):
		var c_info: Dictionary = INFO_CASOS[i]
		var btn_c := Button.new()
		btn_c.text = c_info["titulo"] + "\n[" + c_info["tema"] + "]"
		btn_c.custom_minimum_size = Vector2(0, 50)
		btn_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_c.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn_c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_c.add_theme_font_size_override("font_size", 11)
		var idx_c: int = i
		btn_c.pressed.connect(func(): _seleccionar_caso_en_menu(idx_c))
		casos_vbox.add_child(btn_c)
		btns_menu_casos.append(btn_c)

	# Columna Derecha: Resumen del Caso + Selector de Dificultad
	var der_vbox := VBoxContainer.new()
	der_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der_vbox.add_theme_constant_override("separation", 10)
	body_hbox.add_child(der_vbox)

	var desc_panel := PanelContainer.new()
	desc_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#1d2238", "#29adff", 2, 10))
	der_vbox.add_child(desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 6)
	desc_panel.add_child(desc_vbox)

	lbl_menu_caso_titulo = Label.new()
	lbl_menu_caso_titulo.add_theme_color_override("font_color", Color("#2ce8f5"))
	lbl_menu_caso_titulo.add_theme_font_size_override("font_size", 14)
	lbl_menu_caso_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(lbl_menu_caso_titulo)

	lbl_menu_caso_tema = Label.new()
	lbl_menu_caso_tema.add_theme_color_override("font_color", Color("#feae34"))
	lbl_menu_caso_tema.add_theme_font_size_override("font_size", 12)
	lbl_menu_caso_tema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(lbl_menu_caso_tema)

	lbl_menu_caso_desc = Label.new()
	lbl_menu_caso_desc.add_theme_color_override("font_color", Color("#ffffff"))
	lbl_menu_caso_desc.add_theme_font_size_override("font_size", 12)
	lbl_menu_caso_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_vbox.add_child(lbl_menu_caso_desc)

	# Panel de Dificultad
	var dif_panel := PanelContainer.new()
	dif_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#181c30", "#5a6988", 2, 10))
	der_vbox.add_child(dif_panel)

	var dif_vbox := VBoxContainer.new()
	dif_vbox.add_theme_constant_override("separation", 6)
	dif_panel.add_child(dif_vbox)

	var lbl_sel_dif := Label.new()
	lbl_sel_dif.text = "2. ELIGE LA DIFICULTAD DEL JUICIO:"
	lbl_sel_dif.add_theme_color_override("font_color", Color("#fee761"))
	lbl_sel_dif.add_theme_font_size_override("font_size", 13)
	dif_vbox.add_child(lbl_sel_dif)

	var dif_btns_hbox := HBoxContainer.new()
	dif_btns_hbox.add_theme_constant_override("separation", 6)
	dif_vbox.add_child(dif_btns_hbox)

	btns_menu_difs.clear()
	var nombres_cortos: Array[String] = ["SENCILLA", "NORMAL", "DIFÍCIL"]
	for j in range(INFO_DIFICULTADES.size()):
		var btn_d := Button.new()
		btn_d.text = nombres_cortos[j]
		btn_d.custom_minimum_size = Vector2(0, 34)
		btn_d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_d.add_theme_font_size_override("font_size", 12)
		var idx_d: int = j
		btn_d.pressed.connect(func(): _seleccionar_dificultad_en_menu(idx_d))
		dif_btns_hbox.add_child(btn_d)
		btns_menu_difs.append(btn_d)

	lbl_menu_dif_desc = Label.new()
	lbl_menu_dif_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_menu_dif_desc.add_theme_color_override("font_color", Color("#c0cbdc"))
	lbl_menu_dif_desc.add_theme_font_size_override("font_size", 11)
	dif_vbox.add_child(lbl_menu_dif_desc)

	# Botón grande de Iniciar Partida
	var btn_jugar := Button.new()
	btn_jugar.text = "⚖️  ¡INICIAR PARTIDA Y ENTRAR AL JUZGADO!  ⚖️"
	btn_jugar.custom_minimum_size = Vector2(0, 48)
	btn_jugar.add_theme_font_size_override("font_size", 16)
	btn_jugar.add_theme_stylebox_override("normal", _crear_estilo_caja("#265c42", "#63c74d", 3, 8))
	btn_jugar.add_theme_stylebox_override("hover", _crear_estilo_caja("#38b764", "#fee761", 3, 8))
	btn_jugar.add_theme_color_override("font_color", Color("#ffffff"))
	btn_jugar.pressed.connect(comenzar_partida_desde_menu)
	vbox.add_child(btn_jugar)

	_seleccionar_caso_en_menu(0)
	_seleccionar_dificultad_en_menu(1)


func _seleccionar_caso_en_menu(idx: int) -> void:
	indice_caso_seleccionado = clampi(idx, 0, INFO_CASOS.size() - 1)
	var info: Dictionary = INFO_CASOS[indice_caso_seleccionado]
	caso_id_actual = info["id"]
	lbl_menu_caso_titulo.text = info["titulo"]
	lbl_menu_caso_tema.text = "Tema: " + info["tema"] + " | Rival: " + info["rival"]
	lbl_menu_caso_desc.text = info["descripcion"]

	for i in range(btns_menu_casos.size()):
		if i == indice_caso_seleccionado:
			btns_menu_casos[i].add_theme_stylebox_override("normal", _crear_estilo_caja("#29366f", "#fee761", 2, 6))
			btns_menu_casos[i].add_theme_color_override("font_color", Color("#fee761"))
		else:
			btns_menu_casos[i].add_theme_stylebox_override("normal", _crear_estilo_caja("#1d2b53", "#3a4466", 1, 6))
			btns_menu_casos[i].add_theme_color_override("font_color", Color("#c0cbdc"))


func _seleccionar_dificultad_en_menu(idx: int) -> void:
	indice_dificultad_seleccionada = clampi(idx, 0, INFO_DIFICULTADES.size() - 1)
	var d_info: Dictionary = INFO_DIFICULTADES[indice_dificultad_seleccionada]
	dificultad_actual = d_info["id"]
	lbl_menu_dif_desc.text = d_info["nombre"] + ": " + d_info["detalle"]

	for i in range(btns_menu_difs.size()):
		if i == indice_dificultad_seleccionada:
			btns_menu_difs[i].add_theme_stylebox_override("normal", _crear_estilo_caja("#733e39", "#fee761", 2, 6))
			btns_menu_difs[i].add_theme_color_override("font_color", Color("#fee761"))
		else:
			btns_menu_difs[i].add_theme_stylebox_override("normal", _crear_estilo_caja("#262b44", "#5a6988", 1, 6))
			btns_menu_difs[i].add_theme_color_override("font_color", Color("#c0cbdc"))


func mostrar_menu_principal() -> void:
	esperando_respuesta = false
	tiempo_espera_actual = 0.0
	http_req.cancel_request()
	menu_container.visible = true
	game_container.visible = false
	_guardar_captura_verificacion()


func comenzar_partida_desde_menu() -> void:
	menu_container.visible = false
	game_container.visible = true
	iniciar_nuevo_juicio()


# ============================================================================
# 2. INTERFAZ DEL JUZGADO Y PANTALLA DE VICTORIA / DERROTA
# ============================================================================
func _construir_interfaz_juzgado() -> void:
	game_container = Control.new()
	game_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_container.visible = false
	add_child(game_container)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	root_vbox.add_theme_constant_override("separation", 5)
	game_container.add_child(root_vbox)

	# 1. Barra superior del juzgado
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#1f2438", "#5a6988", 2))
	root_vbox.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 8)
	top_panel.add_child(top_hbox)

	var btn_volver_menu := Button.new()
	btn_volver_menu.text = "⬅ MENÚ PRINCIPAL"
	btn_volver_menu.add_theme_font_size_override("font_size", 11)
	btn_volver_menu.add_theme_stylebox_override("normal", _crear_estilo_caja("#3e2731", "#feae34", 2, 5))
	btn_volver_menu.pressed.connect(mostrar_menu_principal)
	top_hbox.add_child(btn_volver_menu)

	lbl_titulo_partida = Label.new()
	lbl_titulo_partida.text = "Caso 1 | Dificultad: NORMAL"
	lbl_titulo_partida.add_theme_color_override("font_color", Color("#fee761"))
	lbl_titulo_partida.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(lbl_titulo_partida)

	var btn_reiniciar := Button.new()
	btn_reiniciar.text = "🔄 REINICIAR JUICIO"
	btn_reiniciar.add_theme_font_size_override("font_size", 11)
	btn_reiniciar.add_theme_stylebox_override("normal", _crear_estilo_caja("#1d2b53", "#2ce8f5", 2, 5))
	btn_reiniciar.add_theme_stylebox_override("hover", _crear_estilo_caja("#29366f", "#fee761", 2, 5))
	btn_reiniciar.pressed.connect(iniciar_nuevo_juicio)
	top_hbox.add_child(btn_reiniciar)

	lbl_modelo_ia = Label.new()
	lbl_modelo_ia.text = "[IA: Conectada]"
	lbl_modelo_ia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_modelo_ia.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_modelo_ia.clip_text = true
	lbl_modelo_ia.add_theme_color_override("font_color", Color("#63c74d"))
	lbl_modelo_ia.add_theme_font_size_override("font_size", 11)
	top_hbox.add_child(lbl_modelo_ia)

	# 2. Barras de Vida (HP)
	var hp_hbox := HBoxContainer.new()
	hp_hbox.add_theme_constant_override("separation", 14)
	root_vbox.add_child(hp_hbox)

	var vbox_hp_p := VBoxContainer.new()
	vbox_hp_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_hbox.add_child(vbox_hp_p)

	lbl_hp_jugador = Label.new()
	lbl_hp_jugador.text = "TU CREDIBILIDAD (DEFENSA): 100 / 100 HP"
	lbl_hp_jugador.add_theme_color_override("font_color", Color("#2ce8f5"))
	lbl_hp_jugador.add_theme_font_size_override("font_size", 12)
	vbox_hp_p.add_child(lbl_hp_jugador)

	bar_hp_jugador = ProgressBar.new()
	bar_hp_jugador.max_value = 100
	bar_hp_jugador.value = 100
	bar_hp_jugador.show_percentage = false
	bar_hp_jugador.custom_minimum_size = Vector2(0, 14)
	bar_hp_jugador.add_theme_stylebox_override("background", _crear_estilo_caja("#262b44", "#ffffff", 1))
	bar_hp_jugador.add_theme_stylebox_override("fill", _crear_estilo_caja("#38b764", "#ffffff", 0))
	vbox_hp_p.add_child(bar_hp_jugador)

	var vbox_hp_r := VBoxContainer.new()
	vbox_hp_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_hbox.add_child(vbox_hp_r)

	lbl_hp_rival = Label.new()
	lbl_hp_rival.text = "CREDIBILIDAD ABOGADO RIVAL (IA): 100 / 100 HP"
	lbl_hp_rival.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_hp_rival.add_theme_color_override("font_color", Color("#ff7777"))
	lbl_hp_rival.add_theme_font_size_override("font_size", 12)
	vbox_hp_r.add_child(lbl_hp_rival)

	bar_hp_rival = ProgressBar.new()
	bar_hp_rival.max_value = 100
	bar_hp_rival.value = 100
	bar_hp_rival.show_percentage = false
	bar_hp_rival.custom_minimum_size = Vector2(0, 14)
	bar_hp_rival.add_theme_stylebox_override("background", _crear_estilo_caja("#262b44", "#ffffff", 1))
	bar_hp_rival.add_theme_stylebox_override("fill", _crear_estilo_caja("#e43b44", "#ffffff", 0))
	vbox_hp_r.add_child(bar_hp_rival)

	# 3. Escenario 2D 8-Bit del Juzgado (con animaciones de Victoria/Derrota)
	stage = PixelCourtStageScript.new()
	stage.custom_minimum_size = Vector2(0, 152)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(stage)

	# 4. Veredicto / Retroalimentación del Juez
	var juez_panel := PanelContainer.new()
	juez_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#2a1d2e", "#feae34", 2))
	root_vbox.add_child(juez_panel)

	lbl_juez_feedback = Label.new()
	lbl_juez_feedback.text = "JUEZ: El tribunal está en sesión."
	lbl_juez_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_juez_feedback.add_theme_color_override("font_color", Color("#fee761"))
	lbl_juez_feedback.add_theme_font_size_override("font_size", 12)
	juez_panel.add_child(lbl_juez_feedback)

	# 5. Cuadro de Diálogo del Abogado Rival + Botón de Marcar Falacia
	var dialogo_panel := PanelContainer.new()
	dialogo_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#14182e", "#ffffff", 2))
	root_vbox.add_child(dialogo_panel)

	var dialogo_vbox := VBoxContainer.new()
	dialogo_panel.add_child(dialogo_vbox)

	var header_dialogo := HBoxContainer.new()
	dialogo_vbox.add_child(header_dialogo)

	lbl_nombre_hablante = Label.new()
	lbl_nombre_hablante.text = "ABOGADO CONTRINCANTE (IA):"
	lbl_nombre_hablante.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre_hablante.add_theme_color_override("font_color", Color("#ff6b6b"))
	lbl_nombre_hablante.add_theme_font_size_override("font_size", 12)
	header_dialogo.add_child(lbl_nombre_hablante)

	btn_objecion_falacia = Button.new()
	btn_objecion_falacia.text = "¡OBJECIÓN! MARCAR DECLARACIÓN COMO FALACIA"
	btn_objecion_falacia.add_theme_font_size_override("font_size", 12)
	btn_objecion_falacia.add_theme_stylebox_override("normal", _crear_estilo_caja("#9e2835", "#fee761", 2))
	btn_objecion_falacia.add_theme_stylebox_override("hover", _crear_estilo_caja("#e43b44", "#ffffff", 2))
	btn_objecion_falacia.add_theme_color_override("font_color", Color("#ffffff"))
	btn_objecion_falacia.pressed.connect(_on_marcar_falacia_pressed)
	header_dialogo.add_child(btn_objecion_falacia)

	lbl_dialogo_rival = RichTextLabel.new()
	lbl_dialogo_rival.custom_minimum_size = Vector2(0, 44)
	lbl_dialogo_rival.fit_content = true
	lbl_dialogo_rival.scroll_active = false
	lbl_dialogo_rival.add_theme_font_size_override("normal_font_size", 13)
	dialogo_vbox.add_child(lbl_dialogo_rival)

	# 6. Cuadrícula de 4 Opciones de Argumento para el Jugador
	grid_opciones = GridContainer.new()
	grid_opciones.columns = 2
	grid_opciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_opciones.add_theme_constant_override("h_separation", 8)
	grid_opciones.add_theme_constant_override("v_separation", 6)
	root_vbox.add_child(grid_opciones)

	botones_opciones.clear()
	for i in range(4):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_stylebox_override("normal", _crear_estilo_caja("#1d2b53", "#29adff", 2))
		btn.add_theme_stylebox_override("hover", _crear_estilo_caja("#29366f", "#fee761", 2))
		var idx_capturado: int = i
		btn.pressed.connect(func(): _on_opcion_argumento_elegida(idx_capturado))
		grid_opciones.add_child(btn)
		botones_opciones.append(btn)

	# 7. Panel Especial de Fin de Partida (Victoria / Derrota)
	endgame_panel = PanelContainer.new()
	endgame_panel.visible = false
	endgame_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	endgame_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#1f2438", "#fee761", 3, 10))
	root_vbox.add_child(endgame_panel)

	var end_vbox := VBoxContainer.new()
	end_vbox.add_theme_constant_override("separation", 8)
	endgame_panel.add_child(end_vbox)

	lbl_endgame_titulo = Label.new()
	lbl_endgame_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_endgame_titulo.add_theme_font_size_override("font_size", 16)
	end_vbox.add_child(lbl_endgame_titulo)

	lbl_endgame_subtitulo = Label.new()
	lbl_endgame_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_endgame_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_endgame_subtitulo.add_theme_font_size_override("font_size", 12)
	end_vbox.add_child(lbl_endgame_subtitulo)

	var end_btns := HBoxContainer.new()
	end_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	end_btns.add_theme_constant_override("separation", 16)
	end_vbox.add_child(end_btns)

	var btn_revancha := Button.new()
	btn_revancha.text = "🔄 JUGAR REVANCHA EN ESTE CASO"
	btn_revancha.custom_minimum_size = Vector2(260, 38)
	btn_revancha.add_theme_stylebox_override("normal", _crear_estilo_caja("#265c42", "#63c74d", 2, 6))
	btn_revancha.pressed.connect(iniciar_nuevo_juicio)
	end_btns.add_child(btn_revancha)

	var btn_ir_menu := Button.new()
	btn_ir_menu.text = "🏠 VOLVER AL MENÚ PRINCIPAL (CAMBIAR CASO)"
	btn_ir_menu.custom_minimum_size = Vector2(310, 38)
	btn_ir_menu.add_theme_stylebox_override("normal", _crear_estilo_caja("#29366f", "#fee761", 2, 6))
	btn_ir_menu.pressed.connect(mostrar_menu_principal)
	end_btns.add_child(btn_ir_menu)


func iniciar_nuevo_juicio() -> void:
	hp_jugador = 100
	hp_rival = 100
	turno_idx = 0
	juicio_terminado = false
	ya_objeto_este_turno = false
	historial_resumido.clear()
	declaracion_rival_actual = {}

	stage.reset_stage()
	grid_opciones.visible = true
	endgame_panel.visible = false

	var c_info: Dictionary = INFO_CASOS[indice_caso_seleccionado]
	lbl_titulo_partida.text = c_info["titulo"] + "  |  Dificultad: " + dificultad_actual
	lbl_nombre_hablante.text = c_info["rival"].to_upper() + " (CONTRINCANTE IA):"

	_actualizar_barras_vida()
	lbl_juez_feedback.text = "JUEZ: Juicio iniciado en dificultad " + dificultad_actual + ". Escuchemos el alegato inicial."
	_solicitar_turno_litellm("INICIAR_CASO", {})


func _actualizar_barras_vida() -> void:
	hp_jugador = clampi(hp_jugador, 0, 100)
	hp_rival = clampi(hp_rival, 0, 100)
	bar_hp_jugador.value = hp_jugador
	bar_hp_rival.value = hp_rival
	lbl_hp_jugador.text = "TU CREDIBILIDAD (DEFENSA): %d / 100 HP" % hp_jugador
	lbl_hp_rival.text = "CREDIBILIDAD ABOGADO RIVAL (IA): %d / 100 HP" % hp_rival


func _set_botones_habilitados(habilitado: bool) -> void:
	esperando_respuesta = not habilitado
	if not esperando_respuesta:
		tiempo_espera_actual = 0.0
	btn_objecion_falacia.disabled = (not habilitado) or ya_objeto_este_turno or juicio_terminado
	for b in botones_opciones:
		b.disabled = (not habilitado) or juicio_terminado


func _on_marcar_falacia_pressed() -> void:
	if esperando_respuesta or juicio_terminado or ya_objeto_este_turno:
		return
	ya_objeto_este_turno = true
	turno_idx += 1
	stage.trigger_objection("¡OBJECIÓN! ¡ES UNA FALACIA!")
	stage.speaker_state = "JUGADOR"
	_solicitar_turno_litellm("MARCAR_FALACIA", {})


func _on_opcion_argumento_elegida(idx: int) -> void:
	if esperando_respuesta or juicio_terminado or idx >= opciones_actuales.size():
		return
	var opcion: Dictionary = opciones_actuales[idx]
	stage.speaker_state = "JUGADOR"
	turno_idx += 1
	ya_objeto_este_turno = false
	_solicitar_turno_litellm("ARGUMENTAR", opcion)


func _solicitar_turno_litellm(accion: String, opcion_elegida: Dictionary) -> void:
	ultima_accion_pendiente = accion
	ultima_opcion_pendiente = opcion_elegida
	tiempo_espera_actual = 0.0
	_set_botones_habilitados(false)

	if OS.has_feature("web") or not servidor_local_disponible:
		_aplicar_respaldo_offline_en_godot(accion, opcion_elegida)
		return

	lbl_modelo_ia.text = "[IA: Analizando jugada...]"
	http_req.cancel_request()

	var payload: Dictionary = {
		"caso_id": caso_id_actual,
		"dificultad": dificultad_actual,
		"hp_jugador": hp_jugador,
		"hp_rival": hp_rival,
		"accion_jugador": accion,
		"declaracion_previa_rival": declaracion_rival_actual,
		"opcion_elegida": opcion_elegida,
		"historial_resumido": historial_resumido,
		"turno_idx": turno_idx
	}

	var headers: PackedStringArray = ["Content-Type: application/json"]
	var err: Error = http_req.request(BACKEND_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		servidor_local_disponible = false
		_aplicar_respaldo_offline_en_godot(accion, opcion_elegida)


func _on_litellm_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not esperando_respuesta:
		return

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if result == HTTPRequest.RESULT_CANT_CONNECT:
			servidor_local_disponible = false
		lbl_modelo_ia.text = "[IA: Motor Autónomo]"
		_aplicar_respaldo_offline_en_godot(ultima_accion_pendiente, ultima_opcion_pendiente)
		return

	var json_str: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		_aplicar_respaldo_offline_en_godot(ultima_accion_pendiente, ultima_opcion_pendiente)
		return

	_procesar_datos_turno(parsed)


func _mostrar_pantalla_fin_de_juego(es_victoria: bool) -> void:
	juicio_terminado = true
	_set_botones_habilitados(false)
	grid_opciones.visible = false
	endgame_panel.visible = true

	if es_victoria:
		stage.trigger_victory_animation()
		endgame_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#193328", "#63c74d", 3, 10))
		lbl_endgame_titulo.text = "🏆 ¡VICTORIA MAGISTRAL! HAS GANADO EL JUICIO 🏆"
		lbl_endgame_titulo.add_theme_color_override("font_color", Color("#fee761"))
		lbl_endgame_subtitulo.text = "Desmontaste las falacias del fiscal con principios de ética profesional y argumentos infalibles."
		lbl_juez_feedback.text = "¡VEREDICTO FINAL: HA LUGAR A LA DEFENSA! El tribunal falla a tu favor."
		_mostrar_dialogo_rival("¡Imposible! ¡Mi argumentación ha sido completamente refutada ante este tribunal!")
	else:
		stage.trigger_defeat_animation()
		endgame_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#33141e", "#ff0044", 3, 10))
		lbl_endgame_titulo.text = "⚖️ DERROTA EN EL TRIBUNAL: CREDIBILIDAD AGOTADA ⚖️"
		lbl_endgame_titulo.add_theme_color_override("font_color", Color("#ff7777"))
		lbl_endgame_subtitulo.text = "Las falacias cometidas y las objeciones fallidas debilitaron tu postura ética ante el juez."
		lbl_juez_feedback.text = "VEREDICTO FINAL: NO HA LUGAR. La fiscalía se impone en este caso."
		_mostrar_dialogo_rival("Sus errores de razonamiento lógico han quedado expuestos. ¡El caso está cerrado!")

	_guardar_captura_verificacion()


func _procesar_datos_turno(datos: Dictionary) -> void:
	var modelo: String = str(datos.get("modelo_usado", "LiteLLM"))
	lbl_modelo_ia.text = "[IA: " + modelo + "]"

	var dano_r: int = int(datos.get("dano_al_rival", 0))
	var dano_j: int = int(datos.get("dano_al_jugador", 0))

	if dano_r > 0:
		hp_rival -= dano_r
		stage.trigger_damage_flash("RIVAL")
	if dano_j > 0:
		hp_jugador -= dano_j
		stage.trigger_damage_flash("JUGADOR")
		if bool(datos.get("rival_detecto_falacia_jugador", false)):
			stage.trigger_objection("¡FALACIA DETECTADA!")

	_actualizar_barras_vida()

	var veredicto: String = str(datos.get("veredicto_juez", ""))
	lbl_juez_feedback.text = "JUEZ: " + veredicto

	if hp_rival <= 0:
		_mostrar_pantalla_fin_de_juego(true)
		return
	elif hp_jugador <= 0:
		_mostrar_pantalla_fin_de_juego(false)
		return

	declaracion_rival_actual = datos.get("declaracion_rival", {})
	var texto_rival: String = str(declaracion_rival_actual.get("dialogo", ""))
	stage.speaker_state = "RIVAL"
	_mostrar_dialogo_rival(texto_rival)

	opciones_actuales = datos.get("opciones_jugador", [])
	for i in range(botones_opciones.size()):
		if i < opciones_actuales.size():
			var op: Dictionary = opciones_actuales[i]
			botones_opciones[i].text = "%d) %s" % [i + 1, str(op.get("texto", ""))]
		else:
			botones_opciones[i].text = "-"

	if ultima_accion_pendiente == "MARCAR_FALACIA":
		ya_objeto_este_turno = true
		btn_objecion_falacia.text = "OBJECIÓN USADA (ELIGE ARGUMENTO 1-4)"
	else:
		ya_objeto_este_turno = false
		btn_objecion_falacia.text = "¡OBJECIÓN! MARCAR DECLARACIÓN COMO FALACIA"
	_set_botones_habilitados(true)
	_guardar_captura_verificacion()


func _mostrar_dialogo_rival(texto: String) -> void:
	lbl_dialogo_rival.text = texto
	lbl_dialogo_rival.visible_characters = -1


func _aplicar_respaldo_offline_en_godot(accion: String, opcion_elegida: Dictionary) -> void:
	var datos: Dictionary = CasesDatabaseScript.generar_turno_autonomo(
		caso_id_actual,
		dificultad_actual,
		accion,
		declaracion_rival_actual,
		opcion_elegida,
		turno_idx
	)
	_procesar_datos_turno(datos)
