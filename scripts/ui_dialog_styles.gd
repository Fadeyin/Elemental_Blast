extends RefCounted
class_name UiDialogStyles

const PRIMARY_BUTTON_TEXTURE := preload("res://textures/ui_main_menu_play_button.png")
const SECONDARY_BUTTON_TEXTURE := preload("res://textures/ui_bottom_nav_bg.png")
const SMALL_BUTTON_TEXTURE := preload("res://textures/ui_buy_coins_button.png")
const ROUND_BUTTON_TEXTURE := preload("res://textures/ui_menu_round_button_bg.png")

const PRIMARY_BTN_TEX_SIZE := Vector2(1371.0, 474.0)
const SECONDARY_BTN_TEX_SIZE := Vector2(2234.0, 416.0)
const SMALL_BTN_TEX_SIZE := Vector2(705.0, 679.0)
const ROUND_BTN_TEX_SIZE := Vector2(1091.0, 1121.0)

const COMPACT_DIALOG_WIDTH := 440.0
const MEDIUM_DIALOG_WIDTH := 480.0
const ACTION_BUTTON_WIDTH := 280.0

const TITLE_COLOR := Color(0.18, 0.12, 0.08, 1.0)
const BODY_COLOR := Color(0.28, 0.2, 0.14, 1.0)
const MUTED_COLOR := Color(0.42, 0.32, 0.24, 1.0)
const ACCENT_COLOR := Color(0.78, 0.42, 0.12, 1.0)
const PRIMARY_TEXT_COLOR := Color(0.98, 0.96, 0.9, 1.0)
const SECONDARY_TEXT_COLOR := Color(0.22, 0.14, 0.08, 1.0)

const PANEL_BORDER_COLOR := Color(0.12, 0.62, 0.68, 1.0)
const PANEL_FILL_COLOR := Color(0.97, 0.91, 0.82, 1.0)
const SECTION_FILL_COLOR := Color(0.93, 0.87, 0.78, 1.0)
const SECTION_BORDER_COLOR := Color(0.22, 0.58, 0.64, 1.0)


static func create_dimmer(alpha: float = 0.65) -> ColorRect:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, alpha)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	return dimmer


static func mount_dialog_center(parent: Control, host_name: String = "DialogCenterHost", center_name: String = "DialogCenter") -> CenterContainer:
	var host := VBoxContainer.new()
	host.name = host_name
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.offset_left = 24.0
	host.offset_top = 24.0
	host.offset_right = -24.0
	host.offset_bottom = -24.0
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(top_spacer)
	var center := CenterContainer.new()
	center.name = center_name
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	host.add_child(center)
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bottom_spacer)
	parent.add_child(host)
	return center


static func create_dialog_panel(width: float = COMPACT_DIALOG_WIDTH) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply_panel(panel)
	return panel


static func make_flat_panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_FILL_COLOR
	style.border_color = PANEL_BORDER_COLOR
	style.set_border_width_all(5)
	style.set_corner_radius_all(22)
	style.border_blend = true
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 5)
	style.anti_aliasing = true
	style.content_margin_left = 20
	style.content_margin_top = 18
	style.content_margin_right = 20
	style.content_margin_bottom = 18
	return style


static func make_flat_section_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SECTION_FILL_COLOR
	style.border_color = SECTION_BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.border_blend = true
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


static func make_flat_cell_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.border_blend = true
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 4
	return style


static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_flat_panel_stylebox())


static func apply_panel_style(control: Control) -> void:
	if control is PanelContainer:
		apply_panel(control as PanelContainer)
	else:
		control.add_theme_stylebox_override("panel", make_flat_panel_stylebox())


static func apply_section(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_flat_section_stylebox())


static func make_slot_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.95, 0.9, 0.82, 1.0), Color(0.28, 0.62, 0.72, 1.0))


static func make_slot_pressed_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.86, 0.93, 0.98, 1.0), Color(0.22, 0.55, 0.62, 1.0))


static func make_slot_disabled_stylebox() -> StyleBoxFlat:
	return make_flat_cell_stylebox(Color(0.8, 0.8, 0.82, 0.65), Color(0.58, 0.58, 0.6, 0.75))


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
	GameFonts.style_dialog_label(label, font_size, accent, false)
	return label


static func create_title_label(text: String, font_size: int = 30, allow_wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if allow_wrap else TextServer.AUTOWRAP_OFF
	GameFonts.style_dialog_label(label, font_size, TITLE_COLOR, false)
	return label


static func create_body_label(text: String, font_size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.style_dialog_label(label, font_size, BODY_COLOR, true)
	return label


static func create_muted_label(text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameFonts.style_dialog_label(label, font_size, MUTED_COLOR, true)
	return label


static func create_emphasis_label(text: String, font_size: int = 20, color: Color = Color(0.4, 1.0, 0.4)) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_contents = true
	GameFonts.style_dialog_label(label, font_size, color, true)
	return label


static func create_stat_label(text: String, font_size: int = 24, active: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var color := Color(1.0, 0.9, 0.3) if active else Color(0.5, 0.5, 0.5)
	GameFonts.style_dialog_label(label, font_size, color, false)
	return label
