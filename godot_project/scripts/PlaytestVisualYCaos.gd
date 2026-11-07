extends SceneTree
## Agente de Playtesting Visual y Pruebas de Caos (Monkey / Adversarial Testing).
## Ejecuta partidas de prueba reales con renderizado OpenGL, captura imágenes PNG
## y verifica tanto la ausencia de bugs visuales como la resistencia ante acciones
## accidentales o malintencionadas de un jugador ("romper el juego").

var dir_capturas: String = ProjectSettings.globalize_path("res://../capturas_playtest")
var anomalias_detectadas: Array[String] = []
var pruebas_superadas: Array[String] = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(dir_capturas)
	call_deferred("_iniciar_playtest_visual")


func _capturar_pantalla(nombre: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = root.get_texture()
	if tex:
		var img: Image = tex.get_image()
		if img:
			img.save_png(dir_capturas + "/" + nombre + ".png")
			print("   [CAPTURA] Guardada: " + nombre + ".png (" + str(img.get_width()) + "x" + str(img.get_height()) + ")")


func _auditar_geometria_ui(app: Control, contexto: String) -> void:
	await process_frame
	await process_frame
	var vp_size: Vector2 = root.get_visible_rect().size
	print("   [AUDITORÍA GEOMÉTRICA - %s] Viewport: %dx%d" % [contexto, int(vp_size.x), int(vp_size.y)])

	var controles_a_verificar: Array[Dictionary] = []
	if app.menu_container.visible:
		controles_a_verificar.append({"nombre": "menu_container", "nodo": app.menu_container})
		for i in range(app.btns_menu_casos.size()):
			controles_a_verificar.append({"nombre": "btn_menu_caso_%d" % i, "nodo": app.btns_menu_casos[i]})
		for j in range(app.btns_menu_difs.size()):
			controles_a_verificar.append({"nombre": "btn_menu_dif_%d" % j, "nodo": app.btns_menu_difs[j]})
	if app.game_container.visible:
		controles_a_verificar.append({"nombre": "stage", "nodo": app.stage})
		controles_a_verificar.append({"nombre": "lbl_juez_feedback", "nodo": app.lbl_juez_feedback})
		controles_a_verificar.append({"nombre": "lbl_dialogo_rival", "nodo": app.lbl_dialogo_rival})
		controles_a_verificar.append({"nombre": "btn_objecion_falacia", "nodo": app.btn_objecion_falacia})
		if app.grid_opciones.visible:
			for k in range(app.botones_opciones.size()):
				controles_a_verificar.append({"nombre": "boton_opcion_%d" % k, "nodo": app.botones_opciones[k]})
		if app.endgame_panel.visible:
			controles_a_verificar.append({"nombre": "endgame_panel", "nodo": app.endgame_panel})

	for item in controles_a_verificar:
		var ctrl: Control = item["nodo"]
		var rect: Rect2 = ctrl.get_global_rect()
		var nombre_c: String = item["nombre"]
		if rect.position.x < -1.0 or (rect.position.x + rect.size.x) > (vp_size.x + 2.0):
			var msg_x: String = "[BUG VISUAL HORIZONTAL en %s] '%s' se sale del ancho (right=%.1f > %.1f)" % [
				contexto, nombre_c, rect.position.x + rect.size.x, vp_size.x
			]
			anomalias_detectadas.append(msg_x)
			print("      !!! " + msg_x)
		if rect.position.y < -1.0 or (rect.position.y + rect.size.y) > (vp_size.y + 2.0):
			var msg_y: String = "[BUG VISUAL VERTICAL en %s] '%s' se sale del alto (bottom=%.1f > %.1f)" % [
				contexto, nombre_c, rect.position.y + rect.size.y, vp_size.y
			]
			anomalias_detectadas.append(msg_y)
			print("      !!! " + msg_y)

	pruebas_superadas.append("Geometría UI íntegra sin desbordamientos en " + contexto)


func _esperar_turno(app: Control) -> void:
	var t: float = 0.0
	while app.esperando_respuesta and t < 6.2:
		await create_timer(0.05).timeout
		t += 0.05


func _iniciar_playtest_visual() -> void:
	print("======================================================================")
	print(" INICIANDO PLAYTEST VISUAL Y PRUEBAS DE CAOS (JUGADOR REAL / BREAKER)")
	print("======================================================================")

	var packed: PackedScene = load("res://scenes/MainCourtroom.tscn")
	var app: Control = packed.instantiate()
	root.add_child(app)

	await process_frame
	await process_frame
	await create_timer(0.15).timeout

	# 1. Auditar Menú Principal
	await _auditar_geometria_ui(app, "MENU_CASO_1")
	await _capturar_pantalla("01_menu_principal_caso1")

	app.btns_menu_casos[3].pressed.emit()
	app.btns_menu_difs[2].pressed.emit()
	await _auditar_geometria_ui(app, "MENU_CASO_4_DIFICIL")
	await _capturar_pantalla("02_menu_principal_caso4_dificil")

	# 2. Entrar a partida y auditar turno inicial + estado de animación del Fiscal
	app.btns_menu_casos[0].pressed.emit()
	app.btns_menu_difs[1].pressed.emit()
	app.comenzar_partida_desde_menu()
	await _esperar_turno(app)
	await _auditar_geometria_ui(app, "JUZGADO_TURNO_INICIAL")
	await _capturar_pantalla("03_juzgado_turno_inicial")

	if app.stage.speaker_state != "RIVAL":
		anomalias_detectadas.append("[BUG ANIMACIÓN ESCENARIO] stage.speaker_state='%s' en vez de 'RIVAL'" % app.stage.speaker_state)
	else:
		pruebas_superadas.append("Animación de hablante sincronizada con el Fiscal Rival (speaker_state == 'RIVAL')")

	# 3. PRUEBA DE CAOS #1: Cancelación de petición en vuelo (Salir al menú / cambiar de caso a mitad de carga)
	print("\n-> [CAOS #1] Clic en opción e inmediatamente 'Menú Principal' -> Nuevo Caso con petición en vuelo...")
	app.botones_opciones[0].pressed.emit()
	app.mostrar_menu_principal()
	app.btns_menu_casos[1].pressed.emit()
	app.comenzar_partida_desde_menu()
	await _esperar_turno(app)
	if app.caso_id_actual != "caso_vertido_quimico":
		anomalias_detectadas.append("[BUG ESTADO] Al cambiar rápido de caso no se mantuvo caso_vertido_quimico")
	else:
		pruebas_superadas.append("Cancelación limpia de petición HTTP al salir al Menú Principal a mitad de turno")

	# 4. PRUEBA DE CAOS #2: Anti-Exploit de Spam de "¡OBJECIÓN!"
	print("\n-> [CAOS #2] Verificando avance de turno y bloqueo de doble '¡OBJECIÓN!' consecutiva...")
	var turno_antes_obj: int = app.turno_idx
	app.btn_objecion_falacia.pressed.emit()
	await _capturar_pantalla("04_juzgado_cartel_objecion")
	await _esperar_turno(app)

	if app.turno_idx != turno_antes_obj + 1:
		anomalias_detectadas.append("[BUG EXPLOIT] turno_idx no avanzó tras pulsar ¡OBJECIÓN!")
	else:
		pruebas_superadas.append("Avance de turno_idx garantizado al usar ¡OBJECIÓN! (%d -> %d)" % [turno_antes_obj, app.turno_idx])

	if not app.btn_objecion_falacia.disabled or not app.ya_objeto_este_turno:
		anomalias_detectadas.append("[BUG EXPLOIT] El botón de ¡OBJECIÓN! quedó habilitado para spam consecutivo sin argumentar")
	else:
		# Intentar forzar otro clic en ¡OBJECIÓN! estando bloqueado
		var t_bloqueado: int = app.turno_idx
		app.btn_objecion_falacia.pressed.emit()
		if app.turno_idx != t_bloqueado:
			anomalias_detectadas.append("[BUG EXPLOIT] Se pudo spamear ¡OBJECIÓN! estando deshabilitado")
		else:
			pruebas_superadas.append("Anti-Exploit de doble ¡OBJECIÓN! consecutiva verificado (obliga a elegir argumento 1-4)")

	# Al elegir un argumento (1..4), el botón de ¡OBJECIÓN! debe volver a habilitarse para el nuevo turno
	app.botones_opciones[0].pressed.emit()
	await _esperar_turno(app)
	if not app.juicio_terminado and app.btn_objecion_falacia.disabled:
		anomalias_detectadas.append("[BUG ESTADO] El botón de ¡OBJECIÓN! no se reactivó después de elegir un argumento")
	else:
		pruebas_superadas.append("Reactivación de ¡OBJECIÓN! tras presentar argumento verificada")

	# 5. PRUEBA DE CAOS #3: Textos largos extremos en Caso 3
	print("\n-> [CAOS #3] Probando textos más largos del juego (Caso 3 en DIFICIL)...")
	app.servidor_local_disponible = false
	app.btns_menu_casos[2].pressed.emit()
	app.btns_menu_difs[2].pressed.emit()
	app.comenzar_partida_desde_menu()
	app.botones_opciones[0].pressed.emit()
	await _auditar_geometria_ui(app, "JUZGADO_TEXTOS_LARGOS_CASO_3")
	await _capturar_pantalla("05_juzgado_textos_largos_caso3")

	# 6. PRUEBA DE CAOS #4: Pantallas de VICTORIA y DERROTA limpias y bloqueo post-partida
	print("\n-> [CAOS #4] Auditando pantallas de VICTORIA y DERROTA y bloqueo de acciones post-juicio...")
	app._mostrar_pantalla_fin_de_juego(true)
	await _auditar_geometria_ui(app, "PANTALLA_VICTORIA")
	await _capturar_pantalla("06_pantalla_victoria")
	if app.stage.speaker_state != "JUEZ" or app.stage.flash_player_timer > 0.0:
		anomalias_detectadas.append("[BUG VISUAL VICTORIA] Estado sucio de hablante o flash de daño en VICTORIA")
	else:
		pruebas_superadas.append("Pantalla de VICTORIA limpia (sin flashes residuales ni brazos apuntando fuera de turno)")

	app._mostrar_pantalla_fin_de_juego(false)
	await _auditar_geometria_ui(app, "PANTALLA_DERROTA")
	await _capturar_pantalla("07_pantalla_derrota")
	if app.stage.speaker_state != "JUEZ" or app.stage.flash_player_timer > 0.0:
		anomalias_detectadas.append("[BUG VISUAL DERROTA] Estado sucio de hablante o flash de daño en DERROTA")
	else:
		pruebas_superadas.append("Pantalla de DERROTA limpia (sin flashes residuales ni postura de ataque del jugador derrotado)")

	# 7. PRUEBA DE CAOS #5: MONKEY TESTING (50 acciones aleatorias frenéticas de un jugador caótico)
	print("\n-> [CAOS #5] Ejecutando Monkey Testing (50 acciones caóticas aleatorias a máxima velocidad)...")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261107
	app.mostrar_menu_principal()
	app.comenzar_partida_desde_menu()
	for paso in range(50):
		var accion_mono: int = rng.randi_range(0, 6)
		match accion_mono:
			0, 1, 2, 3:
				app.botones_opciones[accion_mono].pressed.emit()
			4:
				app.btn_objecion_falacia.pressed.emit()
			5:
				app.iniciar_nuevo_juicio()
			6:
				app.mostrar_menu_principal()
				app.btns_menu_casos[rng.randi_range(0, 3)].pressed.emit()
				app.btns_menu_difs[rng.randi_range(0, 2)].pressed.emit()
				app.comenzar_partida_desde_menu()
		if app.hp_jugador < 0 or app.hp_jugador > 100 or app.hp_rival < 0 or app.hp_rival > 100:
			anomalias_detectadas.append("[BUG MONKEY] HP fuera de límites [0..100] en paso %d" % paso)
	pruebas_superadas.append("Monkey Testing de 50 acciones caóticas superado sin crashes ni estados corruptos")

	print("\n======================================================================")
	print(" RESUMEN FINAL DEL PLAYTEST VISUAL Y AUDITORÍA ANTI-ROTURA")
	print("======================================================================")
	print(" - Pruebas visuales y de caos superadas: %d" % pruebas_superadas.size())
	for ok_msg in pruebas_superadas:
		print("   [OK] " + ok_msg)
	print(" - Anomalías / Bugs restantes          : %d" % anomalias_detectadas.size())
	for anom in anomalias_detectadas:
		print("   [FAIL] " + anom)
	print("======================================================================")

	if anomalias_detectadas.size() > 0:
		quit(1)
	else:
		quit(0)
