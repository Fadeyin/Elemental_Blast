extends GutTest

var _saved_state: Dictionary = {}


func before_each() -> void:
	_saved_state = _capture_level_manager_state()
	_apply_default_level_manager_state()


func after_each() -> void:
	LevelManager.finish_editor_test()
	LevelManager.clear_editor_level_override()
	_restore_level_manager_state(_saved_state)


func _capture_level_manager_state() -> Dictionary:
	return {
		"player_coins": LevelManager.player_coins,
		"current_level": LevelManager.current_level,
		"max_unlocked_level": LevelManager.max_unlocked_level,
		"is_campaign_started": LevelManager.is_campaign_started,
		"mort_helmet_unlocked": LevelManager.mort_helmet_unlocked,
		"mort_helmet_level": LevelManager.mort_helmet_level,
		"win_streak": LevelManager.win_streak,
		"prelevel_boosts": LevelManager.prelevel_boosts.duplicate(),
		"golden_pass_purchased": LevelManager.golden_pass_purchased,
		"golden_pass_unlocked_tiers": LevelManager.golden_pass_unlocked_tiers,
		"golden_pass_free_claimed": LevelManager.golden_pass_free_claimed.duplicate(),
		"golden_pass_premium_claimed": LevelManager.golden_pass_premium_claimed.duplicate(),
		"golden_pass_last_calendar_date": LevelManager.golden_pass_last_calendar_date,
		"ingame_booster_unlock_bonus_claimed": LevelManager.ingame_booster_unlock_bonus_claimed.duplicate(),
		"booster_counts": {
			LevelManager.BoosterType.HAMMER: LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER),
			LevelManager.BoosterType.ROW_BLAST: LevelManager.get_booster_count(LevelManager.BoosterType.ROW_BLAST),
			LevelManager.BoosterType.SHUFFLE: LevelManager.get_booster_count(LevelManager.BoosterType.SHUFFLE),
			LevelManager.BoosterType.FREEZE: LevelManager.get_booster_count(LevelManager.BoosterType.FREEZE),
		},
	}


func _apply_default_level_manager_state() -> void:
	LevelManager.player_coins = LevelManager.INITIAL_COINS
	LevelManager.current_level = 1
	LevelManager.max_unlocked_level = 1
	LevelManager.is_campaign_started = false
	LevelManager.mort_helmet_unlocked = false
	LevelManager.mort_helmet_level = 0
	LevelManager.win_streak = 0
	LevelManager.prelevel_boosts = {"bomb": 3, "arrow": 3, "rainbow": 3}
	LevelManager.golden_pass_purchased = false
	LevelManager.golden_pass_unlocked_tiers = 1
	LevelManager.golden_pass_free_claimed = []
	LevelManager.golden_pass_premium_claimed = []
	LevelManager.golden_pass_last_calendar_date = ""
	LevelManager.ingame_booster_unlock_bonus_claimed = {
		LevelManager.BoosterType.HAMMER: false,
		LevelManager.BoosterType.ROW_BLAST: false,
		LevelManager.BoosterType.SHUFFLE: false,
		LevelManager.BoosterType.FREEZE: false,
	}
	LevelManager.booster_counts = {
		LevelManager.BoosterType.HAMMER: LevelManager.INITIAL_BOOSTERS,
		LevelManager.BoosterType.ROW_BLAST: LevelManager.INITIAL_BOOSTERS,
		LevelManager.BoosterType.SHUFFLE: LevelManager.INITIAL_BOOSTERS,
		LevelManager.BoosterType.FREEZE: LevelManager.INITIAL_BOOSTERS,
	}
	LevelManager._ensure_golden_pass_arrays()


func _restore_level_manager_state(state: Dictionary) -> void:
	LevelManager.player_coins = int(state.get("player_coins", LevelManager.INITIAL_COINS))
	LevelManager.current_level = int(state.get("current_level", 1))
	LevelManager.max_unlocked_level = int(state.get("max_unlocked_level", 1))
	LevelManager.is_campaign_started = bool(state.get("is_campaign_started", false))
	LevelManager.mort_helmet_unlocked = bool(state.get("mort_helmet_unlocked", false))
	LevelManager.mort_helmet_level = int(state.get("mort_helmet_level", 0))
	LevelManager.win_streak = int(state.get("win_streak", 0))
	LevelManager.prelevel_boosts = state.get("prelevel_boosts", {"bomb": 3, "arrow": 3, "rainbow": 3}).duplicate()
	LevelManager.golden_pass_purchased = bool(state.get("golden_pass_purchased", false))
	LevelManager.golden_pass_unlocked_tiers = int(state.get("golden_pass_unlocked_tiers", 1))
	LevelManager.golden_pass_free_claimed = state.get("golden_pass_free_claimed", []).duplicate()
	LevelManager.golden_pass_premium_claimed = state.get("golden_pass_premium_claimed", []).duplicate()
	LevelManager.golden_pass_last_calendar_date = str(state.get("golden_pass_last_calendar_date", ""))
	var bonus_claimed: Dictionary = state.get("ingame_booster_unlock_bonus_claimed", {})
	for bt in [LevelManager.BoosterType.HAMMER, LevelManager.BoosterType.ROW_BLAST, LevelManager.BoosterType.SHUFFLE, LevelManager.BoosterType.FREEZE]:
		LevelManager.ingame_booster_unlock_bonus_claimed[bt] = bool(bonus_claimed.get(bt, false))
	var counts: Dictionary = state.get("booster_counts", {})
	for bt in counts.keys():
		LevelManager.booster_counts[bt] = int(counts[bt])
	LevelManager._ensure_golden_pass_arrays()


func test_spend_coins_rejects_insufficient_balance() -> void:
	LevelManager.player_coins = 50
	var spent := LevelManager.spend_coins(100)
	assert_false(spent, "Нельзя потратить больше, чем есть")
	assert_eq(LevelManager.get_coins(), 50)


func test_spend_coins_deducts_balance() -> void:
	LevelManager.player_coins = 200
	var spent := LevelManager.spend_coins(75)
	assert_true(spent)
	assert_eq(LevelManager.get_coins(), 125)


func test_add_coins_increases_balance() -> void:
	LevelManager.player_coins = 100
	LevelManager.add_coins(40)
	assert_eq(LevelManager.get_coins(), 140)


func test_set_coins_cheat_sets_balance() -> void:
	LevelManager.player_coins = 100
	LevelManager.set_coins_cheat(999999)
	assert_eq(LevelManager.get_coins(), 999999)


func test_prelevel_boost_pack_costs() -> void:
	assert_eq(LevelManager.get_prelevel_boost_pack_cost("rainbow"), 200)
	assert_eq(LevelManager.get_prelevel_boost_pack_cost("bomb"), 100)
	assert_eq(LevelManager.get_prelevel_boost_pack_cost("arrow"), 150)


func test_purchase_prelevel_boosts_spends_coins_and_adds_stock() -> void:
	LevelManager.player_coins = 500
	var before := LevelManager.get_prelevel_boost_count("bomb")
	assert_true(LevelManager.purchase_prelevel_boosts("bomb"))
	assert_eq(LevelManager.get_coins(), 400)
	assert_eq(LevelManager.get_prelevel_boost_count("bomb"), before + LevelManager.PRELEVEL_BOOST_PACK_COUNT)


func test_use_prelevel_boost_decrements_stock() -> void:
	LevelManager.prelevel_boosts["arrow"] = 2
	assert_true(LevelManager.use_prelevel_boost("arrow"))
	assert_eq(LevelManager.get_prelevel_boost_count("arrow"), 1)
	assert_true(LevelManager.use_prelevel_boost("arrow"))
	assert_eq(LevelManager.get_prelevel_boost_count("arrow"), 0)
	assert_false(LevelManager.use_prelevel_boost("arrow"))


func test_mort_helmet_unlocks_after_level_10_win() -> void:
	LevelManager.current_level = 10
	LevelManager.mort_helmet_unlocked = false
	LevelManager.mark_level_completed()
	assert_true(LevelManager.mort_helmet_unlocked)
	assert_eq(LevelManager.get_win_streak(), 1)
	assert_eq(LevelManager.current_level, 11)


func test_mort_helmet_unlocked_requires_level_above_10() -> void:
	LevelManager.mort_helmet_unlocked = true
	LevelManager.current_level = 10
	assert_false(LevelManager.is_mort_helmet_unlocked())
	LevelManager.current_level = 11
	assert_true(LevelManager.is_mort_helmet_unlocked())


func test_mark_level_failed_resets_win_streak_when_unlocked() -> void:
	LevelManager.mort_helmet_unlocked = true
	LevelManager.current_level = 11
	LevelManager.win_streak = 2
	LevelManager.mort_helmet_level = 2
	LevelManager.mark_level_failed()
	assert_eq(LevelManager.get_win_streak(), 0)
	assert_eq(LevelManager.mort_helmet_level, 0)


func test_golden_pass_free_claim_grants_reward_once() -> void:
	LevelManager.golden_pass_unlocked_tiers = 1
	assert_true(LevelManager.can_claim_golden_pass_free(0))
	assert_true(LevelManager.claim_golden_pass_free(0))
	assert_false(LevelManager.can_claim_golden_pass_free(0))
	assert_false(LevelManager.claim_golden_pass_free(0))


func test_ingame_booster_unlock_levels() -> void:
	LevelManager.current_level = 5
	assert_false(LevelManager.is_ingame_booster_unlocked_at_current_level(LevelManager.BoosterType.HAMMER))
	LevelManager.current_level = 6
	assert_true(LevelManager.is_ingame_booster_unlocked_at_current_level(LevelManager.BoosterType.HAMMER))
	LevelManager.current_level = 13
	assert_true(LevelManager.is_ingame_booster_unlocked_at_current_level(LevelManager.BoosterType.SHUFFLE))


func test_claim_all_golden_pass_rewards_claims_available_tiers() -> void:
	LevelManager.player_coins = 100
	LevelManager.golden_pass_unlocked_tiers = 2
	LevelManager.golden_pass_purchased = false
	var claimed := LevelManager.claim_all_golden_pass_rewards()
	assert_eq(claimed, 2, "Должны забраться free-награды за тиры 0 и 1")
	assert_eq(LevelManager.get_coins(), 140, "40 + 60 монет с тиров 0 и 1")
	assert_false(LevelManager.can_claim_golden_pass_free(0))
	assert_false(LevelManager.can_claim_golden_pass_free(1))
	assert_eq(LevelManager.claim_all_golden_pass_rewards(), 0, "Повторный claim_all ничего не даёт")


func test_claim_all_includes_premium_when_purchased() -> void:
	LevelManager.golden_pass_unlocked_tiers = 1
	LevelManager.golden_pass_purchased = true
	LevelManager.player_coins = 0
	var claimed := LevelManager.claim_all_golden_pass_rewards()
	assert_eq(claimed, 2, "Free + premium за тир 0")
	assert_eq(LevelManager.get_coins(), 160, "40 free + 120 premium")


func test_editor_test_mode_loads_override_level_config() -> void:
	var temp_path := "user://gut_editor_level_test.json"
	var level_data := {
		"cols": 8,
		"rows": 16,
		"enemy_rows": 10,
		"moves": 7,
		"start_monsters": [],
		"scheduled_spawns": [],
		"boss_units": [],
		"obstacles": [],
		"seed": 99
	}
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	assert_not_null(file, "Не удалось создать временный JSON уровня")
	file.store_string(JSON.stringify(level_data))
	file.close()
	LevelManager.begin_editor_test(temp_path, 42)
	assert_true(LevelManager.is_editor_test_mode())
	assert_eq(LevelManager.current_level, 42)
	var cfg: Dictionary = LevelManager.get_level_config(1)
	assert_eq(int(cfg.get("moves", -1)), 7)
	LevelManager.finish_editor_test()
	assert_false(LevelManager.is_editor_test_mode())
	assert_true(LevelManager.get_level_config(1).has("moves"))


func test_golden_pass_daily_login_unlocks_next_tier() -> void:
	LevelManager.golden_pass_last_calendar_date = "2000-01-01"
	LevelManager.golden_pass_unlocked_tiers = 1
	LevelManager.tick_golden_pass_daily_login()
	assert_eq(LevelManager.get_golden_pass_unlocked_tiers(), 2)


func test_golden_pass_daily_login_same_day_is_noop() -> void:
	var today_key := "%04d-%02d-%02d" % [
		int(Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system())).year),
		int(Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system())).month),
		int(Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system())).day),
	]
	LevelManager.golden_pass_last_calendar_date = today_key
	LevelManager.golden_pass_unlocked_tiers = 3
	LevelManager.tick_golden_pass_daily_login()
	assert_eq(LevelManager.get_golden_pass_unlocked_tiers(), 3)


func test_purchase_golden_pass_with_coins() -> void:
	LevelManager.player_coins = LevelManager.GOLDEN_PASS_PREMIUM_PRICE_COINS
	assert_true(LevelManager.purchase_golden_pass_with_coins())
	assert_true(LevelManager.is_golden_pass_purchased())
	assert_eq(LevelManager.get_coins(), 0)
	assert_true(LevelManager.purchase_golden_pass_with_coins(), "Повторная покупка должна быть идемпотентной")


func test_buy_ingame_booster_spends_coins() -> void:
	LevelManager.current_level = 6
	LevelManager.player_coins = LevelManager.INGAME_BOOSTER_PACK_COST
	var before := LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER)
	assert_true(LevelManager.buy_booster(LevelManager.BoosterType.HAMMER))
	assert_eq(LevelManager.get_coins(), 0)
	assert_eq(
		LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER),
		before + LevelManager.get_ingame_booster_pack_quantity(LevelManager.BoosterType.HAMMER)
	)


func test_ensure_ingame_booster_unlock_bonus_once() -> void:
	LevelManager.current_level = 6
	LevelManager.ingame_booster_unlock_bonus_claimed[LevelManager.BoosterType.HAMMER] = false
	var before := LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER)
	LevelManager.ensure_ingame_booster_unlock_bonus_rewards()
	assert_eq(
		LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER),
		before + LevelManager.FREE_INGAME_BOOSTERS_ON_UNLOCK
	)
	LevelManager.ensure_ingame_booster_unlock_bonus_rewards()
	assert_eq(
		LevelManager.get_booster_count(LevelManager.BoosterType.HAMMER),
		before + LevelManager.FREE_INGAME_BOOSTERS_ON_UNLOCK
	)
