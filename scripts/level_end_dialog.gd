# Полноэкранное окно итога уровня: победа или поражение.
# Показывается один раз за вызов; повторное открытие блокируется в game_board.gd.

extends Control

const CONFETTI_OVERLAY_SCRIPT := preload("res://scripts/level_end_confetti_overlay.gd")
const FIREWORKS_OVERLAY_SCRIPT := preload("res://scripts/level_end_fireworks_overlay.gd")
const DIALOG_WIDTH := 460.0
const ACTION_BUTTON_WIDTH := 280.0

signal to_menu_pressed
signal refill_lives_pressed

var _closing: bool = false

func setup_victory(total: int, base_reward: int, chips_bonus: int, bonus_chips_count: int, coins_per_bonus_chip: int) -> void:
	_build_base()
	_fill_victory(total, base_reward, chips_bonus, bonus_chips_count, coins_per_bonus_chip)
	_play_open_animations(true)

func setup_defeat_no_lives(refill_cost: int, player_coins: int, hearts_to_restore: int, can_refill: bool) -> void:
	_build_base()
	_fill_defeat(refill_cost, player_coins, hearts_to_restore, can_refill)
	_play_open_animations(false)

func _build_base() -> void:
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg = UiDialogStyles.create_dimmer()
	bg.name = "LevelEndDimmer"
	add_child(bg)
	var center = UiDialogStyles.create_level_end_dialog_center()
	center.name = "LevelEndCenter"
	add_child(center)
	var panel = UiDialogStyles.create_dialog_panel(DIALOG_WIDTH)
	panel.name = "LevelEndPanel"
	center.add_child(panel)
	var margin = MarginContainer.new()
	margin.name = "LevelEndMargin"
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	vbox.name = "ContentVBox"

func _main_vbox() -> VBoxContainer:
	return get_node("LevelEndCenter/LevelEndPanel/LevelEndMargin/ContentVBox") as VBoxContainer

func _fill_victory(total: int, base_reward: int, chips_bonus: int, bonus_chips_count: int, coins_per_bonus_chip: int) -> void:
	var vbox = _main_vbox()
	var title = UiDialogStyles.create_accent_title_label("ПОБЕДА!", Color(1.0, 0.92, 0.35), 38)
	title.name = "TitleLabel"
	vbox.add_child(title)
	var body = UiDialogStyles.create_body_label(
		"Уровень пройден.\n\nНаграда:\n  Базовая: %d монет\n  За бонусные фишки: %d × %d = %d\n\nВсего: %d монет" % [base_reward, bonus_chips_count, coins_per_bonus_chip, chips_bonus, total],
		19
	)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	vbox.add_child(body)
	_append_mort_helmet_progress_panel(vbox)
	vbox.add_child(_spacer())
	vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _append_mort_helmet_progress_panel(vbox: VBoxContainer) -> void:
	if not LevelManager:
		return
	var stage_before: int = int(LevelManager.get_meta("mort_helmet_stage_before", -1)) if LevelManager.has_meta("mort_helmet_stage_before") else -1
	var unlocked_now: bool = bool(LevelManager.get_meta("mort_helmet_unlocked_now", false)) if LevelManager.has_meta("mort_helmet_unlocked_now") else false
	var stage_after: int = LevelManager.get_mort_helmet_level()
	if stage_before < 0:
		return
	var panel := PanelContainer.new()
	panel.name = "MortHelmetProgressPanel"
	UiDialogStyles.apply_section(panel)
	vbox.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)
	var lbl := UiDialogStyles.create_accent_title_label("", Color(1.0, 0.92, 0.4), 20)
	if unlocked_now:
		lbl.text = "ШЛЕМ МОРТА ОТКРЫТ!"
	elif stage_after > stage_before:
		lbl.text = "ШЛЕМ МОРТА: %d → %d" % [stage_before, stage_after]
	else:
		return
	inner.add_child(lbl)
	var hint := UiDialogStyles.create_body_label("", 16)
	var bonuses: Dictionary = LevelManager.get_mort_helmet_bonus_chips()
	var arrows: int = int(bonuses.get("arrow", 0))
	var bombs: int = int(bonuses.get("bomb", 0))
	hint.text = "На следующем уровне: %d стрел + %d бомб" % [arrows, bombs]
	inner.add_child(hint)
	call_deferred("_play_mort_helmet_panel_enter", panel)

func _play_mort_helmet_panel_enter(panel: PanelContainer) -> void:
	if not is_instance_valid(panel):
		return
	UiDialogAnima.play_pop_in(panel, 0.9, 0.12)

func _play_open_animations(is_victory: bool) -> void:
	var dimmer := get_node_or_null("LevelEndDimmer") as CanvasItem
	var panel := find_child("LevelEndPanel", true, false) as Control
	if dimmer != null and panel != null:
		UiDialogAnima.play_dialog_open(dimmer, panel)
	var title := _main_vbox().get_node_or_null("TitleLabel") as Control
	if title != null:
		if is_victory:
			UiDialogAnima.play_victory_title(title)
			_spawn_victory_effects()
			call_deferred("_play_victory_panel_shake")
		else:
			UiDialogAnima.play_defeat_title(title)
			_spawn_defeat_effects()
			call_deferred("_play_defeat_panel_shake")


func _spawn_victory_effects() -> void:
	_spawn_fireworks(false)
	_spawn_confetti()


func _spawn_defeat_effects() -> void:
	_spawn_fireworks(true)


func _spawn_fireworks(muted: bool) -> void:
	if get_node_or_null("LevelEndFireworks") != null:
		return
	var fireworks := Control.new()
	fireworks.name = "LevelEndFireworks"
	fireworks.set_script(FIREWORKS_OVERLAY_SCRIPT)
	fireworks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if fireworks.has_method("setup"):
		fireworks.setup(muted)
	add_child(fireworks)
	move_child(fireworks, 1)


func _spawn_confetti() -> void:
	if get_node_or_null("LevelEndConfetti") != null:
		return
	var confetti := Control.new()
	confetti.name = "LevelEndConfetti"
	confetti.set_script(CONFETTI_OVERLAY_SCRIPT)
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(confetti)
	move_child(confetti, 2)


func _play_victory_panel_shake() -> void:
	var panel := find_child("LevelEndPanel", true, false) as Control
	if panel != null:
		UiDialogAnima.play_victory_celebration(panel)


func _play_defeat_panel_shake() -> void:
	var panel := find_child("LevelEndPanel", true, false) as Control
	if panel != null:
		UiDialogAnima.play_panel_shake(panel, 6.0, 0.28)

func _fill_defeat(refill_cost: int, player_coins: int, hearts_to_restore: int, can_refill: bool) -> void:
	var vbox = _main_vbox()
	var title = UiDialogStyles.create_accent_title_label("ПОРАЖЕНИЕ", Color(1.0, 0.45, 0.4), 38)
	title.name = "TitleLabel"
	vbox.add_child(title)
	var body = UiDialogStyles.create_body_label("", 19)
	if can_refill:
		body.text = "Жизни закончились.\n\nЗа %d монет — %d жизней и отступ монстров на 3 клетки.\n\nУ вас: %d монет" % [refill_cost, hearts_to_restore, player_coins]
	else:
		body.text = "Жизни закончились.\n\nНужно %d монет (%d жизней).\nУ вас: %d монет\n\nВернитесь в меню." % [refill_cost, hearts_to_restore, player_coins]
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	vbox.add_child(body)
	vbox.add_child(_spacer())
	if can_refill:
		var actions = VBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(_wrap_big_button("ВОССТАНОВИТЬ (%d)" % refill_cost, _on_refill_lives, true))
		actions.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu, false))
		vbox.add_child(actions)
	else:
		vbox.add_child(_wrap_big_button("В МЕНЮ", _on_to_menu))

func _spacer() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 4)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c

func _wrap_big_button(text: String, on_press: Callable, is_primary: bool = true) -> CenterContainer:
	var wrap := CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn: UiTexturedButton
	if is_primary:
		btn = UiDialogStyles.create_primary_button(text, ACTION_BUTTON_WIDTH)
	else:
		btn = UiDialogStyles.create_secondary_button(text, ACTION_BUTTON_WIDTH)
	btn.set_font_size(20)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		if not _closing and not is_queued_for_deletion():
			on_press.call()
	)
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
