# Решение проблемы "Ошибка загрузки игры"

## Проблема

Игра не загружалась на GitHub Pages с сообщением "Ошибка загрузки игры". В консоли браузера была ошибка инициализации движка Godot.

## Диагностика

При анализе логов GitHub Actions были обнаружены следующие ошибки:

```
ERROR: Unrecognized UID: "uid://qloj8kic7ydi"
   at: get_id_path (core/io/resource_uid.cpp:208)
ERROR: Resource file not found: res:// (expected type: unknown)
   at: _load (core/io/resource_loader.cpp:351)
ERROR: Failed to create an autoload, can't load from UID or path: .
   at: _create_autoload (editor/settings/editor_autoload_settings.cpp:405)
```

## Причина

В файле `project.godot` была настроена автозагрузка (autoload) несуществующего скрипта:

```gdscript
[autoload]

MyGlobalState="*res://scripts/GameState.gd"
LevelManager="*res://scripts/LevelManager.gd"
```

Файл `GameState.gd` отсутствовал в репозитории, но при этом существовал файл `GameState.gd.uid` с UID `uid://qloj8kic7ydi`, что вызывало ошибки при сборке и экспорте проекта.

## Решение

### 1. Удалена ссылка на несуществующий autoload

В `project.godot`:

```diff
[autoload]

-MyGlobalState="*res://scripts/GameState.gd"
 LevelManager="*res://scripts/LevelManager.gd"
```

### 2. Удалён .uid файл

Удалён файл `scripts/GameState.gd.uid`, содержащий несуществующий UID.

### 3. Исправлены настройки экспорта

В `export_presets.cfg` отключены требования HTTP-заголовков COOP/COEP для совместимости с GitHub Pages:

```diff
 progressive_web_app/enabled=false
-progressive_web_app/ensure_cross_origin_isolation_headers=true
+progressive_web_app/ensure_cross_origin_isolation_headers=false
 progressive_web_app/offline_page=""
```

## Результат

После применения исправлений:

✅ Godot успешно экспортирует проект без ошибок  
✅ GitHub Actions завершается успешно  
✅ Игра корректно загружается на GitHub Pages  
✅ Все ресурсы (index.wasm, index.pck, index.js) доступны  

## Проверка

1. Проверьте логи GitHub Actions на наличие ошибок ERROR
2. Убедитесь что workflow завершился успешно
3. Откройте https://fadeyin.github.io/Elemental_Blast/ на телефоне
4. Игра должна загрузиться и отобразить главное меню

## Дополнительная информация

### Что такое autoload в Godot?

Autoload (автозагрузка) - это глобальные скрипты или сцены, которые Godot загружает автоматически при запуске игры. Они доступны из любого места в коде через свои имена.

### Почему была ошибка?

Godot пытался загрузить `GameState.gd` по UID `uid://qloj8kic7ydi`, но файл отсутствовал. Это приводило к критической ошибке при инициализации проекта.

### Как предотвратить подобные проблемы?

1. Всегда проверяйте логи GitHub Actions после каждого push
2. Ищите в логах строки с `ERROR` или `Failed`
3. Убедитесь что все autoload-скрипты существуют в репозитории
4. Перед удалением файлов проверьте, не используются ли они в `project.godot`

## Связанные файлы

- `project.godot` - конфигурация проекта
- `export_presets.cfg` - настройки экспорта
- `.github/workflows/godot-web-export.yml` - workflow сборки
- `scripts/LevelManager.gd` - единственный оставшийся autoload

## Pull Request

Исправления были внесены в PR #6:  
https://github.com/Fadeyin/Elemental_Blast/pull/6
