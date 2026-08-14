extends RefCounted
class_name UiDialogStyles

const PANEL_TEXTURE := preload("res://textures/ingame_booster_slot_bg.png")
const SECTION_TEXTURE := preload("res://textures/ingame_booster_slot_bg.png")
const PRIMARY_BUTTON_TEXTURE := preload("res://textures/ui_main_menu_play_button.png")
const SECONDARY_BUTTON_TEXTURE := preload("res://textures/ui_bottom_nav_bg.png")
const SMALL_BUTTON_TEXTURE := preload("res://textures/ui_buy_coins_button.png")
const ROUND_BUTTON_TEXTURE := preload("res://textures/ui_menu_round_button_bg.png")

const PANEL_TEX_SIZE := Vector2i(905, 919)
const PANEL_SLICE := Vector4i(330, 330, 330, 330)
const PANEL_CONTENT_PAD := Vector4i(24, 20, 24, 20)

const SECTION_TEX_SIZE := Vector2i(905, 919)
const SECTION_SLICE := Vector4i(280, 280, 280, 280)
const SECTION_CONTENT_PAD := Vector4i(10, 8, 10, 8)

const PRIMARY_BTN_TEX_SIZE := Vector2(1371.0, 474.0)
const SECONDARY_BTN_TEX_SIZE := Vector2(2234.0, 416.0)
const SMALL_BTN_TEX_SIZE := Vector2(705.0, 679.0)
const ROUND_BTN_TEX_SIZE := Vector2(1091.0, 1121.0)

const COMPACT_DIALOG_WIDTH := 480.0
const MEDIUM_DIALOG_WIDTH := 520.0
const ACTION_BUTTON_WIDTH := 300.0

const TITLE_COLOR := Color(0.18, 0.12, 0.08, 1.0)
const BODY_COLOR := Color(0.28, 0.2, 0.14, 1.0)
const MUTED_COLOR := Color(0.42, 0.32, 0.24, 1.0)
const ACCENT_COLOR := Color(0.78, 0.42, 0.12, 1.0)
const PRIMARY_TEXT_COLOR := Color(0.98, 0.96, 0.9, 1.0)
const SECONDARY_TEXT_COLOR := Color(0.22, 0.14, 0.08, 1.0)

const PANEL_BORDER_COLOR := Color(0.18, 0.72, 0.78, 1.0)
const PANEL_FILL_COLOR := Color(0.96, 0.9, 0.8, 0.98)


static func create_dimmer(alpha: float = 0.62) -> ColorRect:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, alpha)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	return dimmer


static func create_dialog_center() -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 24.0
	center.offset_top = 72.0
	center.offset_right = -24.0
	center.offset_bottom = -72.0
	return center


static func create_dialog_panel(width: float = COMPACT_DIALOG_WIDTH) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply_panel(panel)
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


static func make_flat_panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_FILL_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = PANEL_CONTENT_PAD.x
	style.content_margin_top = PANEL_CONTENT_PAD.y
	style.content_margin_right = PANEL_CONTENT_PAD.z
	style.content_margin_bottom = PANEL_CONTENT_PAD.w
	return style


static func make_flat_cell_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 4
	return style


static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_panel_stylebox())


static func apply_panel_style(control: Control) -> void:
	if control is PanelContainer:
		apply_panel(control as PanelContainer)
	else:
		control.add_theme_stylebox_override("panel", make_panel_stylebox())


static func apply_section(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_section_stylebox())


static func make_slot_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.94, 0.9, 0.84, 0.95), Color(0.28, 0.62, 0.72, 1.0))


static func make_slot_pressed_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.88, 0.94, 0.98, 0.95), Color(0.28, 0.62, 0.72, 1.0))


static func make_slot_disabled_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.78, 0.78, 0.8, 0.55), Color(0.55, 0.55, 0.58, 0.7))


static func primary_button_height_for_width(width: float) -> float:
	return maxf(44.0, width * PRIMARY_BTN_TEX_SIZE.y / PRIMARY_BTN_TEX_SIZE.x)


static func secondary_button_height_for_width(width: float) -> float:
	return maxf(42.0, width * SECONDARY_BTN_TEX_SIZE.y / SECONDARY_BTN_TEX_SIZE.x)


static func create_primary_button(text: String, width: float = ACTION_BUTTON_WIDTH) -> UiTexturedButton:
	var button := UiTexturedButton.new()
	button.setup(PRIMARY_BUTTON_TEXTURE, text, width, PRIMARY_BTN_TEX_SIZE, 22, PRIMARY_TEXT_COLOR)
	return button


static func create_secondary_button(text: String, width: float = ACTION_BUTTON_WIDTH) -> UiTexturedButton:
	var button := UiTexturedButton.new()
	button.setup(SECONDARY_BUTTON_TEXTURE, text, width, SECONDARY_BTN_TEX_SIZE, 20, SECONDARY_TEXT_COLOR)
	return button


static func create_small_icon_button(text: String = "+", size: float = 40.0) -> UiTexturedButton:
	var button := UiTexturedButton.new()
	button.setup(SMALL_BUTTON_TEXTURE, text, size, SMALL_BTN_TEX_SIZE, 20, PRIMARY_TEXT_COLOR)
	return button


static func create_round_info_button(text: String = "i", size: float = 36.0) -> UiTexturedButton:
	var button := UiTexturedButton.new()
	button.setup(ROUND_BUTTON_TEXTURE, text, size, ROUND_BTN_TEX_SIZE, 16, SECONDARY_TEXT_COLOR)
	return button


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
