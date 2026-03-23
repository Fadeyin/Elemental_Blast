#!/bin/bash
# Скрипт для определения версии проекта на основе git-ветки
# 
# Логика версионирования:
# - В main: версия берется из файла VERSION (например, 0.1)
# - В feature-ветках: версия main + последние 5 символов имени ветки (например, 0.1.559b)

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
BASE_VERSION=$(cat VERSION 2>/dev/null || echo "0.1")

if [ "$BRANCH" = "main" ]; then
    echo "$BASE_VERSION"
else
    # Берем последние 5 символов имени ветки, убираем не-алфавитно-цифровые символы в начале
    BRANCH_SUFFIX=$(echo -n "$BRANCH" | tail -c 5 | sed 's/^[^a-zA-Z0-9]*//')
    echo "${BASE_VERSION}.${BRANCH_SUFFIX}"
fi
