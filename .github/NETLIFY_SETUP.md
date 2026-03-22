# 🚀 Настройка Netlify для Elemental Blast

## Почему Netlify?

✅ **Поддерживает HTTP-заголовки** (COOP/COEP) - обязательны для Godot 4.x
✅ **Быстрее GitHub Pages** - лучший CDN
✅ **Бесплатно** - 100 GB трафика/месяц
✅ **Автоматический деплой** - уже настроен в GitHub Actions
✅ **Instant cache invalidation** - изменения видны сразу

## 📋 Пошаговая инструкция

### Шаг 1: Регистрация на Netlify

1. Откройте https://netlify.com
2. Нажмите **Sign up**
3. Выберите **Continue with GitHub**
4. Авторизуйте Netlify через GitHub

### Шаг 2: Создание нового сайта

1. После входа нажмите **Add new site** → **Import an existing project**
2. Выберите **Deploy with GitHub**
3. Найдите и выберите **Elemental_Blast**
4. Настройки деплоя:
   - **Branch to deploy**: `gh-pages`
   - **Base directory**: оставьте пустым
   - **Build command**: оставьте пустым
   - **Publish directory**: `./` (корень)
5. Нажмите **Deploy Elemental_Blast**

### Шаг 3: Получение токенов для автодеплоя

#### 3.1 NETLIFY_AUTH_TOKEN

1. Откройте https://app.netlify.com/user/applications
2. В разделе **Personal access tokens** нажмите **New access token**
3. Описание: `GitHub Actions Elemental Blast`
4. Нажмите **Generate token**
5. **Скопируйте токен** (появится только один раз!)

#### 3.2 NETLIFY_SITE_ID

1. Откройте ваш сайт в Netlify
2. Перейдите в **Site settings**
3. В разделе **Site information** найдите **Site ID**
4. **Скопируйте ID** (формат: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### Шаг 4: Добавление секретов в GitHub

1. Откройте https://github.com/Fadeyin/Elemental_Blast/settings/secrets/actions
2. Нажмите **New repository secret**

**Добавьте первый секрет:**
- Name: `NETLIFY_AUTH_TOKEN`
- Secret: вставьте токен из шага 3.1
- Нажмите **Add secret**

**Добавьте второй секрет:**
- Name: `NETLIFY_SITE_ID`
- Secret: вставьте Site ID из шага 3.2
- Нажмите **Add secret**

### Шаг 5: Запуск автодеплоя

Секреты добавлены! Теперь при каждом push будет автоматический деплой на Netlify.

**Запустите первый деплой:**

```bash
# Сделайте пустой коммит для триггера
git commit --allow-empty -m "Deploy to Netlify"
git push
```

Или просто дождитесь мерджа текущего PR.

### Шаг 6: Получение URL

1. Откройте https://app.netlify.com
2. Выберите ваш сайт **Elemental_Blast**
3. URL будет вида: `https://elemental-blast-xxxxx.netlify.app`
4. **Скопируйте URL** - это ссылка на вашу игру!

## 🎨 Настройка кастомного домена (опционально)

### Если у вас есть свой домен:

1. В настройках сайта Netlify: **Domain settings**
2. **Add custom domain**
3. Введите ваш домен (например, `game.mysite.com`)
4. Настройте DNS у вашего регистратора:
   - Тип: `CNAME`
   - Name: `game` (или `@` для корневого)
   - Value: `elemental-blast-xxxxx.netlify.app`

### Или используйте красивое имя Netlify:

1. **Domain settings** → **Options** → **Edit site name**
2. Измените на `elemental-blast` (если доступно)
3. URL станет: `https://elemental-blast.netlify.app`

## 🔍 Проверка работы

### После первого деплоя:

1. Откройте Actions на GitHub
2. Дождитесь завершения workflow "Godot Web Export"
3. В логах должно быть:
   ```
   Deploy to Netlify: ✅
   Website URL: https://elemental-blast-xxxxx.netlify.app
   ```

### Откройте игру:

1. Перейдите по URL из Netlify
2. Должен показаться индикатор "Загрузка игры..."
3. Игра должна загрузиться и запуститься!

### Проверка заголовков:

```bash
curl -I https://elemental-blast-xxxxx.netlify.app | grep -E "Cross-Origin"
```

Должны быть:
```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

## 📱 Тестирование на телефоне

1. Откройте URL Netlify на телефоне
2. Игра должна загрузиться в полноэкранном режиме
3. Touch-управление должно работать

**Сохраните URL в закладки!**

## 🎯 Преимущества Netlify vs GitHub Pages

| Функция | GitHub Pages | Netlify |
|---------|-------------|---------|
| HTTP-заголовки (COOP/COEP) | ❌ Не поддерживает | ✅ Полная поддержка |
| Godot 4.x работает | ❌ Не работает | ✅ Работает отлично |
| Скорость деплоя | ~5-10 минут | ~1-2 минуты |
| Cache invalidation | Медленно | Мгновенно |
| Бесплатный трафик | 100 GB/мес | 100 GB/мес |
| CDN | Средний | Отличный |
| Custom domains | ✅ | ✅ |
| Автодеплой | ✅ | ✅ |

## 🔄 Рабочий процесс после настройки

```bash
# 1. Внесите изменения
# 2. Commit и Push
git add . && git commit -m "Изменения" && git push

# 3. GitHub Actions автоматически:
#    - Соберёт веб-версию
#    - Задеплоит на GitHub Pages (для истории)
#    - Задеплоит на Netlify (основной)

# 4. Через 1-2 минуты:
#    - Netlify URL обновится
#    - Тестируйте на телефоне!
```

## 🐛 Решение проблем

### Ошибка: "Missing NETLIFY_AUTH_TOKEN"

**Решение:** Проверьте, что добавили секрет в GitHub:
- Settings → Secrets and variables → Actions
- Секрет должен называться точно `NETLIFY_AUTH_TOKEN`

### Ошибка: "Site not found"

**Решение:** Проверьте NETLIFY_SITE_ID:
- Скопируйте ID из Site settings → Site information
- Обновите секрет в GitHub

### Деплой завершается, но игра не работает

**Решение:** Проверьте заголовки:
```bash
curl -I https://ваш-сайт.netlify.app | grep Cross-Origin
```

Если заголовков нет - проверьте, что файл `netlify.toml` в корне репозитория.

### Netlify показывает старую версию

**Решение:** Очистите кэш:
1. Netlify Dashboard → Site → Deploys
2. Trigger deploy → Clear cache and deploy site

## ✨ Дополнительные возможности Netlify

### Analytics (платно, но есть trial)
- Просмотр трафика
- География игроков
- Популярные страницы

### Functions (для мультиплеера в будущем)
- Serverless функции
- Можно сделать онлайн-лидерборд
- Сохранение прогресса в облаке

### Forms (для обратной связи)
- Встроенная обработка форм
- Без бэкенда

## 📊 Мониторинг

### Netlify Dashboard:
- **Deploys** - история деплоев
- **Functions** - если используете
- **Analytics** - статистика (платно)
- **Logs** - логи деплоев

### GitHub Actions:
- Проверка статуса сборки
- Логи каждого шага
- Комментарии к PR с URL деплоя

## 🎉 Готово!

После настройки у вас будет:

✅ Автоматический деплой на Netlify при каждом push
✅ Рабочая игра с правильными HTTP-заголовками
✅ Быстрый CDN для мгновенной загрузки
✅ Комментарии в PR с preview URL
✅ Резервный деплой на GitHub Pages

**Ссылка на игру:** `https://elemental-blast-xxxxx.netlify.app`

---

**Вопросы?** Смотрите `.github/TROUBLESHOOTING.md`
