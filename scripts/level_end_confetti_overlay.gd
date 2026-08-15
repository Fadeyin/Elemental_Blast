# Падающее конфетти поверх экрана победы (immediate-mode, непрерывный спавн).

extends Control

const INITIAL_PARTICLE_COUNT := 96
const MAX_PARTICLE_COUNT := 220
const SPAWN_INTERVAL := 0.11
const GRAVITY := 260.0
const WIND_STRENGTH := 42.0

var _particles: Array = []
var _spawned := false
var _spawn_timer := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 6
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	call_deferred("_spawn_initial_particles")


func _spawn_initial_particles() -> void:
	if _spawned:
		return
	_spawned = true
	for _i in range(INITIAL_PARTICLE_COUNT):
		_spawn_particle(true)
	set_process(true)
	queue_redraw()


func _spawn_particle(from_top: bool) -> void:
	if _particles.size() >= MAX_PARTICLE_COUNT:
		return
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
		Color(1.0, 0.78, 0.92),
	]
	var is_streamer := randf() < 0.22
	var particle_w_max := 14.0 if is_streamer else 10.0
	var particle_h_min := 3.0 if is_streamer else 4.0
	var particle_h_max := 6.0 if is_streamer else 8.0
	_particles.append({
		"x": randf() * vp_size.x,
		"y": randf_range(-vp_size.y * 0.45, vp_size.y * 0.05) if from_top else randf_range(-40.0, vp_size.y * 0.2),
		"vx": randf_range(-120.0, 120.0),
		"vy": randf_range(120.0, 320.0),
		"rot": randf() * TAU,
		"vr": randf_range(-10.0, 10.0),
		"w": randf_range(7.0, particle_w_max),
		"h": randf_range(particle_h_min, particle_h_max),
		"color": palette[randi() % palette.size()],
		"life": randf_range(2.4, 4.2),
		"t": 0.0,
		"sway_phase": randf() * TAU,
	})


func _process(delta: float) -> void:
	_time += delta
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_particle(true)
	var wind := sin(_time * 1.7) * WIND_STRENGTH
	for i in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[i]
		particle.t += delta
		if particle.t >= particle.life:
			_particles.remove_at(i)
			continue
		particle.x += (particle.vx + wind) * delta
		particle.y += particle.vy * delta
		particle.vy += GRAVITY * delta
		particle.rot += particle.vr * delta
		particle.x += sin(_time * 2.4 + particle.sway_phase) * 18.0 * delta
	queue_redraw()


func _draw() -> void:
	for particle in _particles:
		if particle.t >= particle.life:
			continue
		var life_ratio: float = particle.t / particle.life
		var alpha: float = 1.0
		if life_ratio > 0.7:
			alpha = 1.0 - (life_ratio - 0.7) / 0.3
		var col: Color = particle.color
		col.a = alpha
		var xf := Transform2D(particle.rot, Vector2(particle.x, particle.y))
		draw_set_transform_matrix(xf)
		draw_rect(Rect2(-particle.w * 0.5, -particle.h * 0.5, particle.w, particle.h), col)
	draw_set_transform_matrix(Transform2D.IDENTITY)
