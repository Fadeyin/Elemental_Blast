extends Control

@onready var play_button = $TabContent/MainTab/PlayButton
@onready var start_level_label = $TabContent/MainTab/StartLevelLabel
@onready var levels_grid = $TabContent/MainTab/LevelsScroll/LevelsGrid

@onready var shop_tab = $TabContent/ShopTab
@onready var main_tab = $TabContent/MainTab
@onready var ranks_tab = $TabContent/RanksTab

@onready var shop_btn = $BottomNav/HBox/ShopBtn
@onready var main_btn = $BottomNav/HBox/MainBtn
@onready var ranks_btn = $BottomNav/HBox/RanksBtn

# Путь к игровой сцене
const GAME_BOARD_SCENE_PATH = "res://scenes/game_board.tscn"

func _ready():
	_create_top_bar()
	
	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		_style_play_button()
	
	_setup_navigation()
	_update_level_label()
	_build_levels_grid()
	_switch_tab("main")
	
	LevelManager.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(new_amount: int):
	var coins_label = find_child("TopBarCoinsCount", true, false)
	if coins_label:
		coins_label.text = str(new_amount)

func _create_top_bar():
	var top_bar = ColorRect.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(0, 80)
	top_bar.color = Color(0.08, 0.1, 0.12, 0.9)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 80
	add_child(top_bar)
	move_child(top_bar, 1)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	top_bar.add_child(hbox)
	
	hbox.add_child(_create_spacer(20))
	
	var avatar_container = _create_avatar()
	hbox.add_child(avatar_container)
	
	hbox.add_child(_create_spacer(15))
	
	var coins_container = _create_coins_display()
	hbox.add_child(coins_container)
	
	var buy_coins_btn = _create_buy_coins_button()
	hbox.add_child(buy_coins_btn)
	
	hbox.add_child(_create_flexible_spacer())
	
	var settings_btn = _create_settings_button()
	hbox.add_child(settings_btn)
	
	hbox.add_child(_create_spacer(20))

func _create_spacer(width: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(width, 0)
	return spacer

func _create_flexible_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _create_avatar() -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(64, 64)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.35, 0.4, 1.0)
	bg_style.corner_radius_top_left = 32
	bg_style.corner_radius_top_right = 32
	bg_style.corner_radius_bottom_left = 32
	bg_style.corner_radius_bottom_right = 32
	bg_style.border_width_top = 3
	bg_style.border_width_bottom = 3
	bg_style.border_width_left = 3
	bg_style.border_width_right = 3
	bg_style.border_color = Color(0.5, 0.6, 0.7, 1.0)
	container.add_theme_stylebox_override("panel", bg_style)
	
	var avatar_label = Label.new()
	avatar_label.text = "👤"
	avatar_label.add_theme_font_size_override("font_size", 42)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(avatar_label)
	
	return container

func _create_coins_display() -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var coin_icon = Label.new()
	coin_icon.text = "🪙"
	coin_icon.add_theme_font_size_override("font_size", 36)
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(coin_icon)
	
	var coins_label = Label.new()
	coins_label.name = "TopBarCoinsCount"
	coins_label.text = str(LevelManager.get_coins())
	coins_label.add_theme_font_size_override("font_size", 32)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	coins_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0, 0.9))
	coins_label.add_theme_constant_override("outline_size", 4)
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(coins_label)
	
	return container

func _create_buy_coins_button() -> Button:
	var btn = Button.new()
	btn.text = "+"
	btn.custom_minimum_size = Vector2(50, 50)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.6, 0.3, 1.0)
	normal_style.corner_radius_top_left = 25
	normal_style.corner_radius_top_right = 25
	normal_style.corner_radius_bottom_left = 25
	normal_style.corner_radius_bottom_right = 25
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_color = Color(0.3, 0.8, 0.4, 1.0)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.7, 0.4, 1.0)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.5, 0.25, 1.0)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_font_size_override("font_size", 36)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0.3, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 3)
	
	btn.pressed.connect(_on_buy_coins_pressed)
	
	return btn

func _create_settings_button() -> Button:
	var btn = Button.new()
	btn.text = "⚙"
	btn.custom_minimum_size = Vector2(60, 60)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
	normal_style.corner_radius_top_left = 30
	normal_style.corner_radius_top_right = 30
	normal_style.corner_radius_bottom_left = 30
	normal_style.corner_radius_bottom_right = 30
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_color = Color(0.4, 0.5, 0.6, 1.0)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.35, 0.4, 0.45, 1.0)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.25, 0.3, 1.0)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_font_size_override("font_size", 40)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	
	btn.pressed.connect(_on_settings_pressed)
	
	return btn

func _on_buy_coins_pressed():
	_show_buy_coins_dialog()

func _on_settings_pressed():
	var dialog = AcceptDialog.new()
	dialog.title = "Настройки"
	dialog.dialog_text = "Настройки будут добавлены позже"
	dialog.ok_button_text = "Закрыть"
	add_child(dialog)
	dialog.popup_centered(Vector2(400, 150))
	
	var _on_close = func():
		if not dialog.is_queued_for_deletion():
			dialog.queue_free()
	
	dialog.confirmed.connect(_on_close)
	dialog.close_requested.connect(_on_close)

func _show_buy_coins_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "Купить монеты"
	dialog.dialog_text = "Выберите пакет монет:\n\n100 монет - 50₽\n500 монет - 200₽\n1000 монет - 350₽\n\n(Покупка временно недоступна)"
	dialog.ok_button_text = "Закрыть"
	dialog.get_ok_button().disabled = false
	
	add_child(dialog)
	dialog.popup_centered(Vector2(450, 250))
	
	var _on_close = func():
		if not dialog.is_queued_for_deletion():
			dialog.queue_free()
	
	dialog.confirmed.connect(_on_close)
	dialog.close_requested.connect(_on_close)

func _setup_navigation():
	shop_btn.pressed.connect(func(): _switch_tab("shop"))
	main_btn.pressed.connect(func(): _switch_tab("main"))
	ranks_btn.pressed.connect(func(): _switch_tab("ranks"))
	
	# Стилизация навигации
	var buttons = [shop_btn, main_btn, ranks_btn]
	for btn in buttons:
		_style_nav_button(btn)

func _switch_tab(tab_name: String):
	shop_tab.visible = (tab_name == "shop")
	main_tab.visible = (tab_name == "main")
	ranks_tab.visible = (tab_name == "ranks")
	
	# Подсветка активной кнопки
	shop_btn.modulate = Color(1, 1, 1) if tab_name == "shop" else Color(0.6, 0.6, 0.6)
	main_btn.modulate = Color(1, 1, 1) if tab_name == "main" else Color(0.6, 0.6, 0.6)
	ranks_btn.modulate = Color(1, 1, 1) if tab_name == "ranks" else Color(0.6, 0.6, 0.6)

func _style_nav_button(btn: Button):
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0) # Прозрачный фон
	normal.border_width_top = 4
	normal.border_color = Color(0, 0, 0, 0)
	
	var hover = normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.05)
	
	var pressed = normal.duplicate()
	pressed.bg_color = Color(1, 1, 1, 0.1)
	pressed.border_color = Color(0.4, 0.7, 1.0, 1.0) # Синяя полоска сверху
	
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 4)

func _on_play_pressed():
	# Не сбрасываем выбранный пользователем уровень (подтверждаем выбор)
	LevelManager.set_current_level(LevelManager.current_level)
	var err = get_tree().change_scene_to_file(GAME_BOARD_SCENE_PATH)
	if err != OK:
		printerr("Не удалось загрузить сцену игрового поля: ", err)

func _style_play_button():
	if not is_instance_valid(play_button):
		return
	
	# Красивый стиль кнопки с закруглениями
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.4, 0.6, 1.0) # Синий
	normal_style.corner_radius_top_left = 20
	normal_style.corner_radius_top_right = 20
	normal_style.corner_radius_bottom_left = 20
	normal_style.corner_radius_bottom_right = 20
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_color = Color(0.4, 0.6, 0.9, 1.0)
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 8
	normal_style.shadow_offset = Vector2(0, 4)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.5, 0.7, 1.0)
	hover_style.border_color = Color(0.5, 0.7, 1.0, 1.0)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.3, 0.5, 1.0)
	pressed_style.shadow_offset = Vector2(0, 2)
	
	play_button.add_theme_stylebox_override("normal", normal_style)
	play_button.add_theme_stylebox_override("hover", hover_style)
	play_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Игровой шрифт (жирный, читаемый)
	play_button.add_theme_font_size_override("font_size", 48)
	play_button.add_theme_color_override("font_color", Color.WHITE)
	play_button.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	play_button.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	
	# Обводка текста для читаемости
	play_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	play_button.add_theme_constant_override("outline_size", 4)

func _update_level_label():
	if is_instance_valid(start_level_label):
		var lvl = LevelManager.current_level
		start_level_label.text = "Стартовый уровень: " + str(lvl)
		# Применяем игровой шрифт к лейблу
		start_level_label.add_theme_font_size_override("font_size", 32)
		start_level_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		start_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		start_level_label.add_theme_constant_override("outline_size", 3)
	
	# Обновляем текст кнопки
	if is_instance_valid(play_button):
		play_button.text = "Уровень " + str(LevelManager.current_level)

# удалены обработчики стрелок

func _build_levels_grid():
	if not is_instance_valid(levels_grid):
		return
	for c in levels_grid.get_children():
		c.queue_free()
	var levels = LevelManager.get_available_level_numbers()
	for n in levels:
		var b = Button.new()
		b.text = str(n)
		b.custom_minimum_size = Vector2(160, 100)
		b.add_theme_font_size_override("font_size", 40)
		
		# Стиль кнопок уровней
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.25, 0.3, 0.4, 0.9)
		normal_style.corner_radius_top_left = 12
		normal_style.corner_radius_top_right = 12
		normal_style.corner_radius_bottom_left = 12
		normal_style.corner_radius_bottom_right = 12
		normal_style.border_width_top = 2
		normal_style.border_width_bottom = 2
		normal_style.border_width_left = 2
		normal_style.border_width_right = 2
		normal_style.border_color = Color(0.5, 0.6, 0.8, 1.0)
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.35, 0.45, 0.6, 1.0)
		
		var pressed_style = normal_style.duplicate()
		pressed_style.bg_color = Color(0.2, 0.5, 0.7, 1.0)
		pressed_style.border_color = Color(0.6, 0.8, 1.0, 1.0)
		
		b.add_theme_stylebox_override("normal", normal_style)
		b.add_theme_stylebox_override("hover", hover_style)
		b.add_theme_stylebox_override("pressed", pressed_style)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		b.add_theme_constant_override("outline_size", 3)
		
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		b.toggle_mode = true
		b.button_pressed = (n == LevelManager.current_level)
		b.pressed.connect(func():
			LevelManager.set_current_level(int(b.text))
			_update_level_label()
			_highlight_selected_in_grid()
		)
		levels_grid.add_child(b)

func _highlight_selected_in_grid():
	if not is_instance_valid(levels_grid):
		return
	for b in levels_grid.get_children():
		if b is Button:
			b.button_pressed = (int(b.text) == LevelManager.current_level)
