String normalizeBadgeCode(String? raw) {
  if (raw == null) return '';
  return raw.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
}

bool hasBadgeCode(String? raw) {
  return normalizeBadgeCode(raw).isNotEmpty;
}
