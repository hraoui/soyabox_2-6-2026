# 🐛 Debug - Écran Noir au Démarrage

## Symptôme
L'application démarre (logs visibles) mais **écran noir** après le démarrage.

## Causes Possibles

### 1. Thème ou GetMaterialApp mal configuré
- `glassTheme()` peut retourner un thème avec couleur de fond noire
- `GetMaterialApp` peut avoir un problème de configuration

### 2. Splash Screen qui ne s'affiche pas
- Le timer de 5s peut être trop court
- `Get.offAllNamed('/login')` peut échouer

### 3. Problème de rendu initial
- `SafeArea` peut causer des problèmes de layout
- `AnnotatedRegion` peut interférer avec le rendu

## Solution Testée

Ajout de logs dans `MyApp` :

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    print('📱 [MYAPP] initState called');
  }

  @override
  Widget build(BuildContext context) {
    print('📱 [MYAPP] build() called');
    // ...
  }
}
```

## Prochaines Étapes

1. **Lancer l'application** et observer les logs
2. **Vérifier si `MyApp.build()` est appelé**
3. **Si oui** → Problème dans GetMaterialApp ou thème
4. **Si non** → Problème avant le rendu (blocage dans dependencies)

## Solution de Contournement

Si le problème persiste, essayer :

```dart
// Dans main.dart, remplacer temporairement
runApp(MyApp(initialRoute: initialRoute, isSubWindow: isSubWindow));

// Par un widget minimal pour tester
runApp(MaterialApp(
  home: Scaffold(
    body: Center(child: Text('Test')),
  ),
));
```

Cela permettra de vérifier si Flutter fonctionne correctement.
