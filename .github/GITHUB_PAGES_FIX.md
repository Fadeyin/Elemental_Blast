# 🔧 Исправление ошибки загрузки на GitHub Pages

## Проблема

Godot 4.6 по умолчанию использует **потоки (threads)**, которые требуют специальные HTTP-заголовки:
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`

**GitHub Pages НЕ поддерживает** кастомные HTTP-заголовки, поэтому игра не может загрузиться.

## ✅ Решение

Отключили поддержку потоков в экспорте для совместимости с GitHub Pages:

```cfg
variant/thread_support=false
progressive_web_app/ensure_cross_origin_isolation_headers=false
```

### Что изменилось

1. **Workflow обновлён** - теперь создаёт веб-сборку без потоков
2. **Удалены COOP/COEP заголовки** - они больше не нужны
3. **Игра работает на GitHub Pages** - без дополнительных настроек

## 🎮 Проверка работы

После деплоя откройте игру:
```
https://fadeyin.github.io/Elemental_Blast/
```

Игра должна загрузиться без ошибок.

## 📊 Производительность

**Отключение потоков:**
- ✅ Работает на любом хостинге
- ✅ Совместимость с большинством браузеров
- ⚠️ Немного медленнее (обычно незаметно для простых игр)

**Если нужна максимальная производительность** - используйте Netlify с включенными потоками (см. `NETLIFY_SETUP.md`).

## 🔍 Как это работает

### До исправления:
```
Godot 4.6 (threads) → требует COOP/COEP → GitHub Pages не поддерживает → ❌ ошибка
```

### После исправления:
```
Godot 4.6 (no threads) → не требует COOP/COEP → GitHub Pages работает → ✅ успех
```

## 🚀 Что дальше

1. **Запушьте изменения** - workflow автоматически пересоберёт игру
2. **Подождите 3-5 минут** - пока GitHub Actions завершит деплой
3. **Обновите страницу** - игра должна загрузиться

## 📝 Техническая справка

### Godot Export Settings (для справки)

Если вы экспортируете вручную из редактора Godot, используйте эти настройки:

```
Variant → Thread Support: OFF
Progressive Web App → Ensure Cross Origin Isolation Headers: OFF
```

### Проверка в браузере

Откройте консоль разработчика (F12) и проверьте:

✅ **Должно быть:**
```
Loading...
Game loaded successfully
```

❌ **НЕ должно быть:**
```
SharedArrayBuffer is not defined
Cross-Origin-Opener-Policy error
```

## 🆘 Если всё равно не работает

1. Проверьте, что workflow завершился успешно:
   ```bash
   gh run list --limit 1
   ```

2. Проверьте содержимое `gh-pages` ветки:
   ```bash
   git fetch origin gh-pages
   git checkout gh-pages
   ls -la
   ```

3. Очистите кэш браузера (Ctrl+Shift+Delete)

4. Попробуйте в режиме инкогнито

## 🔗 Полезные ссылки

- [Документация Godot по Web Export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [GitHub Pages документация](https://docs.github.com/pages)
- [Troubleshooting Guide](./.github/TROUBLESHOOTING.md)
