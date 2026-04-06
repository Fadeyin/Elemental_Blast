extends Control

signal step_advanced
signal tutorial_finished

const DIM_COLOR := Color(0, 0, 0, 0.82)
const HOLE_BORDER_COLOR := Color(0.95, 0.82, 0.25, 1.0)
const HOLE_BORDER_WIDTH := 4.0
# Резерв под нижнюю панель (бустеры / назад), как UI_BOTTOM_MARGIN в game_board
const BOTTOM_UI_RESERVE := 128.0

enum Phase { NONE = 0, ENEMY_INTRO = 1, CHIPS_HINT = 2, GOALS_HINT = 3, FULL_DIM = 4 }

var _phase: int = Phase.NONE
var _hole_rect: Rect2 = Rect2()
var _instruction_label: Label
var _board: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_instruction_label = Label.new()
	_instruction_label.name = "TutorialInstruction"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.add_theme_font_size_override("font_size", 22)
	_instruction_label.add_theme_color_override("font_color", Color.WHITE)
	_instruction_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_instruction_label.add_theme_constant_override("outline_size", 5)
	_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_instruction_label)

func set_board(board: Node) -> void:
	_board = board

func _await_valid_size() -> void:
	for _i in range(12):
		if size.x > 32.0 and size.y > 32.0:
			return
		await get_tree().process_frame

func begin_enemy_step(enemy_rect_viewport: Rect2, message: String) -> void:
	await _await_valid_size()
	_phase = Phase.ENEMY_INTRO
	_hole_rect = enemy_rect_viewport
	mouse_filter = Control.MOUSE_FILTER_STOP
	await _position_instruction_below_hole(enemy_rect_viewport, message)
	queue_redraw()

func begin_chips_step(player_rect_viewport: Rect2, message: String) -> void:
	await _await_valid_size()
	_phase = Phase.CHIPS_HINT
	_hole_rect = player_rect_viewport
	mouse_filter = Control.MOUSE_FILTER_STOP
	await _position_instruction_above_hole(player_rect_viewport, message)
	queue_redraw()

func begin_goals_step(goals_rect_viewport: Rect2, center_message: String) -> void:
	await _await_valid_size()
	_phase = Phase.GOALS_HINT
	_hole_rect = goals_rect_viewport
	mouse_filter = Control.MOUSE_FILTER_STOP
	await _center_instruction_label(center_message)
	queue_redraw()

func dismiss_visual() -> void:
	_phase = Phase.NONE
	_instruction_label.text = ""
	queue_redraw()

func show_full_screen_dim() -> void:
	_phase = Phase.FULL_DIM
	_instruction_label.text = ""
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _position_instruction_below_hole(hole: Rect2, text: String) -> void:
	_instruction_label.add_theme_font_size_override("font_size", 22)
	_instruction_label.text = text
	var margin := 12.0
	var side_pad := 16.0
	var max_w: float = maxf(120.0, size.x - side_pad * 2.0)
	_instruction_label.custom_minimum_size = Vector2(max_w, 0.0)
	_instruction_label.size = Vector2(max_w, 0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var label_h: float = _instruction_label.get_content_height() + 4.0
	if label_h < 24.0:
		label_h = _instruction_label.size.y
	label_h = maxf(label_h, 40.0)
	var cx: float = hole.position.x + hole.size.x * 0.5
	var top_y: float = hole.end.y + margin
	var left: float = clampf(cx - max_w * 0.5, side_pad, maxf(side_pad, size.x - max_w - side_pad))
	var max_top: float = size.y - BOTTOM_UI_RESERVE - label_h - 8.0
	if top_y > max_top:
		top_y = maxf(hole.end.y + 4.0, max_top)
	if top_y + label_h > size.y - 4.0:
		_instruction_label.add_theme_font_size_override("font_size", 18)
		await get_tree().process_frame
		label_h = maxf(_instruction_label.get_content_height() + 4.0, 32.0)
		max_top = size.y - BOTTOM_UI_RESERVE - label_h - 8.0
		if top_y > max_top:
			top_y = maxf(8.0, max_top)
	_instruction_label.position = Vector2(left, top_y)
	_instruction_label.size = Vector2(max_w, label_h)

func _position_instruction_above_hole(hole: Rect2, text: String) -> void:
	_instruction_label.text = text
	var margin := 16.0
	var max_w: float = min(size.x - 32.0, 560.0)
	_instruction_label.custom_minimum_size = Vector2(max_w, 0.0)
	_instruction_label.size = Vector2(max_w, 0.0)
	await get_tree().process_frame
	var label_h: float = _instruction_label.size.y
	var cx: float = hole.position.x + hole.size.x * 0.5
	var bottom_y: float = hole.position.y - margin
	var top_y: float = bottom_y - label_h
	top_y = maxf(16.0, top_y)
	var left: float = clampf(cx - max_w * 0.5, 16.0, size.x - max_w - 16.0)
	_instruction_label.position = Vector2(left, top_y)
	_instruction_label.size = Vector2(max_w, max(label_h, 40.0))

func _center_instruction_label(text: String) -> void:
	_instruction_label.text = text
	var max_w: float = min(size.x - 48.0, 560.0)
	_instruction_label.custom_minimum_size = Vector2(max_w, 0.0)
	_instruction_label.size = Vector2(max_w, 0.0)
	await get_tree().process_frame
	var label_size: Vector2 = _instruction_label.size
	var pos := Vector2((size.x - label_size.x) * 0.5, (size.y - label_size.y) * 0.5)
	_instruction_label.position = pos
	_instruction_label.size = label_size

func _draw() -> void:
	if _phase == Phase.NONE:
		return
	if _phase == Phase.FULL_DIM:
		draw_rect(Rect2(Vector2.ZERO, size), DIM_COLOR)
		return
	var vp := Rect2(Vector2.ZERO, size)
	var h := _hole_rect.intersection(vp)
	if h.size.x <= 0.0 or h.size.y <= 0.0:
		draw_rect(vp, DIM_COLOR)
		return
	if h.position.y > 0.0:
		draw_rect(Rect2(0.0, 0.0, vp.size.x, h.position.y), DIM_COLOR)
	if h.end.y < vp.size.y:
		draw_rect(Rect2(0.0, h.end.y, vp.size.x, vp.size.y - h.end.y), DIM_COLOR)
	var mid_top: float = h.position.y
	var mid_h: float = h.size.y
	if h.position.x > 0.0:
		draw_rect(Rect2(0.0, mid_top, h.position.x, mid_h), DIM_COLOR)
	if h.end.x < vp.size.x:
		draw_rect(Rect2(h.end.x, mid_top, vp.size.x - h.end.x, mid_h), DIM_COLOR)
	draw_rect(Rect2(h.position, h.size), HOLE_BORDER_COLOR, false, HOLE_BORDER_WIDTH)

func _gui_input(event: InputEvent) -> void:
	if _phase == Phase.NONE:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _phase == Phase.CHIPS_HINT:
		if _hole_rect.has_point(event.position) and _board != null and _board.has_method("tutorial_forward_chip_click"):
			_board.tutorial_forward_chip_click(event.global_position)
		accept_event()
		return
	if _phase == Phase.ENEMY_INTRO:
		emit_signal("step_advanced")
		accept_event()
	elif _phase == Phase.GOALS_HINT:
		emit_signal("tutorial_finished")
		accept_event()
