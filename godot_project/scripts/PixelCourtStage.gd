extends Control
class_name PixelCourtStage
## Renderizador 2D estilo 8-Bit Pixel Art del Juzgado.
## Incluye animaciones de turno, objeciones y secuencias completas de VICTORIA y DERROTA.

const PIXEL_SIZE: int = 4

var anim_time: float = 0.0
var speaker_state: String = "RIVAL" # "JUEZ" | "JUGADOR" | "RIVAL" | "IDLE"
var result_state: String = "NONE"   # "NONE" | "VICTORIA" | "DERROTA"
var flash_player_timer: float = 0.0
var flash_rival_timer: float = 0.0
var objection_banner_timer: float = 0.0
var objection_text: String = "¡OBJECIÓN!"


func _ready() -> void:
	clip_contents = true


func _process(delta: float) -> void:
	anim_time += delta
	if flash_player_timer > 0.0:
		flash_player_timer = max(0.0, flash_player_timer - delta)
	if flash_rival_timer > 0.0:
		flash_rival_timer = max(0.0, flash_rival_timer - delta)
	if objection_banner_timer > 0.0:
		objection_banner_timer = max(0.0, objection_banner_timer - delta)
	queue_redraw()


func reset_stage() -> void:
	result_state = "NONE"
	speaker_state = "IDLE"
	flash_player_timer = 0.0
	flash_rival_timer = 0.0
	objection_banner_timer = 0.0


func trigger_objection(texto: String = "¡OBJECIÓN!") -> void:
	objection_text = texto
	objection_banner_timer = 1.4


func trigger_damage_flash(target: String) -> void:
	if target == "JUGADOR":
		flash_player_timer = 0.7
	elif target == "RIVAL":
		flash_rival_timer = 0.7


func trigger_victory_animation() -> void:
	result_state = "VICTORIA"
	objection_banner_timer = 0.0


func trigger_defeat_animation() -> void:
	result_state = "DERROTA"
	objection_banner_timer = 0.0


func _draw_px_rect(gx: int, gy: int, gw: int, gh: int, col: Color) -> void:
	draw_rect(
		Rect2(gx * PIXEL_SIZE, gy * PIXEL_SIZE, gw * PIXEL_SIZE, gh * PIXEL_SIZE),
		col,
		true
	)


func _draw() -> void:
	var w_px: int = max(120, int(size.x / PIXEL_SIZE))
	var h_px: int = max(36, int(size.y / PIXEL_SIZE))

	# 1. Pared de fondo del juzgado (cambia de atmósfera en Victoria o Derrota)
	var bg_col := Color("#181425")
	if result_state == "VICTORIA":
		bg_col = Color("#1b2a1e") if (int(anim_time * 4.0) % 2 == 0) else Color("#182232")
	elif result_state == "DERROTA":
		bg_col = Color("#2e1118") if (int(anim_time * 6.0) % 2 == 0) else Color("#181018")

	_draw_px_rect(0, 0, w_px, h_px, bg_col)
	_draw_px_rect(0, 0, w_px, 14, Color("#262b44"))
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color("#5a6988"), false, 2.0)

	# Pilares clásicos en 8 bits distribuidos proporcionalmente
	var pilares: Array[int] = [
		int(w_px * 0.08),
		int(w_px * 0.27),
		int(w_px * 0.73) - 8,
		int(w_px * 0.92) - 8
	]
	for px in pilares:
		_draw_px_rect(px, 5, 8, h_px - 16, Color("#3a4466"))
		_draw_px_rect(px + 2, 5, 4, h_px - 16, Color("#5a6988"))
		_draw_px_rect(px - 2, 3, 12, 3, Color("#8b9bb4"))

	# Emblema dorado de la Balanza de la Justicia en el centro superior
	var cx: int = int(w_px / 2)
	_draw_px_rect(cx - 8, 3, 16, 11, Color("#3e2731"))
	_draw_px_rect(cx - 1, 5, 2, 7, Color("#feae34"))
	_draw_px_rect(cx - 6, 7, 12, 2, Color("#feae34"))
	_draw_px_rect(cx - 6, 9, 3, 3, Color("#fee761"))
	_draw_px_rect(cx + 3, 9, 3, 3, Color("#fee761"))

	# 2. Estrado del Juez (Centro)
	var jx: int = cx - 9
	var jy: int = 15
	var judge_talking: bool = (speaker_state == "JUEZ" or result_state != "NONE") and (int(anim_time * 8.0) % 2 == 0)
	_draw_px_rect(jx + 4, jy, 10, 4, Color("#ffffff"))
	_draw_px_rect(jx + 3, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 13, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 5, jy + 3, 8, 7, Color("#f4cca1"))
	_draw_px_rect(jx + 6, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 10, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 8, 4, 2 if judge_talking else 1, Color("#3e2731"))
	_draw_px_rect(jx + 3, jy + 10, 12, 7, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 10, 4, 4, Color("#ffffff"))
	# Mazo del juez golpeando en victoria o derrota
	if result_state != "NONE" and (int(anim_time * 6.0) % 2 == 0):
		_draw_px_rect(jx + 16, jy + 8, 4, 6, Color("#b86f50"))
	_draw_px_rect(cx - 24, jy + 15, 48, 12, Color("#733e39"))
	_draw_px_rect(cx - 26, jy + 14, 52, 3, Color("#b86f50"))

	# 3. Abogado Defensor (Jugador - Izquierda)
	var px_x: int = int(w_px * 0.16)
	var jump_offset: int = -3 if (result_state == "VICTORIA" and int(anim_time * 6.0) % 2 == 0) else (4 if result_state == "DERROTA" else 0)
	var px_y: int = max(12, h_px - 36 + jump_offset)
	var player_hit: bool = flash_player_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var player_talking: bool = (speaker_state == "JUGADOR") and (int(anim_time * 9.0) % 2 == 0)
	var suit_player: Color = Color("#ff0044") if player_hit else Color("#0099db")
	var skin_player: Color = Color("#ffffff") if player_hit else Color("#f4cca1")

	_draw_px_rect(px_x + 2, px_y, 12, 4, Color("#4b2d22"))
	_draw_px_rect(px_x, px_y + 1, 3, 2, Color("#6e4230"))
	_draw_px_rect(px_x + 4, px_y + 4, 9, 8, skin_player)
	_draw_px_rect(px_x + 10, px_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(px_x + 9, px_y + 10, 3, 2 if (player_talking or result_state == "VICTORIA") else 1, Color("#733e39"))
	_draw_px_rect(px_x + 2, px_y + 12, 13, 14, suit_player)
	_draw_px_rect(px_x + 7, px_y + 12, 4, 6, Color("#ffffff"))
	_draw_px_rect(px_x + 8, px_y + 14, 2, 7, Color("#e43b44"))

	if result_state == "VICTORIA":
		# Brazos en alto celebrando la victoria
		_draw_px_rect(px_x - 2, px_y + 6, 4, 9, suit_player)
		_draw_px_rect(px_x + 15, px_y + 6, 4, 9, suit_player)
		_draw_px_rect(px_x - 2, px_y + 4, 4, 2, skin_player)
		_draw_px_rect(px_x + 15, px_y + 4, 4, 2, skin_player)
	elif speaker_state == "JUGADOR" or objection_banner_timer > 0.0:
		_draw_px_rect(px_x + 15, px_y + 13, 11, 4, suit_player)
		_draw_px_rect(px_x + 26, px_y + 13, 4, 3, skin_player)

	# 4. Abogado Contrincante / Fiscal IA (Derecha)
	var rx_x: int = int(w_px * 0.84) - 16
	var rival_offset: int = 5 if result_state == "VICTORIA" else (-2 if (result_state == "DERROTA" and int(anim_time * 6.0) % 2 == 0) else 0)
	var rx_y: int = max(12, h_px - 36 + rival_offset)
	var rival_hit: bool = flash_rival_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var rival_talking: bool = (speaker_state == "RIVAL") and (int(anim_time * 9.0) % 2 == 0)
	var suit_rival: Color = Color("#ffffff") if rival_hit else Color("#9e2835")
	var skin_rival: Color = Color("#ff7777") if rival_hit else Color("#ead4aa")

	_draw_px_rect(rx_x + 3, rx_y, 11, 4, Color("#c0cbdc"))
	_draw_px_rect(rx_x + 12, rx_y + 2, 3, 6, Color("#8b9bb4"))
	_draw_px_rect(rx_x + 4, rx_y + 4, 9, 8, skin_rival)
	_draw_px_rect(rx_x + 5, rx_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(rx_x + 5, rx_y + 10, 3, 2 if (rival_talking or result_state == "DERROTA") else 1, Color("#3e2731"))
	_draw_px_rect(rx_x + 2, rx_y + 12, 13, 14, suit_rival)
	_draw_px_rect(rx_x + 5, rx_y + 12, 5, 8, Color("#ffffff"))
	if speaker_state == "RIVAL" or result_state == "DERROTA":
		_draw_px_rect(rx_x - 10, rx_y + 13, 12, 4, suit_rival)
		_draw_px_rect(rx_x - 13, rx_y + 13, 3, 3, skin_rival)

	# 5. Bancos de madera delanteros
	var bench_w: int = int(w_px * 0.30)
	_draw_px_rect(6, h_px - 11, bench_w, 11, Color("#733e39"))
	_draw_px_rect(4, h_px - 12, bench_w + 4, 3, Color("#b86f50"))

	_draw_px_rect(w_px - bench_w - 6, h_px - 11, bench_w, 11, Color("#733e39"))
	_draw_px_rect(w_px - bench_w - 8, h_px - 12, bench_w + 4, 3, Color("#b86f50"))

	# 6. Efectos de partículas 8-bit y cartel de VICTORIA o DERROTA
	if result_state == "VICTORIA":
		var colores_confeti: Array[Color] = [
			Color("#fee761"), Color("#63c74d"), Color("#2ce8f5"), Color("#ff0044"), Color("#ffffff")
		]
		for i in range(28):
			var c_x: int = (i * 19 + int(anim_time * 18.0) * ((i % 3) + 1)) % w_px
			var c_y: int = (i * 11 + int(anim_time * 24.0)) % h_px
			_draw_px_rect(c_x, c_y, 2, 2, colores_confeti[i % colores_confeti.size()])

		var v_bx: float = size.x * 0.5 - 210.0
		var v_by: float = 12.0 + sin(anim_time * 6.0) * 4.0
		draw_rect(Rect2(v_bx - 4, v_by - 4, 428, 48), Color("#fee761"), true)
		draw_rect(Rect2(v_bx, v_by, 420, 40), Color("#1e6f50"), true)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(v_bx + 16, v_by + 27),
			"★ ¡VICTORIA MAGISTRAL EN EL JUICIO! ★",
			HORIZONTAL_ALIGNMENT_CENTER,
			388,
			18,
			Color("#ffffff")
		)

	elif result_state == "DERROTA":
		for i in range(22):
			var r_x: int = (i * 23) % w_px
			var r_y: int = (i * 13 + int(anim_time * 36.0)) % h_px
			_draw_px_rect(r_x, r_y, 1, 4, Color("#e43b44"))

		var d_bx: float = size.x * 0.5 - 210.0 + sin(anim_time * 30.0) * 3.0
		var d_by: float = 12.0
		draw_rect(Rect2(d_bx - 4, d_by - 4, 428, 48), Color("#ff0044"), true)
		draw_rect(Rect2(d_bx, d_by, 420, 40), Color("#3e121c"), true)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(d_bx + 16, d_by + 27),
			"✖ ¡DERROTA! CREDIBILIDAD AGOTADA ✖",
			HORIZONTAL_ALIGNMENT_CENTER,
			388,
			18,
			Color("#fee761")
		)

	elif objection_banner_timer > 0.0:
		var bx: float = size.x * 0.5 - 160.0
		var by: float = 14.0
		draw_rect(Rect2(bx - 3, by - 3, 326, 42), Color("#fee761"), true)
		draw_rect(Rect2(bx, by, 320, 36), Color("#e43b44"), true)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(bx + 16, by + 25),
			objection_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			288,
			18,
			Color("#ffffff")
		)
