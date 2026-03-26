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

func setup():
	_build_dialog()

func _build_dialog():
	# Полупрозрачный фон
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
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
	
	# Кнопка закрытия (крестик) в правом верхнем углу
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(50, 50)
	close_btn.position = Vector2(panel.custom_minimum_size.x - 70, 10)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_style.set_corner_radius_all(25)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.focus_mode = Control.FOCUS_NONE
	
	close_btn.pressed.connect(func():
		if not _dialog_closing and not is_queued_for_deletion():
			_dialog_closing = true
			_on_close_pressed()
	)
	panel.add_child(close_btn)
	
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
	
	# Заголовок секции
	var boosts_title = Label.new()
	boosts_title.text = "ПРЕДУРОВНЕВЫЕ УСИЛЕНИЯ"
	boosts_title.add_theme_font_size_override("font_size", 28)
	boosts_title.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	boosts_title.add_theme_color_override("font_outline_color", Color.BLACK)
	boosts_title.add_theme_constant_override("outline_size", 4)
	boosts_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(boosts_title)
	
	# HBox для трех типов усилений
	var boosts_hbox = HBoxContainer.new()
	boosts_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	boosts_hbox.add_theme_constant_override("separation", 30)
	
	var boost_types = ["bomb", "arrow", "rainbow"]
	var boost_names = {"bomb": "Бомба", "arrow": "Стрела", "rainbow": "Шар"}
	
	for boost_type in boost_types:
		var boost_count = LevelManager.get_prelevel_boost_count(boost_type)
		
		# Контейнер одного усиления
		var boost_vbox = VBoxContainer.new()
		boost_vbox.add_theme_constant_override("separation", 8)
		boost_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Кнопка с иконкой
		var boost_btn = Button.new()
		boost_btn.custom_minimum_size = Vector2(100, 100)
		boost_btn.toggle_mode = true
		boost_btn.disabled = (boost_count <= 0)
		
		# Иконка усиления
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
		
		# Обработчик выбора усиления
		boost_btn.toggled.connect(func(pressed: bool):
			if pressed:
				if LevelManager.use_prelevel_boost(boost_type):
					_selected_prelevel_boosts[boost_type] = true
				else:
					boost_btn.button_pressed = false
			else:
				# Возврат усиления обратно (отмена выбора)
				if _selected_prelevel_boosts[boost_type]:
					LevelManager.prelevel_boosts[boost_type] += 1
					_selected_prelevel_boosts[boost_type] = false
		)
		
		boost_vbox.add_child(boost_btn)
		
		# Название
		var name_label = Label.new()
		name_label.text = boost_names[boost_type]
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boost_vbox.add_child(name_label)
		
		# Счетчик
		var count_label = Label.new()
		count_label.text = "x" + str(boost_count)
		count_label.add_theme_font_size_override("font_size", 24)
		count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if boost_count > 0 else Color(0.5, 0.5, 0.5))
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boost_vbox.add_child(count_label)
		
		# Кнопка покупки (если закончились)
		if boost_count <= 0:
			var buy_btn = Button.new()
			buy_btn.text = "+"
			buy_btn.custom_minimum_size = Vector2(40, 40)
			buy_btn.add_theme_font_size_override("font_size", 28)
			buy_btn.add_theme_color_override("font_color", Color.WHITE)
			
			var buy_style = StyleBoxFlat.new()
			buy_style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
			buy_style.set_corner_radius_all(20)
			buy_btn.add_theme_stylebox_override("normal", buy_style)
			buy_btn.focus_mode = Control.FOCUS_NONE
			
			buy_btn.pressed.connect(func():
				_show_buy_prelevel_boost_dialog(boost_type)
			)
			
			boost_vbox.add_child(buy_btn)
		
		boosts_hbox.add_child(boost_vbox)
	
	vbox.add_child(boosts_hbox)

func _show_buy_prelevel_boost_dialog(boost_type: String):
	# TODO: Интеграция с монетами
	pass

func _return_selected_prelevel_boosts_to_inventory() -> void:
	if not LevelManager:
		return
	for boost_type in _selected_prelevel_boosts.keys():
		if _selected_prelevel_boosts[boost_type]:
			LevelManager.prelevel_boosts[boost_type] += 1
			_selected_prelevel_boosts[boost_type] = false

func _on_close_pressed() -> void:
	_return_selected_prelevel_boosts_to_inventory()
	queue_free()

func _on_start_pressed():
	var mort_bonuses = LevelManager.get_mort_helmet_bonus_chips() if LevelManager else {}
	emit_signal("start_gameplay", _selected_prelevel_boosts, mort_bonuses)
	queue_free()
