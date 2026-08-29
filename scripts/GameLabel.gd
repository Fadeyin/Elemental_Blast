extends Label
## Label с Rubik ExtraBold для букв и Rubik Black для цифр.
## Встроенный текст Label скрыт (visible_characters = 0), рисуется только _draw.
## Поддерживает \n и autowrap_mode (как обычный Label).

var _builtin_text_hidden := false


func _activate_mixed_draw() -> void:
	if not _builtin_text_hidden:
		visible_characters = 0
		_builtin_text_hidden = true
	clip_contents = true
	queue_redraw()


func _game_fonts_refresh() -> void:
	_activate_mixed_draw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED or what == NOTIFICATION_RESIZED:
		update_minimum_size()
		queue_redraw()


func _use_heavy_digits() -> bool:
	return has_meta(&"game_fonts_heavy") and bool(get_meta("game_fonts_heavy"))


func _wrap_width() -> float:
	if size.x > 1.0:
		return size.x
	if custom_minimum_size.x > 1.0:
		return custom_minimum_size.x
	return 0.0


func _get_minimum_size() -> Vector2:
	var font_size := get_theme_font_size("font_size")
	var outline_pad := float(GameFonts.effective_outline_size(get_theme_constant("outline_size")) * 2)
	var line_spacing := float(get_theme_constant("line_spacing"))
	var use_heavy := _use_heavy_digits()
	if autowrap_mode == TextServer.AUTOWRAP_OFF:
		var single := GameFonts.measure_mixed_wrapped(
			text, font_size, 0.0, TextServer.AUTOWRAP_OFF, line_spacing, use_heavy
		)
		return Vector2(single.width + outline_pad, single.height + outline_pad)
	var wrap_w := _wrap_width()
	if wrap_w <= 1.0:
		# Пока ширина неизвестна — только явные переносы \n, ширина растягивается контейнером
		var by_newline := GameFonts.measure_mixed_wrapped(
			text, font_size, 0.0, TextServer.AUTOWRAP_OFF, line_spacing, use_heavy
		)
		return Vector2(0.0, by_newline.height + outline_pad)
	var wrapped := GameFonts.measure_mixed_wrapped(
		text, font_size, wrap_w, autowrap_mode, line_spacing, use_heavy
	)
	return Vector2(0.0, wrapped.height + outline_pad)


func _draw() -> void:
	if text.is_empty():
		return
	var font_size := get_theme_font_size("font_size")
	var color: Color = _resolved_draw_color()
	var outline_color: Color = get_theme_color("font_outline_color")
	var outline_size: int = get_theme_constant("outline_size")
	var line_spacing := float(get_theme_constant("line_spacing"))
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
		outline_size,
		_use_heavy_digits(),
		autowrap_mode,
		line_spacing
	)


func _resolved_draw_color() -> Color:
	if has_meta(&"game_fonts_draw_color"):
		return get_meta(&"game_fonts_draw_color") as Color
	return get_theme_color("font_color")
