extends GutTest


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
