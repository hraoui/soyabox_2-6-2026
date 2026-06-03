enum ReceiptPrinterTransport { auto, network, usb }

ReceiptPrinterTransport receiptPrinterTransportFromJson(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'network':
      return ReceiptPrinterTransport.network;
    case 'usb':
      return ReceiptPrinterTransport.usb;
    case 'auto':
    default:
      return ReceiptPrinterTransport.auto;
  }
}

class AppSettings {
  static const Object _unset = Object();

  String currencyCode;
  String currencySymbol;
  String? appLogoPath;
  String? ticketLogoPath;
  String? receiptPrinterHost;
  final String? _kitchenReceiptPrinterHost;

  final int? _receiptPrinterPort;
  final int? _kitchenReceiptPrinterPort;
  final bool? _useEscPosPrinting;
  final ReceiptPrinterTransport? _receiptPrinterTransport;
  final ReceiptPrinterTransport? _kitchenReceiptPrinterTransport;

  // ✅ Heures personnalisées de la journée de service (Morocco/Casablanca)
  // Par défaut: 00h00 - 23h59 (jour calendaire)
  // Exemple restaurant: 06h00 - 05h59 (jour de service)
  final int? _dayStartHour;
  final int? _dayEndHour;

  // Getters avec valeurs par défaut sûres
  int get receiptPrinterPort => _receiptPrinterPort ?? 9100;
  bool get useEscPosPrinting => _useEscPosPrinting ?? false;
  ReceiptPrinterTransport get receiptPrinterTransport =>
      _receiptPrinterTransport ?? ReceiptPrinterTransport.auto;
  String? get kitchenReceiptPrinterHost =>
      _kitchenReceiptPrinterHost ?? receiptPrinterHost;
  int get kitchenReceiptPrinterPort =>
      _kitchenReceiptPrinterPort ?? receiptPrinterPort;
  ReceiptPrinterTransport get kitchenReceiptPrinterTransport =>
      _kitchenReceiptPrinterTransport ?? receiptPrinterTransport;
  int get dayStartHour => _dayStartHour ?? 0;
  int get dayEndHour => _dayEndHour ?? 23;
  bool get hasConfiguredCustomerReceiptPrinter =>
      useEscPosPrinting &&
      (receiptPrinterTransport == ReceiptPrinterTransport.auto ||
          receiptPrinterTransport == ReceiptPrinterTransport.usb ||
          (receiptPrinterHost?.trim().isNotEmpty ?? false));
  bool get hasConfiguredKitchenReceiptPrinter =>
      useEscPosPrinting &&
      (kitchenReceiptPrinterTransport == ReceiptPrinterTransport.auto ||
          kitchenReceiptPrinterTransport == ReceiptPrinterTransport.usb ||
          (kitchenReceiptPrinterHost?.trim().isNotEmpty ?? false));
  bool get hasConfiguredReceiptPrinter =>
      hasConfiguredCustomerReceiptPrinter || hasConfiguredKitchenReceiptPrinter;

  AppSettings({
    this.currencyCode = 'MAD',
    this.currencySymbol = 'Dhs',
    this.appLogoPath,
    this.ticketLogoPath,
    this.receiptPrinterHost,
    String? kitchenReceiptPrinterHost,
    int? receiptPrinterPort = 9100,
    int? kitchenReceiptPrinterPort,
    bool? useEscPosPrinting = false,
    ReceiptPrinterTransport? receiptPrinterTransport =
        ReceiptPrinterTransport.auto,
    ReceiptPrinterTransport? kitchenReceiptPrinterTransport,
    int? dayStartHour,
    int? dayEndHour,
  }) : _receiptPrinterPort = receiptPrinterPort,
       _kitchenReceiptPrinterHost = kitchenReceiptPrinterHost,
       _kitchenReceiptPrinterPort = kitchenReceiptPrinterPort,
       _useEscPosPrinting = useEscPosPrinting,
       _receiptPrinterTransport = receiptPrinterTransport,
       _kitchenReceiptPrinterTransport = kitchenReceiptPrinterTransport,
       _dayStartHour = dayStartHour,
       _dayEndHour = dayEndHour;

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    Object? appLogoPath = _unset,
    Object? ticketLogoPath = _unset,
    Object? receiptPrinterHost = _unset,
    Object? kitchenReceiptPrinterHost = _unset,
    int? receiptPrinterPort,
    int? kitchenReceiptPrinterPort,
    bool? useEscPosPrinting,
    ReceiptPrinterTransport? receiptPrinterTransport,
    ReceiptPrinterTransport? kitchenReceiptPrinterTransport,
    int? dayStartHour,
    int? dayEndHour,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      appLogoPath: appLogoPath == _unset
          ? this.appLogoPath
          : appLogoPath as String?,
      ticketLogoPath: ticketLogoPath == _unset
          ? this.ticketLogoPath
          : ticketLogoPath as String?,
      receiptPrinterHost: receiptPrinterHost == _unset
          ? this.receiptPrinterHost
          : receiptPrinterHost as String?,
      kitchenReceiptPrinterHost: kitchenReceiptPrinterHost == _unset
          ? _kitchenReceiptPrinterHost
          : kitchenReceiptPrinterHost as String?,
      receiptPrinterPort: receiptPrinterPort ?? this.receiptPrinterPort,
      kitchenReceiptPrinterPort:
          kitchenReceiptPrinterPort ?? this.kitchenReceiptPrinterPort,
      useEscPosPrinting: useEscPosPrinting ?? this.useEscPosPrinting,
      receiptPrinterTransport:
          receiptPrinterTransport ?? this.receiptPrinterTransport,
      kitchenReceiptPrinterTransport:
          kitchenReceiptPrinterTransport ?? this.kitchenReceiptPrinterTransport,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      dayEndHour: dayEndHour ?? this.dayEndHour,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawPrinterPort = json['receipt_printer_port'];
    final parsedPrinterPort = rawPrinterPort is num
        ? rawPrinterPort.toInt()
        : int.tryParse(rawPrinterPort?.toString() ?? '');
    final rawEscPosFlag = json['use_esc_pos_printing'];
    final parsedEscPosFlag =
        rawEscPosFlag == true ||
        rawEscPosFlag?.toString().toLowerCase() == 'true';
    final parsedTransport = receiptPrinterTransportFromJson(
      json['receipt_printer_transport'],
    );
    final rawKitchenPrinterPort = json['kitchen_receipt_printer_port'];
    final parsedKitchenPrinterPort = rawKitchenPrinterPort is num
        ? rawKitchenPrinterPort.toInt()
        : int.tryParse(rawKitchenPrinterPort?.toString() ?? '');
    final parsedKitchenTransport = receiptPrinterTransportFromJson(
      json['kitchen_receipt_printer_transport'],
    );
    final rawDayStartHour = json['day_start_hour'];
    final parsedDayStartHour = rawDayStartHour is num
        ? rawDayStartHour.toInt()
        : int.tryParse(rawDayStartHour?.toString() ?? '');
    final rawDayEndHour = json['day_end_hour'];
    final parsedDayEndHour = rawDayEndHour is num
        ? rawDayEndHour.toInt()
        : int.tryParse(rawDayEndHour?.toString() ?? '');

    return AppSettings(
      currencyCode: (json['currency_code'] ?? 'MAD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'Dhs').toString(),
      appLogoPath: json['app_logo_path']?.toString(),
      ticketLogoPath: json['ticket_logo_path']?.toString(),
      receiptPrinterHost: json['receipt_printer_host']?.toString(),
      kitchenReceiptPrinterHost:
          json['kitchen_receipt_printer_host']?.toString(),
      receiptPrinterPort: parsedPrinterPort,
      kitchenReceiptPrinterPort: parsedKitchenPrinterPort,
      useEscPosPrinting: parsedEscPosFlag,
      receiptPrinterTransport: parsedTransport,
      kitchenReceiptPrinterTransport: parsedKitchenTransport,
      dayStartHour: parsedDayStartHour,
      dayEndHour: parsedDayEndHour,
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_code': currencyCode,
    'currency_symbol': currencySymbol,
    'app_logo_path': appLogoPath,
    'ticket_logo_path': ticketLogoPath,
    'receipt_printer_host': receiptPrinterHost,
    'kitchen_receipt_printer_host': _kitchenReceiptPrinterHost,
    'receipt_printer_port': receiptPrinterPort,
    'kitchen_receipt_printer_port': kitchenReceiptPrinterPort,
    'use_esc_pos_printing': useEscPosPrinting,
    'receipt_printer_transport': receiptPrinterTransport.name,
    'kitchen_receipt_printer_transport': kitchenReceiptPrinterTransport.name,
    'day_start_hour': dayStartHour,
    'day_end_hour': dayEndHour,
  };

  // ✅ Helper pour obtenir les heures formatées
  String get dayStartLabel => '${dayStartHour.toString().padLeft(2, '0')}h00';
  String get dayEndLabel => '${dayEndHour.toString().padLeft(2, '0')}h59';
  String get dayRangeLabel => '$dayStartLabel → $dayEndLabel';
}
