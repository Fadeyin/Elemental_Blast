# 🌐 Альтернативные варианты хостинга

Помимо GitHub Pages, веб-версию игры можно разместить на различных платформах.

## GitHub Pages (по умолчанию)

✅ **Уже настроено в этом проекте**

**Преимущества:**
- Бесплатно
- Автоматический деплой через Actions
- SSL из коробки
- Высокая скорость

**Недостатки:**
- Ограничение 1 GB на репозиторий
- 100 GB трафика в месяц

## Netlify

### Настройка

1. Зарегистрируйтесь на [netlify.com](https://netlify.com)
2. Подключите GitHub репозиторий
3. Настройте сборку:
   - **Build command**: оставьте пустым (используем GitHub Actions)
   - **Publish directory**: `build/web`
   - **Branch**: `gh-pages`

### Конфигурация (netlify.toml)

```toml
[build]
  publish = "build/web"
  command = ""

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/*"
  [headers.values]
    Cross-Origin-Embedder-Policy = "require-corp"
    Cross-Origin-Opener-Policy = "same-origin"
    Cache-Control = "public, max-age=3600"
```

**Преимущества:**
- Отличная производительность
- Бесплатный план на 100 GB/месяц
- Автоматический SSL
- Предпросмотр для каждого PR
- CDN по всему миру

## Vercel

### Настройка

1. Зарегистрируйтесь на [vercel.com](https://vercel.com)
2. Импортируйте GitHub репозиторий
3. Настройте:
   - **Framework Preset**: Other
   - **Build Command**: оставьте пустым
   - **Output Directory**: `build/web`

### Конфигурация (vercel.json)

```json
{
  "buildCommand": "",
  "outputDirectory": "build/web",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        },
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        }
      ]
    }
  ]
}
```

**Преимущества:**
- Очень быстрый CDN
- Бесплатно до 100 GB трафика
- Автоматические предпросмотры PR
- Отличная аналитика

## Cloudflare Pages

### Настройка

1. Зарегистрируйтесь на [pages.cloudflare.com](https://pages.cloudflare.com)
2. Подключите GitHub
3. Создайте новый проект:
   - **Production branch**: `gh-pages`
   - **Build command**: оставьте пустым
   - **Build output directory**: `build/web`

### Конфигурация (_headers)

Создайте файл `build/web/_headers`:

```
/*
  Cross-Origin-Embedder-Policy: require-corp
  Cross-Origin-Opener-Policy: same-origin
  Cache-Control: public, max-age=3600
```

**Преимущества:**
- Безлимитный трафик (бесплатно!)
- Отличная глобальная CDN
- Высокая скорость
- Автоматический SSL

## Firebase Hosting

### Настройка

```bash
# Установите Firebase CLI
npm install -g firebase-tools

# Войдите в аккаунт
firebase login

# Инициализируйте проект
firebase init hosting
```

### Конфигурация (firebase.json)

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cross-Origin-Embedder-Policy",
            "value": "require-corp"
          },
          {
            "key": "Cross-Origin-Opener-Policy",
            "value": "same-origin"
          }
        ]
      }
    ]
  }
}
```

### Автоматический деплой

Добавьте в `.github/workflows/godot-web-export.yml`:

```yaml
- name: Deploy to Firebase
  if: github.ref == 'refs/heads/main'
  run: |
    npm install -g firebase-tools
    firebase deploy --token "${{ secrets.FIREBASE_TOKEN }}"
```

**Преимущества:**
- Бесплатно до 10 GB хранилища
- 360 MB/день трафика
- Быстрая CDN
- Интеграция с другими сервисами Google

## AWS S3 + CloudFront

### Настройка S3

```bash
# Создайте bucket
aws s3 mb s3://elemental-blast-web

# Включите статический хостинг
aws s3 website s3://elemental-blast-web \
  --index-document index.html

# Загрузите файлы
aws s3 sync build/web/ s3://elemental-blast-web \
  --acl public-read
```

### CloudFront для CDN

1. Создайте CloudFront distribution
2. Origin: ваш S3 bucket
3. Custom headers:
   - `Cross-Origin-Embedder-Policy: require-corp`
   - `Cross-Origin-Opener-Policy: same-origin`

**Преимущества:**
- Полный контроль
- Масштабируемость
- Глобальная CDN

**Недостатки:**
- Платно (от $0.50/месяц)
- Сложнее в настройке

## itch.io

### Настройка

1. Зарегистрируйтесь на [itch.io](https://itch.io)
2. Создайте новый проект (HTML)
3. Загрузите содержимое `build/web/` как ZIP
4. Отметьте "This file will be played in the browser"
5. Установите размер embed: 648x1200

**Преимущества:**
- Специализирован для игр
- Бесплатно
- Встроенная платёжная система
- Сообщество игроков

**Недостатки:**
- Ручная загрузка (без автодеплоя)
- Медленнее GitHub Pages

### Автоматизация деплоя на itch.io

Используйте [butler](https://itch.io/docs/butler/):

```yaml
- name: Deploy to itch.io
  if: github.ref == 'refs/heads/main'
  run: |
    curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
    unzip butler.zip
    chmod +x butler
    ./butler push build/web fadeyin/elemental-blast:web --userversion-file version.txt
  env:
    BUTLER_API_KEY: ${{ secrets.BUTLER_API_KEY }}
```

## Сравнительная таблица

| Платформа       | Бесплатно | Трафик/мес | CDN | Автодеплой | Сложность |
|-----------------|-----------|------------|-----|------------|-----------|
| GitHub Pages    | ✅        | 100 GB     | ✅  | ✅         | Легко     |
| Netlify         | ✅        | 100 GB     | ✅  | ✅         | Легко     |
| Vercel          | ✅        | 100 GB     | ✅  | ✅         | Легко     |
| Cloudflare      | ✅        | Безлимит   | ✅  | ✅         | Легко     |
| Firebase        | ✅        | 10 GB      | ✅  | ⚙️         | Средне    |
| AWS S3          | ❌        | Платно     | ⚙️  | ⚙️         | Сложно    |
| itch.io         | ✅        | ?          | ⚠️  | ⚙️         | Легко     |

**Легенда:**
- ✅ Есть
- ⚙️ Нужна настройка
- ⚠️ Ограниченно
- ❌ Нет

## Рекомендации

### Для разработки и тестирования
**→ GitHub Pages** (уже настроено)
- Простота
- Бесплатно
- Автоматический деплой

### Для продакшена с высокими нагрузками
**→ Cloudflare Pages**
- Безлимитный трафик
- Отличная производительность
- Бесплатно

### Для публикации игры
**→ itch.io**
- Игровое комьюнити
- Платёжная система
- Простая публикация

### Для коммерческого проекта
**→ AWS S3 + CloudFront** или **Vercel**
- Масштабируемость
- Профессиональная поддержка
- Надёжность

## Миграция с GitHub Pages

Если вы решите использовать другой хостинг:

1. Оставьте GitHub Actions для сборки
2. Измените шаг деплоя в `.github/workflows/godot-web-export.yml`
3. Добавьте секреты для выбранной платформы в GitHub Secrets

Пример для Netlify:

```yaml
- name: Deploy to Netlify
  uses: nwtgck/actions-netlify@v2
  with:
    publish-dir: './build/web'
    production-deploy: true
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

## Множественный деплой

Можно деплоить одновременно на несколько платформ:

```yaml
- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web

- name: Deploy to Netlify
  uses: nwtgck/actions-netlify@v2
  with:
    publish-dir: './build/web'
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

---

**Выбирайте платформу под свои нужды! 🚀**
