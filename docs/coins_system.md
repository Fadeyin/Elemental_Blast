# Система монет и покупка ходов

## Описание

Внутриигровая валюта (монеты), которая используется для покупки дополнительных ходов когда они заканчиваются на уровне.

## Основные компоненты

### 1. Монеты игрока

#### Характеристики
- **Начальный баланс**: 500 монет
- **Хранение**: ConfigFile (`user://progress.cfg`)
- **Отображение**: Верхняя панель UI (после ходов)
- **Цвет**: Золотистый (RGB: 1.0, 0.9, 0.3)

#### Функции в LevelManager

```gdscript
const INITIAL_COINS := 500

var player_coins: int = INITIAL_COINS

signal coins_changed(new_amount: int)

func add_coins(amount: int):
    # Добавить монеты и сохранить
    player_coins += amount
    _save_progress()
    emit_signal("coins_changed", player_coins)

func spend_coins(amount: int) -> bool:
    # Потратить монеты (если достаточно)
    if player_coins >= amount:
        player_coins -= amount
        _save_progress()
        emit_signal("coins_changed", player_coins)
        return true
    return false

func get_coins() -> int:
    # Получить текущий баланс
    return player_coins
```

### 2. Покупка ходов

#### Константы

```gdscript
const MOVES_PURCHASE_BASE_COST := 100      # Базовая цена
const MOVES_PURCHASE_INCREMENT := 150       # Прирост за каждую покупку
const MOVES_PER_PURCHASE := 5               # Ходов за покупку

var _moves_purchase_count: int = 0          # Счётчик покупок на уровне
```

#### Формула цены

```gdscript
func _get_moves_purchase_cost() -> int:
    return MOVES_PURCHASE_BASE_COST + (_moves_purchase_count * MOVES_PURCHASE_INCREMENT)
```

**Примеры цен**:
- 1-я покупка: 100 монет
- 2-я покупка: 250 монет (100 + 150)
- 3-я покупка: 400 монет (100 + 150×2)
- 4-я покупка: 550 монет (100 + 150×3)

#### Процесс покупки

1. **Триггер**: Ходы закончились (`_moves_left == 0`), но жизни > 0
2. **Диалог**: Показывается окно с предложением покупки
3. **Проверка**: Достаточно ли монет у игрока
4. **Покупка**: 
   - Списываются монеты
   - Добавляется 5 ходов
   - Счётчик покупок увеличивается
   - UI обновляется
5. **Отказ**: Возврат в главное меню

### 3. Награда за победу

#### Формула награды

```gdscript
var base_reward = 50                    # Базовая награда
var moves_bonus = _moves_left * 10      # Бонус за ходы
var total_reward = base_reward + moves_bonus
```

#### Примеры наград

| Оставшиеся ходы | Базовая | Бонус | Итого |
|-----------------|---------|-------|-------|
| 0               | 50      | 0     | 50    |
| 5               | 50      | 50    | 100   |
| 10              | 50      | 100   | 150   |
| 15              | 50      | 150   | 200   |

#### Экран победы

```
Уровень пройден!

Поздравляем!

Награда:
  Базовая: 50 монет
  За ходы: 10 × 5 = 50 монет

Всего получено: 100 монет
```

## UI элементы

### Счётчик монет (верхняя панель)

```gdscript
var cc = VBoxContainer.new()
cc.name = "CoinsContainerNew"

var c_title = Label.new()
c_title.text = "МОНЕТЫ"
c_title.add_theme_font_size_override("font_size", 14)
c_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

var c_count = Label.new()
c_count.name = "CoinsCount"
c_count.text = str(LevelManager.get_coins())
c_count.add_theme_font_size_override("font_size", 38)
c_count.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
c_count.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0, 0.9))
```

### Диалог покупки ходов

```gdscript
func _show_buy_moves_dialog():
    var cost = _get_moves_purchase_cost()
    var player_coins = LevelManager.get_coins()
    
    var dialog = AcceptDialog.new()
    dialog.title = "Закончились ходы!"
    dialog.dialog_text = "Хотите купить ещё %d ходов за %d монет?\n\nУ вас: %d монет" % [MOVES_PER_PURCHASE, cost, player_coins]
    dialog.ok_button_text = "Купить (%d)" % cost
    dialog.cancel_button_text = "Выйти"
    
    if player_coins < cost:
        dialog.dialog_text = "Недостаточно монет!\nНужно: %d монет\nУ вас: %d монет" % [cost, player_coins]
        dialog.ok_button_text = "Понятно"
        dialog.get_ok_button().disabled = true
```

### Диалог победы

```gdscript
func _show_victory_dialog(total: int, base: int, bonus: int):
    var dialog = AcceptDialog.new()
    dialog.title = "Уровень пройден!"
    dialog.dialog_text = "Поздравляем!\n\nНаграда:\n  Базовая: %d монет\n  За ходы: %d × %d = %d монет\n\nВсего получено: %d монет" % [base, _moves_left, 10, bonus, total]
    dialog.ok_button_text = "Продолжить"
```

## Поток игры

### Нормальное прохождение

```
Старт уровня
    ↓
Игрок делает ходы
    ↓
Победа (враги уничтожены)
    ↓
Начисление награды
    ↓
Экран победы
    ↓
Главное меню
```

### Покупка ходов

```
Старт уровня (500 монет)
    ↓
Игрок делает ходы
    ↓
Ходы закончились (0 ходов)
    ↓
Диалог покупки (100 монет)
    ↓
Игрок покупает (+5 ходов, -100 монет = 400 монет)
    ↓
Продолжение игры
    ↓
Ходы снова закончились
    ↓
Диалог покупки (250 монет)
    ↓
Игрок покупает (+5 ходов, -250 монет = 150 монет)
    ↓
Победа
    ↓
Награда (+100 монет = 250 монет)
```

## Баланс экономики

### Стоимость прохождения

**Без покупок**:
- Затраты: 0 монет
- Награда: 50-200 монет
- Чистая прибыль: 50-200 монет

**С одной покупкой**:
- Затраты: 100 монет
- Награда: 50-150 монет (меньше ходов осталось)
- Чистая прибыль: -50 до +50 монет

**С двумя покупками**:
- Затраты: 350 монет (100 + 250)
- Награда: 50-100 монет
- Чистая прибыль: -300 до -250 монет

### Рекомендации по балансу

1. **Начальные уровни** (1-5):
   - Ходов достаточно для прохождения
   - Награда 100-150 монет
   - Цель: накопить монеты

2. **Средние уровни** (6-15):
   - Может потребоваться 1 покупка
   - Награда 80-120 монет
   - Цель: поддержание баланса

3. **Сложные уровни** (16+):
   - Может потребоваться 2+ покупки
   - Награда 60-100 монет
   - Цель: стратегическое использование ходов

## Сохранение и загрузка

### Формат ConfigFile

```ini
[progress]
current_level=1
max_unlocked_level=1
is_campaign_started=false
player_coins=500
```

### Функции сохранения

```gdscript
func _save_progress():
    var cfg := ConfigFile.new()
    cfg.set_value("progress", "current_level", current_level)
    cfg.set_value("progress", "max_unlocked_level", max_unlocked_level)
    cfg.set_value("progress", "is_campaign_started", is_campaign_started)
    cfg.set_value("progress", "player_coins", player_coins)
    cfg.save(SAVE_PATH)

func _load_progress():
    var cfg := ConfigFile.new()
    var err = cfg.load(SAVE_PATH)
    if err == OK:
        current_level = int(cfg.get_value("progress", "current_level", 1))
        max_unlocked_level = int(cfg.get_value("progress", "max_unlocked_level", 1))
        is_campaign_started = bool(cfg.get_value("progress", "is_campaign_started", false))
        player_coins = int(cfg.get_value("progress", "player_coins", INITIAL_COINS))
```

## Возможные улучшения

### 1. Магазин

- Покупка бустеров за монеты
- Покупка жизней
- Специальные предложения

### 2. Ежедневные награды

- Вход в игру: +50 монет
- Серия побед: +100 монет
- Ежедневные задания: +150 монет

### 3. Достижения

- Первая победа: +100 монет
- 10 побед подряд: +500 монет
- Прохождение без покупок: +200 монет

### 4. Монетизация

- Покупка монет за реальные деньги
- Просмотр рекламы: +50 монет
- Подписка: +1000 монет/неделя

### 5. Динамическая цена

```gdscript
# Цена зависит от сложности уровня
func _get_moves_purchase_cost() -> int:
    var base = MOVES_PURCHASE_BASE_COST
    var level_mult = 1.0 + (LevelManager.current_level / 20.0)
    var purchase_mult = 1.0 + (_moves_purchase_count * 1.5)
    return int(base * level_mult * purchase_mult)
```

### 6. Бонусы за эффективность

```gdscript
# Награда за идеальное прохождение
if _moves_left >= _moves_total * 0.8:
    total_reward *= 2  # Удвоенная награда
```

## Безопасность

### Защита от читов

1. **Валидация**:
   ```gdscript
   func spend_coins(amount: int) -> bool:
       if amount < 0 or amount > 10000:
           return false  # Подозрительная сумма
       if player_coins >= amount:
           player_coins -= amount
           return true
       return false
   ```

2. **Лимиты**:
   ```gdscript
   const MAX_COINS := 999999
   
   func add_coins(amount: int):
       player_coins = min(player_coins + amount, MAX_COINS)
   ```

3. **Логирование**:
   ```gdscript
   func spend_coins(amount: int) -> bool:
       if player_coins >= amount:
           print("Spent %d coins (balance: %d -> %d)" % [amount, player_coins, player_coins - amount])
           player_coins -= amount
           return true
       return false
   ```

## Тестирование

### Тестовые сценарии

1. **Покупка с достаточными монетами**:
   - Начальный баланс: 500
   - Цена покупки: 100
   - Ожидаемый результат: 400 монет, +5 ходов

2. **Покупка с недостаточными монетами**:
   - Баланс: 50
   - Цена покупки: 100
   - Ожидаемый результат: Кнопка "Купить" неактивна

3. **Множественные покупки**:
   - 1-я: 100 монет → 400 осталось
   - 2-я: 250 монет → 150 осталось
   - 3-я: 400 монет → недостаточно

4. **Награда за победу**:
   - Оставшиеся ходы: 10
   - Ожидаемая награда: 50 + 100 = 150 монет

### Команды отладки

```gdscript
# Добавить монеты для тестирования
LevelManager.add_coins(1000)

# Сбросить прогресс
LevelManager.player_coins = INITIAL_COINS
LevelManager._save_progress()

# Проверить баланс
print("Coins:", LevelManager.get_coins())
```

## Заключение

Система монет добавляет:

✅ **Прогрессию**: Накопление ресурсов  
✅ **Выбор**: Купить ходы или сохранить монеты  
✅ **Награду**: Мотивация проходить эффективно  
✅ **Монетизацию**: Основа для будущего магазина  

Баланс настроен так, чтобы игроки могли проходить уровни без покупок, но при желании могли упростить прохождение за монеты.
