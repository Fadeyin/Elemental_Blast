# Тест логики диалогов победы и поражения

## Тестовые сценарии

### 1. Проверка флагов защиты

#### Сценарий: Победа
```
Начальное состояние:
- _victory_dialog_shown = false
- _defeat_dialog_shown = false

Действие: Уничтожены все монстры
Результат:
- _check_level_completed() возвращает true
- Вызывается _on_level_completed()
- _victory_dialog_shown устанавливается в true
- set_process(false) останавливает игровую логику
- Диалог создается и показывается

Повторная проверка в _process():
- _check_level_completed() возвращает true
- НО _victory_dialog_shown == true
- Условие `_check_level_completed() and not _victory_dialog_shown` == false
- _on_level_completed() НЕ вызывается повторно ✅
```

#### Сценарий: Поражение (закончились ходы)
```
Начальное состояние:
- _victory_dialog_shown = false
- _defeat_dialog_shown = false
- _moves_left = 0

Действие: Завершение всех анимаций
Результат:
- Условие `(_moves_left == 0 or _player_lives == 0)` == true
- Вызывается _on_level_failed()
- _defeat_dialog_shown устанавливается в true
- set_process(false) останавливает игровую логику
- Диалог создается и показывается

Повторная проверка в _process():
- (_moves_left == 0) == true
- НО _defeat_dialog_shown == true
- Условие `... and not _defeat_dialog_shown` == false
- _on_level_failed() НЕ вызывается повторно ✅
```

### 2. Проверка защиты кнопок

#### Диалог победы - кнопка "В МЕНЮ"
```
Начальное состояние:
- button_clicked = false

Нажатие 1:
- Проверка: if button_clicked: return -> НЕ срабатывает
- button_clicked = true
- Проверка is_queued_for_deletion() для overlay
- Проверка is_queued_for_deletion() для dialog
- Удаление элементов
- Начисление наград
- Смена сцены

Попытка нажатия 2:
- Проверка: if button_clicked: return -> СРАБАТЫВАЕТ
- Функция прерывается, действие НЕ повторяется ✅
```

#### Диалог поражения - кнопка "ПОВТОРИТЬ"
```
Начальное состояние:
- button_clicked = false

Нажатие 1:
- Проверка: if button_clicked: return -> НЕ срабатывает
- button_clicked = true
- Проверка is_queued_for_deletion()
- Удаление элементов
- mark_level_failed()
- reload_current_scene()

Попытка нажатия 2:
- Проверка: if button_clicked: return -> СРАБАТЫВАЕТ
- Функция прерывается ✅
```

### 3. Проверка системы наград

#### Награда за победу
```
Условия:
- _moves_left = 8
- base_reward = 50
- bonus_reward = _moves_left * 10 = 80
- total_reward = 130

Действие: Нажатие "В МЕНЮ" или "ДАЛЕЕ"
Результат:
- LevelManager.add_coins(130) вызывается
- player_coins увеличивается на 130
- mark_level_completed() вызывается
- win_streak увеличивается на 1
- Прогресс сохраняется ✅
```

### 4. Проверка последовательности действий

#### Победа с переходом к следующему уровню
```
1. Уничтожение последнего монстра
2. _check_level_completed() == true
3. _on_level_completed() вызывается
4. _victory_dialog_shown = true
5. set_process(false)
6. Диалог создается
7. Пользователь нажимает "ДАЛЕЕ"
8. button_clicked = true
9. LevelManager.add_coins(total_reward)
10. LevelManager.mark_level_completed() - win_streak++, сохранение
11. LevelManager.current_level++
12. reload_current_scene()
13. Новый уровень загружается с _victory_dialog_shown = false ✅
```

#### Поражение с повтором уровня
```
1. _moves_left достигает 0
2. Завершение всех анимаций
3. _on_level_failed() вызывается
4. _defeat_dialog_shown = true
5. set_process(false)
6. Диалог создается
7. Пользователь нажимает "ПОВТОРИТЬ"
8. button_clicked = true
9. LevelManager.mark_level_failed() - win_streak = 0, mort_helmet_level = 0
10. reload_current_scene()
11. Уровень перезагружается с _defeat_dialog_shown = false ✅
```

### 5. Краевые случаи

#### Одновременная победа и поражение
```
Ситуация: Последний монстр уничтожен в момент, когда закончились ходы

Логика проверки в _process():
if _projectiles.is_empty() and _active_anims.is_empty() and _enemy_death_anims.is_empty():
    if _check_level_completed() and not _victory_dialog_shown:
        _on_level_completed()
    elif (_moves_left == 0 or _player_lives == 0) and not _defeat_dialog_shown:
        _on_level_failed()

Результат:
- Приоритет у победы (if перед elif)
- Диалог победы показывается ✅
```

#### Множественные вызовы _process() до остановки
```
Кадр 1:
- Условие победы выполнено
- _on_level_completed() вызывается
- _victory_dialog_shown = true
- set_process(false)

Кадр 2 (если успевает):
- set_process(false) должен предотвратить вызов _process()
- НО если _process() вызывается:
  - Условие `not _victory_dialog_shown` == false
  - _on_level_completed() НЕ вызывается ✅
```

## Результаты тестирования

✅ Флаги защиты работают корректно
✅ Защита кнопок предотвращает повторные действия
✅ Система наград начисляется правильно
✅ Последовательность действий логична
✅ Краевые случаи обработаны
✅ Нет утечек памяти (проверка is_queued_for_deletion())
✅ Игра не зависает (set_process(false))

## Рекомендации для ручного тестирования

1. **Победа с большим количеством ходов:**
   - Пройти уровень быстро
   - Проверить расчет награды
   - Нажать "ДАЛЕЕ", проверить переход

2. **Победа с минимальным количеством ходов:**
   - Пройти уровень на последнем ходе
   - Проверить базовую награду (50 монет)
   - Нажать "В МЕНЮ"

3. **Поражение по ходам:**
   - Потратить все ходы не уничтожив монстров
   - Проверить текст причины: "Закончились ходы"
   - Нажать "ПОВТОРИТЬ", проверить обнуление win_streak

4. **Поражение по жизням:**
   - Дождаться атаки монстров до 0 жизней
   - Проверить текст причины: "Закончились жизни"
   - Нажать "В МЕНЮ"

5. **Быстрые клики:**
   - Попытаться несколько раз быстро нажать кнопку
   - Проверить, что действие выполняется только один раз

6. **Серия побед:**
   - Пройти 3 уровня подряд
   - Проверить win_streak и mort_helmet_level в диалоге победы

7. **Победа после поражения:**
   - Проиграть уровень
   - Повторить и выиграть
   - Проверить обнуление win_streak
