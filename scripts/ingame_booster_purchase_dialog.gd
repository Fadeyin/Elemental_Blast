# Окно покупки бустера на игровом поле, когда запас закончился.

extends Control

signal purchase_pressed
signal closed_pressed

var _closing: bool = false

func setup(display_name: String, icon, cost: int, quantity: int, player_coins: int, can_afford: bool, header_title: String = "БУСТЕР ЗАКОНЧИЛСЯ") -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg = UiDialogStyles.create_dimmer()
	add_child(bg)
	var center := UiDialogStyles.create_dialog_center()
	add_child(center)
	var panel = UiDialogStyles.create_dialog_panel(UiDialogStyles.MEDIUM_DIALOG_WIDTH)
	panel.name = "BoosterShopPanel"
	center.add_child(panel)
	var margin = MarginContainer.new()
	margin.name = "BoosterShopMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.name = "BoosterShopVBox"
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	var title := UiDialogStyles.create_accent_title_label(header_title, UiDialogStyles.ACCENT_COLOR, 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_contents = true
	header_row.add_child(title)
	header_row.add_child(UiCloseButton.create(_emit_closed))
	vbox.add_child(header_row)
	if icon != null:
		var icon_wrap = CenterContainer.new()
		var tr = TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(96, 96)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_wrap.add_child(tr)
		vbox.add_child(icon_wrap)
	var name_lbl = UiDialogStyles.create_title_label(display_name, 28)
	name_lbl.clip_contents = true
	vbox.add_child(name_lbl)
	var body = UiDialogStyles.create_body_label("", 20)
	if can_afford:
		if quantity > 1:
			body.text = "Купить %d шт. за %d монет?\n\nУ вас: %d монет" % [quantity, cost, player_coins]
		else:
			body.text = "Купить 1 шт. за %d монет?\n\nУ вас: %d монет" % [cost, player_coins]
	else:
		if quantity > 1:
			body.text = "Недостаточно монет.\nПакет: %d шт. за %d монет\nУ вас: %d монет" % [quantity, cost, player_coins]
		else:
			body.text = "Недостаточно монет.\nЦена: %d монет\nУ вас: %d монет" % [cost, player_coins]
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	vbox.add_child(body)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)
	var btn_width := 260.0
	if can_afford:
		var actions = VBoxContainer.new()
		actions.add_theme_constant_override("separation", 10)
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(_make_big_button("КУПИТЬ (%d)" % cost, _emit_purchase, true, btn_width))
		actions.add_child(_make_big_button("ОТМЕНА", _emit_closed, false, btn_width))
		vbox.add_child(actions)
	else:
		var wrap = CenterContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var close_btn := _make_big_button("ЗАКРЫТЬ", _emit_closed, false, btn_width)
		wrap.add_child(close_btn)
		vbox.add_child(wrap)

func _make_big_button(text: String, callback: Callable, is_primary: bool, width: float) -> Button:
	var btn: Button
	if is_primary:
		btn = UiDialogStyles.create_primary_button(text, width)
	else:
		btn = UiDialogStyles.create_secondary_button(text, width)
	btn.add_theme_font_size_override("font_size", 20)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		if not _closing and not is_queued_for_deletion():
			callback.call()
	)
	return btn

func _emit_purchase() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("purchase_pressed")

func _emit_closed() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("closed_pressed")
