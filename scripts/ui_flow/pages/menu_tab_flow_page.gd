class_name MenuTabFlowPage
extends UIFlowPage

const FADE_DURATION := 0.35

var _tab_root: Control = null


func _init() -> void:
	is_modal = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_created(data: Variant = null) -> void:
	super._on_created(data)
	if typeof(data) == TYPE_DICTIONARY:
		_tab_root = data.get("tab_root") as Control


func _on_opened(data: Variant = null) -> void:
	super._on_opened(data)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("MenuTabFlowPage: ожидался Dictionary в data")
		return
	var tab_root := data.get("tab_root") as Control
	if tab_root == null or not is_instance_valid(tab_root):
		push_error("MenuTabFlowPage: tab_root не задан")
		return
	_tab_root = tab_root
	var all_tabs: Array = data.get("all_tabs", [])
	for tab in all_tabs:
		var tab_control := tab as Control
		if tab_control == null or not is_instance_valid(tab_control):
			continue
		if tab_control != _tab_root:
			tab_control.visible = false
			tab_control.modulate.a = 1.0
	_tab_root.visible = true
	if bool(data.get("instant", false)):
		_tab_root.modulate.a = 1.0
	else:
		_fade_in_tab(_tab_root)


func _fade_in_tab(tab: Control) -> void:
	tab.modulate.a = 0.0
	var tween := tab.create_tween()
	tween.tween_property(tab, "modulate:a", 1.0, FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func get_tab_id(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return str(data.get("tab_id", ""))
