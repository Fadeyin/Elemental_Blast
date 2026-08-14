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
	var bg := UiDialogStyles.create_dimmer()
	bg.gui_input.connect(_on_dimmer_gui_input)
	add_child(bg)
	var center := UiDialogStyles.create_dialog_center()
	add_child(center)
	var panel := UiDialogStyles.create_dialog_panel(480.0)
	panel.name = "MortHelmetRulesPanel"
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(box)
	panel.add_child(margin)
	var title := UiDialogStyles.create_accent_title_label("ШЛЕМ МОРТА", UiDialogStyles.ACCENT_COLOR, 28)
	box.add_child(title)
	var desc := UiDialogStyles.create_body_label(
		"Побеждайте уровни подряд — стадия Шлема будет расти, а на старт следующего уровня вы получите больше бонусов на поле.",
		18
	)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.clip_contents = true
	box.add_child(desc)
	for stage_data in [
		{"stage": 1, "text": "1 победа подряд → 1 стрела + 1 бомба"},
		{"stage": 2, "text": "2 победы подряд → 2 стрелы + 2 бомбы"},
		{"stage": 3, "text": "3+ побед подряд → 3 стрелы + 3 бомбы"},
	]:
		var row := UiDialogStyles.create_body_label(stage_data["text"], 18)
		row.add_theme_color_override("font_color", Color(0.78, 0.42, 0.12, 1.0))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.clip_contents = true
		box.add_child(row)
	var hint := UiDialogStyles.create_muted_label("Поражение или выход после хода сбрасывают серию.", 16)
	hint.add_theme_color_override("font_color", Color(0.72, 0.38, 0.32, 1.0))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.clip_contents = true
	box.add_child(hint)
	var close_btn := UiDialogStyles.create_primary_button("ПОНЯТНО", 220.0)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.focus_mode = Control.FOCUS_NONE
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
