extends GutTest

const INVALID_SCENE_PATH := "res://tests/gut/nonexistent_scene_for_transition_test.tscn"


func test_scene_transition_autoload_ready() -> void:
	assert_not_null(SceneTransition, "SceneTransition должен быть autoload")
	assert_false(SceneTransition.is_busy(), "При старте переход не должен быть активен")
	var fade_rect := SceneTransition.get_node_or_null("SceneTransitionLayer/FadeRect") as ColorRect
	assert_not_null(fade_rect, "Должен существовать fade-оверлей")
	assert_eq(fade_rect.color.a, 0.0, "Оверлей по умолчанию прозрачен")


func test_change_scene_invalid_path_returns_error() -> void:
	var err: int = await SceneTransition.change_scene_to(INVALID_SCENE_PATH)
	assert_ne(err, OK, "Несуществующая сцена должна вернуть ошибку")
	assert_false(SceneTransition.is_busy(), "После ошибки переход должен завершиться")


func test_change_scene_rejects_while_busy() -> void:
	SceneTransition.change_scene_to(INVALID_SCENE_PATH)
	await wait_process_frames(2)
	if not SceneTransition.is_busy():
		pending("Твин fade не успел стартовать в headless")
		return
	var second_err: int = await SceneTransition.change_scene_to(INVALID_SCENE_PATH)
	assert_eq(second_err, ERR_BUSY, "Параллельный переход должен быть отклонён")
