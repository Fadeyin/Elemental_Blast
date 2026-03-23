extends Node

const SAVE_PATH := "user://progress.cfg"

var current_level: int = 1
var max_unlocked_level: int = 1
var is_campaign_started: bool = false

# Шлем Морта (win streak система)
var mort_helmet_level: int = 0 # 0, 1, 2, 3
var win_streak: int = 0 # Количество побед подряд

# Предуровневые усиления (Pre-level Boosters)
var prelevel_boosts := {
	"bomb": 3,      # Бомба
	"arrow": 3,     # Стрела (ракета)
	"rainbow": 3    # Шар (радужная фишка)
}

# Выбранные предуровневые усиления для текущего уровня (передается из main_menu в game_board)
var selected_prelevel_boosts := {
	"bomb": false,
	"arrow": false,
	"rainbow": false
}

const PRELEVEL_BOOST_PURCHASE_COST := 200
const PRELEVEL_BOOST_PURCHASE_COUNT := 3

signal level_started(level: int)
signal level_completed(level: int)

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
	
	# Увеличиваем win streak при победе
	win_streak += 1
	_update_mort_helmet_level()
	
	# Сбрасываем выбранные усиления для следующего уровня
	selected_prelevel_boosts = {"bomb": false, "arrow": false, "rainbow": false}
	
	_save_progress()
	emit_signal("level_completed", current_level)
	# Подготовить следующий уровень для следующего старта из меню
	current_level += 1
	_save_progress()

func mark_level_failed():
	# При поражении обнуляем win streak и шлем Морта
	win_streak = 0
	mort_helmet_level = 0
	
	# Сбрасываем выбранные усиления
	selected_prelevel_boosts = {"bomb": false, "arrow": false, "rainbow": false}
	
	_save_progress()

func _update_mort_helmet_level():
	# Обновляем уровень шлема Морта на основе win streak
	if win_streak >= 3:
		mort_helmet_level = 3
	elif win_streak >= 2:
		mort_helmet_level = 2
	elif win_streak >= 1:
		mort_helmet_level = 1
	else:
		mort_helmet_level = 0

func get_mort_helmet_bonus_chips() -> Dictionary:
	# Возвращает количество бонусных фишек от Шлема Морта
	match mort_helmet_level:
		1: return {"arrow": 1, "bomb": 1}         # 2 усиления: 1 стрела, 1 бомба
		2: return {"arrow": 2, "bomb": 2}         # 4 усиления: 2 стрелы, 2 бомбы
		3: return {"arrow": 3, "bomb": 3}         # 6 усилений: 3 стрелы, 3 бомбы
		_: return {}

func can_purchase_prelevel_boosts(boost_type: String) -> bool:
	# Проверка возможности покупки (у игрока достаточно монет)
	# TODO: интеграция с монетами будет через CoinsManager
	return true

func purchase_prelevel_boosts(boost_type: String) -> bool:
	if not prelevel_boosts.has(boost_type):
		return false
	
	# TODO: списать монеты через CoinsManager
	# if not CoinsManager.spend_coins(PRELEVEL_BOOST_PURCHASE_COST):
	#     return false
	
	prelevel_boosts[boost_type] += PRELEVEL_BOOST_PURCHASE_COUNT
	_save_progress()
	return true

func use_prelevel_boost(boost_type: String) -> bool:
	if not prelevel_boosts.has(boost_type):
		return false
	if prelevel_boosts[boost_type] <= 0:
		return false
	
	prelevel_boosts[boost_type] -= 1
	_save_progress()
	return true

func get_prelevel_boost_count(boost_type: String) -> int:
	return prelevel_boosts.get(boost_type, 0)

func get_prelevel_boost_texture(boost_type: String) -> Texture2D:
	# Возвращает текстуру для иконки усиления
	match boost_type:
		"bomb": return preload("res://textures/Сhip_Bonus_Bomb.png")
		"arrow": return preload("res://textures/Сhip_Bonus_Arrows.png")
		"rainbow": return preload("res://textures/Сhip_Bonus_Rainbow_Ball.png")
		_: return null

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

func _save_progress():
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", current_level)
	cfg.set_value("progress", "max_unlocked_level", max_unlocked_level)
	cfg.set_value("progress", "is_campaign_started", is_campaign_started)
	
	# Сохранение win streak и шлема Морта
	cfg.set_value("mort_helmet", "level", mort_helmet_level)
	cfg.set_value("mort_helmet", "win_streak", win_streak)
	
	# Сохранение предуровневых усилений
	cfg.set_value("prelevel_boosts", "bomb", prelevel_boosts.bomb)
	cfg.set_value("prelevel_boosts", "arrow", prelevel_boosts.arrow)
	cfg.set_value("prelevel_boosts", "rainbow", prelevel_boosts.rainbow)
	
	cfg.save(SAVE_PATH)

func _load_progress():
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		current_level = int(cfg.get_value("progress", "current_level", 1))
		max_unlocked_level = int(cfg.get_value("progress", "max_unlocked_level", 1))
		is_campaign_started = bool(cfg.get_value("progress", "is_campaign_started", false))
		
		# Загрузка win streak и шлема Морта
		mort_helmet_level = int(cfg.get_value("mort_helmet", "level", 0))
		win_streak = int(cfg.get_value("mort_helmet", "win_streak", 0))
		
		# Загрузка предуровневых усилений
		prelevel_boosts.bomb = int(cfg.get_value("prelevel_boosts", "bomb", 3))
		prelevel_boosts.arrow = int(cfg.get_value("prelevel_boosts", "arrow", 3))
		prelevel_boosts.rainbow = int(cfg.get_value("prelevel_boosts", "rainbow", 3))

