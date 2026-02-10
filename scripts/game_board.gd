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
const CHIP_SIZE_FACTOR := 0.95
const CHIP_EDGE_WIDTH := 3.0
const CHIP_SHADOW_OFFSET := Vector2(0, 6)
const CHIP_SHADOW_COLOR := Color(0, 0, 0, 0.25)
const FIELD_GAP := 2.0 # Почти вплотную
const CHIP_HIGHLIGHT_ALPHA := 0.08
const FALL_DURATION := 0.2
const RAINBOW_CHIP_IDX := -2
const ROW_BONUS_CHIP_IDX := -3
const BOMB_CHIP_IDX := -4
const BG_COLOR := Color(0.52, 0.58, 0.68, 1) # Пастельный светло-синий фон
const GAME_BG_TEXTURE := preload("res://textures/Game_Backgound.png")
const ENEMY_TILE_TEXTURE := preload("res://textures/Floor_Enemy_Tile_.png")

# Отступы под UI-панели
const UI_TOP_MARGIN := 72
const UI_BOTTOM_MARGIN := 128

var chips := []
var enemies := [] # 2D массив здоровья врагов (y: 0..ENEMY_ROWS-1)
var enemies_initial_hp := [] # Исходный HP врагов для целей
var _monster_spawn_queue := [] # Очередь монстров для появления на поле
var _projectiles := [] # [{x:int, start_y:float, end_y:float, t:float, d:float, delay:float, color:Color, hit_applied:bool, has_target:bool}]
var _active_anims := [] # [{x:int, start_y:int, end_y:int, color:int, t:float, d:float}]
var _enemy_death_anims := [] # [{x:int, y:int, t:float, d:float}]
var _board_vfx := [] # [{type:str, pos:Vector2, color:Color, t:float, d:float, scale:float}]
var _level_targets := {} # hp -> required count
var _enemy_move_pending: bool = false
var _enemy_move_anims := [] # [{fx:int,fy:int,tx:int,ty:int,hp:int,init:int,t:float,d:float}]

# Ходы уровня
var _moves_total: int = 15
var _moves_left: int = 15
var _player_lives: int = 5
var _needs_ui_update: bool = false

enum BoosterType { NONE, HAMMER, ROW_BLAST, SHUFFLE, FREEZE }
var _active_booster: BoosterType = BoosterType.NONE
var _booster_counts := {
	BoosterType.HAMMER: 4,
	BoosterType.ROW_BLAST: 4,
	BoosterType.SHUFFLE: 4,
	BoosterType.FREEZE: 4
}
var _is_executing_combo: bool = false
var _freeze_turns: int = 0

func _ready():
	randomize()
	var cfg = LevelManager.get_level_config(LevelManager.current_level)
	_init_chips()
	_init_enemies_from_config(cfg)
	_init_moves_from_config(cfg)
	_init_ui()
	_update_ui()
	queue_redraw()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	set_process(true) # Всегда активен для idle-анимаций монстров
	# Кнопка "В меню"
	var back_btn = find_child("BackToMenu", true, false)
	if back_btn != null:
		back_btn.pressed.connect(func():
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
	
	# Полная пересборка TopBar для надежности отображения Жизней и Ходов
	var tb = find_child("TopBar", true, false)
	if tb:
		tb.custom_minimum_size.y = UI_TOP_MARGIN
		tb.offset_bottom = UI_TOP_MARGIN
		tb.alignment = BoxContainer.ALIGNMENT_BEGIN
		tb.add_theme_constant_override("separation", 30)
		
		# Удаляем старые контейнеры, чтобы создать их заново в нужном порядке
		for child in tb.get_children():
			if child.name.begins_with("Lives") or child.name.begins_with("Moves"):
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
		l_count.text = str(_player_lives)
		l_count.add_theme_font_size_override("font_size", 42)
		l_count.add_theme_color_override("font_color", Color.WHITE)
		l_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l_count.add_theme_constant_override("outline_size", 5)
		l_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lc.add_child(l_count)
		
		# 2. Ходы (сразу после жизней)
		var mc = VBoxContainer.new()
		mc.name = "MovesContainerNew"
		mc.custom_minimum_size = Vector2(90, 0)
		mc.add_theme_constant_override("separation", -8)
		mc.alignment = BoxContainer.ALIGNMENT_CENTER
		tb.add_child(mc)
		tb.move_child(mc, 1)
		
		var m_title = Label.new()
		m_title.name = "MovesTitle"
		m_title.text = "ХОДЫ"
		m_title.add_theme_font_size_override("font_size", 14)
		m_title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		m_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mc.add_child(m_title)
		
		var m_count = Label.new()
		m_count.name = "MovesCount"
		m_count.text = str(_moves_left)
		m_count.add_theme_font_size_override("font_size", 42)
		m_count.add_theme_color_override("font_color", Color.WHITE)
		m_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		m_count.add_theme_constant_override("outline_size", 5)
		m_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mc.add_child(m_count)

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
	if _booster_counts.get(type, 0) <= 0: return # Нет зарядов
	
	# Если это мгновенный бустер (Перемешивание)
	if type == BoosterType.SHUFFLE:
		_apply_booster_shuffle()
		_booster_counts[BoosterType.SHUFFLE] -= 1
		_update_ui()
		return
	
	# Если бустер требует выбора цели
	if _active_booster == type:
		_active_booster = BoosterType.NONE
	else:
		_active_booster = type
	
	_update_booster_buttons_visual()

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
		lc_lbl.text = str(_player_lives)
		lc_lbl.add_theme_font_size_override("font_size", 42)
		lc_lbl.add_theme_color_override("font_color", Color.WHITE)
		lc_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lc_lbl.add_theme_constant_override("outline_size", 5)
		if _player_lives <= 1:
			lc_lbl.modulate = Color(1.0, 0.2, 0.2)
		else:
			lc_lbl.modulate = Color(1, 1, 1)

	# Обновление числа ходов (только число)
	var mc = find_child("MovesCount", true, false)
	if mc:
		mc.text = str(_moves_left)
		mc.add_theme_font_size_override("font_size", 42)
		mc.add_theme_color_override("font_color", Color.WHITE)
		mc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		mc.add_theme_constant_override("outline_size", 5)
		# Если ходов мало — подсветим красным
		if _moves_left <= 5:
			mc.modulate = Color(1.0, 0.3, 0.3)
		else:
			mc.modulate = Color(1, 1, 1)
	
	# Обновление заголовка ходов
	var mt = find_child("MovesTitle", true, false)
	if mt:
		mt.text = "ХОДЫ"
		mt.add_theme_font_size_override("font_size", 14)
		mt.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
		mt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		mt.add_theme_constant_override("outline_size", 3)

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
			var count = _booster_counts.get(type, 0)
			# Обновляем текст метки количества
			if btn.has_node("CountLabel"):
				var lbl: Label = btn.get_node("CountLabel")
				lbl.text = str(count)
			
			btn.disabled = (count <= 0)
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
	_level_targets.clear()
	_monster_spawn_queue.clear()
	
	# Подготовим пустую сетку HP=0
	for y in range(ENEMY_ROWS):
		var row := []
		var row0 := []
		for x in range(COLS):
			row.append(0)
			row0.append(0)
		enemies.append(row)
		enemies_initial_hp.append(row0)

	# Собираем всех монстров уровня в общую очередь
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

	# Начальное заполнение: заполняем первые 3 ряда монстрами из очереди
	for y in range(3):
		for x in range(COLS):
			if not _monster_spawn_queue.is_empty():
				var hp = _monster_spawn_queue.pop_front()
				enemies[y][x] = hp
				enemies_initial_hp[y][x] = hp

func _grid_origin(vp_size: Vector2) -> Vector2:
	var grid_size = Vector2(COLS * CELL_SIZE, ENEMY_ROWS * ENEMY_CELL_HEIGHT + PLAYER_ROWS * CELL_SIZE + FIELD_GAP)
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
	
	var grid_size = Vector2(COLS * CELL_SIZE, ROWS * CELL_SIZE + FIELD_GAP)

	# Рисуем текстурный фон самым первым слоем
	if GAME_BG_TEXTURE:
		draw_texture_rect(GAME_BG_TEXTURE, Rect2(Vector2.ZERO, vp_size), false)

	# Заливка зон
	var enemy_rect = Rect2(origin, Vector2(COLS * CELL_SIZE, ENEMY_ROWS * ENEMY_CELL_HEIGHT))
	var player_rect = Rect2(Vector2(origin.x, origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + FIELD_GAP), Vector2(COLS * CELL_SIZE, PLAYER_ROWS * CELL_SIZE))
	
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

	# Текст ходов/целей перенесён в верхнюю панель UI

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
		if a.t < a.d:
			anim_targets[str(a.x)+","+str(a.end_y)] = true

	# Рисуем фишки в зоне игрока (объёмные квадраты)
	var chip_size = CELL_SIZE * CHIP_SIZE_FACTOR
	var pad = (CELL_SIZE - chip_size) * 0.5

	# Враги (монстры) в верхней зоне
	var moving_from := {}
	var moving_to := {}
	for ma in _enemy_move_anims:
		moving_from[str(ma.fx)+","+str(ma.fy)] = true
		moving_to[str(ma.tx)+","+str(ma.ty)] = true
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			if enemies.size() > y and enemies[y].size() > x and enemies[y][x] > 0:
				var key = str(x)+","+str(y)
				if moving_from.has(key) or moving_to.has(key):
					continue
				# Монстры сохраняют пропорции (квадратные), но из-за малой высоты строк
				# они будут перекрывать друг друга по вертикали.
				var e_chip_size = Vector2(CELL_SIZE * CHIP_SIZE_FACTOR, CELL_SIZE * CHIP_SIZE_FACTOR)
				var e_pad_x = (CELL_SIZE - e_chip_size.x) * 0.5
				# Выравниваем монстра по нижнему краю ячейки с небольшим отступом вверх (для тени/анимации)
				var e_top_left = Vector2(origin.x + float(x) * CELL_SIZE + e_pad_x, origin.y + float(y) * ENEMY_CELL_HEIGHT + (ENEMY_CELL_HEIGHT - e_chip_size.y) - 6)
				_draw_enemy_monster(e_top_left, e_chip_size, enemies[y][x], enemies_initial_hp[y][x], x + y * 10)

	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips.size() > y and chips[y].size() > x:
				# Пропускаем конечные клетки активных анимаций — их рисуем отдельно как движущиеся
				if anim_targets.has(str(x)+","+str(y)):
					continue
				var idx = chips[y][x]
				# Добавляем FIELD_GAP для зоны игрока и учитываем разную высоту строк
				var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
				var top_left = Vector2(origin.x + float(x) * CELL_SIZE + pad, origin.y + y_pos + pad)
				var size_v = Vector2(chip_size, chip_size)
				
				if idx == RAINBOW_CHIP_IDX:
					_draw_rainbow_chip(top_left, size_v)
				elif idx == ROW_BONUS_CHIP_IDX:
					_draw_row_bonus_chip(top_left, size_v)
				elif idx == BOMB_CHIP_IDX:
					_draw_bomb_chip(top_left, size_v)
				elif idx >= 0 and idx < CHIP_COLORS.size():
					_draw_chip(top_left, size_v, idx)
					
				# Рисуем индикатор будущего бонуса
				if bonus_cells.has(str(x)+","+str(y)):
					var b_type = bonus_cells[str(x)+","+str(y)]
					var center = top_left + size_v * 0.5
					if b_type == 8:
						# Радужная фишка (черный круг)
						draw_circle(center, size_v.x * 0.25, Color(0, 0, 0, 0.5))
					elif b_type == 7:
						# Горизонтальная ракета (маленькие стрелки)
						var a_color = Color(0, 0, 0, 0.6)
						var a_w = size_v.x * 0.2
						# Левая стрелка
						draw_line(center + Vector2(-a_w, 0), center + Vector2(-a_w+10, -8), a_color, 3.0)
						draw_line(center + Vector2(-a_w, 0), center + Vector2(-a_w+10, 8), a_color, 3.0)
						# Правая стрелка
						draw_line(center + Vector2(a_w, 0), center + Vector2(a_w-10, -8), a_color, 3.0)
						draw_line(center + Vector2(a_w, 0), center + Vector2(a_w-10, 8), a_color, 3.0)
					elif b_type == 6:
						# Бомба (черный круг с фитилем)
						var i_color = Color(0, 0, 0, 0.6)
						var b_r = size_v.x * 0.2
						draw_circle(center, b_r, i_color)
						# Маленький фитиль
						draw_line(center + Vector2(0, -b_r), center + Vector2(8, -b_r-8), i_color, 2.0)

	# Движущиеся фишки
	for a in _active_anims:
		if a.t < a.d:
			var k = clamp(a.t / a.d, 0.0, 1.0)
			# Лёгкое ускорение к концу
			k = pow(k, 0.65)
			var y_interp = lerp(float(a.start_y), float(a.end_y), k)
			# Учитываем разную высоту строк и FIELD_GAP
			var y_pos = 0.0
			if y_interp < ENEMY_ROWS:
				y_pos = y_interp * ENEMY_CELL_HEIGHT
			else:
				y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y_interp - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
			
			var top_left = Vector2(origin.x + float(a.x) * CELL_SIZE + pad, origin.y + y_pos + pad)
			var size_v = Vector2(chip_size, chip_size)
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
		k2 = pow(k2, 0.8)
		var y_interp2 = lerp(p.start_y, p.end_y, k2)
		var cx = origin.x + float(p.x) * CELL_SIZE + CELL_SIZE * 0.5
		var cy_offset = 0.0
		if y_interp2 < ENEMY_ROWS:
			cy_offset = y_interp2 * ENEMY_CELL_HEIGHT + ENEMY_CELL_HEIGHT * 0.5
		else:
			cy_offset = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y_interp2 - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP + CELL_SIZE * 0.5
		var cy = origin.y + cy_offset
		var proj_r = maxf(3.0, float(CELL_SIZE) * 0.08)
		# Тень
		draw_circle(Vector2(cx, cy + 3), proj_r, Color(0,0,0,0.2))
		# Снаряд
		draw_circle(Vector2(cx, cy), proj_r, p.color)

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
	for ma in _enemy_move_anims:
		# ... существующий код отрисовки врагов ...
		var k = clamp(ma.t / ma.d, 0.0, 1.0)
		k = pow(k, 0.8)
		var fx = float(ma.fx)
		var fy = float(ma.fy)
		var tx = float(ma.tx)
		var ty = float(ma.ty)
		var ix = lerp(fx, tx, k)
		var iy = lerp(fy, ty, k)
		var e_chip_size2 = Vector2(CELL_SIZE * CHIP_SIZE_FACTOR, CELL_SIZE * CHIP_SIZE_FACTOR)
		var e_pad_x2 = (CELL_SIZE - e_chip_size2.x) * 0.5
		var e_top_left2 = Vector2(origin.x + ix * CELL_SIZE + e_pad_x2, origin.y + iy * ENEMY_CELL_HEIGHT + (ENEMY_CELL_HEIGHT - e_chip_size2.y) - 6)
		_draw_enemy_monster(e_top_left2, e_chip_size2, int(ma.hp), int(ma.init), ma.fx + ma.fy * 10)

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

	

func _activate_bomb(bx: int, by: int):
	# VFX Бомбы
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (by - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
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
	_trigger_chip_at(bx, by)
	_trigger_chip_at(bx + 1, by)
	_trigger_chip_at(bx - 1, by)
	_trigger_chip_at(bx, by + 1)
	_trigger_chip_at(bx, by - 1)
	
	_apply_gravity_up()
	queue_redraw()

func _trigger_chip_at(x: int, y: int):
	if y < ENEMY_ROWS or y >= ROWS or x < 0 or x >= COLS: return
	var type = chips[y][x]
	if type == -1: return
	
	# Мгновенно помечаем клетку пустой, чтобы избежать бесконечной рекурсии
	chips[y][x] = -1
	_enqueue_projectiles(x, y, 1)
	
	# Если это был бонус — активируем его эффект
	match type:
		RAINBOW_CHIP_IDX:
			_activate_rainbow_chip(x, y)
		ROW_BONUS_CHIP_IDX:
			_apply_row_blast(y)
		BOMB_CHIP_IDX:
			_activate_bomb(x, y)

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
		
		# Легкое свечение для динамики
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = (sin(time * 8.0) + 1.0) * 0.5
		draw_circle(top_left + size_v * 0.5, size_v.x * 0.4, Color(1, 0.9, 0.5, 0.15 * pulse))

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
		
		# Оставляем пульсирующий контур для акцента
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = (sin(time * 5.0) + 1.0) * 0.5
		var border_color = Color(1.0, 1.0, 1.0, 0.3 + pulse * 0.3)
		draw_rect(Rect2(top_left, size_v), border_color, false, 2.0)

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
		
		# Сияние
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = (sin(time * 5.0) + 1.0) * 0.5
		var border_color = Color(1.0, 1.0, 1.0, 0.4 + pulse * 0.4)
		var center = top_left + size_v * 0.5
		draw_arc(center, size_v.x * 0.5, 0, TAU, 32, border_color, 3.0)

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

func _draw_enemy_monster(top_left: Vector2, size_v: Vector2, hp: int, initial_hp: int, monster_id: int):
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
		
		# Эффект заморозки через модуляцию цвета
		var mod_color = Color.WHITE
		if _freeze_turns > 0:
			mod_color = Color(0.5, 0.8, 1.0)
		
		# Тень
		draw_texture_rect(tex, Rect2(rect.position + Vector2(0, 4), rect.size), false, Color(0, 0, 0, 0.3))
		# Сам монстр
		draw_texture_rect(tex, rect, false, mod_color)
		
		# Визуальный урон (трещины поверх текстуры)
		var damage = initial_hp - hp
		if damage > 0:
			_draw_monster_cracks(anim_top_left, anim_size, damage, monster_id)
		
		# Добавляем ледяной эффект поверх
		if _freeze_turns > 0:
			var r = anim_size.x * 0.45
			draw_arc(bottom_center - Vector2(0, anim_size.y * 0.5), r * 0.9, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
	else:
		# Фолбэк на старую отрисовку
		var draw_center = bottom_center - Vector2(0, anim_size.y * 0.5)
		var r = anim_size.x * 0.45
		var body_color = _get_monster_color(initial_hp)
		
		# 1. Тень
		draw_circle(draw_center + Vector2(0, 4), r, Color(0, 0, 0, 0.3))
		
		# 2. Тело (округлое)
		var final_body_color = body_color
		if _freeze_turns > 0:
			final_body_color = body_color.lerp(Color(0.5, 0.8, 1.0), 0.6)
		
		draw_circle(draw_center, r, final_body_color)
		
		# Добавляем ледяной эффект
		if _freeze_turns > 0:
			draw_arc(draw_center, r * 0.9, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.0)
		
		# 3. Детали монстра
		if initial_hp >= 3:
			var horn_color = body_color.lerp(Color.BLACK, 0.3)
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
			_draw_monster_cracks(anim_top_left, anim_size, damage, monster_id)

		# 5. Глаза
		var eye_r = r * 0.25
		var eye_spacing = r * 0.4
		for side in [-1, 1]:
			var eye_pos = draw_center + Vector2(eye_spacing * side, -r * 0.1)
			var eye_bg = Color.WHITE
			if hp == 1 and initial_hp > 1: eye_bg = Color(1, 0.7, 0.7)
			draw_circle(eye_pos, eye_r, eye_bg)
			var pupil_pos = eye_pos
			if damage > 0:
				pupil_pos += Vector2(sin(monster_id + hp + side), cos(monster_id + hp)) * 2.0
			draw_circle(pupil_pos, eye_r * 0.5, Color.BLACK)
			draw_circle(pupil_pos - Vector2(eye_r*0.2, eye_r*0.2), eye_r * 0.15, Color.WHITE)
		
		# 6. Рот
		var mouth_y = draw_center.y + r * 0.4
		var m_w = r * 0.5
		if damage > 0:
			draw_line(Vector2(draw_center.x - m_w, mouth_y + 4), Vector2(draw_center.x, mouth_y - 2), Color.BLACK, 3.0)
			draw_line(Vector2(draw_center.x, mouth_y - 2), Vector2(draw_center.x + m_w, mouth_y + 4), Color.BLACK, 3.0)
		else:
			draw_line(Vector2(draw_center.x - m_w, mouth_y), Vector2(draw_center.x + m_w, mouth_y), Color.BLACK, 2.0)

func _draw_player_zone_overlay():
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var player_rect = Rect2(Vector2(origin.x, origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + FIELD_GAP), Vector2(COLS * CELL_SIZE, PLAYER_ROWS * CELL_SIZE))

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

func _draw_monster_cracks(pos: Vector2, size: Vector2, damage_level: int, seed_val: int):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var crack_color = Color(0, 0, 0, 0.5)
	
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
	if _active_anims.is_empty() and _projectiles.is_empty() and _enemy_death_anims.is_empty() and _enemy_move_anims.is_empty() and _board_vfx.is_empty():
		# Все падения окончены — проверяем нужно ли спавнить новые фишки
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

	for i in range(_active_anims.size() - 1, -1, -1):
		_active_anims[i].t += delta
		if _active_anims[i].t >= _active_anims[i].d:
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
					if enemies[ty][tx] > 0:
						enemies[ty][tx] -= 1
						if enemies[ty][tx] <= 0:
							enemies[ty][tx] = 0
							# Уменьшаем цели по исходному HP этой клетки
							var init_hp = enemies_initial_hp[ty][tx]
							if _level_targets.has(init_hp):
								_level_targets[init_hp] = int(_level_targets[init_hp]) - 1
								if _level_targets[init_hp] < 0:
									_level_targets[init_hp] = 0
							_needs_ui_update = true
							# Запускаем анимацию смерти
							_enemy_death_anims.append({"x": tx, "y": ty, "t": 0.0, "d": 0.35})
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
		if _check_level_completed():
			_on_level_completed()
		elif _moves_left == 0 or _player_lives == 0:
			_on_level_failed()
		elif _enemy_move_pending:
			_enemy_move_step()
			_enemy_move_pending = false
	# после анимаций ничего не применяем — мы уже обновили enemies напрямую
	if _needs_ui_update:
		_needs_ui_update = false
		_update_ui()
	queue_redraw()


func _spawn_new_chips_with_fall():
	var new_anims := []
	var any := false
	for x in range(COLS):
		for y in range(ENEMY_ROWS, ROWS):
			if chips[y][x] == -1:
				any = true
				var color = int(randi() % CHIP_COLORS.size())
				chips[y][x] = color
				new_anims.append({"x": x, "start_y": float(ROWS), "end_y": y, "color": color, "t": 0.0, "d": FALL_DURATION})
	if any and not new_anims.is_empty():
		_active_anims = _active_anims + new_anims
		set_process(true)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		queue_redraw()
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
			_apply_row_blast(cell.y)
		BoosterType.FREEZE:
			_apply_freeze()
	
	if type_used != BoosterType.NONE:
		_booster_counts[type_used] -= 1
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
	_trigger_chip_at(cell.x, cell.y)
	_apply_gravity_up()

func _apply_row_blast(row_y: int):
	# VFX Ракеты
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var center_y = origin.y + row_y * CELL_SIZE + CELL_SIZE * 0.5
	_board_vfx.append({"type": "beam", "pos": Vector2(vp_size.x * 0.5, center_y), "color": Color(0.4, 0.6, 1.0), "t": 0.0, "d": 0.3})
	set_process(true)

	for x in range(COLS):
		_trigger_chip_at(x, row_y)
	
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
	elif y_pixels > enemy_zone_h + FIELD_GAP:
		var y_in_player_zone = y_pixels - enemy_zone_h - FIELD_GAP
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
	
	for cell in cluster:
		chips[cell.y][cell.x] = -1
	
	# Создание бонусов
	var created_bonus := false
	if cluster.size() >= 8:
		chips[y][x] = RAINBOW_CHIP_IDX
		created_bonus = true
	elif cluster.size() == 7:
		chips[y][x] = ROW_BONUS_CHIP_IDX
		created_bonus = true
	elif cluster.size() == 6:
		chips[y][x] = BOMB_CHIP_IDX
		created_bonus = true
		
	# Запускаем снаряды
	if not cluster.is_empty():
		_enqueue_projectiles(x, y, cluster.size() - (1 if created_bonus else 0))
	
	_apply_gravity_up()
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
			var y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (target_y - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
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
			var center_y = origin.y + ENEMY_ROWS * ENEMY_CELL_HEIGHT + (PLAYER_ROWS * 0.5) * CELL_SIZE + FIELD_GAP
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
			# Проверяем, что фишка всё еще на месте
			if chips[p.y][p.x] == special_type:
				# Добавляем VFX для каждого взрыва
				if special_type == BOMB_CHIP_IDX:
					var vp_size = get_viewport_rect().size
					var origin = _grid_origin(vp_size)
					var center_pos = origin + Vector2(p.x * CELL_SIZE + CELL_SIZE * 0.5, p.y * CELL_SIZE + CELL_SIZE * 0.5)
					_board_vfx.append({"type": "bomb_explosion", "pos": center_pos, "color": Color(1, 0.6, 0.2), "t": 0.0, "d": 0.3})
					set_process(true)
				elif special_type == ROW_BONUS_CHIP_IDX:
					var vp_size = get_viewport_rect().size
					var center_y = _grid_origin(vp_size).y + p.y * CELL_SIZE + CELL_SIZE * 0.5
					_board_vfx.append({"type": "beam", "pos": Vector2(vp_size.x * 0.5, center_y), "color": Color(0.4, 0.6, 1.0), "t": 0.0, "d": 0.3})
					set_process(true)
				
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

func _activate_rainbow_chip(rx: int, ry: int):
	var target_color = _get_most_frequent_color_idx()
	if target_color == -1:
		chips[ry][rx] = -1
		_apply_gravity_up()
		return

	# VFX Радуги
	var vp_size = get_viewport_rect().size
	var origin = _grid_origin(vp_size)
	var start_y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (ry - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
	var start_pos = origin + Vector2(rx * CELL_SIZE + CELL_SIZE * 0.5, start_y_pos + CELL_SIZE * 0.5)
	
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] == target_color:
				var end_y_pos = ENEMY_ROWS * ENEMY_CELL_HEIGHT + (y - ENEMY_ROWS) * CELL_SIZE + FIELD_GAP
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
	
	# Лопаем все фишки этого цвета через единую функцию триггера
	for y in range(ENEMY_ROWS, ROWS):
		for x in range(COLS):
			if chips[y][x] == target_color:
				_trigger_chip_at(x, y)
	
	_apply_gravity_up()
	queue_redraw()
func _check_level_completed() -> bool:
	# Победа, если все враги уничтожены (HP == 0) и очередь пуста
	if not _monster_spawn_queue.is_empty():
		return false
		
	for y in range(ENEMY_ROWS):
		for x in range(COLS):
			if enemies[y][x] > 0:
				return false
	return true


func _on_level_completed():
	LevelManager.mark_level_completed()
	# Возврат в меню
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_level_failed():
	# Здесь можно сделать экран поражения, сейчас просто возврат в меню
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _enqueue_projectiles(col_x: int, from_y: int, count: int):
	# Планируем цели по ближайшим врагам снизу вверх, без превышения их суммарного HP
	var hp_left := []
	for yy in range(ENEMY_ROWS):
		var row_hp = 0
		if enemies.size() > yy and enemies[yy].size() > col_x:
			row_hp = enemies[yy][col_x]
		hp_left.append(row_hp)
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
			"delay": float(i) * 0.06,
			"color": Color(1.0, 0.85, 0.2, 1.0),
			"hit_applied": false,
			"has_target": has
		}
		_projectiles.append(proj)
	set_process(true)
	_enemy_move_pending = true

func _enemy_move_step():
	if _freeze_turns > 0:
		_freeze_turns -= 1
		return

	_enemy_move_anims.clear()
	
	# 1. Сдвигаем существующих врагов вниз на одну клетку (начинаем с нижнего ряда)
	for y in range(ENEMY_ROWS - 1, -1, -1):
		for x in range(COLS):
			if enemies[y][x] > 0:
				if y + 1 < ENEMY_ROWS:
					# Если клетка ниже свободна - переносим
					if enemies[y+1][x] == 0:
						enemies[y+1][x] = enemies[y][x]
						enemies_initial_hp[y+1][x] = enemies_initial_hp[y][x]
						enemies[y][x] = 0
						enemies_initial_hp[y][x] = 0
						_enemy_move_anims.append({
							"fx": x, "fy": y, 
							"tx": x, "ty": y+1, 
							"hp": enemies[y+1][x], 
							"init": enemies_initial_hp[y+1][x], 
							"t": 0.0, "d": 0.25
						})
				else:
					# Дошли до нижней границы - атакуем игрока!
					_player_lives = max(0, _player_lives - 1)
					_needs_ui_update = true
					
					# Уменьшаем цели (монстр исчезает, он "выполнил" свою миссию)
					var init_hp = enemies_initial_hp[y][x]
					if _level_targets.has(init_hp):
						_level_targets[init_hp] = max(0, int(_level_targets[init_hp]) - 1)
					
					# Мгновенно убираем монстра с поля
					enemies[y][x] = 0
					enemies_initial_hp[y][x] = 0
					
					# Добавляем визуальный эффект атаки (вспышка на месте монстра)
					var vp_size = get_viewport_rect().size
					var origin = _grid_origin(vp_size)
					var y_pos = float(y) * ENEMY_CELL_HEIGHT
					var center_pos = origin + Vector2(float(x) * CELL_SIZE + CELL_SIZE * 0.5, y_pos + ENEMY_CELL_HEIGHT * 0.5)
					
					_board_vfx.append({
						"type": "shockwave",
						"pos": center_pos,
						"color": Color(1.0, 0.2, 0.2), # Красная вспышка при атаке
						"t": 0.0,
						"d": 0.4
					})
					
					# Тряска экрана (небольшой эффект)
					_board_vfx.append({
						"type": "shake",
						"t": 0.0,
						"d": 0.2,
						"intensity": 8.0
					})

	# 2. Появление новых врагов в верхнем ряду (row 0)
	for x in range(COLS):
		if enemies[0][x] == 0 and not _monster_spawn_queue.is_empty():
			var hp = _monster_spawn_queue.pop_front()
			enemies[0][x] = hp
			enemies_initial_hp[0][x] = hp
			# Анимация появления: "падают" сверху за пределами поля
			_enemy_move_anims.append({
				"fx": x, "fy": -1, 
				"tx": x, "ty": 0, 
				"hp": hp, 
				"init": hp, 
				"t": 0.0, "d": 0.25
			})

	if _enemy_move_anims.size() > 0:
		set_process(true)

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
	# Стартуем анимации
	if not new_anims.is_empty():
		_active_anims = _active_anims + new_anims
		set_process(true)
	else:
		# Если смещать нечего (колонка пустая), сразу спавним новые фишки с анимацией
		_spawn_new_chips_with_fall()

func _init_moves_from_config(cfg: Dictionary):
	var lvl = _get_current_level()
	var def_moves = 15
	if lvl == 1:
		def_moves = 15
	else:
		def_moves = 20
	_moves_total = int(cfg.get("moves", def_moves))
	_moves_left = _moves_total
