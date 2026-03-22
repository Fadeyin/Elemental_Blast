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
  - MyGlobalState: res://scripts/GameState.gd
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
- PR #4: Автоматическая сборка и деплой веб-версии
  - Статус: открыт
  - URL: https://github.com/Fadeyin/Elemental_Blast/pull/4
  - Ветка: cursor/godot-web-9125 → main

## Последние изменения
- 2026-03-22: Настроена автосборка и GitHub Pages
- Коммиты:
  - dcbd6d4: Добавлена быстрая шпаргалка
  - 02b785c: Обновлён .gitignore
  - cf063e6: Создан GitHub Actions workflow
