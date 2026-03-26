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
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.72)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var panel = Panel.new()
	panel.name = "BoosterShopPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 20.0
	panel.offset_top = 20.0
	panel.offset_right = -20.0
	panel.offset_bottom = -20.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.12, 0.17, 0.98)
	panel_style.set_corner_radius_all(22)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.82, 0.68, 0.26, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var margin = MarginContainer.new()
	margin.name = "BoosterShopMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.name = "BoosterShopVBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	var title = Label.new()
	title.text = header_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 7)
	vbox.add_child(title)
	if icon != null:
		var icon_wrap = CenterContainer.new()
		var tr = TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(112, 112)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_wrap.add_child(tr)
		vbox.add_child(icon_wrap)
	var name_lbl = Label.new()
	name_lbl.text = display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	name_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(name_lbl)
	var body = Label.new()
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
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 30)
	body.add_theme_color_override("font_color", Color(0.92, 0.93, 0.96))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	body.add_theme_constant_override("outline_size", 4)
	vbox.add_child(body)
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)
	if can_afford:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 20)
		row.add_child(_make_big_button("КУПИТЬ (%d)" % cost, _emit_purchase, Color(0.22, 0.55, 0.3), Color(0.38, 0.78, 0.45)))
		row.add_child(_make_big_button("ОТМЕНА", _emit_closed, Color(0.35, 0.28, 0.28), Color(0.55, 0.42, 0.42)))
		var row_wrap = CenterContainer.new()
		row_wrap.add_child(row)
		vbox.add_child(row_wrap)
	else:
		var wrap = CenterContainer.new()
		wrap.add_child(_make_big_button("ЗАКРЫТЬ", _emit_closed, Color(0.28, 0.36, 0.52), Color(0.45, 0.58, 0.82)))
		vbox.add_child(wrap)

func _make_big_button(text: String, callback: Callable, bg: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 88)
	btn.add_theme_font_size_override("font_size", 32)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.88))
	btn.add_theme_constant_override("outline_size", 5)
	btn.focus_mode = Control.FOCUS_NONE
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(16)
	st.border_width_left = 3
	st.border_width_top = 3
	st.border_width_right = 3
	st.border_width_bottom = 3
	st.border_color = border
	var st_h = st.duplicate()
	st_h.bg_color = bg.lightened(0.1)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st)
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
