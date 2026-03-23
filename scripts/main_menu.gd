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

# Флаг для предотвращения множественного открытия диалога
var _level_start_dialog_shown: bool = false

func _ready():
	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		_style_play_button()
	
	_setup_navigation()
	_update_level_label()
	_build_levels_grid()
	_switch_tab("main")

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
		
		b.toggle_mode = false
		b.pressed.connect(func():
			LevelManager.set_current_level(int(b.text))
			_update_level_label()
			_show_level_start_dialog(int(b.text))
		)
		levels_grid.add_child(b)

func _highlight_selected_in_grid():
	if not is_instance_valid(levels_grid):
		return
	for b in levels_grid.get_children():
		if b is Button:
			b.button_pressed = (int(b.text) == LevelManager.current_level)

func _show_level_start_dialog(level: int):
	# Предотвращаем множественное открытие диалога
	if _level_start_dialog_shown:
		return
	
	_level_start_dialog_shown = true
	
	# Загружаем и показываем скрипт диалога старта уровня
	var dialog_script = preload("res://scripts/level_start_dialog.gd")
	var dialog = Control.new()
	dialog.set_script(dialog_script)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.z_index = 100
	
	dialog.connect("start_gameplay", _on_level_start_dialog_completed)
	
	# Сбрасываем флаг при удалении диалога
	dialog.tree_exiting.connect(func():
		_level_start_dialog_shown = false
	)
	
	add_child(dialog)
	dialog.setup()

func _on_level_start_dialog_completed(selected_boosts: Dictionary, mort_bonuses: Dictionary):
	# Сохраняем выбранные усиления в LevelManager
	LevelManager.selected_prelevel_boosts = selected_boosts
	
	# Загружаем игровую сцену
	var err = get_tree().change_scene_to_file(GAME_BOARD_SCENE_PATH)
	if err != OK:
		printerr("Не удалось загрузить сцену игрового поля: ", err)
