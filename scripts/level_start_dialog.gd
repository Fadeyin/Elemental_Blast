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
var _mort_helmet_section: Control = null
var _mort_helmet_info_button: Button = null
var _mort_helmet_rules_overlay: Control = null
var _mort_helmet_tutorial_overlay: Control = null

func setup():
	_build_dialog()
	_maybe_show_mort_helmet_tutorial()

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
	var close_btn := UiCloseButton.create(func():
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
	
	# Шлем Морта (Win Streak прогресс) — показываем только после открытия фичи (GDD §2,§7)
	if LevelManager and LevelManager.is_mort_helmet_unlocked():
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
	
	var helmet_level: int = LevelManager.mort_helmet_level
	
	# Контейнер всей секции — нужен, чтобы туториал мог подсветить именно её.
	var section := PanelContainer.new()
	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.18, 0.2, 0.28, 0.6)
	section_style.set_corner_radius_all(12)
	section_style.border_width_left = 2
	section_style.border_width_top = 2
	section_style.border_width_right = 2
	section_style.border_width_bottom = 2
	section_style.border_color = Color(0.55, 0.45, 0.7, 0.8)
	section.add_theme_stylebox_override("panel", section_style)
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
	
	var helmet_title := Label.new()
	helmet_title.text = "ШЛЕМ МОРТА"
	helmet_title.add_theme_font_size_override("font_size", 32)
	helmet_title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	helmet_title.add_theme_color_override("font_outline_color", Color.BLACK)
	helmet_title.add_theme_constant_override("outline_size", 4)
	helmet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_row.add_child(helmet_title)
	
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(right_spacer)
	
	var info_btn := Button.new()
	info_btn.text = "i"
	info_btn.custom_minimum_size = Vector2(44, 44)
	info_btn.focus_mode = Control.FOCUS_NONE
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.25, 0.4, 0.6, 0.9)
	info_style.set_corner_radius_all(22)
	info_style.border_width_left = 2
	info_style.border_width_top = 2
	info_style.border_width_right = 2
	info_style.border_width_bottom = 2
	info_style.border_color = Color(0.6, 0.8, 1.0, 1.0)
	info_btn.add_theme_stylebox_override("normal", info_style)
	info_btn.add_theme_stylebox_override("hover", info_style)
	info_btn.add_theme_stylebox_override("pressed", info_style)
	info_btn.add_theme_font_size_override("font_size", 26)
	info_btn.add_theme_color_override("font_color", Color.WHITE)
	info_btn.add_theme_color_override("font_outline_color", Color.BLACK)
	info_btn.add_theme_constant_override("outline_size", 3)
	info_btn.pressed.connect(_show_mort_helmet_rules)
	header_row.add_child(info_btn)
	_mort_helmet_info_button = info_btn
	
	# Визуальное отображение уровня шлема (3 этапа)
	var helmet_progress := HBoxContainer.new()
	helmet_progress.alignment = BoxContainer.ALIGNMENT_CENTER
	helmet_progress.add_theme_constant_override("separation", 15)
	
	for i in range(1, 4):
		var stage := Panel.new()
		stage.custom_minimum_size = Vector2(60, 60)
		
		var stage_style := StyleBoxFlat.new()
		if i <= helmet_level:
			stage_style.bg_color = Color(0.9, 0.7, 0.2, 1.0)
			stage_style.border_color = Color(1.0, 0.9, 0.5, 1.0)
		else:
			stage_style.bg_color = Color(0.3, 0.3, 0.35, 0.5)
			stage_style.border_color = Color(0.5, 0.5, 0.55, 1.0)
		stage_style.set_corner_radius_all(10)
		stage_style.border_width_left = 3
		stage_style.border_width_top = 3
		stage_style.border_width_right = 3
		stage_style.border_width_bottom = 3
		stage.add_theme_stylebox_override("panel", stage_style)
		
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
	bonus_desc.add_theme_font_size_override("font_size", 22)
	bonus_desc.add_theme_color_override("font_outline_color", Color.BLACK)
	bonus_desc.add_theme_constant_override("outline_size", 3)
	bonus_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	if _mort_helmet_rules_overlay != null and is_instance_valid(_mort_helmet_rules_overlay):
		return
	if LevelManager:
		LevelManager.log_mort_helmet_rules_opened()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 220
	add_child(overlay)
	_mort_helmet_rules_overlay = overlay
	
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_mort_helmet_rules()
	)
	overlay.add_child(bg)
	
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -240
	panel.offset_bottom = 240
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.12, 0.15, 0.2, 0.98)
	ps.set_corner_radius_all(18)
	ps.border_width_left = 4
	ps.border_width_top = 4
	ps.border_width_right = 4
	ps.border_width_bottom = 4
	ps.border_color = Color(0.85, 0.72, 0.28, 1.0)
	panel.add_theme_stylebox_override("panel", ps)
	overlay.add_child(panel)
	
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 20
	box.offset_top = 20
	box.offset_right = -20
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	
	var title := Label.new()
	title.text = "ШЛЕМ МОРТА"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	
	var desc := Label.new()
	desc.text = "Побеждайте уровни подряд — стадия Шлема будет расти, а на старт следующего уровня вы получите больше бонусов на поле."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(desc)
	
	for stage_data in [
		{"stage": 1, "text": "1 победа подряд → 1 стрела + 1 бомба"},
		{"stage": 2, "text": "2 победы подряд → 2 стрелы + 2 бомбы"},
		{"stage": 3, "text": "3+ побед подряд → 3 стрелы + 3 бомбы"}
	]:
		var row := Label.new()
		row.text = stage_data["text"]
		row.add_theme_font_size_override("font_size", 22)
		row.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
		row.add_theme_color_override("font_outline_color", Color.BLACK)
		row.add_theme_constant_override("outline_size", 3)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(row)
	
	var hint := Label.new()
	hint.text = "Поражение или выход после хода сбрасывают серию."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.85, 0.65, 0.65))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	
	var close_btn := Button.new()
	close_btn.text = "ПОНЯТНО"
	close_btn.custom_minimum_size = Vector2(220, 64)
	close_btn.focus_mode = Control.FOCUS_NONE
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.25, 0.5, 0.3, 1.0)
	cs.set_corner_radius_all(12)
	cs.border_color = Color(0.4, 0.8, 0.5, 1.0)
	cs.border_width_left = 3
	cs.border_width_top = 3
	cs.border_width_right = 3
	cs.border_width_bottom = 3
	close_btn.add_theme_stylebox_override("normal", cs)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.pressed.connect(_close_mort_helmet_rules)
	var wrap := CenterContainer.new()
	wrap.add_child(close_btn)
	box.add_child(wrap)

func _close_mort_helmet_rules() -> void:
	if _mort_helmet_rules_overlay != null and is_instance_valid(_mort_helmet_rules_overlay):
		_mort_helmet_rules_overlay.queue_free()
	_mort_helmet_rules_overlay = null

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
	call_deferred("_build_mort_helmet_tutorial_overlay")

func _build_mort_helmet_tutorial_overlay() -> void:
	if _mort_helmet_section == null or not is_instance_valid(_mort_helmet_section):
		return
	if _mort_helmet_info_button == null or not is_instance_valid(_mort_helmet_info_button):
		return
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 230
	add_child(overlay)
	_mort_helmet_tutorial_overlay = overlay
	
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_mort_helmet_tutorial()
	)
	overlay.add_child(dim)
	
	# Подсветка плашки Шлема: рамка вокруг секции.
	var section_rect: Rect2 = _mort_helmet_section.get_global_rect()
	section_rect = section_rect.grow(8.0)
	var highlight := Panel.new()
	highlight.position = section_rect.position
	highlight.size = section_rect.size
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(1.0, 0.95, 0.45, 0.12)
	hs.set_corner_radius_all(14)
	hs.border_color = Color(1.0, 0.95, 0.45, 1.0)
	hs.border_width_left = 4
	hs.border_width_top = 4
	hs.border_width_right = 4
	hs.border_width_bottom = 4
	highlight.add_theme_stylebox_override("panel", hs)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(highlight)
	
	# Стрелка-указатель на кнопку "i".
	var info_rect: Rect2 = _mort_helmet_info_button.get_global_rect()
	var arrow := Label.new()
	arrow.text = "▲"
	arrow.add_theme_font_size_override("font_size", 36)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	arrow.add_theme_color_override("font_outline_color", Color.BLACK)
	arrow.add_theme_constant_override("outline_size", 3)
	arrow.position = Vector2(info_rect.position.x + info_rect.size.x * 0.5 - 14, info_rect.position.y + info_rect.size.y + 6)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(arrow)
	
	var hint := Label.new()
	hint.text = "Это Шлем Морта. Побеждайте уровни подряд, чтобы получать бонусы. Нажмите «i», чтобы узнать подробности."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color.WHITE)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(info_rect.position.x - 280, info_rect.position.y + info_rect.size.y + 60)
	hint.size = Vector2(560, 140)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)
	
	if LevelManager:
		LevelManager.mark_mort_helmet_tutorial_shown()

func _close_mort_helmet_tutorial() -> void:
	if _mort_helmet_tutorial_overlay != null and is_instance_valid(_mort_helmet_tutorial_overlay):
		_mort_helmet_tutorial_overlay.queue_free()
	_mort_helmet_tutorial_overlay = null

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
