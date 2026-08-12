class_name GoldenPassFlowPage
extends EbModalFlowPage

const DIALOG_SCRIPT := preload("res://scripts/golden_pass_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(_data: Variant = null) -> void:
	super._on_opened(_data)
	if LevelManager:
		LevelManager.tick_golden_pass_daily_login()
	_dialog = Control.new()
	_dialog.name = "GoldenPassOverlay"
	_dialog.set_script(DIALOG_SCRIPT)
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dialog)
	_dialog.closed.connect(_on_dialog_closed)
	_dialog.setup()


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
