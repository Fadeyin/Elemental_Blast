extends Control

@onready var play_button = $TabContent/MainTab/PlayButton
@onready var start_level_label = $TabContent/MainTab/StartLevelLabel
@onready var levels_grid = $TabContent/MainTab/LevelsScroll/LevelsGrid
@onready var version_label = $VersionLabel

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
var _golden_pass_dialog_open: bool = false

const GOLDEN_PASS_DIALOG_SCRIPT := preload("res://scripts/golden_pass_dialog.gd")

func _ready():
	_create_top_bar()
	if LevelManager:
		LevelManager.tick_golden_pass_daily_login()
	_create_golden_pass_fab()
	
	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		_style_play_button()
	
	_setup_navigation()
	_update_level_label()
	_update_version_label()
	_build_levels_grid()
	_build_shop_tab()
	_switch_tab("main")
	
	LevelManager.coins_changed.connect(_on_coins_changed)
	LevelManager.boosters_changed.connect(_on_boosters_changed)
	LevelManager.golden_pass_state_changed.connect(_on_golden_pass_state_changed)

func _on_boosters_changed():
	_build_shop_tab()

func _on_coins_changed(new_amount: int):
	var coins_label = find_child("TopBarCoinsCount", true, false)
	if coins_label:
		coins_label.text = str(new_amount)
	_refresh_golden_pass_buy_button_if_visible()

func _on_golden_pass_state_changed():
	_refresh_golden_pass_buy_button_if_visible()

func _refresh_golden_pass_buy_button_if_visible():
	if _golden_pass_dialog_open:
		var dlg = find_child("GoldenPassOverlay", true, false)
		if dlg and dlg.has_method("setup"):
			dlg.setup()

func _create_golden_pass_fab() -> void:
	var fab := Button.new()
	fab.name = "GoldenPassFab"
	fab.focus_mode = Control.FOCUS_NONE
	fab.custom_minimum_size = Vector2(64, 64)
	fab.anchor_left = 1.0
	fab.anchor_top = 0.0
	fab.anchor_right = 1.0
	fab.anchor_bottom = 0.0
	fab.offset_left = -84.0
	fab.offset_top = 88.0
	fab.offset_right = -20.0
	fab.offset_bottom = 152.0
	fab.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	fab.grow_vertical = Control.GROW_DIRECTION_END
	fab.text = "★"
	fab.add_theme_font_size_override("font_size", 32)
	var r := 32
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.78, 0.55, 0.12, 1.0)
	n.set_corner_radius_all(r)
	n.border_width_left = 3
	n.border_width_top = 3
	n.border_width_right = 3
	n.border_width_bottom = 3
	n.border_color = Color(1.0, 0.92, 0.45, 1.0)
	n.shadow_color = Color(0, 0, 0, 0.35)
	n.shadow_size = 6
	n.shadow_offset = Vector2(0, 3)
	var h := n.duplicate()
	h.bg_color = Color(0.9, 0.68, 0.18, 1.0)
	var p := n.duplicate()
	p.bg_color = Color(0.62, 0.42, 0.08, 1.0)
	fab.add_theme_stylebox_override("normal", n)
	fab.add_theme_stylebox_override("hover", h)
	fab.add_theme_stylebox_override("pressed", p)
	fab.add_theme_color_override("font_color", Color(1.0, 0.98, 0.75))
	fab.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0, 0.9))
	fab.add_theme_constant_override("outline_size", 4)
	fab.z_index = 5
	fab.tooltip_text = "Золотой пропуск"
	fab.pressed.connect(_show_golden_pass_dialog)
	add_child(fab)

func _show_golden_pass_dialog() -> void:
	if _golden_pass_dialog_open:
		return
	if LevelManager:
		LevelManager.tick_golden_pass_daily_login()
	_golden_pass_dialog_open = true
	var dlg := Control.new()
	dlg.name = "GoldenPassOverlay"
	dlg.set_script(GOLDEN_PASS_DIALOG_SCRIPT)
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dlg.mouse_filter = Control.MOUSE_FILTER_STOP
	dlg.z_index = 150
	dlg.tree_exiting.connect(func():
		_golden_pass_dialog_open = false
	)
	add_child(dlg)
	dlg.setup()

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
	var coins = LevelManager.get_coins() if LevelManager else 0
	coins_label.text = str(coins)
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
	LevelManager.set_current_level(LevelManager.current_level)
	_show_level_start_dialog(LevelManager.current_level)

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
		var lvl = LevelManager.current_level if LevelManager else 1
		start_level_label.text = "Стартовый уровень: " + str(lvl)
		# Применяем игровой шрифт к лейблу
		start_level_label.add_theme_font_size_override("font_size", 32)
		start_level_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		start_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		start_level_label.add_theme_constant_override("outline_size", 3)
	
	# Обновляем текст кнопки
	if is_instance_valid(play_button):
		var lvl = LevelManager.current_level if LevelManager else 1
		play_button.text = "Уровень " + str(lvl)

func _update_version_label():
	if is_instance_valid(version_label):
		var ver = VersionManager.get_version() if VersionManager else "0.1"
		version_label.text = "v" + str(ver)
		version_label.add_theme_font_size_override("font_size", 18)
		version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
		version_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
		version_label.add_theme_constant_override("outline_size", 2)

# удалены обработчики стрелок

func _build_levels_grid():
	if not is_instance_valid(levels_grid):
		return
	for c in levels_grid.get_children():
		c.queue_free()
	
	if not LevelManager:
		print("ОШИБКА: LevelManager не инициализирован!")
		return
	
	var levels = LevelManager.get_available_level_numbers()
	for n in levels:
		var b = Button.new()
		b.set_meta("level_number", n)
		b.text = "Уровень " + str(n)
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
			var lvl_num = int(b.get_meta("level_number"))
			LevelManager.set_current_level(lvl_num)
			_update_level_label()
			_show_level_start_dialog(lvl_num)
		)
		levels_grid.add_child(b)

func _highlight_selected_in_grid():
	if not is_instance_valid(levels_grid):
		return
	for b in levels_grid.get_children():
		if b is Button and b.has_meta("level_number"):
			b.button_pressed = (int(b.get_meta("level_number")) == LevelManager.current_level)

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

func _build_shop_tab():
	if not has_node("TabContent/ShopTab"):
		return
	
	var shop_tab_node = get_node("TabContent/ShopTab")
	for child in shop_tab_node.get_children():
		child.queue_free()
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("margin_left", 20)
	scroll.add_theme_constant_override("margin_right", 20)
	scroll.add_theme_constant_override("margin_top", 20)
	scroll.add_theme_constant_override("margin_bottom", 20)
	shop_tab_node.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "МАГАЗИН"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(_create_spacer_v(20))
	
	if not LevelManager.is_starter_pack_purchased():
		var starter = _create_shop_offer(
			"СТАРТОВЫЙ ПАКЕТ",
			"🎁 Специальное предложение!",
			["1000 золотых 🪙", "4 бустера каждого вида 🎮"],
			"1$",
			Color(0.8, 0.3, 0.2, 1.0),
			"starter",
			true
		)
		vbox.add_child(starter)
		vbox.add_child(_create_spacer_v(15))
	
	var medium = _create_shop_offer(
		"СРЕДНИЙ ПАКЕТ",
		"Отличное предложение",
		["2500 золотых 🪙", "5 бустеров каждого вида 🎮"],
		"5$",
		Color(0.2, 0.5, 0.8, 1.0),
		"medium",
		false
	)
	vbox.add_child(medium)
	vbox.add_child(_create_spacer_v(15))
	
	var best = _create_shop_offer(
		"САМЫЙ ВЫГОДНЫЙ",
		"⭐ Лучшее предложение!",
		["5000 золотых 🪙", "10 бустеров каждого вида 🎮"],
		"9$",
		Color(0.6, 0.3, 0.8, 1.0),
		"best",
		false
	)
	vbox.add_child(best)

func _create_spacer_v(height: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	return spacer

func _create_shop_offer(title: String, subtitle: String, items: Array, price: String, color: Color, pack_type: String, is_special: bool) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 180)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	bg_style.corner_radius_top_left = 20
	bg_style.corner_radius_top_right = 20
	bg_style.corner_radius_bottom_left = 20
	bg_style.corner_radius_bottom_right = 20
	bg_style.border_width_top = 4
	bg_style.border_width_bottom = 4
	bg_style.border_width_left = 4
	bg_style.border_width_right = 4
	bg_style.border_color = color
	bg_style.shadow_color = Color(0, 0, 0, 0.5)
	bg_style.shadow_size = 10
	bg_style.shadow_offset = Vector2(0, 5)
	panel.add_theme_stylebox_override("panel", bg_style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	
	hbox.add_child(_create_spacer(15))
	
	var content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(content_vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", color)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 4)
	content_vbox.add_child(title_label)
	
	var subtitle_label = Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content_vbox.add_child(subtitle_label)
	
	content_vbox.add_child(_create_spacer_v(5))
	
	for item in items:
		var item_label = Label.new()
		item_label.text = "  • " + item
		item_label.add_theme_font_size_override("font_size", 22)
		item_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		content_vbox.add_child(item_label)
	
	var buy_btn = Button.new()
	buy_btn.text = price
	buy_btn.custom_minimum_size = Vector2(150, 80)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = color
	btn_style.corner_radius_top_left = 15
	btn_style.corner_radius_top_right = 15
	btn_style.corner_radius_bottom_left = 15
	btn_style.corner_radius_bottom_right = 15
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 3
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	btn_style.border_color = color.lightened(0.3)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	
	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", hover_style)
	buy_btn.add_theme_stylebox_override("pressed", pressed_style)
	buy_btn.add_theme_font_size_override("font_size", 36)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	buy_btn.add_theme_constant_override("outline_size", 4)
	
	buy_btn.pressed.connect(_on_shop_purchase.bind(pack_type))
	hbox.add_child(buy_btn)
	
	hbox.add_child(_create_spacer(15))
	
	if is_special:
		var badge = Label.new()
		badge.text = "ТОЛЬКО 1 РАЗ!"
		badge.add_theme_font_size_override("font_size", 16)
		badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		badge.add_theme_color_override("font_outline_color", Color(0.5, 0.2, 0.0))
		badge.add_theme_constant_override("outline_size", 3)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -150
		badge.offset_top = 5
		badge.offset_right = -10
		badge.offset_bottom = 30
		panel.add_child(badge)
	
	return panel

func _on_shop_purchase(pack_type: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Покупка"
	
	match pack_type:
		"starter":
			dialog.dialog_text = "Стартовый пакет:\n\n• 1000 золотых 🪙\n• 4 бустера каждого вида 🎮\n• Цена: 1$\n\n(Покупка через платёжную систему\nвременно недоступна)"
		"medium":
			dialog.dialog_text = "Средний пакет:\n\n• 2500 золотых 🪙\n• 5 бустеров каждого вида 🎮\n• Цена: 5$\n\n(Покупка через платёжную систему\nвременно недоступна)"
		"best":
			dialog.dialog_text = "Самый выгодный пакет:\n\n• 5000 золотых 🪙\n• 10 бустеров каждого вида 🎮\n• Цена: 9$\n\n(Покупка через платёжную систему\nвременно недоступна)"
	
	dialog.ok_button_text = "Понятно"
	add_child(dialog)
	dialog.popup_centered(Vector2(500, 300))
	
	var _on_close = func():
		if not dialog.is_queued_for_deletion():
			dialog.queue_free()
	
	dialog.confirmed.connect(_on_close)
	dialog.close_requested.connect(_on_close)
