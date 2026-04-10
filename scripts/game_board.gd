extends Node2D

# Простой экран игрового поля: только сетка
const COLS := 8
const ROWS := 16
const CELL_SIZE := 80
const ENEMY_CELL_HEIGHT := 40
const LINE_COLOR := Color(0.35, 0.35, 0.4, 1)
const ENEMY_ROWS := 10
const PLAYER_ROWS := 6
const PLAYER_ZONE_OUTLINE_COLOR := Color(1.0, 0.85, 0.2, 1) # Золотой
const PLAYER_ZONE_OUTLINE_WIDTH := 6.0
const CHIP_COLORS := [
	Color(0.82, 0.44, 0.44), # Приглушенный красный (коралловый)
	Color(0.44, 0.58, 0.72), # Серо-синий
	Color(0.52, 0.68, 0.52), # Оливково-зеленый
	Color(0.95, 0.95, 0.95)  # Чистый белый (вместо фиолетового)
]
const CHIP_TEXTURES := [
	preload("res://textures/Сhip_Base_Red.png"),
	preload("res://textures/Сhip_Base_Blue.png"),
	preload("res://textures/Сhip_Base_Green.png"),
	preload("res://textures/Сhip_Base_White.png")
]
const BONUS_TEXTURES := {
	RAINBOW_CHIP_IDX: preload("res://textures/Сhip_Bonus_Rainbow_Ball.png"),
	ROW_BONUS_CHIP_IDX: preload("res://textures/Сhip_Bonus_Arrows.png"),
	BOMB_CHIP_IDX: preload("res://textures/Сhip_Bonus_Bomb.png")
}
const MONSTER_TEXTURES := {
	1: preload("res://textures/Monster_1_lvl.png"),
	2: preload("res://textures/Monster_2_lvl.png"),
	3: preload("res://textures/Monster_3_lvl.png"),
	4: preload("res://textures/Monster_4_lvl.png"),
	5: preload("res://textures/Monster_5_lvl.png")
}
const CHIP_SIZE_FACTOR := 1.02
const CHIP_EDGE_WIDTH := 3.0
const CHIP_SHADOW_OFFSET := Vector2(0, 6)
const CHIP_SHADOW_COLOR := Color(0, 0, 0, 0.25)
const FIELD_GAP_BASE := 8.0 # Минимальный зазор между полосой сердец и зоной фишек
const HEART_STRIP_HEIGHT := 52.0 # Полоса между врагами и фишками — здесь рисуются сердца
const CHIP_HIGHLIGHT_ALPHA := 0.08
const FALL_DURATION := 0.2
const RAINBOW_CHIP_IDX := -2
const ROW_BONUS_CHIP_IDX := -3
const BOMB_CHIP_IDX := -4
# Минимальный размер связной группы обычных фишек для лопания по клику
const MIN_NORMAL_CLUSTER_POP := 2
const BG_COLOR := Color(0.52, 0.58, 0.68, 1) # Пастельный светло-синий фон
const GAME_BG_TEXTURE := preload("res://textures/Game_Backgound.png")
const ENEMY_TILE_TEXTURE := preload("res://textures/Floor_Enemy_Tile_.png")

# Константы полоски здоровья монстров
const HEALTH_BAR_HEIGHT := 4.0
const HEALTH_BAR_MARGIN := 2.0
const HEALTH_BAR_BG_COLOR := Color(0.2, 0.2, 0.2, 0.6)
const HEALTH_BAR_HEALTH_COLOR := Color(0.2, 0.8, 0.2, 0.9)
const HEALTH_BAR_DAMAGE_COLOR := Color(0.9, 0.2, 0.2, 0.7)

# Константы препятствий
const OBSTACLE_COLOR := Color(0.4, 0.35, 0.3, 1.0) # Коричневый (стена)
const OBSTACLE_EDGE_COLOR := Color(0.25, 0.2, 0.15, 1.0) # Тёмно-коричневый (края)

# Отступы под UI-панели
const UI_TOP_MARGIN := 72
const UI_BOTTOM_MARGIN := 128

var chips := []
var enemies := [] # 2D массив здоровья врагов (y: 0..ENEMY_ROWS-1)
var enemies_initial_hp := [] # Исходный HP врагов для целей
var _enemies_hit_this_turn := [] # 2D массив флагов попадания в этом ходу
var _monster_spawn_queue := [] # Очередь монстров для появления на поле
var _scheduled_spawns := [] # [{hp:int, x:int, y:int, spawn_after_player_turns:int}]
var _use_scheduled_spawns: bool = false
var _player_turn_counter: int = 0
var obstacles := [] # 2D массив здоровья препятствий (y: 0..ENEMY_ROWS-1)
var obstacles_initial_hp := [] # Исходный HP препятствий
var obstacles_unbreakable := [] # 2D массив неразрушаемых препятствий
var _obstacle_spawn_on_destroy := {} # "x:y" -> {hp:int,count:int}
var _projectiles := [] # [{x:int, start_y:float, end_y:float, t:float, d:float, delay:float, color:Color, hit_applied:bool, has_target:bool}]
var _active_anims := [] # [{x:int, start_y:int, end_y:int, color:int, t:float, d:float}]
var _enemy_death_anims := [] # [{x:int, y:int, t:float, d:float, hp:int, init:int, id:int}]
var _monster_shakes := {} # monster_id -> {t:float, d:float, intensity:float}
var _board_vfx := [] # [{type:str, pos:Vector2, color:Color, t:float, d:float, scale:float}]
var _level_targets := {} # hp -> required count
var _enemy_move_pending: bool = false
var _enemy_attack_warn_pending: bool = false
var _enemy_attack_warn_time_left: float = 0.0
var _cached_enemy_moves: Array = []
var _cached_mixed_breach_priority: bool = false
var _enemy_move_anims := [] # [{fx:int,fy:int,tx:int,ty:int,hp:int,init:int,t:float,d:float}]
var _moves_total: int = 20
var _moves_left: int = 20

var _needs_ui_update: bool = false
const COINS_PER_REMAINING_BONUS_CHIP := 10
const REFILL_GOLD_PER_HEART := 50
# После оплаты восстановления сердец — сдвиг всех монстров к спавну на столько рядов
const REFILL_ENEMY_SHIFT_ROWS := 1
# Мигание красным перед атакой с переднего ряда (сердце / прорыв)
const ENEMY_ATTACK_WARN_DURATION := 0.55
const ENEMY_ATTACK_WARN_FLASH_HZ := 5.0
# Уникальные столбцы атаки при прорыве (нет сердца в столбце) — для частичного восстановления
var _last_breach_attack_columns: Array = []
# Прорыв в пустой столбец — уровень проигран, нужно окно поражения (не только при 0 сердец везде)
var _defeat_pending_breach: bool = false
# Монстры прорыва по столбцу: после оплаты вернуть на линию сердец (column -> {hp, init})
var _pending_breach_monsters: Dictionary = {}

enum BoosterType { NONE, HAMMER, ROW_BLAST, SHUFFLE, FREEZE }
var _active_booster: BoosterType = BoosterType.NONE
var _is_executing_combo: bool = false
var _freeze_turns: int = 0

# Выбранные предуровневые усиления игрока
var _selected_prelevel_boosts := {
	"bomb": false,
	"arrow": false,
	"rainbow": false
}

# Бонусные фишки от Шлема Морта для текущего уровня
var _mort_helmet_bonus_chips := {}

# Флаги защиты от повторного показа диалогов
var _victory_dialog_shown: bool = false
var _defeat_dialog_shown: bool = false
const LEVEL_END_DIALOG_SCRIPT := preload("res://scripts/level_end_dialog.gd")
const INGAME_BOOSTER_PURCHASE_SCRIPT := preload("res://scripts/ingame_booster_purchase_dialog.gd")
const LEVEL1_TUTORIAL_OVERLAY_SCRIPT := preload("res://scripts/level1_tutorial_overlay.gd")
var _level_end_overlay: Control = null
var _booster_purchase_overlay: Control = null
var _level1_tutorial_overlay: Control = null
# 0 — выкл; 1 — враги; 2 — фишки; 3 — полное затемнение, ожидание снарядов; 4 — цели (показ)
var _level1_tutorial_phase: int = 0
var _level1_tutorial_advancing_to_goals: bool = false
# Сердца в столбцах на _heart_row_y: защита уровня; при старте true, если в клетке нет препятствия
var _column_hearts: Array = []
var _column_hearts_initial: Array = []
# Высота зоны врагов совпадает с размером сетки ENEMY_ROWS (10 рядов); поле enemy_rows в JSON не укорачивает поле
var _enemy_rows_effective: int = ENEMY_ROWS
var _heart_row_y: int = ENEMY_ROWS - 1
var _field_gap_total: float = FIELD_GAP_BASE + HEART_STRIP_HEIGHT

func _ready():
	randomize()
	var cfg = LevelManager.get_level_config(LevelManager.current_level)
	_enemy_rows_effective = ENEMY_ROWS
	_heart_row_y = ENEMY_ROWS - 1
	_field_gap_total = FIELD_GAP_BASE + HEART_STRIP_HEIGHT
	_init_chips()
	_init_obstacles_from_config(cfg)
	_init_enemies_from_config(cfg)
	_init_moves_from_config(cfg)
	_init_column_hearts()
	_init_ui()
	_update_ui()
	queue_redraw()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	set_process(true) # Всегда активен для idle-анимаций монстров
	
	# Получаем предуровневые усиления из LevelManager (переданные из главного меню)
	_selected_prelevel_boosts = LevelManager.selected_prelevel_boosts
	_mort_helmet_bonus_chips = LevelManager.get_mort_helmet_bonus_chips()
	
	# Спавним бонусные фишки на старте уровня
	_spawn_bonus_chips_at_start()
	
	# Кнопка "В меню"
	var back_btn = find_child("BackToMenu", true, false)
	if back_btn != null:
		back_btn.pressed.connect(func():
			if LevelManager.is_editor_test_mode():
				_return_to_editor_after_test()
			else:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
		# Стилизация кнопки "Назад"
		back_btn.add_theme_font_size_override("font_size", 40)
		back_btn.add_theme_color_override("font_color", Color.WHITE)
		back_btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		back_btn.add_theme_constant_override("outline_size", 6)
		
		var back_style = StyleBoxFlat.new()
		back_style.bg_color = Color(0.15, 0.2, 0.3, 0.9)
		back_style.set_corner_radius_all(40) # Круглая кнопка
		back_style.border_width_left = 3
		back_style.border_width_top = 3
		back_style.border_width_right = 3
		back_style.border_width_bottom = 3
		back_style.border_color = Color(0.8, 0.7, 0.3, 1.0) # Золотая рамка
		
		back_btn.add_theme_stylebox_override("normal", back_style)
		back_btn.add_theme_stylebox_override("hover", back_style)
		back_btn.add_theme_stylebox_override("pressed", back_style)
		back_btn.focus_mode = Control.FOCUS_NONE
	
	call_deferred("_start_level1_tutorial_if_needed")

func _rect_global_to_overlay_local(overlay: Control, global_rect: Rect2) -> Rect2:
	var inv: Transform2D = overlay.get_global_transform_with_canvas().affine_inverse()
	var p0: Vector2 = inv * global_rect.position
	var p1: Vector2 = inv * (global_rect.position + global_rect.size)
	return Rect2(p0, p1 - p0)

func _start_level1_tutorial_if_needed() -> void:
	if LevelManager.current_level != 1:
		return
	_level1_tutorial_phase = 1
	var overlay = _attach_level1_tutorial_overlay()
	var enemy_r = _rect_global_to_overlay_local(overlay, _get_enemy_field_rect_viewport())
	var intro_text = "На вас нападают монстры, не дайте им забрать ваши жизни. Если монстры не получили урон, они будут двигаться к вам. Нажмите чтобы продолжить..."
	await overlay.begin_enemy_step(enemy_r, intro_text)

func _attach_level1_tutorial_overlay() -> Control:
	if _level1_tutorial_overlay != null and is_instance_valid(_level1_tutorial_overlay):
		return _level1_tutorial_overlay
	var ui = find_child("UIRoot", true, false)
	var parent: Node = self if ui == null else ui
	var overlay = Control.new()
	overlay.set_script(LEVEL1_TUTORIAL_OVERLAY_SCRIPT)
	overlay.z_index = 180
	parent.add_child(overlay)
	overlay.set_board(self)
	if not overlay.step_advanced.is_connected(_on_level1_tutorial_after_enemy_intro):
		overlay.step_advanced.connect(_on_level1_tutorial_after_enemy_intro)
	if not overlay.tutorial_finished.is_connected(_on_level1_tutorial_finished):
		overlay.tutorial_finished.connect(_on_level1_tutorial_finished)
	_level1_tutorial_overlay = overlay
	return overlay

func _get_enemy_field_rect_viewport() -> Rect2:
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var sz = Vector2(float(COLS) * CELL_SIZE, float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT)
	var tl = to_global(origin)
	var br = to_global(origin + sz)
	return Rect2(tl, br - tl)

func _get_player_field_rect_viewport() -> Rect2:
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var top_y = origin.y + float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT + _field_gap_total
	var sz = Vector2(float(COLS) * CELL_SIZE, float(PLAYER_ROWS) * CELL_SIZE)
	var tl = to_global(Vector2(origin.x, top_y))
	var br = to_global(Vector2(origin.x, top_y) + sz)
	return Rect2(tl, br - tl)

func _get_goals_container_rect_viewport() -> Rect2:
	var gc = find_child("GoalsContainer", true, false)
	if gc == null:
		return Rect2()
	return gc.get_global_rect()

func _on_level1_tutorial_after_enemy_intro() -> void:
	if _level1_tutorial_phase != 1:
		return
	_level1_tutorial_phase = 2
	var overlay = _attach_level1_tutorial_overlay()
	var player_r = _rect_global_to_overlay_local(overlay, _get_player_field_rect_viewport())
	await overlay.begin_chips_step(player_r, "Нажми на фишки одного цвета, чтобы выпустить снаряды во врагов.")

func _on_level1_tutorial_finished() -> void:
	_level1_tutorial_phase = 0
	_level1_tutorial_advancing_to_goals = false
	if _level1_tutorial_overlay != null and is_instance_valid(_level1_tutorial_overlay):
		_level1_tutorial_overlay.queue_free()
	_level1_tutorial_overlay = null
	queue_redraw()

func tutorial_forward_chip_click(screen_pos: Vector2) -> void:
	if _level1_tutorial_phase != 2:
		return
	if not _active_anims.is_empty() or not _projectiles.is_empty() or _is_executing_combo:
		return
	if _active_booster != BoosterType.NONE:
		return
	if _level1_tutorial_overlay != null and is_instance_valid(_level1_tutorial_overlay):
		_level1_tutorial_overlay.show_full_screen_dim()
	var cell = _point_to_cell(screen_pos)
	if cell.x < 0 or cell.y < ENEMY_ROWS:
		if _level1_tutorial_overlay != null and is_instance_valid(_level1_tutorial_overlay):
			_level1_tutorial_overlay.restore_chips_step_after_failed_pop()
		return
	var popped = await _pop_cluster(cell.x, cell.y)
	if popped > 0:
		_update_ui()
		_level1_tutorial_phase = 3
	else:
		if _level1_tutorial_overlay != null and is_instance_valid(_level1_tutorial_overlay):
			_level1_tutorial_overlay.restore_chips_step_after_failed_pop()

func _try_advance_level1_tutorial_to_goals_step() -> void:
	if _level1_tutorial_phase != 3:
		return
	if _level1_tutorial_advancing_to_goals:
		return
	if not _projectiles.is_empty():
		return
	if not _active_anims.is_empty():
		return
	if not _enemy_death_anims.is_empty():
		return
	if _level1_tutorial_overlay == null or not is_instance_valid(_level1_tutorial_overlay):
		return
	_level1_tutorial_advancing_to_goals = true
	_level1_tutorial_phase = 4
	call_deferred("_run_level1_goals_tutorial_step")

func _run_level1_goals_tutorial_step() -> void:
	var overlay = _level1_tutorial_overlay
	if overlay == null or not is_instance_valid(overlay):
		_level1_tutorial_advancing_to_goals = false
		return
	var goals_r = _rect_global_to_overlay_local(overlay, _get_goals_container_rect_viewport())
	await overlay.begin_goals_step(goals_r, "Уничтожь все цели, чтобы пройти уровень.")
	_level1_tutorial_advancing_to_goals = false

func _init_ui():
	# Настройка верхней панели
	if has_node("CanvasUI/UIRoot/TopBarBg"):
		var bg = get_node("CanvasUI/UIRoot/TopBarBg")
		bg.custom_minimum_size.y = UI_TOP_MARGIN
		bg.offset_bottom = UI_TOP_MARGIN
		
		# Создаем золотую окантовку через StyleBox
		var border = Panel.new()
		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.12, 0.16, 1.0) # Полностью непрозрачный
		sb.border_width_bottom = 3
		sb.border_color = Color(0.8, 0.7, 0.3, 1.0) # Золото
		sb.shadow_color = Color(0, 0, 0, 0.5)
		sb.shadow_size = 4
		
		border.add_theme_stylebox_override("panel", sb)
		bg.add_child(border)
	
	# Полная пересборка TopBar для надежности отображения жизней и монет
	var tb = find_child("TopBar", true, false)
	if tb:
		tb.custom_minimum_size.y = UI_TOP_MARGIN
		tb.offset_bottom = UI_TOP_MARGIN
		tb.alignment = BoxContainer.ALIGNMENT_BEGIN
		tb.add_theme_constant_override("separation", 30)
		
		# Удаляем старые контейнеры, чтобы создать их заново в нужном порядке
		for child in tb.get_children():
			if child.name.begins_with("Lives") or child.name.begins_with("Moves") or child.name.begins_with("Coins"):
				child.name = "deleted_" + child.name
				child.queue_free()
		
		# 1. Жизни (крайний левый элемент)
		var lc = VBoxContainer.new()
		lc.name = "LivesContainerNew"
		lc.custom_minimum_size = Vector2(90, 0)
		lc.add_theme_constant_override("separation", -8)
		lc.alignment = BoxContainer.ALIGNMENT_CENTER
		tb.add_child(lc)
		tb.move_child(lc, 0)
		
		var l_title = Label.new()
		l_title.text = "ЖИЗНИ"
		l_title.add_theme_font_size_override("font_size", 14)
		l_title.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		l_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lc.add_child(l_title)
		
		var l_count = Label.new()
		l_count.name = "LivesCount"
		l_count.text = str(_count_column_hearts_remaining())
		l_count.add_theme_font_size_override("font_size", 42)
		l_count.add_theme_color_override("font_color", Color.WHITE)
		l_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l_count.add_theme_constant_override("outline_size", 5)
		l_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lc.add_child(l_count)
		
		# 2. Монеты (после жизней)
		var cc = VBoxContainer.new()
		cc.name = "CoinsContainerNew"
		cc.custom_minimum_size = Vector2(110, 0)
		cc.add_theme_constant_override("separation", -8)
		cc.alignment = BoxContainer.ALIGNMENT_CENTER
		tb.add_child(cc)
		tb.move_child(cc, 1)
		
		var c_title = Label.new()
		c_title.text = "МОНЕТЫ"
		c_title.add_theme_font_size_override("font_size", 14)
		c_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cc.add_child(c_title)
		
		var c_count = Label.new()
		c_count.name = "CoinsCount"
		c_count.text = str(LevelManager.get_coins())
		c_count.add_theme_font_size_override("font_size", 38)
		c_count.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		c_count.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0, 0.9))
		c_count.add_theme_constant_override("outline_size", 5)
		c_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cc.add_child(c_count)

	# Оформление кнопок бустеров
	var booster_types = [BoosterType.HAMMER, BoosterType.ROW_BLAST, BoosterType.SHUFFLE, BoosterType.FREEZE]
	var icon_paths = [
		"res://textures/Booster_Hummer.png",
		"res://textures/Booster_Arrows.png",
		"res://textures/Booster_Refresh.png",
		"res://textures/Booster_Snow.png"
	]
	
	for i in range(4):
		var name = "Booster" + str(i+1)
		if has_node("CanvasUI/UIRoot/BottomBar/" + name):
			var btn: Button = get_node("CanvasUI/UIRoot/BottomBar/" + name)
			
			# Загрузка иконки
			if icon_paths[i] != "":
				var tex = load(icon_paths[i])
				if tex:
					btn.icon = tex
					btn.expand_icon = true
					btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
					btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# Настройка шрифта для счетчика (теперь отдельная метка в углу)
			var count_label = Label.new()
			count_label.name = "CountLabel"
			count_label.text = "0"
			count_label.add_theme_font_size_override("font_size", 28)
			count_label.add_theme_color_override("font_color", Color.WHITE)
			count_label.add_theme_color_override("font_outline_color", Color.BLACK)
			count_label.add_theme_constant_override("outline_size", 8)
			
			# Тень для текста
			count_label.add_theme_constant_override("shadow_offset_x", 2)
			count_label.add_theme_constant_override("shadow_offset_y", 2)
			count_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
			
			# Позиционирование: правый нижний угол кнопки
			count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			count_label.offset_left = -40
			count_label.offset_top = -40
			count_label.offset_right = -5
			count_label.offset_bottom = -5
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			btn.add_child(count_label)
			btn.text = "" # Очищаем основной текст кнопки
			btn.clip_contents = false
			
			# Создание красивого стиля (идеально круглые кнопки)
			var normal := StyleBoxFlat.new()
			normal.bg_color = Color(0.15, 0.2, 0.3, 0.85) # Глубокий синий
			normal.set_corner_radius_all(40) # Идеальный круг для кнопок 80x80
			normal.border_width_left = 3
			normal.border_width_top = 3
			normal.border_width_right = 3
			normal.border_width_bottom = 3
			normal.border_color = Color(0.8, 0.7, 0.3, 1.0) # Золотистая рамка
			normal.shadow_color = Color(0, 0, 0, 0.4)
			normal.shadow_size = 4
			normal.shadow_offset = Vector2(0, 3)
			
			var hover := normal.duplicate()
			hover.bg_color = Color(0.25, 0.35, 0.5, 0.9)
			hover.border_color = Color(1.0, 0.9, 0.5, 1.0)
			
			var active_style := normal.duplicate()
			active_style.bg_color = Color(0.9, 0.7, 0.2, 1.0) # Яркое золото при активации
			active_style.border_color = Color(1.0, 1.0, 0.8, 1.0)
			active_style.shadow_offset = Vector2(0, 1)
			
			var disabled := normal.duplicate()
			disabled.bg_color = Color(0.1, 0.1, 0.1, 0.6)
			disabled.border_color = Color(0.3, 0.3, 0.3, 1.0)
			disabled.shadow_size = 0
			
			btn.add_theme_stylebox_override("normal", normal)
			btn.add_theme_stylebox_override("hover", hover)
			btn.add_theme_stylebox_override("pressed", active_style)
			btn.add_theme_stylebox_override("disabled", disabled)
			
			var type = booster_types[i]
			btn.pressed.connect(func(): _on_booster_clicked(type, btn))
			btn.focus_mode = Control.FOCUS_NONE

func _on_booster_clicked(type: BoosterType, btn: Button):
	if type == BoosterType.NONE: return
	
	var lm_type = _convert_to_lm_booster_type(type)
	var count = LevelManager.get_booster_count(lm_type)
	
	if count <= 0:
		_show_buy_booster_dialog(lm_type)
		return
	
	# Если это мгновенный бустер (Перемешивание)
	if type == BoosterType.SHUFFLE:
		_apply_booster_shuffle()
		LevelManager.use_booster(lm_type)
		_update_ui()
		return
	
	# Если бустер требует выбора цели
	if _active_booster == type:
		_active_booster = BoosterType.NONE
	else:
		_active_booster = type
	
	_update_booster_buttons_visual()

func _convert_to_lm_booster_type(type: BoosterType) -> int:
	match type:
		BoosterType.HAMMER: return LevelManager.BoosterType.HAMMER
		BoosterType.ROW_BLAST: return LevelManager.BoosterType.ROW_BLAST
		BoosterType.SHUFFLE: return LevelManager.BoosterType.SHUFFLE
		BoosterType.FREEZE: return LevelManager.BoosterType.FREEZE
	return LevelManager.BoosterType.HAMMER

func _lm_booster_type_to_shop_icon_index(lm_type: int) -> int:
	match lm_type:
		LevelManager.BoosterType.HAMMER: return 0
		LevelManager.BoosterType.ROW_BLAST: return 1
		LevelManager.BoosterType.SHUFFLE: return 2
		LevelManager.BoosterType.FREEZE: return 3
	return -1

func _dismiss_booster_purchase_overlay() -> void:
	if _booster_purchase_overlay != null and is_instance_valid(_booster_purchase_overlay):
		_booster_purchase_overlay.queue_free()
	_booster_purchase_overlay = null

func _show_buy_booster_dialog(lm_type: int) -> void:
	var booster_names = {
		LevelManager.BoosterType.HAMMER: "Молоток",
		LevelManager.BoosterType.ROW_BLAST: "Стрела",
		LevelManager.BoosterType.SHUFFLE: "Перемешивание",
		LevelManager.BoosterType.FREEZE: "Заморозка"
	}
	var shop_icon_paths = [
		"res://textures/Booster_Hummer.png",
		"res://textures/Booster_Arrows.png",
		"res://textures/Booster_Refresh.png",
		"res://textures/Booster_Snow.png"
	]
	var booster_name = booster_names.get(lm_type, "Бустер")
	var cost = LevelManager.INGAME_BOOSTER_PACK_COST
	var pack_qty = LevelManager.get_ingame_booster_pack_quantity(lm_type)
	var player_coins = LevelManager.get_coins()
	var can_afford = player_coins >= cost
	_dismiss_booster_purchase_overlay()
	var icon_idx = _lm_booster_type_to_shop_icon_index(lm_type)
	var icon_tex: Texture2D = null
	if icon_idx >= 0 and icon_idx < shop_icon_paths.size():
		var loaded = load(shop_icon_paths[icon_idx])
		if loaded is Texture2D:
			icon_tex = loaded
	var ui = find_child("UIRoot", true, false)
	var parent: Node = self if ui == null else ui
	var overlay = Control.new()
	overlay.set_script(INGAME_BOOSTER_PURCHASE_SCRIPT)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 190
	parent.add_child(overlay)
	_booster_purchase_overlay = overlay
	overlay.setup(booster_name, icon_tex, cost, pack_qty, player_coins, can_afford)
	overlay.purchase_pressed.connect(func(): _on_ingame_booster_purchase_confirm(lm_type))
	overlay.closed_pressed.connect(_on_ingame_booster_purchase_closed)

func _on_ingame_booster_purchase_confirm(lm_type: int) -> void:
	_dismiss_booster_purchase_overlay()
	if LevelManager.buy_booster(lm_type):
		_update_ui()
		queue_redraw()

func _on_ingame_booster_purchase_closed() -> void:
	_dismiss_booster_purchase_overlay()

func _update_booster_buttons_visual():
	for i in range(1, 5): # Все 4 бустера
		var btn = get_node("CanvasUI/UIRoot/BottomBar/Booster" + str(i))
		if _active_booster != BoosterType.NONE and i == int(_active_booster):
			btn.modulate = Color(1.5, 1.5, 1.0) # Подсветка активного
		else:
			btn.modulate = Color(1, 1, 1)

func _update_ui():
	# Обновление жизней
	var lc_lbl = find_child("LivesCount", true, false)
	if lc_lbl:
		var hearts_left = _count_column_hearts_remaining()
		lc_lbl.text = str(hearts_left)
		lc_lbl.add_theme_font_size_override("font_size", 42)
		lc_lbl.add_theme_color_override("font_color", Color.WHITE)
		lc_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lc_lbl.add_theme_constant_override("outline_size", 5)
		if hearts_left <= 1:
			lc_lbl.modulate = Color(1.0, 0.2, 0.2)
		else:
			lc_lbl.modulate = Color(1, 1, 1)

	# Обновление монет
	var coins_lbl = find_child("CoinsCount", true, false)
	if coins_lbl:
		coins_lbl.text = str(LevelManager.get_coins())
		coins_lbl.add_theme_font_size_override("font_size", 38)
		coins_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		coins_lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0, 0.9))
		coins_lbl.add_theme_constant_override("outline_size", 5)

	# Обновление целей в GoalsContainer
	if has_node("CanvasUI/UIRoot/TopBar/GoalsContainer"):
		var gc: HBoxContainer = get_node("CanvasUI/UIRoot/TopBar/GoalsContainer")
		# Очищаем старые элементы целей
		for child in gc.get_children():
			child.queue_free()
		
		if _level_targets.is_empty():
			var l = Label.new()
			l.text = "НЕТ ЦЕЛЕЙ"
			l.add_theme_font_size_override("font_size", 28)
			l.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
			l.add_theme_constant_override("outline_size", 3)
			gc.add_child(l)
		else:
			var keys := _level_targets.keys()
			keys.sort()
			for hp in keys:
				var count = int(_level_targets[hp])
				if count > 0:
					var item = HBoxContainer.new()
					item.add_theme_constant_override("separation", 8)
					
					# Иконка цели (теперь текстура монстра)
					var icon = TextureRect.new()
					var m_tex = MONSTER_TEXTURES.get(hp)
					if m_tex:
						icon.texture = m_tex
						icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
						icon.custom_minimum_size = Vector2(48, 48)
					else:
						# Фолбэк на цветной квадрат
						var rect = ColorRect.new()
						rect.custom_minimum_size = Vector2(32, 32)
						rect.color = _get_monster_color(hp)
						icon.add_child(rect)
					
					var lbl = Label.new()
					lbl.text = str(count)
					lbl.add_theme_font_size_override("font_size", 36)
					lbl.add_theme_color_override("font_color", Color.WHITE)
					lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
					lbl.add_theme_constant_override("outline_size", 4)
					
					item.add_child(icon)
					item.add_child(lbl)
					gc.add_child(item)

	# Обновление кнопок бустеров (названия и количество)
	var booster_types = [BoosterType.HAMMER, BoosterType.ROW_BLAST, BoosterType.SHUFFLE, BoosterType.FREEZE]
	for i in range(4):
		var type = booster_types[i]
		var btn_path = "CanvasUI/UIRoot/BottomBar/Booster" + str(i+1)
		if has_node(btn_path):
			var btn: Button = get_node(btn_path)
			var lm_type = _convert_to_lm_booster_type(type)
			var count = LevelManager.get_booster_count(lm_type)
			# Обновляем текст метки количества
			if btn.has_node("CountLabel"):
				var lbl: Label = btn.get_node("CountLabel")
				lbl.text = str(count)
			
			btn.disabled = false
			if count <= 0:
				btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
			else:
				btn.modulate = Color(1, 1, 1, 1)

func _init_chips():
	chips.clear()
	for y in range(ROWS):
		var row := []
		for x in range(COLS):
			var idx := -1
			if y >= ENEMY_ROWS:
				idx = int(randi() % CHIP_COLORS.size())
			row.append(idx)
		chips.append(row)

func _init_enemies_from_config(cfg: Dictionary):
	enemies.clear()
	enemies_initial_hp.clear()
	_enemies_hit_this_turn.clear()
	_level_targets.clear()
	_monster_spawn_queue.clear()
	_scheduled_spawns.clear()
	_use_scheduled_spawns = false
	_player_turn_counter = 0
	
	# Подготовим пустую сетку HP=0
	for y in range(ENEMY_ROWS):
		var row := []
		var row0 := []
		var row_hit := []
		for x in range(COLS):
			row.append(0)
			row0.append(0)
			row_hit.append(false)
		enemies.append(row)
		enemies_initial_hp.append(row0)
		_enemies_hit_this_turn.append(row_hit)

	# Новый режим: стартовые монстры + управляемые отложенные спавны
	if cfg.has("start_monsters") and typeof(cfg.start_monsters) == TYPE_ARRAY:
		_use_scheduled_spawns = true
		for item in cfg.start_monsters:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var hp = max(1, int(item.get("hp", 1)))
			var x = int(item.get("x", -1))
			var y = int(item.get("y", -1))
			if x < 0 or x >= COLS or y < 0 or y >= ENEMY_ROWS:
				continue
			if obstacles[y][x] > 0:
				continue
			if enemies[y][x] == 0:
				enemies[y][x] = hp
				enemies_initial_hp[y][x] = hp
				_level_targets[hp] = int(_level_targets.get(hp, 0)) + 1

	if cfg.has("scheduled_spawns") and typeof(cfg.scheduled_spawns) == TYPE_ARRAY:
		_use_scheduled_spawns = true
		for item in cfg.scheduled_spawns:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var hp = max(1, int(item.get("hp", 1)))
			var x = clamp(int(item.get("x", 0)), 0, COLS - 1)
			var y = clamp(int(item.get("y", 0)), 0, ENEMY_ROWS - 1)
			var turn_n = max(0, int(item.get("spawn_after_player_turns", 0)))
			var count = max(1, int(item.get("count", 1)))
			for i in range(count):
				_scheduled_spawns.append({
					"hp": hp,
					"x": x,
					"y": y,
					"spawn_after_player_turns": turn_n
				})
				_level_targets[hp] = int(_level_targets.get(hp, 0)) + 1

	if _use_scheduled_spawns:
		return

	# Legacy режим: старая очередь монстров
	var all_monsters := []
	if cfg.has("monster_tiers") and typeof(cfg.monster_tiers) == TYPE_ARRAY:
		for tier in cfg.monster_tiers:
			if typeof(tier) == TYPE_DICTIONARY and tier.has("hp") and tier.has("count"):
				var hp = int(tier.hp)
				var cnt = int(tier.count)
				_level_targets[hp] = int(_level_targets.get(hp, 0)) + cnt
				for i in range(cnt):
					all_monsters.append(hp)
	else:
		var total_capacity = ENEMY_ROWS * COLS
		var strong_count = int(cfg.get("strong_monsters", 0))
		var strong_hp = int(cfg.get("strong_hp", 3))
		var normal_count = total_capacity - strong_count
		
		for i in range(strong_count):
			all_monsters.append(strong_hp)
			_level_targets[strong_hp] = int(_level_targets.get(strong_hp, 0)) + 1
		for i in range(normal_count):
			all_monsters.append(1)
			_level_targets[1] = int(_level_targets.get(1, 0)) + 1
	
	all_monsters.shuffle()
	_monster_spawn_queue = all_monsters

	# Начальное заполнение: три ряда монстров; на уровне 1 — по центру поля врагов, иначе сверху
	var initial_rows := 3
	var y_start := 0
	if LevelManager.current_level == 1:
		y_start = int((ENEMY_ROWS - initial_rows) / 2)
	for y in range(y_start, y_start + initial_rows):
		if y < 0 or y >= ENEMY_ROWS:
			continue
		for x in range(COLS):
			# Проверяем, что в клетке нет препятствия
			if obstacles.size() > y and obstacles[y].size() > x and obstacles[y][x] > 0:
				continue
			if not _monster_spawn_queue.is_empty():
				var hp = _monster_spawn_queue.pop_front()
				enemies[y][x] = hp
				enemies_initial_hp[y][x] = hp

func _decrement_level_target_for_init_hp(init_hp: int) -> void:
	if _level_targets.has(init_hp):
		_level_targets[init_hp] = max(0, int(_level_targets[init_hp]) - 1)

func _increment_level_target_for_init_hp(init_hp: int) -> void:
	if _level_targets.has(init_hp):
		_level_targets[init_hp] = int(_level_targets[init_hp]) + 1
	else:
		_level_targets[init_hp] = 1

func _init_obstacles_from_config(cfg: Dictionary):
	obstacles.clear()
	obstacles_initial_hp.clear()
	obstacles_unbreakable.clear()
	_obstacle_spawn_on_destroy.clear()
	
	for y in range(ENEMY_ROWS):
		var row := []
		var row_init := []
		var row_wall := []
		for x in range(COLS):
			row.append(0)
			row_init.append(0)
			row_wall.append(false)
		obstacles.append(row)
		obstacles_initial_hp.append(row_init)
		obstacles_unbreakable.append(row_wall)
	
	if cfg.has("obstacles") and typeof(cfg.obstacles) == TYPE_ARRAY:
		for obs in cfg.obstacles:
			if typeof(obs) == TYPE_DICTIONARY and obs.has("x") and obs.has("y"):
				var ox = int(obs.x)
				var oy = int(obs.y)
				if oy >= 0 and oy < ENEMY_ROWS and ox >= 0 and ox < COLS:
					var o_type = str(obs.get("type", "breakable"))
					if o_type == "wall":
						obstacles[oy][ox] = 1
						obstacles_initial_hp[oy][ox] = 1
						obstacles_unbreakable[oy][ox] = true
					else:
						var hp = max(1, int(obs.get("hp", 1)))
						obstacles[oy][ox] = hp
						obstacles_initial_hp[oy][ox] = hp
					if obs.has("spawn_on_destroy") and typeof(obs.spawn_on_destroy) == TYPE_DICTIONARY:
						var sp = obs.spawn_on_destroy
						var shp = max(1, int(sp.get("hp", 1)))
						var scnt = max(1, int(sp.get("count", 1)))
						_obstacle_spawn_on_destroy["%d:%d" % [ox, oy]] = {"hp": shp, "count": scnt}

func _count_column_hearts_remaining() -> int:
	var n = 0
	for x in range(min(COLS, _column_hearts.size())):
		if _column_hearts[x]:
			n += 1
	return n

func _init_column_hearts() -> void:
	_column_hearts.clear()
	_column_hearts_initial.clear()
	_last_breach_attack_columns.clear()
	_pending_breach_monsters.clear()
	_defeat_pending_breach = false
	for x in range(COLS):
		var blocked = obstacles.size() > _heart_row_y and obstacles[_heart_row_y].size() > x and obstacles[_heart_row_y][x] > 0
		var has_heart = not blocked
		_column_hearts.append(has_heart)
		_column_hearts_initial.append(has_heart)

func _hearts_lost_in_attack_columns() -> int:
	var n = 0
	for cx in _last_breach_attack_columns:
		var x = int(cx)
		if x >= 0 and x < _column_hearts_initial.size() and _column_hearts_initial[x]:
			if not _column_hearts[x]:
				n += 1
	return n

func _breach_refill_unit_count() -> int:
	if _last_breach_attack_columns.is_empty():
		return 0
	var lost = _hearts_lost_in_attack_columns()
	if lost > 0:
		return lost
	return _last_breach_attack_columns.size()

func _compute_refill_cost_after_breach() -> int:
	var k = _breach_refill_unit_count()
	if k <= 0:
		return 0
	return REFILL_GOLD_PER_HEART * k

func _find_free_enemy_cell_in_column_from(x: int, start_y: int) -> int:
	var y = clampi(start_y, 0, ENEMY_ROWS - 1)
	while y < ENEMY_ROWS:
		if enemies.size() > y and enemies[y].size() > x and enemies[y][x] == 0:
			if obstacles.size() > y and obstacles[y].size() > x and obstacles[y][x] > 0:
				y += 1
				continue
			return y
		y += 1
	return -1

func _shift_all_enemies_toward_spawn(rows: int) -> void:
	if rows <= 0:
		return
	var new_hp: Array = []
	var new_init: Array = []
	for yy in range(ENEMY_ROWS):
		var rh := []
		var ri := []
		for xx in range(COLS):
			rh.append(0)
			ri.append(0)
		new_hp.append(rh)
		new_init.append(ri)
	for x in range(COLS):
		var stack := []
		for y in range(ENEMY_ROWS):
			if enemies.size() > y and enemies[y].size() > x and enemies[y][x] > 0:
				stack.append({"y": y, "hp": enemies[y][x], "init": enemies_initial_hp[y][x]})
		stack.sort_custom(func(a, b): return a.y < b.y)
		for it in stack:
			var want_y = clampi(int(it.y) - rows, 0, ENEMY_ROWS - 1)
			var ny = want_y
			while ny < ENEMY_ROWS and (new_hp[ny][x] > 0 or (obstacles.size() > ny and obstacles[ny].size() > x and obstacles[ny][x] > 0)):
				ny += 1
			if ny < ENEMY_ROWS:
				new_hp[ny][x] = it.hp
				new_init[ny][x] = it.init
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			enemies[y][x] = new_hp[y][x]
			enemies_initial_hp[y][x] = new_init[y][x]

func _apply_partial_refill_after_breach_paid() -> void:
	_defeat_pending_breach = false
	for cx in _last_breach_attack_columns:
		var x = int(cx)
		if x >= 0 and x < _column_hearts.size():
			_column_hearts[x] = true
	_last_breach_attack_columns.clear()
	var pending_copy: Dictionary = {}
	for k in _pending_breach_monsters.keys():
		pending_copy[k] = _pending_breach_monsters[k]
	_pending_breach_monsters.clear()
	for k in pending_copy.keys():
		var dat = pending_copy[k]
		_increment_level_target_for_init_hp(int(dat.get("init", 1)))
	for k in pending_copy.keys():
		var cx = int(k)
		var dat = pending_copy[k]
		var mhp = int(dat.get("hp", 1))
		var ihp = int(dat.get("init", mhp))
		if cx < 0 or cx >= COLS:
			continue
		var place_y = _heart_row_y
		var blocked_here = obstacles.size() > place_y and obstacles[place_y].size() > cx and obstacles[place_y][cx] > 0
		if enemies[place_y][cx] > 0 or blocked_here:
			var alt = _find_free_enemy_cell_in_column_from(cx, _heart_row_y)
			if alt >= 0:
				place_y = alt
		if enemies[place_y][cx] == 0:
			enemies[place_y][cx] = mhp
			enemies_initial_hp[place_y][cx] = ihp
	_shift_all_enemies_toward_spawn(REFILL_ENEMY_SHIFT_ROWS)
	_defeat_dialog_shown = false
	_needs_ui_update = true
	queue_redraw()

func _clear_board_vfx_after_refill() -> void:
	_enemy_move_anims.clear()
	_enemy_death_anims.clear()
	_projectiles.clear()
	_monster_shakes.clear()
	_needs_ui_update = true

func _grid_origin(vp_size: Vector2) -> Vector2:
	var grid_size = Vector2(COLS * CELL_SIZE, ENEMY_ROWS * ENEMY_CELL_HEIGHT + PLAYER_ROWS * CELL_SIZE + _field_gap_total)
	var ox = (vp_size.x - grid_size.x) * 0.5
	var usable_h = vp_size.y - UI_TOP_MARGIN - UI_BOTTOM_MARGIN
	var oy = ((usable_h - grid_size.y) * 0.95) + UI_TOP_MARGIN
	return Vector2(ox, oy)

func _on_viewport_size_changed():
	_update_ui()
	queue_redraw()

func _draw():
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	
	# Применяем тряску экрана к началу координат
	for vfx in _board_vfx:
		if vfx.type == "shake":
			var k_shake = 1.0 - (vfx.t / vfx.d)
			origin += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * vfx.intensity * k_shake
	
	var grid_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE + _field_gap_total)

	# Рисуем текстурный фон самым первым слоем
	if GAME_BG_TEXTURE:
		draw_texture_rect(GAME_BG_TEXTURE, Rect2(Vector2.ZERO, vp_size), false)

	# Заливка зон
	var enemy_rect = Rect2(origin, Vector2(COLS * CELL_SIZE, ENEMY_ROWS * ENEMY_CELL_HEIGHT))
	var player_rect = Rect2(Vector2(origin.x, origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + _field_gap_total), Vector2(COLS * CELL_SIZE, PLAYER_ROWS * CELL_SIZE))
	
	# Рисуем зону врагов (тайлы пола с объемной тенью)
	var enemy_sb = StyleBoxFlat.new()
	enemy_sb.bg_color = Color(0, 0, 0, 0.4) # Темная подложка
	enemy_sb.set_corner_radius_all(10.0)
	enemy_sb.shadow_color = Color(0, 0, 0, 0.6)
	enemy_sb.shadow_size = 15
	enemy_sb.shadow_offset = Vector2(0, 5)
	draw_style_box(enemy_sb, enemy_rect)
	
	if ENEMY_TILE_TEXTURE:
		var tile_h = ENEMY_CELL_HEIGHT # Возвращаем полную высоту, чтобы плитки прижимались друг к другу
		for y in range(ENEMY_ROWS):
			for x in range(COLS):
				var tile_pos = origin + Vector2(float(x) * CELL_SIZE, float(y) * ENEMY_CELL_HEIGHT)
				draw_texture_rect(ENEMY_TILE_TEXTURE, Rect2(tile_pos, Vector2(CELL_SIZE, tile_h)), false)
	
	var heart_strip_top = origin.y + float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT
	var heart_strip_rect = Rect2(Vector2(origin.x, heart_strip_top), Vector2(float(COLS) * CELL_SIZE, _field_gap_total))
	var strip_sb = StyleBoxFlat.new()
	strip_sb.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	strip_sb.set_corner_radius_all(12.0)
	strip_sb.border_width_bottom = 2
	strip_sb.border_color = Color(0.5, 0.42, 0.2, 0.85)
	draw_style_box(strip_sb, heart_strip_rect)
	var hearts_center_y = heart_strip_top + HEART_STRIP_HEIGHT * 0.5
	for hx in range(min(COLS, _column_hearts.size())):
		if _column_hearts[hx]:
			var cx = origin.x + float(hx) * CELL_SIZE + CELL_SIZE * 0.5
			_draw_column_heart(Vector2(cx, hearts_center_y), min(CELL_SIZE, HEART_STRIP_HEIGHT) * 0.38)
	
	# Рисуем зону игрока (черная заливка)
	var player_sb = StyleBoxFlat.new()
	player_sb.bg_color = Color(0, 0, 0, 0.7) # Черная полупрозрачная заливка
	player_sb.set_corner_radius_all(20.0)
	
	# Рисуем подложку
	draw_style_box(player_sb, player_rect)
	
	# Отрисовка фишек будет происходить позже в основном цикле _draw
	# ...
	# А в самом конце функции мы нарисуем окантовку и ВНУТРЕННЮЮ тень поверх всего
	# Чтобы создать эффект глубины (ямы)

	# Разделительная линия (теперь скрыта за окантовкой StyleBox)
	# var divider_y = origin.y + float(ENEMY_ROWS) * CELL_SIZE
	# draw_line(Vector2(origin.x, divider_y), Vector2(origin.x + grid_size.x, divider_y), Color(0.8, 0.8, 0.9, 0.6), 2.0)

	# Текст целей перенесён в верхнюю панель UI

	# Линии сетки (отключены по просьбе пользователя)
	# for x in range(COLS + 1):
	# 	var px = origin.x + float(x) * CELL_SIZE
	# 	draw_line(Vector2(px, origin.y), Vector2(px, origin.y + grid_size.y), LINE_COLOR, 2.0)
	# for y in range(ROWS + 1):
	# 	var py = origin.y + float(y) * CELL_SIZE
	# 	draw_line(Vector2(origin.x, py), Vector2(origin.x + grid_size.x, py), LINE_COLOR, 2.0)

	# Старый контур зоны фишек удален, так как теперь используется StyleBox выше

	# Предварительно находим все клетки, входящие в группы 8+
	var bonus_cells := {}
	if _active_anims.is_empty():
		var visited_bonus := {}
		for y_b in range(ENEMY_ROWS, ROWS):
			for x_b in range(COLS):
				var key_b = str(x_b) + "," + str(y_b)
				if visited_bonus.has(key_b): continue
				var c_list = _get_cluster_at(x_b, y_b)
				if c_list.is_empty(): continue
				for cc in c_list:
					visited_bonus[str(cc.x)+","+str(cc.y)] = true
				if c_list.size() >= 8:
					for cc in c_list:
						bonus_cells[str(cc.x)+","+str(cc.y)] = 8
				elif c_list.size() == 7:
					for cc in c_list:
						bonus_cells[str(cc.x)+","+str(cc.y)] = 7
				elif c_list.size() == 6:
					for cc in c_list:
						bonus_cells[str(cc.x)+","+str(cc.y)] = 6

	# Собираем цели для анимаций, чтобы не дублировать отрисовку конечных клеток
	var anim_targets := {}
	for a in _active_anims:
		var delay = a.get("delay", 0.0)
		# Считаем клетку занятой на весь период анимации, включая задержку
		if a.t < delay + a.d:
			anim_targets[Vector2i(int(a.x), int(a.end_y))] = true

	# Рисуем фишки в зоне игрока (объёмные квадраты)
	var chip_size = CELL_SIZE * CHIP_SIZE_FACTOR
	var pad = (CELL_SIZE - chip_size) * 0.5
	
	var time_now = Time.get_ticks_msec() * 0.001

	# Враги (монстры) в верхней зоне
	var moving_from := {}
	var moving_to := {}
	
	# Собираем данные об активных перемещениях
	for ma in _enemy_move_anims:
		moving_from[Vector2i(int(ma.fx), int(ma.fy))] = true
		moving_to[Vector2i(int(ma.tx), int(ma.ty))] = true
	
	# 1. Собираем всех монстров (статичных, движущихся и умирающих) для правильной сортировки по глубине (Z-order)
	var monsters_to_draw := []
	
	# Сначала движущиеся
	for ma in _enemy_move_anims:
		var k = clamp(ma.t / ma.d, 0.0, 1.0)
		k = pow(k, 0.8)
		var ix = lerp(float(ma.fx), float(ma.tx), k)
		var iy = lerp(float(ma.fy), float(ma.ty), k)
		
		monsters_to_draw.append({
			"x": ix,
			"y": iy,
			"hp": int(ma.hp),
			"init_hp": int(ma.init),
			"id": ma.fx + ma.fy * 10,
			"sort_y": iy,
			"alpha": 1.0,
			"attack_warn": 0.0
		})
	
	# Затем умирающие (чтобы они тряслись и исчезали)
	for da in _enemy_death_anims:
		var alpha = 1.0 - (da.t / da.d)
		monsters_to_draw.append({
			"x": float(da.x),
			"y": float(da.y),
			"hp": int(da.hp),
			"init_hp": int(da.init),
			"id": da.id,
			"sort_y": float(da.y),
			"alpha": alpha,
			"heart_strip_death": bool(da.get("in_heart_strip", false)),
			"attack_warn": 0.0
		})
	
	# Затем статичные (те, которые не двигаются в данный момент)
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			if enemies.size() > y and enemies[y].size() > x and enemies[y][x] > 0:
				var cell = Vector2i(x, y)
				if moving_from.has(cell) or moving_to.has(cell):
					continue
				# Проверяем, не умирает ли этот монстр (чтобы не рисовать дважды)
				var is_dying = false
				for da in _enemy_death_anims:
					if da.x == x and da.y == y:
						is_dying = true
						break
				if is_dying: continue
				
				var warn_flash = 0.0
				if _is_last_row_attack_warn_cell(x, y):
					warn_flash = _get_last_row_attack_warn_flash_strength()
				monsters_to_draw.append({
					"x": float(x),
					"y": float(y),
					"hp": enemies[y][x],
					"init_hp": enemies_initial_hp[y][x],
					"id": x + y * 10,
					"sort_y": float(y),
					"alpha": 1.0,
					"attack_warn": warn_flash
				})
	
	# Сортируем: монстры с большим Y (ближе к игроку) рисуются ПОЗЖЕ
	monsters_to_draw.sort_custom(func(a, b): return a.sort_y < b.sort_y)
	
	# Отрисовываем препятствия (статичные, всегда на месте)
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			if obstacles.size() > y and obstacles[y].size() > x and obstacles[y][x] > 0:
				var obs_top_left = Vector2(
					origin.x + float(x) * CELL_SIZE,
					origin.y + float(y) * ENEMY_CELL_HEIGHT
				)
				var obs_size = Vector2(CELL_SIZE, ENEMY_CELL_HEIGHT)
				_draw_obstacle(obs_top_left, obs_size, obstacles[y][x], obstacles_initial_hp[y][x], obstacles_unbreakable[y][x])
	
	# Отрисовываем всех монстров в правильном порядке
	var e_chip_size = Vector2(CELL_SIZE * CHIP_SIZE_FACTOR, CELL_SIZE * CHIP_SIZE_FACTOR)
	var e_pad_x = (CELL_SIZE - e_chip_size.x) * 0.5
	for m in monsters_to_draw:
		var shake_off = Vector2.ZERO
		if _monster_shakes.has(m.id):
			var s = _monster_shakes[m.id]
			var k_s = 1.0 - (s.t / s.d)
			shake_off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * s.intensity * k_s
			
		var e_top_left: Vector2
		if m.get("heart_strip_death", false):
			var strip_mid_y = float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT + HEART_STRIP_HEIGHT * 0.5
			e_top_left = Vector2(
				origin.x + m.x * CELL_SIZE + e_pad_x,
				origin.y + strip_mid_y - e_chip_size.y * 0.5
			) + shake_off
		else:
			e_top_left = Vector2(
				origin.x + m.x * CELL_SIZE + e_pad_x,
				origin.y + m.y * ENEMY_CELL_HEIGHT + (ENEMY_CELL_HEIGHT - e_chip_size.y) - 6
			) + shake_off
		_draw_enemy_monster(e_top_left, e_chip_size, m.hp, m.init_hp, m.id, m.alpha, float(m.get("attack_warn", 0.0)))

	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips.size() > y and chips[y].size() > x:
				# Пропускаем клетки активных анимаций — их рисуем отдельно
				if anim_targets.has(Vector2i(x, y)):
					continue
				var idx = chips[y][x]
				# Зона игрока ниже полосы сердец (_field_gap_total)
				var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
				var top_left = Vector2(origin.x + float(x) * CELL_SIZE + pad, origin.y + y_pos + pad)
				
				# Дрожание для будущих бонусов
				if bonus_cells.has(str(x)+","+str(y)):
					# Каждые 2 секунды небольшое дрожание в течение 0.4 сек
					var cycle = fmod(time_now + float(x+y)*0.1, 2.5)
					if cycle < 0.4:
						var intensity = 3.0 * (1.0 - cycle/0.4)
						top_left += Vector2(sin(time_now * 50.0), cos(time_now * 45.0)) * intensity

				var size_v = Vector2(chip_size, chip_size)
				
				if idx == RAINBOW_CHIP_IDX:
					_draw_rainbow_chip(top_left, size_v)
				elif idx == ROW_BONUS_CHIP_IDX:
					_draw_row_bonus_chip(top_left, size_v)
				elif idx == BOMB_CHIP_IDX:
					_draw_bomb_chip(top_left, size_v)
				elif idx >= 0 and idx < CHIP_COLORS.size():
					_draw_chip(top_left, size_v, idx)

	# Движущиеся фишки
	for a in _active_anims:
		var delay = a.get("delay", 0.0)
		var tt = a.t - delay
		if tt < 0.0: continue
		if tt < a.d:
			var k = clamp(tt / a.d, 0.0, 1.0)
			var top_left: Vector2
			var size_v = Vector2(chip_size, chip_size)
			
			if a.get("type", "") == "scale":
				# Анимация появления через скейл
				k = pow(k, 0.5) # Плавный вход
				size_v *= k
				var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (float(a.end_y) - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
				var center = origin + Vector2(float(a.x) * CELL_SIZE + CELL_SIZE * 0.5, y_pos + CELL_SIZE * 0.5)
				top_left = center - size_v * 0.5
			else:
				# Обычное падение/движение
				k = pow(k, 0.65)
				var y_interp = lerp(float(a.start_y), float(a.end_y), k)
				var y_pos = 0.0
				if y_interp < ENEMY_ROWS:
					y_pos = y_interp * ENEMY_CELL_HEIGHT
				else:
					y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y_interp - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
				top_left = Vector2(origin.x + float(a.x) * CELL_SIZE + pad, origin.y + y_pos + pad)
			
			if a.color == RAINBOW_CHIP_IDX:
				_draw_rainbow_chip(top_left, size_v)
			elif a.color == ROW_BONUS_CHIP_IDX:
				_draw_row_bonus_chip(top_left, size_v)
			elif a.color == BOMB_CHIP_IDX:
				_draw_bomb_chip(top_left, size_v)
			else:
				_draw_chip(top_left, size_v, a.color)

	# Снаряды
	for p in _projectiles:
		var tt = p.t - p.delay
		if tt < 0.0:
			continue
		var k2 = clamp(tt / p.d, 0.0, 1.0)
		var k_trail = k2 # Для шлейфа
		k2 = pow(k2, 0.8)
		
		var y_interp2 = lerp(p.start_y, p.end_y, k2)
		var cx = origin.x + float(p.x) * CELL_SIZE + CELL_SIZE * 0.5
		var cy_offset = 0.0
		if y_interp2 < ENEMY_ROWS:
			cy_offset = y_interp2 * ENEMY_CELL_HEIGHT + ENEMY_CELL_HEIGHT * 0.5
		else:
			cy_offset = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y_interp2 - ENEMY_ROWS) * CELL_SIZE + _field_gap_total + CELL_SIZE * 0.5
		var cy = origin.y + cy_offset
		var proj_r = maxf(4.0, float(CELL_SIZE) * 0.1)
		
		# Рисуем шлейф (несколько кружков по траектории назад)
		for i in range(1, 4):
			var trail_k = clamp(k2 - float(i) * 0.05, 0.0, 1.0)
			var trail_y_interp = lerp(p.start_y, p.end_y, trail_k)
			var trail_cy_offset = 0.0
			if trail_y_interp < ENEMY_ROWS:
				trail_cy_offset = trail_y_interp * ENEMY_CELL_HEIGHT + ENEMY_CELL_HEIGHT * 0.5
			else:
				trail_cy_offset = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (trail_y_interp - ENEMY_ROWS) * CELL_SIZE + _field_gap_total + CELL_SIZE * 0.5
			var tcy = origin.y + trail_cy_offset
			var t_alpha = (1.0 - float(i) / 4.0) * 0.5
			draw_circle(Vector2(cx, tcy), proj_r * (1.0 - float(i) * 0.2), Color(p.color.r, p.color.g, p.color.b, t_alpha))

		# Тень
		draw_circle(Vector2(cx, cy + 4), proj_r, Color(0, 0, 0, 0.25))
		# Снаряд (ядро)
		draw_circle(Vector2(cx, cy), proj_r, Color.WHITE) # Яркое ядро
		draw_circle(Vector2(cx, cy), proj_r * 0.8, p.color) # Цветная оболочка
		# Блик
		draw_circle(Vector2(cx - proj_r * 0.3, cy - proj_r * 0.3), proj_r * 0.2, Color.WHITE)

	# Анимации смерти врагов (вспышка поверх клетки)
	for da in _enemy_death_anims:
		var k3 = clamp(da.t / da.d, 0.0, 1.0)
		var ex = origin.x + float(da.x) * CELL_SIZE + CELL_SIZE * 0.5
		var ey = origin.y + float(da.y) * ENEMY_CELL_HEIGHT + ENEMY_CELL_HEIGHT * 0.5
		var max_r = ENEMY_CELL_HEIGHT * 0.45
		var rr = max_r * (0.6 + 0.4 * k3)
		var alpha = 1.0 - k3
		draw_circle(Vector2(ex, ey), rr, Color(1.0, 0.9, 0.3, alpha * 0.9))
		draw_circle(Vector2(ex, ey), rr * 0.7, Color(0.6, 0.2, 0.8, alpha * 0.6))

	# Анимации движения врагов
	# (Теперь отрисовываются вместе со статичными монстрами выше для корректной сортировки по Y)
	
	# ОТРИСОВКА BOARD VFX
	for vfx in _board_vfx:
		var k = vfx.t / vfx.d
		match vfx.type:
			"shockwave":
				var wave_r = CELL_SIZE * 2.0 * k
				var alpha = 1.0 - k
				draw_arc(vfx.pos, wave_r, 0, TAU, 32, Color(vfx.color.r, vfx.color.g, vfx.color.b, alpha), 4.0 * (1.0 - k))
				draw_circle(vfx.pos, wave_r * 0.5, Color(vfx.color.r, vfx.color.g, vfx.color.b, alpha * 0.3))
			"bomb_explosion":
				# Центральная вспышка
				var flash_size = CELL_SIZE * 0.6 * (1.0 - k * 0.5)
				var alpha = 1.0 - k
				draw_circle(vfx.pos, flash_size, Color(vfx.color.r, vfx.color.g, vfx.color.b, alpha))
				draw_circle(vfx.pos, flash_size * 0.5, Color(1, 1, 1, alpha * 0.8))
				
				# Лучи в 4 стороны (крест)
				var ray_length = CELL_SIZE * (0.3 + k * 0.7) # От центра к краю клетки
				var ray_w = 8.0 * (1.0 - k)
				var ray_color = Color(vfx.color.r, vfx.color.g, vfx.color.b, alpha)
				
				# Горизонтальные лучи
				draw_line(vfx.pos - Vector2(ray_length, 0), vfx.pos - Vector2(CELL_SIZE, 0), ray_color, ray_w)
				draw_line(vfx.pos + Vector2(ray_length, 0), vfx.pos + Vector2(CELL_SIZE, 0), ray_color, ray_w)
				
				# Вертикальные лучи
				draw_line(vfx.pos - Vector2(0, ray_length), vfx.pos - Vector2(0, CELL_SIZE), ray_color, ray_w)
				draw_line(vfx.pos + Vector2(0, ray_length), vfx.pos + Vector2(0, CELL_SIZE), ray_color, ray_w)
			"beam":
				var length = COLS * CELL_SIZE
				var w = CELL_SIZE * 0.8 * (1.0 - k)
				draw_line(vfx.pos - Vector2(length, 0), vfx.pos + Vector2(length, 0), Color(vfx.color.r, vfx.color.g, vfx.color.b, 1.0 - k), w)
				draw_line(vfx.pos - Vector2(length, 0), vfx.pos + Vector2(length, 0), Color(1, 1, 1, (1.0 - k) * 0.8), w * 0.4)
			"beam_vertical":
				var length = PLAYER_ROWS * CELL_SIZE
				var w = CELL_SIZE * 0.8 * (1.0 - k)
				draw_line(vfx.pos - Vector2(0, length), vfx.pos + Vector2(0, length), Color(vfx.color.r, vfx.color.g, vfx.color.b, 1.0 - k), w)
				draw_line(vfx.pos - Vector2(0, length), vfx.pos + Vector2(0, length), Color(1, 1, 1, (1.0 - k) * 0.8), w * 0.4)
			"rainbow_link":
				var start_pos = vfx.pos
				var end_pos = vfx.target_pos
				# Рисуем дугу или прямую линию энергии
				var mid = (start_pos + end_pos) * 0.5 + Vector2(0, -50 * sin(k * PI))
				draw_line(start_pos, mid, Color(vfx.color.r, vfx.color.g, vfx.color.b, 1.0 - k), 3.0)
				draw_line(mid, end_pos, Color(vfx.color.r, vfx.color.g, vfx.color.b, 1.0 - k), 3.0)
				draw_circle(end_pos, 10 * (1.0 - k), Color.WHITE)
			"snowflake":
				var alpha = 1.0 - k
				var size = CELL_SIZE * 0.4 * (1.0 + k * 0.5)
				var color = vfx.color
				color.a *= alpha
				# Простая снежинка из линий
				for i in range(4):
					var dir = Vector2.UP.rotated(i * PI / 4.0)
					draw_line(vfx.pos - dir * size, vfx.pos + dir * size, color, 3.0)
			"particle":
				var alpha = 1.0 - k
				var color = vfx.color
				color.a *= alpha
				var s = vfx.size * (1.0 - k * 0.5)
				draw_rect(Rect2(vfx.pos - Vector2(s, s) * 0.5, Vector2(s, s)), color)

	# ПОСЛЕДНИЙ СЛОЙ: Отрисовка рамки "ямы" поверх всего игрового поля
	_draw_player_zone_overlay()

	# После отрисовки — удалить завершённые анимации, чтобы не зависали
	for m in range(_enemy_move_anims.size() - 1, -1, -1):
		if _enemy_move_anims[m].t >= _enemy_move_anims[m].d:
			_enemy_move_anims.remove_at(m)

	

func _activate_bomb(bx: int, by: int, trigger_move: bool = true):
	# VFX Бомбы
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (by - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
	var center_pos = origin + Vector2(bx * CELL_SIZE + CELL_SIZE * 0.5, y_pos + CELL_SIZE * 0.5)
	_board_vfx.append({"type": "bomb_explosion", "pos": center_pos, "color": Color(1, 0.6, 0.2), "t": 0.0, "d": 0.3})
	
	# Добавляем частицы (искры)
	for i in range(12):
		var angle = randf() * TAU
		var speed = randf_range(150.0, 350.0)
		var vel = Vector2.RIGHT.rotated(angle) * speed
		_board_vfx.append({
			"type": "particle",
			"pos": center_pos,
			"vel": vel,
			"gravity": Vector2(0, 400.0),
			"color": Color(1.0, randf_range(0.5, 0.9), 0.2),
			"t": 0.0,
			"d": randf_range(0.4, 0.7),
			"size": randf_range(4.0, 8.0)
		})
	
	set_process(true)

	# Взрываем крестом (центр + 4 соседа)
	_trigger_chip_at(bx, by, trigger_move)
	_trigger_chip_at(bx + 1, by, trigger_move)
	_trigger_chip_at(bx - 1, by, trigger_move)
	_trigger_chip_at(bx, by + 1, trigger_move)
	_trigger_chip_at(bx, by - 1, trigger_move)
	
	if not _is_executing_combo:
		_apply_gravity_up()
	queue_redraw()

func _trigger_chip_at(x: int, y: int, trigger_move: bool = true):
	if y < ENEMY_ROWS or y >= ROWS or x < 0 or x >= COLS: return
	var type = chips[y][x]
	if type == -1: return
	
	# Эффект лопания фишки
	_add_chip_pop_vfx(x, y, type)
	
	# Мгновенно помечаем клетку пустой, чтобы избежать бесконечной рекурсии
	chips[y][x] = -1
	_enqueue_projectiles(x, y, 1, 0.0, trigger_move)
	
	# Если это был бонус — активируем его эффект
	match type:
		RAINBOW_CHIP_IDX:
			_activate_rainbow_chip(x, y, trigger_move)
		ROW_BONUS_CHIP_IDX:
			_apply_row_blast(y, trigger_move)
		BOMB_CHIP_IDX:
			_activate_bomb(x, y, trigger_move)

func _draw_bomb_chip(top_left: Vector2, size_v: Vector2):
	var tex = BONUS_TEXTURES[BOMB_CHIP_IDX]
	if tex:
		var tex_size = tex.get_size()
		var aspect = tex_size.x / tex_size.y
		
		# Сохраняем пропорции: берем высоту за основу и вычисляем ширину
		var scale_factor = 1.25
		var target_h = size_v.y * scale_factor
		var target_w = target_h * aspect
		
		var adj_size = Vector2(target_w, target_h)
		var offset = (adj_size - size_v) * 0.5
		var bomb_rect = Rect2(top_left - offset, adj_size)
		
		# Тень
		draw_texture_rect(tex, Rect2(bomb_rect.position + CHIP_SHADOW_OFFSET * 0.5, bomb_rect.size), false, CHIP_SHADOW_COLOR)
		# Основная текстура
		draw_texture_rect(tex, bomb_rect, false)
		
func _draw_row_bonus_chip(top_left: Vector2, size_v: Vector2):
	var tex = BONUS_TEXTURES[ROW_BONUS_CHIP_IDX]
	if tex:
		var tex_size = tex.get_size()
		var aspect = tex_size.x / tex_size.y
		
		var target_h = size_v.y
		var target_w = target_h * aspect
		
		var adj_size = Vector2(target_w, target_h)
		var offset = (adj_size - size_v) * 0.5
		var rocket_rect = Rect2(top_left - offset, adj_size)
		
		# Тень
		draw_texture_rect(tex, Rect2(rocket_rect.position + CHIP_SHADOW_OFFSET * 0.5, rocket_rect.size), false, CHIP_SHADOW_COLOR)
		# Основная текстура
		draw_texture_rect(tex, rocket_rect, false)
		
func _draw_rainbow_chip(top_left: Vector2, size_v: Vector2):
	var tex = BONUS_TEXTURES[RAINBOW_CHIP_IDX]
	if tex:
		var tex_size = tex.get_size()
		var aspect = tex_size.x / tex_size.y
		
		var target_h = size_v.y
		var target_w = target_h * aspect
		
		var adj_size = Vector2(target_w, target_h)
		var offset = (adj_size - size_v) * 0.5
		var rainbow_rect = Rect2(top_left - offset, adj_size)
		
		# Тень
		draw_texture_rect(tex, Rect2(rainbow_rect.position + CHIP_SHADOW_OFFSET * 0.5, rainbow_rect.size), false, CHIP_SHADOW_COLOR)
		# Основная текстура
		draw_texture_rect(tex, rainbow_rect, false)
		
func _draw_chip(top_left: Vector2, size_v: Vector2, color_idx: int):
	if color_idx >= 0 and color_idx < CHIP_TEXTURES.size():
		var tex = CHIP_TEXTURES[color_idx]
		if tex:
			# Отрисовка текстуры фишки
			draw_texture_rect(tex, Rect2(top_left, size_v), false)

func _get_monster_color(hp: int) -> Color:
	var h = max(1, hp)
	if h == 1:
		return Color(0.60, 0.30, 0.80, 1) # фиолетовый
	elif h == 2:
		return Color(0.30, 0.60, 0.95, 1) # синий
	elif h == 3:
		return Color(0.95, 0.45, 0.25, 1) # оранжево-красный
	elif h == 4:
		return Color(0.35, 0.75, 0.45, 1) # зелёный
	elif h == 5:
		return Color(0.95, 0.85, 0.25, 1) # жёлтый
	return Color(1.00, 0.60, 0.20, 1) # запасной (янтарный)

func _draw_column_heart(center: Vector2, radius: float) -> void:
	var r = radius
	var top = center + Vector2(0, -r * 0.35)
	var left = center + Vector2(-r * 0.55, -r * 0.1)
	var right = center + Vector2(r * 0.55, -r * 0.1)
	var bottom = center + Vector2(0, r * 0.75)
	var fill = Color(0.95, 0.2, 0.28, 1.0)
	var edge = Color(0.55, 0.05, 0.12, 1.0)
	draw_circle(left, r * 0.48, fill)
	draw_circle(right, r * 0.48, fill)
	var poly = PackedVector2Array([
		top,
		center + Vector2(-r * 0.95, r * 0.15),
		bottom,
		center + Vector2(r * 0.95, r * 0.15)
	])
	draw_colored_polygon(poly, fill)
	draw_arc(left, r * 0.48, 0, TAU, 24, edge, 2.0)
	draw_arc(right, r * 0.48, 0, TAU, 24, edge, 2.0)
	draw_polyline(poly, edge, 2.0)

func _draw_monster_health_bar(top_left: Vector2, width: float, hp: int, max_hp: int, alpha: float = 1.0):
	if max_hp <= 0:
		return
	
	var bar_width := width * 0.7
	var bar_offset := (width - bar_width) * 0.5
	var bar_x := top_left.x + bar_offset
	var bar_y := top_left.y - HEALTH_BAR_HEIGHT - HEALTH_BAR_MARGIN
	
	var health_ratio := float(hp) / float(max_hp)
	health_ratio = clamp(health_ratio, 0.0, 1.0)
	
	var bg_color := HEALTH_BAR_BG_COLOR
	bg_color.a *= alpha
	draw_rect(Rect2(bar_x, bar_y, bar_width, HEALTH_BAR_HEIGHT), bg_color)
	
	if hp > 0:
		var green_width := bar_width * health_ratio
		var green_color := HEALTH_BAR_HEALTH_COLOR
		green_color.a *= alpha
		draw_rect(Rect2(bar_x, bar_y, green_width, HEALTH_BAR_HEIGHT), green_color)
	
	if hp < max_hp and hp > 0:
		var damage_width := bar_width * (1.0 - health_ratio)
		var red_color := HEALTH_BAR_DAMAGE_COLOR
		red_color.a *= alpha
		draw_rect(Rect2(bar_x + bar_width * health_ratio, bar_y, damage_width, HEALTH_BAR_HEIGHT), red_color)

func _draw_enemy_monster(top_left: Vector2, size_v: Vector2, hp: int, initial_hp: int, monster_id: int, alpha: float = 1.0, attack_warn_strength: float = 0.0):
	# Idle-анимация: "дыхание" и легкое покачивание на месте
	var time = Time.get_ticks_msec() * 0.001
	var phase = monster_id * 0.5
	
	# Параметры дыхания (масштабирование относительно низа)
	var scale_y = 1.0 + sin(time * 2.5 + phase) * 0.03
	var scale_x = 1.0 + cos(time * 2.5 + phase) * 0.02
	var anim_size = Vector2(size_v.x * scale_x, size_v.y * scale_y)
	
	# Точка опоры (низ монстра) остается неподвижной
	var bottom_center = Vector2(top_left.x + size_v.x * 0.5, top_left.y + size_v.y)
	var anim_top_left = Vector2(bottom_center.x - anim_size.x * 0.5, bottom_center.y - anim_size.y)
	
	# Легкое горизонтальное покачивание (микро-смещение)
	anim_top_left.x += sin(time * 1.8 + phase) * 1.5
	
	var tex = MONSTER_TEXTURES.get(initial_hp)
	if tex:
		# Отрисовка текстуры монстра
		var rect = Rect2(anim_top_left, anim_size)
		
		# Эффект заморозки через модуляцию цвета; перед атакой с переднего ряда — мигание красным
		var mod_color = Color.WHITE
		if _freeze_turns > 0:
			mod_color = Color(0.5, 0.8, 1.0)
		if attack_warn_strength > 0.0:
			var warn_col = Color(1.0, 0.22, 0.2)
			mod_color = mod_color.lerp(warn_col, clamp(attack_warn_strength, 0.0, 1.0) * 0.88)
		
		mod_color.a *= alpha
		
		# Тень
		draw_texture_rect(tex, Rect2(rect.position + Vector2(0, 4), rect.size), false, Color(0, 0, 0, 0.3 * alpha))
		# Сам монстр
		draw_texture_rect(tex, rect, false, mod_color)
		
		# Визуальный урон (трещины поверх текстуры)
		var damage = initial_hp - hp
		if damage > 0:
			_draw_monster_cracks(anim_top_left, anim_size, damage, monster_id, alpha)
		
		# Добавляем ледяной эффект поверх
		if _freeze_turns > 0:
			var r = anim_size.x * 0.45
			draw_arc(bottom_center - Vector2(0, anim_size.y * 0.5), r * 0.9, 0, TAU, 32, Color(1, 1, 1, 0.4 * alpha), 2.0)
	else:
		# Фолбэк на старую отрисовку
		var draw_center = bottom_center - Vector2(0, anim_size.y * 0.5)
		var r = anim_size.x * 0.45
		var body_color = _get_monster_color(initial_hp)
		
		# 1. Тень
		draw_circle(draw_center + Vector2(0, 4), r, Color(0, 0, 0, 0.3 * alpha))
		
		# 2. Тело (округлое)
		var final_body_color = body_color
		if _freeze_turns > 0:
			final_body_color = body_color.lerp(Color(0.5, 0.8, 1.0), 0.6)
		if attack_warn_strength > 0.0:
			var warn_col = Color(1.0, 0.22, 0.2)
			final_body_color = final_body_color.lerp(warn_col, clamp(attack_warn_strength, 0.0, 1.0) * 0.88)
		
		final_body_color.a *= alpha
		draw_circle(draw_center, r, final_body_color)
		
		# Добавляем ледяной эффект
		if _freeze_turns > 0:
			draw_arc(draw_center, r * 0.9, 0, TAU, 32, Color(1, 1, 1, 0.4 * alpha), 2.0)
		
		# 3. Детали монстра
		if initial_hp >= 3:
			var horn_color = body_color.lerp(Color.BLACK, 0.3)
			horn_color.a *= alpha
			draw_colored_polygon(PackedVector2Array([
				draw_center + Vector2(-r*0.5, -r*0.8),
				draw_center + Vector2(-r*0.8, -r*1.3),
				draw_center + Vector2(-r*0.2, -r*0.9)
			]), horn_color)
			draw_colored_polygon(PackedVector2Array([
				draw_center + Vector2(r*0.5, -r*0.8),
				draw_center + Vector2(r*0.8, -r*1.3),
				draw_center + Vector2(r*0.2, -r*0.9)
			]), horn_color)
		
		# 4. Трещины
		var damage = initial_hp - hp
		if damage > 0:
			_draw_monster_cracks(anim_top_left, anim_size, damage, monster_id, alpha)

		# 5. Глаза
		var eye_r = r * 0.25
		var eye_spacing = r * 0.4
		for side in [-1, 1]:
			var eye_pos = draw_center + Vector2(eye_spacing * side, -r * 0.1)
			var eye_bg = Color.WHITE
			if hp == 1 and initial_hp > 1: eye_bg = Color(1, 0.7, 0.7)
			eye_bg.a *= alpha
			draw_circle(eye_pos, eye_r, eye_bg)
			var pupil_pos = eye_pos
			if damage > 0:
				pupil_pos += Vector2(sin(monster_id + hp + side), cos(monster_id + hp)) * 2.0
			var p_color = Color.BLACK
			p_color.a *= alpha
			draw_circle(pupil_pos, eye_r * 0.5, p_color)
			var reflect_color = Color.WHITE
			reflect_color.a *= alpha
			draw_circle(pupil_pos - Vector2(eye_r*0.2, eye_r*0.2), eye_r * 0.15, reflect_color)
		
		# 6. Рот
		var mouth_y = draw_center.y + r * 0.4
		var m_w = r * 0.5
		var mouth_color = Color.BLACK
		mouth_color.a *= alpha
		if damage > 0:
			draw_line(Vector2(draw_center.x - m_w, mouth_y + 4), Vector2(draw_center.x, mouth_y - 2), mouth_color, 3.0)
			draw_line(Vector2(draw_center.x, mouth_y - 2), Vector2(draw_center.x + m_w, mouth_y + 4), mouth_color, 3.0)
		else:
			draw_line(Vector2(draw_center.x - m_w, mouth_y), Vector2(draw_center.x + m_w, mouth_y), mouth_color, 2.0)
	
	_draw_monster_health_bar(anim_top_left, anim_size.x, hp, initial_hp, alpha)

func _draw_obstacle(top_left: Vector2, size: Vector2, hp: int, max_hp: int, is_unbreakable: bool = false):
	if is_unbreakable:
		var wall_base = Color(0.36, 0.38, 0.45, 1.0)
		var wall_edge = Color(0.2, 0.22, 0.3, 1.0)
		draw_rect(Rect2(top_left + Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(top_left, size), wall_base)
		draw_line(top_left, top_left + Vector2(size.x, 0), wall_edge, 3.0)
		draw_line(top_left, top_left + Vector2(0, size.y), wall_edge, 3.0)
		draw_line(top_left + Vector2(size.x, 0), top_left + size, wall_edge, 3.0)
		draw_line(top_left + Vector2(0, size.y), top_left + size, wall_edge, 3.0)
		draw_line(top_left + Vector2(4, 4), top_left + size - Vector2(4, 4), Color(1, 1, 1, 0.18), 2.0)
		draw_line(Vector2(top_left.x + size.x - 4, top_left.y + 4), Vector2(top_left.x + 4, top_left.y + size.y - 4), Color(1, 1, 1, 0.18), 2.0)
		return

	var base_color = OBSTACLE_COLOR
	var edge_color = OBSTACLE_EDGE_COLOR
	
	draw_rect(Rect2(top_left + Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(top_left, size), base_color)
	
	draw_line(top_left, top_left + Vector2(size.x, 0), edge_color, 3.0)
	draw_line(top_left, top_left + Vector2(0, size.y), edge_color, 3.0)
	draw_line(top_left + Vector2(size.x, 0), top_left + size, edge_color, 3.0)
	draw_line(top_left + Vector2(0, size.y), top_left + size, edge_color, 3.0)
	
	var block_pattern = [
		[0.0, 0.0, 0.5, 0.33],
		[0.5, 0.0, 1.0, 0.33],
		[0.0, 0.33, 0.4, 0.66],
		[0.4, 0.33, 1.0, 0.66],
		[0.0, 0.66, 0.6, 1.0],
		[0.6, 0.66, 1.0, 1.0]
	]
	
	for block in block_pattern:
		var bx = top_left.x + size.x * block[0]
		var by = top_left.y + size.y * block[1]
		var bw = size.x * (block[2] - block[0])
		var bh = size.y * (block[3] - block[1])
		draw_rect(Rect2(bx, by, bw, bh), edge_color, false, 1.5)
	
	_draw_monster_health_bar(top_left, size.x, hp, max_hp, 1.0)

func _draw_player_zone_overlay():
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var player_rect = Rect2(Vector2(origin.x, origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + _field_gap_total), Vector2(COLS * CELL_SIZE, PLAYER_ROWS * CELL_SIZE))

	# 1. РИСУЕМ ГРАДИЕНТНУЮ ВНУТРЕННЮЮ ТЕНЬ (сначала, чтобы она была под рамкой)
	var shadow_steps = 20
	var shadow_max_alpha = 0.4
	for i in range(shadow_steps):
		var t = float(i) / shadow_steps
		var alpha = lerp(shadow_max_alpha, 0.0, t)
		var inset = PLAYER_ZONE_OUTLINE_WIDTH + i
		var shadow_rect = player_rect.grow(-inset)
		
		if shadow_rect.size.x > 0 and shadow_rect.size.y > 0:
			draw_rect(shadow_rect, Color(0, 0, 0, alpha), false, 1.0)

	# 2. РИСУЕМ ЗОЛОТУЮ ОКАНТОВКУ ПОВЕРХ ТЕНИ
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color(0, 0, 0, 0)
	frame.draw_center = false
	frame.set_corner_radius_all(16.0)
	frame.border_width_left = int(PLAYER_ZONE_OUTLINE_WIDTH)
	frame.border_width_top = int(PLAYER_ZONE_OUTLINE_WIDTH)
	frame.border_width_right = int(PLAYER_ZONE_OUTLINE_WIDTH)
	frame.border_width_bottom = int(PLAYER_ZONE_OUTLINE_WIDTH)
	frame.border_color = PLAYER_ZONE_OUTLINE_COLOR
	
	# Убрали border_blend для полной непрозрачности
	
	draw_style_box(frame, player_rect)
	
	# 3. Дополнительный блик на верхней грани рамки для блеска
	var highlight_color = PLAYER_ZONE_OUTLINE_COLOR.lerp(Color.WHITE, 0.5)
	var line_start = Vector2(player_rect.position.x + 10, player_rect.position.y + 2)
	var line_end = Vector2(player_rect.end.x - 10, player_rect.position.y + 2)
	draw_line(line_start, line_end, highlight_color, 2.0)

func _draw_monster_cracks(pos: Vector2, size: Vector2, damage_level: int, seed_val: int, alpha: float = 1.0):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var crack_color = Color(0, 0, 0, 0.5 * alpha)
	
	# Чем больше урон, тем больше основных веток трещин
	for i in range(damage_level * 2):
		var start = pos + Vector2(rng.randf_range(0.2, 0.8) * size.x, rng.randf_range(0.2, 0.8) * size.y)
		var end = start + Vector2(rng.randf_range(-0.4, 0.4) * size.x, rng.randf_range(-0.4, 0.4) * size.y)
		
		# Ограничиваем трещины внутри тела
		end.x = clamp(end.x, pos.x + 5, pos.x + size.x - 5)
		end.y = clamp(end.y, pos.y + 5, pos.y + size.y - 5)
		
		draw_line(start, end, crack_color, 1.5)
		
		# Маленькие ответвления для реализма
		if rng.randf() > 0.5:
			var branch_end = end + Vector2(rng.randf_range(-0.2, 0.2) * size.x, rng.randf_range(-0.2, 0.2) * size.y)
			branch_end.x = clamp(branch_end.x, pos.x + 5, pos.x + size.x - 5)
			branch_end.y = clamp(branch_end.y, pos.y + 5, pos.y + size.y - 5)
			draw_line(end, branch_end, crack_color, 1.0)


func _process(delta: float) -> void:
	if _enemy_attack_warn_pending:
		_enemy_attack_warn_time_left -= delta
		if _enemy_attack_warn_time_left <= 0.0:
			_enemy_attack_warn_pending = false
			var planned = _cached_enemy_moves
			_cached_enemy_moves = []
			_apply_enemy_moves_from_plan(planned)
	if _active_anims.is_empty():
		# Все падения окончены — проверяем нужно ли спавнить новые фишки
		# Мы не ждем окончания стрельбы или движения монстров, чтобы игра ощущалась динамичнее
		_spawn_new_chips_with_fall()
	
	# Обновляем Board VFX
	var shake_offset = Vector2.ZERO
	for i in range(_board_vfx.size() - 1, -1, -1):
		var vfx = _board_vfx[i]
		vfx.t += delta
		
		if vfx.type == "shake":
			var k_shake = 1.0 - (vfx.t / vfx.d)
			shake_offset += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * vfx.intensity * k_shake
		
		if vfx.type == "particle":
			vfx.pos += vfx.vel * delta
			if vfx.has("gravity"):
				vfx.vel += vfx.gravity * delta
		
		if vfx.t >= vfx.d:
			_board_vfx.remove_at(i)

	# Обновляем шейки монстров
	var shakes_to_remove = []
	for mid in _monster_shakes:
		var s = _monster_shakes[mid]
		s.t += delta
		if s.t >= s.d:
			shakes_to_remove.append(mid)
	for mid in shakes_to_remove:
		_monster_shakes.erase(mid)

	for i in range(_active_anims.size() - 1, -1, -1):
		_active_anims[i].t += delta
		var delay = _active_anims[i].get("delay", 0.0)
		if _active_anims[i].t - delay >= _active_anims[i].d:
			_active_anims.remove_at(i)
	# Обновляем снаряды
	for j in range(_projectiles.size() - 1, -1, -1):
		_projectiles[j].t += delta
		var tt = _projectiles[j].t - _projectiles[j].delay
		if tt >= _projectiles[j].d and not _projectiles[j].hit_applied:
			# Применяем урон по цели, если цель есть
			if _projectiles[j].has_target:
				var tx = _projectiles[j].x
				var ty = int(_projectiles[j].end_y)
				if ty >= 0 and ty < ENEMY_ROWS and enemies.size() > ty and enemies[ty].size() > tx:
					# Проверяем препятствие
					if obstacles[ty][tx] > 0:
						if obstacles_unbreakable[ty][tx]:
							# Неразрушаемая стена просто блокирует снаряд
							pass
						else:
							obstacles[ty][tx] -= 1
							if obstacles[ty][tx] <= 0:
								obstacles[ty][tx] = 0
								obstacles_initial_hp[ty][tx] = 0
								# VFX разрушения препятствия
								var vp_size = get_viewport_rect().size
								var origin = _grid_origin(vp_size)
								var obs_center = origin + Vector2(float(tx) * CELL_SIZE + CELL_SIZE * 0.5, float(ty) * ENEMY_CELL_HEIGHT + ENEMY_CELL_HEIGHT * 0.5)
								_board_vfx.append({
									"type": "explosion",
									"pos": obs_center,
									"color": OBSTACLE_COLOR,
									"t": 0.0,
									"d": 0.3
								})
								var key = "%d:%d" % [tx, ty]
								if _obstacle_spawn_on_destroy.has(key):
									var sp = _obstacle_spawn_on_destroy[key]
									var shp = max(1, int(sp.get("hp", 1)))
									var scnt = max(1, int(sp.get("count", 1)))
									for ii in range(scnt):
										_scheduled_spawns.append({
											"hp": shp,
											"x": tx,
											"y": ty,
											"spawn_after_player_turns": _player_turn_counter
										})
									_obstacle_spawn_on_destroy.erase(key)
						queue_redraw()
					# Проверяем монстра (только если нет препятствия)
					elif enemies[ty][tx] > 0:
						enemies[ty][tx] -= 1
						_enemies_hit_this_turn[ty][tx] = true
						
						# Добавляем шейк при попадании
						var mid = tx + ty * 10
						_monster_shakes[mid] = {"t": 0.0, "d": 0.2, "intensity": 10.0}
						
						if enemies[ty][tx] <= 0:
							enemies[ty][tx] = 0
							# Уменьшаем цели по исходному HP этой клетки
							var init_hp = enemies_initial_hp[ty][tx]
							_decrement_level_target_for_init_hp(int(init_hp))
							_needs_ui_update = true
							# Запускаем анимацию смерти с сохранением данных монстра для отрисовки
							_enemy_death_anims.append({
								"x": tx, "y": ty, "t": 0.0, "d": 0.35,
								"hp": 0, "init": init_hp, "id": mid
							})
							# При смерти шейк сильнее и дольше
							_monster_shakes[mid] = {"t": 0.0, "d": 0.35, "intensity": 15.0}
			_projectiles[j].hit_applied = true
		if tt >= _projectiles[j].d + 0.05:
			_projectiles.remove_at(j)
	# Обновляем анимации смерти
	for k in range(_enemy_death_anims.size() - 1, -1, -1):
		_enemy_death_anims[k].t += delta
		if _enemy_death_anims[k].t >= _enemy_death_anims[k].d:
			_enemy_death_anims.remove_at(k)
	# Обновляем анимации движения врагов
	for m in range(_enemy_move_anims.size() - 1, -1, -1):
		_enemy_move_anims[m].t += delta
		if _enemy_move_anims[m].t >= _enemy_move_anims[m].d:
			_enemy_move_anims[m].t = _enemy_move_anims[m].d
			# оставляем запись до конца кадра, удалим после отрисовки, чтобы дошли до цели визуально
	# Удаляем завершённые после отрисовки
	# Автопобеда/поражение и шаги врагов после завершения всех эффектов
	if _projectiles.is_empty() and _active_anims.is_empty() and _enemy_death_anims.is_empty():
		# Отложенные спавны (порталы): раньше обрабатывались только после хода врагов —
		# при пустом поле и уже наступившем ходе игрока волна не появлялась до следующего хода.
		if _use_scheduled_spawns:
			var anim_count_before_spawn := _enemy_move_anims.size()
			_process_scheduled_spawns()
			if _enemy_move_anims.size() > anim_count_before_spawn:
				set_process(true)
		if not _defeat_dialog_shown and (_count_column_hearts_remaining() == 0 or _defeat_pending_breach):
			_defeat_pending_breach = false
			_on_level_failed()
		elif _check_level_completed() and not _victory_dialog_shown:
			_on_level_completed()
		elif _enemy_move_pending:
			_enemy_move_step()
			_enemy_move_pending = false
	# после анимаций ничего не применяем — мы уже обновили enemies напрямую
	if _needs_ui_update:
		_needs_ui_update = false
		_update_ui()
	_try_advance_level1_tutorial_to_goals_step()
	queue_redraw()


func _spawn_new_chips_with_fall():
	var new_anims := []
	var any := false
	var count := 0
	# Идем по колонкам, а внутри колонок снизу вверх, чтобы создать эффект "цепочки" снизу
	for x in range(COLS):
		for y in range(ROWS - 1, ENEMY_ROWS - 1, -1):
			if chips[y][x] == -1:
				any = true
				var color = int(randi() % CHIP_COLORS.size())
				chips[y][x] = color
				new_anims.append({
					"x": x, 
					"start_y": y, # Используем int
					"end_y": y,   # Используем int
					"color": color, 
					"t": 0.0, 
					"d": 0.25, 
					"delay": float(count) * 0.02,
					"type": "scale"
				})
				count += 1
	if any and not new_anims.is_empty():
		_active_anims = _active_anims + new_anims
		set_process(true)

func _init_moves_from_config(cfg: Dictionary) -> void:
	_moves_total = max(1, int(cfg.get("moves", 20)))
	_moves_left = _moves_total


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		queue_redraw()
		return
	if _level1_tutorial_phase == 2:
		return
		
	if not _active_anims.is_empty() or not _projectiles.is_empty() or _is_executing_combo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell = _point_to_cell(event.position)
		if cell.x >= 0 and cell.y >= 0:
			if _active_booster != BoosterType.NONE:
				_use_booster_on_cell(cell)
				return
			
			var popped = await _pop_cluster(cell.x, cell.y)
			if popped > 0:
				_player_turn_counter += 1
				_moves_left = max(0, _moves_left - 1)
				_update_ui()
		# Проверку победы/поражения делаем после завершения анимаций в _process

func _use_booster_on_cell(cell: Vector2i):
	var type_used = _active_booster
	if type_used == BoosterType.NONE: return
	
	# Бустеры обычно только на зону игрока, кроме заморозки
	if type_used != BoosterType.FREEZE and cell.y < ENEMY_ROWS: 
		return 

	match type_used:
		BoosterType.HAMMER:
			_apply_hammer(cell)
		BoosterType.ROW_BLAST:
			_apply_row_blast(cell.y, false)
		BoosterType.FREEZE:
			_apply_freeze()
	
	if type_used != BoosterType.NONE:
		var lm_type = _convert_to_lm_booster_type(type_used)
		LevelManager.use_booster(lm_type)
		_update_ui()
	
	_active_booster = BoosterType.NONE
	_update_booster_buttons_visual()
	queue_redraw()

func _apply_freeze():
	_freeze_turns = 1 # Замораживаем на один ход
	# Добавим VFX снежинок на все поле врагов
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			if enemies[y][x] > 0:
				var pos = origin + Vector2(x * CELL_SIZE + CELL_SIZE * 0.5, y * CELL_SIZE + CELL_SIZE * 0.5)
				_board_vfx.append({
					"type": "snowflake",
					"pos": pos,
					"color": Color(0.7, 0.9, 1.0, 0.9),
					"t": 0.0,
					"d": 0.8
				})
	set_process(true)
	queue_redraw()

func _apply_hammer(cell: Vector2i):
	_trigger_chip_at(cell.x, cell.y, false)
	_apply_gravity_up()

func _apply_row_blast(row_y: int, trigger_move: bool = true):
	# VFX Ракеты
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var center_y = origin.y + row_y * CELL_SIZE + CELL_SIZE * 0.5
	_board_vfx.append({"type": "beam", "pos": Vector2(vp_size.x * 0.5, center_y), "color": Color(0.4, 0.6, 1.0), "t": 0.0, "d": 0.3})
	set_process(true)

	for x in range(COLS):
		_trigger_chip_at(x, row_y, trigger_move)
	
	if not _is_executing_combo:
		_apply_gravity_up()
	queue_redraw()

func _apply_booster_shuffle():
	var colors := []
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] != -1:
				colors.append(chips[y][x])
	
	colors.shuffle()
	
	var idx = 0
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] != -1:
				chips[y][x] = colors[idx]
				idx += 1
	queue_redraw()

func _point_to_cell(screen_pos: Vector2) -> Vector2i:
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var local = screen_pos - origin
	
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)
	
	var x = int(floor(local.x / CELL_SIZE))
	var y_pixels = local.y
	var y = -1
	
	var enemy_zone_h = ENEMY_ROWS * ENEMY_CELL_HEIGHT
	if y_pixels < enemy_zone_h:
		y = int(floor(y_pixels / ENEMY_CELL_HEIGHT))
	elif y_pixels > enemy_zone_h + _field_gap_total:
		var y_in_player_zone = y_pixels - enemy_zone_h - _field_gap_total
		y = ENEMY_ROWS + int(floor(y_in_player_zone / CELL_SIZE))
	
	if x < 0 or x >= COLS or y < 0 or y >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(x, y)

func _get_cluster_at(x: int, y: int) -> Array:
	if y < ENEMY_ROWS or y >= ROWS or x < 0 or x >= COLS: return []
	var color_idx = chips[y][x]
	if color_idx < 0: return []
	
	var stack: Array = [Vector2i(x, y)]
	var visited := {}
	var cluster := []
	while not stack.is_empty():
		var c = stack.pop_back()
		var key = str(c.x) + "," + str(c.y)
		if visited.has(key): continue
		visited[key] = true
		
		if c.y < ENEMY_ROWS or c.y >= ROWS or c.x < 0 or c.x >= COLS: continue
		if chips[c.y][c.x] != color_idx: continue
		
		cluster.append(c)
		stack.append(Vector2i(c.x + 1, c.y))
		stack.append(Vector2i(c.x - 1, c.y))
		stack.append(Vector2i(c.x, c.y + 1))
		stack.append(Vector2i(c.x, c.y - 1))
	return cluster

func _get_current_level() -> int:
	return LevelManager.current_level

func _pop_cluster(x: int, y: int):
	if y < ENEMY_ROWS:
			return 0
	if y >= chips.size() or x >= chips[y].size():
		return 0
	
	var color_idx = chips[y][x]
	
	# Проверка на слияние бонусов
	if color_idx < -1:
		if await _check_and_execute_bonus_combine(x, y):
			return 1

	# Активация радужной фишки (одиночная)
	if color_idx == RAINBOW_CHIP_IDX:
		_trigger_chip_at(x, y)
		return 1
		
	# Активация горизонтального бонуса
	if color_idx == ROW_BONUS_CHIP_IDX:
		_trigger_chip_at(x, y)
		return 1
		
	# Активация бомбы
	if color_idx == BOMB_CHIP_IDX:
		_trigger_chip_at(x, y)
		return 1

	if color_idx < 0:
		return 0
		
	var stack: Array = [Vector2i(x, y)]
	var visited := {}
	var cluster := []
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		var key = str(c.x) + "," + str(c.y)
		if visited.has(key):
			continue
		visited[key] = true
		if c.y < ENEMY_ROWS:
			continue
		if c.y < 0 or c.y >= ROWS or c.x < 0 or c.x >= COLS:
			continue
		if chips[c.y].size() <= c.x:
			continue
		if chips[c.y][c.x] != color_idx:
					continue
		cluster.append(c)
		stack.append(Vector2i(c.x + 1, c.y))
		stack.append(Vector2i(c.x - 1, c.y))
		stack.append(Vector2i(c.x, c.y + 1))
		stack.append(Vector2i(c.x, c.y - 1))
	
	if cluster.size() < MIN_NORMAL_CLUSTER_POP:
		return 0
	
	for cell in cluster:
		chips[cell.y][cell.x] = -1
	
	# Создание бонусов
	var created_bonus := false
	var bonus_idx = -1
	if cluster.size() >= 8:
		bonus_idx = RAINBOW_CHIP_IDX
	elif cluster.size() == 7:
		bonus_idx = ROW_BONUS_CHIP_IDX
	elif cluster.size() == 6:
		bonus_idx = BOMB_CHIP_IDX
		
	if bonus_idx != -1:
		chips[y][x] = bonus_idx
		created_bonus = true
		
	# Запускаем снаряды
	if not cluster.is_empty():
		# Используем счетчик для каждой колонки, чтобы добавить небольшую задержку между снарядами в одной колонке
		var col_stagger = {}
		for cell in cluster:
			# Эффект лопания фишки
			_add_chip_pop_vfx(cell.x, cell.y, color_idx)
			
			var stagger = col_stagger.get(cell.x, 0)
			_enqueue_projectiles(cell.x, cell.y, 1, stagger * 0.06)
			col_stagger[cell.x] = stagger + 1
	
	_apply_gravity_up()
	
	# Находим, куда улетел наш бонус, и делаем ему красивое появление через скейл с задержкой
	if created_bonus:
		for ay in range(ENEMY_ROWS, ROWS):
			if chips[ay][x] == bonus_idx:
				var found_anim = false
				for a in _active_anims:
					if a.x == x and a.end_y == ay:
						a["type"] = "scale"
						a["delay"] = 0.2 # Задержка, чтобы сначала вылетел снаряд
						found_anim = true
						break
				if not found_anim:
					_active_anims.append({
						"x": x, "start_y": ay, "end_y": ay,
						"color": bonus_idx, "t": 0.0, "d": 0.3,
						"delay": 0.2, "type": "scale"
					})
				break

	queue_redraw()
 
	return cluster.size()

func _check_and_execute_bonus_combine(x: int, y: int) -> bool:
	var neighbors = [Vector2i(x+1, y), Vector2i(x-1, y), Vector2i(x, y+1), Vector2i(x, y-1)]
	var combined_points = [Vector2i(x, y)]
	var types = {chips[y][x]: true}
	
	for n in neighbors:
		if n.x >= 0 and n.x < COLS and n.y >= ENEMY_ROWS and n.y < ROWS:
			var t = chips[n.y][n.x]
			if t < -1:
				combined_points.append(n)
				types[t] = true
	
	if combined_points.size() < 2:
		return false # Нет соседей-бонусов
	
	_is_executing_combo = true
	
	# Поглощаем все бонусы, участвующие в комбо
	for p in combined_points:
		chips[p.y][p.x] = -1
	
	# Определяем тип комбо
	var has_rainbow = types.has(RAINBOW_CHIP_IDX)
	var has_rocket = types.has(ROW_BONUS_CHIP_IDX)
	var has_bomb = types.has(BOMB_CHIP_IDX)
	
	if has_rainbow and has_rocket and has_bomb:
		await _combo_mega_blast()
	elif has_rainbow and has_bomb:
		await _combo_rainbow_plus_special(BOMB_CHIP_IDX)
	elif has_rainbow and has_rocket:
		await _combo_rainbow_plus_special(ROW_BONUS_CHIP_IDX)
	elif has_bomb and has_rocket:
		await _combo_bomb_plus_rocket(x, y)
	else:
		# Если спец-комбо нет, просто активируем эффекты присутствующих типов
		if has_rocket: _apply_row_blast(y)
		if has_bomb: _activate_bomb(x, y)
		if has_rainbow: _activate_rainbow_chip(x, y)

	_is_executing_combo = false
	_apply_gravity_up()
	queue_redraw()
	return true

func _combo_mega_blast():
	# Короткая задержка перед тотальной зачисткой
	await get_tree().create_timer(0.3).timeout
	
	# Взрываем по частям с задержкой для зрелищности
	var all_cells = []
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] != -1:
				all_cells.append(Vector2i(x, y))
	
	# Перемешиваем для хаотичного эффекта
	all_cells.shuffle()
	
	# Взрываем группами по 5-7 фишек с небольшой задержкой
	var batch_size = 6
	for i in range(0, all_cells.size(), batch_size):
		for j in range(i, min(i + batch_size, all_cells.size())):
			var p = all_cells[j]
			_trigger_chip_at(p.x, p.y)
		await get_tree().create_timer(0.08).timeout

func _combo_bomb_plus_rocket(cx: int, cy: int):
	# Короткая задержка для акцента на слиянии
	await get_tree().create_timer(0.2).timeout
	
	# Сначала взрываем ряды (горизонтальные)
	for i in range(-1, 2):
		var target_y = cy + i
		if target_y >= ENEMY_ROWS and target_y < ROWS:
			# VFX для каждого ряда
			var vp_size = get_viewport_rect().size
			var origin = _grid_origin(vp_size)
			var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (target_y - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
			var center_y = origin.y + y_pos + CELL_SIZE * 0.5
			_board_vfx.append({"type": "beam", "pos": Vector2(vp_size.x * 0.5, center_y), "color": Color(0.4, 0.6, 1.0), "t": 0.0, "d": 0.3})
			set_process(true)
			
			for x in range(COLS):
				_trigger_chip_at(x, target_y)
			await get_tree().create_timer(0.15).timeout
	
	# Затем взрываем столбцы (вертикальные)
	for i in range(-1, 2):
		var target_x = cx + i
		if target_x >= 0 and target_x < COLS:
			# VFX для каждого столбца (вертикальный луч)
			var vp_size = get_viewport_rect().size
			var origin = _grid_origin(vp_size)
			var center_x = origin.x + target_x * CELL_SIZE + CELL_SIZE * 0.5
			var center_y = origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + (PLAYER_ROWS * 0.5) * CELL_SIZE + _field_gap_total
			_board_vfx.append({"type": "beam_vertical", "pos": Vector2(center_x, center_y), "color": Color(1.0, 0.6, 0.2), "t": 0.0, "d": 0.3})
			set_process(true)
			
			for y in range(ENEMY_ROWS, ROWS):
				_trigger_chip_at(target_x, y)
			await get_tree().create_timer(0.15).timeout

func _combo_rainbow_plus_special(special_type: int):
	var target_color = _get_most_frequent_color_idx()
	if target_color == -1: return
	
	var affected_cells = []
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] == target_color:
				# ШАГ 1: Визуально превращаем фишку в бонус
				chips[y][x] = special_type
				affected_cells.append(Vector2i(x, y))
	
	queue_redraw()
	
	# ШАГ 2: Ждем, чтобы игрок увидел поле полное бомб/ракет
	await get_tree().create_timer(0.6).timeout
	
	# ШАГ 3: Последовательная детонация с задержками
	var batch_size = 4
	for i in range(0, affected_cells.size(), batch_size):
		for j in range(i, min(i + batch_size, affected_cells.size())):
			var p = affected_cells[j]
			# Проверяем, что фишка всё еще на месте (могла взорваться от соседа)
			if chips[p.y][p.x] == special_type:
				_trigger_chip_at(p.x, p.y)
		await get_tree().create_timer(0.1).timeout

func _get_most_frequent_color_idx() -> int:
	var counts := {}
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			var c = chips[y][x]
			if c >= 0:
				counts[c] = counts.get(c, 0) + 1
	if counts.is_empty(): return -1
	var max_c = 0
	for c in counts:
		if counts[c] > max_c: max_c = counts[c]
	var bests := []
	for c in counts:
		if counts[c] == max_c: bests.append(c)
	return bests[randi() % bests.size()]

func _activate_rainbow_chip(rx: int, ry: int, trigger_move: bool = true):
	var target_color = _get_most_frequent_color_idx()
	if target_color == -1:
		chips[ry][rx] = -1
		if not _is_executing_combo:
			_apply_gravity_up()
		return

	# VFX Радуги
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var start_y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (ry - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
	var start_pos = origin + Vector2(rx * CELL_SIZE + CELL_SIZE * 0.5, start_y_pos + CELL_SIZE * 0.5)
	
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] == target_color:
				var end_y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
				var end_pos = origin + Vector2(x * CELL_SIZE + CELL_SIZE * 0.5, end_y_pos + CELL_SIZE * 0.5)
				_board_vfx.append({
					"type": "rainbow_link", 
					"pos": start_pos, 
					"target_pos": end_pos, 
					"color": CHIP_COLORS[target_color], 
					"t": 0.0, 
					"d": 0.5
				})
	set_process(true)

	# Удаляем радужную фишку
	chips[ry][rx] = -1
	
	var old_combo = _is_executing_combo
	_is_executing_combo = true
	
	# Лопаем все фишки этого цвета через единую функцию триггера
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] == target_color:
				_trigger_chip_at(x, y, trigger_move)
	
	_is_executing_combo = old_combo
	
	if not _is_executing_combo:
		_apply_gravity_up()
	queue_redraw()
func _check_level_completed() -> bool:
	# Нельзя засчитать победу, пока ожидается проигрыш по прорыву или открыт диалог поражения
	if _defeat_pending_breach or _defeat_dialog_shown:
		return false
	# Победа: выполнены все цели; живые враги и препятствия на поле не отменяют победу
	if _level_targets.is_empty():
		return false
	for hp in _level_targets:
		if int(_level_targets[hp]) > 0:
			return false
	if not _monster_spawn_queue.is_empty():
		return false
	if not _scheduled_spawns.is_empty():
		return false
	return true

func _count_bonus_chips_on_player_field() -> int:
	var n := 0
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips.size() <= y or chips[y].size() <= x:
				continue
			var v = chips[y][x]
			if v == RAINBOW_CHIP_IDX or v == ROW_BONUS_CHIP_IDX or v == BOMB_CHIP_IDX:
				n += 1
	return n


func _on_level_completed():
	if LevelManager.is_editor_test_mode():
		_return_to_editor_after_test()
		return
	_victory_dialog_shown = true
	# Награда за победу: базовая + бонус за оставшиеся на поле бонусные фишки
	var base_reward = 50
	var bonus_chips = _count_bonus_chips_on_player_field()
	var chips_bonus = bonus_chips * COINS_PER_REMAINING_BONUS_CHIP
	var total_reward = base_reward + chips_bonus
	
	LevelManager.add_coins(total_reward)
	LevelManager.mark_level_completed()
	
	_show_level_end_victory(total_reward, base_reward, chips_bonus, bonus_chips)

func _attach_level_end_overlay() -> Control:
	if _level_end_overlay != null and is_instance_valid(_level_end_overlay):
		return _level_end_overlay
	var ui = find_child("UIRoot", true, false)
	var parent: Node = self
	if ui != null:
		parent = ui
	var overlay = Control.new()
	overlay.set_script(LEVEL_END_DIALOG_SCRIPT)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	parent.add_child(overlay)
	_level_end_overlay = overlay
	return overlay

func _show_level_end_victory(total: int, base_reward: int, chips_bonus: int, bonus_chips_count: int) -> void:
	var overlay = _attach_level_end_overlay()
	overlay.setup_victory(total, base_reward, chips_bonus, bonus_chips_count, COINS_PER_REMAINING_BONUS_CHIP)
	if not overlay.to_menu_pressed.is_connected(_on_level_end_to_menu):
		overlay.to_menu_pressed.connect(_on_level_end_to_menu)

func _on_level_end_to_menu() -> void:
	if _level_end_overlay != null and is_instance_valid(_level_end_overlay):
		_level_end_overlay.queue_free()
		_level_end_overlay = null
	if LevelManager.is_editor_test_mode():
		_return_to_editor_after_test()
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_level_end_defeat_no_lives() -> void:
	var overlay = _attach_level_end_overlay()
	if overlay.to_menu_pressed.is_connected(_on_level_end_to_menu):
		overlay.to_menu_pressed.disconnect(_on_level_end_to_menu)
	if overlay.refill_lives_pressed.is_connected(_on_defeat_refill_lives):
		overlay.refill_lives_pressed.disconnect(_on_defeat_refill_lives)
	var player_coins = LevelManager.get_coins()
	var cost = _compute_refill_cost_after_breach()
	var k_restore = _breach_refill_unit_count()
	var can_refill = k_restore > 0 and player_coins >= cost
	overlay.setup_defeat_no_lives(cost, player_coins, k_restore, can_refill)
	if not overlay.to_menu_pressed.is_connected(_on_defeat_no_lives_to_menu):
		overlay.to_menu_pressed.connect(_on_defeat_no_lives_to_menu)
	if can_refill and not overlay.refill_lives_pressed.is_connected(_on_defeat_refill_lives):
		overlay.refill_lives_pressed.connect(_on_defeat_refill_lives)

func _on_defeat_no_lives_to_menu() -> void:
	if _level_end_overlay != null and is_instance_valid(_level_end_overlay):
		_level_end_overlay.queue_free()
		_level_end_overlay = null
	if LevelManager.is_editor_test_mode():
		_return_to_editor_after_test()
		return
	LevelManager.mark_level_failed()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_defeat_refill_lives() -> void:
	if _level_end_overlay != null and is_instance_valid(_level_end_overlay):
		_level_end_overlay.queue_free()
		_level_end_overlay = null
	var cost = _compute_refill_cost_after_breach()
	if cost > 0 and LevelManager.spend_coins(cost):
		_clear_board_vfx_after_refill()
		_apply_partial_refill_after_breach_paid()
		_update_ui()
		queue_redraw()
	else:
		if LevelManager.is_editor_test_mode():
			_return_to_editor_after_test()
			return
		LevelManager.mark_level_failed()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_level_failed():
	if LevelManager.is_editor_test_mode():
		_return_to_editor_after_test()
		return
	_defeat_dialog_shown = true
	_show_level_end_defeat_no_lives()

func _return_to_editor_after_test() -> void:
	LevelManager.finish_editor_test()
	get_tree().change_scene_to_file(LevelManager.get_editor_return_scene())

func _enqueue_projectiles(col_x: int, from_y: int, count: int, base_delay: float = 0.0, trigger_move: bool = true):
	# Планируем цели по ближайшим врагам/препятствиям снизу вверх, без превышения их суммарного HP
	var hp_left := []
	for yy in range(ENEMY_ROWS):
		var row_hp = 0
		if obstacles.size() > yy and obstacles[yy].size() > col_x and obstacles[yy][col_x] > 0:
			# Препятствие блокирует — снаряд попадёт в него
			row_hp = obstacles[yy][col_x]
		elif enemies.size() > yy and enemies[yy].size() > col_x:
			row_hp = enemies[yy][col_x]
		# Учитываем снаряды, которые уже летят в эту цель, чтобы не было "оверкилла"
		for p in _projectiles:
			if not p.hit_applied and p.has_target and p.x == col_x and int(p.end_y) == yy:
				row_hp -= 1
		hp_left.append(max(0, row_hp))
	var planned := [] # пары (has_target:bool, target_y:int)
	for i in range(count):
		var target_found = false
		for yy in range(ENEMY_ROWS - 1, -1, -1):
			if hp_left[yy] > 0:
				hp_left[yy] -= 1
				planned.append({"has": true, "y": yy})
				target_found = true
				break
		if not target_found:
			planned.append({"has": false, "y": -1})
	# Создаем анимации снарядов с небольшой задержкой между ними
	for i in range(planned.size()):
		var has = planned[i].has
		var ty = planned[i].y
		var proj = {
			"x": col_x,
			"start_y": float(from_y),
			"end_y": (float(ty) if has else -1.0),
			"t": 0.0,
			"d": 0.25,
			"delay": base_delay + float(i) * 0.06,
			"color": Color(1.0, 0.85, 0.2, 1.0),
			"hit_applied": false,
			"has_target": has
		}
		_projectiles.append(proj)
	set_process(true)
	if trigger_move:
		_enemy_move_pending = true

func _enemy_mixed_columns_mode() -> bool:
	var has_heart = false
	var has_no_heart = false
	for x in range(min(COLS, _column_hearts.size())):
		if _column_hearts[x]:
			has_heart = true
		else:
			has_no_heart = true
		if has_heart and has_no_heart:
			return true
	return false

# Колонка клетки сразу под связной группой препятствий (проход для обхода сбоку)
func _find_detour_exit_column_below_obstacle(monster_x: int, monster_y: int) -> int:
	var ty_down = monster_y + 1
	if ty_down < 0 or ty_down >= ENEMY_ROWS:
		return -1
	if obstacles[ty_down][monster_x] <= 0:
		return -1
	var visited := {}
	var stack: Array = [Vector2i(monster_x, ty_down)]
	var col_bottom_row := {}
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		var key = str(c.x) + "," + str(c.y)
		if visited.has(key):
			continue
		visited[key] = true
		var cx = int(c.x)
		var cy = int(c.y)
		if not col_bottom_row.has(cx) or cy > int(col_bottom_row[cx]):
			col_bottom_row[cx] = cy
		var nbs = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d in nbs:
			var n = c + d
			if n.x < 0 or n.x >= COLS or n.y < 0 or n.y >= ENEMY_ROWS:
				continue
			if obstacles[n.y][n.x] <= 0:
				continue
			stack.append(n)
	var exit_cols: Array = []
	for col_key in col_bottom_row.keys():
		var col = int(col_key)
		var bottom_r = int(col_bottom_row[col_key])
		var exit_r = bottom_r + 1
		if exit_r < ENEMY_ROWS and obstacles[exit_r][col] <= 0:
			exit_cols.append(col)
	if exit_cols.is_empty():
		return -1
	exit_cols.sort()
	var best_col = int(exit_cols[0])
	var best_dist = abs(best_col - monster_x)
	for i in range(1, exit_cols.size()):
		var cand = int(exit_cols[i])
		var dist = abs(cand - monster_x)
		if dist < best_dist:
			best_dist = dist
			best_col = cand
		elif dist == best_dist and cand < best_col:
			best_col = cand
	return best_col

# Порядок проверки влево/вправо: сначала к ближайшему проходу под многоклеточным препятствием
func _horizontal_detour_direction_order(monster_x: int, monster_y: int) -> Array:
	var exit_c = _find_detour_exit_column_below_obstacle(monster_x, monster_y)
	if exit_c < 0:
		var dirs_alt = [-1, 1]
		if (monster_x + monster_y + int(Time.get_ticks_msec() * 0.001)) % 2 == 0:
			dirs_alt.reverse()
		return dirs_alt
	if exit_c < monster_x:
		return [-1, 1]
	if exit_c > monster_x:
		return [1, -1]
	return [-1, 1]

func _plan_enemy_moves() -> Array:
	_enemy_move_anims.clear()
	_cached_mixed_breach_priority = _enemy_mixed_columns_mode()
	var moves: Array = []
	var occupied_next = []
	for yy in range(ENEMY_ROWS):
		var row = []
		for xx in range(COLS): row.append(enemies[yy][xx] > 0)
		occupied_next.append(row)
	for y in range(ENEMY_ROWS - 1, -1, -1):
		for x in range(COLS):
			if enemies[y][x] > 0:
				var hp = enemies[y][x]
				var init = enemies_initial_hp[y][x]
				var was_hit_this_turn = _enemies_hit_this_turn[y][x]
				if was_hit_this_turn:
					pass
				else:
					var moved = false
					if y == _heart_row_y:
						if x < _column_hearts.size() and _column_hearts[x]:
							moves.append({"fx": x, "fy": y, "tx": x, "ty": y, "hp": hp, "init": init, "outcome": "heart_kill"})
						else:
							moves.append({"fx": x, "fy": y, "tx": x, "ty": y, "hp": hp, "init": init, "outcome": "breach"})
						occupied_next[y][x] = false
						moved = true
					elif y + 1 < _enemy_rows_effective:
						var ty = y + 1
						var has_obstacle = obstacles[ty][x] > 0
						if not occupied_next[ty][x] and not has_obstacle:
							moves.append({"fx": x, "fy": y, "tx": x, "ty": ty, "hp": hp, "init": init, "outcome": "normal"})
							occupied_next[y][x] = false
							occupied_next[ty][x] = true
							moved = true
					elif y + 1 < ENEMY_ROWS:
						var tyb = y + 1
						var has_obstacle_b = obstacles[tyb][x] > 0
						if not occupied_next[tyb][x] and not has_obstacle_b:
							moves.append({"fx": x, "fy": y, "tx": x, "ty": tyb, "hp": hp, "init": init, "outcome": "normal"})
							occupied_next[y][x] = false
							occupied_next[tyb][x] = true
							moved = true
					else:
						moves.append({"fx": x, "fy": y, "tx": x, "ty": y+1, "hp": hp, "init": init, "outcome": "breach"})
						occupied_next[y][x] = false
						moved = true
					if not moved:
						var dirs = _horizontal_detour_direction_order(x, y)
						for dx in dirs:
							var nx = x + dx
							if nx >= 0 and nx < COLS:
								var has_obstacle_side = obstacles[y][nx] > 0
								if not occupied_next[y][nx] and not has_obstacle_side:
									moves.append({"fx": x, "fy": y, "tx": nx, "ty": y, "hp": hp, "init": init, "outcome": "normal"})
									occupied_next[y][x] = false
									occupied_next[y][nx] = true
									moved = true
									break
	return moves

func _enemy_moves_include_last_row_attack(moves: Array) -> bool:
	for m in moves:
		if int(m.fy) != _heart_row_y:
			continue
		var outcome = str(m.get("outcome", "normal"))
		if outcome == "heart_kill" or outcome == "breach":
			return true
	return false

func _get_last_row_attack_warn_flash_strength() -> float:
	if not _enemy_attack_warn_pending or _cached_enemy_moves.is_empty():
		return 0.0
	var t = Time.get_ticks_msec() * 0.001
	return 0.5 + 0.5 * sin(t * TAU * ENEMY_ATTACK_WARN_FLASH_HZ * 2.0)

func _is_last_row_attack_warn_cell(x: int, y: int) -> bool:
	if not _enemy_attack_warn_pending:
		return false
	if y != _heart_row_y:
		return false
	for m in _cached_enemy_moves:
		if int(m.fx) != x or int(m.fy) != y:
			continue
		var outcome = str(m.get("outcome", "normal"))
		return outcome == "heart_kill" or outcome == "breach"
	return false

func _apply_enemy_moves_from_plan(moves: Array) -> void:
	var mixed_breach_priority = _cached_mixed_breach_priority
	for yy in range(ENEMY_ROWS):
		for xx in range(COLS):
			_enemies_hit_this_turn[yy][xx] = false
	for m in moves:
		enemies[m.fy][m.fx] = 0
		enemies_initial_hp[m.fy][m.fx] = 0
	
	var vp_size_apply = get_viewport_rect().size
	var origin_apply = _grid_origin(vp_size_apply)
	
	for m in moves:
		var outcome = str(m.get("outcome", "normal"))
		var ax = int(m.fx)
		var init_hp_i = int(m.init)
		if outcome == "breach":
			_defeat_pending_breach = true
			_decrement_level_target_for_init_hp(init_hp_i)
			if not ax in _last_breach_attack_columns:
				_last_breach_attack_columns.append(ax)
			_pending_breach_monsters[ax] = {"hp": m.hp, "init": m.init}
			_needs_ui_update = true
			var y_pos_b = float(m.fy) * ENEMY_CELL_HEIGHT
			var center_pos = origin_apply + Vector2(float(ax) * CELL_SIZE + CELL_SIZE * 0.5, y_pos_b + ENEMY_CELL_HEIGHT * 0.5)
			_board_vfx.append({
				"type": "shockwave",
				"pos": center_pos,
				"color": Color(1.0, 0.2, 0.2),
				"t": 0.0,
				"d": 0.4
			})
			_board_vfx.append({
				"type": "shake",
				"t": 0.0,
				"d": 0.2,
				"intensity": 8.0
			})
		elif outcome == "heart_kill":
			if m.tx < _column_hearts.size() and _column_hearts[m.tx]:
				_column_hearts[m.tx] = false
			_decrement_level_target_for_init_hp(init_hp_i)
			_needs_ui_update = true
			var mid_h = m.tx + m.ty * 10
			_enemy_death_anims.append({
				"x": m.tx, "y": m.ty, "t": 0.0, "d": 0.35,
				"hp": 0, "init": m.init, "id": mid_h,
				"in_heart_strip": true
			})
			_monster_shakes[mid_h] = {"t": 0.0, "d": 0.35, "intensity": 15.0}
			var strip_mid_apply = float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT + HEART_STRIP_HEIGHT * 0.5
			var center_h = origin_apply + Vector2(float(m.tx) * CELL_SIZE + CELL_SIZE * 0.5, strip_mid_apply)
			_board_vfx.append({
				"type": "shockwave",
				"pos": center_h,
				"color": Color(1.0, 0.35, 0.45),
				"t": 0.0,
				"d": 0.35
			})
		else:
			enemies[m.ty][m.tx] = m.hp
			enemies_initial_hp[m.ty][m.tx] = m.init
			_enemy_move_anims.append({
				"fx": m.fx, "fy": m.fy, 
				"tx": m.tx, "ty": m.ty, 
				"hp": m.hp, 
				"init": m.init, 
				"t": 0.0, "d": 0.25
			})

	if _use_scheduled_spawns:
		_process_scheduled_spawns()
	else:
		# Legacy-логика: появление новых врагов в верхнем ряду (row 0)
		for x in range(COLS):
			if mixed_breach_priority and x < _column_hearts.size() and _column_hearts[x]:
				continue
			# Проверяем, что нет препятствия в этой клетке
			if enemies[0][x] == 0 and obstacles[0][x] == 0 and not _monster_spawn_queue.is_empty():
				var hp = _monster_spawn_queue.pop_front()
				enemies[0][x] = hp
				enemies_initial_hp[0][x] = hp
				_enemy_move_anims.append({
					"fx": x, "fy": -1, 
					"tx": x, "ty": 0, 
					"hp": hp, 
					"init": hp, 
					"t": 0.0, "d": 0.25
				})

	if _enemy_move_anims.size() > 0:
		set_process(true)

func _enemy_move_step() -> void:
	if _enemy_attack_warn_pending:
		return
	if _freeze_turns > 0:
		_freeze_turns -= 1
		for y in range(ENEMY_ROWS):
			for x in range(COLS):
				_enemies_hit_this_turn[y][x] = false
		return
	var planned = _plan_enemy_moves()
	if _enemy_moves_include_last_row_attack(planned):
		_cached_enemy_moves = planned
		_enemy_attack_warn_pending = true
		_enemy_attack_warn_time_left = ENEMY_ATTACK_WARN_DURATION
		set_process(true)
		queue_redraw()
		return
	_apply_enemy_moves_from_plan(planned)

func _process_scheduled_spawns():
	for i in range(_scheduled_spawns.size() - 1, -1, -1):
		var item = _scheduled_spawns[i]
		var due_turn = int(item.get("spawn_after_player_turns", 0))
		if due_turn > _player_turn_counter:
			continue
		var x = clamp(int(item.get("x", 0)), 0, COLS - 1)
		var y = clamp(int(item.get("y", 0)), 0, ENEMY_ROWS - 1)
		var hp = max(1, int(item.get("hp", 1)))
		if obstacles[y][x] > 0:
			continue
		if enemies[y][x] > 0:
			continue
		enemies[y][x] = hp
		enemies_initial_hp[y][x] = hp
		_enemy_move_anims.append({
			"fx": x, "fy": y - 1,
			"tx": x, "ty": y,
			"hp": hp,
			"init": hp,
			"t": 0.0, "d": 0.25
		})
		_scheduled_spawns.remove_at(i)

func _apply_gravity_up():
	# Смещаем фишки вверх только внутри зоны игрока (ENEMY_ROWS .. ROWS)
	var new_anims := []
	for x in range(COLS):
		var packed := []
		var origins := []
		for y in range(ENEMY_ROWS, ROWS):
			var v = chips[y][x]
			if v != -1: # Теперь учитываем все фишки, кроме пустых (-1)
				packed.append(v)
				origins.append(y)
		# Записываем плотно начиная сверху зоны игрока
		var write_y = ENEMY_ROWS
		for i in range(packed.size()):
			var v = packed[i]
			var from_y = origins[i]
			chips[write_y][x] = v
			if from_y != write_y:
				new_anims.append({"x": x, "start_y": from_y, "end_y": write_y, "color": v, "t": 0.0, "d": FALL_DURATION})
			write_y += 1
		# Остальные клетки снизу зоны игрока очищаем
		for y in range(write_y, ROWS):
			chips[y][x] = -1
	# Стартуем анимации падения и СРАЗУ заполняем пустоты новыми фишками
	if not new_anims.is_empty():
		_active_anims = _active_anims + new_anims
		set_process(true)
	
	# Заполняем образовавшиеся пустоты (они всегда снизу при гравитации вверх)
	_spawn_new_chips_with_fall()

func _add_chip_pop_vfx(x: int, y: int, color_idx: int):
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var y_pos = 0.0
	var cell_h = CELL_SIZE
	if y < ENEMY_ROWS:
		y_pos = float(y) * ENEMY_CELL_HEIGHT
		cell_h = ENEMY_CELL_HEIGHT
	else:
		y_pos = float(ENEMY_ROWS) * ENEMY_CELL_HEIGHT + float(y - ENEMY_ROWS) * CELL_SIZE + _field_gap_total
	
	var center = origin + Vector2(float(x) * CELL_SIZE + CELL_SIZE * 0.5, y_pos + float(cell_h) * 0.5)
	
	var color = Color.WHITE
	var vfx_color = Color.WHITE
	if color_idx >= 0 and color_idx < CHIP_COLORS.size():
		color = CHIP_COLORS[color_idx]
		# Создаем более насыщенный цвет для эффектов брызг
		match color_idx:
			0: vfx_color = Color(1.0, 0.3, 0.3) # Ярко-красный
			1: vfx_color = Color(0.3, 0.6, 1.0) # Ярко-синий
			2: vfx_color = Color(0.4, 1.0, 0.4) # Ярко-зеленый
			3: vfx_color = Color(1.0, 1.0, 1.0) # Чисто белый
	elif color_idx == RAINBOW_CHIP_IDX:
		vfx_color = Color(0.8, 0.4, 1.0) # Фиолетовый
	elif color_idx == BOMB_CHIP_IDX:
		vfx_color = Color(1.0, 0.5, 0.2) # Оранжевый
	elif color_idx == ROW_BONUS_CHIP_IDX:
		vfx_color = Color(0.3, 0.7, 1.0) # Голубой

	# 1. Вспышка (ударная волна)
	_board_vfx.append({
		"type": "shockwave",
		"pos": center,
		"color": vfx_color,
		"t": 0.0,
		"d": 0.25
	})
	
	# 2. Осколки фишки (частицы)
	for i in range(8):
		var angle = randf() * TAU
		var speed = randf_range(140.0, 280.0)
		var vel = Vector2.RIGHT.rotated(angle) * speed
		_board_vfx.append({
			"type": "particle",
			"pos": center,
			"vel": vel,
			"gravity": Vector2(0, 600.0),
			"color": vfx_color,
			"t": 0.0,
			"d": randf_range(0.4, 0.7),
			"size": randf_range(5.0, 10.0)
		})
	
	# 3. Маленькое облако пыли/света (теперь тоже подкрашено)
	for i in range(5):
		var angle = randf() * TAU
		var dist = randf_range(5.0, 20.0)
		var p_color = vfx_color.lerp(Color.WHITE, 0.6)
		p_color.a = 0.4
		_board_vfx.append({
			"type": "particle",
			"pos": center + Vector2.RIGHT.rotated(angle) * dist,
			"vel": Vector2.RIGHT.rotated(angle) * 50.0,
			"color": p_color,
			"t": 0.0,
			"d": 0.5,
			"size": randf_range(12.0, 18.0)
		})
	
	set_process(true)

func _spawn_bonus_chips_at_start():
	# Собираем все бонусные фишки для спавна (предуровневые + шлем морта)
	var bonus_chips_to_spawn := []
	
	# Бонусы от Шлема Морта
	var arrow_count = _mort_helmet_bonus_chips.get("arrow", 0)
	var bomb_count = _mort_helmet_bonus_chips.get("bomb", 0)
	
	for i in range(arrow_count):
		bonus_chips_to_spawn.append(ROW_BONUS_CHIP_IDX)
	for i in range(bomb_count):
		bonus_chips_to_spawn.append(BOMB_CHIP_IDX)
	
	# Предуровневые усиления
	if _selected_prelevel_boosts.get("arrow", false):
		bonus_chips_to_spawn.append(ROW_BONUS_CHIP_IDX)
	if _selected_prelevel_boosts.get("bomb", false):
		bonus_chips_to_spawn.append(BOMB_CHIP_IDX)
	if _selected_prelevel_boosts.get("rainbow", false):
		bonus_chips_to_spawn.append(RAINBOW_CHIP_IDX)
	
	if bonus_chips_to_spawn.is_empty():
		return
	
	# Получаем список всех пустых клеток в зоне игрока
	var empty_cells := []
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] >= 0: # Обычная фишка (не пустая и не бонус)
				empty_cells.append(Vector2i(x, y))
	
	# Перемешиваем и выбираем рандомные позиции
	empty_cells.shuffle()
	
	var spawn_count = min(bonus_chips_to_spawn.size(), empty_cells.size())
	for i in range(spawn_count):
		var cell = empty_cells[i]
		var bonus_type = bonus_chips_to_spawn[i]
		chips[cell.y][cell.x] = bonus_type
	
	queue_redraw()
