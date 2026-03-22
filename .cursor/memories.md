# Memories - Контекст проекта

## Проект
- **Название**: Elemental Blast
- **Тип**: Match-3 игра на Godot Engine 4.6
- **Репозиторий**: https://github.com/Fadeyin/Elemental_Blast
- **Основная ветка**: main
- **Рабочие ветки**: cursor/godot-web-9125

## Автоматизация сборки

### GitHub Actions
- Настроена автоматическая сборка веб-версии через GitHub Actions
- Workflow: `.github/workflows/godot-web-export.yml`
- Триггеры: push в main и cursor/godot-web-9125
- Используется Godot 4.6 stable

### GitHub Pages
- Публикация на: https://fadeyin.github.io/Elemental_Blast/
- Ветка деплоя: gh-pages
- Требуется первичная настройка в Settings → Pages

### Документация
- Быстрый старт: `.github/QUICK_START.md`
- Полная документация: `DEPLOYMENT.md`

## Структура проекта

### Конфигурация Godot
- Версия: 4.6
- Режим рендеринга: mobile
- Разрешение: 648x1200 (портретная ориентация)
- Главная сцена: uid://q6kql6yp0x11
- Автозагрузка:
  - LevelManager: res://scripts/LevelManager.gd

### Важные файлы
- `project.godot` - конфигурация проекта
- `.gitignore` - настроен для игнорирования файлов сборки
- `export_presets.cfg` - генерируется автоматически в CI/CD

## Рабочий процесс

### Тестирование на телефоне
1. Внести изменения
2. Commit + Push
3. Подождать 3-5 минут (GitHub Actions)
4. Открыть https://fadeyin.github.io/Elemental_Blast/ на телефоне

### Проверка сборки
- GitHub → Actions → "Godot Web Export"
- Артефакты хранятся 14 дней
- Можно скачать и запустить локально

## Технические детали

### Мобильная оптимизация
- Полноэкранный режим
- Адаптивный viewport
- Отключение масштабирования
- Индикатор загрузки
- Обработка ошибок

### HTTP-заголовки
Настроены для работы Godot в браузере:
- Cross-Origin-Embedder-Policy: require-corp
- Cross-Origin-Opener-Policy: same-origin

## Pull Requests
- PR #6: Критическое исправление: ошибка загрузки игры на GitHub Pages
  - Статус: смержен
  - URL: https://github.com/Fadeyin/Elemental_Blast/pull/6
  - Решена проблема с несуществующим autoload GameState
- PR #4: Автоматическая сборка и деплой веб-версии
  - Статус: смержен
  - URL: https://github.com/Fadeyin/Elemental_Blast/pull/4
  - Ветка: cursor/godot-web-9125 → main

## Последние изменения
- 2026-03-22: Исправлена критическая ошибка загрузки игры
  - Удалён несуществующий autoload MyGlobalState
  - Исправлены настройки экспорта для GitHub Pages
  - Добавлена документация решения проблемы
- 2026-03-22: Настроена автосборка и GitHub Pages
- Коммиты:
  - 07f9194: Добавлена документация решения проблемы загрузки игры
  - a394fa4: Критическое исправление: ошибка загрузки игры на GitHub Pages (#6)
  - 1dec432: Добавлены бейджи статуса в README
  - f83abd3: Документация по альтернативным хостингам
  - 124570d: Добавлен README и скрипт локального тестирования
  - 65de46e: Визуальная схема процесса сборки
  - 981758b: Память проекта для агентов
  - dcbd6d4: Быстрая шпаргалка
  - 02b785c: Обновлён .gitignore
  - cf063e6: Создан GitHub Actions workflow

## Созданные файлы
- `.github/workflows/godot-web-export.yml` - GitHub Actions workflow
- `.github/TROUBLESHOOTING_GAMESTATE.md` - Решение проблемы загрузки игры
- `.github/QUICK_START.md` - Быстрая шпаргалка
- `.github/WORKFLOW_DIAGRAM.md` - Визуальная схема процесса
- `.github/ALTERNATIVE_HOSTING.md` - Альтернативные хостинги
- `DEPLOYMENT.md` - Подробная документация
- `README.md` - Главный README проекта
- `serve_local.sh` - Скрипт для локального тестирования
- `.cursor/memories.md` - Память для агентов

## Известные проблемы и решения
- **Ошибка загрузки игры**: Решена удалением несуществующего autoload и отключением требований COOP/COEP заголовков
- **Netlify деплой**: Требует настройки секретов NETLIFY_AUTH_TOKEN и NETLIFY_SITE_ID (опционально)
- **Кеширование**: GitHub Pages может кешировать старую версию до 10 минут
