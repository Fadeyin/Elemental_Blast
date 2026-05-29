extends Node
## Глобальные шрифты Rubik: ExtraBold (wght 800) для текста, Black (wght 900) для цифр.

const RUBIK_VARIABLE_PATH := "res://fonts/Rubik-Variable.ttf"
const WEIGHT_TEXT := 800.0
const WEIGHT_DIGIT := 900.0

const GAME_LABEL_SCRIPT := preload("res://scripts/GameLabel.gd")
const GAME_BUTTON_SCRIPT := preload("res://scripts/GameButton.gd")

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
		label.set_script(null)


func _clear_button_script(button: Button) -> void:
	if button.get_script() == GAME_BUTTON_SCRIPT:
		button.set_script(null)


func _setup_label(label: Label) -> void:
	_track_text_control(label)
	if text_is_digits_only(label.text):
		_clear_label_script(label)
		label.add_theme_font_override("font", digit_font)
		return
	if text_has_digits(label.text):
		if label.get_script() != GAME_LABEL_SCRIPT:
			label.set_script(GAME_LABEL_SCRIPT)
		if label.has_method("_game_fonts_refresh"):
			label._game_fonts_refresh()
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
		if button.get_script() != GAME_BUTTON_SCRIPT:
			button.set_script(GAME_BUTTON_SCRIPT)
		if button.has_method("_game_fonts_refresh"):
			button._game_fonts_refresh()
		return
	_clear_button_script(button)
	button.add_theme_font_override("font", text_font)


func _setup_line_edit(edit: LineEdit) -> void:
	_track_text_control(edit)
	if text_is_digits_only(edit.text) or edit.placeholder_text == "Номер":
		edit.add_theme_font_override("font", digit_font)
	else:
		edit.add_theme_font_override("font", text_font)


func measure_mixed_string(text: String, font_size: int) -> Vector2:
	var width := 0.0
	var height := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var font := font_for_char(ch)
		var char_size := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		width += char_size.x
		height = maxf(height, char_size.y)
	return Vector2(width, height)


func draw_mixed_string(
	canvas: CanvasItem,
	pos: Vector2,
	text: String,
	font_size: int,
	color: Color,
	outline_color: Color = Color(0, 0, 0, 0),
	outline_size: int = 0
) -> void:
	if text.is_empty():
		return
	var x := pos.x
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var font := font_for_char(ch)
		if outline_size > 0 and outline_color.a > 0.0:
			for ox in range(-outline_size, outline_size + 1):
				for oy in range(-outline_size, outline_size + 1):
					if ox == 0 and oy == 0:
						continue
					canvas.draw_string(font, Vector2(x + ox, pos.y + oy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
		canvas.draw_string(font, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
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
	var text_size := measure_mixed_string(text, font_size)
	var pos := rect.position
	if h_align == HORIZONTAL_ALIGNMENT_CENTER:
		pos.x += (rect.size.x - text_size.x) * 0.5
	elif h_align == HORIZONTAL_ALIGNMENT_RIGHT:
		pos.x += rect.size.x - text_size.x
	if v_align == VERTICAL_ALIGNMENT_CENTER:
		pos.y += (rect.size.y + text_size.y) * 0.5 - text_size.y * 0.85
	elif v_align == VERTICAL_ALIGNMENT_BOTTOM:
		pos.y += rect.size.y - text_size.y * 0.15
	else:
		pos.y += text_size.y * 0.85
	draw_mixed_string(canvas, pos, text, font_size, color, outline_color, outline_size)
