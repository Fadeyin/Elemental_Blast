extends Control

class_name LevelEditor

const COLS := 8
const ENEMY_ROWS := 10
const ROWS := 16
const LEVEL_PATH_TEMPLATE := "res://levels/level_%03d.json"
const MONSTER_TEXTURES := {
	1: preload("res://textures/Monster_1_lvl.png"),
	2: preload("res://textures/Monster_2_lvl.png"),
	3: preload("res://textures/Monster_3_lvl.png"),
	4: preload("res://textures/Monster_4_lvl.png"),
	5: preload("res://textures/Monster_5_lvl.png")
}
const OBSTACLE_COLOR := Color(0.4, 0.35, 0.3, 1.0)
const WALL_COLOR := Color(0.36, 0.38, 0.45, 1.0)

enum BrushMode { START_MONSTER, SCHEDULED_MONSTER, OBSTACLE, ERASE }

var _level_data := {}
var _current_file_path := ""
var _current_level_number: int = 1
var _dirty: bool = false
var _brush_mode: int = BrushMode.START_MONSTER
var _selected_hp: int = 1
var _selected_obstacle_hp: int = 2
var _selected_spawn_delay: int = 1
var _selected_spawn_count: int = 1
var _selected_cell := Vector2i(0, 0)
var _entity_refs := []
var _pending_level_switch: int = -1
var _grid_zoom: float = 1.0
const GRID_ZOOM_MIN := 0.7
const GRID_ZOOM_MAX := 2.0

@onready var _level_spin: SpinBox = $Root/TopActions/LevelSpin
@onready var _mode_option: OptionButton = $Root/ToolsScroll/Tools/ModeOption
@onready var _monster_hp_spin: SpinBox = $Root/ToolsScroll/Tools/MonsterHpSpin
@onready var _obstacle_hp_spin: SpinBox = $Root/ToolsScroll/Tools/ObstacleHpSpin
@onready var _spawn_delay_spin: SpinBox = $Root/ToolsScroll/Tools/SpawnDelaySpin
@onready var _spawn_count_spin: SpinBox = $Root/ToolsScroll/Tools/SpawnCountSpin
@onready var _moves_spin: SpinBox = $Root/ToolsScroll/Tools/MovesSpin
@onready var _obstacle_type_option: OptionButton = $Root/ToolsScroll/Tools/ObstacleTypeOption
@onready var _spawn_on_break_check: CheckBox = $Root/ToolsScroll/Tools/SpawnOnBreakCheck
@onready var _spawn_on_break_hp_spin: SpinBox = $Root/ToolsScroll/Tools/SpawnOnBreakHpSpin
@onready var _spawn_on_break_count_spin: SpinBox = $Root/ToolsScroll/Tools/SpawnOnBreakCountSpin
@onready var _grid: GridContainer = $Root/CenterPanel/CenterWrap/GridWrap/Grid
@onready var _status_label: Label = $Root/BottomPanel/StatusLabel
@onready var _counts_label: Label = $Root/BottomPanel/CountsLabel
@onready var _only_selected_check: CheckBox = $Root/BottomPanel/OnlySelectedCheck
@onready var _selected_cell_label: Label = $Root/BottomPanel/SelectedCellLabel
@onready var _entities_list: ItemList = $Root/BottomPanel/EntitiesList
@onready var _confirm_switch: ConfirmationDialog = $ConfirmSwitchDialog

func _ready() -> void:
	_level_data = _new_level_template()
	_init_controls()
	_build_grid()
	_connect_buttons()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_autoload_current_level()

func _new_level_template() -> Dictionary:
	return {
		"cols": COLS,
		"rows": ROWS,
		"enemy_rows": ENEMY_ROWS,
		"moves": 20,
		"start_monsters": [],
		"scheduled_spawns": [],
		"obstacles": [],
		"seed": int(Time.get_unix_time_from_system())
	}

func _init_controls() -> void:
	_mode_option.clear()
	_mode_option.add_item("Стартовый монстр")
	_mode_option.add_item("Отложенный монстр")
	_mode_option.add_item("Препятствие")
	_mode_option.add_item("Ластик")
	_mode_option.item_selected.connect(func(i: int):
		_brush_mode = i
		_refresh_ui()
	)

	_obstacle_type_option.clear()
	_obstacle_type_option.add_item("Разрушаемое")
	_obstacle_type_option.add_item("Неразрушаемое")
	_spawn_on_break_check.toggled.connect(func(_v: bool): _refresh_ui())

	_monster_hp_spin.value_changed.connect(func(v: float): _selected_hp = max(1, int(v)))
	_obstacle_hp_spin.value_changed.connect(func(v: float): _selected_obstacle_hp = max(1, int(v)))
	_spawn_delay_spin.value_changed.connect(func(v: float): _selected_spawn_delay = max(0, int(v)))
	_spawn_count_spin.value_changed.connect(func(v: float): _selected_spawn_count = max(1, int(v)))
	_spawn_on_break_hp_spin.value_changed.connect(func(_v: float): pass)
	_spawn_on_break_count_spin.value_changed.connect(func(_v: float): pass)
	_moves_spin.value_changed.connect(func(v: float):
		_level_data["moves"] = max(1, int(v))
		_dirty = true
	)
	_only_selected_check.toggled.connect(func(_v: bool): _refresh_entity_list())

	_level_spin.min_value = 1
	_level_spin.max_value = 999

	for s in [_level_spin, _monster_hp_spin, _obstacle_hp_spin, _spawn_delay_spin, _spawn_count_spin, _moves_spin, _spawn_on_break_hp_spin, _spawn_on_break_count_spin]:
		s.editable = false

	for c in [
		$Root/TopActions/NewButton,
		$Root/TopActions/PrevLevelButton,
		$Root/TopActions/GoToLevelButton,
		$Root/TopActions/NextLevelButton,
		$Root/TopActions/LoadButton,
		$Root/TopActions/SaveButton,
		$Root/TopActions/ExportJsonButton,
		$Root/TopActions/ExportZipButton,
		$Root/TopActions/CopyJsonButton,
		$Root/TopActions/TestButton,
		$Root/TopActions/BackButton,
		_mode_option,
		_monster_hp_spin,
		_obstacle_hp_spin,
		_spawn_delay_spin,
		_spawn_count_spin,
		_moves_spin,
		_obstacle_type_option,
		_spawn_on_break_check,
		_spawn_on_break_hp_spin,
		_spawn_on_break_count_spin
	]:
		if c is Control:
			c.add_theme_font_size_override("font_size", 14)
			if c is BaseButton:
				c.custom_minimum_size.y = 34

	_confirm_switch.dialog_text = "Сохранить текущий уровень перед переходом?"
	_confirm_switch.get_ok_button().text = "Сохранить и перейти"
	var discard_btn = _confirm_switch.add_button("Перейти без сохранения", false, "discard")
	discard_btn.pressed.connect(_on_switch_discard_pressed)
	_confirm_switch.confirmed.connect(_on_switch_save_pressed)

func _build_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_grid.columns = COLS
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(72, 50)
			btn.focus_mode = Control.FOCUS_NONE
			btn.flat = false
			btn.clip_contents = true
			btn.pressed.connect(_on_cell_pressed.bind(x, y))
			var icon := TextureRect.new()
			icon.name = "MonsterIcon"
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_left = 6
			icon.offset_top = 4
			icon.offset_right = -6
			icon.offset_bottom = -16
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(icon)

			var hp_bg := ColorRect.new()
			hp_bg.name = "HpBg"
			hp_bg.anchor_left = 0.15
			hp_bg.anchor_top = 1.0
			hp_bg.anchor_right = 0.85
			hp_bg.anchor_bottom = 1.0
			hp_bg.offset_top = -12
			hp_bg.offset_bottom = -6
			hp_bg.color = Color(0.1, 0.1, 0.1, 0.6)
			hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(hp_bg)

			var hp_fg := ColorRect.new()
			hp_fg.name = "HpFg"
			hp_fg.anchor_left = 0.15
			hp_fg.anchor_top = 1.0
			hp_fg.anchor_right = 0.85
			hp_fg.anchor_bottom = 1.0
			hp_fg.offset_top = -12
			hp_fg.offset_bottom = -6
			hp_fg.color = Color(0.25, 0.8, 0.3, 0.95)
			hp_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(hp_fg)

			var top_label := Label.new()
			top_label.name = "TopLabel"
			top_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			top_label.offset_left = 4
			top_label.offset_top = 2
			top_label.add_theme_font_size_override("font_size", 12)
			top_label.add_theme_color_override("font_color", Color.WHITE)
			top_label.add_theme_color_override("font_outline_color", Color.BLACK)
			top_label.add_theme_constant_override("outline_size", 2)
			top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(top_label)
			_grid.add_child(btn)
	_resize_grid_cells()

func _connect_buttons() -> void:
	$Root/TopActions/NewButton.pressed.connect(_on_new_pressed)
	$Root/TopActions/LoadButton.pressed.connect(_on_load_pressed)
	$Root/TopActions/SaveButton.pressed.connect(_on_save_pressed)
	$Root/TopActions/ExportJsonButton.pressed.connect(_on_export_json_pressed)
	$Root/TopActions/ExportZipButton.pressed.connect(_on_export_zip_pressed)
	$Root/TopActions/CopyJsonButton.pressed.connect(_on_copy_json_pressed)
	$Root/TopActions/TestButton.pressed.connect(_on_test_pressed)
	$Root/TopActions/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Root/TopActions/PrevLevelButton.pressed.connect(func(): _request_level_switch(_current_level_number - 1))
	$Root/TopActions/NextLevelButton.pressed.connect(func(): _request_level_switch(_current_level_number + 1))
	$Root/BottomPanel/DeleteSelectedEntityButton.pressed.connect(_on_delete_selected_entity)
	$Root/TopActions/GoToLevelButton.pressed.connect(func(): _request_level_switch(int(_level_spin.value)))
	for b in [
		$Root/TopActions/NewButton,
		$Root/TopActions/PrevLevelButton,
		$Root/TopActions/GoToLevelButton,
		$Root/TopActions/NextLevelButton,
		$Root/TopActions/LoadButton,
		$Root/TopActions/SaveButton,
		$Root/TopActions/ExportJsonButton,
		$Root/TopActions/ExportZipButton,
		$Root/TopActions/CopyJsonButton,
		$Root/TopActions/TestButton,
		$Root/TopActions/BackButton
	]:
		b.custom_minimum_size = Vector2(0, 48)

func _autoload_current_level() -> void:
	_current_level_number = max(1, int(LevelManager.current_level))
	_level_spin.value = _current_level_number
	_load_level_by_number(_current_level_number)

func _request_level_switch(next_level: int) -> void:
	next_level = max(1, next_level)
	if next_level == _current_level_number:
		return
	if _dirty:
		_pending_level_switch = next_level
		_confirm_switch.popup_centered(Vector2(520, 180))
		return
	_apply_level_switch(next_level)

func _on_switch_save_pressed() -> void:
	_save_to_path(_path_for_level(_current_level_number))
	if _pending_level_switch > 0:
		_apply_level_switch(_pending_level_switch)
	_pending_level_switch = -1

func _on_switch_discard_pressed() -> void:
	if _pending_level_switch > 0:
		_apply_level_switch(_pending_level_switch)
	_pending_level_switch = -1
	_confirm_switch.hide()

func _apply_level_switch(level_num: int) -> void:
	_current_level_number = level_num
	_level_spin.value = level_num
	_load_level_by_number(level_num)

func _path_for_level(level_num: int) -> String:
	return LEVEL_PATH_TEMPLATE % level_num

func _load_level_by_number(level_num: int) -> void:
	var path = _path_for_level(level_num)
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				_level_data = parsed
	else:
		_level_data = _new_level_template()
	_current_file_path = path
	_level_data["start_monsters"] = _level_data.get("start_monsters", [])
	_level_data["scheduled_spawns"] = _level_data.get("scheduled_spawns", [])
	_level_data["obstacles"] = _level_data.get("obstacles", [])
	_level_data["moves"] = int(_level_data.get("moves", 20))
	_moves_spin.value = _level_data["moves"]
	_dirty = false
	_refresh_ui()

func _on_new_pressed() -> void:
	_level_data = _new_level_template()
	_dirty = true
	_refresh_ui()

func _on_load_pressed() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.add_filter("*.json", "JSON level")
	dlg.file_selected.connect(func(path: String):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			f.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				_level_data = parsed
				_current_file_path = path
				_level_data["start_monsters"] = _level_data.get("start_monsters", [])
				_level_data["scheduled_spawns"] = _level_data.get("scheduled_spawns", [])
				_level_data["obstacles"] = _level_data.get("obstacles", [])
				_level_data["moves"] = int(_level_data.get("moves", 20))
				_moves_spin.value = _level_data["moves"]
				_dirty = false
				_refresh_ui()
		dlg.queue_free()
	)
	add_child(dlg)
	dlg.popup_centered_ratio(0.85)

func _on_save_pressed() -> void:
	_save_to_path(_path_for_level(_current_level_number))

func _save_to_path(path: String) -> void:
	_level_data["cols"] = COLS
	_level_data["rows"] = ROWS
	_level_data["enemy_rows"] = ENEMY_ROWS
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return
	f.store_string(JSON.stringify(_level_data, "\t"))
	f.close()
	_current_file_path = path
	_dirty = false
	_refresh_ui()

func _on_test_pressed() -> void:
	var temp_path = "user://editor_preview_level.json"
	_save_to_path(temp_path)
	LevelManager.begin_editor_test(temp_path, _current_level_number)
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")

func _on_export_json_pressed() -> void:
	var export_dir = "user://exports"
	DirAccess.make_dir_recursive_absolute(export_dir)
	var path = "%s/level_%03d.json" % [export_dir, _current_level_number]
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		_status_label.text = "Экспорт JSON не удался"
		return
	f.store_string(JSON.stringify(_level_data, "\t"))
	f.close()
	_status_label.text = "JSON сохранен: %s" % path

func _on_export_zip_pressed() -> void:
	var export_dir = "user://exports"
	DirAccess.make_dir_recursive_absolute(export_dir)
	var zip_path = "%s/levels_pack.zip" % export_dir
	var zipper := ZIPPacker.new()
	if zipper.open(zip_path) != OK:
		_status_label.text = "Не удалось создать ZIP"
		return
	var levels = LevelManager.get_available_level_numbers()
	for n in levels:
		var src_path = LEVEL_PATH_TEMPLATE % int(n)
		if not FileAccess.file_exists(src_path):
			continue
		var f = FileAccess.open(src_path, FileAccess.READ)
		if not f:
			continue
		var content = f.get_as_text()
		f.close()
		var inner_path = "levels/level_%03d.json" % int(n)
		if zipper.start_file(inner_path) == OK:
			zipper.write_file(content.to_utf8_buffer())
			zipper.close_file()
	zipper.close()
	_status_label.text = "ZIP сохранен: %s" % zip_path

func _on_copy_json_pressed() -> void:
	DisplayServer.clipboard_set(JSON.stringify(_level_data, "\t"))
	_status_label.text = "JSON скопирован в буфер обмена"

func _on_cell_pressed(x: int, y: int) -> void:
	_selected_cell = Vector2i(x, y)
	match _brush_mode:
		BrushMode.START_MONSTER:
			_level_data["start_monsters"].append({"x": x, "y": y, "hp": _selected_hp})
			_dirty = true
		BrushMode.SCHEDULED_MONSTER:
			_level_data["scheduled_spawns"].append({
				"x": x, "y": y, "hp": _selected_hp, "count": _selected_spawn_count,
				"spawn_after_player_turns": _selected_spawn_delay
			})
			_dirty = true
		BrushMode.OBSTACLE:
			_erase_obstacle(x, y)
			var obs = {
				"x": x, "y": y,
				"type": ("wall" if _obstacle_type_option.selected == 1 else "breakable"),
				"hp": _selected_obstacle_hp
			}
			if _spawn_on_break_check.button_pressed:
				obs["spawn_on_destroy"] = {
					"hp": int(_spawn_on_break_hp_spin.value),
					"count": int(_spawn_on_break_count_spin.value)
				}
			_level_data["obstacles"].append(obs)
			_dirty = true
		BrushMode.ERASE:
			_erase_cell_full(x, y)
			_dirty = true
	_refresh_ui()

func _erase_obstacle(x: int, y: int) -> void:
	var next := []
	for o in _level_data["obstacles"]:
		if int(o.get("x", -1)) == x and int(o.get("y", -1)) == y:
			continue
		next.append(o)
	_level_data["obstacles"] = next

func _erase_cell_full(x: int, y: int) -> void:
	var next_start := []
	for m in _level_data["start_monsters"]:
		if int(m.get("x", -1)) == x and int(m.get("y", -1)) == y:
			continue
		next_start.append(m)
	_level_data["start_monsters"] = next_start

	var next_sched := []
	for s in _level_data["scheduled_spawns"]:
		if int(s.get("x", -1)) == x and int(s.get("y", -1)) == y:
			continue
		next_sched.append(s)
	_level_data["scheduled_spawns"] = next_sched
	_erase_obstacle(x, y)

func _refresh_ui() -> void:
	_mode_option.select(_brush_mode)
	_level_spin.value = _current_level_number
	_status_label.text = "Уровень %d | Файл: %s%s" % [_current_level_number, _current_file_path, (" *" if _dirty else "")]
	_selected_cell_label.text = "Выбрана ячейка: (%d, %d)" % [_selected_cell.x, _selected_cell.y]

	var start_total = _level_data["start_monsters"].size()
	var sched_total = _level_data["scheduled_spawns"].size()
	var obstacles_total = _level_data["obstacles"].size()
	_counts_label.text = "Стартовых: %d | Отложенных: %d | Препятствий: %d" % [start_total, sched_total, obstacles_total]

	_refresh_grid_visuals()
	_refresh_entity_list()
	_resize_grid_cells()

func _on_viewport_size_changed() -> void:
	_resize_grid_cells()

func _resize_grid_cells() -> void:
	if _grid == null:
		return
	var wrap: Control = $Root/CenterPanel/CenterWrap/GridWrap
	if wrap == null:
		return
	var avail = wrap.size
	if avail.x <= 0 or avail.y <= 0:
		return
	var spacing_x = float(_grid.get_theme_constant("h_separation"))
	var spacing_y = float(_grid.get_theme_constant("v_separation"))
	var cell_w = floor((avail.x - spacing_x * float(COLS - 1)) / float(COLS))
	var cell_h = floor((avail.y - spacing_y * float(ENEMY_ROWS - 1)) / float(ENEMY_ROWS))
	var side = int(max(44.0, min(cell_w, cell_h)))
	for c in _grid.get_children():
		if c is Button:
			c.custom_minimum_size = Vector2(side, side * 0.72)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		_grid_zoom = clamp(_grid_zoom * event.factor, GRID_ZOOM_MIN, GRID_ZOOM_MAX)
		var wrap: Control = $Root/CenterPanel/CenterWrap/GridWrap
		if wrap:
			wrap.scale = Vector2(_grid_zoom, _grid_zoom)

func _refresh_grid_visuals() -> void:
	var start_map := {}
	var sched_map := {}
	var obstacle_map := {}

	for m in _level_data["start_monsters"]:
		var key = "%d:%d" % [int(m.get("x", -1)), int(m.get("y", -1))]
		if not start_map.has(key):
			start_map[key] = []
		start_map[key].append(m)

	for s in _level_data["scheduled_spawns"]:
		var key = "%d:%d" % [int(s.get("x", -1)), int(s.get("y", -1))]
		if not sched_map.has(key):
			sched_map[key] = []
		sched_map[key].append(s)

	for o in _level_data["obstacles"]:
		var key = "%d:%d" % [int(o.get("x", -1)), int(o.get("y", -1))]
		obstacle_map[key] = o

	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			var idx = y * COLS + x
			var btn: Button = _grid.get_child(idx)
			btn.text = ""
			btn.modulate = Color(1, 1, 1, 1)
			btn.self_modulate = Color(1, 1, 1, 1)
			btn.tooltip_text = "x=%d y=%d" % [x, y]
			var key = "%d:%d" % [x, y]
			var icon: TextureRect = btn.get_node("MonsterIcon")
			var hp_bg: ColorRect = btn.get_node("HpBg")
			var hp_fg: ColorRect = btn.get_node("HpFg")
			var top_label: Label = btn.get_node("TopLabel")
			icon.texture = null
			top_label.text = ""
			hp_bg.visible = false
			hp_fg.visible = false

			if obstacle_map.has(key):
				var obs = obstacle_map[key]
				var typ = str(obs.get("type", "breakable"))
				if typ == "wall":
					btn.self_modulate = WALL_COLOR
					top_label.text = "W"
				else:
					btn.self_modulate = OBSTACLE_COLOR
					var ohp = int(obs.get("hp", 1))
					top_label.text = "O%d" % ohp
					hp_bg.visible = true
					hp_fg.visible = true
					var hp_ratio = clamp(float(ohp) / 5.0, 0.2, 1.0)
					hp_fg.anchor_right = 0.15 + 0.7 * hp_ratio
			else:
				btn.self_modulate = Color(1, 1, 1, 1)

			if start_map.has(key) and start_map[key].size() > 0:
				var hp = int(start_map[key][0].get("hp", 1))
				icon.texture = MONSTER_TEXTURES.get(hp, null)
				top_label.text = ("M%d" % hp) + ((" " + top_label.text) if top_label.text != "" else "")
				hp_bg.visible = true
				hp_fg.visible = true

			if sched_map.has(key) and sched_map[key].size() > 0:
				if not start_map.has(key):
					var shp = int(sched_map[key][0].get("hp", 1))
					icon.texture = MONSTER_TEXTURES.get(shp, null)
					btn.modulate = Color(1, 1, 1, 0.5)
				top_label.text = (top_label.text + " " if top_label.text != "" else "") + ("q×%d" % sched_map[key].size())

			if _selected_cell.x == x and _selected_cell.y == y:
				btn.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
				btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.6))
			else:
				btn.remove_theme_color_override("font_color")
				btn.remove_theme_color_override("font_hover_color")

func _refresh_entity_list() -> void:
	_entities_list.clear()
	_entity_refs.clear()
	var only_selected = _only_selected_check.button_pressed

	for i in range(_level_data["start_monsters"].size()):
		var m = _level_data["start_monsters"][i]
		var x = int(m.get("x", -1))
		var y = int(m.get("y", -1))
		if only_selected and (_selected_cell.x != x or _selected_cell.y != y):
			continue
		_entities_list.add_item("Старт hp=%d @ (%d,%d)" % [int(m.get("hp", 1)), x, y])
		_entity_refs.append({"kind": "start", "index": i})

	for i in range(_level_data["scheduled_spawns"].size()):
		var s = _level_data["scheduled_spawns"][i]
		var x = int(s.get("x", -1))
		var y = int(s.get("y", -1))
		if only_selected and (_selected_cell.x != x or _selected_cell.y != y):
			continue
		_entities_list.add_item("Очередь hp=%d x%d через %d @ (%d,%d)" % [int(s.get("hp", 1)), int(s.get("count", 1)), int(s.get("spawn_after_player_turns", 0)), x, y])
		_entity_refs.append({"kind": "scheduled", "index": i})

	for i in range(_level_data["obstacles"].size()):
		var o = _level_data["obstacles"][i]
		var x = int(o.get("x", -1))
		var y = int(o.get("y", -1))
		if only_selected and (_selected_cell.x != x or _selected_cell.y != y):
			continue
		var typ = str(o.get("type", "breakable"))
		var txt = "Препятствие %s @ (%d,%d)" % [typ, x, y]
		if typ != "wall":
			txt = "Препятствие hp=%d @ (%d,%d)" % [int(o.get("hp", 1)), x, y]
		_entities_list.add_item(txt)
		_entity_refs.append({"kind": "obstacle", "index": i})

func _on_delete_selected_entity() -> void:
	if _entities_list.get_selected_items().is_empty():
		return
	var pos = int(_entities_list.get_selected_items()[0])
	if pos < 0 or pos >= _entity_refs.size():
		return
	var ref = _entity_refs[pos]
	var idx = int(ref.get("index", -1))
	match String(ref.get("kind", "")):
		"start":
			if idx >= 0 and idx < _level_data["start_monsters"].size():
				_level_data["start_monsters"].remove_at(idx)
		"scheduled":
			if idx >= 0 and idx < _level_data["scheduled_spawns"].size():
				_level_data["scheduled_spawns"].remove_at(idx)
		"obstacle":
			if idx >= 0 and idx < _level_data["obstacles"].size():
				_level_data["obstacles"].remove_at(idx)
	_dirty = true
	_refresh_ui()
