extends Button
## Кнопка с Rubik ExtraBold для букв и Rubik Black для цифр.
## Встроенный текст кнопки скрыт (прозрачный font_color), рисуется только _draw.

var _cached_font_color := Color.WHITE
var _cached_outline_color := Color(0, 0, 0, 0)
var _cached_outline_size := 0


func _activate_mixed_draw() -> void:
	_cache_draw_colors()
	_hide_builtin_text()
	queue_redraw()


func _enter_tree() -> void:
	_activate_mixed_draw()


func _game_fonts_refresh() -> void:
	_activate_mixed_draw()


func _cache_draw_colors() -> void:
	_cached_font_color = get_theme_color("font_color")
	_cached_outline_color = get_theme_color("font_outline_color")
	_cached_outline_size = get_theme_constant("outline_size")


func _hide_builtin_text() -> void:
	add_theme_color_override("font_color", Color(1, 1, 1, 0))
	add_theme_color_override("font_outline_color", Color(1, 1, 1, 0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_cache_draw_colors()
		_hide_builtin_text()
		queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var font_size := get_theme_font_size("font_size")
	var color: Color = _cached_font_color
	if is_disabled():
		color = color.lerp(Color(0.55, 0.55, 0.55), 0.45)
	var rect := Rect2(Vector2.ZERO, size)
	GameFonts.draw_mixed_string_in_rect(
		self,
		rect,
		text,
		font_size,
		color,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		_cached_outline_color,
		_cached_outline_size
	)
