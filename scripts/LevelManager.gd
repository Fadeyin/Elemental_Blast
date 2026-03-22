extends Node

const SAVE_PATH := "user://progress.cfg"
const INITIAL_COINS := 500

var current_level: int = 1
var max_unlocked_level: int = 1
var is_campaign_started: bool = false
var player_coins: int = INITIAL_COINS

signal level_started(level: int)
signal level_completed(level: int)
signal coins_changed(new_amount: int)

func _ready():
	_load_progress()

func start_new_game():
	is_campaign_started = true
	current_level = 1
	_emit_start()

func start_next_level():
	if is_campaign_started:
		current_level += 1
	else:
		is_campaign_started = true
		current_level = 1
	_emit_start()

func restart_current_level():
	if not is_campaign_started:
		is_campaign_started = true
		current_level = 1
	_emit_start()

func mark_level_completed():
	max_unlocked_level = max(max_unlocked_level, current_level)
	_save_progress()
	emit_signal("level_completed", current_level)
	# Подготовить следующий уровень для следующего старта из меню
	current_level += 1
	_save_progress()

func get_level_config(level: int) -> Dictionary:
	# Пытаемся загрузить JSON-конфиг уровня из res://levels/
	var candidates := [
		"res://levels/level_%03d.json" % level,
		"res://levels/level_%d.json" % level
	]
	for path in candidates:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var txt := f.get_as_text()
				f.close()
				var j := JSON.new()
				if j.parse(txt) == OK:
					var data = j.get_data()
					if typeof(data) == TYPE_DICTIONARY:
						return data
	# Дефолтные параметры, если файл не найден
	return {
		"cols": 7,
		"rows": 12,
		"enemy_rows": 6,
		"strong_monsters": max(0, (level - 1) * 5),
		"strong_hp": 3
	}

func _emit_start():
	_save_progress()
	emit_signal("level_started", current_level)

func set_current_level(level: int):
	current_level = max(1, level)
	is_campaign_started = true
	_save_progress()

func get_available_level_numbers() -> Array:
	var result: Array = [1]
	var dir := DirAccess.open("res://levels")
	if dir:
		dir.list_dir_begin()
		var name = dir.get_next()
		while name != "":
			if not dir.current_is_dir() and name.ends_with(".json") and name.begins_with("level_"):
				var base = name.get_basename() # e.g., level_002
				var num_str = base.substr(6) # after 'level_'
				if num_str.is_valid_int():
					var n = int(num_str)
					if n >= 1:
						result.append(n)
			name = dir.get_next()
		dir.list_dir_end()
	# Уникализируем и сортируем
	var unique := {}
	for n in result:
		unique[n] = true
	var out: Array = []
	for k in unique.keys():
		out.append(k)
	out.sort()
	return out

func add_coins(amount: int):
	player_coins += amount
	_save_progress()
	emit_signal("coins_changed", player_coins)

func spend_coins(amount: int) -> bool:
	if player_coins >= amount:
		player_coins -= amount
		_save_progress()
		emit_signal("coins_changed", player_coins)
		return true
	return false

func get_coins() -> int:
	return player_coins

func _save_progress():
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", current_level)
	cfg.set_value("progress", "max_unlocked_level", max_unlocked_level)
	cfg.set_value("progress", "is_campaign_started", is_campaign_started)
	cfg.set_value("progress", "player_coins", player_coins)
	cfg.save(SAVE_PATH)

func _load_progress():
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		current_level = int(cfg.get_value("progress", "current_level", 1))
		max_unlocked_level = int(cfg.get_value("progress", "max_unlocked_level", 1))
		is_campaign_started = bool(cfg.get_value("progress", "is_campaign_started", false))
		player_coins = int(cfg.get_value("progress", "player_coins", INITIAL_COINS))

