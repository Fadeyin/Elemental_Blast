# Фоновые фейерверки за окном победы (одноразовый салют).

extends Control

const ROCKET_SPAWN_INTERVAL := 0.38
const MAX_ACTIVE_ROCKETS := 4
const MAX_TOTAL_ROCKETS := 9
const BURST_PARTICLE_COUNT := 24
const SALUTE_DURATION := 4.2

var _rockets: Array = []
var _bursts: Array = []
var _spawn_timer := 0.0
var _elapsed := 0.0
var _rockets_spawned := 0
var _finished := false
var _palette: Array[Color] = [
	Color(1.0, 0.92, 0.35),
	Color(1.0, 0.55, 0.45),
	Color(0.45, 0.9, 1.0),
	Color(0.55, 1.0, 0.55),
	Color(1.0, 0.7, 0.25),
	Color(0.9, 0.55, 1.0),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)
	_spawn_rocket()


func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	_spawn_timer += delta
	if _elapsed < SALUTE_DURATION and _spawn_timer >= ROCKET_SPAWN_INTERVAL:
		_spawn_timer = 0.0
		if _rockets.size() < MAX_ACTIVE_ROCKETS and _rockets_spawned < MAX_TOTAL_ROCKETS:
			_spawn_rocket()
	var any_alive := false
	for i in range(_rockets.size() - 1, -1, -1):
		var rocket: Dictionary = _rockets[i]
		rocket.t += delta
		rocket.y += rocket.vy * delta
		rocket.x += rocket.vx * delta
		if rocket.y <= rocket.target_y:
			_spawn_burst(rocket.x, rocket.y, rocket.color)
			_rockets.remove_at(i)
			continue
		any_alive = true
	for i in range(_bursts.size() - 1, -1, -1):
		var particle: Dictionary = _bursts[i]
		particle.t += delta
		if particle.t >= particle.life:
			_bursts.remove_at(i)
			continue
		any_alive = true
		particle.x += particle.vx * delta
		particle.y += particle.vy * delta
		particle.vy += particle.gravity * delta
		particle.vx *= 0.985
	if any_alive or _rockets.size() > 0:
		queue_redraw()
	elif _elapsed >= SALUTE_DURATION:
		_finished = true
		set_process(false)


func _spawn_rocket() -> void:
	var vp_size := size
	if vp_size.x < 32.0:
		vp_size = get_viewport_rect().size
	var color: Color = _palette[randi() % _palette.size()]
	_rockets.append({
		"x": randf_range(vp_size.x * 0.14, vp_size.x * 0.86),
		"y": vp_size.y + 12.0,
		"vx": randf_range(-18.0, 18.0),
		"vy": randf_range(-360.0, -280.0),
		"target_y": randf_range(vp_size.y * 0.14, vp_size.y * 0.46),
		"color": color,
		"t": 0.0,
	})
	_rockets_spawned += 1


func _spawn_burst(x: float, y: float, color: Color) -> void:
	for _i in range(BURST_PARTICLE_COUNT):
		var angle := randf() * TAU
		var speed := randf_range(90.0, 210.0)
		var spark := color.lightened(randf_range(-0.08, 0.12))
		_bursts.append({
			"x": x,
			"y": y,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"gravity": randf_range(120.0, 200.0),
			"radius": randf_range(2.0, 4.5),
			"color": spark,
			"life": randf_range(0.55, 1.05),
			"t": 0.0,
		})


func _draw() -> void:
	for rocket in _rockets:
		var col: Color = rocket.color
		col.a = 0.95
		draw_circle(Vector2(rocket.x, rocket.y), 3.0, col)
		draw_line(Vector2(rocket.x, rocket.y + 4.0), Vector2(rocket.x, rocket.y + 18.0), Color(col.r, col.g, col.b, 0.35), 2.0)
	for particle in _bursts:
		var life_ratio: float = particle.t / particle.life
		var alpha: float = 1.0 - life_ratio
		var col: Color = particle.color
		col.a = alpha
		draw_circle(Vector2(particle.x, particle.y), particle.radius, col)
