# Пульсирующее градиентное свечение за окном победы.

extends Control

const GLOW_TEXTURE_SIZE := 256

var _time := 0.0
var _warm_glow_texture: GradientTexture2D
var _cool_glow_texture: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	z_index = -1
	z_as_relative = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_warm_glow_texture = _create_radial_glow_texture(
		[
			Color(1.0, 0.94, 0.5, 0.42),
			Color(1.0, 0.72, 0.28, 0.22),
			Color(1.0, 0.55, 0.2, 0.08),
			Color(1.0, 0.55, 0.2, 0.0),
		],
		[0.0, 0.22, 0.62, 1.0]
	)
	_cool_glow_texture = _create_radial_glow_texture(
		[
			Color(0.55, 0.92, 1.0, 0.28),
			Color(0.45, 0.78, 1.0, 0.12),
			Color(0.35, 0.62, 0.95, 0.04),
			Color(0.35, 0.62, 0.95, 0.0),
		],
		[0.0, 0.28, 0.7, 1.0]
	)
	set_process(true)


func _create_radial_glow_texture(colors: Array, offsets: Array) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = GLOW_TEXTURE_SIZE
	texture.height = GLOW_TEXTURE_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _warm_glow_texture == null or _cool_glow_texture == null:
		return
	var draw_size := size
	if draw_size.x < 8.0 or draw_size.y < 8.0:
		draw_size = get_viewport_rect().size
	var center := draw_size * 0.5
	var pulse := 0.5 + 0.5 * sin(_time * 1.35)
	var breathe := 0.5 + 0.5 * sin(_time * 0.85 + 1.2)
	var warm_radius := maxf(draw_size.x, draw_size.y) * (0.95 + pulse * 0.14)
	var cool_radius := warm_radius * (0.78 + breathe * 0.08)
	var warm_alpha := 0.78 + pulse * 0.22
	var cool_alpha := 0.55 + breathe * 0.2
	_draw_glow_layer(center, warm_radius, _warm_glow_texture, warm_alpha)
	_draw_glow_layer(center, cool_radius, _cool_glow_texture, cool_alpha * 0.85)


func _draw_glow_layer(center: Vector2, radius: float, texture: GradientTexture2D, alpha: float) -> void:
	var half := Vector2(radius, radius)
	var rect := Rect2(center - half, half * 2.0)
	draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))
