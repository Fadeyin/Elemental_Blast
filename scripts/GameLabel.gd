extends Label
## Label с Rubik ExtraBold для букв и Rubik Black для цифр.
## Встроенный текст Label скрыт (visible_characters = 0), рисуется только _draw.

var _builtin_text_hidden := false


func _activate_mixed_draw() -> void:
	if not _builtin_text_hidden:
		visible_characters = 0
		_builtin_text_hidden = true
	queue_redraw()


func _game_fonts_refresh() -> void:
	_activate_mixed_draw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var font_size := get_theme_font_size("font_size")
	var color: Color = get_theme_color("font_color")
	var outline_color: Color = get_theme_color("font_outline_color")
	var outline_size: int = get_theme_constant("outline_size")
	var rect := Rect2(Vector2.ZERO, size)
	GameFonts.draw_mixed_string_in_rect(
		self,
		rect,
		text,
		font_size,
		color,
		horizontal_alignment,
		vertical_alignment,
		outline_color,
		outline_size
	)
