# Полноэкранное окно итога уровня: победа или поражение.
# Показывается один раз за вызов; повторное открытие блокируется в game_board.gd.

extends Control

signal to_menu_pressed
signal refill_lives_pressed

var _closing: bool = false

func setup_victory(total: int, base_reward: int, chips_bonus: int, bonus_chips_count: int, coins_per_bonus_chip: int) -> void:
	_build_base()
	_fill_victory(total, base_reward, chips_bonus, bonus_chips_count, coins_per_bonus_chip)

func setup_defeat_no_lives(refill_cost: int, player_coins: int, hearts_to_restore: int, can_refill: bool) -> void:
	_build_base()
	_fill_defeat(refill_cost, player_coins, hearts_to_restore, can_refill)

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

func _fill_victory(total: int, base_reward: int, chips_bonus: int, bonus_chips_count: int, coins_per_bonus_chip: int) -> void:
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
	body.text = "Уровень пройден.\n\nНаграда:\n  Базовая: %d монет\n  За бонусные фишки на поле: %d × %d = %d монет\n\nВсего: %d монет" % [base_reward, bonus_chips_count, coins_per_bonus_chip, chips_bonus, total]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	body.add_theme_font_size_override("font_size", 26)
	body.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	body.add_theme_constant_override("outline_size", 4)
	vbox.add_child(body)
	_append_mort_helmet_progress_panel(vbox)
	vbox.add_child(_spacer())
	vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _append_mort_helmet_progress_panel(vbox: VBoxContainer) -> void:
	# GDD §7: на экране победы показываем открытие/повышение стадии Шлема Морта.
	if not LevelManager:
		return
	var stage_before: int = int(LevelManager.get_meta("mort_helmet_stage_before", -1)) if LevelManager.has_meta("mort_helmet_stage_before") else -1
	var unlocked_now: bool = bool(LevelManager.get_meta("mort_helmet_unlocked_now", false)) if LevelManager.has_meta("mort_helmet_unlocked_now") else false
	var stage_after: int = LevelManager.get_mort_helmet_level()
	if stage_before < 0:
		return
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.18, 0.16, 0.28, 0.85)
	ps.set_corner_radius_all(12)
	ps.border_width_left = 3
	ps.border_width_top = 3
	ps.border_width_right = 3
	ps.border_width_bottom = 3
	ps.border_color = Color(0.85, 0.72, 0.28, 1.0)
	panel.add_theme_stylebox_override("panel", ps)
	vbox.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if unlocked_now:
		lbl.text = "ШЛЕМ МОРТА ОТКРЫТ!"
	elif stage_after > stage_before:
		lbl.text = "ШЛЕМ МОРТА: СТАДИЯ %d → %d" % [stage_before, stage_after]
	else:
		# На стадии 3 не показываем рост, по GDD это допустимо.
		return
	inner.add_child(lbl)
	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.95, 0.9, 0.95))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.clip_contents = true
	var bonuses: Dictionary = LevelManager.get_mort_helmet_bonus_chips()
	var arrows: int = int(bonuses.get("arrow", 0))
	var bombs: int = int(bonuses.get("bomb", 0))
	hint.text = "На старте следующего уровня: %d стрел + %d бомб" % [arrows, bombs]
	inner.add_child(hint)
	# Анимация: лёгкое всплытие/масштабирование.
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	panel.pivot_offset = Vector2(panel.custom_minimum_size.x * 0.5, panel.custom_minimum_size.y * 0.5)
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fill_defeat(refill_cost: int, player_coins: int, hearts_to_restore: int, can_refill: bool) -> void:
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
	if can_refill:
		body.text = "Жизни закончились.\n\nЗа %d монет восстановить %d жизней на шкале и отодвинуть всех монстров на три клетки назад.\n\nУ вас: %d монет" % [refill_cost, hearts_to_restore, player_coins]
	else:
		body.text = "Жизни закончились.\n\nДля следующего восстановления нужно %d монет (%d жизней).\nУ вас: %d монет\n\nВернитесь в меню или попробуйте снова." % [refill_cost, hearts_to_restore, player_coins]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	body.add_theme_font_size_override("font_size", 26)
	body.add_theme_color_override("font_color", Color(0.92, 0.92, 0.95))
	body.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	body.add_theme_constant_override("outline_size", 4)
	vbox.add_child(body)
	vbox.add_child(_spacer())
	if can_refill:
		var actions = VBoxContainer.new()
		actions.add_theme_constant_override("separation", 14)
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(_big_button("ВОССТАНОВИТЬ (%d)" % refill_cost, _on_refill_lives, Color(0.22, 0.48, 0.58), Color(0.35, 0.65, 0.78)))
		actions.add_child(_big_button("В МЕНЮ", _on_to_menu, Color(0.45, 0.22, 0.22), Color(0.65, 0.35, 0.35)))
		vbox.add_child(actions)
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
	btn.custom_minimum_size = Vector2(0, 88)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_text = true
	btn.clip_contents = true
	btn.add_theme_font_size_override("font_size", 28)
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
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn := _big_button(text, on_press, Color(0.25, 0.38, 0.62), Color(0.45, 0.6, 0.9))
	btn.custom_minimum_size = Vector2(320, 88)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrap.add_child(btn)
	return wrap

func _on_to_menu() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("to_menu_pressed")

func _on_refill_lives() -> void:
	if _closing:
		return
	_closing = true
	emit_signal("refill_lives_pressed")
