extends Node

# Глобальная кнопка «Скопировать логи» поверх всех сцен + регистрация логгера.

const _FILE_TAIL_MAX_CHARS := 65536

var _collector: GameLogCollector = null
var _copy_button: Button = null
var _toast_label: Label = null


func _init() -> void:
	_collector = GameLogCollector.new()
	OS.add_logger(_collector)


func _ready() -> void:
	_build_overlay()


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "LogCopyOverlayLayer"
	layer.layer = 120
	add_child(layer)
	var root := Control.new()
	root.name = "LogCopyOverlayRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_copy_button = Button.new()
	_copy_button.name = "CopyLogsButton"
	_copy_button.text = "Логи"
	_copy_button.tooltip_text = "Скопировать журнал сообщений в буфер обмена"
	_copy_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_copy_button.focus_mode = Control.FOCUS_NONE
	_copy_button.pressed.connect(_on_copy_logs_pressed)
	root.add_child(_copy_button)
	_copy_button.anchor_left = 1.0
	_copy_button.anchor_top = 0.0
	_copy_button.anchor_right = 1.0
	_copy_button.anchor_bottom = 0.0
	_copy_button.offset_left = -96.0
	_copy_button.offset_right = -8.0
	_copy_button.offset_top = 8.0
	_copy_button.offset_bottom = 44.0
	_copy_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_label = Label.new()
	_toast_label.name = "CopyLogsToast"
	_toast_label.visible = false
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_toast_label)
	_toast_label.anchor_left = 1.0
	_toast_label.anchor_top = 0.0
	_toast_label.anchor_right = 1.0
	_toast_label.anchor_bottom = 0.0
	_toast_label.offset_left = -240.0
	_toast_label.offset_right = -8.0
	_toast_label.offset_top = 46.0
	_toast_label.offset_bottom = 74.0
	_toast_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	_toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast_label.add_theme_constant_override("outline_size", 4)


func _on_copy_logs_pressed() -> void:
	var chunks: PackedStringArray = PackedStringArray()
	var ver := Engine.get_version_info()
	chunks.append("Elemental blast — журнал (%s.%s.%s)" % [ver.major, ver.minor, ver.patch])
	chunks.append("")
	var mem_lines := _collector.take_snapshot_lines()
	if mem_lines.is_empty():
		chunks.append("(сообщений в буфере пока нет)")
	else:
		for line in mem_lines:
			chunks.append(line)
	var file_tail := _read_engine_log_tail()
	if file_tail != "":
		chunks.append("")
		chunks.append("--- хвост файла godot.log ---")
		chunks.append(file_tail)
	var full_text := "\n".join(chunks)
	DisplayServer.clipboard_set(full_text)
	_show_toast("Скопировано")


func _read_engine_log_tail() -> String:
	var rel: String = str(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	var abs_path := ProjectSettings.globalize_path(rel)
	if not FileAccess.file_exists(abs_path):
		return ""
	var f := FileAccess.open(abs_path, FileAccess.READ)
	if f == null:
		return ""
	var content := f.get_as_text()
	f.close()
	if content.length() <= _FILE_TAIL_MAX_CHARS:
		return content
	return content.substr(content.length() - _FILE_TAIL_MAX_CHARS, _FILE_TAIL_MAX_CHARS)


func _show_toast(message: String) -> void:
	if not is_instance_valid(_toast_label):
		return
	_toast_label.text = message
	_toast_label.visible = true
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(1.6).timeout
	if is_instance_valid(_toast_label):
		_toast_label.visible = false
