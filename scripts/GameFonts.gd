extends Node
## Глобальные шрифты Rubik: ExtraBold (wght 800) для текста, Black (wght 900) для цифр.

const RUBIK_VARIABLE_PATH := "res://fonts/Rubik-Variable.ttf"
const WEIGHT_TEXT := 800.0
const WEIGHT_DIGIT := 900.0

const OUTLINE_DIRS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

const GAME_LABEL_SCRIPT := preload("res://scripts/GameLabel.gd")
const GAME_BUTTON_SCRIPT := preload("res://scripts/GameButton.gd")
const META_MIXED_ACTIVE := &"game_fonts_mixed_active"

var text_font: Font
var digit_font: Font

var _tracked: Array[Control] = []
var _last_text_by_id: Dictionary = {}


func _ready() -> void:
	_build_fonts()
	ThemeDB.fallback_font = text_font
	ThemeDB.fallback_font_size = 16
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_existing_tree", get_tree().root)


func _process(_delta: float) -> void:
	_poll_tracked_text()


func _build_fonts() -> void:
	var base: FontFile = load(RUBIK_VARIABLE_PATH) as FontFile
	assert(base != null, "Не удалось загрузить шрифт Rubik: %s" % RUBIK_VARIABLE_PATH)
	var text_var := FontVariation.new()
	text_var.base_font = base
	text_var.variation_opentype = { &"wght": WEIGHT_TEXT }
	text_font = text_var
	var digit_var := FontVariation.new()
	digit_var.base_font = base
	digit_var.variation_opentype = { &"wght": WEIGHT_DIGIT }
	digit_font = digit_var


static func is_digit_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	return code >= 48 and code <= 57


static func text_has_digits(text: String) -> bool:
	for i in range(text.length()):
		if is_digit_char(text.substr(i, 1)):
			return true
	return false


static func text_is_digits_only(text: String) -> bool:
	if text.is_empty():
		return false
	for i in range(text.length()):
		if is_digit_char(text.substr(i, 1)):
			continue
		return false
	return true


static func font_for_char(ch: String) -> Font:
	if is_digit_char(ch):
		return GameFonts.digit_font
	return GameFonts.text_font


func _on_node_added(node: Node) -> void:
	if node == self:
		return
	call_deferred("_setup_node", node)


func _apply_existing_tree(root: Node) -> void:
	_walk_tree(root)


func _walk_tree(node: Node) -> void:
	_setup_node(node)
	for child in node.get_children():
		_walk_tree(child)


func _setup_node(node: Node) -> void:
	if node is Label:
		_setup_label(node as Label)
	elif node is Button:
		_setup_button(node as Button)
	elif node is LineEdit:
		_setup_line_edit(node as LineEdit)


func _track_text_control(control: Control) -> void:
	if control in _tracked:
		return
	_tracked.append(control)
	_last_text_by_id[control.get_instance_id()] = _read_control_text(control)


func _read_control_text(control: Control) -> String:
	if control is Label:
		return (control as Label).text
	if control is Button:
		return (control as Button).text
	if control is LineEdit:
		return (control as LineEdit).text
	return ""


func _poll_tracked_text() -> void:
	for i in range(_tracked.size() - 1, -1, -1):
		var control: Control = _tracked[i]
		if not is_instance_valid(control):
			_tracked.remove_at(i)
			continue
		var id := control.get_instance_id()
		var current := _read_control_text(control)
		if _last_text_by_id.get(id, "") == current:
			continue
		_last_text_by_id[id] = current
		if control is Label:
			_setup_label(control as Label)
		elif control is Button:
			_setup_button(control as Button)
		elif control is LineEdit:
			_setup_line_edit(control as LineEdit)


func _clear_label_script(label: Label) -> void:
	if label.get_script() == GAME_LABEL_SCRIPT:
		label.visible_characters = -1
		label.set_script(null)
	if label.has_meta(META_MIXED_ACTIVE):
		label.remove_meta(META_MIXED_ACTIVE)


func _clear_button_script(button: Button) -> void:
	if button.get_script() == GAME_BUTTON_SCRIPT:
		button.remove_theme_color_override("font_color")
		button.remove_theme_color_override("font_outline_color")
		button.set_script(null)
	if button.has_meta(META_MIXED_ACTIVE):
		button.remove_meta(META_MIXED_ACTIVE)


func _setup_label(label: Label) -> void:
	_track_text_control(label)
	if text_is_digits_only(label.text):
		_clear_label_script(label)
		label.add_theme_font_override("font", digit_font)
		return
	if text_has_digits(label.text):
		label.remove_theme_font_override("font")
		if label.get_script() != GAME_LABEL_SCRIPT:
			label.set_script(GAME_LABEL_SCRIPT)
			label.set_meta(META_MIXED_ACTIVE, true)
			if label.has_method("_activate_mixed_draw"):
				label._activate_mixed_draw()
		return
	_clear_label_script(label)
	label.add_theme_font_override("font", text_font)


func _setup_button(button: Button) -> void:
	_track_text_control(button)
	if text_is_digits_only(button.text):
		_clear_button_script(button)
		button.add_theme_font_override("font", digit_font)
		return
	if text_has_digits(button.text):
		button.remove_theme_font_override("font")
		if button.get_script() != GAME_BUTTON_SCRIPT:
			button.set_script(GAME_BUTTON_SCRIPT)
			button.set_meta(META_MIXED_ACTIVE, true)
			if button.has_method("_activate_mixed_draw"):
				button._activate_mixed_draw()
		return
	_clear_button_script(button)
	button.add_theme_font_override("font", text_font)


func _setup_line_edit(edit: LineEdit) -> void:
	_track_text_control(edit)
	if text_is_digits_only(edit.text) or edit.placeholder_text == "Номер":
		edit.add_theme_font_override("font", digit_font)
	else:
		edit.add_theme_font_override("font", text_font)


static func effective_outline_size(requested: int) -> int:
	return clampi(requested, 0, 2)


func measure_mixed_text_layout(text: String, font_size: int) -> Dictionary:
	var width := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var font := font_for_char(ch)
		width += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		max_ascent = maxf(max_ascent, font.get_ascent(font_size))
		max_descent = maxf(max_descent, font.get_descent(font_size))
	return {
		"width": width,
		"height": max_ascent + max_descent,
		"ascent": max_ascent,
		"descent": max_descent,
	}


func measure_mixed_string(text: String, font_size: int) -> Vector2:
	var layout := measure_mixed_text_layout(text, font_size)
	return Vector2(layout.width, layout.height)


func draw_mixed_string(
	canvas: CanvasItem,
	baseline_pos: Vector2,
	text: String,
	font_size: int,
	color: Color,
	outline_color: Color = Color(0, 0, 0, 0),
	outline_size: int = 0,
	shared_ascent: float = -1.0
) -> void:
	if text.is_empty():
		return
	var layout := measure_mixed_text_layout(text, font_size)
	var max_ascent: float = shared_ascent if shared_ascent >= 0.0 else layout.ascent
	var outline_px := effective_outline_size(outline_size)
	var x := baseline_pos.x
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var font := font_for_char(ch)
		var y: float = baseline_pos.y + (max_ascent - font.get_ascent(font_size))
		if outline_px > 0 and outline_color.a > 0.0:
			for dir: Vector2i in OUTLINE_DIRS:
				for step in range(1, outline_px + 1):
					var off := Vector2(dir.x * step, dir.y * step)
					canvas.draw_string(
						font,
						Vector2(x, y) + off,
						ch,
						HORIZONTAL_ALIGNMENT_LEFT,
						-1,
						font_size,
						outline_color
					)
		canvas.draw_string(font, Vector2(x, y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func draw_mixed_string_in_rect(
	canvas: CanvasItem,
	rect: Rect2,
	text: String,
	font_size: int,
	color: Color,
	h_align: HorizontalAlignment,
	v_align: VerticalAlignment,
	outline_color: Color = Color(0, 0, 0, 0),
	outline_size: int = 0
) -> void:
	if text.is_empty():
		return
	var layout := measure_mixed_text_layout(text, font_size)
	var baseline := rect.position
	if h_align == HORIZONTAL_ALIGNMENT_CENTER:
		baseline.x += (rect.size.x - layout.width) * 0.5
	elif h_align == HORIZONTAL_ALIGNMENT_RIGHT:
		baseline.x += rect.size.x - layout.width
	if v_align == VERTICAL_ALIGNMENT_CENTER:
		baseline.y += (rect.size.y - layout.height) * 0.5 + layout.ascent
	elif v_align == VERTICAL_ALIGNMENT_BOTTOM:
		baseline.y += rect.size.y - layout.descent
	else:
		baseline.y += layout.ascent
	draw_mixed_string(canvas, baseline, text, font_size, color, outline_color, outline_size, layout.ascent)
