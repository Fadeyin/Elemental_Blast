extends Button
## Кнопка с Rubik ExtraBold для букв и Rubik Black для цифр.
## Встроенный текст кнопки скрыт (прозрачный font_color), рисуется только _draw.
## При нехватке ширины уменьшает кегль, чтобы текст не вылезал за кнопку.

const MIN_FIT_FONT_SIZE := 14
const HORIZONTAL_FIT_PAD := 16.0

var _cached_font_color := Color.WHITE
var _cached_outline_color := Color(0, 0, 0, 0)
var _cached_outline_size := 0
var _builtin_text_hidden := false


func _activate_mixed_draw() -> void:
	if not _builtin_text_hidden:
		_cache_draw_colors()
		_hide_builtin_text()
	clip_contents = true
	queue_redraw()


func _game_fonts_refresh() -> void:
	_activate_mixed_draw()


func _cache_draw_colors() -> void:
	_cached_font_color = get_theme_color("font_color")
	_cached_outline_color = get_theme_color("font_outline_color")
	_cached_outline_size = get_theme_constant("outline_size")


func _hide_builtin_text() -> void:
	if _builtin_text_hidden:
		return
	_builtin_text_hidden = true
	add_theme_color_override("font_color", Color(1, 1, 1, 0))
	add_theme_color_override("font_outline_color", Color(1, 1, 1, 0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var desired_size := get_theme_font_size("font_size")
	var color: Color = _cached_font_color
	if is_disabled():
		color = color.lerp(Color(0.55, 0.55, 0.55), 0.45)
	var rect := Rect2(Vector2.ZERO, size)
	var avail_w: float = maxf(rect.size.x - HORIZONTAL_FIT_PAD, 8.0)
	var font_size: int = GameFonts.fit_mixed_font_size(text, avail_w, desired_size, MIN_FIT_FONT_SIZE)
	GameFonts.draw_mixed_string_in_rect(
		self,
		rect,
		text,
		font_size,
		color,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		_cached_outline_color,
		_cached_outline_size,
		false,
		TextServer.AUTOWRAP_OFF,
		0.0
	)
