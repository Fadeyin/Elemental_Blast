# Agent context
- Git: по завершении работы мержить назначенную ветку в `main` и пушить `origin/main` (предпочтение пользователя).
- Branch: cursor/-bc-acc2393e-c381-5f3d-be0a-1a91209495b1-57ff
- Prelevel boost purchase: rainbow 200 / bomb 100 / arrow 150 for +3 each; overlay uses ingame_booster_purchase_dialog with header «ПОКУПКА УСИЛЕНИЯ»; + button circular over icon slot.
- Level end: breach in column without heart sets `_defeat_pending_breach` → same defeat dialog as 0 hearts. Refill cost/units: `_breach_refill_unit_count()` (lost hearts in attack cols, else count of breach columns for columns without initial heart). After pay: `_column_hearts[x]=true` for all attack columns.
- Golden pass: daily calendar unlock (+1 tier per new calendar day after first recorded day), 30 tiers, two columns (free / premium), claim in overlay `golden_pass_dialog.gd`; circular FAB under top bar top-right. Premium: 499 coins in-game (stub). Rewards mix coins, in-game boosters, prelevel chips. Reward cells: title then square icon box (88px) with centered art; coin uses `textures/ui_gold_coin.png` (replace with user asset). Top bar coin uses same texture via `LevelManager.UI_GOLD_COIN_TEXTURE`.
