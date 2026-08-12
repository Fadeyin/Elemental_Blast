class_name LevelEndFlowPage
extends EbModalFlowPage

signal to_menu_pressed
signal refill_lives_pressed

const DIALOG_SCRIPT := preload("res://scripts/level_end_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("LevelEndFlowPage: ожидался Dictionary в data")
		return
	_dialog = Control.new()
	_dialog.name = "LevelEndDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.to_menu_pressed.connect(_on_dialog_to_menu)
	_dialog.refill_lives_pressed.connect(_on_dialog_refill_lives)
	var mode := str(data.get("mode", "victory"))
	if mode == "defeat_no_lives":
		_dialog.setup_defeat_no_lives(
			int(data.get("refill_cost", 0)),
			int(data.get("player_coins", 0)),
			int(data.get("hearts_to_restore", 0)),
			bool(data.get("can_refill", false))
		)
	else:
		_dialog.setup_victory(
			int(data.get("total", 0)),
			int(data.get("base_reward", 0)),
			int(data.get("chips_bonus", 0)),
			int(data.get("bonus_chips_count", 0)),
			int(data.get("coins_per_bonus_chip", 0))
		)


func _on_dialog_to_menu() -> void:
	if _closing:
		return
	_closing = true
	to_menu_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()


func _on_dialog_refill_lives() -> void:
	if _closing:
		return
	_closing = true
	refill_lives_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
