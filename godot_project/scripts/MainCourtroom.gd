extends Control
## Controlador principal del videojuego 'Juicio Lógico 8-Bit'.
## Conecta Godot con el servidor LiteLLM (http://127.0.0.1:8000/turno)
## y gestiona barras de vida, turnos, 4 opciones de argumento y el botón de marcar falacia.

const BACKEND_URL: String = "http://127.0.0.1:8000/turno"
const PixelCourtStageScript = preload("res://scripts/PixelCourtStage.gd")

var caso_id_actual: String = "caso_algoritmo_medico"
var dificultad_actual: String = "NORMAL" # "FACIL" | "NORMAL" | "DIFICIL"

var hp_jugador: int = 100
var hp_rival: int = 100
var turno_idx: int = 0
var juicio_terminado: bool = false
var esperando_respuesta: bool = false
var ya_objeto_este_turno: bool = false

var declaracion_rival_actual: Dictionary = {}
var opciones_actuales: Array = []
var historial_resumido: Array[String] = []

# Nodos de UI creados dinámicamente con estética 8-bit
var stage: Control
var lbl_hp_jugador: Label
var bar_hp_jugador: ProgressBar
var lbl_hp_rival: Label
var bar_hp_rival: ProgressBar
var lbl_modelo_ia: Label
var lbl_juez_feedback: Label
var lbl_nombre_hablante: Label
var lbl_dialogo_rival: RichTextLabel
var btn_objecion_falacia: Button
var botones_opciones: Array[Button] = []
var selector_caso: OptionButton
var selector_dificultad: OptionButton
var http_req: HTTPRequest

# Efecto máquina de escribir 8-bit
var texto_meta_dialogo: String = ""
var chars_visibles: float = 0.0


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_move_to_foreground()
	_construir_interfaz_8bit()
	http_req = HTTPRequest.new()
	add_child(http_req)
	http_req.request_completed.connect(_on_litellm_response)
	iniciar_nuevo_juicio()


func _process(delta: float) -> void:
	if lbl_dialogo_rival and lbl_dialogo_rival.visible_characters < texto_meta_dialogo.length():
		chars_visibles += delta * 48.0
		lbl_dialogo_rival.visible_characters = int(chars_visibles)
		stage.speaker_state = "RIVAL"
	else:
		if stage and stage.speaker_state == "RIVAL":
			stage.speaker_state = "IDLE"


func _crear_estilo_caja(bg_hex: String, border_hex: String, border_w: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_hex)
	sb.border_color = Color(border_hex)
	sb.set_border_width_all(border_w)
	sb.set_content_margin_all(8)
	return sb


func _construir_interfaz_8bit() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	root_vbox.add_theme_constant_override("separation", 6)
	add_child(root_vbox)

	# 1. Barra superior: Selección de Caso, Dificultad y Estado LiteLLM
	var top_panel := PanelContainer.new()
	top_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#1f2438", "#5a6988", 2))
	root_vbox.add_child(top_panel)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top_panel.add_child(top_hbox)

	var lbl_caso := Label.new()
	lbl_caso.text = "CASO:"
	lbl_caso.add_theme_color_override("font_color", Color("#fee761"))
	top_hbox.add_child(lbl_caso)

	selector_caso = OptionButton.new()
	selector_caso.add_item("Caso 1: Algoritmo Médico (Bioética/NDA)", 0)
	selector_caso.add_item("Caso 2: Informe Químico (Secreto vs. Ambiente)", 1)
	selector_caso.add_item("Caso 3: Auditoría de Pensiones (Conflicto Interés)", 2)
	selector_caso.item_selected.connect(_on_caso_cambiado)
	top_hbox.add_child(selector_caso)

	var lbl_dif := Label.new()
	lbl_dif.text = "DIFICULTAD:"
	lbl_dif.add_theme_color_override("font_color", Color("#fee761"))
	top_hbox.add_child(lbl_dif)

	selector_dificultad = OptionButton.new()
	selector_dificultad.add_item("SENCILLA (IA comete más falacias)", 0)
	selector_dificultad.add_item("NORMAL (Equilibrado)", 1)
	selector_dificultad.add_item("DIFÍCIL (IA casi infalible)", 2)
	selector_dificultad.selected = 1
	selector_dificultad.item_selected.connect(_on_dificultad_cambiada)
	top_hbox.add_child(selector_dificultad)

	var btn_reiniciar := Button.new()
	btn_reiniciar.text = "NUEVO JUICIO"
	btn_reiniciar.pressed.connect(iniciar_nuevo_juicio)
	top_hbox.add_child(btn_reiniciar)

	lbl_modelo_ia = Label.new()
	lbl_modelo_ia.text = "[LiteLLM: Conectando...]"
	lbl_modelo_ia.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_modelo_ia.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_modelo_ia.add_theme_color_override("font_color", Color("#63c74d"))
	lbl_modelo_ia.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(lbl_modelo_ia)

	# 2. Barras de Vida (HP) de ambos abogados
	var hp_hbox := HBoxContainer.new()
	hp_hbox.add_theme_constant_override("separation", 16)
	root_vbox.add_child(hp_hbox)

	var vbox_hp_p := VBoxContainer.new()
	vbox_hp_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_hbox.add_child(vbox_hp_p)

	lbl_hp_jugador = Label.new()
	lbl_hp_jugador.text = "TU CREDIBILIDAD (DEFENSA): 100 / 100 HP"
	lbl_hp_jugador.add_theme_color_override("font_color", Color("#2ce8f5"))
	vbox_hp_p.add_child(lbl_hp_jugador)

	bar_hp_jugador = ProgressBar.new()
	bar_hp_jugador.max_value = 100
	bar_hp_jugador.value = 100
	bar_hp_jugador.show_percentage = false
	bar_hp_jugador.custom_minimum_size = Vector2(0, 16)
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
	vbox_hp_r.add_child(lbl_hp_rival)

	bar_hp_rival = ProgressBar.new()
	bar_hp_rival.max_value = 100
	bar_hp_rival.value = 100
	bar_hp_rival.show_percentage = false
	bar_hp_rival.custom_minimum_size = Vector2(0, 16)
	bar_hp_rival.add_theme_stylebox_override("background", _crear_estilo_caja("#262b44", "#ffffff", 1))
	bar_hp_rival.add_theme_stylebox_override("fill", _crear_estilo_caja("#e43b44", "#ffffff", 0))
	vbox_hp_r.add_child(bar_hp_rival)

	# 3. Escenario 2D 8-Bit del Juzgado
	stage = PixelCourtStageScript.new()
	stage.custom_minimum_size = Vector2(0, 168)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(stage)

	# 4. Veredicto / Retroalimentación del Juez
	var juez_panel := PanelContainer.new()
	juez_panel.add_theme_stylebox_override("panel", _crear_estilo_caja("#2a1d2e", "#feae34", 2))
	root_vbox.add_child(juez_panel)

	lbl_juez_feedback = Label.new()
	lbl_juez_feedback.text = "JUEZ: El tribunal está en sesión. Analiza el argumento del fiscal."
	lbl_juez_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_juez_feedback.add_theme_color_override("font_color", Color("#fee761"))
	lbl_juez_feedback.add_theme_font_size_override("font_size", 13)
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
	header_dialogo.add_child(lbl_nombre_hablante)

	btn_objecion_falacia = Button.new()
	btn_objecion_falacia.text = "¡OBJECIÓN! MARCAR DECLARACIÓN DEL RIVAL COMO FALACIA"
	btn_objecion_falacia.add_theme_stylebox_override("normal", _crear_estilo_caja("#9e2835", "#fee761", 2))
	btn_objecion_falacia.add_theme_stylebox_override("hover", _crear_estilo_caja("#e43b44", "#ffffff", 2))
	btn_objecion_falacia.add_theme_color_override("font_color", Color("#ffffff"))
	btn_objecion_falacia.pressed.connect(_on_marcar_falacia_pressed)
	header_dialogo.add_child(btn_objecion_falacia)

	lbl_dialogo_rival = RichTextLabel.new()
	lbl_dialogo_rival.custom_minimum_size = Vector2(0, 48)
	lbl_dialogo_rival.fit_content = true
	lbl_dialogo_rival.scroll_active = false
	lbl_dialogo_rival.add_theme_font_size_override("normal_font_size", 14)
	dialogo_vbox.add_child(lbl_dialogo_rival)

	# 6. Cuadrícula de 4 Opciones de Argumento para el Jugador (1 Infalible, 2 Medios, 1 Falacia)
	var grid_opciones := GridContainer.new()
	grid_opciones.columns = 2
	grid_opciones.add_theme_constant_override("h_separation", 8)
	grid_opciones.add_theme_constant_override("v_separation", 8)
	root_vbox.add_child(grid_opciones)

	botones_opciones.clear()
	for i in range(4):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(440, 54)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_stylebox_override("normal", _crear_estilo_caja("#1d2b53", "#29adff", 2))
		btn.add_theme_stylebox_override("hover", _crear_estilo_caja("#29366f", "#fee761", 2))
		var idx_capturado: int = i
		btn.pressed.connect(func(): _on_opcion_argumento_elegida(idx_capturado))
		grid_opciones.add_child(btn)
		botones_opciones.append(btn)


func _on_caso_cambiado(index: int) -> void:
	var ids: Array[String] = [
		"caso_algoritmo_medico",
		"caso_vertido_quimico",
		"caso_auditoria_contable"
	]
	caso_id_actual = ids[clampi(index, 0, ids.size() - 1)]
	iniciar_nuevo_juicio()


func _on_dificultad_cambiada(index: int) -> void:
	var difs: Array[String] = ["FACIL", "NORMAL", "DIFICIL"]
	dificultad_actual = difs[clampi(index, 0, difs.size() - 1)]
	iniciar_nuevo_juicio()


func iniciar_nuevo_juicio() -> void:
	hp_jugador = 100
	hp_rival = 100
	turno_idx = 0
	juicio_terminado = false
	ya_objeto_este_turno = false
	historial_resumido.clear()
	declaracion_rival_actual = {}
	_actualizar_barras_vida()
	lbl_juez_feedback.text = "JUEZ: Nuevo juicio iniciado en dificultad " + dificultad_actual + ". Escuchemos el alegato inicial."
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
	btn_objecion_falacia.disabled = (not habilitado) or ya_objeto_este_turno or juicio_terminado
	for b in botones_opciones:
		b.disabled = (not habilitado) or juicio_terminado


func _on_marcar_falacia_pressed() -> void:
	if esperando_respuesta or juicio_terminado:
		return
	ya_objeto_este_turno = true
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
	_set_botones_habilitados(false)
	lbl_modelo_ia.text = "[LiteLLM: Pensando jugada...]"

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
		_aplicar_respaldo_offline_en_godot(accion, opcion_elegida)


func _on_litellm_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		lbl_modelo_ia.text = "[Modo Offline Integrado en Godot]"
		_aplicar_respaldo_offline_en_godot("FALLBACK", {})
		return

	var json_str: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		_aplicar_respaldo_offline_en_godot("FALLBACK", {})
		return

	_procesar_datos_turno(parsed)


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
			stage.trigger_objection("¡CONTRADICCIÓN DETECTADA!")

	_actualizar_barras_vida()

	var veredicto: String = str(datos.get("veredicto_juez", ""))
	lbl_juez_feedback.text = "JUEZ: " + veredicto

	# Verificar condición de victoria o derrota
	if hp_rival <= 0:
		juicio_terminado = true
		lbl_juez_feedback.text = "¡VEREDICTO FINAL: VICTORIA! Has desmontado todos los argumentos del fiscal con ética y lógica impecable."
		_mostrar_dialogo_rival("¡Imposible! ¡Mi argumentación ha sido completamente refutada en este tribunal!")
		_set_botones_habilitados(false)
		return
	elif hp_jugador <= 0:
		juicio_terminado = true
		lbl_juez_feedback.text = "VEREDICTO FINAL: DERROTA. Tus falacias y objeciones infundadas agotaron tu credibilidad ante el tribunal."
		_mostrar_dialogo_rival("El tribunal ha visto las fisuras de su razonamiento. ¡El caso está cerrado!")
		_set_botones_habilitados(false)
		return

	declaracion_rival_actual = datos.get("declaracion_rival", {})
	var texto_rival: String = str(declaracion_rival_actual.get("dialogo", ""))
	_mostrar_dialogo_rival(texto_rival)

	opciones_actuales = datos.get("opciones_jugador", [])
	for i in range(botones_opciones.size()):
		if i < opciones_actuales.size():
			var op: Dictionary = opciones_actuales[i]
			botones_opciones[i].text = "%d) %s" % [i + 1, str(op.get("texto", ""))]
		else:
			botones_opciones[i].text = "-"

	ya_objeto_este_turno = false
	_set_botones_habilitados(true)


func _mostrar_dialogo_rival(texto: String) -> void:
	texto_meta_dialogo = texto
	chars_visibles = 0.0
	lbl_dialogo_rival.text = texto
	lbl_dialogo_rival.visible_characters = 0


func _aplicar_respaldo_offline_en_godot(accion: String, opcion_elegida: Dictionary) -> void:
	# Por si el usuario abre Godot sin haber encendido aún el servidor Python LiteLLM
	var dano_r: int = 0
	var dano_j: int = 0
	var veredicto: String = "El juicio avanza en modo local (ejecuta iniciar_juego.bat para conectar LiteLLM)."

	if accion == "MARCAR_FALACIA" and not declaracion_rival_actual.is_empty():
		if bool(declaracion_rival_actual.get("es_falacia", false)):
			dano_r = 25
			veredicto = "¡HA LUGAR! Detectaste correctamente la falacia: " + str(declaracion_rival_actual.get("nombre_falacia", ""))
		else:
			dano_j = 20
			veredicto = "¡NO HA LUGAR! El argumento del fiscal era válido; pierdes credibilidad (-20 HP)."
	elif accion == "ARGUMENTAR" and not opcion_elegida.is_empty():
		var t: String = str(opcion_elegida.get("tipo", "MEDIO"))
		if t == "INFALIBLE":
			dano_r = 25
			veredicto = "¡Argumento infalible! " + str(opcion_elegida.get("explicacion", ""))
		elif t == "FALACIA":
			dano_j = 25
			veredicto = "¡El fiscal detectó tu falacia (" + str(opcion_elegida.get("nombre_falacia", "")) + ")! Pierdes 25 HP."
		else:
			dano_j = 10 if dificultad_actual != "FACIL" else 0
			veredicto = "Argumento medio rebatible. " + str(opcion_elegida.get("explicacion", ""))

	var rival_es_falacia: bool = (randf() < 0.6) if dificultad_actual == "FACIL" else (randf() < 0.25)
	var nueva_decl: Dictionary = {
		"dialogo": "Si permitimos que un profesional cuestione una orden empresarial por razones éticas, mañana nadie obedecerá ninguna ley y reinará el caos total." if rival_es_falacia else "El contrato de confidencialidad fue firmado voluntariamente y obliga a las partes según el derecho civil vigente.",
		"es_falacia": rival_es_falacia,
		"nombre_falacia": "Pendiente Resbaladiza" if rival_es_falacia else null,
		"explicacion_logica": "Exagera consecuencias extremas sin prueba causal." if rival_es_falacia else "Argumento contractual estándar."
	}

	var nuevas_opciones: Array = [
		{
			"texto": "Los códigos deontológicos establecen que la protección de la vida y derechos fundamentales prevalece sobre cláusulas privadas de secreto.",
			"tipo": "INFALIBLE",
			"nombre_falacia": null,
			"explicacion": "Jerarquía ética del bien público y no maleficencia."
		},
		{
			"texto": "El profesional actuó de buena fe porque quería ayudar a la comunidad.",
			"tipo": "MEDIO",
			"nombre_falacia": null,
			"explicacion": "Apela a la intención subjetiva, pero requiere sustento normativo."
		},
		{
			"texto": "La empresa tenía ganancias suficientes para asumir el costo de corregir el problema.",
			"tipo": "MEDIO",
			"nombre_falacia": null,
			"explicacion": "Hecho económico secundario frente al deber deontológico."
		},
		{
			"texto": "El fiscal solo defiende a la empresa porque seguro odia a los trabajadores honestos.",
			"tipo": "FALACIA",
			"nombre_falacia": "Ad Hominem",
			"explicacion": "Ataca personalmente al fiscal en vez de refutar su argumento."
		}
	]
	nuevas_opciones.shuffle()

	_procesar_datos_turno({
		"modelo_usado": "Respaldo-Interno-Godot",
		"veredicto_juez": veredicto,
		"dano_al_rival": dano_r,
		"dano_al_jugador": dano_j,
		"rival_detecto_falacia_jugador": (dano_j >= 25),
		"declaracion_rival": nueva_decl,
		"opciones_jugador": nuevas_opciones
	})
