# Agent context
- Branch: cursor/-bc-cc6cfbcd-77df-5cf4-b917-bf56ee6c7d62-36f7
- Откат: сняты последние 4 merge-коммита по первому родителю (PR #22–#25: мешок золота и fix monster_tiers); HEAD на `71d9087` (merge PR #21).
- Prelevel boost purchase: rainbow 200 / bomb 100 / arrow 150 for +3 each; overlay uses ingame_booster_purchase_dialog with header «ПОКУПКА УСИЛЕНИЯ»; + button circular over icon slot.
- Level end: victory requires cleared targets/obstacles/queue/enemies; defeat only if not completed. Victory coin bonus from remaining bonus chips on player field (10 coins each). Defeat at 0 lives: optional refill all lives for 100 coins.
- Golden pass: daily calendar unlock (+1 tier per new calendar day after first recorded day), 30 tiers, two columns (free / premium), claim in overlay `golden_pass_dialog.gd`; circular FAB under top bar top-right. Premium: 499 coins in-game (stub). Rewards mix coins, in-game boosters, prelevel chips. Reward cells: title then square icon box (88px) with centered art; coin uses `textures/ui_gold_coin.png` (replace with user asset). Top bar coin uses same texture via `LevelManager.UI_GOLD_COIN_TEXTURE`.
