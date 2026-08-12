class_name MortHelmetTutorialFlowPage
extends EbModalFlowPage

signal closed_pressed

const DIALOG_SCRIPT := preload("res://scripts/mort_helmet_tutorial_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MortHelmetTutorialFlowPage: ожидался Dictionary в data")
		return
	var section_rect: Rect2 = data.get("section_rect", Rect2())
	var info_rect: Rect2 = data.get("info_rect", Rect2())
	_dialog = Control.new()
	_dialog.name = "MortHelmetTutorialDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.closed_pressed.connect(_on_dialog_closed)
	_dialog.setup(section_rect, info_rect)


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
