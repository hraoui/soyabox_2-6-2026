#!/bin/bash

# ============================================
# Script pour générer un token API Laravel
# ============================================

echo "========================================"
echo "  Générateur de token API Laravel"
echo "========================================"
echo ""

# Demander le chemin du backend Laravel
read -p "Chemin complet vers votre backend Laravel (ex: /Users/macbookpro/Developer/laravel-pos) : " BACKEND_PATH

# Vérifier si le chemin existe
if [ ! -d "$BACKEND_PATH" ]; then
    echo "❌ Erreur: Le dossier '$BACKEND_PATH' n'existe pas"
    exit 1
fi

# Vérifier si artisan existe
if [ ! -f "$BACKEND_PATH/artisan" ]; then
    echo "❌ Erreur: Ce n'est pas un projet Laravel (artisan introuvable)"
    exit 1
fi

echo ""
echo "✅ Backend trouvé: $BACKEND_PATH"
echo ""

# Menu
echo "Choisissez une option:"
echo "1. Voir les utilisateurs existants"
echo "2. Créer un token pour un utilisateur existant"
echo "3. Créer un utilisateur admin + token"
echo "4. Tester la connexion API"
echo ""
read -p "Option (1-4) : " OPTION

case $OPTION in
    1)
        echo ""
        echo "📋 Utilisateurs existants :"
        echo "----------------------------------------"
        cd "$BACKEND_PATH"
        php artisan tinker --execute="
            \$users = App\Models\User::all(['id','name','phone','role','is_active']);
            echo 'ID | Name | Phone | Role | Active' . PHP_EOL;
            echo '----------------------------------------' . PHP_EOL;
            foreach (\$users as \$u) {
                echo \$u->id.' | '.\$u->name.' | '.\$u->phone.' | '.\$u->role.' | '.(\$u->is_active ? 'Oui' : 'Non') . PHP_EOL;
            }
        "
        ;;
    
    2)
        read -p "ID de l'utilisateur : " USER_ID
        echo ""
        echo "🔑 Génération du token pour l'utilisateur ID=$USER_ID..."
        cd "$BACKEND_PATH"
        TOKEN=$(php artisan tinker --execute="
            \$user = App\Models\User::find($USER_ID);
            if (!\$user) {
                echo 'ERROR: Utilisateur introuvable';
                exit(1);
            }
            \$user->tokens()->delete();
            \$token = \$user->createToken('pos-sync-token')->plainTextToken;
            echo \$token;
        ")
        
        if [[ $TOKEN == *"ERROR"* ]]; then
            echo "❌ Erreur: $TOKEN"
        else
            echo ""
            echo "========================================"
            echo "  ✅ TOKEN GÉNÉRÉ AVEC SUCCÈS"
            echo "========================================"
            echo ""
            echo "Copiez ce token :"
            echo ""
            echo "  $TOKEN"
            echo ""
            echo "========================================"
            echo ""
            echo "📱 Pour lancer l'application Flutter avec ce token :"
            echo ""
            echo "flutter run -d macos \\"
            echo "  --dart-define=API_BASE_URL=http://localhost:8000 \\"
            echo "  --dart-define=API_TOKEN=$TOKEN"
            echo ""
            echo "Ou copiez-collez le token dans le fichier .env de Flutter si configuré"
            echo ""
        fi
        ;;
    
    3)
        read -p "Nom de l'admin : " ADMIN_NAME
        read -p "Téléphone (10 chiffres) : " ADMIN_PHONE
        read -p "Mot de passe : " -s ADMIN_PASSWORD
        echo ""
        read -p "PIN code (4-6 chiffres) : " ADMIN_PIN
        
        cd "$BACKEND_PATH"
        php artisan tinker --execute="
            \$user = App\Models\User::create([
                'name' => '$ADMIN_NAME',
                'phone' => '$ADMIN_PHONE',
                'password' => bcrypt('$ADMIN_PASSWORD'),
                'pin_code' => '$ADMIN_PIN',
                'role' => 'admin',
                'is_active' => true,
            ]);
            \$token = \$user->createToken('pos-sync-token')->plainTextToken;
            echo '✅ Utilisateur créé avec succès !' . PHP_EOL;
            echo 'Token: ' . \$token;
        "
        ;;
    
    4)
        read -p "URL du backend (ex: http://localhost:8000) : " API_URL
        read -p "Téléphone : " PHONE
        read -p "Mot de passe : " -s PASSWORD
        echo ""
        
        echo ""
        echo "🔐 Test de connexion à $API_URL..."
        RESPONSE=$(curl -s -X POST "$API_URL/api/login" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "{\"phone\":\"$PHONE\",\"password\":\"$PASSWORD\"}")
        
        echo ""
        echo "Réponse:"
        echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
        
        # Extraire le token si succès
        TOKEN=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))" 2>/dev/null)
        
        if [ ! -z "$TOKEN" ]; then
            echo ""
            echo "✅ Token récupéré : $TOKEN"
        fi
        ;;
    
    *)
        echo "❌ Option invalide"
        exit 1
        ;;
esac

echo ""
echo "Appuyez sur Entrée pour quitter..."
read
