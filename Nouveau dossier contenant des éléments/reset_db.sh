#!/bin/bash
# reset_db.sh - Reset local Isar database and seeder flag for SOYABOX POS
# Usage: chmod +x reset_db.sh && ./reset_db.sh

set -e

echo "🗑️  =========================================="
echo "   SOYABOX POS - Database Reset Script"
echo "=========================================="
echo ""

# Define paths
APP_SUPPORT_DIR="$HOME/Library/Application Support"
APP_DATA_DIR="$APP_SUPPORT_DIR/com.soyabox.caisse1"
SEEDER_FLAG_FILES="$APP_SUPPORT_DIR/.user_seeder_has_run_v2*"

echo "📍 Checking paths..."
echo "   App Data: $APP_DATA_DIR"
echo "   Seeder flags: $SEEDER_FLAG_FILES"
echo ""

# Check if files exist
FOUND_DATA=false
FOUND_SEEDER=false

if [ -d "$APP_DATA_DIR" ]; then
    FOUND_DATA=true
fi

# Check for seeder flag files
if ls $SEEDER_FLAG_FILES 1> /dev/null 2>&1; then
    FOUND_SEEDER=true
fi

if [ "$FOUND_DATA" = false ] && [ "$FOUND_SEEDER" = false ]; then
    echo "✅ No local database or seeder flags found."
    echo "   The database is already clean."
    echo ""
    read -p "Do you want to continue anyway? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled."
        exit 0
    fi
fi

# Backup prompt
echo "⚠️  WARNING: This will delete all local data including:"
echo "   • Users (admins, staff, livreurs)"
echo "   • Commands (POS orders)"
echo "   • Products and categories"
echo "   • Tables and customers"
echo "   • Application settings"
echo ""
read -p "Are you sure you want to continue? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting Isar database..."
if [ -d "$APP_DATA_DIR" ]; then
    rm -rf "$APP_DATA_DIR"
    echo "   ✅ Database deleted: $APP_DATA_DIR"
else
    echo "   ⏭️  Database not found, skipping"
fi

echo ""
echo "🗑️  Deleting seeder flag files..."
FOUND_FLAG=false
for file in $SEEDER_FLAG_FILES; do
    if [ -e "$file" ]; then
        rm -f "$file"
        echo "   ✅ Deleted: $file"
        FOUND_FLAG=true
    fi
done
if [ "$FOUND_FLAG" = false ]; then
    echo "   ⏭️  No seeder flag files found, skipping"
fi

echo ""
echo "=========================================="
echo "✅ Database reset complete!"
echo "=========================================="
echo ""
echo "🚀 Next steps:"
echo "   1. Rebuild the app (if needed):"
echo "      flutter build macos --release"
echo ""
echo "   2. Launch the app:"
echo "      open build/macos/Build/Products/Release/caisse_1.app"
echo ""
echo "   3. Login with:"
echo "      • Super Admin → PIN: 2026soya"
echo "      • Admin Casablanca → PIN: soya2026"
echo "      • Admin Mohammedia → PIN: soya2026"
echo ""
echo "📝 The UserSeeder will run on first launch and create:"
echo "   • 1 Super Admin (no restaurant, PIN: 2026soya)"
echo "   • 2 Admins (with restaurants, PIN: soya2026)"
echo ""
