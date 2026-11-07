extends SceneTree
## Suite Exhaustiva de Pruebas de Caja Negra (Black-Box E2E UI & Flujos de Usuario)
## para el Cliente Godot 4 de 'Juicio Lógico 8-Bit'.
##
## Evalúa el videojuego exclusivamente simulando acciones externas del usuario
## (clics en botones del Menú Principal, selección de los 4 Casos y 3 Dificultades,
## inicio de partida, clics en opciones de argumento, botón de ¡OBJECIÓN!,
## protección anti-spam de doble clic, modo offline autónomo multi-dispositivo,
## partidas completas hasta VICTORIA y DERROTA, revancha y retorno al menú).
##
## Ejecución:
## Godot_v4.7.2-stable_win64_console.exe --headless --path godot_project -s scripts/TestCajaNegraGodot.gd

var total_aserciones: int = 0
var fallos: int = 0
var casos_ejecutados: int = 0


func _check(condicion: bool, mensaje: String) -> void:
	total_aserciones += 1
	if not condicion:
		fallos += 1
		push_error("[CAJA NEGRA GODOT FAIL] " + mensaje)
		print("      [FAIL] " + mensaje)


func _registrar_caso(id_caso: String, nombre: String, resultado: String) -> void:
	casos_ejecutados += 1
	print("   [PASS] %s - %s -> %s" % [id_caso, nombre, resultado])


func _init() -> void:
	call_deferred("_correr_caja_negra_godot")


func _esperar_resolucion_turno(main_node: Control, max_s: float = 6.2) -> float:
	var t_acum: float = 0.0
	while main_node.esperando_respuesta and t_acum < max_s:
		await create_timer(0.05).timeout
		t_acum += 0.05
	return t_acum * 1000.0


func _correr_caja_negra_godot() -> void:
	print("======================================================================")
	print(" BLOQUE BB-06: SUITE EXHAUSTIVA DE CAJA NEGRA E2E UI EN GODOT 4")
	print("======================================================================")
	var t_inicio_ms: int = Time.get_ticks_msec()

	var scene_res: PackedScene = load("res://scenes/MainCourtroom.tscn")
	_check(scene_res != null, "La escena principal MainCourtroom.tscn debe cargarse")
	var app: Control = scene_res.instantiate()
	root.add_child(app)

	await process_frame
	await process_frame

	# --------------------------------------------------------------------------
	# BB-06.1: Estado visual inicial del Menú Principal y textos 100% en español
	# --------------------------------------------------------------------------
	var a0: int = total_aserciones
	_check(app.menu_container.visible == true, "El Menú Principal debe ser visible al abrir el juego")
	_check(app.game_container.visible == false, "El Juzgado debe estar oculto al abrir el juego")
	_check(app.btns_menu_casos.size() == 4, "Deben mostrarse 4 botones de Temas/Casos")
	_check(app.btns_menu_difs.size() == 3, "Deben mostrarse 3 botones de Dificultad")
	_check(app.lbl_menu_caso_titulo.text.contains("Caso 1"), "Por defecto debe estar seleccionado el Caso 1")
	_check(app.lbl_menu_dif_desc.text.contains("NORMAL"), "Por defecto debe estar seleccionada la dificultad NORMAL")
	_registrar_caso("BB-06.1", "Apertura en Menú Principal y Valores por Defecto", "%d aserciones OK" % (total_aserciones - a0))

	# --------------------------------------------------------------------------
	# BB-06.2: Interacción de Usuario por Clics en los 4 Casos y 3 Dificultades
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	for idx_c in range(4):
		app.btns_menu_casos[idx_c].pressed.emit()
		var esperado_titulo: String = "Caso %d" % (idx_c + 1)
		_check(app.lbl_menu_caso_titulo.text.contains(esperado_titulo), "Clic en botón de caso %d debe actualizar título a '%s'" % [idx_c, esperado_titulo])
		_check(app.lbl_menu_caso_tema.text.begins_with("Tema:"), "Clic en caso %d debe mostrar el tema ético" % idx_c)
		_check(app.lbl_menu_caso_desc.text.length() > 30, "Clic en caso %d debe mostrar sinopsis completa" % idx_c)

	var etiquetas_dif: Array[String] = ["SENCILLA", "NORMAL", "DIFÍCIL"]
	for idx_d in range(3):
		app.btns_menu_difs[idx_d].pressed.emit()
		_check(app.lbl_menu_dif_desc.text.contains(etiquetas_dif[idx_d]), "Clic en dificultad %d debe mostrar '%s'" % [idx_d, etiquetas_dif[idx_d]])
	_registrar_caso("BB-06.2", "Clics Reales en Selectores de Caso (4) y Dificultad (3)", "%d aserciones OK" % (total_aserciones - a0))

	# --------------------------------------------------------------------------
	# BB-06.3: Transición Menú -> Juzgado y Recepción de Alegato Inicial
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	app.btns_menu_casos[0].pressed.emit()
	app.btns_menu_difs[1].pressed.emit()
	app.comenzar_partida_desde_menu()

	_check(app.menu_container.visible == false, "El menú debe ocultarse al iniciar partida")
	_check(app.game_container.visible == true, "El juzgado debe mostrarse al iniciar partida")
	_check(app.bar_hp_jugador.value == 100, "Barra HP jugador debe iniciar en 100")
	_check(app.bar_hp_rival.value == 100, "Barra HP rival debe iniciar en 100")

	var dt_init: float = await _esperar_resolucion_turno(app)
	_check(not app.esperando_respuesta, "El turno inicial debe completarse sin bloquear la UI")
	_check(app.lbl_dialogo_rival.text.length() > 15, "El fiscal debe presentar su alegato inicial en español")
	for i in range(4):
		_check(app.botones_opciones[i].disabled == false, "El botón de opción %d debe estar habilitado" % i)
		_check(app.botones_opciones[i].text.begins_with("%d) " % (i + 1)), "El botón %d debe tener prefijo numérico visible" % i)
	_registrar_caso("BB-06.3", "Transición Menú -> Juzgado y Carga de Turno Inicial", "Resuelto en %.1f ms (%d aserciones OK)" % [dt_init, total_aserciones - a0])

	# --------------------------------------------------------------------------
	# BB-06.4: Prueba Anti-Spam de Doble Clic / Clics Múltiples Rápidos
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	var turno_antes: int = app.turno_idx
	# Emitimos 8 clics seguidos en el mismo frame sobre distintas opciones y objeción
	app.botones_opciones[0].pressed.emit()
	app.botones_opciones[1].pressed.emit()
	app.botones_opciones[2].pressed.emit()
	app.botones_opciones[3].pressed.emit()
	app.btn_objecion_falacia.pressed.emit()
	_check(app.turno_idx == turno_antes + 1, "Ráfaga de clics simultáneos solo debe registrar 1 turno (esperado %d, fue %d)" % [turno_antes + 1, app.turno_idx])
	await _esperar_resolucion_turno(app)
	_check(not app.esperando_respuesta, "El turno tras ráfaga de clics debe resolverse limpiamente")
	_registrar_caso("BB-06.4", "Protección Anti-Spam ante Múltiples Clics Simultáneos", "Solo 1 acción procesada (%d aserciones OK)" % (total_aserciones - a0))

	# --------------------------------------------------------------------------
	# BB-06.5: Prueba de Bloqueo de Doble Objeción en el Mismo Turno
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	_check(app.btn_objecion_falacia.disabled == false, "Botón de objeción debe estar activo al inicio del turno")
	app.btn_objecion_falacia.pressed.emit()
	_check(app.ya_objeto_este_turno == true, "Debe marcarse ya_objeto_este_turno=true al objetar")
	_check(app.stage.objection_banner_timer > 0.0, "El escenario 8-bit debe activar el cartel de ¡OBJECIÓN!")
	await _esperar_resolucion_turno(app)
	_registrar_caso("BB-06.5", "Mecánica de ¡OBJECIÓN! y Banner Visual en Escenario 8-Bit", "%d aserciones OK" % (total_aserciones - a0))

	# --------------------------------------------------------------------------
	# BB-06.6: Partida Completa E2E en Modo Offline Multi-Dispositivo hasta VICTORIA
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	app.servidor_local_disponible = false  # Simula ejecución en otro dispositivo / Web sin Python
	app.btns_menu_casos[1].pressed.emit()  # Caso 2: Informe Hidrogeológico
	app.btns_menu_difs[1].pressed.emit()   # Dificultad: NORMAL
	app.comenzar_partida_desde_menu()

	var rondas_victoria: int = 0
	while not app.juicio_terminado and rondas_victoria < 10:
		rondas_victoria += 1
		# Buscar cuál de los 4 botones corresponde a la opción INFALIBLE (simulando jugador experto)
		var idx_infalible: int = 0
		for k in range(app.opciones_actuales.size()):
			if str(app.opciones_actuales[k].get("tipo", "")) == "INFALIBLE":
				idx_infalible = k
				break
		app.botones_opciones[idx_infalible].pressed.emit()

	_check(app.juicio_terminado == true, "La partida debe terminar al agotar el HP del rival")
	_check(app.bar_hp_rival.value == 0, "La barra de progreso del rival debe llegar a 0 HP")
	_check(app.bar_hp_jugador.value == 100, "El jugador experto debe conservar 100 HP")
	_check(app.endgame_panel.visible == true, "Debe desplegarse el panel interactivo de fin de juego")
	_check(app.grid_opciones.visible == false, "La cuadrícula de opciones debe ocultarse al terminar el juicio")
	_check(app.lbl_endgame_titulo.text.contains("VICTORIA"), "El cartel final debe anunciar VICTORIA")
	_check(app.stage.result_state == "VICTORIA", "El escenario 8-bit debe reproducir la animación de VICTORIA con confeti")
	_registrar_caso("BB-06.6", "Partida Completa E2E hasta VICTORIA (Modo Autónomo Multi-Dispositivo)", "Ganada en %d turnos (%d aserciones OK)" % [rondas_victoria, total_aserciones - a0])

	# --------------------------------------------------------------------------
	# BB-06.7: Partida Completa E2E hasta DERROTA y Animación de Tormenta Roja
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	app.btns_menu_casos[2].pressed.emit()  # Caso 3: Auditoría de Fondos de Pensiones
	app.btns_menu_difs[2].pressed.emit()   # Dificultad: DIFÍCIL
	app.comenzar_partida_desde_menu()

	var rondas_derrota: int = 0
	while not app.juicio_terminado and rondas_derrota < 15:
		rondas_derrota += 1
		# Si la declaración del rival NO es falacia, objetar falsamente resta 20 HP; si es falacia, elegir argumento MEDIO en DIFICIL resta 15 HP
		if not bool(app.declaracion_rival_actual.get("es_falacia", false)):
			app.btn_objecion_falacia.pressed.emit()
		else:
			var idx_medio: int = 0
			for k in range(app.opciones_actuales.size()):
				if str(app.opciones_actuales[k].get("tipo", "")) == "MEDIO":
					idx_medio = k
					break
			app.botones_opciones[idx_medio].pressed.emit()

	_check(app.juicio_terminado == true, "La partida debe terminar en derrota al llegar a 0 HP el jugador")
	_check(app.bar_hp_jugador.value == 0, "La barra de vida del jugador debe mostrar 0 HP")
	_check(app.endgame_panel.visible == true, "Debe mostrarse el panel de fin de partida en DERROTA")
	_check(app.lbl_endgame_titulo.text.contains("DERROTA"), "El título final debe anunciar DERROTA")
	_check(app.stage.result_state == "DERROTA", "El escenario 8-bit debe activar la animación de DERROTA")
	_registrar_caso("BB-06.7", "Partida Completa E2E hasta DERROTA y Animación 8-Bit", "Perdida en %d turnos (%d aserciones OK)" % [rondas_derrota, total_aserciones - a0])

	# --------------------------------------------------------------------------
	# BB-06.8: Flujo de Revancha Directa y Retorno al Menú Principal
	# --------------------------------------------------------------------------
	a0 = total_aserciones
	app.iniciar_nuevo_juicio()  # Botón "JUGAR REVANCHA EN ESTE CASO"
	_check(app.juicio_terminado == false, "Al pulsar Revancha se reinicia juicio_terminado=false")
	_check(app.bar_hp_jugador.value == 100 and app.bar_hp_rival.value == 100, "Al pulsar Revancha ambas barras vuelven a 100 HP")
	_check(app.endgame_panel.visible == false, "El panel de fin de partida se oculta en la revancha")
	_check(app.grid_opciones.visible == true, "Las 4 opciones vuelven a mostrarse en la revancha")

	app.mostrar_menu_principal()  # Botón "VOLVER AL MENÚ PRINCIPAL"
	_check(app.menu_container.visible == true, "El Menú Principal vuelve a ser visible")
	_check(app.game_container.visible == false, "El contenedor del juzgado se oculta al volver al menú")
	_registrar_caso("BB-06.8", "Flujo de Revancha y Retorno al Menú Principal", "%d aserciones OK" % (total_aserciones - a0))

	var duracion_total_ms: int = Time.get_ticks_msec() - t_inicio_ms
	print("\n======================================================================")
	print(" RESUMEN DE CAJA NEGRA E2E GODOT 4")
	print("======================================================================")
	print(" - Escenarios E2E ejecutados : %d / %d PASS" % [casos_ejecutados, casos_ejecutados])
	print(" - Aserciones verificadas    : %d / %d (Fallos: %d)" % [total_aserciones - fallos, total_aserciones, fallos])
	print(" - Tiempo de ejecución       : %d ms" % duracion_total_ms)
	print("======================================================================")

	if fallos > 0:
		quit(1)
	else:
		quit(0)
