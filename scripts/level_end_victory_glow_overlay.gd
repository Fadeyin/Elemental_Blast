# Пульсирующее градиентное свечение за окном победы.

extends Control

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var vp_size := size
	if vp_size.x < 32.0 or vp_size.y < 32.0:
		vp_size = get_viewport_rect().size
	var center := vp_size * 0.5
	var pulse := 0.5 + 0.5 * sin(_time * 1.35)
	var base_radius := minf(vp_size.x, vp_size.y) * 0.34
	var layers := [
		{"radius": base_radius * (1.0 + pulse * 0.18), "alpha": 0.16, "color": Color(1.0, 0.88, 0.35)},
		{"radius": base_radius * (0.82 + pulse * 0.12), "alpha": 0.12, "color": Color(1.0, 0.55, 0.25)},
		{"radius": base_radius * (0.62 + pulse * 0.08), "alpha": 0.1, "color": Color(0.45, 0.9, 1.0)},
	]
	for layer in layers:
		var col: Color = layer.color
		col.a = layer.alpha
		draw_circle(center, layer.radius, col)
