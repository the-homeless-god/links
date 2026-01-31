#!/bin/bash

set -e

# Определяем корневую директорию проекта (где находится скрипт)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Переходим в корневую директорию проекта
cd "${PROJECT_ROOT}"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Параметры
VERSION="${1:-0.1.0}"
APP_NAME="Links API"
DMG_NAME="LinksAPI-${VERSION}.dmg"
TEMP_DIR=$(mktemp -d)
DMG_DIR="${TEMP_DIR}/dmg"
APP_DIR="${DMG_DIR}/${APP_NAME}.app"
EXTENSION_DIR="${DMG_DIR}/Chrome Extension"
POSTINSTALL_SCRIPT="${DMG_DIR}/postinstall.sh"

echo -e "${GREEN}Сборка DMG для macOS${NC}"
echo "Версия: ${VERSION}"
echo "Корневая директория: ${PROJECT_ROOT}"
echo "Временная директория: ${TEMP_DIR}"

# Проверка наличия необходимых инструментов
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Установка create-dmg...${NC}"
    brew install create-dmg || {
        echo -e "${RED}Ошибка: не удалось установить create-dmg${NC}"
        echo "Установите вручную: brew install create-dmg"
        exit 1
    }
fi

# Создание структуры директорий
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"
mkdir -p "${EXTENSION_DIR}"

# Поиск архива релиза
RELEASE_ARCHIVE=$(find elixir_backend/_build/prod -name "links_api-*.tar.gz" | head -1)
if [ -z "$RELEASE_ARCHIVE" ]; then
    echo -e "${RED}Ошибка: не найден архив релиза${NC}"
    echo "Сначала выполните: cd elixir_backend && MIX_ENV=prod mix release"
    exit 1
fi

echo -e "${GREEN}Найден архив: ${RELEASE_ARCHIVE}${NC}"

# Распаковка релиза
echo -e "${GREEN}Распаковка релиза...${NC}"
RELEASE_TEMP=$(mktemp -d)
tar -xzf "${RELEASE_ARCHIVE}" -C "${RELEASE_TEMP}"
RELEASE_DIR=$(find "${RELEASE_TEMP}" -type d -name "links_api-*" | head -1)

if [ -z "$RELEASE_DIR" ]; then
    echo -e "${RED}Ошибка: не удалось найти распакованную директорию релиза${NC}"
    exit 1
fi

echo -e "${GREEN}Директория релиза: ${RELEASE_DIR}${NC}"

# Копирование релиза в .app
cp -r "${RELEASE_DIR}"/* "${APP_DIR}/Contents/MacOS/"

# Создание скрипта запуска приложения
cat > "${APP_DIR}/Contents/MacOS/links_api" << 'EOF'
#!/bin/bash
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"
exec "$APP_DIR/bin/links_api" daemon
EOF
chmod +x "${APP_DIR}/Contents/MacOS/links_api"

# Создание Info.plist для .app
cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>links_api</string>
    <key>CFBundleIdentifier</key>
    <string>com.linksapi.app</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
</dict>
</plist>
EOF

# Сборка расширения Chrome
echo -e "${GREEN}Сборка расширения Chrome...${NC}"
cd extension
if [ ! -d "node_modules" ]; then
    echo "Установка зависимостей расширения..."
    npm install
fi
npm run build:release
cd ..

# Копирование расширения
if [ -d "extension/dist" ]; then
    cp -r extension/dist/* "${EXTENSION_DIR}/"
    echo -e "${GREEN}Расширение скопировано${NC}"
else
    echo -e "${YELLOW}Предупреждение: расширение не собрано, пропускаем${NC}"
fi

# Создание postinstall скрипта
cat > "${POSTINSTALL_SCRIPT}" << 'EOF'
#!/bin/bash

DOCS_URL="https://the-homeless-god.github.io/links/"

echo "=========================================="
echo "  Links API успешно установлен!"
echo "=========================================="
echo ""
echo "Следующие шаги:"
echo ""
echo "1. Запустите приложение:"
echo "   Откройте 'Links API.app' из папки Applications"
echo ""
echo "2. Установите расширение Chrome:"
echo "   - Откройте Chrome и перейдите в chrome://extensions/"
echo "   - Включите 'Режим разработчика'"
echo "   - Нажмите 'Загрузить распакованное расширение'"
echo "   - Выберите папку 'Chrome Extension'"
echo ""
echo "3. Откройте документацию:"
echo "   $DOCS_URL"
echo ""

# Предложение открыть документацию
read -p "Открыть документацию в браузере? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$DOCS_URL"
fi

# Предложение открыть расширения Chrome
read -p "Открыть страницу расширений Chrome? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "chrome://extensions/"
fi

echo ""
echo "Готово! Приятного использования Links API!"
EOF
chmod +x "${POSTINSTALL_SCRIPT}"

# Создание README для DMG
cat > "${DMG_DIR}/README.txt" << 'EOF'
========================================
  Links API - Установка
========================================

СОДЕРЖИМОЕ:

1. Links API.app
   - Приложение Links API
   - Перетащите в папку Applications для установки

2. Chrome Extension
   - Расширение для Chrome браузера
   - См. инструкции по установке ниже

3. postinstall.sh
   - Скрипт установки (запустите после копирования приложения)

УСТАНОВКА:

1. Перетащите "Links API.app" в папку Applications

2. Установите расширение Chrome:
   - Откройте Chrome → chrome://extensions/
   - Включите "Режим разработчика"
   - Нажмите "Загрузить распакованное расширение"
   - Выберите папку "Chrome Extension"

3. Запустите postinstall.sh для получения дополнительных инструкций

ДОКУМЕНТАЦИЯ:
https://the-homeless-god.github.io/links/

ПОДДЕРЖКА:
https://github.com/the-homeless-god/links
EOF

# Создание DMG
echo -e "${GREEN}Создание DMG образа...${NC}"
echo "DMG будет создан в: ${PROJECT_ROOT}/${DMG_NAME}"
echo "Исходная директория: ${DMG_DIR}"

# Упрощенный вызов create-dmg без опциональных параметров
DMG_OUTPUT=$(create-dmg \
    --volname "Links API ${VERSION}" \
    --window-pos 200 120 \
    --window-size 800 500 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 200 190 \
    --icon "Chrome Extension" 400 190 \
    --icon "postinstall.sh" 600 190 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 600 385 \
    "${PROJECT_ROOT}/${DMG_NAME}" \
    "${DMG_DIR}" 2>&1)

DMG_EXIT_CODE=$?

# create-dmg может создавать файл с другим именем (например, master.dmg вместо LinksAPI-0.1.0.dmg)
# Ищем созданный DMG файл
CREATED_DMG=$(find "${PROJECT_ROOT}" -maxdepth 1 -name "*.dmg" -type f -newer "${DMG_DIR}" 2>/dev/null | head -1)

if [ $DMG_EXIT_CODE -eq 0 ] || [ -n "$CREATED_DMG" ]; then
    if [ -n "$CREATED_DMG" ]; then
        # Переименовываем созданный файл в нужное имя
        if [ "$CREATED_DMG" != "${PROJECT_ROOT}/${DMG_NAME}" ]; then
            mv "$CREATED_DMG" "${PROJECT_ROOT}/${DMG_NAME}"
        fi
    fi
    
    if [ -f "${PROJECT_ROOT}/${DMG_NAME}" ]; then
        echo -e "${GREEN}✓ DMG создан: ${PROJECT_ROOT}/${DMG_NAME}${NC}"
        echo "Размер: $(du -h "${PROJECT_ROOT}/${DMG_NAME}" | cut -f1)"
        ls -lh "${PROJECT_ROOT}/${DMG_NAME}"
    else
        echo -e "${YELLOW}Предупреждение: DMG создан, но с другим именем${NC}"
        echo "Вывод create-dmg:"
        echo "$DMG_OUTPUT"
        # Пытаемся найти любой DMG файл в корне
        FOUND_DMG=$(find "${PROJECT_ROOT}" -maxdepth 1 -name "*.dmg" -type f | head -1)
        if [ -n "$FOUND_DMG" ]; then
            echo "Найден DMG файл: $FOUND_DMG"
            mv "$FOUND_DMG" "${PROJECT_ROOT}/${DMG_NAME}"
            if [ -f "${PROJECT_ROOT}/${DMG_NAME}" ]; then
                echo -e "${GREEN}✓ DMG переименован: ${PROJECT_ROOT}/${DMG_NAME}${NC}"
            fi
        else
            echo -e "${RED}Ошибка: DMG файл не найден после создания${NC}"
            exit 1
        fi
    fi
else
    echo -e "${RED}Ошибка при создании DMG${NC}"
    echo "Вывод create-dmg:"
    echo "$DMG_OUTPUT"
    exit 1
fi

# Очистка
rm -rf "${TEMP_DIR}"

echo -e "${GREEN}Готово!${NC}"
