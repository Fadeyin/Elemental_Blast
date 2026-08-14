# Полноэкранное окно «Золотой пропуск»: две колонки наград, прокрутка, ежедневное открытие уровней.

extends Control

signal closed

const TEX_WATER_BALL := preload("res://textures/Booster_Water_Ball.png")
const TEX_FIRE_ARROW := preload("res://textures/Booster_Fire_Arrow.png")
const TEX_WHIRLWIND := preload("res://textures/Booster_Whirlwind.png")
const TEX_ROOTS := preload("res://textures/Booster_Roots.png")
const REWARD_ICON_BOX := 88

var _scroll_content: VBoxContainer
var _buy_pass_btn: UiTexturedButton
var _claim_all_bar: Control
var _claim_all_btn: UiTexturedButton
var _closing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup() -> void:
	_closing = false
	while get_child_count() > 0:
		var ch = get_child(0)
		remove_child(ch)
		ch.free()
	var dim := UiDialogStyles.create_dimmer()
	dim.gui_input.connect(_on_dim_gui_input)
	add_child(dim)
	var panel := UiDialogStyles.create_dialog_panel(UiDialogStyles.MEDIUM_DIALOG_WIDTH)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 16.0
	panel.offset_top = 88.0
	panel.offset_right = -16.0
	panel.offset_bottom = -104.0
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	var root_v := VBoxContainer.new()
	root_v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_v.add_theme_constant_override("separation", 10)
	panel.add_child(margin)
	margin.offset_bottom = -88.0
	margin.add_child(root_v)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	var title := UiDialogStyles.create_accent_title_label("ЗОЛОТОЙ ПРОПУСК", UiDialogStyles.ACCENT_COLOR, 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)
	var close_btn := UiCloseButton.create(_on_close_pressed)
	top_row.add_child(close_btn)
	root_v.add_child(top_row)
	var sub := UiDialogStyles.create_body_label("", 17)
	sub.name = "GoldenPassSubLabel"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.clip_contents = true
	root_v.add_child(sub)
	var buy_wrap := CenterContainer.new()
	buy_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_pass_btn = UiDialogStyles.create_primary_button("", UiDialogStyles.MEDIUM_DIALOG_WIDTH - 48.0)
	_buy_pass_btn.name = "GoldenPassBuyBtn"
	_buy_pass_btn.set_font_size(20)
	_buy_pass_btn.pressed.connect(_on_buy_pass_pressed)
	buy_wrap.add_child(_buy_pass_btn)
	root_v.add_child(buy_wrap)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 24
	scroll.follow_focus = false
	root_v.add_child(scroll)
	_scroll_content = VBoxContainer.new()
	_scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_scroll_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_scroll_content)
	_claim_all_bar = PanelContainer.new()
	_claim_all_bar.name = "GoldenPassClaimAllBar"
	_claim_all_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_claim_all_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_claim_all_bar.anchor_top = 1.0
	_claim_all_bar.anchor_bottom = 1.0
	_claim_all_bar.offset_left = 18.0
	_claim_all_bar.offset_right = -18.0
	_claim_all_bar.offset_top = -82.0
	_claim_all_bar.offset_bottom = -14.0
	_claim_all_bar.z_index = 6
	UiDialogStyles.apply_section(_claim_all_bar)
	var bar_margin := MarginContainer.new()
	bar_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_margin.add_theme_constant_override("margin_left", 12)
	bar_margin.add_theme_constant_override("margin_top", 8)
	bar_margin.add_theme_constant_override("margin_right", 12)
	bar_margin.add_theme_constant_override("margin_bottom", 8)
	_claim_all_bar.add_child(bar_margin)
	_claim_all_btn = UiDialogStyles.create_primary_button("ЗАБРАТЬ ВСЁ", UiDialogStyles.MEDIUM_DIALOG_WIDTH - 80.0)
	_claim_all_btn.name = "GoldenPassClaimAllBtn"
	_claim_all_btn.focus_mode = Control.FOCUS_NONE
	_claim_all_btn.set_font_size(18)
	_claim_all_btn.pressed.connect(_on_claim_all_pressed)
	bar_margin.add_child(_claim_all_btn)
	panel.add_child(_claim_all_bar)
	if LevelManager and not LevelManager.golden_pass_state_changed.is_connected(_rebuild_rows):
		LevelManager.golden_pass_state_changed.connect(_rebuild_rows)
	_rebuild_all()

func refresh_from_state() -> void:
	_rebuild_all()

func _exit_tree() -> void:
	if LevelManager and LevelManager.golden_pass_state_changed.is_connected(_rebuild_rows):
		LevelManager.golden_pass_state_changed.disconnect(_rebuild_rows)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()

func _on_close_pressed() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	queue_free()

func _on_buy_pass_pressed() -> void:
	if not LevelManager:
		return
	if LevelManager.is_golden_pass_purchased():
		return
	var price := LevelManager.GOLDEN_PASS_PREMIUM_PRICE_COINS
	if LevelManager.get_coins() < price:
		return
	LevelManager.purchase_golden_pass_with_coins()

func _rebuild_rows() -> void:
	_rebuild_all()

func _rebuild_all() -> void:
	if not is_instance_valid(_scroll_content) or not LevelManager:
		return
	for c in _scroll_content.get_children():
		c.queue_free()
	var sub_lbl: Label = find_child("GoldenPassSubLabel", true, false)
	if sub_lbl:
		var u := LevelManager.get_golden_pass_unlocked_tiers()
		var total := LevelManager.GOLDEN_PASS_TIER_COUNT
		sub_lbl.text = "Каждый календарный день открывается новый уровень ленты. Сейчас доступно: %d из %d." % [u, total]
	if is_instance_valid(_buy_pass_btn):
		if LevelManager.is_golden_pass_purchased():
			_buy_pass_btn.visible = false
		else:
			_buy_pass_btn.visible = true
			var p := LevelManager.GOLDEN_PASS_PREMIUM_PRICE_COINS
			_buy_pass_btn.set_text("Купить золотой пропуск за %d монет" % p)
			_buy_pass_btn.set_disabled(LevelManager.get_coins() < p)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 6)
	header.add_child(_header_cell("№", 36, true))
	header.add_child(_header_cell("Бесплатно", 120, false))
	header.add_child(_header_cell("Золотой пропуск", 120, false))
	_scroll_content.add_child(header)
	var n := LevelManager.GOLDEN_PASS_TIER_COUNT
	for tier in range(n):
		_scroll_content.add_child(_build_tier_row(tier))
	_update_claim_all_bar()

func _update_claim_all_bar() -> void:
	if not is_instance_valid(_claim_all_bar) or not is_instance_valid(_claim_all_btn) or not LevelManager:
		return
	var pending := LevelManager.get_golden_pass_pending_claim_count()
	var show_bar := pending > 0
	_claim_all_bar.visible = show_bar
	if show_bar:
		_claim_all_btn.set_text("ЗАБРАТЬ ВСЁ (%d)" % pending)

func _on_claim_all_pressed() -> void:
	if not LevelManager:
		return
	if LevelManager.get_golden_pass_pending_claim_count() <= 0:
		return
	var claimed := LevelManager.claim_all_golden_pass_rewards()
	if claimed > 0 and is_instance_valid(_claim_all_btn):
		GlobalTweens.color_flash(_claim_all_btn, Color(0.55, 1.0, 0.65), 0.22)

func _header_cell(txt: String, w: float, narrow: bool) -> Control:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color(1.0, 0.82, 0.4))
	if narrow:
		l.custom_minimum_size = Vector2(w, 0)
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _build_tier_row(tier_index: int) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	var num := Label.new()
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.text = str(tier_index + 1)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.custom_minimum_size = Vector2(36, 0)
	num.add_theme_font_size_override("font_size", 20)
	num.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	row.add_child(num)
	row.add_child(_build_reward_cell(tier_index, false))
	row.add_child(_build_reward_cell(tier_index, true))
	return row

func _build_reward_cell(tier_index: int, is_premium: bool) -> Control:
	var wrap := MarginContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := PanelContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := StyleBoxFlat.new()
	st.set_corner_radius_all(10)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	var unlocked := tier_index < LevelManager.get_golden_pass_unlocked_tiers()
	var claimed := false
	var can_claim := false
	if is_premium:
		claimed = LevelManager.is_golden_pass_premium_claimed(tier_index)
		can_claim = LevelManager.can_claim_golden_pass_premium(tier_index)
	else:
		claimed = LevelManager.is_golden_pass_free_claimed(tier_index)
		can_claim = LevelManager.can_claim_golden_pass_free(tier_index)
	if not unlocked:
		st.bg_color = Color(0.82, 0.84, 0.88, 0.75)
		st.border_color = Color(0.62, 0.65, 0.7, 1.0)
	elif claimed:
		st.bg_color = Color(0.86, 0.92, 0.86, 0.92)
		st.border_color = Color(0.45, 0.62, 0.45, 1.0)
	elif can_claim:
		st.bg_color = Color(0.96, 0.9, 0.78, 0.96)
		st.border_color = Color(0.78, 0.42, 0.12, 1.0)
	else:
		st.bg_color = Color(0.94, 0.9, 0.84, 0.92)
		st.border_color = Color(0.28, 0.62, 0.72, 1.0)
	inner.add_theme_stylebox_override("panel", st)
	wrap.add_child(inner)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	inner.add_child(vb)
	var rw: Dictionary = LevelManager.get_golden_pass_tier_reward(tier_index)
	var entry: Dictionary = {}
	if not rw.is_empty():
		entry = rw["premium"] if is_premium else rw["free"]
	if entry.is_empty():
		var empty_l := Label.new()
		empty_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty_l.text = "—"
		empty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(empty_l)
		return wrap
	var title_l := Label.new()
	title_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_l.text = _reward_title(entry)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_l.add_theme_font_size_override("font_size", 16)
	title_l.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	vb.add_child(title_l)
	var tex := _reward_texture(entry)
	var icon_bg := PanelContainer.new()
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_bg.custom_minimum_size = Vector2(REWARD_ICON_BOX, REWARD_ICON_BOX)
	icon_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_bg.add_theme_stylebox_override("panel", UiDialogStyles.make_flat_cell_stylebox(
		Color(0.9, 0.88, 0.82, 0.95),
		Color(0.28, 0.62, 0.72, 1.0)
	))
	var inner_icon := MarginContainer.new()
	inner_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_icon.add_theme_constant_override("margin_left", 6)
	inner_icon.add_theme_constant_override("margin_top", 6)
	inner_icon.add_theme_constant_override("margin_right", 6)
	inner_icon.add_theme_constant_override("margin_bottom", 6)
	icon_bg.add_child(inner_icon)
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_icon.add_child(icon_center)
	if tex:
		var tr := TextureRect.new()
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.texture = tex
		tr.custom_minimum_size = Vector2(REWARD_ICON_BOX - 12, REWARD_ICON_BOX - 12)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_center.add_child(tr)
	vb.add_child(icon_bg)
	var amt_l := Label.new()
	amt_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amt_l.text = _reward_amount_line(entry)
	amt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt_l.add_theme_font_size_override("font_size", 14)
	amt_l.add_theme_color_override("font_color", Color(0.88, 0.9, 0.94))
	vb.add_child(amt_l)
	if is_premium and not LevelManager.is_golden_pass_purchased():
		var lock_l := Label.new()
		lock_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_l.text = "Нужен пропуск"
		lock_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_l.add_theme_font_size_override("font_size", 14)
		lock_l.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35))
		vb.add_child(lock_l)
	elif not unlocked:
		var wait_l := Label.new()
		wait_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wait_l.text = "Скоро"
		wait_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wait_l.add_theme_font_size_override("font_size", 14)
		wait_l.add_theme_color_override("font_color", Color(0.65, 0.68, 0.75))
		vb.add_child(wait_l)
	elif claimed:
		var got := Label.new()
		got.mouse_filter = Control.MOUSE_FILTER_IGNORE
		got.text = "Получено"
		got.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		got.add_theme_font_size_override("font_size", 14)
		got.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
		vb.add_child(got)
	elif can_claim:
		var claim_wrap := CenterContainer.new()
		var claim := UiDialogStyles.create_primary_button("ЗАБРАТЬ", 108.0)
		claim.name = "GoldenPassClaimBtn_%d_%s" % [tier_index, "premium" if is_premium else "free"]
		claim.mouse_filter = Control.MOUSE_FILTER_STOP
		claim.set_font_size(14)
		claim.pressed.connect(_on_claim_pressed.bind(tier_index, is_premium))
		claim_wrap.add_child(claim)
		vb.add_child(claim_wrap)
	return wrap

func _on_claim_pressed(tier_index: int, is_premium: bool) -> void:
	if not LevelManager:
		return
	var claimed := false
	if is_premium:
		claimed = LevelManager.claim_golden_pass_premium(tier_index)
	else:
		claimed = LevelManager.claim_golden_pass_free(tier_index)
	if claimed:
		var btn_name := "GoldenPassClaimBtn_%d_%s" % [tier_index, "premium" if is_premium else "free"]
		var claim_btn := find_child(btn_name, true, false) as CanvasItem
		if claim_btn != null:
			GlobalTweens.color_flash(claim_btn, Color(0.55, 1.0, 0.65), 0.18)

func _reward_title(entry: Dictionary) -> String:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"coins":
			return "Золото"
		"booster":
			var bid: String = str(entry.get("id", "hammer"))
			var names := {
				"hammer": LevelManager.get_booster_display_name(LevelManager.BoosterType.HAMMER),
				"row_blast": LevelManager.get_booster_display_name(LevelManager.BoosterType.ROW_BLAST),
				"shuffle": LevelManager.get_booster_display_name(LevelManager.BoosterType.SHUFFLE),
				"freeze": LevelManager.get_booster_display_name(LevelManager.BoosterType.FREEZE)
			}
			return str(names.get(bid, bid))
		"bonus_chip":
			var cid: String = str(entry.get("id", "bomb"))
			var cnames := {"bomb": "Бомба", "arrow": "Стрела", "rainbow": "Шар"}
			return str(cnames.get(cid, cid))
		_:
			return "Награда"

func _reward_amount_line(entry: Dictionary) -> String:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"coins":
			return "%d монет" % int(entry.get("amount", 0))
		"booster", "bonus_chip":
			return "× %d" % int(entry.get("amount", 1))
		_:
			return ""

func _reward_texture(entry: Dictionary) -> Texture2D:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"coins":
			return LevelManager.UI_GOLD_COIN_TEXTURE if LevelManager else null
		"booster":
			var bid: String = str(entry.get("id", "hammer"))
			match bid:
				"hammer": return TEX_WATER_BALL
				"row_blast": return TEX_FIRE_ARROW
				"shuffle": return TEX_WHIRLWIND
				"freeze": return TEX_ROOTS
				_: return null
		"bonus_chip":
			var cid: String = str(entry.get("id", "bomb"))
			return LevelManager.get_prelevel_boost_texture(cid) if LevelManager else null
		_:
			return null

func _style_circle_btn(btn: Button, base: Color, hover_c: Color) -> void:
	var r := int(btn.custom_minimum_size.x / 2.0)
	var n := StyleBoxFlat.new()
	n.bg_color = base
	n.set_corner_radius_all(r)
	n.border_width_left = 2
	n.border_width_top = 2
	n.border_width_right = 2
	n.border_width_bottom = 2
	n.border_color = base.lightened(0.15)
	var h := n.duplicate()
	h.bg_color = hover_c
	var p := n.duplicate()
	p.bg_color = base.darkened(0.12)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color.WHITE)
