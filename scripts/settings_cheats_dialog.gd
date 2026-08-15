# Настройки с читами на монеты (для отладки / QA).

extends Control

signal closed_pressed

const CHEAT_AMOUNTS := [1000, 5000, 50000]

var _closing := false


func setup() -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var bg := UiDialogStyles.create_dimmer()
	add_child(bg)
	var center := UiDialogStyles.mount_dialog_center(self, "SettingsCheatsCenterHost", "SettingsCheatsCenter")
	var panel := UiDialogStyles.create_dialog_panel(UiDialogStyles.COMPACT_DIALOG_WIDTH)
	panel.name = "SettingsCheatsPanel"
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var header_row := HBoxContainer.new()
	var title_lbl := UiDialogStyles.create_title_label("Настройки", 28)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title_lbl)
	header_row.add_child(UiCloseButton.create(_emit_closed))
	vbox.add_child(header_row)
	var coins_lbl := UiDialogStyles.create_body_label(_coins_line(), 18)
	coins_lbl.name = "CoinsBalanceLabel"
	vbox.add_child(coins_lbl)
	var cheats_title := UiDialogStyles.create_title_label("Читы: монеты", 22)
	vbox.add_child(cheats_title)
	for amount in CHEAT_AMOUNTS:
		var row := CenterContainer.new()
		var btn := UiDialogStyles.create_primary_button("+%d" % amount, 240.0)
		btn.set_font_size(20)
		btn.pressed.connect(_on_add_coins_pressed.bind(amount))
		row.add_child(btn)
		vbox.add_child(row)
	var max_row := CenterContainer.new()
	var max_btn := UiDialogStyles.create_secondary_button("Установить 999 999", 240.0)
	max_btn.set_font_size(18)
	max_btn.pressed.connect(_on_set_max_coins_pressed)
	max_row.add_child(max_btn)
	vbox.add_child(max_row)
	var close_row := CenterContainer.new()
	var close_btn := UiDialogStyles.create_secondary_button("Закрыть", 220.0)
	close_btn.set_font_size(20)
	close_btn.pressed.connect(_emit_closed)
	close_row.add_child(close_btn)
	vbox.add_child(close_row)


func _coins_line() -> String:
	if LevelManager:
		return "Текущий баланс: %d монет" % LevelManager.get_coins()
	return "Текущий баланс: —"


func _refresh_coins_label() -> void:
	var lbl := find_child("CoinsBalanceLabel", true, false) as Label
	if lbl != null:
		lbl.text = _coins_line()


func _on_add_coins_pressed(amount: int) -> void:
	if not LevelManager:
		return
	LevelManager.add_coins(amount)
	_refresh_coins_label()


func _on_set_max_coins_pressed() -> void:
	if not LevelManager:
		return
	LevelManager.set_coins_cheat(999999)
	_refresh_coins_label()


func _emit_closed() -> void:
	if _closing:
		return
	_closing = true
	closed_pressed.emit()
