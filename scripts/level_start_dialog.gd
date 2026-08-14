# Вспомогательный скрипт для диалога старта уровня
# Используется game_board.gd для отображения предстартового экрана

extends Control

signal start_gameplay(selected_boosts: Dictionary, mort_helmet_bonuses: Dictionary)

var _selected_prelevel_boosts := {
	"bomb": false,
	"arrow": false,
	"rainbow": false
}

# Флаг для предотвращения множественного закрытия диалога
var _dialog_closing: bool = false

const BOOSTER_PURCHASE_FLOW_PAGE_SCRIPT := preload("res://scripts/ui_flow/pages/booster_purchase_flow_page.gd")
const MORT_HELMET_RULES_FLOW_PAGE_SCRIPT := preload("res://scripts/ui_flow/pages/mort_helmet_rules_flow_page.gd")
const MORT_HELMET_TUTORIAL_FLOW_PAGE_SCRIPT := preload("res://scripts/ui_flow/pages/mort_helmet_tutorial_flow_page.gd")

var _prelevel_boosts_row: HBoxContainer = null
var _prelevel_purchase_flow_open := false
var _mort_helmet_section: Control = null
var _mort_helmet_info_button: Button = null
var _mort_helmet_rules_flow_open := false
var _mort_helmet_tutorial_flow_open := false

func setup():
	_build_dialog()
	_maybe_show_mort_helmet_tutorial()
	if WebSmokeTestBridge and WebSmokeTestBridge.is_active():
		call_deferred("_run_web_smoke_test_level_start_flow")

func _build_dialog():
	# Полупрозрачный фон (клик вне панели — закрыть без старта)
	var bg = UiDialogStyles.create_dimmer()
	bg.name = "LevelStartDimmer"
	bg.gui_input.connect(_on_dimmer_gui_input)
	add_child(bg)
	
	# Центральная панель диалога
	var panel = Panel.new()
	panel.name = "LevelStartPanel"
	panel.custom_minimum_size = Vector2(600, 700)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -350
	panel.offset_bottom = 350
	UiDialogStyles.apply_panel_style(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	
	# VBoxContainer для вертикального расположения элементов
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.offset_left = 12
	vbox.offset_right = -12
	vbox.offset_top = 12
	vbox.offset_bottom = -12
	panel.add_child(vbox)
	
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 8)
	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	var close_btn := UiCloseButton.create(func():
		if not _dialog_closing and not is_queued_for_deletion():
			_dialog_closing = true
			_on_close_pressed()
	)
	header_row.add_child(close_btn)
	vbox.add_child(header_row)
	
	# Заголовок
	var title = UiDialogStyles.create_accent_title_label(
		"УРОВЕНЬ " + str(LevelManager.current_level if LevelManager else 1),
		UiDialogStyles.ACCENT_COLOR,
		48
	)
	vbox.add_child(title)
	
	# Шлем Морта (Win Streak прогресс) — показываем только после открытия фичи (GDD §2,§7)
	if LevelManager and LevelManager.is_mort_helmet_unlocked():
		_add_mort_helmet_section(vbox)
	
	# Предуровневые усиления
	_add_prelevel_boosts_section(vbox)
	
	# Кнопка "Играть"
	var play_btn = UiDialogStyles.create_primary_button("ИГРАТЬ", 360.0)
	play_btn.name = "PlayButton"
	play_btn.add_theme_font_size_override("font_size", 36)
	play_btn.focus_mode = Control.FOCUS_NONE
	
	play_btn.pressed.connect(func():
		if not _dialog_closing and not is_queued_for_deletion():
			_dialog_closing = true
			_on_start_pressed()
	)
	
	var play_container = CenterContainer.new()
	play_container.add_child(play_btn)
	vbox.add_child(play_container)
	call_deferred("_play_open_animations")

func _play_open_animations() -> void:
	var dimmer := get_node_or_null("LevelStartDimmer") as CanvasItem
	var panel := get_node_or_null("LevelStartPanel") as Control
	if dimmer == null or panel == null:
		return
	UiDialogAnima.play_dialog_open(dimmer, panel)
	var play_btn := panel.find_child("PlayButton", true, false) as Control
	if play_btn != null:
		UiDialogAnima.play_attention_pulse(play_btn, 0.48)

func _add_mort_helmet_section(vbox: VBoxContainer):
	if not LevelManager:
		return
	
	var helmet_level: int = LevelManager.mort_helmet_level
	
	# Контейнер всей секции — нужен, чтобы туториал мог подсветить именно её.
	var section := PanelContainer.new()
	UiDialogStyles.apply_section(section)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(section)
	_mort_helmet_section = section
	
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(inner)
	
	# Шапка с заголовком и кнопкой "i"
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(header_row)
	
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(left_spacer)
	
	var helmet_title := UiDialogStyles.create_title_label("ШЛЕМ МОРТА", 32)
	helmet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(helmet_title)
	
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(right_spacer)
	
	var info_btn := UiDialogStyles.create_round_info_button("i", 44.0)
	info_btn.focus_mode = Control.FOCUS_NONE
	info_btn.pressed.connect(_show_mort_helmet_rules)
	header_row.add_child(info_btn)
	_mort_helmet_info_button = info_btn
	
	# Визуальное отображение уровня шлема (3 этапа)
	var helmet_progress := HBoxContainer.new()
	helmet_progress.alignment = BoxContainer.ALIGNMENT_CENTER
	helmet_progress.add_theme_constant_override("separation", 15)
	
	for i in range(1, 4):
		var stage := PanelContainer.new()
		stage.custom_minimum_size = Vector2(60, 60)
		if i <= helmet_level:
			stage.add_theme_stylebox_override("panel", UiDialogStyles.make_slot_pressed_stylebox())
		else:
			stage.add_theme_stylebox_override("panel", UiDialogStyles.make_slot_disabled_stylebox())
		
		var stage_label := Label.new()
		stage_label.text = str(i)
		stage_label.add_theme_font_size_override("font_size", 28)
		stage_label.add_theme_color_override("font_color", Color.WHITE if i <= helmet_level else Color(0.6, 0.6, 0.6))
		stage_label.add_theme_color_override("font_outline_color", Color.BLACK)
		stage_label.add_theme_constant_override("outline_size", 3)
		stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stage_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stage.add_child(stage_label)
		
		helmet_progress.add_child(stage)
	inner.add_child(helmet_progress)
	
	# Описание текущего бонуса (на стадии 0 — поясняем как получить бонусы)
	var bonus_chips: Dictionary = LevelManager.get_mort_helmet_bonus_chips()
	var bonus_desc := Label.new()
	bonus_desc.add_theme_font_size_override("font_size", 20)
	bonus_desc.add_theme_color_override("font_outline_color", Color.BLACK)
	bonus_desc.add_theme_constant_override("outline_size", 3)
	bonus_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus_desc.clip_contents = true
	if not bonus_chips.is_empty():
		var arrow_count: int = int(bonus_chips.get("arrow", 0))
		var bomb_count: int = int(bonus_chips.get("bomb", 0))
		bonus_desc.text = "Бонус: %d %s + %d %s" % [arrow_count, _decline_arrows(arrow_count), bomb_count, _decline_bombs(bomb_count)]
		bonus_desc.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		bonus_desc.text = "Победите уровень, чтобы получить бонусы Шлема"
		bonus_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	inner.add_child(bonus_desc)

func _decline_arrows(n: int) -> String:
	# Грубое русское склонение для UI: 1 стрела / 2-4 стрелы / 5+ стрел.
	var mod_100 := n % 100
	var mod_10 := n % 10
	if mod_100 >= 11 and mod_100 <= 14:
		return "стрел"
	if mod_10 == 1:
		return "стрела"
	if mod_10 >= 2 and mod_10 <= 4:
		return "стрелы"
	return "стрел"

func _decline_bombs(n: int) -> String:
	var mod_100 := n % 100
	var mod_10 := n % 10
	if mod_100 >= 11 and mod_100 <= 14:
		return "бомб"
	if mod_10 == 1:
		return "бомба"
	if mod_10 >= 2 and mod_10 <= 4:
		return "бомбы"
	return "бомб"

func _show_mort_helmet_rules() -> void:
	if _mort_helmet_rules_flow_open or UIFlow.has_page(MORT_HELMET_RULES_FLOW_PAGE_SCRIPT):
		return
	if LevelManager:
		LevelManager.log_mort_helmet_rules_opened()
	_mort_helmet_rules_flow_open = true
	var page: MortHelmetRulesFlowPage = MORT_HELMET_RULES_FLOW_PAGE_SCRIPT.new()
	page.closed_pressed.connect(func() -> void:
		_mort_helmet_rules_flow_open = false
	)
	UIFlow.push_instance(page, {})

func _maybe_show_mort_helmet_tutorial() -> void:
	# GDD §8: при первом открытии фичи показывается короткий нежесткий туториал.
	if not LevelManager:
		return
	if not LevelManager.is_mort_helmet_unlocked():
		return
	if LevelManager.is_mort_helmet_tutorial_shown():
		return
	if _mort_helmet_section == null or not is_instance_valid(_mort_helmet_section):
		return
	if _mort_helmet_info_button == null or not is_instance_valid(_mort_helmet_info_button):
		return
	# Запускаем после раскладки, чтобы получить корректные глобальные прямоугольники.
	call_deferred("_push_mort_helmet_tutorial_flow")

func _push_mort_helmet_tutorial_flow() -> void:
	if _mort_helmet_section == null or not is_instance_valid(_mort_helmet_section):
		return
	if _mort_helmet_info_button == null or not is_instance_valid(_mort_helmet_info_button):
		return
	if _mort_helmet_tutorial_flow_open or UIFlow.has_page(MORT_HELMET_TUTORIAL_FLOW_PAGE_SCRIPT):
		return
	var section_rect: Rect2 = _mort_helmet_section.get_global_rect()
	var info_rect: Rect2 = _mort_helmet_info_button.get_global_rect()
	_mort_helmet_tutorial_flow_open = true
	var page: MortHelmetTutorialFlowPage = MORT_HELMET_TUTORIAL_FLOW_PAGE_SCRIPT.new()
	page.closed_pressed.connect(func() -> void:
		_mort_helmet_tutorial_flow_open = false
	)
	UIFlow.push_instance(page, {
		"section_rect": section_rect,
		"info_rect": info_rect,
	})

func _add_prelevel_boosts_section(vbox: VBoxContainer):
	if not LevelManager:
		return
	var boosts_title = UiDialogStyles.create_title_label("ПРЕДУРОВНЕВЫЕ УСИЛЕНИЯ", 26)
	boosts_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boosts_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	boosts_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boosts_title.clip_contents = true
	vbox.add_child(boosts_title)
	_prelevel_boosts_row = HBoxContainer.new()
	_prelevel_boosts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_prelevel_boosts_row.add_theme_constant_override("separation", 30)
	vbox.add_child(_prelevel_boosts_row)
	_populate_prelevel_boosts_row()

func _clear_container_children_immediate(container: Node) -> void:
	var n := container.get_child_count()
	for i in range(n - 1, -1, -1):
		var ch = container.get_child(i)
		container.remove_child(ch)
		ch.free()

func _populate_prelevel_boosts_row() -> void:
	if not LevelManager or _prelevel_boosts_row == null or not is_instance_valid(_prelevel_boosts_row):
		return
	_clear_container_children_immediate(_prelevel_boosts_row)
	var boost_types: Array[String] = ["bomb", "arrow", "rainbow"]
	var boost_names := {"bomb": "Бомба", "arrow": "Стрела", "rainbow": "Шар"}
	var slot_size := Vector2(100, 100)
	for boost_type in boost_types:
		var boost_count: int = LevelManager.get_prelevel_boost_count(boost_type)
		var boost_vbox = VBoxContainer.new()
		boost_vbox.add_theme_constant_override("separation", 8)
		boost_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		var slot = Control.new()
		slot.custom_minimum_size = slot_size
		var boost_btn = Button.new()
		boost_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		boost_btn.toggle_mode = true
		boost_btn.disabled = (boost_count <= 0)
		var texture = LevelManager.get_prelevel_boost_texture(boost_type)
		if texture:
			boost_btn.icon = texture
			boost_btn.expand_icon = true
		if boost_count > 0:
			boost_btn.add_theme_stylebox_override("normal", UiDialogStyles.make_slot_stylebox())
		else:
			boost_btn.add_theme_stylebox_override("normal", UiDialogStyles.make_slot_disabled_stylebox())
		boost_btn.add_theme_stylebox_override("pressed", UiDialogStyles.make_slot_pressed_stylebox())
		boost_btn.focus_mode = Control.FOCUS_NONE
		var captured_type: String = boost_type
		boost_btn.toggled.connect(func(pressed: bool):
			if pressed:
				if LevelManager.use_prelevel_boost(captured_type):
					_selected_prelevel_boosts[captured_type] = true
				else:
					boost_btn.button_pressed = false
			else:
				if _selected_prelevel_boosts[captured_type]:
					LevelManager.prelevel_boosts[captured_type] += 1
					_selected_prelevel_boosts[captured_type] = false
		)
		slot.add_child(boost_btn)
		var buy_btn = UiDialogStyles.create_small_icon_button("+", minf(slot_size.x, slot_size.y) * 0.5)
		buy_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.flat = true
		var is_empty := boost_count <= 0
		buy_btn.visible = is_empty
		buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP if is_empty else Control.MOUSE_FILTER_IGNORE
		buy_btn.pressed.connect(func():
			_show_buy_prelevel_boost_dialog(captured_type)
		)
		slot.add_child(buy_btn)
		boost_vbox.add_child(slot)
		var name_label = UiDialogStyles.create_body_label(boost_names[boost_type], 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boost_vbox.add_child(name_label)
		var count_label = Label.new()
		count_label.text = "x" + str(boost_count)
		count_label.add_theme_font_size_override("font_size", 24)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if boost_count > 0 else Color(0.5, 0.5, 0.5))
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boost_vbox.add_child(count_label)
		_prelevel_boosts_row.add_child(boost_vbox)

func _refresh_prelevel_boosts_row() -> void:
	_populate_prelevel_boosts_row()

func _show_buy_prelevel_boost_dialog(boost_type: String) -> void:
	if not LevelManager:
		return
	if _prelevel_purchase_flow_open or UIFlow.has_page(BOOSTER_PURCHASE_FLOW_PAGE_SCRIPT):
		return
	var display_names := {"bomb": "Бомба", "arrow": "Стрела", "rainbow": "Шар"}
	var cost: int = LevelManager.get_prelevel_boost_pack_cost(boost_type)
	var qty: int = LevelManager.PRELEVEL_BOOST_PACK_COUNT
	var player_coins: int = LevelManager.get_coins()
	var can_afford: bool = player_coins >= cost
	var icon_tex: Texture2D = LevelManager.get_prelevel_boost_texture(boost_type)
	var title_name: String = display_names.get(boost_type, "Усиление")
	var captured_boost: String = boost_type
	_prelevel_purchase_flow_open = true
	var page: BoosterPurchaseFlowPage = BOOSTER_PURCHASE_FLOW_PAGE_SCRIPT.new()
	page.closed_pressed.connect(func() -> void:
		_prelevel_purchase_flow_open = false
	)
	page.purchase_pressed.connect(func() -> void:
		if LevelManager.purchase_prelevel_boosts(captured_boost):
			_refresh_prelevel_boosts_row()
	)
	UIFlow.push_instance(page, {
		"display_name": title_name,
		"icon_tex": icon_tex,
		"cost": cost,
		"pack_qty": qty,
		"player_coins": player_coins,
		"can_afford": can_afford,
		"header_title": "ПОКУПКА УСИЛЕНИЯ",
	})

func _return_selected_prelevel_boosts_to_inventory() -> void:
	if not LevelManager:
		return
	for boost_type in _selected_prelevel_boosts.keys():
		if _selected_prelevel_boosts[boost_type]:
			LevelManager.prelevel_boosts[boost_type] += 1
			_selected_prelevel_boosts[boost_type] = false

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if _dialog_closing:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_dialog_closing = true
			_on_close_pressed()
			get_viewport().set_input_as_handled()

func _on_close_pressed() -> void:
	_return_selected_prelevel_boosts_to_inventory()
	queue_free()

func _run_web_smoke_test_level_start_flow() -> void:
	WebSmokeTestBridge.report_phase("level_start_dialog_ready")
	await get_tree().create_timer(0.75).timeout
	if _dialog_closing or is_queued_for_deletion():
		return
	_dialog_closing = true
	_on_start_pressed()

func _on_start_pressed():
	var mort_bonuses = LevelManager.get_mort_helmet_bonus_chips() if LevelManager else {}
	emit_signal("start_gameplay", _selected_prelevel_boosts, mort_bonuses)
	queue_free()
