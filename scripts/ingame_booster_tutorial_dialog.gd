# Подсветка кнопки внутриуровневого бустера и текст подсказки.

extends Control

signal closed_pressed

var _closing := false


func setup(highlight_global_rect: Rect2, hint_text: String) -> void:
	_closing = false
	await get_tree().process_frame
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
	var local_rect: Rect2 = _global_rect_to_local(highlight_global_rect.grow(8.0))
	var highlight := Panel.new()
	highlight.position = local_rect.position
	highlight.size = local_rect.size
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
	var hint := Label.new()
	hint.text = hint_text
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hw: float = minf(maxf(size.x - 40.0, 160.0), 560.0)
	hint.custom_minimum_size = Vector2(hw, 0)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.clip_contents = true
	var hint_h: float = GameFonts.measure_mixed_wrapped(
		hint.text, 22, hw, TextServer.AUTOWRAP_WORD_SMART, 0.0
	).height + 12.0
	var hint_x: float = size.x * 0.5 - hw * 0.5
	var hint_y: float = maxf(16.0, local_rect.position.y - maxf(hint_h + 24.0, 150.0))
	hint.position = Vector2(hint_x, hint_y)
	hint.size = Vector2(hw, hint_h)
	add_child(hint)


func _global_rect_to_local(global_rect: Rect2) -> Rect2:
	var inv: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var p0: Vector2 = inv * global_rect.position
	var p1: Vector2 = inv * (global_rect.position + global_rect.size)
	return Rect2(p0, p1 - p0)


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
