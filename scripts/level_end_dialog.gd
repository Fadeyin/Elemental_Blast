# Полноэкранное окно итога уровня: победа, поражение или покупка ходов.
# Показывается один раз за вызов; повторное открытие блокируется в game_board.gd.

extends Control

signal buy_moves_pressed
signal to_menu_pressed

var _closing: bool = false

func setup_victory(total: int, base_reward: int, moves_bonus: int, moves_left: int) -> void:
	_build_base()
	_fill_victory(total, base_reward, moves_bonus, moves_left)

func setup_defeat_no_lives() -> void:
	_build_base()
	_fill_defeat()

func setup_buy_moves(cost: int, player_coins: int, moves_count: int, can_afford: bool) -> void:
	_build_base()
	_fill_buy_moves(cost, player_coins, moves_count, can_afford)

func _build_base() -> void:
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.75)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = -16.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.13, 0.18, 0.98)
	panel_style.set_corner_radius_all(24)
	panel_style.border_width_left = 5
	panel_style.border_width_top = 5
	panel_style.border_width_right = 5
	panel_style.border_width_bottom = 5
	panel_style.border_color = Color(0.85, 0.72, 0.28, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.55)
	panel_style.shadow_size = 28
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.name = "LevelEndPanel"
	add_child(panel)
	var margin = MarginContainer.new()
	margin.name = "LevelEndMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	vbox.name = "ContentVBox"

func _main_vbox() -> VBoxContainer:
	return get_node("LevelEndPanel/LevelEndMargin/ContentVBox") as VBoxContainer

func _fill_victory(total: int, base_reward: int, moves_bonus: int, moves_left: int) -> void:
	var vbox = _main_vbox()
	var title = Label.new()
	title.text = "ПОБЕДА!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)
	var body = Label.new()
	body.text = "Уровень пройден.\n\nНаграда:\n  Базовая: %d монет\n  За ходы: %d × 10 = %d монет\n\nВсего: %d монет" % [base_reward, moves_left, moves_bonus, total]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 32)
	body.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	body.add_theme_constant_override("outline_size", 5)
	vbox.add_child(body)
	vbox.add_child(_spacer())
	vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _fill_defeat() -> void:
	var vbox = _main_vbox()
	var title = Label.new()
	title.text = "ПОРАЖЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	vbox.add_child(title)
	var body = Label.new()
	body.text = "Жизни закончились.\nПопробуйте пройти уровень снова!"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 32)
	body.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	body.add_theme_constant_override("outline_size", 5)
	vbox.add_child(body)
	vbox.add_child(_spacer())
	vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _fill_buy_moves(cost: int, player_coins: int, moves_count: int, can_afford: bool) -> void:
	var vbox = _main_vbox()
	var title = Label.new()
	title.text = "ХОДЫ ЗАКОНЧИЛИСЬ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 7)
	vbox.add_child(title)
	var body = Label.new()
	if can_afford:
		body.text = "Купить ещё %d ходов за %d монет?\n\nУ вас: %d монет" % [moves_count, cost, player_coins]
	else:
		body.text = "Недостаточно монет.\nНужно: %d монет\nУ вас: %d монет" % [cost, player_coins]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 32)
	body.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	body.add_theme_constant_override("outline_size", 5)
	vbox.add_child(body)
	vbox.add_child(_spacer())
	if can_afford:
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		row.add_child(_big_button("КУПИТЬ (%d)" % cost, _on_buy_moves, Color(0.22, 0.58, 0.32), Color(0.35, 0.75, 0.42)))
		row.add_child(_big_button("ВЫЙТИ", _on_to_menu, Color(0.45, 0.22, 0.22), Color(0.65, 0.35, 0.35)))
		var wrap = CenterContainer.new()
		wrap.add_child(row)
		vbox.add_child(wrap)
	else:
		vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _spacer() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 12)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c

func _big_button(text: String, on_press: Callable, bg: Color, border: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 96)
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 6)
	btn.focus_mode = Control.FOCUS_NONE
	var st = StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(18)
	st.border_width_left = 4
	st.border_width_top = 4
	st.border_width_right = 4
	st.border_width_bottom = 4
	st.border_color = border
	var st_h = st.duplicate()
	st_h.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st)
	btn.pressed.connect(func():
		if not _closing and not is_queued_for_deletion():
			on_press.call()
	)
	return btn

func _wrap_big_button(text: String, on_press: Callable) -> CenterContainer:
	var wrap = CenterContainer.new()
	wrap.add_child(_big_button(text, on_press, Color(0.25, 0.38, 0.62), Color(0.45, 0.6, 0.9)))
	return wrap

func _on_to_menu() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("to_menu_pressed")

func _on_buy_moves() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("buy_moves_pressed")
