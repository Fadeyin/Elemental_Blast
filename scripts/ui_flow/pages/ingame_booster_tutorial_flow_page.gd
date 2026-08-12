class_name IngameBoosterTutorialFlowPage
extends EbModalFlowPage

signal closed_pressed

const DIALOG_SCRIPT := preload("res://scripts/ingame_booster_tutorial_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("IngameBoosterTutorialFlowPage: ожидался Dictionary в data")
		return
	var highlight_rect: Rect2 = data.get("highlight_rect", Rect2())
	var hint_text: String = str(data.get("hint_text", ""))
	var tutorial_key: String = str(data.get("tutorial_key", ""))
	_mark_tutorial_shown(tutorial_key)
	_dialog = Control.new()
	_dialog.name = "IngameBoosterTutorialDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.closed_pressed.connect(_on_dialog_closed)
	await get_tree().process_frame
	if _dialog != null and is_instance_valid(_dialog):
		await _dialog.setup(highlight_rect, hint_text)


func _mark_tutorial_shown(tutorial_key: String) -> void:
	if LevelManager == null:
		return
	match tutorial_key:
		"hammer":
			LevelManager.mark_hammer_booster_tutorial_shown()
		"row_blast":
			LevelManager.mark_row_blast_booster_tutorial_shown()
		"shuffle":
			LevelManager.mark_shuffle_booster_tutorial_shown()
		"freeze":
			LevelManager.mark_freeze_booster_tutorial_shown()


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
