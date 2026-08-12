class_name UiDialogAnima
extends RefCounted

const PANEL_SCALE_FROM := 0.92
const DIMMER_FADE_DURATION := 0.28
const PANEL_FADE_DURATION := 0.35
const PANEL_SCALE_DURATION := 0.45


static func _ease_out_cubic() -> AnimaEase:
	var easing := AnimaEase.new()
	easing.kind = AnimaEase.Kind.EASE_OUT_CUBIC
	return easing


static func _ease_out_back() -> AnimaEase:
	var easing := AnimaEase.new()
	easing.kind = AnimaEase.Kind.EASE_OUT_BACK
	return easing


static func _ease_in_out_sine() -> AnimaEase:
	var easing := AnimaEase.new()
	easing.kind = AnimaEase.Kind.EASE_IN_OUT_SINE
	return easing


static func play_dimmer_enter(dimmer: CanvasItem) -> AnimaPlayback:
	dimmer.modulate.a = 0.0
	var motion := Anima.on(dimmer).opacity(1.0, DIMMER_FADE_DURATION).with_ease(_ease_out_cubic())
	return Anima.play(motion, dimmer)


static func play_panel_enter(panel: Control, scale_from: float = PANEL_SCALE_FROM) -> AnimaPlayback:
	panel.modulate.a = 0.0
	panel.scale = Vector2(scale_from, scale_from)
	var opacity_motion := Motion.to(NodePath("modulate:a"), 1.0).from(0.0).with_duration(PANEL_FADE_DURATION).with_ease(_ease_out_cubic())
	var scale_motion := Motion.to(NodePath("scale"), Vector2.ONE).from(Vector2(scale_from, scale_from)).with_duration(PANEL_SCALE_DURATION).with_ease(_ease_out_back()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	return Anima.play(Motion.parallel([opacity_motion, scale_motion]), panel)


static func play_dialog_open(dimmer: CanvasItem, panel: Control) -> void:
	play_dimmer_enter(dimmer)
	play_panel_enter(panel)


static func play_pop_in(control: Control, scale_from: float = 0.88, delay: float = 0.0) -> AnimaPlayback:
	control.modulate.a = 0.0
	control.scale = Vector2(scale_from, scale_from)
	var opacity_motion := Motion.to(NodePath("modulate:a"), 1.0).from(0.0).with_duration(0.32).with_delay(delay).with_ease(_ease_out_cubic())
	var scale_motion := Motion.to(NodePath("scale"), Vector2.ONE).from(Vector2(scale_from, scale_from)).with_duration(0.42).with_delay(delay).with_ease(_ease_out_back()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	return Anima.play(Motion.parallel([opacity_motion, scale_motion]), control)


static func play_victory_title(title: Control) -> AnimaPlayback:
	title.modulate.a = 0.0
	title.scale = Vector2(0.72, 0.72)
	var opacity_motion := Motion.to(NodePath("modulate:a"), 1.0).from(0.0).with_duration(0.22).with_ease(_ease_out_cubic())
	var scale_motion := Motion.to(NodePath("scale"), Vector2.ONE).from(Vector2(0.72, 0.72)).with_duration(0.55).with_ease(_ease_out_back()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	return Anima.play(Motion.parallel([opacity_motion, scale_motion]), title)


static func play_defeat_title(title: Control) -> AnimaPlayback:
	title.modulate.a = 0.0
	title.scale = Vector2(1.14, 1.14)
	var opacity_motion := Motion.to(NodePath("modulate:a"), 1.0).from(0.0).with_duration(0.18).with_ease(_ease_out_cubic())
	var scale_motion := Motion.to(NodePath("scale"), Vector2.ONE).from(Vector2(1.14, 1.14)).with_duration(0.38).with_ease(_ease_out_back()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	return Anima.play(Motion.parallel([opacity_motion, scale_motion]), title)


static func play_attention_pulse(target: Control, delay: float = 0.0) -> AnimaPlayback:
	var pulse_up := Motion.to(NodePath("scale"), Vector2(1.05, 1.05)).with_duration(0.28).with_delay(delay).with_ease(_ease_in_out_sine()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	var pulse_down := Motion.to(NodePath("scale"), Vector2.ONE).with_duration(0.28).with_ease(_ease_in_out_sine()).with_pivot(AnimaPropertyMotion.Pivot.CENTER)
	return Anima.play(Motion.sequence([pulse_up, pulse_down]), target)
