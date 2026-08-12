class_name Level1TutorialFlowPage
extends EbModalFlowPage

signal step_advanced
signal tutorial_finished

const OVERLAY_SCRIPT := preload("res://scripts/level1_tutorial_overlay.gd")

var _overlay: Control = null
var _closing := false


func _init() -> void:
	super._init()
	var fade := UIFlowFadeEffect.new()
	fade.duration = 0.0
	enter_effect = fade


func get_overlay() -> Control:
	return _overlay


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	_overlay = Control.new()
	_overlay.name = "Level1TutorialOverlayHost"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.set_script(OVERLAY_SCRIPT)
	add_child(_overlay)
	if typeof(data) == TYPE_DICTIONARY and data.has("board"):
		_overlay.set_board(data["board"])
	_overlay.step_advanced.connect(_on_overlay_step_advanced)
	_overlay.tutorial_finished.connect(_on_overlay_tutorial_finished)


func _on_overlay_step_advanced() -> void:
	step_advanced.emit()


func _on_overlay_tutorial_finished() -> void:
	if _closing:
		return
	_closing = true
	tutorial_finished.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
