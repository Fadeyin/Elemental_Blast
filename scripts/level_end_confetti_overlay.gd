# Падающее конфетти поверх экрана победы (immediate-mode).

extends Control

const PARTICLE_COUNT := 52
const GRAVITY := 220.0

var _particles: Array = []
var _spawned := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 6
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	call_deferred("_spawn_particles")


func _spawn_particles() -> void:
	if _spawned:
		return
	_spawned = true
	var vp_size: Vector2 = size
	if vp_size.x < 32.0 or vp_size.y < 32.0:
		vp_size = get_viewport_rect().size
	var palette: Array[Color] = [
		Color(1.0, 0.92, 0.32),
		Color(1.0, 0.45, 0.52),
		Color(0.45, 0.82, 1.0),
		Color(0.55, 1.0, 0.55),
		Color(1.0, 0.62, 0.22),
		Color(0.85, 0.55, 1.0),
	]
	_particles.clear()
	for _i in range(PARTICLE_COUNT):
		_particles.append({
			"x": randf() * vp_size.x,
			"y": randf_range(-vp_size.y * 0.35, vp_size.y * 0.08),
			"vx": randf_range(-95.0, 95.0),
			"vy": randf_range(90.0, 260.0),
			"rot": randf() * TAU,
			"vr": randf_range(-7.0, 7.0),
			"w": randf_range(5.0, 11.0),
			"h": randf_range(3.0, 7.0),
			"color": palette[randi() % palette.size()],
			"life": randf_range(2.0, 3.4),
			"t": 0.0,
		})
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var any_alive := false
	for particle in _particles:
		particle.t += delta
		if particle.t >= particle.life:
			continue
		any_alive = true
		particle.x += particle.vx * delta
		particle.y += particle.vy * delta
		particle.vy += GRAVITY * delta
		particle.rot += particle.vr * delta
	if any_alive:
		queue_redraw()
	else:
		set_process(false)


func _draw() -> void:
	for particle in _particles:
		if particle.t >= particle.life:
			continue
		var life_ratio: float = particle.t / particle.life
		var alpha: float = 1.0
		if life_ratio > 0.72:
			alpha = 1.0 - (life_ratio - 0.72) / 0.28
		var col: Color = particle.color
		col.a = alpha
		var xf := Transform2D(particle.rot, Vector2(particle.x, particle.y))
		draw_set_transform_matrix(xf)
		draw_rect(Rect2(-particle.w * 0.5, -particle.h * 0.5, particle.w, particle.h), col)
	draw_set_transform_matrix(Transform2D.IDENTITY)
