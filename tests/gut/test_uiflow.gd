extends GutTest

const LEVEL_END_FLOW_PAGE := preload("res://scripts/ui_flow/pages/level_end_flow_page.gd")
const MENU_TAB_FLOW_PAGE := preload("res://scripts/ui_flow/pages/menu_tab_flow_page.gd")
const BOOSTER_PURCHASE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/booster_purchase_flow_page.gd")
const SIMPLE_MESSAGE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/simple_message_flow_page.gd")
const MORT_HELMET_RULES_FLOW_PAGE := preload("res://scripts/ui_flow/pages/mort_helmet_rules_flow_page.gd")
const MORT_HELMET_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/mort_helmet_tutorial_flow_page.gd")
const LEVEL1_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/level1_tutorial_flow_page.gd")
const INGAME_BOOSTER_TUTORIAL_FLOW_PAGE := preload("res://scripts/ui_flow/pages/ingame_booster_tutorial_flow_page.gd")


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
