import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger. Debug builds emit verbose output;
/// release builds suppress everything below warnings.
final appLogger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(lineLength: 80),
);
