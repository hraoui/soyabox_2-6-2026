/// Centralized display labels for order channels and fulfillment types.
/// Used ONLY for UI display -- does not affect business logic or stored values.
class OrderDisplayLabels {
  /// Channel display label mapping (for UI only)
  /// pos → Caisse, api → Mobile, web → Site Web, kiosk → Kiosque
  static String channelLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pos':
        return 'Caisse';
      case 'api':
        return 'Mobile';
      case 'web':
        return 'Site Web';
      case 'kiosk':
        return 'Kiosque';
      default:
        return value.toUpperCase();
    }
  }

  /// Fulfillment type display label mapping (for UI only)
  /// on_site → Sur place, pickup → Emporter, delivery → Livraison
  static String typeLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'on_site':
        return 'Sur place';
      case 'pickup':
        return 'Emporter';
      case 'delivery':
        return 'Livraison';
      default:
        return value;
    }
  }
}
