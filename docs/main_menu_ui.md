# UI главного меню

## Описание

Главный экран игры с верхним баром, отображающим основную информацию игрока и кнопки управления.

## Структура экрана

```
┌─────────────────────────────────────────┐
│ 👤  🪙 500  [+]        [⚙]             │ ← Верхний бар (80px)
├─────────────────────────────────────────┤
│                                         │
│         Стартовый уровень: 1            │
│                                         │
│     ┌───┐  ┌───┐  ┌───┐                │
│     │ 1 │  │ 2 │  │ 3 │                │
│     └───┘  └───┘  └───┘                │
│     ┌───┐  ┌───┐  ┌───┐                │
│     │ 4 │  │ 5 │  │ 6 │                │
│     └───┘  └───┘  └───┘                │
│                                         │
│      ┌────────────────┐                 │
│      │  Уровень 1     │                 │
│      └────────────────┘                 │
├─────────────────────────────────────────┤
│  [Магазин]  [Главная]  [Ранги]        │ ← Нижний бар (100px)
└─────────────────────────────────────────┘
```

## Верхний бар (TopBar)

### Характеристики

- **Высота**: 80px
- **Фон**: Тёмно-серый (RGB: 0.08, 0.1, 0.12, прозрачность: 0.9)
- **Компоновка**: HBoxContainer с отступами

### Элементы (слева направо)

#### 1. Аватарка игрока (заглушка)

```gdscript
func _create_avatar() -> Control:
    var container = PanelContainer.new()
    container.custom_minimum_size = Vector2(64, 64)
    
    # Круглый контейнер с обводкой
    var bg_style = StyleBoxFlat.new()
    bg_style.bg_color = Color(0.3, 0.35, 0.4, 1.0)
    bg_style.corner_radius_top_left = 32  # Радиус = 64/2
    bg_style.corner_radius_top_right = 32
    bg_style.corner_radius_bottom_left = 32
    bg_style.corner_radius_bottom_right = 32
    bg_style.border_width_top = 3
    bg_style.border_color = Color(0.5, 0.6, 0.7, 1.0)
    
    # Иконка пользователя
    var avatar_label = Label.new()
    avatar_label.text = "👤"
    avatar_label.add_theme_font_size_override("font_size", 42)
```

**Характеристики**:
- Размер: 64×64 пикселя
- Форма: Круг (corner_radius = 32)
- Фон: Серо-синий (0.3, 0.35, 0.4)
- Обводка: 3px, светло-серая
- Иконка: 👤 (заглушка, размер 42px)

#### 2. Отступ (15px)

#### 3. Отображение монет

```gdscript
func _create_coins_display() -> Control:
    var container = HBoxContainer.new()
    container.add_theme_constant_override("separation", 8)
    
    # Иконка монеты
    var coin_icon = Label.new()
    coin_icon.text = "🪙"
    coin_icon.add_theme_font_size_override("font_size", 36)
    
    # Количество монет
    var coins_label = Label.new()
    coins_label.name = "TopBarCoinsCount"
    coins_label.text = str(LevelManager.get_coins())
    coins_label.add_theme_font_size_override("font_size", 32)
    coins_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
    coins_label.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.0, 0.9))
    coins_label.add_theme_constant_override("outline_size", 4)
```

**Характеристики**:
- Иконка: 🪙 (размер 36px)
- Текст: Золотистый (1.0, 0.9, 0.3)
- Размер шрифта: 32px
- Обводка: Тёмно-коричневая (0.3, 0.2, 0.0)
- Автообновление через сигнал `coins_changed`

#### 4. Кнопка покупки монет "+"

```gdscript
func _create_buy_coins_button() -> Button:
    var btn = Button.new()
    btn.text = "+"
    btn.custom_minimum_size = Vector2(50, 50)
    
    # Круглая зелёная кнопка
    var normal_style = StyleBoxFlat.new()
    normal_style.bg_color = Color(0.2, 0.6, 0.3, 1.0)
    normal_style.corner_radius_top_left = 25
    normal_style.border_width_top = 2
    normal_style.border_color = Color(0.3, 0.8, 0.4, 1.0)
    
    btn.add_theme_font_size_override("font_size", 36)
    btn.add_theme_color_override("font_color", Color.WHITE)
```

**Характеристики**:
- Размер: 50×50 пикселей
- Форма: Круг (corner_radius = 25)
- Цвет: Зелёный (0.2, 0.6, 0.3)
- Обводка: Светло-зелёная (0.3, 0.8, 0.4)
- Текст: "+" белый, размер 36px
- Hover: Светлее (0.3, 0.7, 0.4)
- Pressed: Темнее (0.15, 0.5, 0.25)

**Действие**: Открывает диалог покупки монет

#### 5. Гибкий отступ (заполняет пространство)

#### 6. Кнопка настроек "⚙"

```gdscript
func _create_settings_button() -> Button:
    var btn = Button.new()
    btn.text = "⚙"
    btn.custom_minimum_size = Vector2(60, 60)
    
    # Круглая серая кнопка
    var normal_style = StyleBoxFlat.new()
    normal_style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
    normal_style.corner_radius_top_left = 30
    normal_style.border_width_top = 2
    normal_style.border_color = Color(0.4, 0.5, 0.6, 1.0)
    
    btn.add_theme_font_size_override("font_size", 40)
    btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
```

**Характеристики**:
- Размер: 60×60 пикселей
- Форма: Круг (corner_radius = 30)
- Цвет: Серый (0.25, 0.3, 0.35)
- Обводка: Светло-серая (0.4, 0.5, 0.6)
- Текст: "⚙" белый, размер 40px
- Hover: Светлее (0.35, 0.4, 0.45)
- Pressed: Темнее (0.2, 0.25, 0.3)

**Действие**: Открывает диалог настроек (заглушка)

#### 7. Отступ (20px)

## Диалоги

### Диалог покупки монет

```gdscript
func _show_buy_coins_dialog():
    var dialog = AcceptDialog.new()
    dialog.title = "Купить монеты"
    dialog.dialog_text = "Выберите пакет монет:\n\n100 монет - 50₽\n500 монет - 200₽\n1000 монет - 350₽\n\n(Покупка временно недоступна)"
    dialog.ok_button_text = "Закрыть"
```

**Содержимое**:
```
Купить монеты

Выберите пакет монет:

100 монет - 50₽
500 монет - 200₽
1000 монет - 350₽

(Покупка временно недоступна)

[Закрыть]
```

**Будущее**:
- Интеграция с платёжной системой
- Реальные покупки через Google Play / App Store
- Специальные предложения
- Ограниченные по времени акции

### Диалог настроек

```gdscript
func _on_settings_pressed():
    var dialog = AcceptDialog.new()
    dialog.title = "Настройки"
    dialog.dialog_text = "Настройки будут добавлены позже"
    dialog.ok_button_text = "Закрыть"
```

**Будущее**:
- Звук (музыка, эффекты)
- Вибрация
- Язык
- Управление учётной записью
- Сброс прогресса
- О игре

## Автообновление

### Подписка на изменения

```gdscript
func _ready():
    # ...
    LevelManager.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(new_amount: int):
    var coins_label = find_child("TopBarCoinsCount", true, false)
    if coins_label:
        coins_label.text = str(new_amount)
```

**Когда обновляется**:
- Победа на уровне (+награда)
- Покупка ходов (-стоимость)
- Покупка бустера (-350)
- Покупка монет (+пакет) - в будущем

## Компоновка

### HBoxContainer

```
[20px] [Аватарка 64×64] [15px] [🪙 500] [+ 50×50] [flex] [⚙ 60×60] [20px]
```

### Отступы

- Левый: 20px
- Между аватаркой и монетами: 15px
- Между элементами монет: 8px (separation в HBox)
- Гибкий отступ: заполняет пространство
- Правый: 20px

## Адаптация контента

### Смещение вниз

Основной контент (`TabContent`) смещён на 80px вниз:

```gdscript
[node name="TabContent" type="Control" parent="."]
offset_top = 80  # Новое
```

### Корректировка элементов

- `StartLevelLabel`: offset_top изменён с 40 на 20
- `LevelsScroll`: offset_top изменён с -450 на -400

## Стилизация элементов

### Круглые кнопки (паттерн)

```gdscript
var style = StyleBoxFlat.new()
style.bg_color = Color(...)
style.corner_radius_top_left = SIZE / 2
style.corner_radius_top_right = SIZE / 2
style.corner_radius_bottom_left = SIZE / 2
style.corner_radius_bottom_right = SIZE / 2
style.border_width_top = 2
style.border_width_bottom = 2
style.border_width_left = 2
style.border_width_right = 2
style.border_color = Color(...)
```

### Цветовая палитра

| Элемент | Нормальный | Hover | Pressed |
|---------|-----------|-------|---------|
| Кнопка "+" | 0.2, 0.6, 0.3 | 0.3, 0.7, 0.4 | 0.15, 0.5, 0.25 |
| Настройки | 0.25, 0.3, 0.35 | 0.35, 0.4, 0.45 | 0.2, 0.25, 0.3 |
| Аватарка | 0.3, 0.35, 0.4 | - | - |

## Будущие улучшения

### Аватарка

1. **Загрузка изображения**:
```gdscript
func _load_avatar():
    var avatar_path = "user://avatar.png"
    if FileAccess.file_exists(avatar_path):
        var img = Image.load_from_file(avatar_path)
        var tex = ImageTexture.create_from_image(img)
        avatar_rect.texture = tex
```

2. **Выбор аватарки**:
```gdscript
func _show_avatar_selection():
    # Галерея предустановленных аватарок
    # Загрузка собственного изображения
    # Редактор аватарки
```

3. **Информация игрока**:
```gdscript
# При клике на аватарку
func _on_avatar_clicked():
    _show_player_profile()
    # Имя игрока
    # Уровень аккаунта
    # Статистика (пройдено уровней, монет заработано)
```

### Покупка монет

1. **Интеграция платежей**:
```gdscript
func _show_buy_coins_dialog():
    var packages = [
        {"coins": 100, "price": "50₽", "product_id": "coins_100"},
        {"coins": 500, "price": "200₽", "product_id": "coins_500"},
        {"coins": 1000, "price": "350₽", "product_id": "coins_1000"}
    ]
    
    for pkg in packages:
        var btn = Button.new()
        btn.text = "%d монет\n%s" % [pkg.coins, pkg.price]
        btn.pressed.connect(func(): _purchase_coins(pkg))
```

2. **Специальные предложения**:
```gdscript
# Ежедневная акция
{"coins": 200, "price": "99₽", "discount": "50%"}

# Первая покупка
{"coins": 500, "price": "150₽", "bonus": "+200 бонус"}
```

3. **Реклама за монеты**:
```gdscript
func _watch_ad_for_coins():
    # Просмотр рекламы → +50 монет
    # Лимит: 5 раз в день
```

### Настройки

1. **Звук**:
```gdscript
var music_slider = HSlider.new()
var sfx_slider = HSlider.new()
```

2. **Графика**:
```gdscript
var quality_options = ["Низкое", "Среднее", "Высокое"]
```

3. **Управление**:
```gdscript
var vibration_toggle = CheckButton.new()
```

4. **Учётная запись**:
```gdscript
# Вход/выход
# Синхронизация облака
# Смена аватарки
```

### Дополнительные элементы

1. **Уровень игрока**:
```gdscript
var level_label = Label.new()
level_label.text = "Уровень 15"
# Прогресс бар опыта
```

2. **Уведомления**:
```gdscript
var notification_badge = Label.new()
notification_badge.text = "3"  # Количество новых
# Красный кружок с числом
```

3. **Энергия/Жизни**:
```gdscript
var energy_label = Label.new()
energy_label.text = "❤️ 5/5"
# Таймер восстановления
```

## Технические детали

### Создание бара

```gdscript
func _create_top_bar():
    var top_bar = ColorRect.new()
    top_bar.name = "TopBar"
    top_bar.custom_minimum_size = Vector2(0, 80)
    top_bar.color = Color(0.08, 0.1, 0.12, 0.9)
    top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    top_bar.offset_bottom = 80
    add_child(top_bar)
    move_child(top_bar, 1)  # После фона, перед контентом
```

### Вспомогательные функции

```gdscript
func _create_spacer(width: float) -> Control:
    # Фиксированный отступ
    var spacer = Control.new()
    spacer.custom_minimum_size = Vector2(width, 0)
    return spacer

func _create_flexible_spacer() -> Control:
    # Гибкий отступ (заполняет пространство)
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return spacer
```

## Интеграция с игрой

### Обновление из других сцен

```gdscript
# В game_board.gd при победе
LevelManager.add_coins(reward)
# → Сигнал coins_changed
# → Автообновление в главном меню (если открыто)
```

### Переходы между сценами

```gdscript
# Из главного меню в игру
get_tree().change_scene_to_file("res://scenes/game_board.tscn")

# Из игры в главное меню
get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

## Тестирование

### Визуальная проверка

1. Запустить игру
2. Проверить отображение верхнего бара
3. Проверить все элементы:
   - ✅ Аватарка круглая 64×64
   - ✅ Монеты отображаются корректно
   - ✅ Кнопка "+" зелёная круглая
   - ✅ Кнопка настроек серая круглая
   - ✅ Компоновка правильная

### Функциональная проверка

1. **Монеты**:
   - Проверить начальное значение (500)
   - Пройти уровень → вернуться → проверить обновление

2. **Кнопка "+"**:
   - Клик → диалог покупки
   - Проверить пакеты монет
   - Закрыть диалог

3. **Кнопка настроек**:
   - Клик → диалог настроек
   - Проверить заглушку
   - Закрыть диалог

### Проверка адаптации

1. Запустить на разных разрешениях
2. Проверить, что контент не перекрывается
3. Проверить гибкий отступ (растягивается)

## Заключение

Верхний бар добавляет:

✅ **Информативность** - баланс монет всегда виден  
✅ **Доступность** - быстрая покупка монет  
✅ **Персонализация** - аватарка игрока  
✅ **Управление** - кнопка настроек  
✅ **Профессиональный вид** - современный UI  

Основа для будущего функционала: профиль игрока, достижения, уведомления, энергия.
