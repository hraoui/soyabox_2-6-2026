# Caisse POS – Workflow & Structure

Ce guide rapide aide à comprendre le fonctionnement pour les utilisateurs métier et les développeurs.

## Pour les utilisateurs
- **Connexion admin/staff (tel + mot de passe)** : écran `login_screen`, ouvre le tableau de bord (admin) ou le POS (staff).
- **Accès rapide POS par PIN** : bouton “Ouvrir le POS avec PIN” sur l’écran de login → saisie PIN sur l’écran POS verrouillé. Un token backend est demandé via `POST /api/login-pin` (si disponible), sinon le POS reste hors‑ligne.
- **Vue restreinte** :
  - Admin/staff voient uniquement les utilisateurs de leur restaurant ; superadmin voit tout.
  - Tables : admin/staff chargent seulement les tables de leur restaurant ; superadmin peut choisir le restaurant.
  - Produits/Catégories : communs (pas de filtre restaurant côté app, comme le backend).
- **Import** : boutons d’import (restaurants, catégories, produits, tables, users) tirent depuis l’API. Les routes users nécessitent un token.
- **Sync commandes** :
  - Upload : toutes les commandes locales (pos, pickup, delivery) partent vers `/api/sync/orders/upsert` dès qu’un token existe.
  - Download : l’app importe aussi les commandes API/web (sauf canal `api` + `on_site` qui est ignoré).
- **Recherche produits** : champ “Rechercher un produit” filtre la grille en temps réel.

## Pour les développeurs
### Tech et structure
- **Flutter** + **GetX** (DI/état/navigation), **Isar** (offline), **http** (API), **path_provider**.
- Dossier clé :
  - `lib/controllers`: logique métier (auth, pos, import, sync…).
  - `lib/services`: API clients, sync, DB locale.
  - `lib/views`: écrans UI (POS, login, admin).
  - `lib/models`: entités Isar (User, Product, Category, PosOrder…).

### Flux d’authentification
- Login standard : `/api/login` avec `phone + password` → token Sanctum propagé à `ApiClient`, `SyncQueueService`, `ApiOrderPullService`, `ImportController`, stocké dans `AuthSessionService`.
- Login PIN (POS) : `PosController.unlockWithPin` → `/api/login-pin` si dispo. Token stocké idem.

### Sync offline/online
- **Upload** : `SyncQueueService` queue les upserts/delete (users, categories, products, orders). Envoi seulement avec token. `client_order_id` = `pos-<local_id>` pour compat.
- **Download** : `ApiOrderPullService` tire `/api/orders` (tous canaux, sauf `api+on_site`), mappe vers Isar.
- La sync auto tourne toutes les 30 s si token présent et DNS OK.

### Données par restaurant
- Users : `UserController.fetchAllUsers` filtre par `restaurantId` de l’utilisateur (superadmin = tous) et rôles admin/staff uniquement.
- Tables : `TableController.loadTables` prend le `restaurantId` courant ; superadmin peut choisir.
- Produits/Catégories : non filtrés (backend commun).

### Variables runtime
- `API_BASE_URL` (dart-define) : URL backend (défaut https://soyabox.ma).
- `API_TOKEN` (dart-define) : token de service optionnel pour forcer la sync.

### Commandes utiles
- Formatage : `dart format lib/**`.
- Analyse : `dart analyze`.
- Build Isar : `flutter pub run build_runner build --delete-conflicting-outputs` (pas nécessaire actuellement car modèles sans restaurantId).

### Bonnes pratiques
- Toujours propager un token valide avant de déclencher la sync (login ou API_TOKEN).
- Superadmin uniquement pour changer de restaurant ou voir tous les utilisateurs.
- En cas d’erreur 401 récurrente : vérifier token/session, puis relancer la sync manuelle.

### Points d’intégration backend
- Auth : `/api/login` (phone+password), `/api/login-pin` (pin_code).
- Sync upload : `/api/sync/{users,categories,products,orders}/{upsert,delete}` (Sanctum).
- Import : `/api/{restaurants,categories,products,tables,users}` (users nécessite token).



########win10#########

Commandes à exécuter dans le terminal Windows
Option 1 : Build automatique (Recommandé)
cd C:\Users\macbookpro\Developer\caisse1-main
scripts\build_windows.bat
Option 2 : Commandes manuelles (étape par étape)
REM 1. Se placer dans le dossier du projet
cd C:\Users\macbookpro\Developer\caisse1-main

REM 2. Installer les dépendances
flutter pub get

REM 3. Build de l'application Windows
flutter build windows --release

REM 4. Créer l'installateur avec Inno Setup
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss

REM 5. Créer les raccourcis (optionnel)
powershell -ExecutionPolicy Bypass -File scripts\create_shortcut_win.ps1
Option 3 : PowerShell
cd C:\Users\macbookpro\Developer\caisse1-main
.\scripts\build_windows.bat
📋 Résultat attendu
Après exécution, vous aurez :

build/windows/x64/runner/Release/caisse_1.exe          ← Exécutable
build/windows/installer/CaissePOS-Setup-1.0.0.exe      ← Installateur
⚡ Commande rapide (copier-coller)
cd C:\Users\macbookpro\Developer\caisse1-main && flutter pub get && flutter build windows --release && "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss
