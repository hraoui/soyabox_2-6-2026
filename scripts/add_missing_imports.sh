#!/bin/bash

# Script pour ajouter les imports manquants dans les fichiers Flutter

echo "🔧 Ajout des imports manquants dans les fichiers..."

# Fichiers à modifier
FILES=(
  "lib/views/admin_delivery_accounting_screen.dart"
  "lib/views/delivery_detail_screen.dart"
  "lib/views/delivery_management_screen.dart"
  "lib/views/login_screen.dart"
  "lib/views/pos_screen.dart"
  "lib/views/pos_staff_orders_screen.dart"
  "lib/views/product_catalog_screen.dart"
  "lib/views/user_management_screen.dart"
  "lib/widgets/creation_success_dialog.dart"
  "lib/widgets/pin_dialog.dart"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "📄 Traitement de $file..."
    
    # Vérifier si l'import existe déjà
    if ! grep -q "import '../theme/app_colors.dart';" "$file"; then
      # Ajouter l'import après les autres imports de theme
      sed -i '' "/import '.*theme.*\.dart';/a\\
import '../theme/app_colors.dart';" "$file" 2>/dev/null || \
      sed -i "s|import '\(.*\)theme\(.*\)\.dart';|import '\1theme\2.dart';\nimport '../theme/app_colors.dart';|" "$file"
    fi
    
    # Vérifier si l'import de responsive_design existe
    if ! grep -q "import '../utils/responsive_design.dart';" "$file"; then
      sed -i '' "/import '.*theme.*\.dart';/a\\
import '../utils/responsive_design.dart';" "$file" 2>/dev/null || \
      sed -i "s|import '\(.*\)theme\(.*\)\.dart';|import '\1theme\2.dart';\nimport '../utils/responsive_design.dart';|" "$file"
    fi
  fi
done

echo "✅ Imports ajoutés !"
echo ""
echo "📊 Exécutez 'flutter analyze' pour vérifier les erreurs restantes."
