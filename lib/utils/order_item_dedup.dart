import '../models/pos_order_item.dart';

/// Déduplique les items d'une commande en fusionnant les produits identiques.
///
/// Cette fonction est utilisée avant l'affichage pour éviter que les produits
/// apparaissent plusieurs fois dans les détails de commande.
///
/// **IMPORTANT** : Quand il y a plusieurs items avec le même productId,
/// on garde celui qui a la quantité la PLUS ÉLEVÉE (car c'est probablement
/// le vrai, les autres sont des duplications accidentelles).
///
/// On NE SOMME PAS les quantités car cela donnerait des résultats erronés
/// si les items sont des duplications (ex: 22304 duplications = quantité x22304).
List<PosOrderItem> deduplicateOrderItems(List<PosOrderItem> items) {
  if (items.isEmpty) return items;

  final Map<String, PosOrderItem> uniqueItems = {};

  for (final item in items) {
    final key = [
      item.productId,
      item.groupNumber ?? 0,
      item.groupLabel ?? '',
      item.itemNote ?? '',
      item.serviceCourseKey ?? '',
      item.serviceCourseLabel ?? '',
      item.priceType ?? '',
      item.unitPrice.toStringAsFixed(4),
      item.glovoBasePrice?.toStringAsFixed(4) ?? '',
    ].join('|');

    if (uniqueItems.containsKey(key)) {
      final existing = uniqueItems[key]!;
      // Garder l'item avec la quantité la plus élevée (probablement le vrai)
      // Les autres sont des duplications accidentelles de la DB
      if (item.quantity > existing.quantity) {
        uniqueItems[key] = item;
      }
      // Sinon, on garde l'existant (déjà le plus élevé)
    } else {
      uniqueItems[key] = item;
    }
  }

  return uniqueItems.values.toList();
}
