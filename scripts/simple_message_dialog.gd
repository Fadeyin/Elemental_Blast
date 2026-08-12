# Простое модальное сообщение: заголовок, текст, одна кнопка.

extends Control

signal closed_pressed

var _closing := false


func setup(title: String, body: String, ok_text: String = "Закрыть") -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var panel := Panel.new()
	panel.name = "SimpleMessagePanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24.0
	panel.offset_top = 24.0
	panel.offset_right = -24.0
	panel.offset_bottom = -24.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.12, 0.17, 0.98)
	panel_style.set_corner_radius_all(22)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.45, 0.58, 0.82, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	title_lbl.add_theme_constant_override("outline_size", 4)
	header_row.add_child(title_lbl)
	header_row.add_child(UiCloseButton.create(_emit_closed))
	vbox.add_child(header_row)
	var body_lbl := Label.new()
	body_lbl.text = body
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.add_theme_font_size_override("font_size", 24)
	body_lbl.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
	body_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	body_lbl.add_theme_constant_override("outline_size", 3)
	vbox.add_child(body_lbl)
	var actions := CenterContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok_btn := Button.new()
	ok_btn.text = ok_text
	ok_btn.custom_minimum_size = Vector2(280, 72)
	ok_btn.add_theme_font_size_override("font_size", 26)
	ok_btn.focus_mode = Control.FOCUS_NONE
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color(0.22, 0.38, 0.52, 1.0)
	ok_style.set_corner_radius_all(16)
	ok_style.border_width_left = 3
	ok_style.border_width_top = 3
	ok_style.border_width_right = 3
	ok_style.border_width_bottom = 3
	ok_style.border_color = Color(0.45, 0.58, 0.82, 1.0)
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	ok_btn.add_theme_stylebox_override("hover", ok_style)
	ok_btn.add_theme_stylebox_override("pressed", ok_style)
	ok_btn.pressed.connect(_emit_closed)
	actions.add_child(ok_btn)
	vbox.add_child(actions)


func _emit_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
