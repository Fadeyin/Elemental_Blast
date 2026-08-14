extends GutTest

const MATCH3_ANIM_CONTROLLER := preload("res://scripts/match3_anim_controller.gd")


func _make_controller() -> Match3AnimController:
	return MATCH3_ANIM_CONTROLLER.new()


func test_projectile_hit_emitted_once() -> void:
	var controller := _make_controller()
	controller.projectiles.append({
		"x": 2,
		"start_y": 12.0,
		"end_y": 1.0,
		"t": 0.0,
		"d": 0.25,
		"delay": 0.0,
		"color": Color.YELLOW,
		"hit_applied": false,
		"has_target": true,
	})
	var tick1: Dictionary = controller.tick(0.1)
	assert_eq(tick1.get("projectile_hits", []).size(), 0)
	var tick2: Dictionary = controller.tick(0.2)
	var hits: Array = tick2.get("projectile_hits", [])
	assert_eq(hits.size(), 1)
	assert_eq(int(hits[0].x), 2)
	assert_eq(int(hits[0].y), 1)
	var tick3: Dictionary = controller.tick(0.1)
	assert_eq(tick3.get("projectile_hits", []).size(), 0)


func test_active_anim_removed_after_duration() -> void:
	var controller := _make_controller()
	controller.active_anims.append({
		"x": 0,
		"start_y": 10,
		"end_y": 11,
		"color": 0,
		"t": 0.0,
		"d": 0.2,
		"delay": 0.0,
	})
	controller.tick(0.15)
	assert_eq(controller.active_anims.size(), 1)
	controller.tick(0.1)
	assert_eq(controller.active_anims.size(), 0)


func test_combat_idle_when_all_layers_empty() -> void:
	var controller := _make_controller()
	assert_true(controller.is_combat_idle())
	var tick_result: Dictionary = controller.tick(0.016)
	assert_true(bool(tick_result.get("combat_idle", false)))


func test_clear_after_refill_keeps_chip_anims() -> void:
	var controller := _make_controller()
	controller.active_anims.append({"x": 0, "t": 0.0, "d": 1.0})
	controller.projectiles.append({"x": 0, "t": 0.0, "d": 1.0, "delay": 0.0, "hit_applied": false})
	controller.enemy_move_anims.append({"t": 0.0, "d": 1.0})
	controller.clear_after_refill()
	assert_eq(controller.active_anims.size(), 1)
	assert_eq(controller.projectiles.size(), 0)
	assert_eq(controller.enemy_move_anims.size(), 0)


func test_chip_spawn_bounce_overshoots_then_settles() -> void:
	var mid_scale: float = Match3AnimController.chip_spawn_bounce_scale(0.5)
	var end_scale: float = Match3AnimController.chip_spawn_bounce_scale(1.0)
	assert_gt(mid_scale, 1.0)
	assert_almost_eq(end_scale, 1.0, 0.02)


func test_chip_fall_squash_at_landing() -> void:
	var mid: Vector2 = Match3AnimController.chip_fall_squash_scale(0.5)
	var land: Vector2 = Match3AnimController.chip_fall_squash_scale(0.92)
	assert_almost_eq(mid.x, 1.0, 0.01)
	assert_gt(land.x, 1.0)
	assert_lt(land.y, 1.0)
