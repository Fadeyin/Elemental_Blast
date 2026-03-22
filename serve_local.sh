#!/bin/bash
# Скрипт для локального запуска веб-версии игры
# Полезно для быстрого тестирования без деплоя на GitHub Pages

set -e

PORT=8000
BUILD_DIR="build/web"

echo "🎮 Локальный веб-сервер для Elemental Blast"
echo "=============================================="
echo ""

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 не найден. Установите Python для запуска локального сервера."
    exit 1
fi

# Проверка наличия собранной версии
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Папка $BUILD_DIR не найдена."
    echo ""
    echo "Для локальной сборки:"
    echo "1. Откройте проект в Godot"
    echo "2. Экспортируйте в Web (HTML5)"
    echo "3. Сохраните в папку $BUILD_DIR"
    echo ""
    echo "Или подождите автоматическую сборку на GitHub и скачайте артефакт."
    exit 1
fi

# Запуск веб-сервера с правильными заголовками
echo "✅ Запуск локального веб-сервера..."
echo "📁 Директория: $BUILD_DIR"
echo "🌐 Порт: $PORT"
echo ""
echo "Откройте в браузере:"
echo "  http://localhost:$PORT"
echo ""
echo "Для тестирования на телефоне в локальной сети:"
LOCAL_IP=$(ip route get 1 | awk '{print $7; exit}' 2>/dev/null || echo "получите IP вручную")
echo "  http://$LOCAL_IP:$PORT"
echo ""
echo "Нажмите Ctrl+C для остановки сервера"
echo ""

cd "$BUILD_DIR"

# Запускаем Python сервер с поддержкой COOP/COEP заголовков
python3 -c "
import http.server
import socketserver

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Добавляем необходимые заголовки для Godot Web
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

PORT = $PORT
Handler = MyHTTPRequestHandler

with socketserver.TCPServer(('', PORT), Handler) as httpd:
    print(f'🚀 Сервер запущен на порту {PORT}')
    httpd.serve_forever()
"
