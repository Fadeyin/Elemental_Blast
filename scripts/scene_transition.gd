extends Node

# Глобальный fade-переход между сценами (меню ↔ бой).

const FADE_DURATION := 0.4
const SMOKE_FADE_DURATION := 0.05
const HEADLESS_FADE_DURATION := 0.01

var _overlay_layer: CanvasLayer
var _fade_rect: ColorRect
var _transitioning := false


func _ready() -> void:
	_build_overlay()


func is_busy() -> bool:
	return _transitioning


func change_scene_to(scene_path: String) -> int:
	if _transitioning:
		return ERR_BUSY
	_transitioning = true
	var fade_duration := _get_fade_duration()
	if fade_duration <= 0.0:
		var instant_err := get_tree().change_scene_to_file(scene_path)
		if instant_err != OK:
			push_error("SceneTransition: не удалось загрузить сцену %s (код %s)" % [scene_path, str(instant_err)])
		_transitioning = false
		_reset_overlay()
		return instant_err
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out := create_tween()
	fade_out.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 1.0), fade_duration)
	await fade_out.finished
	var change_err := get_tree().change_scene_to_file(scene_path)
	if change_err != OK:
		var fade_back := create_tween()
		fade_back.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_duration)
		await fade_back.finished
		_reset_overlay()
		_transitioning = false
		push_error("SceneTransition: не удалось загрузить сцену %s (код %s)" % [scene_path, str(change_err)])
		return change_err
	await get_tree().process_frame
	var fade_in := create_tween()
	fade_in.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_duration)
	await fade_in.finished
	_reset_overlay()
	_transitioning = false
	return OK


func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "SceneTransitionLayer"
	_overlay_layer.layer = 140
	add_child(_overlay_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay_layer.add_child(_fade_rect)


func _reset_overlay() -> void:
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_fade_duration() -> float:
	if WebSmokeTestBridge and WebSmokeTestBridge.is_active():
		return SMOKE_FADE_DURATION
	if OS.has_feature("headless"):
		return HEADLESS_FADE_DURATION
	return FADE_DURATION
