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

const PRELEVEL_PURCHASE_OVERLAY_SCRIPT := preload("res://scripts/ingame_booster_purchase_dialog.gd")

var _prelevel_boosts_row: HBoxContainer = null
var _prelevel_purchase_overlay: Control = null

func setup():
	_build_dialog()

func _build_dialog():
	# Полупрозрачный фон (клик вне панели — закрыть без старта)
	var bg = ColorRect.new()
	bg.name = "LevelStartDimmer"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(_on_dimmer_gui_input)
	add_child(bg)
	
	# Центральная панель диалога
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(600, 700)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -350
	panel.offset_bottom = 350
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.15, 0.2, 0.95)
	panel_style.set_corner_radius_all(20)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.8, 0.7, 0.3, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	
	# VBoxContainer для вертикального расположения элементов
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	panel.add_child(vbox)
	
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 8)
	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 50)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_style.set_corner_radius_all(25)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(func():
		if not _dialog_closing and not is_queued_for_deletion():
			_dialog_closing = true
			_on_close_pressed()
	)
	header_row.add_child(close_btn)
	vbox.add_child(header_row)
	
	# Заголовок
	var title = Label.new()
	var level_num = LevelManager.current_level if LevelManager else 1
	title.text = "УРОВЕНЬ " + str(level_num)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Шлем Морта (Win Streak прогресс)
	_add_mort_helmet_section(vbox)
	
	# Предуровневые усиления
	_add_prelevel_boosts_section(vbox)
	
	# Кнопка "Играть"
	var play_btn = Button.new()
	play_btn.text = "ИГРАТЬ"
	play_btn.custom_minimum_size = Vector2(400, 80)
	
	var play_style = StyleBoxFlat.new()
	play_style.bg_color = Color(0.2, 0.6, 0.3, 1.0)
	play_style.set_corner_radius_all(15)
	play_style.border_width_left = 3
	play_style.border_width_top = 3
	play_style.border_width_right = 3
	play_style.border_width_bottom = 3
	play_style.border_color = Color(0.4, 0.9, 0.5, 1.0)
	
	var play_hover = play_style.duplicate()
	play_hover.bg_color = Color(0.3, 0.7, 0.4, 1.0)
	
	play_btn.add_theme_stylebox_override("normal", play_style)
	play_btn.add_theme_stylebox_override("hover", play_hover)
	play_btn.add_theme_font_size_override("font_size", 42)
	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	play_btn.add_theme_constant_override("outline_size", 5)
	play_btn.focus_mode = Control.FOCUS_NONE
	
	play_btn.pressed.connect(func():
		if not _dialog_closing and not is_queued_for_deletion():
			_dialog_closing = true
			_on_start_pressed()
	)
	
	var play_container = CenterContainer.new()
	play_container.add_child(play_btn)
	vbox.add_child(play_container)

func _add_mort_helmet_section(vbox: VBoxContainer):
	if not LevelManager:
		return
	
	var helmet_level = LevelManager.mort_helmet_level
	var win_streak = LevelManager.win_streak
	
	# Заголовок секции
	var helmet_title = Label.new()
	helmet_title.text = "ШЛЕМ МОРТА"
	helmet_title.add_theme_font_size_override("font_size", 32)
	helmet_title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	helmet_title.add_theme_color_override("font_outline_color", Color.BLACK)
	helmet_title.add_theme_constant_override("outline_size", 4)
	helmet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(helmet_title)
	
	# Визуальное отображение уровня шлема (3 этапа)
	var helmet_progress = HBoxContainer.new()
	helmet_progress.alignment = BoxContainer.ALIGNMENT_CENTER
	helmet_progress.add_theme_constant_override("separation", 15)
	
	for i in range(1, 4):
		var stage = Panel.new()
		stage.custom_minimum_size = Vector2(60, 60)
		
		var stage_style = StyleBoxFlat.new()
		if i <= helmet_level:
			# Активный этап - золотой
			stage_style.bg_color = Color(0.9, 0.7, 0.2, 1.0)
			stage_style.border_color = Color(1.0, 0.9, 0.5, 1.0)
		else:
			# Неактивный этап - серый
			stage_style.bg_color = Color(0.3, 0.3, 0.35, 0.5)
			stage_style.border_color = Color(0.5, 0.5, 0.55, 1.0)
		
		stage_style.set_corner_radius_all(10)
		stage_style.border_width_left = 3
		stage_style.border_width_top = 3
		stage_style.border_width_right = 3
		stage_style.border_width_bottom = 3
		stage.add_theme_stylebox_override("panel", stage_style)
		
		# Номер этапа
		var stage_label = Label.new()
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
	
	vbox.add_child(helmet_progress)
	
	# Описание текущего бонуса
	var bonus_chips = LevelManager.get_mort_helmet_bonus_chips()
	if not bonus_chips.is_empty():
		var bonus_desc = Label.new()
		var arrow_count = bonus_chips.get("arrow", 0)
		var bomb_count = bonus_chips.get("bomb", 0)
		bonus_desc.text = "Бонус: %d стрел + %d бомб" % [arrow_count, bomb_count]
		bonus_desc.add_theme_font_size_override("font_size", 24)
		bonus_desc.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		bonus_desc.add_theme_color_override("font_outline_color", Color.BLACK)
		bonus_desc.add_theme_constant_override("outline_size", 3)
		bonus_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(bonus_desc)
	else:
		var no_bonus = Label.new()
		no_bonus.text = "Победите уровни подряд для усиления!"
		no_bonus.add_theme_font_size_override("font_size", 20)
		no_bonus.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		no_bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_bonus)

func _add_prelevel_boosts_section(vbox: VBoxContainer):
	if not LevelManager:
		return
	var boosts_title = Label.new()
	boosts_title.text = "ПРЕДУРОВНЕВЫЕ УСИЛЕНИЯ"
	boosts_title.add_theme_font_size_override("font_size", 28)
	boosts_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	boosts_title.add_theme_color_override("font_outline_color", Color.BLACK)
	boosts_title.add_theme_constant_override("outline_size", 4)
	boosts_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.25, 0.3, 0.8) if boost_count > 0 else Color(0.15, 0.15, 0.15, 0.5)
		btn_style.set_corner_radius_all(15)
		btn_style.border_width_left = 3
		btn_style.border_width_top = 3
		btn_style.border_width_right = 3
		btn_style.border_width_bottom = 3
		btn_style.border_color = Color(0.6, 0.6, 0.7, 1.0) if boost_count > 0 else Color(0.3, 0.3, 0.3, 0.5)
		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.3, 0.6, 0.9, 1.0)
		btn_pressed.border_color = Color(0.5, 0.8, 1.0, 1.0)
		boost_btn.add_theme_stylebox_override("normal", btn_style)
		boost_btn.add_theme_stylebox_override("pressed", btn_pressed)
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
		var buy_btn = Button.new()
		buy_btn.text = "+"
		buy_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		buy_btn.focus_mode = Control.FOCUS_NONE
		buy_btn.flat = true
		var plus_r := int(floor(min(slot_size.x, slot_size.y) * 0.5))
		var buy_normal = StyleBoxFlat.new()
		buy_normal.bg_color = Color(0.18, 0.62, 0.22, 0.92)
		buy_normal.set_corner_radius_all(plus_r)
		buy_normal.border_width_left = 3
		buy_normal.border_width_top = 3
		buy_normal.border_width_right = 3
		buy_normal.border_width_bottom = 3
		buy_normal.border_color = Color(0.35, 0.85, 0.42, 1.0)
		var buy_hover = buy_normal.duplicate()
		buy_hover.bg_color = Color(0.25, 0.72, 0.3, 0.95)
		buy_btn.add_theme_stylebox_override("normal", buy_normal)
		buy_btn.add_theme_stylebox_override("hover", buy_hover)
		buy_btn.add_theme_stylebox_override("pressed", buy_normal)
		buy_btn.add_theme_font_size_override("font_size", 36)
		buy_btn.add_theme_color_override("font_color", Color.WHITE)
		buy_btn.add_theme_color_override("font_outline_color", Color.BLACK)
		buy_btn.add_theme_constant_override("outline_size", 4)
		var is_empty := boost_count <= 0
		buy_btn.visible = is_empty
		buy_btn.mouse_filter = Control.MOUSE_FILTER_STOP if is_empty else Control.MOUSE_FILTER_IGNORE
		buy_btn.pressed.connect(func():
			_show_buy_prelevel_boost_dialog(captured_type)
		)
		slot.add_child(buy_btn)
		boost_vbox.add_child(slot)
		var name_label = Label.new()
		name_label.text = boost_names[boost_type]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.WHITE)
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

func _dismiss_prelevel_purchase_overlay() -> void:
	if _prelevel_purchase_overlay != null and is_instance_valid(_prelevel_purchase_overlay):
		_prelevel_purchase_overlay.queue_free()
	_prelevel_purchase_overlay = null

func _show_buy_prelevel_boost_dialog(boost_type: String) -> void:
	if not LevelManager:
		return
	var display_names := {"bomb": "Бомба", "arrow": "Стрела", "rainbow": "Шар"}
	var cost: int = LevelManager.get_prelevel_boost_pack_cost(boost_type)
	var qty: int = LevelManager.PRELEVEL_BOOST_PACK_COUNT
	var player_coins: int = LevelManager.get_coins()
	var can_afford: bool = player_coins >= cost
	var icon_tex: Texture2D = LevelManager.get_prelevel_boost_texture(boost_type)
	_dismiss_prelevel_purchase_overlay()
	var overlay = Control.new()
	overlay.set_script(PRELEVEL_PURCHASE_OVERLAY_SCRIPT)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 150
	add_child(overlay)
	overlay.move_to_front()
	_prelevel_purchase_overlay = overlay
	var title_name: String = display_names.get(boost_type, "Усиление")
	overlay.setup(title_name, icon_tex, cost, qty, player_coins, can_afford, "ПОКУПКА УСИЛЕНИЯ")
	var captured_boost: String = boost_type
	overlay.purchase_pressed.connect(func():
		if LevelManager.purchase_prelevel_boosts(captured_boost):
			_dismiss_prelevel_purchase_overlay()
			_refresh_prelevel_boosts_row()
		else:
			_dismiss_prelevel_purchase_overlay()
	)
	overlay.closed_pressed.connect(_dismiss_prelevel_purchase_overlay)

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

func _on_start_pressed():
	var mort_bonuses = LevelManager.get_mort_helmet_bonus_chips() if LevelManager else {}
	emit_signal("start_gameplay", _selected_prelevel_boosts, mort_bonuses)
	queue_free()
