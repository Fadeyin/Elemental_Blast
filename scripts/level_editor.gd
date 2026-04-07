extends Control

class_name LevelEditor

const COLS := 8
const ENEMY_ROWS := 10

enum BrushMode { START_MONSTER, SCHEDULED_MONSTER, OBSTACLE, ERASE }

var _level_data := {
	"cols": COLS,
	"rows": 16,
	"enemy_rows": ENEMY_ROWS,
	"moves": 20,
	"start_monsters": [],
	"scheduled_spawns": [],
	"obstacles": [],
	"seed": 1
}
var _current_file_path := ""
var _brush_mode: BrushMode = BrushMode.START_MONSTER
var _selected_hp: int = 1
var _selected_obstacle_hp: int = 2
var _selected_spawn_delay: int = 1
var _selected_spawn_count: int = 1

@onready var _mode_option: OptionButton = $Root/TopBar/ModeOption
@onready var _monster_hp_spin: SpinBox = $Root/TopBar/MonsterHpSpin
@onready var _obstacle_hp_spin: SpinBox = $Root/TopBar/ObstacleHpSpin
@onready var _spawn_delay_spin: SpinBox = $Root/TopBar/SpawnDelaySpin
@onready var _spawn_count_spin: SpinBox = $Root/TopBar/SpawnCountSpin
@onready var _moves_spin: SpinBox = $Root/TopBar/MovesSpin
@onready var _grid: GridContainer = $Root/Main/GridPanel/Grid
@onready var _status_label: Label = $Root/Main/Sidebar/StatusLabel
@onready var _entities_list: ItemList = $Root/Main/Sidebar/EntitiesList

func _ready() -> void:
	_init_mode_controls()
	_build_grid()
	_connect_buttons()
	_refresh_ui()

func _init_mode_controls() -> void:
	_mode_option.clear()
	_mode_option.add_item("Стартовый монстр")
	_mode_option.add_item("Отложенный монстр")
	_mode_option.add_item("Препятствие")
	_mode_option.add_item("Ластик")
	_mode_option.item_selected.connect(func(i: int):
		_brush_mode = BrushMode(i)
		_refresh_ui()
	)

	_monster_hp_spin.value_changed.connect(func(v: float): _selected_hp = max(1, int(v)))
	_obstacle_hp_spin.value_changed.connect(func(v: float): _selected_obstacle_hp = max(1, int(v)))
	_spawn_delay_spin.value_changed.connect(func(v: float): _selected_spawn_delay = max(0, int(v)))
	_spawn_count_spin.value_changed.connect(func(v: float): _selected_spawn_count = max(1, int(v)))
	_moves_spin.value_changed.connect(func(v: float): _level_data["moves"] = max(1, int(v)))

func _build_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_grid.columns = COLS
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(74, 44)
			btn.focus_mode = Control.FOCUS_NONE
			btn.pressed.connect(_on_cell_pressed.bind(x, y))
			_grid.add_child(btn)

func _connect_buttons() -> void:
	$Root/Header/NewButton.pressed.connect(_on_new_pressed)
	$Root/Header/LoadButton.pressed.connect(_on_load_pressed)
	$Root/Header/SaveButton.pressed.connect(_on_save_pressed)
	$Root/Header/SaveAsButton.pressed.connect(_on_save_as_pressed)
	$Root/Header/TestButton.pressed.connect(_on_test_pressed)
	$Root/Header/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _on_cell_pressed(x: int, y: int) -> void:
	match _brush_mode:
		BrushMode.START_MONSTER:
			_erase_cell(x, y)
			_level_data["start_monsters"].append({"x": x, "y": y, "hp": _selected_hp})
		BrushMode.SCHEDULED_MONSTER:
			_erase_cell(x, y, false)
			_level_data["scheduled_spawns"].append({
				"x": x,
				"y": y,
				"hp": _selected_hp,
				"count": _selected_spawn_count,
				"spawn_after_player_turns": _selected_spawn_delay
			})
		BrushMode.OBSTACLE:
			_erase_obstacle(x, y)
			_level_data["obstacles"].append({"x": x, "y": y, "hp": _selected_obstacle_hp})
		BrushMode.ERASE:
			_erase_cell(x, y)
	_refresh_ui()

func _erase_cell(x: int, y: int, erase_scheduled: bool = true) -> void:
	var next_start := []
	for m in _level_data["start_monsters"]:
		if int(m.get("x", -1)) == x and int(m.get("y", -1)) == y:
			continue
		next_start.append(m)
	_level_data["start_monsters"] = next_start

	if erase_scheduled:
		var next_sched := []
		for s in _level_data["scheduled_spawns"]:
			if int(s.get("x", -1)) == x and int(s.get("y", -1)) == y:
				continue
			next_sched.append(s)
		_level_data["scheduled_spawns"] = next_sched

	_erase_obstacle(x, y)

func _erase_obstacle(x: int, y: int) -> void:
	var next_obs := []
	for o in _level_data["obstacles"]:
		if int(o.get("x", -1)) == x and int(o.get("y", -1)) == y:
			continue
		next_obs.append(o)
	_level_data["obstacles"] = next_obs

func _refresh_ui() -> void:
	_mode_option.select(int(_brush_mode))
	_status_label.text = "Режим: %s | Файл: %s" % [_mode_option.get_item_text(_mode_option.selected), (_current_file_path if _current_file_path != "" else "новый уровень")]
	_entities_list.clear()

	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			var btn: Button = _grid.get_child(y * COLS + x)
			btn.text = ""
			btn.modulate = Color.WHITE
			btn.tooltip_text = "x=%d y=%d" % [x, y]

	var start_index := {}
	for m in _level_data["start_monsters"]:
		var x = int(m.get("x", -1))
		var y = int(m.get("y", -1))
		var hp = int(m.get("hp", 1))
		if x < 0 or x >= COLS or y < 0 or y >= ENEMY_ROWS:
			continue
		var idx = y * COLS + x
		start_index["%d:%d" % [x, y]] = true
		var cell: Button = _grid.get_child(idx)
		cell.text = "M%d" % hp
		cell.modulate = Color(1, 1, 1, 1)
		_entities_list.add_item("Старт: hp=%d @ (%d,%d)" % [hp, x, y])

	for s in _level_data["scheduled_spawns"]:
		var x = int(s.get("x", -1))
		var y = int(s.get("y", -1))
		var hp = int(s.get("hp", 1))
		var delay = int(s.get("spawn_after_player_turns", 0))
		var count = int(s.get("count", 1))
		if x < 0 or x >= COLS or y < 0 or y >= ENEMY_ROWS:
			continue
		var idx = y * COLS + x
		var cell: Button = _grid.get_child(idx)
		if not start_index.has("%d:%d" % [x, y]):
			cell.text = "q%d" % hp
			cell.modulate = Color(1, 1, 1, 0.5)
		_entities_list.add_item("Очередь: hp=%d x%d через %d ходов @ (%d,%d)" % [hp, count, delay, x, y])

	for o in _level_data["obstacles"]:
		var x = int(o.get("x", -1))
		var y = int(o.get("y", -1))
		var hp = int(o.get("hp", 1))
		if x < 0 or x >= COLS or y < 0 or y >= ENEMY_ROWS:
			continue
		var idx = y * COLS + x
		var cell: Button = _grid.get_child(idx)
		cell.text = "O%d" % hp
		cell.modulate = Color(0.9, 0.7, 0.4, 1)
		_entities_list.add_item("Препятствие: hp=%d @ (%d,%d)" % [hp, x, y])

func _on_new_pressed() -> void:
	_current_file_path = ""
	_level_data = {
		"cols": COLS,
		"rows": 16,
		"enemy_rows": ENEMY_ROWS,
		"moves": 20,
		"start_monsters": [],
		"scheduled_spawns": [],
		"obstacles": [],
		"seed": int(Time.get_unix_time_from_system())
	}
	_moves_spin.value = _level_data["moves"]
	_refresh_ui()

func _on_load_pressed() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dlg.add_filter("*.json", "JSON level")
	dlg.file_selected.connect(func(path: String):
		var f = FileAccess.open(path, FileAccess.READ)
		if not f:
			return
		var data = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(data) == TYPE_DICTIONARY:
			_level_data = data
			_level_data["start_monsters"] = _level_data.get("start_monsters", [])
			_level_data["scheduled_spawns"] = _level_data.get("scheduled_spawns", [])
			_level_data["obstacles"] = _level_data.get("obstacles", [])
			_level_data["moves"] = int(_level_data.get("moves", 20))
			_current_file_path = path
			_moves_spin.value = _level_data["moves"]
			_refresh_ui()
		dlg.queue_free()
	)
	add_child(dlg)
	dlg.popup_centered_ratio(0.8)

func _on_save_pressed() -> void:
	if _current_file_path == "":
		_on_save_as_pressed()
		return
	_save_to_path(_current_file_path)

func _on_save_as_pressed() -> void:
	var dlg := FileDialog.new()
	dlg.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dlg.add_filter("*.json", "JSON level")
	dlg.file_selected.connect(func(path: String):
		_current_file_path = path
		_save_to_path(path)
		dlg.queue_free()
	)
	add_child(dlg)
	dlg.popup_centered_ratio(0.8)

func _save_to_path(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		return
	f.store_string(JSON.stringify(_level_data, "\t"))
	f.close()
	_refresh_ui()

func _on_test_pressed() -> void:
	var temp_path = "user://editor_preview_level.json"
	_save_to_path(temp_path)
	LevelManager.set_editor_level_override(temp_path)
	LevelManager.set_current_level(1)
	get_tree().change_scene_to_file("res://scenes/game_board.tscn")
