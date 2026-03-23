# 🔀 Запуск билда из других веток

## 📋 Содержание

1. [Автоматический запуск при push](#автоматический-запуск-при-push)
2. [Ручной запуск через workflow_dispatch](#ручной-запуск-через-workflow_dispatch)
3. [Preview деплой для Pull Request](#preview-деплой-для-pull-request)
4. [Настройка веток для деплоя](#настройка-веток-для-деплоя)

---

## 🚀 Способ 1: Автоматический запуск при push

### Как это работает сейчас

Билд **автоматически** запускается при push в ветки:
- `main` - продакшн деплой
- `cursor/godot-web-9125` - тестовая ветка

### Как добавить новую ветку

**Вариант A: Постоянная ветка для автосборки**

Отредактируйте `.github/workflows/godot-web-export.yml`:

```yaml
on:
  push:
    branches:
      - main
      - cursor/godot-web-9125
      - develop              # ← добавьте вашу ветку
      - feature/new-feature  # ← или несколько веток
```

**Вариант B: Автосборка из ВСЕХ веток**

```yaml
on:
  push:
    branches:
      - '**'  # все ветки
```

**Вариант C: Автосборка по паттерну**

```yaml
on:
  push:
    branches:
      - main
      - 'feature/**'   # все ветки начинающиеся с feature/
      - 'hotfix/**'    # все ветки начинающиеся с hotfix/
      - 'release/**'   # все ветки начинающиеся с release/
```

### Где будет деплой

⚠️ **Важно:** Не все push приводят к деплою!

Текущая конфигурация деплоит **только** из `main` и `cursor/godot-web-9125`:

```yaml
- name: Deploy to GitHub Pages
  if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/cursor/godot-web-9125'
```

Чтобы деплоить из других веток, см. [Настройка веток для деплоя](#настройка-веток-для-деплоя).

---

## 🎯 Способ 2: Ручной запуск через workflow_dispatch

### Настройка

Добавьте `workflow_dispatch` в `.github/workflows/godot-web-export.yml`:

```yaml
name: Godot Web Export

on:
  push:
    branches:
      - main
      - cursor/godot-web-9125
  pull_request:
    branches:
      - main
  workflow_dispatch:  # ← добавьте это
    inputs:
      deploy_to_pages:
        description: 'Деплоить на GitHub Pages?'
        required: false
        type: boolean
        default: false
      deploy_to_netlify:
        description: 'Деплоить на Netlify?'
        required: false
        type: boolean
        default: false
```

### Как запустить вручную

1. Откройте GitHub: `https://github.com/Fadeyin/Elemental_Blast/actions`
2. Выберите **"Godot Web Export"** в списке слева
3. Нажмите **"Run workflow"** (справа вверху)
4. Выберите ветку из выпадающего списка
5. Отметьте опции деплоя (если нужно)
6. Нажмите **"Run workflow"**

### Обновление конфигурации с inputs

```yaml
- name: Deploy to GitHub Pages
  if: |
    (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/cursor/godot-web-9125') ||
    (github.event_name == 'workflow_dispatch' && inputs.deploy_to_pages == true)
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web

- name: Deploy to Netlify
  if: |
    (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/cursor/godot-web-9125') ||
    (github.event_name == 'workflow_dispatch' && inputs.deploy_to_netlify == true)
  uses: nwtgck/actions-netlify@v3
  with:
    publish-dir: './build/web'
    production-deploy: true
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

---

## 🔍 Способ 3: Preview деплой для Pull Request

### Что это

При создании Pull Request из любой ветки автоматически создаётся **preview** версия на Netlify с уникальным URL.

### Как это работает

Уже настроено! При создании PR:

1. GitHub Actions собирает билд
2. Netlify создаёт preview деплой
3. URL доступен в комментарии к PR

**Пример URL:**
```
https://deploy-preview-8--elemental-blast.netlify.app
```

### Настройка для GitHub Pages (preview через gh-pages-preview)

Для множественных preview на GitHub Pages нужно использовать альтернативный подход:

```yaml
- name: Deploy PR Preview to GitHub Pages
  if: github.event_name == 'pull_request'
  uses: rossjrw/pr-preview-action@v1
  with:
    source-dir: ./build/web
    preview-branch: gh-pages-preview
    umbrella-dir: pr-preview
```

**URL preview:** `https://fadeyin.github.io/Elemental_Blast/pr-preview/pr-8/`

---

## ⚙️ Способ 4: Настройка веток для деплоя

### Сценарий A: Деплой из всех веток

```yaml
- name: Deploy to GitHub Pages
  if: github.event_name == 'push'  # любой push (не PR)
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
```

⚠️ **Осторожно:** Каждый push перезапишет продакшн сайт!

### Сценарий B: Отдельные деплои для разных веток

Используйте разные сайты для разных веток:

```yaml
- name: Deploy Main to Production
  if: github.ref == 'refs/heads/main'
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
    publish_branch: gh-pages  # продакшн

- name: Deploy Develop to Staging
  if: github.ref == 'refs/heads/develop'
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
    publish_branch: gh-pages-staging  # staging
    destination_dir: staging
```

**URL:**
- Продакшн: `https://fadeyin.github.io/Elemental_Blast/`
- Staging: `https://fadeyin.github.io/Elemental_Blast/staging/`

### Сценарий C: Netlify с разными окружениями

Создайте отдельные Netlify сайты для staging:

```yaml
- name: Deploy to Netlify Production
  if: github.ref == 'refs/heads/main'
  uses: nwtgck/actions-netlify@v3
  with:
    publish-dir: './build/web'
    production-deploy: true
    alias: production
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}

- name: Deploy to Netlify Staging
  if: github.ref == 'refs/heads/develop'
  uses: nwtgck/actions-netlify@v3
  with:
    publish-dir: './build/web'
    production-deploy: true
    alias: staging
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_STAGING_SITE_ID }}  # другой сайт
```

### Сценарий D: Деплой по тегам

Деплой только при создании релизных тегов:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # v1.0.0, v2.1.3, и т.д.

- name: Deploy Release
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
```

---

## 📝 Примеры использования

### Пример 1: Разработка в feature ветке

**Задача:** Протестировать изменения из ветки `feature/new-level` на телефоне.

**Решение:**

```bash
# 1. Переключитесь на ветку
git checkout feature/new-level

# 2. Внесите изменения и закоммитьте
git add .
git commit -m "Добавлен новый уровень"

# 3. Запушьте ветку
git push origin feature/new-level

# 4. Создайте Pull Request на GitHub
# GitHub Actions автоматически создаст preview на Netlify

# 5. Откройте preview URL на телефоне (из комментария в PR)
```

**Альтернатива с ручным запуском:**

```bash
# 1-3 те же шаги

# 4. Откройте GitHub Actions и запустите workflow вручную
#    - Выберите ветку: feature/new-level
#    - Отметьте "Деплоить на Netlify"
#    - Нажмите "Run workflow"

# 5. Дождитесь завершения и откройте на телефоне
```

### Пример 2: Staging окружение

**Задача:** Создать постоянное staging окружение для ветки `develop`.

**Решение:**

Добавьте в workflow:

```yaml
on:
  push:
    branches:
      - main
      - develop  # staging ветка

- name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
    destination_dir: .

- name: Deploy to Staging
  if: github.ref == 'refs/heads/develop'
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
    destination_dir: staging
```

**Использование:**

```bash
# Работа над фичей
git checkout develop
git add .
git commit -m "Новая фича"
git push origin develop

# Проверка на staging
open https://fadeyin.github.io/Elemental_Blast/staging/

# Готово? Мердж в main
git checkout main
git merge develop
git push origin main

# Автоматический деплой на продакшн
open https://fadeyin.github.io/Elemental_Blast/
```

### Пример 3: Быстрый тест без деплоя

**Задача:** Собрать билд из любой ветки БЕЗ деплоя, скачать артефакт.

**Решение:**

```bash
# 1. Запустите workflow вручную (workflow_dispatch)
#    - Выберите нужную ветку
#    - НЕ отмечайте опции деплоя
#    - Run workflow

# 2. Дождитесь завершения

# 3. Скачайте артефакт:
#    Actions → выберите запуск → Artifacts → web-build (zip)

# 4. Распакуйте и запустите локально:
cd ~/Downloads
unzip web-build.zip
python3 -m http.server 8000

# 5. Откройте на телефоне (если в одной сети):
#    http://ваш-ip:8000
```

---

## 🛠️ Готовые конфигурации

### Конфигурация 1: Простая (одна продакшн ветка)

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:  # ручной запуск из любой ветки

- name: Deploy to GitHub Pages
  if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
```

**Плюсы:** Простая, безопасная  
**Минусы:** Ручной запуск для тестов

### Конфигурация 2: Продакшн + Staging

```yaml
on:
  push:
    branches:
      - main
      - develop

- name: Deploy Production
  if: github.ref == 'refs/heads/main'
  # ... деплой на https://fadeyin.github.io/Elemental_Blast/

- name: Deploy Staging
  if: github.ref == 'refs/heads/develop'
  # ... деплой на https://fadeyin.github.io/Elemental_Blast/staging/
```

**Плюсы:** Постоянный staging  
**Минусы:** Нужно следить за двумя окружениями

### Конфигурация 3: PR Preview + Продакшн

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

- name: Deploy Production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  # ... деплой на продакшн

- name: Deploy PR Preview
  if: github.event_name == 'pull_request'
  # ... preview на Netlify
```

**Плюсы:** Автоматический preview для PR  
**Минусы:** Требует настройки Netlify

### Конфигурация 4: Максимальная гибкость

```yaml
on:
  push:
    branches:
      - main
      - develop
      - 'feature/**'
  pull_request:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options:
          - none
          - production
          - staging
          - preview

- name: Build
  # всегда собирается

- name: Deploy
  if: |
    (github.ref == 'refs/heads/main' && github.event_name == 'push') ||
    (github.ref == 'refs/heads/develop' && github.event_name == 'push') ||
    (github.event_name == 'pull_request') ||
    (github.event_name == 'workflow_dispatch' && inputs.environment != 'none')
  # ... условный деплой
```

**Плюсы:** Полный контроль  
**Минусы:** Сложная конфигурация

---

## ✅ Рекомендации

### Для быстрых тестов

Используйте **Netlify PR Preview**:
- Создавайте PR из любой ветки
- Netlify автоматически создаст уникальный URL
- Тестируйте на телефоне
- Закройте PR если не нужен мердж

### Для постоянного staging

Используйте **отдельную ветку `develop`**:
- Настройте деплой в поддиректорию `/staging/`
- Всегда доступен по фиксированному URL
- Мерджите в `main` для продакшн деплоя

### Для экспериментов

Используйте **workflow_dispatch**:
- Запускайте вручную из любой ветки
- Выбирайте деплоить или нет
- Скачивайте артефакты для локального теста

---

## 🔗 Полезные ссылки

- [GitHub Actions: Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [Netlify Deploy Previews](https://docs.netlify.com/site-deploys/deploy-previews/)
- [GitHub Pages: Deployment branches](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

---

## 📊 Сравнительная таблица

| Способ | Автоматический | Из любой ветки | Preview URL | Сложность |
|--------|---------------|----------------|-------------|-----------|
| Push в main/develop | ✅ | ❌ | ❌ | ⭐ |
| Push в feature/** | ✅ | ✅ | ❌ | ⭐⭐ |
| workflow_dispatch | ❌ (ручной) | ✅ | опционально | ⭐⭐ |
| Pull Request | ✅ | ✅ | ✅ (Netlify) | ⭐⭐⭐ |
| PR Preview Action | ✅ | ✅ | ✅ (GH Pages) | ⭐⭐⭐⭐ |

---

**Что выбрать?**

- Простота → **workflow_dispatch** (ручной запуск)
- Автоматизация → **Pull Request + Netlify**
- Staging → **отдельная ветка develop**
- Гибкость → **комбинация всех способов**
