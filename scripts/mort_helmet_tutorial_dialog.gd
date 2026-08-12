# Нежёсткий туториал Шлема Морта: подсветка плашки и указатель на кнопку «i».

extends Control

signal closed_pressed

var _closing := false


func setup(section_rect: Rect2, info_rect: Rect2) -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dimmer_gui_input)
	add_child(dim)
	var highlight_rect: Rect2 = section_rect.grow(8.0)
	var highlight := Panel.new()
	highlight.position = highlight_rect.position
	highlight.size = highlight_rect.size
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(1.0, 0.95, 0.45, 0.12)
	hs.set_corner_radius_all(14)
	hs.border_color = Color(1.0, 0.95, 0.45, 1.0)
	hs.border_width_left = 4
	hs.border_width_top = 4
	hs.border_width_right = 4
	hs.border_width_bottom = 4
	highlight.add_theme_stylebox_override("panel", hs)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlight)
	var arrow := Label.new()
	arrow.text = "▲"
	arrow.add_theme_font_size_override("font_size", 36)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	arrow.add_theme_color_override("font_outline_color", Color.BLACK)
	arrow.add_theme_constant_override("outline_size", 3)
	arrow.position = Vector2(info_rect.position.x + info_rect.size.x * 0.5 - 14, info_rect.position.y + info_rect.size.y + 6)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrow)
	var hint := Label.new()
	hint.text = "Это Шлем Морта. Побеждайте уровни подряд, чтобы получать бонусы. Нажмите «i», чтобы узнать подробности."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(info_rect.position.x - 280, info_rect.position.y + info_rect.size.y + 60)
	hint.size = Vector2(560, 140)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	if LevelManager:
		LevelManager.mark_mort_helmet_tutorial_shown()


func _on_dimmer_gui_input(event: InputEvent) -> void:
	if _closing:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_emit_closed()


func _emit_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
