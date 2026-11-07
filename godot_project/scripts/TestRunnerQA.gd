extends SceneTree
## Script de Prueba Automatizada Exhaustiva de Escena (QA Headless) para Godot 4.
## Ejecución:
## Godot_v4.7.2-stable_win64_console.exe --headless --path godot_project -s scripts/TestRunnerQA.gd

var total_assertions: int = 0
var failed_assertions: int = 0


func _assert(condicion: bool, descripcion: String) -> void:
	total_assertions += 1
	if not condicion:
		failed_assertions += 1
		push_error("[QA FAIL] " + descripcion)
		print("   [FAIL] " + descripcion)
	else:
		print("   [OK] " + descripcion)


func _init() -> void:
	call_deferred("_ejecutar_suite_qa")


func _ejecutar_suite_qa() -> void:
	print("======================================================================")
	print(" INICIANDO SUITE QA AUTOMATIZADA EN GODOT HEADLESS (MainCourtroom)")
	print("======================================================================")

	var packed: PackedScene = load("res://scenes/MainCourtroom.tscn")
	_assert(packed != null, "Carga de escena res://scenes/MainCourtroom.tscn exitosa")

	var main_node: Control = packed.instantiate()
	root.add_child(main_node)

	# Esperar 2 frames para que _ready() construya los contenedores y el menú principal
	await process_frame
	await process_frame

	# 1. Verificar estado inicial en Menú Principal
	print("\n-> [1/6] Verificando estado inicial del Menú Principal...")
	_assert(main_node.menu_container != null and main_node.menu_container.visible == true, "menu_container está visible al iniciar")
	_assert(main_node.game_container != null and main_node.game_container.visible == false, "game_container está oculto al iniciar")
	_assert(main_node.btns_menu_casos.size() == 4, "Existen 4 botones de selección de caso en el menú")
	_assert(main_node.btns_menu_difs.size() == 3, "Existen 3 botones de selección de dificultad en el menú")

	# 2. Probar selección de los 4 casos y las 3 dificultades en el menú
	print("\n-> [2/6] Probando selección de los 4 casos y 3 dificultades...")
	var casos_esperados: Array[String] = [
		"caso_algoritmo_medico",
		"caso_vertido_quimico",
		"caso_auditoria_contable",
		"caso_ia_periodismo"
	]
	for i in range(4):
		main_node._seleccionar_caso_en_menu(i)
		_assert(main_node.indice_caso_seleccionado == i, "Índice de caso actualizado a %d" % i)
		_assert(main_node.caso_id_actual == casos_esperados[i], "caso_id_actual coincide con '%s'" % casos_esperados[i])
		_assert(main_node.lbl_menu_caso_titulo.text.length() > 5, "Título del caso %d actualizado en UI" % i)

	var difs_esperadas: Array[String] = ["FACIL", "NORMAL", "DIFICIL"]
	for j in range(3):
		main_node._seleccionar_dificultad_en_menu(j)
		_assert(main_node.indice_dificultad_seleccionada == j, "Índice de dificultad actualizado a %d" % j)
		_assert(main_node.dificultad_actual == difs_esperadas[j], "dificultad_actual coincide con '%s'" % difs_esperadas[j])

	# Dejar seleccionado Caso 1 en NORMAL e iniciar partida
	main_node._seleccionar_caso_en_menu(0)
	main_node._seleccionar_dificultad_en_menu(1)

	# 3. Iniciar partida desde el menú y verificar transición al Juzgado
	print("\n-> [3/6] Probando comenzar_partida_desde_menu() y recepción del turno inicial...")
	main_node.comenzar_partida_desde_menu()
	_assert(main_node.menu_container.visible == false, "menu_container se oculta al iniciar partida")
	_assert(main_node.game_container.visible == true, "game_container se muestra al iniciar partida")
	_assert(main_node.hp_jugador == 100 and main_node.hp_rival == 100, "Barras de vida inician en 100/100 HP")
	_assert(main_node.TIEMPO_MAX_ESPERA <= 6.0 and main_node.TIEMPO_MAX_ESPERA > 0.0, "Watchdog anti-bloqueo TIEMPO_MAX_ESPERA configurado (%.1fs)" % main_node.TIEMPO_MAX_ESPERA)

	# Esperar hasta que termine la petición inicial (o actúe el respaldo rápido)
	var t_wait: float = 0.0
	while main_node.esperando_respuesta and t_wait < 6.5:
		await create_timer(0.15).timeout
		t_wait += 0.15

	_assert(not main_node.esperando_respuesta, "El turno inicial se resolvió sin bloqueo en %.2fs" % t_wait)
	_assert(main_node.opciones_actuales.size() == 4, "Se cargaron 4 opciones de argumento en el juzgado")
	_assert(main_node.lbl_dialogo_rival.text.length() > 10, "El diálogo del abogado rival se muestra en pantalla")

	# 4. Simular turnos de juego y probar Watchdog Anti-Bloqueo explícitamente
	print("\n-> [4/6] Simulando jugada de argumento y probando Watchdog Anti-Bloqueo...")
	main_node._on_opcion_argumento_elegida(0)
	_assert(main_node.esperando_respuesta == true, "Al elegir opción se activa esperando_respuesta")
	# Forzar simulación de demora de red adelantando el reloj del Watchdog a TIEMPO_MAX_ESPERA
	main_node._process(main_node.TIEMPO_MAX_ESPERA + 0.1)
	_assert(main_node.esperando_respuesta == false, "Watchdog Anti-Bloqueo destrancó el turno automáticamente al superar TIEMPO_MAX_ESPERA")
	_assert(main_node.opciones_actuales.size() == 4, "Watchdog mantuvo 4 opciones válidas tras el respaldo instantáneo")

	# 5. Probar transición a pantalla de VICTORIA y de DERROTA
	print("\n-> [5/6] Probando pantallas y animaciones de VICTORIA y DERROTA...")
	main_node._mostrar_pantalla_fin_de_juego(true)
	_assert(main_node.juicio_terminado == true, "juicio_terminado es true en VICTORIA")
	_assert(main_node.stage.result_state == "VICTORIA", "stage.result_state cambió a 'VICTORIA'")
	_assert(main_node.endgame_panel.visible == true, "endgame_panel visible en VICTORIA")
	_assert(main_node.grid_opciones.visible == false, "grid_opciones oculto al terminar partida en VICTORIA")
	_assert(main_node.lbl_endgame_titulo.text.contains("VICTORIA"), "Título de fin de juego muestra VICTORIA")

	main_node._mostrar_pantalla_fin_de_juego(false)
	_assert(main_node.juicio_terminado == true, "juicio_terminado es true en DERROTA")
	_assert(main_node.stage.result_state == "DERROTA", "stage.result_state cambió a 'DERROTA'")
	_assert(main_node.endgame_panel.visible == true, "endgame_panel visible en DERROTA")
	_assert(main_node.lbl_endgame_titulo.text.contains("DERROTA"), "Título de fin de juego muestra DERROTA")

	# 6. Probar volver al Menú Principal
	print("\n-> [6/6] Probando retorno al Menú Principal (mostrar_menu_principal)...")
	main_node.mostrar_menu_principal()
	_assert(main_node.menu_container.visible == true, "menu_container vuelve a estar visible")
	_assert(main_node.game_container.visible == false, "game_container vuelve a ocultarse")
	_assert(main_node.esperando_respuesta == false, "esperando_respuesta queda en false al volver al menú")

	await process_frame
	await process_frame

	print("\n======================================================================")
	print(" RESUMEN SUITE QA GODOT HEADLESS")
	print("======================================================================")
	print(" - Aserciones pasadas : %d / %d" % [total_assertions - failed_assertions, total_assertions])
	print(" - Aserciones fallidas: %d" % failed_assertions)
	print("======================================================================")

	if failed_assertions > 0:
		quit(1)
	else:
		print(" RESULTADO FINAL GODOT QA: 100% EXITOSO")
		quit(0)
