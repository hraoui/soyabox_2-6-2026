class AppSettings {
  String currencyCode;
  String currencySymbol;
  String? appLogoPath;
  String? ticketLogoPath;

  // ✅ Heures personnalisées de la journée de service (Morocco/Casablanca)
  // Par défaut: 00h00 - 23h59 (jour calendaire)
  // Exemple restaurant: 06h00 - 05h59 (jour de service)
  final int? _dayStartHour;
  final int? _dayEndHour;

  // Getters avec valeurs par défaut sûres
  int get dayStartHour => _dayStartHour ?? 0;
  int get dayEndHour => _dayEndHour ?? 23;

  AppSettings({
    this.currencyCode = 'MAD',
    this.currencySymbol = 'Dhs',
    this.appLogoPath,
    this.ticketLogoPath,
    int? dayStartHour,
    int? dayEndHour,
  }) : _dayStartHour = dayStartHour,
       _dayEndHour = dayEndHour;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currencyCode: (json['currency_code'] ?? 'MAD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'Dhs').toString(),
      appLogoPath: json['app_logo_path']?.toString(),
      ticketLogoPath: json['ticket_logo_path']?.toString(),
      dayStartHour: json['day_start_hour'] as int?,
      dayEndHour: json['day_end_hour'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_code': currencyCode,
    'currency_symbol': currencySymbol,
    'app_logo_path': appLogoPath,
    'ticket_logo_path': ticketLogoPath,
    'day_start_hour': dayStartHour,
    'day_end_hour': dayEndHour,
  };

  // ✅ Helper pour obtenir les heures formatées
  String get dayStartLabel => '${dayStartHour.toString().padLeft(2, '0')}h00';
  String get dayEndLabel => '${dayEndHour.toString().padLeft(2, '0')}h59';
  String get dayRangeLabel => '$dayStartLabel → $dayEndLabel';
}
