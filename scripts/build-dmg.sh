#!/bin/bash
set -e

# Build Voxa.dmg — self-contained distribution for macOS
# Usage: ./scripts/build-dmg.sh

cd "$(dirname "$0")/.."

echo "🔨 Building Voxa (Release)..."
xcodebuild -project TranscriptionApp/TranscriptionApp.xcodeproj \
    -scheme TranscriptionApp \
    -configuration Release \
    -derivedDataPath ./build \
    -arch arm64 \
    CODE_SIGN_IDENTITY="-" \
    ONLY_ACTIVE_ARCH=NO \
    -quiet

APP_PATH="./build/Build/Products/Release/Voxa.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed: Voxa.app not found"
    exit 1
fi

echo "📦 Creating DMG..."
rm -rf dmg_staging
mkdir -p dmg_staging
cp -R "$APP_PATH" dmg_staging/
ln -s /Applications dmg_staging/Applications

rm -f Voxa.dmg
hdiutil create -volname "Voxa" -srcfolder dmg_staging -ov -format UDZO "Voxa.dmg"
rm -rf dmg_staging

DMG_SIZE=$(du -h Voxa.dmg | cut -f1)
echo ""
echo "✅ Voxa.dmg created ($DMG_SIZE)"
echo ""
echo "Installation:"
echo "  1. Open Voxa.dmg"
echo "  2. Drag Voxa to Applications"
echo "  3. Launch Voxa and follow the setup wizard"
