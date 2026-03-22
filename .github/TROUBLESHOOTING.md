# 🔧 Решение проблемы "Ошибка загрузки игры"

## 📋 Чеклист быстрой проверки

### 1. Проверьте GitHub Pages включён

1. Откройте: https://github.com/Fadeyin/Elemental_Blast/settings/pages
2. Должно быть:
   - **Source**: Branch `gh-pages`, Folder `/ (root)`
   - **Статус**: "Your site is live at https://fadeyin.github.io/Elemental_Blast/"

Если НЕТ настроек Source:
- Нажмите на поле Source
- Выберите Branch: `gh-pages`
- Выберите Folder: `/ (root)`
- Нажмите **Save**
- Подождите 2-3 минуты

### 2. Очистите кэш браузера

**На компьютере:**
- Chrome/Edge: `Ctrl + Shift + R` (или `Cmd + Shift + R` на Mac)
- Firefox: `Ctrl + F5`
- Safari: `Cmd + Option + R`

**На телефоне:**
- Откройте в **режиме инкогнито** (приватный режим)
- Или добавьте `?v=1` к URL: `https://fadeyin.github.io/Elemental_Blast/?v=1`

### 3. Подождите первую публикацию

После включения GitHub Pages нужно подождать **5-10 минут** для первого деплоя.

Проверьте статус:
1. Actions → Workflows → "pages build and deployment"
2. Дождитесь зелёной галочки ✅

### 4. Проверьте консоль браузера

**На компьютере:**
1. Откройте https://fadeyin.github.io/Elemental_Blast/
2. Нажмите `F12` (или `Cmd + Option + I` на Mac)
3. Перейдите на вкладку **Console**
4. Обновите страницу (`F5`)
5. Посмотрите ошибки (красные строки)

**На телефоне Android:**
1. Подключите телефон к компьютеру через USB
2. Включите USB-отладку на телефоне
3. На компьютере откройте Chrome: `chrome://inspect/#devices`
4. Найдите вкладку с игрой, нажмите **inspect**
5. Посмотрите вкладку Console

### 5. Частые ошибки и решения

#### Ошибка: "Failed to load index.wasm"

**Причина:** Неправильные пути к файлам

**Решение:**
1. Проверьте в браузере: https://fadeyin.github.io/Elemental_Blast/index.wasm
2. Если 404 - файл не задеплоился
3. Проверьте последний workflow: https://github.com/Fadeyin/Elemental_Blast/actions

#### Ошибка: "SharedArrayBuffer is not defined"

**Причина:** Отсутствуют HTTP-заголовки COOP/COEP

**Решение:**
Это уже настроено в нашем workflow, но GitHub Pages может игнорировать `.htaccess`.

Проверьте заголовки:
```bash
curl -I https://fadeyin.github.io/Elemental_Blast/
```

Должны быть:
```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

Если их нет, используйте альтернативный хостинг (Netlify, Vercel).

#### Ошибка: "404 Not Found"

**Причина:** GitHub Pages не включён или не задеплоился

**Решение:**
1. Проверьте Settings → Pages → Source настроен
2. Подождите 5-10 минут после первого включения
3. Проверьте Actions → "pages build and deployment" завершился

#### Ошибка: "CORS policy"

**Причина:** Файлы загружаются с другого домена

**Решение:**
Убедитесь, что все файлы загружаются с `fadeyin.github.io`, а не с других доменов.

### 6. Проверьте файлы на gh-pages

```bash
# Проверьте, что все файлы на месте
curl -s https://fadeyin.github.io/Elemental_Blast/ | grep -o 'index\.[a-z]*' | sort -u
```

Должны быть:
- index.html
- index.js
- index.wasm
- index.pck

### 7. Проверьте размер файлов

```bash
# Проверьте, что файлы не пустые
curl -I https://fadeyin.github.io/Elemental_Blast/index.wasm | grep Content-Length
```

Должен быть > 20MB (примерно 25-30 MB для Godot 4.6)

### 8. Временное решение: Локальное тестирование

Пока разбираемся с GitHub Pages, протестируйте локально:

```bash
# Скачайте последний артефакт
gh run download --name web-build

# Запустите локальный сервер
cd web-build
python3 -m http.server 8000
```

Откройте: http://localhost:8000

Если локально работает - проблема в GitHub Pages настройках.

## 🔍 Детальная диагностика

### Проверка 1: GitHub Pages URL

Откройте: https://github.com/Fadeyin/Elemental_Blast/settings/pages

Скопируйте точный URL, который там указан. Иногда он может отличаться.

### Проверка 2: Workflow деплоя

```bash
# Посмотрите последний успешный деплой
gh run list --workflow "Godot Web Export" --limit 1

# Посмотрите логи
gh run view --log
```

Ищите строки:
- "Deploy to GitHub Pages" - должен быть успешным
- Проверьте, что нет ошибок в шаге деплоя

### Проверка 3: Ветка gh-pages

```bash
# Проверьте содержимое ветки
git fetch origin gh-pages
git checkout gh-pages
ls -lh

# Должны быть файлы:
# index.html, index.js, index.wasm, index.pck
```

### Проверка 4: Тест прямых ссылок

Попробуйте открыть каждый файл отдельно:

1. https://fadeyin.github.io/Elemental_Blast/index.html ✅
2. https://fadeyin.github.io/Elemental_Blast/index.js ✅
3. https://fadeyin.github.io/Elemental_Blast/index.wasm ✅
4. https://fadeyin.github.io/Elemental_Blast/index.pck ✅

Все должны загружаться (или скачиваться).

## 🚨 Если ничего не помогло

### Вариант 1: Пересоздайте деплой

```bash
# Сделайте пустой коммит для ре-деплоя
git commit --allow-empty -m "Redeploy to GitHub Pages"
git push
```

### Вариант 2: Используйте Netlify (быстрее и надёжнее)

1. Зарегистрируйтесь на https://netlify.com
2. Подключите репозиторий
3. Настройки:
   - Branch: `gh-pages`
   - Publish directory: `/`
4. Deploy

Netlify часто работает лучше для Godot игр.

### Вариант 3: Проверьте исходный проект

Может быть ошибка в самом проекте Godot:

1. Откройте проект в Godot Editor
2. Попробуйте экспортировать вручную: Project → Export → Web (HTML5)
3. Сохраните в `build/web/`
4. Запустите `./serve_local.sh`
5. Откройте http://localhost:8000

Если локально не работает - проблема в проекте, а не в деплое.

## 📞 Получить помощь

Если проблема остаётся, соберите диагностическую информацию:

```bash
# Запустите скрипт диагностики
curl -I https://fadeyin.github.io/Elemental_Blast/ > diagnostic.txt
curl -I https://fadeyin.github.io/Elemental_Blast/index.wasm >> diagnostic.txt
gh run list --limit 5 >> diagnostic.txt
```

И пришлите содержимое `diagnostic.txt`.

## ✅ Чеклист "Работает"

- [ ] GitHub Pages включён (Settings → Pages → Source: gh-pages)
- [ ] Статус "Your site is live at..."
- [ ] Actions → "pages build and deployment" ✅ зелёная галочка
- [ ] https://fadeyin.github.io/Elemental_Blast/ открывается
- [ ] Консоль браузера (F12) без красных ошибок
- [ ] Индикатор загрузки показывается
- [ ] Игра загружается и запускается

---

**Начните с шагов 1-3, они решают 90% проблем!**
