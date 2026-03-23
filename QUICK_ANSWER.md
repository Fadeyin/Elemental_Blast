# ✅ Ответ: Можно ли запускать билд из других веток?

## Да! Теперь доступно 4 способа

---

## 🎯 Способ 1: Ручной запуск (Рекомендуется)

**За 5 кликов:**

1. Откройте: https://github.com/Fadeyin/Elemental_Blast/actions
2. Кликните **"Godot Web Export"**
3. Кликните **"Run workflow"**
4. Выберите **вашу ветку**
5. Отметьте **"Деплоить на Netlify"** → **"Run workflow"**

**Результат:** Через 3-5 минут игра доступна на телефоне!

---

## 🔀 Способ 2: Pull Request (автоматический preview)

```bash
git checkout -b feature/my-feature
git push origin feature/my-feature
# Создайте PR → автоматический preview URL
```

---

## 📦 Способ 3: Скачать артефакт

Запустите workflow без деплоя → скачайте `web-build.zip` → локальный тест

---

## ⚙️ Способ 4: Автоматическая ветка

Добавьте вашу ветку в `.github/workflows/godot-web-export.yml`:

```yaml
on:
  push:
    branches:
      - main
      - cursor/godot-web-9125
      - ваша-ветка  # ← добавьте здесь
```

---

## 📚 Подробная документация

- **Быстрый старт:** `.github/BRANCH_BUILD_QUICKSTART.md`
- **Полное руководство:** `.github/MULTI_BRANCH_BUILD.md`
- **Визуальные схемы:** `.github/MULTI_BRANCH_WORKFLOW_DIAGRAM.md`
- **Краткое резюме:** `.github/MULTI_BRANCH_SUMMARY.md`

---

## 🚀 Начните прямо сейчас!

Попробуйте **Способ 1** (ручной запуск) - это быстрее всего!
