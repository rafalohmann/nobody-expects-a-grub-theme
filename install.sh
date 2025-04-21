#!/bin/bash

THEME_NAME="SpanishInquisition"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
GRUB_DIR="/boot/grub"
[[ -d /boot/grub2 ]] && GRUB_DIR="/boot/grub2"
THEME_DIR="$GRUB_DIR/themes/$THEME_NAME"

# Ensure running as root
[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

# Backup existing theme if exists
if [ -d "$THEME_DIR" ]; then
    echo "[*] Backing up existing theme"
    mv "$THEME_DIR" "$THEME_DIR-backup-$TIMESTAMP"
fi

# Check grub config tool
GRUB_MKCONFIG=$(command -v grub2-mkconfig || command -v grub-mkconfig)
[[ -z "$GRUB_MKCONFIG" ]] && echo "grub-mkconfig not found" && exit 1

# Copy theme files
mkdir -p "$THEME_DIR"
cp -r ./SpanishInquisition/* "$THEME_DIR"

# Determine DPI scaling
SCALING=1
if command -v hwinfo >/dev/null 2>&1; then
    MONITOR=$(hwinfo --monitor)
    if [ -n "$MONITOR" ]; then
        SIZE=$(echo "$MONITOR" | grep -m 1 Size | sed -n -E 's/ *Size[ :]*([0-9]+)x[0-9]+.*/\\1/p')
        RES=$(echo "$MONITOR" | grep -m 1 Resolution | sed -n -E 's/ *Resolution[ :]*([0-9]+)x[0-9]+.*/\\1/p')
        if [ -n "$SIZE" ] && [ -n "$RES" ]; then
            SCALING=$((RES / SIZE / 3))
            [[ $SCALING -lt 1 ]] && SCALING=1
            [[ $SCALING -gt 4 ]] && SCALING=4
        fi
    fi
else
    echo "[!] hwinfo not found; defaulting to scaling=1"
fi

# Font logic using local Fonts/ directory
FONT_SIZE=$((16 * SCALING))
FONT_FILE="DejaVuSansMono.pf2"
FONT_TTF="Fonts/DejaVuSansMono.ttf"

if [ ! -f "$THEME_DIR/$FONT_FILE" ]; then
    if [ -f "$FONT_TTF" ]; then
        echo "[*] Converting local TTF to PF2 with size $FONT_SIZE..."
        grub-mkfont -s "$FONT_SIZE" -o "$THEME_DIR/$FONT_FILE" "$FONT_TTF"
    else
        echo "[!] Fonts/DejaVuSansMono.ttf not found. Please ensure the font file exists."
        exit 1
    fi
fi

# Apply theme
sed -i '/^GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"$THEME_DIR/theme.txt\"" >> /etc/default/grub

# Rebuild grub config
$GRUB_MKCONFIG -o "$GRUB_DIR/grub.cfg"

echo "[✓] Theme installed with DPI scaling. Reboot to see it."
