# 🛠️ Полезные команды

Список часто используемых команд для работы с проектом.

## Git операции

### Базовый workflow

```bash
# Проверить статус
git status

# Добавить все изменения
git add .

# Создать коммит
git commit -m "Описание изменений"

# Отправить на GitHub (автоматически запустит сборку)
git push

# Полный цикл в одной команде
git add . && git commit -m "Описание изменений" && git push
```

### Работа с ветками

```bash
# Посмотреть текущую ветку
git branch

# Создать новую ветку
git checkout -b feature/new-feature

# Переключиться на другую ветку
git checkout main

# Удалить локальную ветку
git branch -d feature/old-feature

# Обновить локальную копию
git pull
```

### Просмотр истории

```bash
# Посмотреть последние коммиты
git log --oneline -10

# Посмотреть изменения в последнем коммите
git show

# Посмотреть разницу с удалённой веткой
git diff origin/main
```

## GitHub Actions

### Проверка статуса сборки

```bash
# Через GitHub CLI (если установлен)
gh run list --workflow "Godot Web Export"

# Посмотреть последний запуск
gh run view

# Посмотреть логи последней сборки
gh run view --log

# Посмотреть логи конкретного запуска
gh run view <run-id> --log
```

### Ручной запуск workflow

```bash
# Через GitHub CLI
gh workflow run "Godot Web Export"

# Или просто сделайте пустой коммит:
git commit --allow-empty -m "Trigger rebuild"
git push
```

## Локальная разработка

### Запуск локального веб-сервера

```bash
# Через скрипт (рекомендуется)
./serve_local.sh

# Вручную через Python
cd build/web/
python3 -m http.server 8000

# С правильными заголовками
cd build/web/
python3 -c "
import http.server
import socketserver

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        super().end_headers()

with socketserver.TCPServer(('', 8000), MyHTTPRequestHandler) as httpd:
    print('Server on :8000')
    httpd.serve_forever()
"
```

### Узнать локальный IP для тестирования на телефоне

```bash
# Linux/macOS
ip route get 1 | awk '{print $7; exit}'
# или
hostname -I | awk '{print $1}'

# После этого открывайте на телефоне:
# http://<ваш-ip>:8000
```

## Godot Engine

### Экспорт из командной строки (без GUI)

```bash
# Экспорт веб-версии
godot --headless --export-release "Web" build/web/index.html

# Экспорт отладочной версии
godot --headless --export-debug "Web" build/web/index.html

# Проверка версии Godot
godot --version

# Список доступных экспорт-шаблонов
godot --export --list
```

### Проверка проекта

```bash
# Запустить проект
godot project.godot

# Запустить конкретную сцену
godot project.godot --path scenes/main_menu.tscn

# Проверка на ошибки
godot --check-only project.godot
```

## Артефакты и скачивание

### Скачать артефакты через GitHub CLI

```bash
# Список артефактов
gh run list --limit 5

# Скачать артефакт последней сборки
gh run download

# Скачать конкретный артефакт
gh run download <run-id> -n web-build

# Скачать в определённую директорию
gh run download <run-id> -n web-build -D ./downloads/
```

### Распаковка и запуск

```bash
# Распаковать скачанный артефакт
unzip web-build.zip -d build/web/

# Запустить локальный сервер
cd build/web/ && python3 -m http.server 8000
```

## Проверка и отладка

### Проверка размеров файлов

```bash
# Размер собранной веб-версии
du -sh build/web/

# Размеры отдельных файлов
ls -lh build/web/

# Самые большие файлы
ls -lhS build/web/ | head
```

### Проверка workflow файла

```bash
# Проверка YAML синтаксиса (если установлен yamllint)
yamllint .github/workflows/godot-web-export.yml

# Проверка через GitHub CLI
gh workflow view "Godot Web Export"
```

### Очистка кэша

```bash
# Очистить build директорию
rm -rf build/

# Очистить Godot кэш
rm -rf .godot/

# Полная очистка (осторожно!)
git clean -fdx
```

## Тестирование на мобильных устройствах

### QR-код для быстрого доступа

```bash
# Создать QR-код со ссылкой (если установлен qrencode)
echo "https://fadeyin.github.io/Elemental_Blast/" | qrencode -t UTF8

# Или используйте онлайн: https://www.qr-code-generator.com/
```

### Удалённая отладка через Chrome DevTools

```bash
# 1. Подключите Android-устройство через USB
# 2. Включите USB-отладку на телефоне
# 3. Откройте в Chrome на компьютере:
#    chrome://inspect/#devices
# 4. Найдите вкладку с игрой и нажмите "inspect"
```

## Обслуживание

### Обновление Godot версии

```bash
# 1. Откройте .github/workflows/godot-web-export.yml
# 2. Измените GODOT_VERSION: 4.6 на нужную версию
# 3. Commit и push

# Или sed командой:
sed -i 's/GODOT_VERSION: 4.6/GODOT_VERSION: 4.7/' .github/workflows/godot-web-export.yml
git add .github/workflows/godot-web-export.yml
git commit -m "Обновлена версия Godot до 4.7"
git push
```

### Очистка старых workflow runs

```bash
# Через GitHub CLI
gh run list --status completed --limit 100 | \
  awk '{print $7}' | \
  xargs -n1 gh run delete

# Или через веб-интерфейс:
# Actions → Выбрать workflow → ⋮ → Delete workflow run
```

### Проверка лимитов GitHub Actions

```bash
# Посмотреть использование Actions
gh api /repos/Fadeyin/Elemental_Blast/actions/cache/usage

# Лимиты хранилища
gh api /repos/Fadeyin/Elemental_Blast
```

## Быстрые шаблоны коммитов

```bash
# Новая фича
git commit -m "feat: добавлен новый уровень"

# Исправление бага
git commit -m "fix: исправлена коллизия с врагами"

# Рефакторинг
git commit -m "refactor: улучшена структура кода игровой доски"

# Документация
git commit -m "docs: обновлена инструкция по установке"

# Тесты
git commit -m "test: добавлены тесты для системы комбо"

# Производительность
git commit -m "perf: оптимизирована загрузка текстур"

# Стиль/форматирование
git commit -m "style: форматирование кода по стандарту"
```

## Алиасы (добавьте в ~/.bashrc или ~/.zshrc)

```bash
# Git алиасы
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# Проект алиасы
alias serve='./serve_local.sh'
alias build='godot --headless --export-release "Web" build/web/index.html'
alias deploy='git add . && git commit -m "Update" && git push'

# GitHub Actions
alias gh-status='gh run list --workflow "Godot Web Export"'
alias gh-logs='gh run view --log'
alias gh-trigger='git commit --allow-empty -m "Trigger rebuild" && git push'
```

После добавления алиасов:
```bash
source ~/.bashrc  # или ~/.zshrc
```

## Полезные однострочники

```bash
# Быстрый деплой с сообщением
read -p "Commit message: " msg && git add . && git commit -m "$msg" && git push

# Проверить, запущена ли сборка прямо сейчас
gh run list --status in_progress --workflow "Godot Web Export"

# Узнать размер репозитория
git count-objects -vH

# Посмотреть, что изменилось с последнего деплоя
git diff origin/gh-pages

# Откат к предыдущей версии (осторожно!)
git revert HEAD && git push

# Открыть GitHub Pages в браузере
xdg-open https://fadeyin.github.io/Elemental_Blast/  # Linux
open https://fadeyin.github.io/Elemental_Blast/      # macOS
```

## Мониторинг

```bash
# Следить за статусом сборки в реальном времени
watch -n 5 'gh run list --limit 1 --workflow "Godot Web Export"'

# Уведомление при завершении сборки (Linux)
while gh run list --status in_progress --limit 1 | grep -q "in_progress"; do 
  sleep 10
done && notify-send "Сборка завершена!"
```

## Troubleshooting

```bash
# Проверить подключение к GitHub
ssh -T git@github.com

# Сбросить Git кэш
git rm -r --cached .
git add .
git commit -m "Reset cache"

# Проверить remote URL
git remote -v

# Принудительная синхронизация с remote
git fetch --all
git reset --hard origin/main

# Проверка прав доступа к Actions
gh api repos/Fadeyin/Elemental_Blast/actions/permissions
```

---

**Сохраните эту шпаргалку для быстрого доступа!** 📋
