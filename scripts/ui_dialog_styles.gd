extends RefCounted
class_name UiDialogStyles

const PANEL_TEXTURE := preload("res://textures/ui_main_menu_toolbar_bg.png")
const SECTION_TEXTURE := preload("res://textures/ingame_booster_slot_bg.png")
const PRIMARY_BUTTON_TEXTURE := preload("res://textures/ui_main_menu_play_button.png")
const SECONDARY_BUTTON_TEXTURE := preload("res://textures/ui_bottom_nav_bg.png")
const SMALL_BUTTON_TEXTURE := preload("res://textures/ui_buy_coins_button.png")
const ROUND_BUTTON_TEXTURE := preload("res://textures/ui_menu_round_button_bg.png")

# Размеры исходных текстур и 9-slice margins (left, top, right, bottom) в пикселях арта.
const PANEL_TEX_SIZE := Vector2i(1640, 336)
const PANEL_SLICE := Vector4i(168, 74, 168, 74)
const PANEL_CONTENT_PAD := Vector4i(22, 18, 22, 18)

const SECTION_TEX_SIZE := Vector2i(905, 919)
const SECTION_SLICE := Vector4i(300, 300, 300, 300)
const SECTION_CONTENT_PAD := Vector4i(12, 10, 12, 10)

const PRIMARY_BTN_TEX_SIZE := Vector2i(1371, 474)
const PRIMARY_BTN_SLICE := Vector4i(237, 86, 237, 86)
const PRIMARY_BTN_CONTENT_PAD := Vector4i(20, 10, 20, 14)

const SECONDARY_BTN_TEX_SIZE := Vector2i(2234, 416)
const SECONDARY_BTN_SLICE := Vector4i(208, 78, 208, 78)
const SECONDARY_BTN_CONTENT_PAD := Vector4i(18, 8, 18, 12)

const SMALL_BTN_TEX_SIZE := Vector2i(705, 679)
const SMALL_BTN_SLICE := Vector4i(230, 230, 230, 230)
const SMALL_BTN_CONTENT_PAD := Vector4i(8, 6, 8, 8)

const ROUND_BTN_TEX_SIZE := Vector2i(1091, 1121)
const ROUND_BTN_SLICE := Vector4i(480, 480, 480, 480)
const ROUND_BTN_CONTENT_PAD := Vector4i(10, 8, 10, 10)

const COMPACT_DIALOG_WIDTH := 520.0
const MEDIUM_DIALOG_WIDTH := 560.0

const TITLE_COLOR := Color(0.18, 0.12, 0.08, 1.0)
const BODY_COLOR := Color(0.28, 0.2, 0.14, 1.0)
const MUTED_COLOR := Color(0.42, 0.32, 0.24, 1.0)
const ACCENT_COLOR := Color(0.78, 0.42, 0.12, 1.0)
const PRIMARY_TEXT_COLOR := Color(0.98, 0.96, 0.9, 1.0)
const SECONDARY_TEXT_COLOR := Color(0.22, 0.14, 0.08, 1.0)


static func create_dimmer(alpha: float = 0.55) -> ColorRect:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, alpha)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	return dimmer


static func create_dialog_center(width: float = COMPACT_DIALOG_WIDTH) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 20.0
	center.offset_top = 48.0
	center.offset_right = -20.0
	center.offset_bottom = -48.0
	return center


static func create_dialog_panel(width: float = COMPACT_DIALOG_WIDTH) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(width, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply_panel_style(panel)
	return panel


static func _apply_nine_slice(style: StyleBoxTexture, slice: Vector4i, content_pad: Vector4i) -> void:
	style.texture_margin_left = slice.x
	style.texture_margin_top = slice.y
	style.texture_margin_right = slice.z
	style.texture_margin_bottom = slice.w
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.draw_center = true
	style.content_margin_left = content_pad.x
	style.content_margin_top = content_pad.y
	style.content_margin_right = content_pad.z
	style.content_margin_bottom = content_pad.w


static func _make_stylebox(texture: Texture2D, slice: Vector4i, content_pad: Vector4i) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	_apply_nine_slice(style, slice, content_pad)
	return style


static func make_panel_stylebox() -> StyleBoxTexture:
	return _make_stylebox(PANEL_TEXTURE, PANEL_SLICE, PANEL_CONTENT_PAD)


static func make_section_stylebox() -> StyleBoxTexture:
	return _make_stylebox(SECTION_TEXTURE, SECTION_SLICE, SECTION_CONTENT_PAD)


static func make_primary_button_stylebox() -> StyleBoxTexture:
	return _make_stylebox(PRIMARY_BUTTON_TEXTURE, PRIMARY_BTN_SLICE, PRIMARY_BTN_CONTENT_PAD)


static func make_secondary_button_stylebox() -> StyleBoxTexture:
	return _make_stylebox(SECONDARY_BUTTON_TEXTURE, SECONDARY_BTN_SLICE, SECONDARY_BTN_CONTENT_PAD)


static func make_small_button_stylebox() -> StyleBoxTexture:
	return _make_stylebox(SMALL_BUTTON_TEXTURE, SMALL_BTN_SLICE, SMALL_BTN_CONTENT_PAD)


static func make_round_button_stylebox() -> StyleBoxTexture:
	return _make_stylebox(ROUND_BUTTON_TEXTURE, ROUND_BTN_SLICE, ROUND_BTN_CONTENT_PAD)


static func apply_panel(panel: PanelContainer) -> void:
	apply_panel_style(panel)


static func apply_panel_style(control: Control) -> void:
	control.add_theme_stylebox_override("panel", make_panel_stylebox())


static func apply_section(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_section_stylebox())


static func make_slot_stylebox() -> StyleBoxTexture:
	return make_section_stylebox()


static func make_slot_pressed_stylebox() -> StyleBoxTexture:
	var style := make_section_stylebox()
	style.modulate_color = Color(0.88, 0.94, 1.0, 1.0)
	return style


static func make_slot_disabled_stylebox() -> StyleBoxTexture:
	var style := make_section_stylebox()
	style.modulate_color = Color(0.62, 0.62, 0.66, 0.82)
	return style


static func primary_button_height_for_width(width: float) -> float:
	return maxf(44.0, width * float(PRIMARY_BTN_TEX_SIZE.y) / float(PRIMARY_BTN_TEX_SIZE.x))


static func secondary_button_height_for_width(width: float) -> float:
	return maxf(42.0, width * float(SECONDARY_BTN_TEX_SIZE.y) / float(SECONDARY_BTN_TEX_SIZE.x))


static func _apply_button_styleboxes(button: Button, normal: StyleBoxTexture, pressed_pad_delta: int = 2) -> void:
	var hover := normal.duplicate() as StyleBoxTexture
	var pressed := normal.duplicate() as StyleBoxTexture
	pressed.content_margin_top = normal.content_margin_top + pressed_pad_delta
	pressed.content_margin_bottom = maxi(0, normal.content_margin_bottom - pressed_pad_delta)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", normal)


static func create_accent_title_label(text: String, accent: Color = ACCENT_COLOR, font_size: int = 48) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	return label


static func create_title_label(text: String, font_size: int = 30) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TITLE_COLOR)
	return label


static func create_body_label(text: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", BODY_COLOR)
	return label


static func create_muted_label(text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", MUTED_COLOR)
	return label


static func create_primary_button(text: String, width: float = 280.0) -> Button:
	var button := Button.new()
	button.text = text
	var btn_width := width if width > 0.0 else 280.0
	var height := primary_button_height_for_width(btn_width)
	button.custom_minimum_size = Vector2(width if width > 0.0 else 0.0, height)
	_apply_button_styleboxes(button, make_primary_button_stylebox())
	button.add_theme_color_override("font_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", PRIMARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 22)
	return button


static func create_secondary_button(text: String, width: float = 280.0) -> Button:
	var button := Button.new()
	button.text = text
	var height := secondary_button_height_for_width(width)
	button.custom_minimum_size = Vector2(width, height)
	_apply_button_styleboxes(button, make_secondary_button_stylebox())
	button.add_theme_color_override("font_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", SECONDARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 20)
	return button


static func create_small_icon_button(text: String = "+", size: float = 40.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(size, size)
	_apply_button_styleboxes(button, make_small_button_stylebox(), 1)
	button.add_theme_color_override("font_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", PRIMARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 22)
	return button


static func create_round_info_button(text: String = "i", size: float = 36.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(size, size)
	_apply_button_styleboxes(button, make_round_button_stylebox(), 1)
	button.add_theme_color_override("font_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", SECONDARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 18)
	return button
