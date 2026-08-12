class_name EbModalFlowPage
extends UIFlowPage

## Базовая модальная страница Elemental Blast с fade-переходом UIFlow.


func _init() -> void:
	is_modal = true
	exit_reverses_enter = true
	var fade := UIFlowFadeEffect.new()
	fade.duration = 0.22
	enter_effect = fade
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
