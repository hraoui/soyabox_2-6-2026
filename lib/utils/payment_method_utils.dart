import 'dart:convert';

const String paymentMethodCash = 'cash';
const String paymentMethodTpe = 'tpe';
const String paymentMethodEnCompte = 'en_compte';
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

/// Format split payment details for display
String formatSplitPaymentDetails(String? paymentSplit) {
  if (paymentSplit == null || paymentSplit.isEmpty) {
    return '';
  }

  try {
    final List<dynamic> payments = jsonDecode(paymentSplit);
    if (payments.isEmpty) return '';

    final details = payments
        .map((payment) {
          final method = paymentMethodLabel(
            payment['payment_method'] as String?,
          );
          final amount = (payment['amount'] as num).toDouble();
          return '$method: ${amount.toStringAsFixed(2)} DA';
        })
        .join(', ');

    return details;
  } catch (e) {
    return '';
  }
}
