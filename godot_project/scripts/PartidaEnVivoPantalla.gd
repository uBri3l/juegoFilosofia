extends SceneTree
## Juega 2 partidas completas en vivo en la pantalla del usuario (paso a paso,
## turno por turno, sin atajos):
## - Partida 1 (Conectado al Servidor LiteLLM): Desde el Menú Principal hasta VICTORIA
##   reduciendo la vida del rival turno por turno (100 -> 75 -> 50 -> 25 -> 0 HP).
## - Partida 2 (Modo Autónomo Sin Servidor, como en otro dispositivo): Desde el Menú
##   Principal hasta DERROTA reduciendo la vida del jugador turno por turno hasta 0 HP.

var dir_vivo: String = "c:/Users/gabri/OneDrive/Escritorio/juegoFilosofia/capturas_partida_real"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(dir_vivo)
	call_deferred("_jugar_en_vivo")


func _capturar(nombre: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = root.get_texture()
	if tex:
		var img: Image = tex.get_image()
		if img:
			img.save_png(dir_vivo + "/" + nombre + ".png")
			print("   [PANTALLA CAPTURADA] %s.png" % nombre)


func _esperar_respuesta(app: Control) -> void:
	var t: float = 0.0
	while app.esperando_respuesta and t < 6.2:
		await create_timer(0.05).timeout
		t += 0.05


func _jugar_en_vivo() -> void:
	print("======================================================================")
	print(" JUGANDO PARTIDAS REALES EN PANTALLA (TURNO POR TURNO HASTA 0 HP)")
	print("======================================================================")

	var packed: PackedScene = load("res://scenes/MainCourtroom.tscn")
	var app: Control = packed.instantiate()
	root.add_child(app)

	await create_timer(0.4).timeout
	DisplayServer.window_move_to_foreground()

	# --------------------------------------------------------------------------
	# PARTIDA 1: JUGANDO PASO A PASO HASTA VICTORIA (100 -> 75 -> 50 -> 25 -> 0 HP)
	# --------------------------------------------------------------------------
	print("\n-> [PARTIDA 1] Seleccionando Caso 1 en Dificultad NORMAL en el Menú Principal...")
	app.btns_menu_casos[0].pressed.emit()
	app.btns_menu_difs[1].pressed.emit()
	await create_timer(0.5).timeout
	await _capturar("01_menu_seleccion_jugador")

	print("-> [PARTIDA 1] Pulsando '¡INICIAR PARTIDA Y ENTRAR AL JUZGADO!'...")
	app.comenzar_partida_desde_menu()
	await _esperar_respuesta(app)
	await create_timer(0.5).timeout
	print("   Estado Inicial -> Jugador: %d/100 HP | Rival: %d/100 HP" % [app.hp_jugador, app.hp_rival])
	await _capturar("02_partida1_turno0_100hp_vs_100hp")

	var paso: int = 0
	while not app.juicio_terminado and paso < 8:
		paso += 1
		# Si el fiscal dijo una falacia y podemos objetar, ¡objetamos! Si no, elegimos el argumento INFALIBLE
		if bool(app.declaracion_rival_actual.get("es_falacia", false)) and not app.btn_objecion_falacia.disabled:
			print("   [Jugada %d] El jugador detecta falacia del fiscal y pulsa '¡OBJECIÓN!'..." % paso)
			app.btn_objecion_falacia.pressed.emit()
		else:
			var idx_mejor: int = 0
			for i in range(app.opciones_actuales.size()):
				if str(app.opciones_actuales[i].get("tipo", "")) == "INFALIBLE":
					idx_mejor = i
					break
			print("   [Jugada %d] El jugador elige el argumento ético #%d (INFALIBLE)..." % [paso, idx_mejor + 1])
			app.botones_opciones[idx_mejor].pressed.emit()

		await _esperar_respuesta(app)
		await create_timer(0.55).timeout
		print("   Resultado Jugada %d -> Jugador: %d/100 HP (Barra=%.0f) | Rival: %d/100 HP (Barra=%.0f)" % [
			paso, app.hp_jugador, app.bar_hp_jugador.value, app.hp_rival, app.bar_hp_rival.value
		])
		await _capturar("03_partida1_jugada%d_jugador%dhp_rival%dhp" % [paso, app.hp_jugador, app.hp_rival])

	await create_timer(0.7).timeout
	await _capturar("04_partida1_victoria_final_rival_0hp")

	# --------------------------------------------------------------------------
	# PARTIDA 2: MODO AUTÓNOMO SIN SERVIDOR (MULTI-DISPOSITIVO) HASTA DERROTA (0 HP)
	# --------------------------------------------------------------------------
	print("\n-> [PARTIDA 2 - SIN SERVIDOR] Volviendo al Menú Principal y desactivando conexión al servidor...")
	app.mostrar_menu_principal()
	app.servidor_local_disponible = false # Fuerza modo 100% autónomo sin servidor
	app.btns_menu_casos[2].pressed.emit() # Caso 3: Auditoría de Fondos de Pensiones
	app.btns_menu_difs[2].pressed.emit()  # Dificultad: DIFÍCIL
	await create_timer(0.5).timeout

	print("-> [PARTIDA 2 - SIN SERVIDOR] Iniciando Caso 3 en DIFÍCIL y cometiendo errores hasta llegar a 0 HP...")
	app.comenzar_partida_desde_menu()
	await create_timer(0.4).timeout

	var paso_d: int = 0
	while not app.juicio_terminado and paso_d < 10:
		paso_d += 1
		# Para perder rápido como un mal jugador: si el argumento del rival NO es falacia y podemos objetar, objetamos en falso (-20 HP); si no, elegimos la opción FALACIA (-25 HP) o MEDIO (-15 HP)
		if (not bool(app.declaracion_rival_actual.get("es_falacia", false))) and (not app.btn_objecion_falacia.disabled):
			print("   [Jugada Errónea %d] El jugador hace una '¡OBJECIÓN!' improcedente (-20 HP)..." % paso_d)
			app.btn_objecion_falacia.pressed.emit()
		else:
			var idx_peor: int = 0
			for k in range(app.opciones_actuales.size()):
				if str(app.opciones_actuales[k].get("tipo", "")) == "FALACIA":
					idx_peor = k
					break
			print("   [Jugada Errónea %d] El jugador elige la opción #%d con FALACIA (-25 HP)..." % [paso_d, idx_peor + 1])
			app.botones_opciones[idx_peor].pressed.emit()

		await create_timer(0.55).timeout
		print("   Resultado Jugada %d -> Jugador: %d/100 HP (Barra=%.0f) | Rival: %d/100 HP (Barra=%.0f)" % [
			paso_d, app.hp_jugador, app.bar_hp_jugador.value, app.hp_rival, app.bar_hp_rival.value
		])
		await _capturar("05_partida2_jugada%d_jugador%dhp_rival%dhp" % [paso_d, app.hp_jugador, app.hp_rival])

	await create_timer(0.7).timeout
	await _capturar("06_partida2_derrota_final_jugador_0hp")

	print("\n======================================================================")
	print(" PARTIDAS REALES EN PANTALLA FINALIZADAS CON ÉXITO")
	print("======================================================================")
	quit(0)
