# Agent context
- Git: по завершении работы мержить назначенную ветку в `main` и пушить `origin/main` (предпочтение пользователя).
- Branch: cursor/-bc-acc2393e-c381-5f3d-be0a-1a91209495b1-57ff
- Prelevel boost purchase: rainbow 200 / bomb 100 / arrow 150 for +3 each; overlay uses ingame_booster_purchase_dialog with header «ПОКУПКА УСИЛЕНИЯ»; + button circular over icon slot.
- Level end: victory requires cleared targets/obstacles/queue/enemies; defeat on monster breach past heart row. Enemy zone always `ENEMY_ROWS` (10); `_heart_row_y` = 9. Step onto last row is normal; next forward step from heart row triggers heart_kill or breach (not same turn as entering row).
- Golden pass: daily calendar unlock (+1 tier per new calendar day after first recorded day), 30 tiers, two columns (free / premium), claim in overlay `golden_pass_dialog.gd`; circular FAB under top bar top-right. Premium: 499 coins in-game (stub). Rewards mix coins, in-game boosters, prelevel chips. Reward cells: title then square icon box (88px) with centered art; coin uses `textures/ui_gold_coin.png` (replace with user asset). Top bar coin uses same texture via `LevelManager.UI_GOLD_COIN_TEXTURE`.
