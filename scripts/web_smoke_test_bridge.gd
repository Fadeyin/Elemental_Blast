extends Node

# Мост для E2E smoke-теста Web-сборки: ?smoke_test=1 в URL.
# Публикует фазу загрузки в window.__EB_SMOKE__ для Playwright.

var _active: bool = false


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var raw = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('smoke_test')")
	_active = str(raw) == "1"
	if not _active:
		return
	_install_js_hooks()
	report_phase("bridge_ready")


func is_active() -> bool:
	return _active


func report_phase(phase: String, detail: String = "") -> void:
	if not _active:
		return
	var safe_phase := JSON.stringify(phase)
	var safe_detail := JSON.stringify(detail)
	JavaScriptBridge.eval(
		"window.__EB_SMOKE__ = window.__EB_SMOKE__ || {errors:[]};"
		+ "window.__EB_SMOKE__.phase = %s;"
		+ "window.__EB_SMOKE__.detail = %s;"
		+ "window.__EB_SMOKE__.updatedAt = Date.now();" % [safe_phase, safe_detail]
	)


func report_error(message: String) -> void:
	if not _active:
		return
	var safe_message := JSON.stringify(message)
	JavaScriptBridge.eval("window.__EB_SMOKE__.errors.push(%s);" % safe_message)
	report_phase("error", message)


func _install_js_hooks() -> void:
	JavaScriptBridge.eval(
		"window.__EB_SMOKE__ = window.__EB_SMOKE__ || {};"
		+ "window.__EB_SMOKE__.errors = window.__EB_SMOKE__.errors || [];"
		+ "window.__EB_SMOKE__.consoleErrors = window.__EB_SMOKE__.consoleErrors || [];"
	)
