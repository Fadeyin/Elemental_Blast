extends GutTest

const LEVEL_END_FLOW_PAGE := preload("res://scripts/ui_flow/pages/level_end_flow_page.gd")
const MENU_TAB_FLOW_PAGE := preload("res://scripts/ui_flow/pages/menu_tab_flow_page.gd")
const BOOSTER_PURCHASE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/booster_purchase_flow_page.gd")
const SIMPLE_MESSAGE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/simple_message_flow_page.gd")
const MORT_HELMET_RULES_FLOW_PAGE := preload("res://scripts/ui_flow/pages/mort_helmet_rules_flow_page.gd")
const MORT_HELMET_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/mort_helmet_tutorial_flow_page.gd")
const LEVEL1_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/level1_tutorial_flow_page.gd")
const INGAME_BOOSTER_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/ingame_booster_tutorial_flow_page.gd")


func after_each() -> void:
	if UIFlow:
		UIFlow.clear_stack()


func test_uiflow_autoloads_ready() -> void:
	assert_not_null(UIFlow, "UIFlow должен быть autoload")
	assert_not_null(UIFlowUI, "UIFlowUI должен быть autoload")
	assert_not_null(UIFlowUI.Toast, "UIFlowUI.Toast должен быть доступен")
	assert_true(UIFlow.has_method("push_instance"))


func test_level_start_flow_page_can_be_created() -> void:
	var page := LevelStartFlowPage.new()
	add_child_autofree(page)
	assert_true(page is UIFlowPage)
	assert_true(page.is_modal)


func test_level_end_flow_page_can_be_created() -> void:
	var page = LEVEL_END_FLOW_PAGE.new()
	add_child_autofree(page)
	assert_true(page is UIFlowPage)
	assert_true(page.is_modal)


func test_menu_tab_flow_page_can_be_created() -> void:
	var page = MENU_TAB_FLOW_PAGE.new()
	add_child_autofree(page)
	assert_true(page is UIFlowPage)
	assert_false(page.is_modal)


func test_booster_purchase_flow_page_can_be_created() -> void:
	var page = BOOSTER_PURCHASE_FLOW_PAGE.new()
	add_child_autofree(page)
	assert_true(page is UIFlowPage)
	assert_true(page.is_modal)


func test_booster_purchase_flow_page_setup() -> void:
	var page = BOOSTER_PURCHASE_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"display_name": "Молот",
		"icon_tex": null,
		"cost": 200,
		"pack_qty": 3,
		"player_coins": 500,
		"can_afford": true,
		"header_title": "БУСТЕР ЗАКОНЧИЛСЯ",
	})
	await wait_process_frames(3)
	assert_not_null(page.find_child("BoosterPurchaseDialogHost", true, false))
	assert_not_null(page.find_child("BoosterShopPanel", true, false))


func test_simple_message_flow_page_setup() -> void:
	var page = SIMPLE_MESSAGE_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"title": "Настройки",
		"body": "Тестовое сообщение",
		"ok_text": "Закрыть",
	})
	await wait_process_frames(3)
	assert_not_null(page.find_child("SimpleMessageDialogHost", true, false))
	assert_not_null(page.find_child("SimpleMessagePanel", true, false))


func test_simple_message_flow_page_scene_to_menu_action() -> void:
	var page = SIMPLE_MESSAGE_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"title": "Ошибка",
		"body": "Тест",
		"ok_text": "В меню",
		"ok_action": "scene_to_menu",
	})
	await wait_process_frames(2)
	assert_not_null(page.find_child("SimpleMessageDialogHost", true, false))


func test_mort_helmet_rules_flow_page_setup() -> void:
	var page = MORT_HELMET_RULES_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({})
	await wait_process_frames(3)
	assert_not_null(page.find_child("MortHelmetRulesDialogHost", true, false))
	assert_not_null(page.find_child("MortHelmetRulesPanel", true, false))


func test_mort_helmet_tutorial_flow_page_setup() -> void:
	var page = MORT_HELMET_TUTORIAL_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"section_rect": Rect2(40, 200, 560, 120),
		"info_rect": Rect2(520, 210, 40, 40),
	})
	await wait_process_frames(3)
	assert_not_null(page.find_child("MortHelmetTutorialDialogHost", true, false))


func test_level1_tutorial_flow_page_setup() -> void:
	var page = LEVEL1_TUTORIAL_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({"board": null})
	await wait_process_frames(3)
	assert_not_null(page.find_child("Level1TutorialOverlayHost", true, false))
	assert_not_null(page.get_overlay())


func test_ingame_booster_tutorial_flow_page_setup() -> void:
	var page = INGAME_BOOSTER_TUTORIAL_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"highlight_rect": Rect2(40, 900, 112, 112),
		"hint_text": "Тестовая подсказка бустера",
		"tutorial_key": "hammer",
	})
	await wait_process_frames(5)
	assert_not_null(page.find_child("IngameBoosterTutorialDialogHost", true, false))


func test_level_end_flow_page_victory_setup() -> void:
	var page = LEVEL_END_FLOW_PAGE.new()
	add_child_autofree(page)
	page._on_opened({
		"mode": "victory",
		"total": 100,
		"base_reward": 50,
		"chips_bonus": 50,
		"bonus_chips_count": 2,
		"coins_per_bonus_chip": 25,
	})
	await wait_process_frames(3)
	assert_not_null(page.find_child("LevelEndDialogHost", true, false))
	assert_not_null(page.find_child("LevelEndDimmer", true, false))


func test_level_end_dialog_victory_confetti() -> void:
	var dialog := Control.new()
	dialog.set_script(load("res://scripts/level_end_dialog.gd"))
	add_child_autofree(dialog)
	dialog.setup_victory(100, 50, 50, 2, 25)
	await wait_process_frames(3)
	assert_not_null(dialog.find_child("LevelEndConfetti", true, false))


func test_ui_dialog_styles_panel_texture() -> void:
	var style := UiDialogStyles.make_panel_stylebox()
	assert_not_null(style, "Панель диалога должна использовать текстуру")
	assert_not_null(style.texture, "StyleBoxTexture должен ссылаться на ui_main_menu_toolbar_bg")
	assert_gte(style.texture_margin_left, 100, "9-slice left margin должен защищать скругление")
	assert_gte(style.texture_margin_top, 40, "9-slice top margin должен защищать рамку")
	assert_eq(style.axis_stretch_horizontal, StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH)


func test_clear_stack_unblocks_level_end_after_menu_tab() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(host)
	UIFlow.set_ui_root(host)
	UIFlow.clear_stack()
	var tab_stub := Control.new()
	host.add_child(tab_stub)
	var menu_page = MENU_TAB_FLOW_PAGE.new()
	UIFlow.push_instance(menu_page, {
		"tab_id": "main",
		"tab_root": tab_stub,
		"all_tabs": [tab_stub],
		"instant": true,
	})
	assert_eq(UIFlow.stack_depth(), 1, "После входа в меню на стеке должен быть таб")
	UIFlow.clear_stack()
	assert_eq(UIFlow.stack_depth(), 0, "clear_stack перед боем должен сбрасывать MenuTabFlowPage")
	var end_page = LEVEL_END_FLOW_PAGE.new()
	var pushed := UIFlow.push_instance(end_page, {
		"mode": "victory",
		"total": 100,
		"base_reward": 50,
		"chips_bonus": 0,
		"bonus_chips_count": 0,
		"coins_per_bonus_chip": 25,
	})
	assert_not_null(pushed, "LevelEndFlowPage должен открываться после clear_stack")
	assert_eq(UIFlow.stack_depth(), 1)
	UIFlow.clear_stack()
