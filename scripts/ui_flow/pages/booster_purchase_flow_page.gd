class_name BoosterPurchaseFlowPage
extends EbModalFlowPage

signal purchase_pressed
signal closed_pressed

const DIALOG_SCRIPT := preload("res://scripts/ingame_booster_purchase_dialog.gd")

var _dialog: Control = null
var _closing := false


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("BoosterPurchaseFlowPage: ожидался Dictionary в data")
		return
	_dialog = Control.new()
	_dialog.name = "BoosterPurchaseDialogHost"
	_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)
	_dialog.purchase_pressed.connect(_on_dialog_purchase)
	_dialog.closed_pressed.connect(_on_dialog_closed)
	_dialog.setup(
		str(data.get("display_name", "Бустер")),
		data.get("icon_tex", null),
		int(data.get("cost", 0)),
		int(data.get("pack_qty", 1)),
		int(data.get("player_coins", 0)),
		bool(data.get("can_afford", false)),
		str(data.get("header_title", "БУСТЕР ЗАКОНЧИЛСЯ"))
	)


func _on_dialog_purchase() -> void:
	if _closing:
		return
	_closing = true
	purchase_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()


func _on_dialog_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
	if UIFlow.stack_depth() > 0:
		UIFlow.pop()
