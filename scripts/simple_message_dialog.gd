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
	var bg := UiDialogStyles.create_dimmer()
	add_child(bg)
	var center := UiDialogStyles.create_dialog_center()
	add_child(center)
	var panel := UiDialogStyles.create_dialog_panel(UiDialogStyles.COMPACT_DIALOG_WIDTH)
	panel.name = "SimpleMessagePanel"
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	var title_lbl := UiDialogStyles.create_title_label(title, 28)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_lbl)
	header_row.add_child(UiCloseButton.create(_emit_closed))
	vbox.add_child(header_row)
	var body_lbl := UiDialogStyles.create_body_label(body, 20)
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(body_lbl)
	var actions := CenterContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok_btn := UiDialogStyles.create_primary_button(ok_text, 240.0)
	ok_btn.add_theme_font_size_override("font_size", 22)
	ok_btn.focus_mode = Control.FOCUS_NONE
	ok_btn.pressed.connect(_emit_closed)
	actions.add_child(ok_btn)
	vbox.add_child(actions)


func _emit_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
