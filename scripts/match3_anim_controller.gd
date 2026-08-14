class_name Match3AnimController
extends RefCounted

## Контроллер анимаций match-3 / TD для game_board (immediate-mode отрисовка).
## Хранит состояние тиков и отдаёт события (попадания снарядов) в game_board.

var active_anims: Array = []
var projectiles: Array = []
var enemy_death_anims: Array = []
var enemy_move_anims: Array = []
var board_vfx: Array = []
var monster_shakes: Dictionary = {}
var portal_spawn_burst_vfx: Array = []


func clear_after_refill() -> void:
	enemy_move_anims.clear()
	enemy_death_anims.clear()
	projectiles.clear()
	monster_shakes.clear()


func clear_all() -> void:
	active_anims.clear()
	projectiles.clear()
	enemy_death_anims.clear()
	enemy_move_anims.clear()
	board_vfx.clear()
	monster_shakes.clear()
	portal_spawn_burst_vfx.clear()


func is_input_blocked() -> bool:
	return not active_anims.is_empty() or not projectiles.is_empty()


func is_combat_idle() -> bool:
	return projectiles.is_empty() and active_anims.is_empty() and enemy_death_anims.is_empty()


func has_active_chip_anims() -> bool:
	return not active_anims.is_empty()


static func chip_draw_scale(anim_type: String, progress: float) -> Vector2:
	match anim_type:
		"scale":
			var uniform_scale: float = chip_spawn_bounce_scale(progress)
			return Vector2(uniform_scale, uniform_scale)
		"pop":
			var shrink: float = 1.0 - ease(progress, 2.2)
			return Vector2(shrink, shrink)
		_:
			return chip_fall_squash_scale(progress)


static func chip_spawn_bounce_scale(progress: float) -> float:
	if progress <= 0.62:
		return ease(progress / 0.62, -0.45) * 1.2
	return lerpf(1.2, 1.0, ease((progress - 0.62) / 0.38, -1.2))


static func chip_fall_squash_scale(progress: float) -> Vector2:
	if progress < 0.8:
		return Vector2.ONE
	var landing_phase: float = (progress - 0.8) / 0.2
	var wobble: float = sin(landing_phase * PI) * 0.16
	return Vector2(1.0 + wobble, 1.0 - wobble * 0.9)


func get_shake_offset() -> Vector2:
	var shake_offset := Vector2.ZERO
	for vfx in board_vfx:
		if vfx.type != "shake":
			continue
		var k_shake: float = 1.0 - (float(vfx.t) / float(vfx.d))
		shake_offset += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * float(vfx.intensity) * k_shake
	return shake_offset


func prune_finished_enemy_move_anims() -> void:
	for move_index in range(enemy_move_anims.size() - 1, -1, -1):
		if enemy_move_anims[move_index].t >= enemy_move_anims[move_index].d:
			enemy_move_anims.remove_at(move_index)


func all_enemy_move_anims_done() -> bool:
	if enemy_move_anims.is_empty():
		return true
	for move_anim in enemy_move_anims:
		if move_anim.t < move_anim.d:
			return false
	return true


func tick(delta: float) -> Dictionary:
	var new_projectile_hits: Array = []
	_tick_board_vfx(delta)
	_tick_monster_shakes(delta)
	_tick_active_anims(delta)
	new_projectile_hits = _tick_projectiles(delta)
	_tick_enemy_death_anims(delta)
	_tick_enemy_move_anims(delta)
	_tick_portal_spawn_burst_vfx(delta)
	return {
		"projectile_hits": new_projectile_hits,
		"combat_idle": is_combat_idle(),
		"enemy_move_anims_done": all_enemy_move_anims_done(),
	}


func _tick_board_vfx(delta: float) -> void:
	for vfx_index in range(board_vfx.size() - 1, -1, -1):
		var vfx: Dictionary = board_vfx[vfx_index]
		vfx.t += delta
		if vfx.type == "particle" and vfx.has("gravity"):
			vfx.pos += vfx.vel * delta
			vfx.vel += vfx.gravity * delta
		if vfx.t >= vfx.d:
			board_vfx.remove_at(vfx_index)


func _tick_monster_shakes(delta: float) -> void:
	var shakes_to_remove: Array = []
	for monster_id in monster_shakes.keys():
		var shake_state: Dictionary = monster_shakes[monster_id]
		shake_state.t += delta
		if shake_state.t >= shake_state.d:
			shakes_to_remove.append(monster_id)
	for monster_id in shakes_to_remove:
		monster_shakes.erase(monster_id)


func _tick_active_anims(delta: float) -> void:
	for anim_index in range(active_anims.size() - 1, -1, -1):
		var anim: Dictionary = active_anims[anim_index]
		anim.t += delta
		var delay: float = float(anim.get("delay", 0.0))
		if anim.t - delay >= anim.d:
			active_anims.remove_at(anim_index)


func _tick_projectiles(delta: float) -> Array:
	var hits: Array = []
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[projectile_index]
		projectile.t += delta
		var elapsed: float = projectile.t - projectile.delay
		if elapsed >= projectile.d and not projectile.hit_applied:
			if projectile.has_target:
				hits.append({
					"x": int(projectile.x),
					"y": int(projectile.end_y),
				})
			projectile.hit_applied = true
		if elapsed >= projectile.d + 0.05:
			projectiles.remove_at(projectile_index)
	return hits


func _tick_enemy_death_anims(delta: float) -> void:
	for death_index in range(enemy_death_anims.size() - 1, -1, -1):
		enemy_death_anims[death_index].t += delta
		if enemy_death_anims[death_index].t >= enemy_death_anims[death_index].d:
			enemy_death_anims.remove_at(death_index)


func _tick_enemy_move_anims(delta: float) -> void:
	for move_index in range(enemy_move_anims.size() - 1, -1, -1):
		var move_anim: Dictionary = enemy_move_anims[move_index]
		move_anim.t += delta
		if move_anim.t >= move_anim.d:
			move_anim.t = move_anim.d


func _tick_portal_spawn_burst_vfx(delta: float) -> void:
	for burst_index in range(portal_spawn_burst_vfx.size() - 1, -1, -1):
		portal_spawn_burst_vfx[burst_index].t += delta
		if portal_spawn_burst_vfx[burst_index].t >= portal_spawn_burst_vfx[burst_index].d:
			portal_spawn_burst_vfx.remove_at(burst_index)
