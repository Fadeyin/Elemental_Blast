extends GutTest

const LEVEL_END_FLOW_PAGE := preload("res://scripts/ui_flow/pages/level_end_flow_page.gd")
const MENU_TAB_FLOW_PAGE := preload("res://scripts/ui_flow/pages/menu_tab_flow_page.gd")
const BOOSTER_PURCHASE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/booster_purchase_flow_page.gd")
const SIMPLE_MESSAGE_FLOW_PAGE := preload("res://scripts/ui_flow/pages/simple_message_flow_page.gd")


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
