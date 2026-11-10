#!/bin/bash
set -e

APP_NAME="narwhal"
APP_DIR="$HOME/.local/share/Narwhal"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"

echo "Creating directories..."
mkdir -p "$APP_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$ICON_DIR"

echo "Copying build files to $APP_DIR..."
rm -rf "$APP_DIR"/*
cp -r build/linux/x64/release/bundle/* "$APP_DIR/"

echo "Creating symlink in $BIN_DIR..."
ln -sf "$APP_DIR/$APP_NAME" "$BIN_DIR/narwhal"
ln -sf "$APP_DIR/$APP_NAME" "$BIN_DIR/planner"

echo "Copying icons and adapting to current desktop theme..."
cp linux/app_icon_light.png "$APP_DIR/app_icon_light.png" || true
cp linux/app_icon_dark.png "$APP_DIR/app_icon_dark.png" || true

# Determine if the current desktop environment is in dark or light mode
GTK_THEME=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null || echo "")
CIN_THEME=$(gsettings get org.cinnamon.theme name 2>/dev/null || echo "")
IS_DARK=true
if [[ "$GTK_THEME" =~ [Ll]ight ]] && [[ ! "$CIN_THEME" =~ [Nn]okto|[Dd]ark ]]; then
    IS_DARK=false
fi

if [ "$IS_DARK" = true ]; then
    echo "Detected Dark Desktop Theme ($GTK_THEME / $CIN_THEME). Setting high-contrast white monochrome icon."
    cp linux/app_icon_light.png "$APP_DIR/app_icon.png"
    ACTIVE_ICON="linux/app_icon_light.png"
else
    echo "Detected Light Desktop Theme ($GTK_THEME / $CIN_THEME). Setting dark slate monochrome icon."
    cp linux/app_icon_dark.png "$APP_DIR/app_icon.png"
    ACTIVE_ICON="linux/app_icon_dark.png"
fi

cp "$ACTIVE_ICON" "$ICON_DIR/narwhal.png" || true
cp "$ACTIVE_ICON" "$ICON_DIR/com.algorithmx.narwhal.png" || true
cp "$ACTIVE_ICON" "$ICON_DIR/planner.png" || true
cp "$ACTIVE_ICON" "$ICON_DIR/com.algorithmx.planner.png" || true
mkdir -p "$HOME/.local/share/pixmaps"
cp "$ACTIVE_ICON" "$HOME/.local/share/pixmaps/narwhal.png" || true
cp "$ACTIVE_ICON" "$HOME/.local/share/pixmaps/com.algorithmx.narwhal.png" || true
cp "$ACTIVE_ICON" "$HOME/.local/share/pixmaps/planner.png" || true
cp "$ACTIVE_ICON" "$HOME/.local/share/pixmaps/com.algorithmx.planner.png" || true

echo "Creating desktop entry..."
cat <<EOF > "$DESKTOP_DIR/narwhal.desktop"
[Desktop Entry]
Version=1.0
Name=Narwhal : The Smart Planner
GenericName=Smart Planner
Comment=Narwhal: The Smart Planner application
Exec=$APP_DIR/$APP_NAME %U
Icon=$APP_DIR/app_icon.png
Terminal=false
Type=Application
Categories=Office;Utility;
StartupWMClass=com.algorithmx.planner
StartupNotify=true
EOF

ln -sf "$DESKTOP_DIR/narwhal.desktop" "$DESKTOP_DIR/planner.desktop"
ln -sf "$DESKTOP_DIR/narwhal.desktop" "$DESKTOP_DIR/com.algorithmx.planner.desktop"

update-desktop-database "$DESKTOP_DIR" || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" || true

echo "Installation complete! You can now run 'narwhal' from the terminal or your application launcher."
