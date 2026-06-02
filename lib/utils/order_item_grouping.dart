import '../models/pos_order_item.dart';

class ServiceCourseDescriptor {
  const ServiceCourseDescriptor({
    required this.key,
    required this.label,
    required this.sortOrder,
  });

  final String key;
  final String label;
  final int sortOrder;
}

const ServiceCourseDescriptor serviceCourseStarter = ServiceCourseDescriptor(
  key: 'starter',
  label: 'Entrée',
  sortOrder: 0,
);

const ServiceCourseDescriptor serviceCourseMain = ServiceCourseDescriptor(
  key: 'main',
  label: 'Plat Principal',
  sortOrder: 1,
);

const ServiceCourseDescriptor serviceCourseCheese = ServiceCourseDescriptor(
  key: 'cheese',
  label: 'Suite & Sortie',
  sortOrder: 2,
);

const ServiceCourseDescriptor serviceCourseDessert = ServiceCourseDescriptor(
  key: 'dessert',
  label: 'Dessert',
  sortOrder: 3,
);

const ServiceCourseDescriptor serviceCourseDrink = ServiceCourseDescriptor(
  key: 'drink',
  label: 'Boissons',
  sortOrder: 4,
);

const ServiceCourseDescriptor serviceCourseOther = ServiceCourseDescriptor(
  key: 'other',
  label: 'Autres',
  sortOrder: 5,
);

String cleanOrderItemProductName(String name) {
  return name.startsWith('[LOCAL] ') ? name.substring(8) : name;
}

String normalizeFreeText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed;
}

String? normalizeOptionalFreeText(String? value) {
  final trimmed = normalizeFreeText(value);
  return trimmed.isEmpty ? null : trimmed;
}

String formatGuestGroupLabel({int? groupNumber, String? groupLabel}) {
  final normalizedLabel = normalizeOptionalFreeText(groupLabel);
  if (normalizedLabel != null) {
    return normalizedLabel;
  }
  if (groupNumber != null && groupNumber > 0) {
    return 'Ensemble $groupNumber';
  }
  return 'Sans ensemble';
}

ServiceCourseDescriptor inferServiceCourseFromCategoryName(
  String? categoryName,
) {
  final normalized = normalizeFreeText(categoryName).toLowerCase();
  if (normalized.isEmpty) {
    return serviceCourseMain;
  }

  bool containsAny(List<String> tokens) {
    for (final token in tokens) {
      if (normalized.contains(token)) {
        return true;
      }
    }
    return false;
  }

  if (containsAny(const [
    'entree',
    'entrée',
    'starter',
    'appetizer',
    'hors',
    'mezza',
    'mezze',
    'salad',
    'salade',
    'soup',
    'soupe',
  ])) {
    return serviceCourseStarter;
  }

  if (containsAny(const [
    'dessert',
    'glace',
    'ice',
    'cake',
    'gateau',
    'gâteau',
    'tiramisu',
    'crepe',
    'crêpe',
    'patis',
    'sweet',
    'sucr',
  ])) {
    return serviceCourseDessert;
  }

  if (containsAny(const [
    'boisson',
    'drink',
    'jus',
    'soda',
    'eau',
    'water',
    'coffee',
    'cafe',
    'café',
    'the',
    'thé',
    'tea',
  ])) {
    return serviceCourseDrink;
  }

  return serviceCourseMain;
}

ServiceCourseDescriptor serviceCourseDescriptorForItem(PosOrderItem item) {
  final normalizedKey = normalizeFreeText(item.serviceCourseKey).toLowerCase();
  switch (normalizedKey) {
    case 'starter':
      return ServiceCourseDescriptor(
        key: serviceCourseStarter.key,
        label: normalizeFreeText(item.serviceCourseLabel).isEmpty
            ? serviceCourseStarter.label
            : normalizeFreeText(item.serviceCourseLabel),
        sortOrder: serviceCourseStarter.sortOrder,
      );
    case 'dessert':
      return ServiceCourseDescriptor(
        key: serviceCourseDessert.key,
        label: normalizeFreeText(item.serviceCourseLabel).isEmpty
            ? serviceCourseDessert.label
            : normalizeFreeText(item.serviceCourseLabel),
        sortOrder: serviceCourseDessert.sortOrder,
      );
    case 'drink':
      return ServiceCourseDescriptor(
        key: serviceCourseDrink.key,
        label: normalizeFreeText(item.serviceCourseLabel).isEmpty
            ? serviceCourseDrink.label
            : normalizeFreeText(item.serviceCourseLabel),
        sortOrder: serviceCourseDrink.sortOrder,
      );
    case 'other':
      return ServiceCourseDescriptor(
        key: serviceCourseOther.key,
        label: normalizeFreeText(item.serviceCourseLabel).isEmpty
            ? serviceCourseOther.label
            : normalizeFreeText(item.serviceCourseLabel),
        sortOrder: serviceCourseOther.sortOrder,
      );
    case 'main':
    default:
      return ServiceCourseDescriptor(
        key: serviceCourseMain.key,
        label: normalizeFreeText(item.serviceCourseLabel).isEmpty
            ? serviceCourseMain.label
            : normalizeFreeText(item.serviceCourseLabel),
        sortOrder: serviceCourseMain.sortOrder,
      );
  }
}

int compareOrderItemsForService(PosOrderItem a, PosOrderItem b) {
  final aGroup = a.groupNumber ?? 0;
  final bGroup = b.groupNumber ?? 0;
  if (aGroup != bGroup) {
    if (aGroup == 0) return 1;
    if (bGroup == 0) return -1;
    return aGroup.compareTo(bGroup);
  }

  final aCourse = serviceCourseDescriptorForItem(a);
  final bCourse = serviceCourseDescriptorForItem(b);
  if (aCourse.sortOrder != bCourse.sortOrder) {
    return aCourse.sortOrder.compareTo(bCourse.sortOrder);
  }

  final aName = cleanOrderItemProductName(a.productName).toLowerCase();
  final bName = cleanOrderItemProductName(b.productName).toLowerCase();
  return aName.compareTo(bName);
}

List<PosOrderItem> sortOrderItemsForService(List<PosOrderItem> items) {
  final sorted = [...items];
  sorted.sort(compareOrderItemsForService);
  return sorted;
}

Map<String, List<PosOrderItem>> groupOrderItemsByGuest(
  List<PosOrderItem> items,
) {
  final grouped = <String, List<PosOrderItem>>{};
  for (final item in sortOrderItemsForService(items)) {
    final label = formatGuestGroupLabel(
      groupNumber: item.groupNumber,
      groupLabel: item.groupLabel,
    );
    grouped.putIfAbsent(label, () => <PosOrderItem>[]).add(item);
  }
  return grouped;
}

Map<ServiceCourseDescriptor, List<PosOrderItem>> groupOrderItemsByCourse(
  List<PosOrderItem> items,
) {
  final grouped = <ServiceCourseDescriptor, List<PosOrderItem>>{};
  for (final item in sortOrderItemsForService(items)) {
    final course = serviceCourseDescriptorForItem(item);
    final existingKey = grouped.keys
        .where((entry) => entry.key == course.key)
        .firstOrNull;
    if (existingKey != null) {
      grouped[existingKey]!.add(item);
    } else {
      grouped[course] = <PosOrderItem>[item];
    }
  }
  return grouped;
}
