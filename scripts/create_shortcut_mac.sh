#!/bin/bash
# Crée un alias sur le bureau pointant vers l'app installée.
# Usage : bash scripts/create_shortcut_mac.sh "/Applications/Caisse.app" "Caisse POS"

APP_PATH="${1:-/Applications/Caisse.app}"
ALIAS_NAME="${2:-Caisse POS}"

if [ ! -e "$APP_PATH" ]; then
  echo "App introuvable à $APP_PATH. Place l’app dans /Applications ou passe le chemin en 1er argument."
  exit 1
fi

DESKTOP_ALIAS="$HOME/Desktop/${ALIAS_NAME}.app"
rm -f "$DESKTOP_ALIAS"
ln -s "$APP_PATH" "$DESKTOP_ALIAS"
echo "Alias créé : $DESKTOP_ALIAS"

# Rappel : pour apparaître dans Launchpad, l’app doit résider dans /Applications (déjà géré par APP_PATH).
