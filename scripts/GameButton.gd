extends Button
## Кнопка с Rubik ExtraBold для букв и Rubik Black для цифр.


func _game_fonts_refresh() -> void:
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var font_size := get_theme_font_size("font_size")
	var color: Color = get_theme_color("font_color")
	if is_disabled():
		color = color.lerp(Color(0.55, 0.55, 0.55), 0.45)
	var outline_color: Color = get_theme_color("font_outline_color")
	var outline_size: int = get_theme_constant("outline_size")
	var rect := Rect2(Vector2.ZERO, size)
	GameFonts.draw_mixed_string_in_rect(
		self,
		rect,
		text,
		font_size,
		color,
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		outline_color,
		outline_size
	)
