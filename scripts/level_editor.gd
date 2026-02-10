extends Control

class_name LevelEditor

# Константы
const CELL_SIZE = 100
const COLS = 8
const ROWS = 8

# Переменные для хранения данных уровня
var current_level_data = {
	"name": "Новый уровень",
	"description": "",
	"difficulty": 1,
	"grid": [],  # Будет хранить состояние сетки
	"enemies": [],  # Будет хранить информацию о врагах
	"rewards": {  # Награды за прохождение
		"gold": 100,
		"dice_charges": 1
	}
}

# Ссылки на узлы
@onready var grid_container = $VBoxContainer/GridContainer
@onready var save_button = $VBoxContainer/HBoxContainer/SaveButton
@onready var load_button = $VBoxContainer/HBoxContainer/LoadButton
@onready var level_name_edit = $VBoxContainer/HBoxContainer/LevelNameEdit
@onready var level_description_edit = $VBoxContainer/LevelDescriptionEdit
@onready var difficulty_spinbox = $VBoxContainer/HBoxContainer/DifficultySpinBox
@onready var red_button = $VBoxContainer/HBoxContainer2/CreatureTypeButtons/RedButton
@onready var blue_button = $VBoxContainer/HBoxContainer2/CreatureTypeButtons/BlueButton
@onready var green_button = $VBoxContainer/HBoxContainer2/CreatureTypeButtons/GreenButton
@onready var purple_button = $VBoxContainer/HBoxContainer2/CreatureTypeButtons/PurpleButton

const CHIP_TEXTURES := [
	preload("res://textures/Сhip_Base_Red.png"),
	preload("res://textures/Сhip_Base_Blue.png"),
	preload("res://textures/Сhip_Base_Green.png"),
	preload("res://textures/Сhip_Base_White.png")
]

# Текущий выбранный тип фишки
var selected_creature_type = 1

func _ready():
	# Инициализируем сетку
	initialize_grid()
	
	# Подключаем сигналы
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	level_name_edit.text_changed.connect(_on_level_name_changed)
	level_description_edit.text_changed.connect(_on_level_description_changed)
	difficulty_spinbox.value_changed.connect(_on_difficulty_changed)
	
	# Подключаем сигналы кнопок выбора типа фишки
	red_button.pressed.connect(_on_creature_type_selected.bind(1))
	blue_button.pressed.connect(_on_creature_type_selected.bind(2))
	green_button.pressed.connect(_on_creature_type_selected.bind(3))
	purple_button.pressed.connect(_on_creature_type_selected.bind(4))
	
	# Выделяем красную фишку по умолчанию
	update_creature_type_buttons()

func initialize_grid():
	# Создаем пустую сетку
	current_level_data.grid = []
	for y in range(ROWS):
		var row = []
		for x in range(COLS):
			row.append(null)
		current_level_data.grid.append(row)
	
	# Создаем визуальные ячейки
	for y in range(ROWS):
		for x in range(COLS):
			var cell = ColorRect.new()
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.color = Color(0.2, 0.2, 0.2, 1.0) if (x + y) % 2 == 0 else Color(0.3, 0.3, 0.3, 1.0)
			cell.gui_input.connect(_on_cell_gui_input.bind(x, y))
			grid_container.add_child(cell)

func _on_cell_gui_input(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Размещаем или удаляем фишку
		if current_level_data.grid[y][x] == null:
			# Создаем новую фишку
			var creature = create_creature(selected_creature_type)
			current_level_data.grid[y][x] = {
				"type": selected_creature_type,
				"level": 1
			}
			grid_container.get_child(y * COLS + x).add_child(creature)
		else:
			# Удаляем существующую фишку
			var cell = grid_container.get_child(y * COLS + x)
			for child in cell.get_children():
				child.queue_free()
			current_level_data.grid[y][x] = null

func create_creature(type: int) -> Control:
	var creature = TextureRect.new()
	creature.size = Vector2(CELL_SIZE, CELL_SIZE)
	creature.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	if type >= 1 and type <= CHIP_TEXTURES.size():
		creature.texture = CHIP_TEXTURES[type - 1]
	
	return creature

func _on_save_button_pressed():
	var save_dialog = FileDialog.new()
	save_dialog.title = "Сохранить уровень"
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.add_filter("*.json", "JSON файлы")
	add_child(save_dialog)
	
	save_dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(current_level_data))
			file.close()
			print("Уровень сохранен в: ", path)
		save_dialog.queue_free()
	)
	
	save_dialog.popup_centered()

func _on_load_button_pressed():
	var load_dialog = FileDialog.new()
	load_dialog.title = "Загрузить уровень"
	load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_dialog.add_filter("*.json", "JSON файлы")
	add_child(load_dialog)
	
	load_dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.parse_string(file.get_as_text())
			if json:
				current_level_data = json
				update_grid_visuals()
				print("Уровень загружен из: ", path)
			file.close()
		load_dialog.queue_free()
	)
	
	load_dialog.popup_centered()

func update_grid_visuals():
	# Очищаем текущую сетку
	for cell in grid_container.get_children():
		for child in cell.get_children():
			child.queue_free()
	
	# Обновляем визуальное отображение
	for y in range(ROWS):
		for x in range(COLS):
			var cell_data = current_level_data.grid[y][x]
			if cell_data != null:
				var creature = create_creature(cell_data.type)
				grid_container.get_child(y * COLS + x).add_child(creature)

func _on_level_name_changed(new_text: String):
	current_level_data.name = new_text

func _on_level_description_changed(new_text: String):
	current_level_data.description = new_text

func _on_difficulty_changed(value: float):
	current_level_data.difficulty = int(value)

func _on_creature_type_selected(type: int):
	selected_creature_type = type
	update_creature_type_buttons()

func update_creature_type_buttons():
	# Сбрасываем все кнопки
	red_button.modulate = Color.WHITE
	blue_button.modulate = Color.WHITE
	green_button.modulate = Color.WHITE
	purple_button.modulate = Color.WHITE
	
	# Выделяем выбранную кнопку
	match selected_creature_type:
		1: red_button.modulate = Color(1.5, 1.5, 1.5)
		2: blue_button.modulate = Color(1.5, 1.5, 1.5)
		3: green_button.modulate = Color(1.5, 1.5, 1.5)
		4: purple_button.modulate = Color(1.5, 1.5, 1.5) 
