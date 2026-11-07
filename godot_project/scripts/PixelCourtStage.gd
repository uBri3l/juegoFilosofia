extends Control
class_name PixelCourtStage
## Renderizador 2D estilo 8-Bit Pixel Art del Juzgado.
## Dibuja la sala, el Juez, el Abogado Defensor (Jugador) y el Fiscal (IA)
## adaptándose dinámicamente al ancho exacto del contenedor sin cortarse.

const PIXEL_SIZE: int = 4

var anim_time: float = 0.0
var speaker_state: String = "RIVAL" # "JUEZ" | "JUGADOR" | "RIVAL" | "IDLE"
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


func trigger_objection(texto: String = "¡OBJECIÓN!") -> void:
	objection_text = texto
	objection_banner_timer = 1.4


func trigger_damage_flash(target: String) -> void:
	if target == "JUGADOR":
		flash_player_timer = 0.7
	elif target == "RIVAL":
		flash_rival_timer = 0.7


func _draw_px_rect(gx: int, gy: int, gw: int, gh: int, col: Color) -> void:
	draw_rect(
		Rect2(gx * PIXEL_SIZE, gy * PIXEL_SIZE, gw * PIXEL_SIZE, gh * PIXEL_SIZE),
		col,
		true
	)


func _draw() -> void:
	var w_px: int = max(120, int(size.x / PIXEL_SIZE))
	var h_px: int = max(36, int(size.y / PIXEL_SIZE))

	# 1. Pared de fondo del juzgado (estilo NES/8-bit oscuro azul/púrpura)
	_draw_px_rect(0, 0, w_px, h_px, Color("#181425"))
	_draw_px_rect(0, 0, w_px, 14, Color("#262b44"))
	# Marco interior para que se vea claramente el borde izquierdo y derecho completo
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
	var judge_talking: bool = (speaker_state == "JUEZ") and (int(anim_time * 8.0) % 2 == 0)
	_draw_px_rect(jx + 4, jy, 10, 4, Color("#ffffff"))
	_draw_px_rect(jx + 3, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 13, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 5, jy + 3, 8, 7, Color("#f4cca1"))
	_draw_px_rect(jx + 6, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 10, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 8, 4, 2 if judge_talking else 1, Color("#3e2731"))
	_draw_px_rect(jx + 3, jy + 10, 12, 7, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 10, 4, 4, Color("#ffffff"))
	_draw_px_rect(cx - 24, jy + 15, 48, 12, Color("#733e39"))
	_draw_px_rect(cx - 26, jy + 14, 52, 3, Color("#b86f50"))

	# 3. Abogado Defensor (Jugador - Izquierda, traje azul clásico)
	var px_x: int = int(w_px * 0.16)
	var px_y: int = max(14, h_px - 36)
	var player_hit: bool = flash_player_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var player_talking: bool = (speaker_state == "JUGADOR") and (int(anim_time * 9.0) % 2 == 0)
	var suit_player: Color = Color("#ff0044") if player_hit else Color("#0099db")
	var skin_player: Color = Color("#ffffff") if player_hit else Color("#f4cca1")

	_draw_px_rect(px_x + 2, px_y, 12, 4, Color("#4b2d22"))
	_draw_px_rect(px_x, px_y + 1, 3, 2, Color("#6e4230"))
	_draw_px_rect(px_x + 4, px_y + 4, 9, 8, skin_player)
	_draw_px_rect(px_x + 10, px_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(px_x + 9, px_y + 10, 3, 2 if player_talking else 1, Color("#733e39"))
	_draw_px_rect(px_x + 2, px_y + 12, 13, 14, suit_player)
	_draw_px_rect(px_x + 7, px_y + 12, 4, 6, Color("#ffffff"))
	_draw_px_rect(px_x + 8, px_y + 14, 2, 7, Color("#e43b44"))
	if speaker_state == "JUGADOR" or objection_banner_timer > 0.0:
		_draw_px_rect(px_x + 15, px_y + 13, 11, 4, suit_player)
		_draw_px_rect(px_x + 26, px_y + 13, 4, 3, skin_player)

	# 4. Abogado Contrincante / Fiscal IA (Derecha - traje carmesí/vino)
	var rx_x: int = int(w_px * 0.84) - 16
	var rx_y: int = max(14, h_px - 36)
	var rival_hit: bool = flash_rival_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var rival_talking: bool = (speaker_state == "RIVAL") and (int(anim_time * 9.0) % 2 == 0)
	var suit_rival: Color = Color("#ffffff") if rival_hit else Color("#9e2835")
	var skin_rival: Color = Color("#ff7777") if rival_hit else Color("#ead4aa")

	_draw_px_rect(rx_x + 3, rx_y, 11, 4, Color("#c0cbdc"))
	_draw_px_rect(rx_x + 12, rx_y + 2, 3, 6, Color("#8b9bb4"))
	_draw_px_rect(rx_x + 4, rx_y + 4, 9, 8, skin_rival)
	_draw_px_rect(rx_x + 5, rx_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(rx_x + 5, rx_y + 10, 3, 2 if rival_talking else 1, Color("#3e2731"))
	_draw_px_rect(rx_x + 2, rx_y + 12, 13, 14, suit_rival)
	_draw_px_rect(rx_x + 5, rx_y + 12, 5, 8, Color("#ffffff"))
	if speaker_state == "RIVAL":
		_draw_px_rect(rx_x - 10, rx_y + 13, 12, 4, suit_rival)
		_draw_px_rect(rx_x - 13, rx_y + 13, 3, 3, skin_rival)

	# 5. Bancos de madera delanteros (Defensa y Fiscalía)
	var bench_w: int = int(w_px * 0.30)
	_draw_px_rect(6, h_px - 11, bench_w, 11, Color("#733e39"))
	_draw_px_rect(4, h_px - 12, bench_w + 4, 3, Color("#b86f50"))

	_draw_px_rect(w_px - bench_w - 6, h_px - 11, bench_w, 11, Color("#733e39"))
	_draw_px_rect(w_px - bench_w - 8, h_px - 12, bench_w + 4, 3, Color("#b86f50"))

	# 6. Banner dramático de ¡OBJECIÓN! si está activo
	if objection_banner_timer > 0.0:
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
