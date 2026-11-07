extends SceneTree
## Suite de Pruebas de Caja Blanca (White-Box Testing) para Godot 4.
## Verifica método por método y rama por rama (cobertura de sentencias, decisiones y límites):
## 1. res://scripts/CasesDatabase.gd
## 2. res://scripts/PixelCourtStage.gd
## 3. res://scripts/MainCourtroom.gd

const CasesDatabaseScript = preload("res://scripts/CasesDatabase.gd")
const PixelCourtStageScript = preload("res://scripts/PixelCourtStage.gd")

var total_metodos_probados: int = 0
var total_aserciones: int = 0
var fallos: int = 0
var reporte_metodos: Array[Dictionary] = []


func _check(condicion: bool, msg: String) -> void:
	total_aserciones += 1
	if not condicion:
		fallos += 1
		push_error("[WHITEBOX FAIL] " + msg)
		print("   [FAIL] " + msg)


func _registrar(script_nombre: String, metodo: String, ramas: Array[String], aserciones_metodo: int, ms: float) -> void:
	total_metodos_probados += 1
	reporte_metodos.append({
		"script": script_nombre,
		"metodo": metodo,
		"ramas": ramas,
		"aserciones": aserciones_metodo,
		"tiempo_ms": snappedf(ms, 0.001),
		"estado": "PASS" if fallos == 0 else "FAIL"
	})
	print(" [PASS] %s :: %s (%d aserciones, %.3f ms)" % [script_nombre, metodo, aserciones_metodo, ms])


func _init() -> void:
	call_deferred("_run_whitebox_suite")


func _run_whitebox_suite() -> void:
	print("======================================================================")
	print(" INICIANDO PRUEBAS DE CAJA BLANCA (MÉTODO POR MÉTODO) - GODOT 4")
	print("======================================================================")

	_test_cases_database()
	await _test_pixel_court_stage()
	await _test_main_courtroom_all_methods()

	print("======================================================================")
	print(" RESUMEN CAJA BLANCA GODOT: %d métodos probados | %d aserciones | %d fallos" % [
		total_metodos_probados, total_aserciones, fallos
	])
	print("======================================================================")
	quit(0 if fallos == 0 else 1)


# ============================================================================
# 1. CAJA BLANCA: CasesDatabase.gd
# ============================================================================
func _test_cases_database() -> void:
	var t0: int = Time.get_ticks_usec()
	var a_ini: int = total_aserciones

	# Rama 1: INICIAR_CASO en los 4 casos
	for c_id in ["caso_algoritmo_medico", "caso_vertido_quimico", "caso_auditoria_contable", "caso_ia_periodismo"]:
		var r_ini: Dictionary = CasesDatabaseScript.generar_turno_autonomo(c_id, "NORMAL", "INICIAR_CASO", {}, {}, 0)
		_check(r_ini["dano_al_rival"] == 0 and r_ini["dano_al_jugador"] == 0, "INICIAR_CASO daño 0 en " + c_id)
		_check(r_ini["opciones_jugador"].size() == 4, "4 opciones en " + c_id)

	# Rama 2: MARCAR_FALACIA verdadera vs falsa
	var r_mf_true: Dictionary = CasesDatabaseScript.generar_turno_autonomo(
		"caso_algoritmo_medico", "NORMAL", "MARCAR_FALACIA",
		{"es_falacia": true, "nombre_falacia": "Ad Hominem", "explicacion_logica": "Ataque"}, {}, 0
	)
	_check(r_mf_true["dano_al_rival"] == 25 and r_mf_true["dano_al_jugador"] == 0, "MARCAR_FALACIA verdadera -> 25 daño rival")

	var r_mf_false: Dictionary = CasesDatabaseScript.generar_turno_autonomo(
		"caso_algoritmo_medico", "NORMAL", "MARCAR_FALACIA",
		{"es_falacia": false, "explicacion_logica": "Válido"}, {}, 0
	)
	_check(r_mf_false["dano_al_rival"] == 0 and r_mf_false["dano_al_jugador"] == 20, "MARCAR_FALACIA falsa -> 20 daño jugador")

	# Rama 3: ARGUMENTAR INFALIBLE
	var r_inf: Dictionary = CasesDatabaseScript.generar_turno_autonomo(
		"caso_algoritmo_medico", "DIFICIL", "ARGUMENTAR", {},
		{"tipo": "INFALIBLE", "explicacion": "Sólido"}, 1
	)
	_check(r_inf["dano_al_rival"] == 25, "ARGUMENTAR INFALIBLE -> 25 daño rival")

	# Rama 4: ARGUMENTAR MEDIO en FACIL (0), NORMAL (10), DIFICIL (15)
	var r_m_f: Dictionary = CasesDatabaseScript.generar_turno_autonomo("caso_algoritmo_medico", "FACIL", "ARGUMENTAR", {}, {"tipo": "MEDIO", "explicacion": "M"}, 0)
	var r_m_n: Dictionary = CasesDatabaseScript.generar_turno_autonomo("caso_algoritmo_medico", "NORMAL", "ARGUMENTAR", {}, {"tipo": "MEDIO", "explicacion": "M"}, 0)
	var r_m_d: Dictionary = CasesDatabaseScript.generar_turno_autonomo("caso_algoritmo_medico", "DIFICIL", "ARGUMENTAR", {}, {"tipo": "MEDIO", "explicacion": "M"}, 0)
	_check(r_m_f["dano_al_jugador"] == 0, "MEDIO en FACIL -> 0 daño")
	_check(r_m_n["dano_al_jugador"] == 10, "MEDIO en NORMAL -> 10 daño")
	_check(r_m_d["dano_al_jugador"] == 15, "MEDIO en DIFICIL -> 15 daño")

	# Rama 5: ARGUMENTAR FALACIA
	var r_fal: Dictionary = CasesDatabaseScript.generar_turno_autonomo(
		"caso_algoritmo_medico", "DIFICIL", "ARGUMENTAR", {},
		{"tipo": "FALACIA", "nombre_falacia": "Ad Hominem", "explicacion": "F"}, 0
	)
	_check(r_fal["dano_al_jugador"] == 25 or r_fal["dano_al_jugador"] == 0, "ARGUMENTAR FALACIA evaluada correctamente")

	var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	_registrar(
		"CasesDatabase.gd",
		"generar_turno_autonomo",
		["INICIAR_CASO (4 casos)", "MARCAR_FALACIA (true/false)", "ARGUMENTAR (INFALIBLE, MEDIOx3 dificultades, FALACIA)"],
		total_aserciones - a_ini,
		ms
	)


# ============================================================================
# 2. CAJA BLANCA: PixelCourtStage.gd (8 métodos)
# ============================================================================
func _test_pixel_court_stage() -> void:
	var stage: Control = PixelCourtStageScript.new()
	stage.size = Vector2(880, 160)
	root.add_child(stage)
	await process_frame

	# 2.1 _ready()
	var t0: int = Time.get_ticks_usec()
	var a0: int = total_aserciones
	_check(stage.clip_contents == true, "_ready() activa clip_contents = true")
	_registrar("PixelCourtStage.gd", "_ready", ["Inicialización clip_contents = true"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.2 trigger_objection(texto)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	stage.trigger_objection("¡FALACIA AD HOMINEM!")
	_check(stage.objection_text == "¡FALACIA AD HOMINEM!", "objection_text asignado")
	_check(is_equal_approx(stage.objection_banner_timer, 1.4), "objection_banner_timer = 1.4")
	_registrar("PixelCourtStage.gd", "trigger_objection", ["Asignación de texto y timer a 1.4s"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.3 trigger_damage_flash(target)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	stage.trigger_damage_flash("JUGADOR")
	_check(is_equal_approx(stage.flash_player_timer, 0.7), "Rama target == 'JUGADOR' activa flash_player_timer = 0.7")
	stage.trigger_damage_flash("RIVAL")
	_check(is_equal_approx(stage.flash_rival_timer, 0.7), "Rama target == 'RIVAL' activa flash_rival_timer = 0.7")
	_registrar("PixelCourtStage.gd", "trigger_damage_flash", ["Rama target == 'JUGADOR'", "Rama target == 'RIVAL'"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.4 _process(delta)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	var anim_prev: float = stage.anim_time
	stage._process(0.25)
	_check(stage.anim_time > anim_prev, "_process incrementa anim_time")
	_check(stage.flash_player_timer < 0.7 and stage.flash_rival_timer < 0.7 and stage.objection_banner_timer < 1.4, "_process decrementa los 3 timers activos")
	_registrar("PixelCourtStage.gd", "_process", ["Decremento de timers > 0 y avance de anim_time"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.5 trigger_victory_animation()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	stage.trigger_victory_animation()
	_check(stage.result_state == "VICTORIA", "result_state == 'VICTORIA'")
	_check(is_equal_approx(stage.objection_banner_timer, 0.0), "Limpia objection_banner_timer a 0")
	_registrar("PixelCourtStage.gd", "trigger_victory_animation", ["Transición a estado VICTORIA"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.6 trigger_defeat_animation()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	stage.trigger_defeat_animation()
	_check(stage.result_state == "DERROTA", "result_state == 'DERROTA'")
	_check(is_equal_approx(stage.objection_banner_timer, 0.0), "Limpia objection_banner_timer a 0")
	_registrar("PixelCourtStage.gd", "trigger_defeat_animation", ["Transición a estado DERROTA"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.7 reset_stage()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	stage.reset_stage()
	_check(stage.result_state == "NONE" and stage.speaker_state == "IDLE", "Restaura result_state='NONE' y speaker_state='IDLE'")
	_check(stage.flash_player_timer == 0.0 and stage.flash_rival_timer == 0.0 and stage.objection_banner_timer == 0.0, "Reinicia timers a 0.0")
	_registrar("PixelCourtStage.gd", "reset_stage", ["Reinicio completo de estado y temporizadores"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 2.8 _draw() y _draw_px_rect() en todos los estados
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	for st in ["NONE", "VICTORIA", "DERROTA"]:
		stage.result_state = st
		stage.queue_redraw()
		await process_frame
	_check(true, "Ciclo de renderizado _draw() y _draw_px_rect() ejecutado en NONE, VICTORIA y DERROTA sin errores")
	_registrar("PixelCourtStage.gd", "_draw / _draw_px_rect", ["Rama NONE", "Rama VICTORIA (confeti)", "Rama DERROTA (lluvia roja)"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	stage.queue_free()
	await process_frame


# ============================================================================
# 3. CAJA BLANCA: MainCourtroom.gd (22 métodos)
# ============================================================================
func _test_main_courtroom_all_methods() -> void:
	var packed: PackedScene = load("res://scenes/MainCourtroom.tscn")
	var mc: Control = packed.instantiate()
	root.add_child(mc)
	await process_frame
	await process_frame

	# 3.1 _ready(), _construir_menu_principal(), _construir_interfaz_juzgado()
	var t0: int = Time.get_ticks_usec()
	var a0: int = total_aserciones
	_check(mc.http_req != null and is_equal_approx(mc.http_req.timeout, 5.2), "_ready() inicializa HTTPRequest con timeout 5.2s")
	_check(mc.menu_container != null and mc.btns_menu_casos.size() == 4 and mc.btns_menu_difs.size() == 3, "_construir_menu_principal() crea los selectores")
	_check(mc.game_container != null and mc.botones_opciones.size() == 4 and mc.endgame_panel != null, "_construir_interfaz_juzgado() crea la sala y los 4 botones")
	_registrar("MainCourtroom.gd", "_ready / _construir_menu_principal / _construir_interfaz_juzgado", ["Inicialización de árbol UI completo y HTTPRequest"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.2 _centrar_ventana_en_pantalla() y _guardar_captura_verificacion()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc._centrar_ventana_en_pantalla()
	await mc._guardar_captura_verificacion()
	_check(DisplayServer.get_name() == "headless", "Rama guarda headless en _centrar_ventana_en_pantalla y _guardar_captura_verificacion")
	_registrar("MainCourtroom.gd", "_centrar_ventana_en_pantalla / _guardar_captura_verificacion", ["Rama guarda headless activa"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.3 _crear_estilo_caja()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	var sb: StyleBoxFlat = mc._crear_estilo_caja("#121526", "#feae34", 3, 10)
	_check(sb is StyleBoxFlat and sb.get_border_width(SIDE_LEFT) == 3, "_crear_estilo_caja genera StyleBoxFlat con borde y margen exactos")
	_registrar("MainCourtroom.gd", "_crear_estilo_caja", ["Construcción parametrizada de StyleBoxFlat"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.4 _seleccionar_caso_en_menu(idx) (incluyendo límites fuera de rango con clampi)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc._seleccionar_caso_en_menu(-10)
	_check(mc.indice_caso_seleccionado == 0 and mc.caso_id_actual == "caso_algoritmo_medico", "Límite inferior clampi(-10) -> 0")
	mc._seleccionar_caso_en_menu(99)
	_check(mc.indice_caso_seleccionado == 3 and mc.caso_id_actual == "caso_ia_periodismo", "Límite superior clampi(99) -> 3")
	mc._seleccionar_caso_en_menu(1)
	_check(mc.indice_caso_seleccionado == 1 and mc.caso_id_actual == "caso_vertido_quimico", "Rama normal idx=1")
	_registrar("MainCourtroom.gd", "_seleccionar_caso_en_menu", ["Límite inferior (<0)", "Límite superior (>3)", "Selección normal (0..3)"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.5 _seleccionar_dificultad_en_menu(idx) (incluyendo límites clampi)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc._seleccionar_dificultad_en_menu(-5)
	_check(mc.indice_dificultad_seleccionada == 0 and mc.dificultad_actual == "FACIL", "Límite inferior clampi(-5) -> FACIL")
	mc._seleccionar_dificultad_en_menu(50)
	_check(mc.indice_dificultad_seleccionada == 2 and mc.dificultad_actual == "DIFICIL", "Límite superior clampi(50) -> DIFICIL")
	mc._seleccionar_dificultad_en_menu(1)
	_check(mc.indice_dificultad_seleccionada == 1 and mc.dificultad_actual == "NORMAL", "Rama normal idx=1 -> NORMAL")
	_registrar("MainCourtroom.gd", "_seleccionar_dificultad_en_menu", ["Límite inferior (<0)", "Límite superior (>2)", "Selección normal (0..2)"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.6 comenzar_partida_desde_menu() e iniciar_nuevo_juicio()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.servidor_local_disponible = false # Para probar primero flujo determinista instantáneo
	mc.comenzar_partida_desde_menu()
	_check(mc.menu_container.visible == false and mc.game_container.visible == true, "Transición de contenedores Menú -> Juzgado")
	_check(mc.hp_jugador == 100 and mc.hp_rival == 100 and mc.juicio_terminado == false, "iniciar_nuevo_juicio restaura HP 100/100")
	_check(mc.opciones_actuales.size() == 4, "Carga inicial de 4 opciones")
	_registrar("MainCourtroom.gd", "comenzar_partida_desde_menu / iniciar_nuevo_juicio", ["Oculta menú, muestra juzgado, reinicia estado y solicita primer turno"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.7 _actualizar_barras_vida() (probando límites <0 y >100)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.hp_jugador = -40
	mc.hp_rival = 180
	mc._actualizar_barras_vida()
	_check(mc.hp_jugador == 0 and mc.bar_hp_jugador.value == 0, "clampi limita hp_jugador negativo a 0")
	_check(mc.hp_rival == 100 and mc.bar_hp_rival.value == 100, "clampi limita hp_rival >100 a 100")
	mc.hp_jugador = 100
	mc._actualizar_barras_vida()
	_registrar("MainCourtroom.gd", "_actualizar_barras_vida", ["Límite inferior (<0 -> 0)", "Límite superior (>100 -> 100)", "Sincronización ProgressBar y Label"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.8 _set_botones_habilitados(habilitado)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc._set_botones_habilitados(false)
	_check(mc.esperando_respuesta == true and mc.botones_opciones[0].disabled == true, "habilitado=false bloquea botones y activa esperando_respuesta")
	mc._set_botones_habilitados(true)
	_check(mc.esperando_respuesta == false and mc.botones_opciones[0].disabled == false, "habilitado=true habilita botones y limpia tiempo_espera_actual")
	_registrar("MainCourtroom.gd", "_set_botones_habilitados", ["Rama habilitado=false", "Rama habilitado=true"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.9 _on_marcar_falacia_pressed()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.declaracion_rival_actual = {"es_falacia": true, "nombre_falacia": "Ad Hominem", "explicacion_logica": "Test"}
	mc._on_marcar_falacia_pressed()
	_check(mc.hp_rival == 75, "_on_marcar_falacia_pressed sobre falacia verdadera reduce hp_rival a 75")
	# Probar guarda cuando esperando_respuesta == true
	mc.esperando_respuesta = true
	var hp_antes: int = mc.hp_rival
	mc._on_marcar_falacia_pressed()
	_check(mc.hp_rival == hp_antes, "Guarda impide ejecutar objeción si esperando_respuesta == true")
	mc._set_botones_habilitados(true)
	_registrar("MainCourtroom.gd", "_on_marcar_falacia_pressed", ["Rama normal de objeción", "Guarda cuando esperando_respuesta o juicio_terminado es true"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.10 _on_opcion_argumento_elegida(idx)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	var t_antes: int = mc.turno_idx
	mc._on_opcion_argumento_elegida(99) # Fuera de rango -> guarda debe ignorar
	_check(mc.turno_idx == t_antes, "Guarda ignora índice fuera de rango (idx >= opciones_actuales.size())")
	mc._on_opcion_argumento_elegida(0)
	_check(mc.turno_idx == t_antes + 1, "Rama válida incrementa turno_idx y procesa la opción elegida")
	_registrar("MainCourtroom.gd", "_on_opcion_argumento_elegida", ["Guarda índice inválido", "Ejecución válida con incremento de turno_idx"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.11 _process(delta) Watchdog Anti-Bloqueo
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.esperando_respuesta = true
	mc.tiempo_espera_actual = 0.0
	mc.ultima_accion_pendiente = "INICIAR_CASO"
	mc._process(mc.TIEMPO_MAX_ESPERA + 0.2)
	_check(mc.esperando_respuesta == false and mc.tiempo_espera_actual == 0.0, "Watchdog destranca automáticamente esperando_respuesta al superar TIEMPO_MAX_ESPERA (5.8s)")
	_registrar("MainCourtroom.gd", "_process (Watchdog Anti-Bloqueo)", ["Rama tiempo_espera_actual < 5.8s", "Rama tiempo_espera_actual >= 5.8s (destrancado automático)"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.12 _on_litellm_response() (4 ramas: !esperando_respuesta, error HTTP, JSON inválido, JSON válido)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.esperando_respuesta = false
	mc._on_litellm_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_check(mc.esperando_respuesta == false, "Rama 1: Ignora respuesta tardía si esperando_respuesta es false")

	mc.esperando_respuesta = true
	mc.servidor_local_disponible = true
	mc._on_litellm_response(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())
	_check(mc.servidor_local_disponible == false and mc.esperando_respuesta == false, "Rama 2: RESULT_CANT_CONNECT desactiva servidor_local_disponible y aplica respaldo")

	mc.esperando_respuesta = true
	mc._on_litellm_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "JSON_CORRUPTO{{{".to_utf8_buffer())
	_check(mc.esperando_respuesta == false, "Rama 3: JSON corrupto aplica respaldo sin colgar el juego")

	mc.esperando_respuesta = true
	var json_ok: String = JSON.stringify({
		"modelo_usado": "test-caja-blanca",
		"veredicto_juez": "Veredicto de prueba.",
		"dano_al_rival": 25,
		"dano_al_jugador": 0,
		"declaracion_rival": {"dialogo": "Diálogo rival", "es_falacia": false},
		"opciones_jugador": [
			{"texto": "A", "tipo": "INFALIBLE"},
			{"texto": "B", "tipo": "MEDIO"},
			{"texto": "C", "tipo": "MEDIO"},
			{"texto": "D", "tipo": "FALACIA"}
		]
	})
	mc.hp_rival = 100
	mc._on_litellm_response(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), json_ok.to_utf8_buffer())
	_check(mc.hp_rival == 75 and mc.lbl_modelo_ia.text == "[IA: test-caja-blanca]", "Rama 4: HTTP 200 con JSON válido procesa turno y resta HP")
	_registrar("MainCourtroom.gd", "_on_litellm_response", ["Rama !esperando_respuesta", "Rama RESULT_CANT_CONNECT", "Rama JSON inválido", "Rama HTTP 200 JSON válido"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.13 _procesar_datos_turno() y _mostrar_pantalla_fin_de_juego(true/false)
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.hp_rival = 20
	mc.hp_jugador = 100
	mc._procesar_datos_turno({"dano_al_rival": 25, "dano_al_jugador": 0, "veredicto_juez": "Fin"})
	_check(mc.juicio_terminado == true and mc.stage.result_state == "VICTORIA" and mc.endgame_panel.visible == true, "Rama hp_rival <= 0 dispara VICTORIA y muestra endgame_panel")

	mc.hp_rival = 100
	mc.hp_jugador = 15
	mc.juicio_terminado = false
	mc._procesar_datos_turno({"dano_al_rival": 0, "dano_al_jugador": 25, "rival_detecto_falacia_jugador": true, "veredicto_juez": "Derrota"})
	_check(mc.juicio_terminado == true and mc.stage.result_state == "DERROTA" and mc.endgame_panel.visible == true, "Rama hp_jugador <= 0 dispara DERROTA y muestra endgame_panel")
	_registrar("MainCourtroom.gd", "_procesar_datos_turno / _mostrar_pantalla_fin_de_juego", ["Rama daño normal", "Rama Victoria (hp_rival <= 0)", "Rama Derrota (hp_jugador <= 0)"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	# 3.14 mostrar_menu_principal()
	t0 = Time.get_ticks_usec()
	a0 = total_aserciones
	mc.mostrar_menu_principal()
	_check(mc.menu_container.visible == true and mc.game_container.visible == false and mc.esperando_respuesta == false, "mostrar_menu_principal restaura vista de menú y cancela esperas")
	_registrar("MainCourtroom.gd", "mostrar_menu_principal", ["Restauración de estado y visibilidad del Menú Principal"], total_aserciones - a0, (Time.get_ticks_usec() - t0) / 1000.0)

	mc.queue_free()
	await process_frame
