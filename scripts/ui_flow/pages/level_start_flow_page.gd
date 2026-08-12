class_name LevelStartFlowPage
extends EbModalFlowPage

signal start_gameplay(selected_boosts: Dictionary, mort_bonuses: Dictionary)

const DIALOG_SCRIPT := preload("res://scripts/level_start_dialog.gd")

var _dialog: Control = null
var _closing_via_gameplay := false


func _on_opened(_data: Variant = null) -> void:
	super._on_opened(_data)
	_dialog = Control.new()
	_dialog.name = "LevelStartDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.start_gameplay.connect(_on_dialog_start_gameplay)
	_dialog.tree_exiting.connect(_on_dialog_tree_exiting)
	_dialog.setup()


func _on_dialog_start_gameplay(boosts: Dictionary, bonuses: Dictionary) -> void:
	if _closing_via_gameplay:
		return
	_closing_via_gameplay = true
	start_gameplay.emit(boosts, bonuses)
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()


func _on_dialog_tree_exiting() -> void:
	if _closing_via_gameplay:
		return
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
