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

@onready var _level_spin: SpinBox = $Root/TopActions/LevelSpin
@onready var _mode_option: OptionButton = $Root/Tools/ModeOption
@onready var _monster_hp_spin: SpinBox = $Root/Tools/MonsterHpSpin
@onready var _obstacle_hp_spin: SpinBox = $Root/Tools/ObstacleHpSpin
@onready var _spawn_delay_spin: SpinBox = $Root/Tools/SpawnDelaySpin
@onready var _spawn_count_spin: SpinBox = $Root/Tools/SpawnCountSpin
@onready var _moves_spin: SpinBox = $Root/Tools/MovesSpin
@onready var _obstacle_type_option: OptionButton = $Root/Tools/ObstacleTypeOption
@onready var _spawn_on_break_check: CheckBox = $Root/Tools/SpawnOnBreakCheck
@onready var _spawn_on_break_hp_spin: SpinBox = $Root/Tools/SpawnOnBreakHpSpin
@onready var _spawn_on_break_count_spin: SpinBox = $Root/Tools/SpawnOnBreakCountSpin
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
			btn.custom_minimum_size = Vector2(84, 58)
			btn.focus_mode = Control.FOCUS_NONE
			btn.flat = false
			btn.pressed.connect(_on_cell_pressed.bind(x, y))
			_grid.add_child(btn)

func _connect_buttons() -> void:
	$Root/TopActions/NewButton.pressed.connect(_on_new_pressed)
	$Root/TopActions/LoadButton.pressed.connect(_on_load_pressed)
	$Root/TopActions/SaveButton.pressed.connect(_on_save_pressed)
	$Root/TopActions/TestButton.pressed.connect(_on_test_pressed)
	$Root/TopActions/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	$Root/TopActions/PrevLevelButton.pressed.connect(func(): _request_level_switch(_current_level_number - 1))
	$Root/TopActions/NextLevelButton.pressed.connect(func(): _request_level_switch(_current_level_number + 1))
	$Root/BottomPanel/DeleteSelectedEntityButton.pressed.connect(_on_delete_selected_entity)
	$Root/TopActions/GoToLevelButton.pressed.connect(func(): _request_level_switch(int(_level_spin.value)))

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
	LevelManager.set_editor_level_override(temp_path)
	LevelManager.set_current_level(_current_level_number)
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")

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
			btn.icon = null
			btn.modulate = Color(1, 1, 1, 1)
			btn.tooltip_text = "x=%d y=%d" % [x, y]
			var key = "%d:%d" % [x, y]

			if obstacle_map.has(key):
				var obs = obstacle_map[key]
				var typ = str(obs.get("type", "breakable"))
				if typ == "wall":
					btn.text = "W"
					btn.self_modulate = Color(0.55, 0.55, 0.62, 1.0)
				else:
					btn.text = "O%d" % int(obs.get("hp", 1))
					btn.self_modulate = Color(0.85, 0.75, 0.55, 1.0)
			else:
				btn.self_modulate = Color(1, 1, 1, 1)

			if start_map.has(key) and start_map[key].size() > 0:
				var hp = int(start_map[key][0].get("hp", 1))
				btn.icon = MONSTER_TEXTURES.get(hp, null)
				btn.expand_icon = true
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
				btn.text = btn.text + (" M%d" % hp)

			if sched_map.has(key) and sched_map[key].size() > 0:
				if not start_map.has(key):
					var shp = int(sched_map[key][0].get("hp", 1))
					btn.icon = MONSTER_TEXTURES.get(shp, null)
					btn.modulate = Color(1, 1, 1, 0.5)
				btn.text = btn.text + (" q×%d" % sched_map[key].size())

			if _selected_cell.x == x and _selected_cell.y == y:
				btn.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
			else:
				btn.remove_theme_color_override("font_color")

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
