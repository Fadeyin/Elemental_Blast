class_name SimpleMessageFlowPage
extends EbModalFlowPage

signal closed_pressed

const DIALOG_SCRIPT := preload("res://scripts/simple_message_dialog.gd")

var _dialog: Control = null
var _closing := false
var _ok_action: String = "close"


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SimpleMessageFlowPage: ожидался Dictionary в data")
		return
	_ok_action = str(data.get("ok_action", "close"))
	_dialog = Control.new()
	_dialog.name = "SimpleMessageDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.closed_pressed.connect(_on_dialog_closed)
	_dialog.setup(
		str(data.get("title", "")),
		str(data.get("body", "")),
		str(data.get("ok_text", "Закрыть"))
	)
	if _dialog.get_child_count() >= 2:
		UiDialogAnima.play_dialog_open(_dialog.get_child(0), _dialog.get_child(1) as Control)


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
	if _ok_action == "scene_to_menu":
		if UIFlow.stack_depth() > 0:
			UIFlow.pop()
		SceneTransition.change_scene_to("res://scenes/main_menu.tscn")
		return
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
