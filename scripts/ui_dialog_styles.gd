extends RefCounted
class_name UiDialogStyles

const PANEL_TEXTURE := "res://textures/ui_main_menu_toolbar_bg.png"
const SECTION_TEXTURE := "res://textures/ingame_booster_slot_bg.png"
const PRIMARY_BUTTON_TEXTURE := "res://textures/ui_main_menu_play_button.png"
const SECONDARY_BUTTON_TEXTURE := "res://textures/ui_bottom_nav_bg.png"
const SMALL_BUTTON_TEXTURE := "res://textures/ui_buy_coins_button.png"
const ROUND_BUTTON_TEXTURE := "res://textures/ui_menu_round_button_bg.png"

const PANEL_MARGIN := 18
const SECTION_MARGIN := 10
const BUTTON_CONTENT_MARGIN := 14

const TITLE_COLOR := Color(0.18, 0.12, 0.08, 1.0)
const BODY_COLOR := Color(0.28, 0.2, 0.14, 1.0)
const MUTED_COLOR := Color(0.42, 0.32, 0.24, 1.0)
const ACCENT_COLOR := Color(0.78, 0.42, 0.12, 1.0)
const PRIMARY_TEXT_COLOR := Color(0.98, 0.96, 0.9, 1.0)
const SECONDARY_TEXT_COLOR := Color(0.22, 0.14, 0.08, 1.0)


static func create_dimmer() -> ColorRect:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.55)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	return dimmer


static func make_panel_stylebox() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(PANEL_TEXTURE)
	style.texture_margin_left = PANEL_MARGIN
	style.texture_margin_top = PANEL_MARGIN
	style.texture_margin_right = PANEL_MARGIN
	style.texture_margin_bottom = PANEL_MARGIN
	style.content_margin_left = PANEL_MARGIN + 4
	style.content_margin_top = PANEL_MARGIN + 2
	style.content_margin_right = PANEL_MARGIN + 4
	style.content_margin_bottom = PANEL_MARGIN + 4
	return style


static func make_section_stylebox() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(SECTION_TEXTURE)
	style.texture_margin_left = SECTION_MARGIN
	style.texture_margin_top = SECTION_MARGIN
	style.texture_margin_right = SECTION_MARGIN
	style.texture_margin_bottom = SECTION_MARGIN
	style.content_margin_left = SECTION_MARGIN + 2
	style.content_margin_top = SECTION_MARGIN + 2
	style.content_margin_right = SECTION_MARGIN + 2
	style.content_margin_bottom = SECTION_MARGIN + 2
	return style


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
	style.modulate_color = Color(0.82, 0.92, 1.0, 1.0)
	return style


static func make_slot_disabled_stylebox() -> StyleBoxTexture:
	var style := make_section_stylebox()
	style.modulate_color = Color(0.55, 0.55, 0.58, 0.75)
	return style


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


static func _make_button_stylebox(texture_path: String, content_margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(texture_path)
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin - 2
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin + 2
	return style


static func create_primary_button(text: String, min_height: float = 52.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, min_height)
	button.add_theme_stylebox_override("normal", _make_button_stylebox(PRIMARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(PRIMARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(PRIMARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN + 2))
	button.add_theme_stylebox_override("focus", _make_button_stylebox(PRIMARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
	button.add_theme_color_override("font_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", PRIMARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", PRIMARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 22)
	return button


static func create_secondary_button(text: String, min_height: float = 48.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, min_height)
	button.add_theme_stylebox_override("normal", _make_button_stylebox(SECONDARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(SECONDARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(SECONDARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN + 2))
	button.add_theme_stylebox_override("focus", _make_button_stylebox(SECONDARY_BUTTON_TEXTURE, BUTTON_CONTENT_MARGIN))
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
	var margin := 8
	button.add_theme_stylebox_override("normal", _make_button_stylebox(SMALL_BUTTON_TEXTURE, margin))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(SMALL_BUTTON_TEXTURE, margin))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(SMALL_BUTTON_TEXTURE, margin + 1))
	button.add_theme_stylebox_override("focus", _make_button_stylebox(SMALL_BUTTON_TEXTURE, margin))
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
	var margin := 10
	button.add_theme_stylebox_override("normal", _make_button_stylebox(ROUND_BUTTON_TEXTURE, margin))
	button.add_theme_stylebox_override("hover", _make_button_stylebox(ROUND_BUTTON_TEXTURE, margin))
	button.add_theme_stylebox_override("pressed", _make_button_stylebox(ROUND_BUTTON_TEXTURE, margin + 1))
	button.add_theme_stylebox_override("focus", _make_button_stylebox(ROUND_BUTTON_TEXTURE, margin))
	button.add_theme_color_override("font_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", SECONDARY_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", SECONDARY_TEXT_COLOR)
	button.add_theme_font_size_override("font_size", 18)
	return button
