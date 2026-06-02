# 📋 COMPTES ADMIN - IDENTIFIANTS DE CONNEXION

## ✅ Comptes disponibles (UserSeeder)

### 🔶 Super Admin

| Champ | Valeur |
|-------|--------|
| **Rôle** | `superadmin` |
| **Téléphone** | `0600000000` |
| **Email** | `superadmin@soyabox.com` |
| **Mot de passe** | `superadmin123` |
| **PIN Code** | `null` (pas de PIN) |
| **Restaurant** | `null` (tous les restaurants) |
| **Permissions** | ✅ TOUS les restaurants, TOUS les utilisateurs |

---

### 🟢 Admin Casablanca

| Champ | Valeur |
|-------|--------|
| **Rôle** | `admin` |
| **Téléphone** | `0611111111` |
| **Email** | `admin.casablanca@soyabox.com` |
| **Mot de passe** | `casa123` |
| **PIN Code** | `1111` |
| **Restaurant** | `1` (Casablanca) |
| **Permissions** | ✅ Restaurant 1 uniquement, utilisateurs de Casa |

---

### 🔵 Admin Mohammedia

| Champ | Valeur |
|-------|--------|
| **Rôle** | `admin` |
| **Téléphone** | `0622222222` |
| **Email** | `admin.mohammedia@soyabox.com` |
| **Mot de passe** | `moha123` |
| **PIN Code** | `2222` |
| **Restaurant** | `2` (Mohammedia) |
| **Permissions** | ✅ Restaurant 2 uniquement, utilisateurs de Moha |

---

## 🚀 Comment se connecter

### 1. Lancer l'application

```bash
cd /Users/macbookpro/Documents/caisse1-main

flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=202|rcijFRypRHMJpJBmVoJgG1M53l8XGsvxpItNpuGu9ba2bf54
```

### 2. Écran de login

**Option A : Connexion par téléphone/mot de passe**

```
Téléphone: 0600000000
Mot de passe: superadmin123
```

**Option B : Connexion par PIN code** (admin/staff uniquement)

```
PIN Code: 1111  (pour Admin Casa)
PIN Code: 2222  (pour Admin Moha)
```

---

## 📊 Tableau récapitulatif

| Rôle | Téléphone | Email | Mot de passe | PIN | Restaurant |
|------|-----------|-------|--------------|-----|------------|
| **Super Admin** | `0600000000` | `superadmin@soyabox.com` | `superadmin123` | - | Tous |
| **Admin Casa** | `0611111111` | `admin.casablanca@soyabox.com` | `casa123` | `1111` | 1 (Casa) |
| **Admin Moha** | `0622222222` | `admin.mohammedia@soyabox.com` | `moha123` | `2222` | 2 (Moha) |

---

## 🔍 Vérification dans la base de données

### Backend Laravel

```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

// Voir tous les utilisateurs
>>> App\Models\User::all(['id', 'name', 'phone', 'email', 'role', 'restaurant_id'])

// Vérifier Super Admin
>>> App\Models\User::where('phone', '0600000000')->first()

// Vérifier Admin Casa
>>> App\Models\User::where('phone', '0611111111')->first()

// Vérifier Admin Moha
>>> App\Models\User::where('phone', '0622222222')->first()
```

### Flutter Local (Isar)

```dart
// Dans la console DevTools ou code temporaire
import 'package:caisse_1/services/database_service.dart';

final users = await DatabaseService.getAllUsers();
users.forEach((u) {
  print('${u.name} | ${u.phone} | ${u.email} | ${u.role}');
});

// Doit afficher:
// Super Admin | 0600000000 | superadmin@soyabox.com | superadmin
// Admin Casablanca | 0611111111 | admin.casablanca@soyabox.com | admin
// Admin Mohammedia | 0622222222 | admin.mohammedia@soyabox.com | admin
```

---

## 🧪 Tests de validation

### Test 1 : Login Super Admin

```
Téléphone: 0600000000
Mot de passe: superadmin123

Résultat attendu:
✅ Login réussi
✅ Voit TOUS les restaurants
✅ Voit TOUS les utilisateurs
✅ Peut tout modifier
```

### Test 2 : Login Admin Casa

```
Téléphone: 0611111111
Mot de passe: casa123

Résultat attendu:
✅ Login réussi
✅ Voit restaurant 1 (Casa)
✅ Voit utilisateurs de Casa
❌ Ne voit PAS restaurant 2 (Moha)
```

### Test 3 : Login Admin Moha

```
Téléphone: 0622222222
Mot de passe: moha123

Résultat attendu:
✅ Login réussi
✅ Voit restaurant 2 (Moha)
✅ Voit utilisateurs de Moha
❌ Ne voit PAS restaurant 1 (Casa)
```

### Test 4 : Login PIN Admin Casa

```
PIN Code: 1111

Résultat attendu:
✅ Login réussi
✅ Voit restaurant 1 (Casa)
```

### Test 5 : Login PIN Admin Moha

```
PIN Code: 2222

Résultat attendu:
✅ Login réussi
✅ Voit restaurant 2 (Moha)
```

---

## 🔒 Sécurité

### Mots de passe

Les mots de passe sont hashés avec **bcrypt** avant stockage :

```dart
// Dans User.hashPassword()
static String hashPassword(String password) {
  // Utilise bcrypt pour hasher le mot de passe
  return BCrypt.hashpw(password, BCrypt.gensalt());
}
```

### PIN Codes

Les PIN codes sont stockés en **clair** dans la base de données (pour login rapide) :

```dart
// Dans le seeder
pinCode: '1111',  // Stocké tel quel
```

**Recommandation :** En production, hasher aussi les PIN codes.

---

## 📝 Fichier modifié

**Fichier :** `lib/seeders/user_seeder.dart`

**Modifications :**
- ✅ Téléphones formatés en `0600000000` (pas de `+212`)
- ✅ PIN codes ajoutés pour les admins (`1111`, `2222`)
- ✅ Emails et mots de passe mis à jour

---

## 🐛 Dépannage

### Problème : "Identifiants incorrects"

**Cause :** Le seeder n'a pas encore été exécuté ou les identifiants sont wrong.

**Solution :**
```bash
# 1. Vérifier si les utilisateurs existent dans Flutter
# (nécessite un rebuild complet)

# 2. Supprimer les données locales et rebuild
flutter clean
flutter pub get
flutter run

# 3. Le seeder va recréer les 3 utilisateurs
```

### Problème : "PIN code invalide"

**Cause :** Le PIN code a été modifié ou n'existe pas.

**Vérification :**
```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> App\Models\User::where('pin_code', '1111')->first()
// Doit retourner Admin Casablanca
```

### Problème : "Accès refusé : Cet utilisateur appartient à un autre restaurant"

**Cause :** Vous essayez de connecter un admin avec un restaurant différent de celui importé.

**Solution :**
- Utiliser le Super Admin (`0600000000`) qui n'a pas de restriction
- OU importer le bon restaurant pour l'admin

---

## ✅ Checklist de validation

- [x] Super Admin existe avec téléphone `0600000000`
- [x] Admin Casa existe avec téléphone `0611111111`
- [x] Admin Moha existe avec téléphone `0622222222`
- [x] Emails corrects (`@soyabox.com`)
- [x] Mots de passe corrects (`superadmin123`, `casa123`, `moha123`)
- [x] PIN codes corrects (`1111`, `2222`)
- [x] Restaurant IDs corrects (`null`, `1`, `2`)
- [x] 0 erreur de compilation

---

**Date :** 2025-04-02  
**Statut :** ✅ **MIS À JOUR**  
**Version :** 1.0.2
