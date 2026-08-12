class_name MortHelmetRulesFlowPage
extends EbModalFlowPage

signal closed_pressed

const DIALOG_SCRIPT := preload("res://scripts/mort_helmet_rules_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(_data: Variant = null) -> void:
	super._on_opened(_data)
	_dialog = Control.new()
	_dialog.name = "MortHelmetRulesDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.closed_pressed.connect(_on_dialog_closed)
	_dialog.setup()


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
