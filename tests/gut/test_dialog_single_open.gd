extends GutTest

const MAIN_MENU_SCENE := preload("res://scenes/main_menu.tscn")
const MENU_TAB_FLOW_PAGE := preload("res://scripts/ui_flow/pages/menu_tab_flow_page.gd")
const LEVEL_START_DIALOG_SCRIPT := preload("res://scripts/level_start_dialog.gd")
const LEVEL_END_DIALOG_SCRIPT := preload("res://scripts/level_end_dialog.gd")

const MAIN_MENU_TAB_NODES := {
	"shop": "ShopTab",
	"main": "MainTab",
	"ranks": "RanksTab",
}


func after_each() -> void:
	if UIFlow:
		UIFlow.clear_stack()


func before_each() -> void:
	DisplayServer.window_set_size(Vector2i(648, 1200))


func _spawn_level_start_dialog() -> Control:
	var dialog := Control.new()
	dialog.set_script(LEVEL_START_DIALOG_SCRIPT)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(dialog)
	dialog.setup()
	return dialog


func _spawn_level_end_dialog() -> Control:
	var dialog := Control.new()
	dialog.set_script(LEVEL_END_DIALOG_SCRIPT)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(dialog)
	return dialog


func _count_nodes_with_script(root: Node, script: Script) -> int:
	var count := 0
	for child in root.get_children():
		if child.get_script() == script:
			count += 1
	return count


func test_main_menu_level_start_dialog_opens_once() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	await wait_process_frames(5)
	menu._show_level_start_dialog(1)
	menu._show_level_start_dialog(1)
	menu._show_level_start_dialog(1)
	await wait_process_frames(10)
	assert_eq(UIFlow.stack_depth(), 2, "Повторные вызовы _show_level_start_dialog не должны открывать второй диалог")


func test_main_menu_tabs_use_uiflow() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	await wait_process_frames(12)
	assert_eq(UIFlow.stack_depth(), 1, "Базовый таб меню должен быть на стеке UIFlow")
	assert_not_null(UIFlow.get_page(MENU_TAB_FLOW_PAGE), "Активный таб должен быть MenuTabFlowPage")


func test_main_menu_switch_tab_updates_uiflow() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	await wait_process_frames(12)
	menu._switch_tab("shop")
	await wait_process_frames(12)
	assert_eq(UIFlow.stack_depth(), 1, "Смена таба не должна увеличивать глубину стека")
	assert_true(menu.shop_tab.visible, "Таб магазина должен быть видимым")
	assert_false(menu.main_tab.visible, "Главный таб должен быть скрыт")


func test_main_menu_switch_tab_ignores_same_tab() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	await wait_process_frames(12)
	menu._switch_tab("main")
	await wait_process_frames(5)
	menu._switch_tab("main")
	assert_true(menu.main_tab.visible, "Повторный _switch_tab(main) не должен скрывать главный таб")


func test_level_start_dialog_builds_expected_nodes() -> void:
	var dialog := _spawn_level_start_dialog()
	await wait_process_frames(3)
	assert_not_null(dialog.get_node_or_null("LevelStartDimmer"), "Должен быть затемняющий фон")
	assert_not_null(dialog.get_node_or_null("LevelStartPanel"), "Должна быть центральная панель")
	assert_not_null(
		dialog.find_child("PlayButton", true, false),
		"Должна быть кнопка «Играть»"
	)


func test_level_start_play_button_emits_start_gameplay_once() -> void:
	var dialog := Control.new()
	dialog.set_script(LEVEL_START_DIALOG_SCRIPT)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(dialog)
	var emit_count := [0]
	dialog.start_gameplay.connect(func(_boosts: Dictionary, _bonuses: Dictionary) -> void:
		emit_count[0] += 1
	)
	dialog.setup()
	await wait_process_frames(3)
	var play_btn := dialog.find_child("PlayButton", true, false) as Button
	assert_not_null(play_btn, "Кнопка «Играть» должна существовать")
	play_btn.pressed.emit()
	play_btn.pressed.emit()
	await wait_process_frames(1)
	assert_eq(emit_count[0], 1, "Двойное нажатие «Играть» не должно запускать уровень дважды")


func test_level_end_to_menu_emits_once() -> void:
	var dialog := _spawn_level_end_dialog()
	var emit_count := [0]
	dialog.to_menu_pressed.connect(func() -> void:
		emit_count[0] += 1
	)
	dialog.setup_victory(100, 50, 50, 2, 25)
	await wait_process_frames(3)
	dialog._on_to_menu()
	dialog._on_to_menu()
	assert_eq(emit_count[0], 1, "Повторный _on_to_menu не должен эмитить сигнал снова")


func test_level_end_refill_emits_once() -> void:
	var dialog := _spawn_level_end_dialog()
	var emit_count := [0]
	dialog.refill_lives_pressed.connect(func() -> void:
		emit_count[0] += 1
	)
	dialog.setup_defeat_no_lives(100, 500, 3, true)
	await wait_process_frames(3)
	dialog._on_refill_lives()
	dialog._on_refill_lives()
	assert_eq(emit_count[0], 1, "Повторный _on_refill_lives не должен эмитить сигнал снова")
