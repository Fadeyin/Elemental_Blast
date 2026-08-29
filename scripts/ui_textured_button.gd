extends Control
class_name UiTexturedButton

signal pressed

var _texture_button: TextureButton
var _label: Label


func setup(
	texture: Texture2D,
	text: String,
	width: float,
	texture_size: Vector2,
	font_size: int = 22,
	text_color: Color = Color(0.98, 0.96, 0.9, 1.0)
) -> void:
	_clear_children()
	var height := maxf(44.0, width * texture_size.y / texture_size.x)
	custom_minimum_size = Vector2(width, height)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_texture_button = TextureButton.new()
	_texture_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_button.texture_normal = texture
	_texture_button.texture_pressed = texture
	_texture_button.texture_hover = texture
	_texture_button.ignore_texture_size = true
	_texture_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_texture_button.focus_mode = Control.FOCUS_NONE
	_texture_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_texture_button.pressed.connect(func() -> void:
		pressed.emit()
	)
	add_child(_texture_button)
	_label = Label.new()
	_label.text = text
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameFonts.style_button_label(_label, font_size, text_color, text_color.get_luminance() < 0.55)
	add_child(_label)


func set_text(value: String) -> void:
	if _label != null:
		_label.text = value


func set_font_size(font_size: int) -> void:
	if _label != null:
		_label.add_theme_font_size_override("font_size", font_size)


func set_disabled(value: bool) -> void:
	if _texture_button != null:
		_texture_button.disabled = value
	modulate = Color(0.72, 0.72, 0.72, 1.0) if value else Color.WHITE


func _clear_children() -> void:
	while get_child_count() > 0:
		var ch := get_child(0)
		remove_child(ch)
		ch.free()
