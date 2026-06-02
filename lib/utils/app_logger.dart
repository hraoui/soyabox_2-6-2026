import 'package:logger/logger.dart';

class AppLogger {
  AppLogger._()
    : _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 3,
          lineLength: 120,
          colors: false,
          printEmojis: false,
          printTime: true,
        ),
      );

  final Logger _logger;

  void d(String message, {Map<String, Object?>? context}) {
    _logger.d(_format(message, context));
  }

  void i(String message, {Map<String, Object?>? context}) {
    _logger.i(_format(message, context));
  }

  void w(String message, {Map<String, Object?>? context}) {
    _logger.w(_format(message, context));
  }

  void e(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    _logger.e(_format(message, context), error: error, stackTrace: stackTrace);
  }

  String _format(String message, Map<String, Object?>? context) {
    if (context == null || context.isEmpty) {
      return message;
    }
    final parts = context.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .toList(growable: false);
    if (parts.isEmpty) {
      return message;
    }
    return '$message [${parts.join(' ')}]';
  }
}

final appLogger = AppLogger._();
