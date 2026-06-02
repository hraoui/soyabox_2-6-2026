#!/bin/bash

# SOYABOX POS - Database Reset Script
# This script resets the local Isar database and seeder flag
# Use this when admin users are missing or corrupted

echo "🗑️  SOYABOX POS Database Reset"
echo "================================"
echo ""

# Find all possible application support directories for SOYABOX
APP_DIRS=$(find ~/Library/Application\ Support -type d -name "*soyabox*" -o -name "*caisse*" 2>/dev/null)

if [ -z "$APP_DIRS" ]; then
    echo "⚠️  No SOYABOX application directories found in ~/Library/Application Support"
    echo "   The app may not have been run yet, or uses a different path."
    echo ""
    echo "Searching in common Flutter macOS paths..."
    
    # Check common Flutter macOS paths
    COMMON_PATHS=(
        "~/Library/Application Support/com.soyabox.caisse1"
        "~/Library/Application Support/caisse_1"
        "~/Library/Containers/com.soyabox.caisse1/Data/Library/Application Support"
    )
    
    for path in "${COMMON_PATHS[@]}"; do
        expanded_path=$(eval echo $path)
        if [ -d "$expanded_path" ]; then
            APP_DIRS="$APP_DIRS $expanded_path"
            echo "✅ Found: $expanded_path"
        fi
    done
fi

if [ -z "$APP_DIRS" ]; then
    echo "❌ Could not find any SOYABOX directories."
    echo "   Please run the app at least once first, then try again."
    exit 1
fi

echo "📂 Found application directories:"
echo "$APP_DIRS"
echo ""

# Confirm with user
read -p "⚠️  This will DELETE all local data including users, orders, and settings. Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

# Delete each directory
for dir in $APP_DIRS; do
    echo "🗑️  Deleting: $dir"
    rm -rf "$dir"
done

echo ""
echo "✅ Local database deleted successfully!"
echo ""
echo "🚀 Next steps:"
echo "   1. Rebuild the app: flutter clean && flutter pub get"
echo "   2. Run the app: flutter run -d macos"
echo "   3. The seeder will recreate admin users automatically"
echo ""
echo "📋 Default Admin Credentials (after reset):"
echo "   • Super Admin: PIN 'superadmin123' (email: superadmin@soyabox.com)"
echo "   • Admin Casa:  PIN 'casa123' (email: admin.casablanca@soyabox.com)"
echo "   • Admin Moha:  PIN 'moha123' (email: admin.mohammedia@soyabox.com)"
echo ""
