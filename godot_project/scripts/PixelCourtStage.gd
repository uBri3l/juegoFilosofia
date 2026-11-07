extends Control
class_name PixelCourtStage
## Renderizador 2D estilo 8-Bit Pixel Art del Juzgado.
## Dibuja la sala, el Juez, el Abogado Defensor (Jugador) y el Fiscal (IA)
## utilizando bloques de píxeles escalados para garantizar estética retro pura.

const PIXEL_SIZE: int = 4

var anim_time: float = 0.0
var speaker_state: String = "RIVAL" # "JUEZ" | "JUGADOR" | "RIVAL" | "IDLE"
var flash_player_timer: float = 0.0
var flash_rival_timer: float = 0.0
var objection_banner_timer: float = 0.0
var objection_text: String = "¡OBJECIÓN!"


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
	var w_px: int = int(size.x / PIXEL_SIZE)
	var h_px: int = int(size.y / PIXEL_SIZE)

	# 1. Pared de fondo del juzgado (estilo NES/8-bit oscuro azul/púrpura)
	_draw_px_rect(0, 0, w_px, h_px, Color("#181425"))
	_draw_px_rect(0, 0, w_px, 16, Color("#262b44"))

	# Pilares clásicos en 8 bits
	for px in [18, 65, 175, 222]:
		_draw_px_rect(px, 6, 8, h_px - 18, Color("#3a4466"))
		_draw_px_rect(px + 2, 6, 4, h_px - 18, Color("#5a6988"))
		_draw_px_rect(px - 2, 4, 12, 4, Color("#8b9bb4"))

	# Emblema dorado de la Balanza de la Justicia en el centro superior
	var cx: int = int(w_px / 2)
	_draw_px_rect(cx - 8, 5, 16, 12, Color("#3e2731"))
	_draw_px_rect(cx - 1, 7, 2, 8, Color("#feae34"))
	_draw_px_rect(cx - 6, 9, 12, 2, Color("#feae34"))
	_draw_px_rect(cx - 6, 11, 3, 3, Color("#fee761"))
	_draw_px_rect(cx + 3, 11, 3, 3, Color("#fee761"))

	# 2. Estrado del Juez (Centro)
	var jx: int = cx - 9
	var jy: int = 20
	var judge_talking: bool = (speaker_state == "JUEZ") and (int(anim_time * 8.0) % 2 == 0)
	# Peluca blanca 8-bit y rostro
	_draw_px_rect(jx + 4, jy, 10, 4, Color("#ffffff"))
	_draw_px_rect(jx + 3, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 13, jy + 3, 2, 7, Color("#e0e0e0"))
	_draw_px_rect(jx + 5, jy + 3, 8, 7, Color("#f4cca1"))
	# Ojos y boca del juez
	_draw_px_rect(jx + 6, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 10, jy + 5, 2, 2, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 8, 4, 2 if judge_talking else 1, Color("#3e2731"))
	# Toga negra
	_draw_px_rect(jx + 3, jy + 10, 12, 8, Color("#181425"))
	_draw_px_rect(jx + 7, jy + 10, 4, 4, Color("#ffffff"))
	# Mesa alta del juez
	_draw_px_rect(cx - 26, jy + 16, 52, 14, Color("#733e39"))
	_draw_px_rect(cx - 28, jy + 15, 56, 3, Color("#b86f50"))

	# 3. Abogado Defensor (Jugador - Izquierda, traje azul clásico)
	var px_x: int = 34
	var px_y: int = 26
	var player_hit: bool = flash_player_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var player_talking: bool = (speaker_state == "JUGADOR") and (int(anim_time * 9.0) % 2 == 0)
	var suit_player: Color = Color("#ff0044") if player_hit else Color("#0099db")
	var skin_player: Color = Color("#ffffff") if player_hit else Color("#f4cca1")

	# Cabello puntiagudo retro
	_draw_px_rect(px_x + 2, px_y, 12, 4, Color("#181425"))
	_draw_px_rect(px_x, px_y + 1, 3, 2, Color("#181425"))
	# Rostro
	_draw_px_rect(px_x + 4, px_y + 4, 9, 8, skin_player)
	_draw_px_rect(px_x + 10, px_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(px_x + 9, px_y + 10, 3, 2 if player_talking else 1, Color("#733e39"))
	# Traje y corbata roja
	_draw_px_rect(px_x + 2, px_y + 12, 13, 16, suit_player)
	_draw_px_rect(px_x + 7, px_y + 12, 4, 6, Color("#ffffff"))
	_draw_px_rect(px_x + 8, px_y + 14, 2, 8, Color("#e43b44"))
	# Brazo apuntando cuando habla u objeta
	if speaker_state == "JUGADOR" or objection_banner_timer > 0.0:
		_draw_px_rect(px_x + 15, px_y + 13, 12, 4, suit_player)
		_draw_px_rect(px_x + 27, px_y + 13, 4, 3, skin_player)

	# 4. Abogado Contrincante / Fiscal IA (Derecha - traje carmesí/vino)
	var rx_x: int = w_px - 52
	var rx_y: int = 26
	var rival_hit: bool = flash_rival_timer > 0.0 and (int(anim_time * 16.0) % 2 == 0)
	var rival_talking: bool = (speaker_state == "RIVAL") and (int(anim_time * 9.0) % 2 == 0)
	var suit_rival: Color = Color("#ffffff") if rival_hit else Color("#9e2835")
	var skin_rival: Color = Color("#ff7777") if rival_hit else Color("#ead4aa")

	# Cabello plateado elegante de fiscal
	_draw_px_rect(rx_x + 3, rx_y, 11, 4, Color("#c0cbdc"))
	_draw_px_rect(rx_x + 12, rx_y + 2, 3, 6, Color("#8b9bb4"))
	# Rostro
	_draw_px_rect(rx_x + 4, rx_y + 4, 9, 8, skin_rival)
	_draw_px_rect(rx_x + 5, rx_y + 6, 2, 2, Color("#181425"))
	_draw_px_rect(rx_x + 5, rx_y + 10, 3, 2 if rival_talking else 1, Color("#3e2731"))
	# Traje fiscal con chorrera blanca
	_draw_px_rect(rx_x + 2, rx_y + 12, 13, 16, suit_rival)
	_draw_px_rect(rx_x + 5, rx_y + 12, 5, 9, Color("#ffffff"))
	if speaker_state == "RIVAL":
		_draw_px_rect(rx_x - 10, rx_y + 14, 12, 4, suit_rival)
		_draw_px_rect(rx_x - 13, rx_y + 14, 3, 3, skin_rival)

	# 5. Bancos de madera delanteros (Defensa y Fiscalía)
	_draw_px_rect(10, h_px - 14, 78, 14, Color("#733e39"))
	_draw_px_rect(8, h_px - 15, 82, 3, Color("#b86f50"))

	_draw_px_rect(w_px - 88, h_px - 14, 78, 14, Color("#733e39"))
	_draw_px_rect(w_px - 90, h_px - 15, 82, 3, Color("#b86f50"))

	# 6. Banner dramático de ¡OBJECIÓN! si está activo
	if objection_banner_timer > 0.0:
		var bx: float = size.x * 0.5 - 170.0
		var by: float = 18.0
		draw_rect(Rect2(bx - 4, by - 4, 348, 48), Color("#fee761"), true)
		draw_rect(Rect2(bx, by, 340, 40), Color("#e43b44"), true)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(bx + 24, by + 28),
			objection_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			300,
			22,
			Color("#ffffff")
		)
