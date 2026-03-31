# Agent context
- Git: по завершении работы мержить назначенную ветку в `main` и пушить `origin/main` (предпочтение пользователя).
- Branch: cursor/-bc-acc2393e-c381-5f3d-be0a-1a91209495b1-57ff
- Prelevel boost purchase: rainbow 200 / bomb 100 / arrow 150 for +3 each; overlay uses ingame_booster_purchase_dialog with header «ПОКУПКА УСИЛЕНИЯ»; + button circular over icon slot.
- Level end: breach sets `_defeat_pending_breach`, stores attacker in `_pending_breach_monsters[column]`. After paid refill: restore hearts, `_increment_level_target` per pending, `_shift_all_enemies_toward_spawn(3)`, place pending monsters on heart row (or free cell in column). No freeze on refill.
- Golden pass: daily calendar unlock (+1 tier per new calendar day after first recorded day), 30 tiers, two columns (free / premium), claim in overlay `golden_pass_dialog.gd`; circular FAB under top bar top-right. Premium: 499 coins in-game (stub). Rewards mix coins, in-game boosters, prelevel chips. Reward cells: title then square icon box (88px) with centered art; coin uses `textures/ui_gold_coin.png` (replace with user asset). Top bar coin uses same texture via `LevelManager.UI_GOLD_COIN_TEXTURE`.
