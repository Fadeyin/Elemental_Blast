extends Control

@onready var play_button: TextureButton = $TabContent/MainTab/PlayButton
@onready var version_label = $VersionLabel

@onready var ranks_level_edit: LineEdit = $TabContent/RanksTab/RanksMargin/RanksVBox/LevelPickRow/LevelNumberEdit
@onready var ranks_minus_btn: Button = $TabContent/RanksTab/RanksMargin/RanksVBox/LevelPickRow/MinusBtn
@onready var ranks_plus_btn: Button = $TabContent/RanksTab/RanksMargin/RanksVBox/LevelPickRow/PlusBtn
@onready var ranks_editor_button: Button = $TabContent/RanksTab/RanksMargin/RanksVBox/RanksEditorButton

@onready var shop_tab = $TabContent/ShopTab
@onready var main_tab = $TabContent/MainTab
@onready var ranks_tab = $TabContent/RanksTab

@onready var bottom_nav_bg: TextureRect = $BottomNav/NavBackground
@onready var shop_btn: TextureButton = $BottomNav/NavRow/ShopItem/Content/VBox/ShopBtn
@onready var main_btn: TextureButton = $BottomNav/NavRow/MainItem/Content/VBox/MainBtn
@onready var ranks_btn: TextureButton = $BottomNav/NavRow/RanksItem/Content/VBox/RanksBtn
@onready var shop_label: Label = $BottomNav/NavRow/ShopItem/Content/VBox/ShopLabel
@onready var main_label: Label = $BottomNav/NavRow/MainItem/Content/VBox/MainLabel
@onready var ranks_label: Label = $BottomNav/NavRow/RanksItem/Content/VBox/RanksLabel
@onready var shop_active_bg: TextureRect = $BottomNav/NavRow/ShopItem/ActiveBg
@onready var main_active_bg: TextureRect = $BottomNav/NavRow/MainItem/ActiveBg
@onready var ranks_active_bg: TextureRect = $BottomNav/NavRow/RanksItem/ActiveBg

# Путь к игровой сцене
const GAME_BOARD_SCENE_PATH = "res://scenes/game_board.tscn"

# Флаг для предотвращения множественного открытия диалога
var _level_start_dialog_shown: bool = false
var _golden_pass_dialog_open: bool = false

const GOLDEN_PASS_DIALOG_SCRIPT := preload("res://scripts/golden_pass_dialog.gd")
const TEX_UI_TOOLBAR_BG := preload("res://textures/ui_main_menu_toolbar_bg.png")
const TEX_UI_BUY_COINS_BTN := preload("res://textures/ui_buy_coins_button.png")
const TEX_UI_PLAY_BTN := preload("res://textures/ui_main_menu_play_button.png")
const TEX_UI_SETTINGS := preload("res://textures/Booster_Hummer.png")
const TEX_UI_GOLDEN_PASS := preload("res://textures/Chip_Bonus_Rainbow_Ball.png")
const TEX_NAV_LEADERBOARD := preload("res://textures/ui_nav_icon_leaderboard.png")
const TEX_NAV_HOME := preload("res://textures/ui_nav_icon_home.png")
const TEX_NAV_SHOP := preload("res://textures/ui_nav_icon_shop.png")
const TEX_BOTTOM_NAV_BG := preload("res://textures/ui_bottom_nav_bg.png")
const TEX_BOTTOM_NAV_ACTIVE := preload("res://textures/ui_bottom_nav_active_bg.png")
const PLAY_BTN_TEX_SIZE := Vector2(1371.0, 474.0)
const NAV_ICON_SIZE := 44.0
const NAV_LABEL_FONT_SIZE := 22
const NAV_ICON_ACTIVE_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const NAV_ICON_INACTIVE_MODULATE := Color(0.18, 0.48, 0.62, 1.0)
const NAV_LABEL_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NAV_LABEL_INACTIVE_COLOR := Color(0.12, 0.36, 0.5, 1.0)
const TOP_BAR_HEIGHT := 62.0
const TOP_BAR_WIDTH := 268.0
const TOP_BAR_MARGIN_LEFT := 10.0
const TOP_BAR_MARGIN_TOP := 18.0
const BUY_COINS_BTN_SIZE := 46.0
const PLAY_BTN_PRESS_SCALE := Vector2(0.92, 0.92)
const UI_SHADOW_COLOR := Color(0, 0, 0, 0.45)
const UI_SHADOW_SIZE := 8
const UI_SHADOW_OFFSET := Vector2(0, 4)
const UI_SHADOW_SIZE_SOFT := 6
const UI_SHADOW_OFFSET_SOFT := Vector2(0, 3)

var _syncing_ranks_level_edit: bool = false
var _play_level_banner: Label = null

func _ready():
	if LevelManager:
		LevelManager.clear_editor_level_override()
	_create_top_bar()
	_create_top_bar_settings()
	if LevelManager:
		LevelManager.tick_golden_pass_daily_login()
	_create_golden_pass_fab()
	
	if is_instance_valid(play_button):
		play_button.pressed.connect(_on_play_pressed)
		_style_play_button()
		_setup_play_button_press_feedback()
	if is_instance_valid(ranks_editor_button):
		ranks_editor_button.pressed.connect(_on_editor_pressed)
		_style_secondary_action_button(ranks_editor_button)
	_setup_ranks_level_controls()
	_apply_bottom_nav_visuals()
	_setup_navigation()
	_update_level_label()
	_update_version_label()
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
		if dlg and dlg.has_method("refresh_from_state"):
			dlg.refresh_from_state()

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
	fab.text = ""
	var fab_icon_wrap := CenterContainer.new()
	fab_icon_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fab_icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fab_icon := TextureRect.new()
	fab_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fab_icon.texture = TEX_UI_GOLDEN_PASS
	fab_icon.custom_minimum_size = Vector2(36, 36)
	fab_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fab_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fab_icon_wrap.add_child(fab_icon)
	fab.add_child(fab_icon_wrap)
	var r := 32
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.78, 0.55, 0.12, 1.0)
	n.set_corner_radius_all(r)
	n.border_width_left = 3
	n.border_width_top = 3
	n.border_width_right = 3
	n.border_width_bottom = 3
	n.border_color = Color(1.0, 0.92, 0.45, 1.0)
	_apply_menu_shadow(n, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	var h := n.duplicate()
	h.bg_color = Color(0.9, 0.68, 0.18, 1.0)
	var p := n.duplicate()
	p.bg_color = Color(0.62, 0.42, 0.08, 1.0)
	fab.add_theme_stylebox_override("normal", n)
	fab.add_theme_stylebox_override("hover", h)
	fab.add_theme_stylebox_override("pressed", p)
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

func _create_top_bar() -> void:
	var top_bar := Control.new()
	top_bar.name = "TopBar"
	top_bar.anchor_left = 0.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_right = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = TOP_BAR_MARGIN_LEFT
	top_bar.offset_top = TOP_BAR_MARGIN_TOP
	top_bar.offset_right = TOP_BAR_MARGIN_LEFT + TOP_BAR_WIDTH
	top_bar.offset_bottom = TOP_BAR_MARGIN_TOP + TOP_BAR_HEIGHT
	top_bar.z_index = 10
	add_child(top_bar)
	move_child(top_bar, 1)
	var top_shadow := _make_shadow_panel(14, Color(0.1, 0.14, 0.18, 0.82), UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	top_shadow.name = "TopBarShadow"
	top_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_bar.add_child(top_shadow)
	var bg := TextureRect.new()
	bg.name = "TopBarBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = TEX_UI_TOOLBAR_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(bg)
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 6.0
	hbox.offset_right = -6.0
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(hbox)
	hbox.add_child(_create_spacer(2))
	hbox.add_child(_create_coins_display())
	hbox.add_child(_create_buy_coins_button())

func _create_top_bar_settings() -> void:
	var settings_btn := _create_settings_button()
	settings_btn.name = "TopBarSettings"
	settings_btn.anchor_left = 1.0
	settings_btn.anchor_top = 0.0
	settings_btn.anchor_right = 1.0
	settings_btn.anchor_bottom = 0.0
	settings_btn.offset_left = -72.0
	settings_btn.offset_top = TOP_BAR_MARGIN_TOP
	settings_btn.offset_right = -10.0
	settings_btn.offset_bottom = TOP_BAR_MARGIN_TOP + 60.0
	settings_btn.z_index = 10
	add_child(settings_btn)

func _create_spacer(width: float) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(width, 0)
	return spacer

func _create_flexible_spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer

func _apply_menu_shadow(style: StyleBoxFlat, shadow_size: int = UI_SHADOW_SIZE, shadow_offset: Vector2 = UI_SHADOW_OFFSET) -> void:
	style.shadow_color = UI_SHADOW_COLOR
	style.shadow_size = shadow_size
	style.shadow_offset = shadow_offset


func _make_shadow_panel(corner_radius: int, bg_color: Color, shadow_size: int = UI_SHADOW_SIZE, shadow_offset: Vector2 = UI_SHADOW_OFFSET) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	_apply_menu_shadow(style, shadow_size, shadow_offset)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_coins_display() -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	var coin_slot := CenterContainer.new()
	coin_slot.custom_minimum_size = Vector2(46, 46)
	var coin_icon := TextureRect.new()
	coin_icon.texture = LevelManager.UI_GOLD_COIN_TEXTURE
	coin_icon.custom_minimum_size = Vector2(42, 42)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_slot.add_child(coin_icon)
	container.add_child(coin_slot)
	
	var coins_label = Label.new()
	coins_label.name = "TopBarCoinsCount"
	var coins = LevelManager.get_coins() if LevelManager else 0
	coins_label.text = str(coins)
	coins_label.add_theme_font_size_override("font_size", 28)
	coins_label.add_theme_color_override("font_color", Color(0.34, 0.20, 0.0, 1.0))
	coins_label.add_theme_color_override("font_outline_color", Color(0.92, 0.78, 0.38, 0.55))
	coins_label.add_theme_constant_override("outline_size", 2)
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(coins_label)
	
	return container

func _create_buy_coins_button() -> TextureButton:
	var btn := TextureButton.new()
	btn.texture_normal = TEX_UI_BUY_COINS_BTN
	btn.texture_pressed = TEX_UI_BUY_COINS_BTN
	btn.texture_hover = TEX_UI_BUY_COINS_BTN
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(BUY_COINS_BTN_SIZE, BUY_COINS_BTN_SIZE)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_buy_coins_pressed)
	return btn

func _create_settings_button() -> Button:
	var btn = Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(60, 60)
	var settings_icon_wrap := CenterContainer.new()
	settings_icon_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var settings_icon := TextureRect.new()
	settings_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_icon.texture = TEX_UI_SETTINGS
	settings_icon.custom_minimum_size = Vector2(40, 40)
	settings_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	settings_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	settings_icon_wrap.add_child(settings_icon)
	btn.add_child(settings_icon_wrap)
	
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
	_apply_menu_shadow(normal_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.35, 0.4, 0.45, 1.0)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.25, 0.3, 1.0)
	_apply_menu_shadow(hover_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	_apply_menu_shadow(pressed_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
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

func _ensure_bottom_nav_shadow() -> void:
	if not is_instance_valid(bottom_nav_bg):
		return
	var bottom_nav: Control = bottom_nav_bg.get_parent() as Control
	if bottom_nav == null:
		return
	var existing := bottom_nav.get_node_or_null("NavShadow")
	if existing != null:
		return
	var nav_shadow := _make_shadow_panel(24, Color(0.08, 0.1, 0.12, 0.9), UI_SHADOW_SIZE, UI_SHADOW_OFFSET)
	nav_shadow.name = "NavShadow"
	nav_shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom_nav.add_child(nav_shadow)
	bottom_nav.move_child(nav_shadow, 0)


func _apply_bottom_nav_visuals() -> void:
	_ensure_bottom_nav_shadow()
	if is_instance_valid(bottom_nav_bg):
		bottom_nav_bg.texture = TEX_BOTTOM_NAV_BG
		bottom_nav_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bottom_nav_bg.stretch_mode = TextureRect.STRETCH_SCALE
	for active_bg in [shop_active_bg, main_active_bg, ranks_active_bg]:
		if is_instance_valid(active_bg):
			active_bg.texture = TEX_BOTTOM_NAV_ACTIVE
			active_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			active_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_style_nav_texture_button(shop_btn, TEX_NAV_SHOP)
	_style_nav_texture_button(main_btn, TEX_NAV_HOME)
	_style_nav_texture_button(ranks_btn, TEX_NAV_LEADERBOARD)
	for nav_label in [shop_label, main_label, ranks_label]:
		if is_instance_valid(nav_label):
			nav_label.add_theme_font_size_override("font_size", NAV_LABEL_FONT_SIZE)
			nav_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.35))
			nav_label.add_theme_constant_override("outline_size", 1)
			nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nav_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _style_nav_texture_button(btn: TextureButton, tex: Texture2D) -> void:
	if not is_instance_valid(btn):
		return
	btn.texture_normal = tex
	btn.texture_pressed = tex
	btn.texture_hover = tex
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(NAV_ICON_SIZE, NAV_ICON_SIZE)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE

func _setup_navigation():
	shop_btn.pressed.connect(func(): _switch_tab("shop"))
	main_btn.pressed.connect(func(): _switch_tab("main"))
	ranks_btn.pressed.connect(func(): _switch_tab("ranks"))

func _switch_tab(tab_name: String):
	shop_tab.visible = (tab_name == "shop")
	main_tab.visible = (tab_name == "main")
	ranks_tab.visible = (tab_name == "ranks")
	if tab_name == "ranks":
		_sync_ranks_level_field_from_manager()
	_update_nav_highlight(tab_name)

func _update_nav_highlight(tab_name: String) -> void:
	var entries := {
		"shop": {"btn": shop_btn, "bg": shop_active_bg, "label": shop_label},
		"main": {"btn": main_btn, "bg": main_active_bg, "label": main_label},
		"ranks": {"btn": ranks_btn, "bg": ranks_active_bg, "label": ranks_label},
	}
	for key in entries.keys():
		var entry: Dictionary = entries[key]
		var btn: TextureButton = entry["btn"]
		var active_bg: TextureRect = entry["bg"]
		var nav_label: Label = entry["label"]
		if not is_instance_valid(btn) or not is_instance_valid(active_bg):
			continue
		var is_active: bool = str(key) == tab_name
		active_bg.visible = is_active
		btn.scale = Vector2.ONE
		btn.modulate = NAV_ICON_ACTIVE_MODULATE if is_active else NAV_ICON_INACTIVE_MODULATE
		if is_instance_valid(nav_label):
			nav_label.add_theme_color_override("font_color", NAV_LABEL_ACTIVE_COLOR if is_active else NAV_LABEL_INACTIVE_COLOR)

func _on_play_pressed():
	LevelManager.set_current_level(LevelManager.current_level)
	_show_level_start_dialog(LevelManager.current_level)

func _on_editor_pressed():
	get_tree().change_scene_to_file("res://scenes/level_editor.tscn")



func _style_ranks_control_button(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.38, 0.52, 1.0)
	normal.set_corner_radius_all(16)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.45, 0.62, 0.85, 1.0)
	_apply_menu_shadow(normal)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.32, 0.48, 0.62, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.16, 0.3, 0.45, 1.0)
	_apply_menu_shadow(hover)
	_apply_menu_shadow(pressed)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_font_size_override("font_size", 32)


func _style_ranks_level_edit() -> void:
	if not is_instance_valid(ranks_level_edit):
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.16, 0.2, 0.95)
	normal.set_corner_radius_all(14)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.4, 0.55, 0.7, 1.0)
	_apply_menu_shadow(normal, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	var focus := normal.duplicate()
	focus.border_color = Color(0.55, 0.75, 0.95, 1.0)
	ranks_level_edit.add_theme_stylebox_override("normal", normal)
	ranks_level_edit.add_theme_stylebox_override("focus", focus)
	ranks_level_edit.add_theme_font_size_override("font_size", 28)

func _setup_ranks_level_controls() -> void:
	if is_instance_valid(ranks_minus_btn):
		ranks_minus_btn.pressed.connect(_on_ranks_level_step.bind(-1))
	if is_instance_valid(ranks_plus_btn):
		ranks_plus_btn.pressed.connect(_on_ranks_level_step.bind(1))
	if is_instance_valid(ranks_level_edit):
		ranks_level_edit.text_submitted.connect(_on_ranks_level_submitted)
		ranks_level_edit.focus_exited.connect(_on_ranks_level_focus_exited)
	_style_ranks_control_button(ranks_minus_btn)
	_style_ranks_control_button(ranks_plus_btn)
	_style_ranks_level_edit()
	_sync_ranks_level_field_from_manager()

func _get_max_selectable_level() -> int:
	if LevelManager:
		return LevelManager.get_max_level_number()
	return 1

func _clamp_level_choice(value: int) -> int:
	return clampi(value, 1, _get_max_selectable_level())

func _sync_ranks_level_field_from_manager() -> void:
	if not is_instance_valid(ranks_level_edit) or not LevelManager:
		return
	var lvl := _clamp_level_choice(LevelManager.current_level)
	_syncing_ranks_level_edit = true
	ranks_level_edit.text = str(lvl)
	_syncing_ranks_level_edit = false

func _on_ranks_level_submitted(_text: String) -> void:
	_apply_ranks_level_from_field(true)

func _on_ranks_level_focus_exited() -> void:
	_apply_ranks_level_from_field(true)

func _apply_ranks_level_from_field(force_valid: bool) -> void:
	if not LevelManager or not is_instance_valid(ranks_level_edit):
		return
	var raw := ranks_level_edit.text.strip_edges()
	if raw.is_empty():
		if force_valid:
			_sync_ranks_level_field_from_manager()
		return
	if not raw.is_valid_int():
		if force_valid:
			_sync_ranks_level_field_from_manager()
		return
	var parsed := int(raw)
	var clamped := _clamp_level_choice(parsed)
	LevelManager.set_current_level(clamped)
	_update_level_label()
	if clamped != parsed or force_valid:
		_sync_ranks_level_field_from_manager()

func _on_ranks_level_step(delta: int) -> void:
	if not LevelManager:
		return
	var max_lvl := _get_max_selectable_level()
	var next := clampi(LevelManager.current_level + delta, 1, max_lvl)
	LevelManager.set_current_level(next)
	_update_level_label()
	_sync_ranks_level_field_from_manager()

func _style_secondary_action_button(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.22, 0.38, 0.52, 1.0)
	normal_style.corner_radius_top_left = 16
	normal_style.corner_radius_top_right = 16
	normal_style.corner_radius_bottom_left = 16
	normal_style.corner_radius_bottom_right = 16
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_color = Color(0.45, 0.62, 0.85, 1.0)
	_apply_menu_shadow(normal_style)
	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.32, 0.48, 0.62, 1.0)
	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.16, 0.3, 0.45, 1.0)
	_apply_menu_shadow(hover_style)
	_apply_menu_shadow(pressed_style)
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	btn.add_theme_constant_override("outline_size", 3)

func _style_play_button() -> void:
	if not is_instance_valid(play_button):
		return
	play_button.texture_normal = TEX_UI_PLAY_BTN
	play_button.texture_pressed = TEX_UI_PLAY_BTN
	play_button.texture_hover = TEX_UI_PLAY_BTN
	play_button.ignore_texture_size = true
	play_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	var btn_w := 400.0
	var btn_h := btn_w * PLAY_BTN_TEX_SIZE.y / PLAY_BTN_TEX_SIZE.x
	play_button.custom_minimum_size = Vector2(btn_w, btn_h)
	var bottom_gap := 142.0
	play_button.offset_left = -btn_w * 0.5
	play_button.offset_right = btn_w * 0.5
	play_button.offset_top = -bottom_gap - btn_h
	play_button.offset_bottom = -bottom_gap
	play_button.z_index = 2
	_ensure_play_button_shadow()
	_ensure_play_level_banner()
	call_deferred("_update_play_button_pivot")



func _ensure_play_button_shadow() -> void:
	if not is_instance_valid(play_button):
		return
	var parent: Control = play_button.get_parent() as Control
	if parent == null:
		return
	var shadow: PanelContainer = parent.get_node_or_null("PlayButtonShadow") as PanelContainer
	if shadow == null:
		shadow = _make_shadow_panel(28, Color(0.1, 0.42, 0.18, 0.55), UI_SHADOW_SIZE, UI_SHADOW_OFFSET)
		shadow.name = "PlayButtonShadow"
		parent.add_child(shadow)
		parent.move_child(shadow, play_button.get_index())
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shadow.anchor_left = play_button.anchor_left
	shadow.anchor_top = play_button.anchor_top
	shadow.anchor_right = play_button.anchor_right
	shadow.anchor_bottom = play_button.anchor_bottom
	shadow.offset_left = play_button.offset_left
	shadow.offset_top = play_button.offset_top
	shadow.offset_right = play_button.offset_right
	shadow.offset_bottom = play_button.offset_bottom
	shadow.grow_horizontal = play_button.grow_horizontal
	shadow.grow_vertical = play_button.grow_vertical
	shadow.z_index = play_button.z_index - 1
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_play_level_banner_style(label: Label) -> void:
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 54)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.22, 0.1, 0.75))
	label.add_theme_constant_override("outline_size", 2)
	label.set_meta(&"game_fonts_heavy", true)


func _ensure_play_level_banner() -> void:
	if not is_instance_valid(play_button):
		return
	var old_on_tab := main_tab.get_node_or_null("PlayLevelBanner") if is_instance_valid(main_tab) else null
	if old_on_tab != null:
		old_on_tab.queue_free()
	var overlay := play_button.get_node_or_null("PlayLevelOverlay") as Control
	if overlay == null:
		overlay = Control.new()
		overlay.name = "PlayLevelOverlay"
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_button.add_child(overlay)
	var existing := overlay.get_node_or_null("PlayLevelBanner") as Label
	if existing != null:
		_play_level_banner = existing
	else:
		_play_level_banner = Label.new()
		_play_level_banner.name = "PlayLevelBanner"
		_play_level_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(_play_level_banner)
	_apply_play_level_banner_style(_play_level_banner)
	call_deferred("_refresh_play_level_banner")


func _setup_play_button_press_feedback() -> void:
	if not is_instance_valid(play_button):
		return
	if play_button.button_down.is_connected(_on_play_button_down):
		return
	play_button.button_down.connect(_on_play_button_down)
	play_button.button_up.connect(_on_play_button_up)
	play_button.focus_exited.connect(_on_play_button_up)

func _update_play_button_pivot() -> void:
	if is_instance_valid(play_button):
		play_button.pivot_offset = play_button.size * 0.5

func _on_play_button_down() -> void:
	if not is_instance_valid(play_button):
		return
	_update_play_button_pivot()
	play_button.modulate = Color(0.86, 0.86, 0.86, 1.0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(play_button, "scale", PLAY_BTN_PRESS_SCALE, 0.07)

func _on_play_button_up() -> void:
	if not is_instance_valid(play_button):
		return
	play_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(play_button, "scale", Vector2.ONE, 0.11)

func _update_level_label() -> void:
	var lvl := LevelManager.current_level if LevelManager else 1
	_ensure_play_level_banner()
	if _play_level_banner != null and is_instance_valid(_play_level_banner):
		_play_level_banner.text = "Уровень %d" % lvl
		_refresh_play_level_banner()

func _refresh_play_level_banner() -> void:
	if _play_level_banner == null or not is_instance_valid(_play_level_banner):
		return
	_play_level_banner.queue_redraw()


func _update_version_label():
	if is_instance_valid(version_label):
		var ver = VersionManager.get_version() if VersionManager else "0.1"
		version_label.text = "v" + str(ver)
		version_label.add_theme_font_size_override("font_size", 18)
		version_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.8))
		version_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
		version_label.add_theme_constant_override("outline_size", 2)

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
	var err := get_tree().change_scene_to_file(GAME_BOARD_SCENE_PATH)
	if err != OK:
		push_error("Не удалось загрузить сцену игрового поля: код ", err)
		_show_fatal_scene_switch_dialog(GAME_BOARD_SCENE_PATH, err)

func _show_fatal_scene_switch_dialog(scene_path: String, err_code: int) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Ошибка сцены"
	dlg.dialog_text = "Не удалось открыть игру (%s).\nКод ошибки Godot: %s." % [scene_path, str(err_code)]
	dlg.ok_button_text = "ОК"
	add_child(dlg)
	dlg.popup_centered_ratio(0.85)
	dlg.confirmed.connect(func(): dlg.queue_free())

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
	scroll.add_theme_constant_override("margin_top", 36)
	scroll.add_theme_constant_override("margin_bottom", 20)
	shop_tab_node.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "МАГАЗИН"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	title.add_theme_constant_override("outline_size", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(_create_spacer_v(20))
	
	if not LevelManager.is_starter_pack_purchased():
		var starter = _create_shop_offer(
			"СТАРТОВЫЙ ПАКЕТ",
			"Специальное предложение!",
			["1000 золотых", "4 бустера каждого вида"],
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
		["2500 золотых", "5 бустеров каждого вида"],
		"5$",
		Color(0.2, 0.5, 0.8, 1.0),
		"medium",
		false
	)
	vbox.add_child(medium)
	vbox.add_child(_create_spacer_v(15))
	
	var best = _create_shop_offer(
		"САМЫЙ ВЫГОДНЫЙ",
		"Лучшее предложение!",
		["5000 золотых", "10 бустеров каждого вида"],
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
	_apply_menu_shadow(bg_style, 10, Vector2(0, 5))
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
	title_label.add_theme_constant_override("outline_size", 2)
	content_vbox.add_child(title_label)
	
	var subtitle_label = Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	content_vbox.add_child(subtitle_label)
	
	content_vbox.add_child(_create_spacer_v(5))
	
	for item in items:
		var item_label = Label.new()
		item_label.text = "  - " + item
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
	_apply_menu_shadow(btn_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	
	var pressed_style = btn_style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	_apply_menu_shadow(hover_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	_apply_menu_shadow(pressed_style, UI_SHADOW_SIZE_SOFT, UI_SHADOW_OFFSET_SOFT)
	
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", hover_style)
	buy_btn.add_theme_stylebox_override("pressed", pressed_style)
	buy_btn.add_theme_font_size_override("font_size", 40)
	buy_btn.add_theme_color_override("font_color", Color.WHITE)
	buy_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	buy_btn.add_theme_constant_override("outline_size", 2)
	
	buy_btn.pressed.connect(_on_shop_purchase.bind(pack_type))
	hbox.add_child(buy_btn)
	
	hbox.add_child(_create_spacer(15))
	
	if is_special:
		var badge = Label.new()
		badge.text = "ТОЛЬКО 1 РАЗ!"
		badge.add_theme_font_size_override("font_size", 16)
		badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		badge.add_theme_color_override("font_outline_color", Color(0.5, 0.2, 0.0))
		badge.add_theme_constant_override("outline_size", 2)
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
