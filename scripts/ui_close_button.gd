#◦ Playrix ◦
# Текстурная кнопка закрытия для модальных окон.

extends RefCounted
class_name UiCloseButton

const TEX_UI_CLOSE := preload("res://textures/ui_close_button.png")
const DEFAULT_SIZE := 52.0
const PRESS_SCALE := Vector2(0.92, 0.92)

static func create(pressed_callback: Callable = Callable(), size: float = DEFAULT_SIZE) -> TextureButton:
	var btn := TextureButton.new()
	btn.name = "CloseButton"
	btn.texture_normal = TEX_UI_CLOSE
	btn.texture_pressed = TEX_UI_CLOSE
	btn.texture_hover = TEX_UI_CLOSE
	btn.ignore_texture_size = true
	btn.custom_minimum_size = Vector2(size, size)
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if pressed_callback.is_valid():
		btn.pressed.connect(pressed_callback)
	btn.button_down.connect(func():
		if is_instance_valid(btn):
			btn.scale = PRESS_SCALE
	)
	btn.button_up.connect(func():
		if is_instance_valid(btn):
			btn.scale = Vector2.ONE
	)
	return btn
