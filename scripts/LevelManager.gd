extends Node

const SAVE_PATH := "user://progress.cfg"
const INITIAL_COINS := 500
const INITIAL_BOOSTERS := 4
const INGAME_BOOSTER_PACK_COST := 150
const UI_GOLD_COIN_TEXTURE := preload("res://textures/ui_gold_coin.png")

enum BoosterType { HAMMER = 1, ROW_BLAST = 2, SHUFFLE = 3, FREEZE = 4 }

var current_level: int = 1
var max_unlocked_level: int = 1
var is_campaign_started: bool = false
var player_coins: int = INITIAL_COINS
var booster_counts := {
	BoosterType.HAMMER: INITIAL_BOOSTERS,
	BoosterType.ROW_BLAST: INITIAL_BOOSTERS,
	BoosterType.SHUFFLE: INITIAL_BOOSTERS,
	BoosterType.FREEZE: INITIAL_BOOSTERS
}
var starter_pack_purchased: bool = false

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

const PRELEVEL_BOOST_PACK_COUNT := 3

# Золотой пропуск: лента наград по календарным дням входа
const GOLDEN_PASS_TIER_COUNT := 30
const GOLDEN_PASS_PREMIUM_PRICE_COINS := 499

var golden_pass_purchased: bool = false
var golden_pass_last_calendar_date: String = ""
var golden_pass_unlocked_tiers: int = 1
var golden_pass_free_claimed: Array = []
var golden_pass_premium_claimed: Array = []
var _editor_level_override_path: String = ""
var _editor_test_mode: bool = false
var _editor_return_scene: String = "res://scenes/level_editor.tscn"

func get_prelevel_boost_pack_cost(boost_type: String) -> int:
	match boost_type:
		"rainbow": return 200
		"bomb": return 100
		"arrow": return 150
		_: return 999999

signal level_started(level: int)
signal level_completed(level: int)
signal coins_changed(new_amount: int)
signal boosters_changed()
signal golden_pass_state_changed()

func _ready():
	_load_progress()
	_ensure_golden_pass_arrays()
	print("LevelManager инициализирован: уровень=%d, монеты=%d" % [current_level, player_coins])

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
	if not prelevel_boosts.has(boost_type):
		return false
	return player_coins >= get_prelevel_boost_pack_cost(boost_type)

func purchase_prelevel_boosts(boost_type: String) -> bool:
	if not prelevel_boosts.has(boost_type):
		return false
	var cost := get_prelevel_boost_pack_cost(boost_type)
	if not spend_coins(cost):
		return false
	prelevel_boosts[boost_type] += PRELEVEL_BOOST_PACK_COUNT
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

func get_mort_helmet_level() -> int:
	return mort_helmet_level

func get_win_streak() -> int:
	return win_streak

func set_editor_level_override(path: String) -> void:
	_editor_level_override_path = path

func clear_editor_level_override() -> void:
	_editor_level_override_path = ""

func begin_editor_test(level_path: String, level_num: int) -> void:
	_editor_test_mode = true
	_editor_level_override_path = level_path
	current_level = max(1, level_num)

func finish_editor_test() -> void:
	_editor_test_mode = false
	_editor_level_override_path = ""

func is_editor_test_mode() -> bool:
	return _editor_test_mode

func get_editor_return_scene() -> String:
	return _editor_return_scene

# Функции управления монетами
func get_level_config(level: int) -> Dictionary:
	if _editor_level_override_path != "" and FileAccess.file_exists(_editor_level_override_path):
		var override_data = _load_level_config_from_path(_editor_level_override_path)
		if not override_data.is_empty():
			return _normalize_level_config(override_data, level)

	# Пытаемся загрузить JSON-конфиг уровня из res://levels/
	var candidates := [
		"res://levels/level_%03d.json" % level,
		"res://levels/level_%d.json" % level
	]
	for path in candidates:
		if FileAccess.file_exists(path):
			var data = _load_level_config_from_path(path)
			if not data.is_empty():
				return _normalize_level_config(data, level)
	# Дефолтные параметры, если файл не найден
	return _normalize_level_config({
		"cols": 7,
		"rows": 12,
		"enemy_rows": 10,
		"strong_monsters": max(0, (level - 1) * 5),
		"strong_hp": 3
	}, level)

func _load_level_config_from_path(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var txt := f.get_as_text()
	f.close()
	var j := JSON.new()
	if j.parse(txt) != OK:
		return {}
	var data = j.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

func _normalize_level_config(data: Dictionary, level: int) -> Dictionary:
	var out = data.duplicate(true)
	out["cols"] = int(out.get("cols", 7))
	out["rows"] = int(out.get("rows", 12))
	out["enemy_rows"] = int(out.get("enemy_rows", 6))
	out["moves"] = int(out.get("moves", (15 if level == 1 else 20)))

	var normalized_scheduled := []
	if out.has("scheduled_spawns") and typeof(out.scheduled_spawns) == TYPE_ARRAY:
		for item in out.scheduled_spawns:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			normalized_scheduled.append({
				"hp": max(1, int(item.get("hp", 1))),
				"count": max(1, int(item.get("count", 1))),
				"x": int(item.get("x", 0)),
				"y": int(item.get("y", 0)),
				"spawn_after_player_turns": max(0, int(item.get("spawn_after_player_turns", 0)))
			})
	out["scheduled_spawns"] = normalized_scheduled

	var normalized_start := []
	if out.has("start_monsters") and typeof(out.start_monsters) == TYPE_ARRAY:
		for item in out.start_monsters:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			normalized_start.append({
				"hp": max(1, int(item.get("hp", 1))),
				"x": int(item.get("x", 0)),
				"y": int(item.get("y", 0))
			})
	out["start_monsters"] = normalized_start

	var normalized_obstacles := []
	if out.has("obstacles") and typeof(out.obstacles) == TYPE_ARRAY:
		for item in out.obstacles:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var o_type = str(item.get("type", "breakable"))
			var obstacle_data = {
				"x": int(item.get("x", 0)),
				"y": int(item.get("y", 0)),
				"type": ("wall" if o_type == "wall" else "breakable")
			}
			if obstacle_data["type"] == "breakable":
				obstacle_data["hp"] = max(1, int(item.get("hp", 1)))
			if item.has("spawn_on_destroy") and typeof(item.spawn_on_destroy) == TYPE_DICTIONARY:
				var sp = item.spawn_on_destroy
				obstacle_data["spawn_on_destroy"] = {
					"hp": max(1, int(sp.get("hp", 1))),
					"count": max(1, int(sp.get("count", 1)))
				}
			normalized_obstacles.append(obstacle_data)
	out["obstacles"] = normalized_obstacles

	return out

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

func _ensure_golden_pass_arrays() -> void:
	while golden_pass_free_claimed.size() < GOLDEN_PASS_TIER_COUNT:
		golden_pass_free_claimed.append(false)
	while golden_pass_premium_claimed.size() < GOLDEN_PASS_TIER_COUNT:
		golden_pass_premium_claimed.append(false)
	if golden_pass_unlocked_tiers < 1:
		golden_pass_unlocked_tiers = 1
	golden_pass_unlocked_tiers = min(golden_pass_unlocked_tiers, GOLDEN_PASS_TIER_COUNT)

func _calendar_date_key_from_unix(unix_sec: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix_sec)
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func tick_golden_pass_daily_login() -> void:
	_ensure_golden_pass_arrays()
	var today := _calendar_date_key_from_unix(int(Time.get_unix_time_from_system()))
	if golden_pass_last_calendar_date == today:
		return
	if golden_pass_last_calendar_date != "":
		golden_pass_unlocked_tiers = min(golden_pass_unlocked_tiers + 1, GOLDEN_PASS_TIER_COUNT)
	golden_pass_last_calendar_date = today
	_save_progress()
	emit_signal("golden_pass_state_changed")

func get_golden_pass_unlocked_tiers() -> int:
	_ensure_golden_pass_arrays()
	return golden_pass_unlocked_tiers

func is_golden_pass_purchased() -> bool:
	return golden_pass_purchased

func is_golden_pass_free_claimed(tier_index: int) -> bool:
	_ensure_golden_pass_arrays()
	if tier_index < 0 or tier_index >= golden_pass_free_claimed.size():
		return false
	return bool(golden_pass_free_claimed[tier_index])

func is_golden_pass_premium_claimed(tier_index: int) -> bool:
	_ensure_golden_pass_arrays()
	if tier_index < 0 or tier_index >= golden_pass_premium_claimed.size():
		return false
	return bool(golden_pass_premium_claimed[tier_index])

func can_claim_golden_pass_free(tier_index: int) -> bool:
	return tier_index < get_golden_pass_unlocked_tiers() and not is_golden_pass_free_claimed(tier_index)

func can_claim_golden_pass_premium(tier_index: int) -> bool:
	return golden_pass_purchased and tier_index < get_golden_pass_unlocked_tiers() and not is_golden_pass_premium_claimed(tier_index)

func claim_golden_pass_free(tier_index: int) -> bool:
	if not can_claim_golden_pass_free(tier_index):
		return false
	var reward: Dictionary = get_golden_pass_tier_reward(tier_index)
	if not reward.has("free"):
		return false
	if not _apply_golden_pass_reward(reward["free"]):
		return false
	golden_pass_free_claimed[tier_index] = true
	_save_progress()
	emit_signal("golden_pass_state_changed")
	return true

func claim_golden_pass_premium(tier_index: int) -> bool:
	if not can_claim_golden_pass_premium(tier_index):
		return false
	var reward: Dictionary = get_golden_pass_tier_reward(tier_index)
	if not reward.has("premium"):
		return false
	if not _apply_golden_pass_reward(reward["premium"]):
		return false
	golden_pass_premium_claimed[tier_index] = true
	_save_progress()
	emit_signal("golden_pass_state_changed")
	return true

func purchase_golden_pass_with_coins() -> bool:
	if golden_pass_purchased:
		return true
	if not spend_coins(GOLDEN_PASS_PREMIUM_PRICE_COINS):
		return false
	golden_pass_purchased = true
	_save_progress()
	emit_signal("golden_pass_state_changed")
	return true

func _booster_type_from_pass_id(pass_id: String) -> BoosterType:
	match pass_id:
		"hammer": return BoosterType.HAMMER
		"row_blast": return BoosterType.ROW_BLAST
		"shuffle": return BoosterType.SHUFFLE
		"freeze": return BoosterType.FREEZE
		_: return BoosterType.HAMMER

func _apply_golden_pass_reward(entry: Dictionary) -> bool:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"coins":
			var amt: int = int(entry.get("amount", 0))
			if amt <= 0:
				return false
			add_coins(amt)
			return true
		"booster":
			var bid: String = str(entry.get("id", "hammer"))
			var n: int = int(entry.get("amount", 1))
			if n <= 0:
				return false
			var bt := _booster_type_from_pass_id(bid)
			booster_counts[bt] = booster_counts.get(bt, 0) + n
			_save_progress()
			emit_signal("boosters_changed")
			return true
		"bonus_chip":
			var chip: String = str(entry.get("id", "bomb"))
			var c: int = int(entry.get("amount", 1))
			if c <= 0 or not prelevel_boosts.has(chip):
				return false
			prelevel_boosts[chip] += c
			_save_progress()
			return true
		_:
			return false

func get_golden_pass_tier_reward(tier_index: int) -> Dictionary:
	var rows: Array = [
		{"free": {"kind": "coins", "amount": 40}, "premium": {"kind": "coins", "amount": 120}},
		{"free": {"kind": "booster", "id": "hammer", "amount": 1}, "premium": {"kind": "booster", "id": "hammer", "amount": 2}},
		{"free": {"kind": "coins", "amount": 60}, "premium": {"kind": "bonus_chip", "id": "bomb", "amount": 2}},
		{"free": {"kind": "booster", "id": "row_blast", "amount": 1}, "premium": {"kind": "booster", "id": "row_blast", "amount": 2}},
		{"free": {"kind": "bonus_chip", "id": "arrow", "amount": 1}, "premium": {"kind": "coins", "amount": 200}},
		{"free": {"kind": "coins", "amount": 50}, "premium": {"kind": "bonus_chip", "id": "rainbow", "amount": 2}},
		{"free": {"kind": "booster", "id": "shuffle", "amount": 1}, "premium": {"kind": "booster", "id": "shuffle", "amount": 3}},
		{"free": {"kind": "coins", "amount": 70}, "premium": {"kind": "coins", "amount": 180}},
		{"free": {"kind": "bonus_chip", "id": "bomb", "amount": 1}, "premium": {"kind": "bonus_chip", "id": "bomb", "amount": 4}},
		{"free": {"kind": "booster", "id": "freeze", "amount": 1}, "premium": {"kind": "booster", "id": "freeze", "amount": 2}},
		{"free": {"kind": "coins", "amount": 80}, "premium": {"kind": "bonus_chip", "id": "arrow", "amount": 3}},
		{"free": {"kind": "booster", "id": "hammer", "amount": 1}, "premium": {"kind": "coins", "amount": 250}},
		{"free": {"kind": "coins", "amount": 55}, "premium": {"kind": "booster", "id": "row_blast", "amount": 3}},
		{"free": {"kind": "bonus_chip", "id": "rainbow", "amount": 1}, "premium": {"kind": "bonus_chip", "id": "rainbow", "amount": 3}},
		{"free": {"kind": "booster", "id": "shuffle", "amount": 1}, "premium": {"kind": "coins", "amount": 220}},
		{"free": {"kind": "coins", "amount": 90}, "premium": {"kind": "booster", "id": "hammer", "amount": 3}},
		{"free": {"kind": "bonus_chip", "id": "bomb", "amount": 2}, "premium": {"kind": "bonus_chip", "id": "bomb", "amount": 3}},
		{"free": {"kind": "booster", "id": "row_blast", "amount": 1}, "premium": {"kind": "booster", "id": "freeze", "amount": 3}},
		{"free": {"kind": "coins", "amount": 100}, "premium": {"kind": "coins", "amount": 300}},
		{"free": {"kind": "booster", "id": "freeze", "amount": 1}, "premium": {"kind": "bonus_chip", "id": "arrow", "amount": 4}},
		{"free": {"kind": "coins", "amount": 65}, "premium": {"kind": "booster", "id": "shuffle", "amount": 2}},
		{"free": {"kind": "bonus_chip", "id": "arrow", "amount": 2}, "premium": {"kind": "coins", "amount": 280}},
		{"free": {"kind": "booster", "id": "hammer", "amount": 2}, "premium": {"kind": "bonus_chip", "id": "rainbow", "amount": 2}},
		{"free": {"kind": "coins", "amount": 75}, "premium": {"kind": "booster", "id": "row_blast", "amount": 2}},
		{"free": {"kind": "bonus_chip", "id": "bomb", "amount": 1}, "premium": {"kind": "coins", "amount": 350}},
		{"free": {"kind": "booster", "id": "shuffle", "amount": 1}, "premium": {"kind": "booster", "id": "hammer", "amount": 4}},
		{"free": {"kind": "coins", "amount": 95}, "premium": {"kind": "bonus_chip", "id": "bomb", "amount": 5}},
		{"free": {"kind": "booster", "id": "row_blast", "amount": 1}, "premium": {"kind": "coins", "amount": 400}},
		{"free": {"kind": "bonus_chip", "id": "rainbow", "amount": 2}, "premium": {"kind": "booster", "id": "freeze", "amount": 4}},
		{"free": {"kind": "coins", "amount": 150}, "premium": {"kind": "coins", "amount": 500}},
	]
	if tier_index < 0 or tier_index >= rows.size():
		return {}
	return rows[tier_index]

func use_booster(type: BoosterType) -> bool:
	if booster_counts.get(type, 0) > 0:
		booster_counts[type] -= 1
		_save_progress()
		emit_signal("boosters_changed")
		return true
	return false

func get_ingame_booster_pack_quantity(type: BoosterType) -> int:
	if type == BoosterType.HAMMER:
		return 3
	return 1

func buy_booster(type: BoosterType) -> bool:
	var qty := get_ingame_booster_pack_quantity(type)
	if not spend_coins(INGAME_BOOSTER_PACK_COST):
		return false
	booster_counts[type] = booster_counts.get(type, 0) + qty
	_save_progress()
	emit_signal("boosters_changed")
	return true

func get_booster_count(type: BoosterType) -> int:
	return booster_counts.get(type, 0)

func purchase_starter_pack():
	if not starter_pack_purchased:
		player_coins += 1000
		for type in [BoosterType.HAMMER, BoosterType.ROW_BLAST, BoosterType.SHUFFLE, BoosterType.FREEZE]:
			booster_counts[type] = booster_counts.get(type, 0) + 4
		starter_pack_purchased = true
		_save_progress()
		emit_signal("coins_changed", player_coins)
		emit_signal("boosters_changed")

func purchase_medium_pack():
	player_coins += 2500
	for type in [BoosterType.HAMMER, BoosterType.ROW_BLAST, BoosterType.SHUFFLE, BoosterType.FREEZE]:
		booster_counts[type] = booster_counts.get(type, 0) + 5
	_save_progress()
	emit_signal("coins_changed", player_coins)
	emit_signal("boosters_changed")

func purchase_best_pack():
	player_coins += 5000
	for type in [BoosterType.HAMMER, BoosterType.ROW_BLAST, BoosterType.SHUFFLE, BoosterType.FREEZE]:
		booster_counts[type] = booster_counts.get(type, 0) + 10
	_save_progress()
	emit_signal("coins_changed", player_coins)
	emit_signal("boosters_changed")

func is_starter_pack_purchased() -> bool:
	return starter_pack_purchased

func _save_progress():
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", current_level)
	cfg.set_value("progress", "max_unlocked_level", max_unlocked_level)
	cfg.set_value("progress", "is_campaign_started", is_campaign_started)
	cfg.set_value("progress", "player_coins", player_coins)
	cfg.set_value("progress", "starter_pack_purchased", starter_pack_purchased)
	
	# Сохранение win streak и шлема Морта
	cfg.set_value("mort_helmet", "level", mort_helmet_level)
	cfg.set_value("mort_helmet", "win_streak", win_streak)
	
	# Сохранение предуровневых усилений
	cfg.set_value("prelevel_boosts", "bomb", prelevel_boosts["bomb"])
	cfg.set_value("prelevel_boosts", "arrow", prelevel_boosts["arrow"])
	cfg.set_value("prelevel_boosts", "rainbow", prelevel_boosts["rainbow"])
	
	# Сохранение бустеров
	cfg.set_value("boosters", "hammer", booster_counts.get(BoosterType.HAMMER, INITIAL_BOOSTERS))
	cfg.set_value("boosters", "row_blast", booster_counts.get(BoosterType.ROW_BLAST, INITIAL_BOOSTERS))
	cfg.set_value("boosters", "shuffle", booster_counts.get(BoosterType.SHUFFLE, INITIAL_BOOSTERS))
	cfg.set_value("boosters", "freeze", booster_counts.get(BoosterType.FREEZE, INITIAL_BOOSTERS))
	
	cfg.set_value("golden_pass", "purchased", golden_pass_purchased)
	cfg.set_value("golden_pass", "last_calendar_date", golden_pass_last_calendar_date)
	cfg.set_value("golden_pass", "unlocked_tiers", golden_pass_unlocked_tiers)
	cfg.set_value("golden_pass", "free_claimed", golden_pass_free_claimed)
	cfg.set_value("golden_pass", "premium_claimed", golden_pass_premium_claimed)
	
	cfg.save(SAVE_PATH)

func _load_progress():
	var cfg := ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		current_level = int(cfg.get_value("progress", "current_level", 1))
		max_unlocked_level = int(cfg.get_value("progress", "max_unlocked_level", 1))
		is_campaign_started = bool(cfg.get_value("progress", "is_campaign_started", false))
		player_coins = int(cfg.get_value("progress", "player_coins", INITIAL_COINS))
		starter_pack_purchased = bool(cfg.get_value("progress", "starter_pack_purchased", false))
		
		# Загрузка win streak и шлема Морта
		mort_helmet_level = int(cfg.get_value("mort_helmet", "level", 0))
		win_streak = int(cfg.get_value("mort_helmet", "win_streak", 0))
		
		# Загрузка предуровневых усилений
		prelevel_boosts["bomb"] = int(cfg.get_value("prelevel_boosts", "bomb", 3))
		prelevel_boosts["arrow"] = int(cfg.get_value("prelevel_boosts", "arrow", 3))
		prelevel_boosts["rainbow"] = int(cfg.get_value("prelevel_boosts", "rainbow", 3))
		
		# Загрузка бустеров
		booster_counts[BoosterType.HAMMER] = int(cfg.get_value("boosters", "hammer", INITIAL_BOOSTERS))
		booster_counts[BoosterType.ROW_BLAST] = int(cfg.get_value("boosters", "row_blast", INITIAL_BOOSTERS))
		booster_counts[BoosterType.SHUFFLE] = int(cfg.get_value("boosters", "shuffle", INITIAL_BOOSTERS))
		booster_counts[BoosterType.FREEZE] = int(cfg.get_value("boosters", "freeze", INITIAL_BOOSTERS))
		
		golden_pass_purchased = bool(cfg.get_value("golden_pass", "purchased", false))
		golden_pass_last_calendar_date = str(cfg.get_value("golden_pass", "last_calendar_date", ""))
		golden_pass_unlocked_tiers = int(cfg.get_value("golden_pass", "unlocked_tiers", 1))
		var fc = cfg.get_value("golden_pass", "free_claimed", [])
		var pc = cfg.get_value("golden_pass", "premium_claimed", [])
		if typeof(fc) == TYPE_ARRAY:
			golden_pass_free_claimed = fc.duplicate()
		else:
			golden_pass_free_claimed = []
		if typeof(pc) == TYPE_ARRAY:
			golden_pass_premium_claimed = pc.duplicate()
		else:
			golden_pass_premium_claimed = []
		_ensure_golden_pass_arrays()
	else:
		_ensure_golden_pass_arrays()

