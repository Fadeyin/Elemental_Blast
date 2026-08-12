# Окно правил Шлема Морта: стадии наград и подсказка о сбросе серии.

extends Control

signal closed_pressed

var _closing := false


func setup() -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_dimmer_gui_input)
	add_child(bg)
	var panel := Panel.new()
	panel.name = "MortHelmetRulesPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -240
	panel.offset_bottom = 240
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.12, 0.15, 0.2, 0.98)
	ps.set_corner_radius_all(18)
	ps.border_width_left = 4
	ps.border_width_top = 4
	ps.border_width_right = 4
	ps.border_width_bottom = 4
	ps.border_color = Color(0.85, 0.72, 0.28, 1.0)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 20
	box.offset_top = 20
	box.offset_right = -20
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := Label.new()
	title.text = "ШЛЕМ МОРТА"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var desc := Label.new()
	desc.text = "Побеждайте уровни подряд — стадия Шлема будет расти, а на старт следующего уровня вы получите больше бонусов на поле."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.clip_contents = true
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(desc)
	for stage_data in [
		{"stage": 1, "text": "1 победа подряд → 1 стрела + 1 бомба"},
		{"stage": 2, "text": "2 победы подряд → 2 стрелы + 2 бомбы"},
		{"stage": 3, "text": "3+ побед подряд → 3 стрелы + 3 бомбы"},
	]:
		var row := Label.new()
		row.text = stage_data["text"]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.clip_contents = true
		row.add_theme_font_size_override("font_size", 20)
		row.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
		row.add_theme_color_override("font_outline_color", Color.BLACK)
		row.add_theme_constant_override("outline_size", 3)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(row)
	var hint := Label.new()
	hint.text = "Поражение или выход после хода сбрасывают серию."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.clip_contents = true
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.85, 0.65, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var close_btn := Button.new()
	close_btn.text = "ПОНЯТНО"
	close_btn.custom_minimum_size = Vector2(220, 64)
	close_btn.focus_mode = Control.FOCUS_NONE
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.25, 0.5, 0.3, 1.0)
	cs.set_corner_radius_all(12)
	cs.border_color = Color(0.4, 0.8, 0.5, 1.0)
	cs.border_width_left = 3
	cs.border_width_top = 3
	cs.border_width_right = 3
	cs.border_width_bottom = 3
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(_emit_closed)
	var wrap := CenterContainer.new()
	wrap.add_child(close_btn)
	box.add_child(wrap)
	if get_child_count() >= 2:
		UiDialogAnima.play_dialog_open(bg, panel)


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
