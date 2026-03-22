# ⚡ Netlify - Быстрая настройка (ОПЦИОНАЛЬНО)

## 🎯 Обновление

**Игра теперь работает на GitHub Pages!** Потоки отключены для совместимости.

**Netlify нужен только если вам требуется:**
- Максимальная производительность (поддержка threads)
- Кастомный домен
- Продвинутые функции (A/B тесты, формы, serverless)

## 📋 Пошаговая инструкция

### 1. Регистрация (1 минута)

1. Откройте: https://app.netlify.com/signup
2. Нажмите **Continue with GitHub**
3. Авторизуйтесь

### 2. Создание сайта (2 минуты)

1. **Add new site** → **Import an existing project**
2. **Deploy with GitHub**
3. Выберите `Fadeyin/Elemental_Blast`
4. Настройки:
   ```
   Branch: gh-pages
   Build command: (оставьте пустым)
   Publish directory: ./
   ```
5. **Deploy Elemental_Blast**

### 3. Получение токенов (1 минута)

#### NETLIFY_AUTH_TOKEN:
1. https://app.netlify.com/user/applications
2. **New access token**
3. Описание: `GitHub Actions`
4. **Generate** и скопируйте токен

#### NETLIFY_SITE_ID:
1. Откройте ваш сайт в Netlify
2. **Site settings**
3. Скопируйте **Site ID** (под Site information)

### 4. Добавление секретов в GitHub (1 минута)

1. https://github.com/Fadeyin/Elemental_Blast/settings/secrets/actions
2. **New repository secret**

**Первый секрет:**
```
Name: NETLIFY_AUTH_TOKEN
Value: (ваш токен из шага 3)
```

**Второй секрет:**
```
Name: NETLIFY_SITE_ID
Value: (ваш Site ID из шага 3)
```

### 5. Запуск деплоя

После мерджа PR или сделайте:
```bash
git commit --allow-empty -m "Deploy to Netlify"
git push
```

## ✅ Готово!

Через 1-2 минуты игра будет доступна по адресу:
```
https://elemental-blast-xxxxx.netlify.app
```

Найдите URL в:
- Netlify Dashboard → ваш сайт → URL вверху
- Или в GitHub Actions → Deploy to Netlify → Website URL

## 🎮 Тестирование

1. Откройте URL на телефоне
2. Игра должна загрузиться!
3. Сохраните в закладки

## 💡 Дополнительно

### Красивое имя:
В Netlify: **Domain settings** → **Edit site name** → введите `elemental-blast`
URL станет: `https://elemental-blast.netlify.app`

### Автодеплой:
Уже настроен! Каждый `git push` → автоматический деплой на Netlify.

---

**Подробная инструкция:** `.github/NETLIFY_SETUP.md`
