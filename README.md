# 🎮 Elemental Blast

[![Godot Web Export](https://github.com/Fadeyin/Elemental_Blast/actions/workflows/godot-web-export.yml/badge.svg)](https://github.com/Fadeyin/Elemental_Blast/actions/workflows/godot-web-export.yml)
[![GitHub Pages](https://img.shields.io/badge/play-online-success)](https://fadeyin.github.io/Elemental_Blast/)
[![Godot Engine](https://img.shields.io/badge/Godot-4.6-blue.svg)](https://godotengine.org/)

Match-3 головоломка на Godot Engine 4.6

## 🎮 Играть сейчас!

**https://fadeyin.github.io/Elemental_Blast/**

✅ **Работает на GitHub Pages** - откройте на телефоне, компьютере или планшете!

> **Последнее обновление:** 22 марта 2026 - игра полностью работает на GitHub Pages после исправления загрузки

## 🚀 Быстрый старт

### Тестирование на телефоне

Игра автоматически собирается и публикуется на **GitHub Pages** при каждом push в ветку `main`

**Опционально: Netlify** (для максимальной производительности):
```
https://elemental-blast-xxxxx.netlify.app
```
*Требует настройки секретов (см. `NETLIFY_QUICK_GUIDE.md`)*

### Разработка

1. **Внесите изменения** в Godot или коде
2. **Commit и Push**:
   ```bash
   git add .
   git commit -m "Описание изменений"
   git push
   ```
3. **Подождите 3-5 минут** (автоматическая сборка)
4. **Обновите страницу** на телефоне и тестируйте!

### 🔀 Билд из других веток

**Новая функция!** Теперь можно собирать и тестировать игру из любой ветки:

#### Способ 1: Ручной запуск

1. Откройте [GitHub Actions](https://github.com/Fadeyin/Elemental_Blast/actions)
2. Выберите "Godot Web Export" → "Run workflow"
3. Выберите вашу ветку из списка
4. Отметьте нужные опции деплоя
5. Запустите!

#### Способ 2: Pull Request Preview

```bash
git checkout -b feature/my-feature
git push origin feature/my-feature
# Создайте PR → автоматический preview на Netlify
```

#### Способ 3: Скачать артефакт

Запустите workflow без деплоя и скачайте артефакт для локального тестирования.

---

**📖 Быстрый старт:** [BRANCH_BUILD_QUICKSTART.md](.github/BRANCH_BUILD_QUICKSTART.md)  
**📚 Полное руководство:** [MULTI_BRANCH_BUILD.md](.github/MULTI_BRANCH_BUILD.md)  
**📊 Визуальные схемы:** [MULTI_BRANCH_WORKFLOW_DIAGRAM.md](.github/MULTI_BRANCH_WORKFLOW_DIAGRAM.md)

## 📋 Требования

- Godot Engine 4.6 (для локальной разработки)
- Git
- Аккаунт на GitHub (для автоматической сборки)

## 🛠️ Технические детали

### Конфигурация

- **Движок**: Godot Engine 4.6
- **Платформа**: Mobile (iOS/Android/Web)
- **Разрешение**: 648x1200 (портрет)
- **Рендер**: Mobile renderer
- **Ориентация**: Портретная

### Структура проекта

```
.
├── scenes/              # Сцены игры
│   ├── main_menu.tscn
│   ├── game_board.tscn
│   └── ...
├── scripts/             # Скрипты GDScript
│   ├── main_menu.gd
│   ├── game_board.gd
│   └── ...
├── textures/            # Текстуры и спрайты
├── .github/
│   ├── workflows/       # GitHub Actions
│   ├── QUICK_START.md   # Быстрая шпаргалка
│   └── WORKFLOW_DIAGRAM.md  # Схема процесса
├── DEPLOYMENT.md        # Подробная документация
└── serve_local.sh       # Локальный веб-сервер
```

## 📚 Документация

| Документ | Описание |
|----------|----------|
| **[BRANCH_BUILD_QUICKSTART.md](.github/BRANCH_BUILD_QUICKSTART.md)** | ⚡ **НОВОЕ:** Билд из других веток (быстрый старт) |
| **[MULTI_BRANCH_BUILD.md](.github/MULTI_BRANCH_BUILD.md)** | 🔀 **НОВОЕ:** Полное руководство по сборке из веток |
| **[NETLIFY_SETUP.md](.github/NETLIFY_SETUP.md)** | ⭐ Настройка Netlify (рекомендуется) |
| **[QUICK_START.md](.github/QUICK_START.md)** | Быстрая шпаргалка для начала работы |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Подробная инструкция по деплою и настройке |
| **[WORKFLOW_DIAGRAM.md](.github/WORKFLOW_DIAGRAM.md)** | Визуальная схема процесса сборки |
| **[SETUP_CHECKLIST.md](.github/SETUP_CHECKLIST.md)** | Чеклист для проверки настройки |
| **[TROUBLESHOOTING.md](.github/TROUBLESHOOTING.md)** | Решение проблем с загрузкой |
| **[ALTERNATIVE_HOSTING.md](.github/ALTERNATIVE_HOSTING.md)** | Альтернативные варианты хостинга |
| **[COMMANDS.md](COMMANDS.md)** | Полезные команды и шпаргалки |

## 🔧 Локальная разработка

### Открыть проект

```bash
# Откройте project.godot в Godot Editor
godot project.godot
```

### Локальное тестирование веб-версии

```bash
# После экспорта в build/web/ из Godot:
./serve_local.sh
```

Или вручную:

```bash
cd build/web/
python3 -m http.server 8000
```

Откройте http://localhost:8000 в браузере.

## 🌐 Автоматическая сборка

### Как это работает

При каждом `git push` в ветки `main` или `cursor/godot-web-9125`:

1. GitHub Actions скачивает Godot Engine 4.6
2. Экспортирует веб-версию игры
3. Оптимизирует для мобильных устройств
4. Публикует на GitHub Pages
5. Сохраняет артефакты на 14 дней

### Проверка статуса

Перейдите в раздел **Actions** на GitHub:
- ✅ Зелёная галочка = сборка успешна
- 🔄 Жёлтый кружок = в процессе
- ❌ Красный крестик = ошибка

## 📱 Первичная настройка GitHub Pages

**Выполнить один раз** после первого push:

1. Откройте репозиторий на GitHub
2. **Settings** → **Pages**
3. **Source**:
   - Branch: `gh-pages`
   - Folder: `/ (root)`
4. Нажмите **Save**

Через несколько минут игра станет доступна по адресу выше.

## 🐛 Решение проблем

### Игра не загружается

1. Проверьте GitHub Pages включён (см. выше)
2. Проверьте успешность сборки в Actions
3. Очистите кэш браузера (Ctrl+Shift+R)
4. Откройте в режиме инкогнито

### Старая версия на GitHub Pages

```bash
# Добавьте версию к URL
https://fadeyin.github.io/Elemental_Blast/?v=2
```

Меняйте номер версии при каждом обновлении.

### Сборка завершается с ошибкой

1. Откройте **Actions** → кликните на неудачный запуск
2. Посмотрите логи каждого шага
3. Типичные причины:
   - Некорректные ссылки в сценах
   - Отсутствующие ресурсы
   - Ошибки в скриптах

## 🎯 Преимущества автосборки

**Не нужно:**
- ❌ Открывать Godot для каждого теста
- ❌ Вручную экспортировать веб-версию
- ❌ Настраивать локальный веб-сервер
- ❌ Копировать файлы на хостинг

**Достаточно:**
- ✅ Внести изменения
- ✅ `git push`
- ✅ Открыть ссылку через 3-5 минут

## 📦 Артефакты

Каждая сборка сохраняется как артефакт на 14 дней:

1. **Actions** → выберите запуск
2. **Artifacts** → скачайте **web-build**
3. Распакуйте и откройте `index.html` локально

## 🔄 Workflow

```bash
# Обычный рабочий процесс:

# 1. Создайте новую фичу
git checkout -b feature/new-level

# 2. Внесите изменения в Godot
# ... редактирование ...

# 3. Commit и Push
git add .
git commit -m "Добавлен новый уровень"
git push origin feature/new-level

# 4. Создайте PR в main
# ... через GitHub UI ...

# 5. После мерджа в main - автоматический деплой!
```

## 📄 Лицензия

Проект для личного использования.

## 👤 Автор

Fadeyin

---

**Приятной разработки! 🎮**
