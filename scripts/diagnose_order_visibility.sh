#!/bin/bash

# ============================================================
# Script de Diagnostic: Visibilité Commandes & Synchronisation
# ============================================================

echo "🔍 Diagnostic: Visibilité des Commandes et Synchronisation"
echo "=========================================================="
echo ""

# 1. Vérifier les fichiers modifiés
echo "📁 1. Vérification des fichiers modifiés..."
if [ -f "lib/controllers/pos_controller.dart" ]; then
    echo "   ✅ pos_controller.dart existe"
    
    # Vérifier la présence du fix de visibilité
    if grep -q "POS order from same restaurant" lib/controllers/pos_controller.dart; then
        echo "   ✅ Fix visibilité restaurant appliqué"
    else
        echo "   ❌ Fix visibilité restaurant MANQUANT"
    fi
    
    # Vérifier le fix paymentMethod
    if grep -q "resolvedPaymentMethod" lib/controllers/pos_controller.dart; then
        echo "   ✅ Fix paymentMethod par défaut appliqué"
    else
        echo "   ❌ Fix paymentMethod MANQUANT"
    fi
else
    echo "   ❌ pos_controller.dart introuvable"
fi

if [ -f "lib/services/sync_queue_service.dart" ]; then
    echo "   ✅ sync_queue_service.dart existe"
    
    # Vérifier la simplification de _shouldSyncOrderUpsert
    if grep -A 8 "_shouldSyncOrderUpsert" lib/services/sync_queue_service.dart | grep -q "if (order.isFromApi) return false"; then
        echo "   ✅ Simplification logique sync appliquée"
    else
        echo "   ❌ Logique sync NON corrigée"
    fi
else
    echo "   ❌ sync_queue_service.dart introuvable"
fi

echo ""

# 2. Vérifier la base de données locale (si accessible)
echo "🗄️  2. Vérification base de données locale..."
DB_PATH="$HOME/Library/Containers/com.soyabox.pos/Data/Library/Application Support/com.soyabox.pos/default.isar"

if [ -f "$DB_PATH" ]; then
    echo "   ✅ Base de données Isar trouvée"
    echo "   📊 Taille: $(du -h "$DB_PATH" | cut -f1)"
else
    echo "   ⚠️  Base de données non trouvée (app peut-être pas lancée)"
fi

echo ""

# 3. Vérifier la queue de synchronisation
echo "🔄 3. Vérification queue de synchronisation..."
QUEUE_FILE="$HOME/Library/Containers/com.soyabox.pos/Data/Library/Application Support/com.soyabox.pos/sync_queue.json"

if [ -f "$QUEUE_FILE" ]; then
    QUEUE_SIZE=$(cat "$QUEUE_FILE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "erreur")
    echo "   ✅ Queue trouvée: $QUEUE_SIZE commandes en attente"
    
    if [ "$QUEUE_SIZE" != "erreur" ] && [ "$QUEUE_SIZE" -gt 0 ]; then
        echo "   ⚠️  ATTENTION: $QUEUE_SIZE commandes bloquées dans la queue"
        echo "   💡 Conseil: Vérifiez les logs pour les erreurs de synchronisation"
    fi
else
    echo "   ℹ️  Queue vide ou inexistante (normal si tout est synchronisé)"
fi

echo ""

# 4. Vérifier les logs récents
echo "📋 4. Recherche d'erreurs critiques dans les logs..."
LOG_PATTERN="Library/Logs/com.soyabox.pos/*.log"
LOG_FILES=$(ls ~/Library/Logs/com.soyabox.pos/*.log 2>/dev/null | head -1)

if [ -n "$LOG_FILES" ]; then
    LATEST_LOG="$LOG_FILES"
    echo "   📄 Fichier log: $LATEST_LOG"
    
    # Chercher les erreurs SQL
    SQL_ERRORS=$(grep -c "SQLSTATE\|cannot be null" "$LATEST_LOG" 2>/dev/null || echo "0")
    if [ "$SQL_ERRORS" -gt 0 ]; then
        echo "   ❌ $SQL_ERRORS erreurs SQL détectées"
        echo "   🔍 Dernières erreurs:"
        grep "SQLSTATE\|cannot be null" "$LATEST_LOG" | tail -3 | sed 's/^/      /'
    else
        echo "   ✅ Aucune erreur SQL récente"
    fi
    
    # Chercher les succès de sync
    SYNC_SUCCESS=$(grep -c "\[SYNC SUCCESS\]" "$LATEST_LOG" 2>/dev/null || echo "0")
    echo "   ✅ $SYNC_SUCCESS synchronisations réussies"
    
    # Chercher les skips de sync
    SYNC_SKIPS=$(grep -c "\[SYNC SKIP\]" "$LATEST_LOG" 2>/dev/null || echo "0")
    echo "   ℹ️  $SYNC_SKIPS commandes ignorées (déjà synchronisées)"
else
    echo "   ⚠️  Aucun fichier log trouvé"
fi

echo ""

# 5. Résumé et recommandations
echo "📊 5. Résumé et Recommandations"
echo "================================"
echo ""
echo "✅ Corrections appliquées:"
echo "   • Visibilité restaurant-wide pour tous les staffs"
echo "   • Valeur par défaut 'pending' pour paymentMethod"
echo "   • Simplification de la logique de synchronisation"
echo ""
echo "🧪 Tests à effectuer:"
echo "   1. Connecter 2 staffs du même restaurant"
echo "   2. Staff A crée une commande POS"
echo "   3. Vérifier que Staff B voit la commande"
echo "   4. Attendre 60s et vérifier la synchronisation backend"
echo ""
echo "🔍 Logs à surveiller:"
echo "   • '✅ Order #X included: POS order from same restaurant'"
echo "   • '✅ [SYNC SUCCESS] Order #X synced to backend'"
echo "   • '❌ Order #X filtered: wrong restaurant'"
echo ""
echo "📖 Documentation complète:"
echo "   Voir: CORRECTION_VISIBILITE_COMMANDES_SYNC.md"
echo ""
echo "=========================================================="
echo "Diagnostic terminé ✅"
