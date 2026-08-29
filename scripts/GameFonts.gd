extends Node
## Глобальные шрифты Rubik: ExtraBold (wght 800) для текста, Black (wght 900) для цифр.

const RUBIK_VARIABLE_PATH := "res://fonts/Rubik-Variable.ttf"
const WEIGHT_TEXT := 800.0
const WEIGHT_UI_BODY := 700.0
const WEIGHT_DIGIT := 900.0

const OUTLINE_SOFT_SHADOW := Color(0.14, 0.09, 0.06, 0.32)
const OUTLINE_HUD := Color(0.0, 0.0, 0.0, 0.42)
const OUTLINE_DIALOG := Color(0.04, 0.03, 0.02, 0.58)
const META_DIALOG_STYLE := &"game_fonts_dialog_style"

enum OutlineMode {
	NONE,
	SOFT_SHADOW,
	HUD,
	DIALOG,
}

const OUTLINE_DIRS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
	Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
]

const GAME_LABEL_SCRIPT := preload("res://scripts/GameLabel.gd")
const GAME_BUTTON_SCRIPT := preload("res://scripts/GameButton.gd")
const META_MIXED_ACTIVE := &"game_fonts_mixed_active"

var text_font: Font
var ui_body_font: Font
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
	var body_var := FontVariation.new()
	body_var.base_font = base
	body_var.variation_opentype = { &"wght": WEIGHT_UI_BODY }
	ui_body_font = body_var
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


static func font_for_char(ch: String, use_heavy: bool = false) -> Font:
	if use_heavy:
		return GameFonts.digit_font
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
		elif label.has_method("_game_fonts_refresh"):
			label._game_fonts_refresh()
		_reapply_dialog_label_style(label)
		return
	_clear_label_script(label)
	label.add_theme_font_override("font", text_font)
	_reapply_dialog_label_style(label)


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
		elif button.has_method("_game_fonts_refresh"):
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


static func effective_outline_size(requested: int) -> int:
	return clampi(requested, 0, 2)


func apply_rubik_font(control: Control, use_body_weight: bool = false) -> void:
	if control == null:
		return
	if use_body_weight and ui_body_font != null:
		control.add_theme_font_override("font", ui_body_font)
	elif text_font != null:
		control.add_theme_font_override("font", text_font)


func apply_outline(control: Control, mode: OutlineMode) -> void:
	if control == null:
		return
	match mode:
		OutlineMode.NONE:
			control.add_theme_constant_override("outline_size", 0)
			control.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		OutlineMode.SOFT_SHADOW:
			control.add_theme_constant_override("outline_size", 1)
			control.add_theme_color_override("font_outline_color", OUTLINE_SOFT_SHADOW)
		OutlineMode.HUD:
			control.add_theme_constant_override("outline_size", 2)
			control.add_theme_color_override("font_outline_color", OUTLINE_HUD)
		OutlineMode.DIALOG:
			control.add_theme_constant_override("outline_size", 2)
			control.add_theme_color_override("font_outline_color", OUTLINE_DIALOG)


func _apply_dialog_label_style(label: Label, font_size: int, color: Color, use_body_weight: bool) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.set_meta(&"game_fonts_draw_color", color)
	apply_rubik_font(label, use_body_weight)
	apply_outline(label, OutlineMode.DIALOG)
	label.add_theme_constant_override("line_spacing", 2)
	if label.has_method("queue_redraw"):
		label.queue_redraw()


func _reapply_dialog_label_style(label: Label) -> void:
	if not label.has_meta(META_DIALOG_STYLE):
		return
	var style: Dictionary = label.get_meta(META_DIALOG_STYLE)
	_apply_dialog_label_style(
		label,
		int(style.get("font_size", label.get_theme_font_size("font_size"))),
		style.get("color", label.get_theme_color("font_color")) as Color,
		bool(style.get("use_body_weight", true))
	)


func style_dialog_label(label: Label, font_size: int, color: Color, use_body_weight: bool = true) -> void:
	label.set_meta(META_DIALOG_STYLE, {
		"font_size": font_size,
		"color": color,
		"use_body_weight": use_body_weight,
	})
	_apply_dialog_label_style(label, font_size, color, use_body_weight)
	if not label.is_inside_tree():
		label.tree_entered.connect(func() -> void:
			_reapply_dialog_label_style(label)
		, CONNECT_ONE_SHOT)


func style_button_label(label: Label, font_size: int, color: Color, dark_text: bool = false) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.set_meta(&"game_fonts_draw_color", color)
	apply_rubik_font(label, false)
	apply_outline(label, OutlineMode.DIALOG if dark_text else OutlineMode.SOFT_SHADOW)
	if label.has_method("queue_redraw"):
		label.queue_redraw()


static func measure_mixed_text_layout(text: String, font_size: int, use_heavy: bool = false) -> Dictionary:
	var width := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if ch == "\n":
			continue
		var font := font_for_char(ch, use_heavy)
		width += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		max_ascent = maxf(max_ascent, font.get_ascent(font_size))
		max_descent = maxf(max_descent, font.get_descent(font_size))
	return {
		"width": width,
		"height": max_ascent + max_descent,
		"ascent": max_ascent,
		"descent": max_descent,
	}


func measure_mixed_string(text: String, font_size: int, use_heavy: bool = false) -> Vector2:
	var layout := measure_mixed_text_layout(text, font_size, use_heavy)
	return Vector2(layout.width, layout.height)


func fit_mixed_font_size(
	text: String,
	max_width: float,
	desired_size: int,
	min_size: int = 14,
	use_heavy: bool = false
) -> int:
	var fs: int = maxi(desired_size, min_size)
	if max_width <= 1.0 or text.is_empty():
		return fs
	while fs > min_size:
		if measure_mixed_string(text, fs, use_heavy).x <= max_width:
			return fs
		fs -= 1
	return min_size


func wrap_mixed_text(
	text: String,
	font_size: int,
	max_width: float,
	autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF,
	use_heavy: bool = false
) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var paragraphs := text.split("\n", true)
	var allow_wrap: bool = autowrap_mode != TextServer.AUTOWRAP_OFF and max_width > 1.0
	for paragraph in paragraphs:
		if not allow_wrap:
			lines.append(paragraph)
			continue
		if paragraph.is_empty():
			lines.append("")
			continue
		var words := paragraph.split(" ", false)
		if words.is_empty():
			lines.append("")
			continue
		var current := ""
		for word in words:
			var candidate: String = word if current.is_empty() else current + " " + word
			if measure_mixed_string(candidate, font_size, use_heavy).x <= max_width:
				current = candidate
				continue
			if not current.is_empty():
				lines.append(current)
				current = ""
			if measure_mixed_string(word, font_size, use_heavy).x <= max_width:
				current = word
				continue
			# Длинное слово без пробелов — режем по символам
			var chunk := ""
			for i in range(word.length()):
				var ch := word.substr(i, 1)
				var next_chunk: String = chunk + ch
				if chunk.is_empty() or measure_mixed_string(next_chunk, font_size, use_heavy).x <= max_width:
					chunk = next_chunk
				else:
					lines.append(chunk)
					chunk = ch
			current = chunk
		if not current.is_empty() or words.is_empty():
			lines.append(current)
	if lines.is_empty():
		lines.append("")
	return lines


func measure_mixed_lines(
	lines: PackedStringArray,
	font_size: int,
	line_spacing: float = 0.0,
	use_heavy: bool = false
) -> Dictionary:
	var max_width := 0.0
	var total_height := 0.0
	var max_ascent := 0.0
	var max_descent := 0.0
	var line_height := 0.0
	for i in range(lines.size()):
		var line: String = lines[i]
		var layout := measure_mixed_text_layout(line if not line.is_empty() else " ", font_size, use_heavy)
		max_width = maxf(max_width, layout.width if not line.is_empty() else 0.0)
		max_ascent = maxf(max_ascent, layout.ascent)
		max_descent = maxf(max_descent, layout.descent)
		line_height = layout.height
		total_height += layout.height
		if i < lines.size() - 1:
			total_height += line_spacing
	return {
		"width": max_width,
		"height": total_height,
		"ascent": max_ascent,
		"descent": max_descent,
		"line_height": line_height,
		"line_count": lines.size(),
	}


func measure_mixed_wrapped(
	text: String,
	font_size: int,
	max_width: float,
	autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF,
	line_spacing: float = 0.0,
	use_heavy: bool = false
) -> Dictionary:
	var lines := wrap_mixed_text(text, font_size, max_width, autowrap_mode, use_heavy)
	var measured := measure_mixed_lines(lines, font_size, line_spacing, use_heavy)
	measured["lines"] = lines
	return measured


func draw_mixed_string(
	canvas: CanvasItem,
	baseline_pos: Vector2,
	text: String,
	font_size: int,
	color: Color,
	outline_color: Color = Color(0, 0, 0, 0),
	outline_size: int = 0,
	shared_ascent: float = -1.0,
	use_heavy: bool = false
) -> void:
	if text.is_empty():
		return
	var layout := measure_mixed_text_layout(text, font_size, use_heavy)
	var max_ascent: float = shared_ascent if shared_ascent >= 0.0 else layout.ascent
	var outline_px := effective_outline_size(outline_size)
	var x := baseline_pos.x
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		if ch == "\n":
			continue
		var font := font_for_char(ch, use_heavy)
		var y: float = baseline_pos.y + (max_ascent - font.get_ascent(font_size))
		if outline_px > 0 and outline_color.a > 0.0:
			if outline_px == 1:
				canvas.draw_string(
					font,
					Vector2(x + 1.0, y + 1.0),
					ch,
					HORIZONTAL_ALIGNMENT_LEFT,
					-1,
					font_size,
					Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.65)
				)
			else:
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
							Color(outline_color.r, outline_color.g, outline_color.b, outline_color.a * 0.75)
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
	outline_size: int = 0,
	use_heavy: bool = false,
	autowrap_mode: TextServer.AutowrapMode = TextServer.AUTOWRAP_OFF,
	line_spacing: float = 0.0
) -> void:
	if text.is_empty():
		return
	var max_width: float = rect.size.x
	var measured := measure_mixed_wrapped(text, font_size, max_width, autowrap_mode, line_spacing, use_heavy)
	var lines: PackedStringArray = measured.lines
	var block_height: float = measured.height
	var line_height: float = measured.line_height
	var y0 := rect.position.y
	if v_align == VERTICAL_ALIGNMENT_CENTER:
		y0 += (rect.size.y - block_height) * 0.5
	elif v_align == VERTICAL_ALIGNMENT_BOTTOM:
		y0 += rect.size.y - block_height
	var y := y0
	for i in range(lines.size()):
		var line: String = lines[i]
		var layout := measure_mixed_text_layout(line if not line.is_empty() else " ", font_size, use_heavy)
		var baseline := Vector2(rect.position.x, y + layout.ascent)
		if h_align == HORIZONTAL_ALIGNMENT_CENTER:
			baseline.x += (rect.size.x - layout.width) * 0.5
		elif h_align == HORIZONTAL_ALIGNMENT_RIGHT:
			baseline.x += rect.size.x - layout.width
		if not line.is_empty():
			draw_mixed_string(canvas, baseline, line, font_size, color, outline_color, outline_size, layout.ascent, use_heavy)
		y += line_height
		if i < lines.size() - 1:
			y += line_spacing

