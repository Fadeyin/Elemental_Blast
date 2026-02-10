@tool
extends Node2D

@export var cols: int = 8
@export var rows: int = 16
@export var enemy_rows: int = 10
@export var cell_size: int = 80
@export var enemy_cell_height: int = 40
@export var field_gap: int = 10
@export var line_color: Color = Color(0.35, 0.35, 0.4, 1)
@export var outline_color: Color = Color(0.1, 0.2, 0.4, 1)

func _ready():
	# Превращаем гизмо в чисто редакторский: в рантайме скрываем
	if not Engine.is_editor_hint():
		visible = false
		set_process(false)
		set_physics_process(false)

func _notification(what):
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_READY or what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

func _draw():
	if not Engine.is_editor_hint():
		return
	
	var enemy_h = enemy_rows * enemy_cell_height
	var player_h = (rows - enemy_rows) * cell_size
	var total_h = enemy_h + player_h + field_gap
	var total_w = cols * cell_size
	
	# Outline
	draw_rect(Rect2(Vector2.ZERO, Vector2(total_w, total_h)), outline_color, false, 2.0)
	
	# Enemy Grid
	for x in range(cols + 1):
		var px = float(x) * cell_size
		draw_line(Vector2(px, 0), Vector2(px, enemy_h), line_color, 1.0)
	for y in range(enemy_rows + 1):
		var py = float(y) * enemy_cell_height
		draw_line(Vector2(0, py), Vector2(total_w, py), line_color, 1.0)
		
	# Player Grid
	var p_origin_y = enemy_h + field_gap
	for x in range(cols + 1):
		var px = float(x) * cell_size
		draw_line(Vector2(px, p_origin_y), Vector2(px, p_origin_y + player_h), line_color, 1.5)
	for y in range(rows - enemy_rows + 1):
		var py = p_origin_y + float(y) * cell_size
		draw_line(Vector2(0, py), Vector2(total_w, py), line_color, 1.5)
