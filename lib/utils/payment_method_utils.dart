import 'dart:convert';

const String paymentMethodCash = 'cash';
const String paymentMethodTpe = 'tpe';
const String paymentMethodEnCompte = 'en_compte';
const String paymentMethodOffert = 'offert';
const String paymentMethodOther = 'other';

String normalizePaymentMethod(String? raw) {
  final normalized = raw?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty || normalized == 'pending') {
    return '';
  }

  if (normalized == paymentMethodCash ||
      normalized.contains('cash') ||
      normalized.contains('espece') ||
      normalized.contains('espèce')) {
    return paymentMethodCash;
  }

  if (normalized == paymentMethodTpe ||
      normalized == 'card' ||
      normalized.contains('tpe') ||
      normalized.contains('carte') ||
      normalized.contains('card') ||
      normalized.contains('cb') ||
      normalized.contains('bancaire')) {
    return paymentMethodTpe;
  }

  if (normalized == paymentMethodEnCompte ||
      normalized.contains('en_compte') ||
      normalized.contains('en compte') ||
      normalized.contains('compte')) {
    return paymentMethodEnCompte;
  }

  if (normalized == paymentMethodOffert ||
      normalized.contains('offert') ||
      normalized.contains('offre')) {
    return paymentMethodOffert;
  }

  if (normalized == paymentMethodOther ||
      normalized.contains('other') ||
      normalized.contains('autre')) {
    return paymentMethodOther;
  }

  return normalized;
}

String paymentMethodLabel(String? raw) {
  switch (normalizePaymentMethod(raw)) {
    case paymentMethodCash:
      return 'Espèces';
    case paymentMethodTpe:
      return 'TPE';
    case paymentMethodEnCompte:
      return 'En compte';
    case paymentMethodOffert:
      return 'Offert';
    case paymentMethodOther:
      return 'Autre';
    case 'split':
      return 'Paiement multiple';
    default:
      final fallback = raw?.trim() ?? '';
      return fallback.isEmpty ? 'Non renseigné' : fallback;
  }
}

bool isCashPaymentMethod(String? raw) {
  return normalizePaymentMethod(raw) == paymentMethodCash;
}

bool isTpePaymentMethod(String? raw) {
  return normalizePaymentMethod(raw) == paymentMethodTpe;
}

bool isEnComptePaymentMethod(String? raw) {
  return normalizePaymentMethod(raw) == paymentMethodEnCompte;
}

bool hasRecordedPaymentMethod(String? raw) {
  return normalizePaymentMethod(raw).isNotEmpty;
}

bool isOfferedPaymentMethod(String? raw) {
  return normalizePaymentMethod(raw) == paymentMethodOffert;
}

Map<String, dynamic>? _normalizeSplitPaymentEntry(dynamic raw) {
  if (raw is! Map) {
    return null;
  }

  final rawMethod = (raw['payment_method'] ?? raw['method'] ?? '').toString();
  final method = normalizePaymentMethod(rawMethod);
  final rawAmount = raw['amount'] ?? raw['montant'] ?? 0;
  final amount = rawAmount is num
      ? rawAmount.toDouble()
      : double.tryParse(rawAmount.toString().replaceAll(',', '.')) ?? 0.0;
  final timestamp = (raw['timestamp'] ?? raw['created_at'] ?? '')
      .toString()
      .trim();

  final entry = <String, dynamic>{
    'payment_method': method.isEmpty
        ? (rawMethod.trim().isEmpty ? paymentMethodOther : rawMethod.trim())
        : method,
    'amount': amount,
  };

  if (timestamp.isNotEmpty) {
    entry['timestamp'] = timestamp;
  }

  if (raw.containsKey('is_offered')) {
    entry['is_offered'] = raw['is_offered'] == true;
  }

  return entry;
}

List<Map<String, dynamic>> parseSplitPaymentEntries(String? paymentSplit) {
  if (paymentSplit == null || paymentSplit.trim().isEmpty) {
    return [];
  }

  final entries = <Map<String, dynamic>>[];

  try {
    final decoded = jsonDecode(paymentSplit);
    if (decoded is List) {
      for (final raw in decoded) {
        final normalized = _normalizeSplitPaymentEntry(raw);
        if (normalized != null) {
          entries.add(normalized);
        }
      }
      if (entries.isNotEmpty) {
        return entries;
      }
    }
  } catch (_) {
    // Fall through to legacy parsing below.
  }

  final legacyPattern = RegExp(
    r'\{[^}]*?(?:payment_method|method):\s*"?([A-Za-z0-9_ ]+)"?[^}]*?(?:amount|montant):\s*"?([\d.,]+)"?[^}]*\}',
  );
  for (final match in legacyPattern.allMatches(paymentSplit)) {
    final rawMethod = match.group(1) ?? '';
    final rawAmount = match.group(2) ?? '0';
    final method = normalizePaymentMethod(rawMethod);
    final amount = double.tryParse(rawAmount.replaceAll(',', '.')) ?? 0.0;
    entries.add({
      'payment_method': method.isEmpty ? rawMethod.trim() : method,
      'amount': amount,
    });
  }

  return entries;
}

double sumSplitPaymentAmount(
  String? paymentSplit, {
  bool includeOffert = false,
}) {
  final entries = parseSplitPaymentEntries(paymentSplit);
  return entries.fold<double>(0.0, (sum, entry) {
    final method = normalizePaymentMethod(entry['payment_method']?.toString());
    if (!includeOffert && method == paymentMethodOffert) {
      return sum;
    }

    final amount = entry['amount'];
    if (amount is num) {
      return sum + amount.toDouble();
    }
    if (amount is String) {
      return sum + (double.tryParse(amount.replaceAll(',', '.')) ?? 0.0);
    }
    return sum;
  });
}

Map<String, double> splitPaymentTotalsByMethod(
  String? paymentSplit, {
  bool includeOffert = false,
}) {
  final totals = <String, double>{};
  for (final entry in parseSplitPaymentEntries(paymentSplit)) {
    final method = normalizePaymentMethod(entry['payment_method']?.toString());
    if (!includeOffert && method == paymentMethodOffert) {
      continue;
    }

    final amount = entry['amount'];
    final parsedAmount = amount is num
        ? amount.toDouble()
        : amount is String
        ? (double.tryParse(amount.replaceAll(',', '.')) ?? 0.0)
        : 0.0;
    if (parsedAmount <= 0) {
      continue;
    }

    totals[method] = (totals[method] ?? 0.0) + parsedAmount;
  }
  return totals;
}

bool hasOfferedSplitPayment(String? paymentSplit) {
  return parseSplitPaymentEntries(
    paymentSplit,
  ).any((entry) => isOfferedPaymentMethod(entry['payment_method']?.toString()));
}

/// Get list of offered items from partial payment history JSON
List<Map<String, dynamic>> getOfferedItemsFromHistory(String? historyJson) {
  if (historyJson == null || historyJson.isEmpty) {
    return [];
  }
  try {
    final List<dynamic> history = jsonDecode(historyJson);
    final offered = history
        .whereType<Map<String, dynamic>>()
        .where((item) => item['is_offered'] == true)
        .toList();
    return offered.cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
}

/// Check if an item has any offered quantities
bool hasOfferedQuantity(String? historyJson) {
  return getOfferedItemsFromHistory(historyJson).isNotEmpty;
}

/// Get the name of who offered the item
String? getOfferedByName(String? historyJson) {
  final offered = getOfferedItemsFromHistory(historyJson);
  if (offered.isEmpty) return null;
  return offered.last['offered_by_staff_name'] as String?;
}

/// Format split payment details for display
String formatSplitPaymentDetails(String? paymentSplit) {
  if (paymentSplit == null || paymentSplit.isEmpty) {
    return '';
  }

  try {
    final payments = parseSplitPaymentEntries(paymentSplit);
    if (payments.isEmpty) return '';

    final details = payments
        .map((payment) {
          final method = paymentMethodLabel(
            payment['payment_method'] as String?,
          );
          final amount = payment['amount'] as num? ?? 0.0;
          return '$method: ${amount.toDouble().toStringAsFixed(2)} DA';
        })
        .join(', ');

    return details;
  } catch (e) {
    return '';
  }
}
