import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkRetryHelper {
  /// Executes an asynchronous [action] with timeout, exponential backoff retry mechanism, and error logging.
  static Future<T> execute<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration timeoutDuration = const Duration(seconds: 8),
    Duration initialDelay = const Duration(milliseconds: 500),
    String actionName = 'NetworkRequest',
    T? fallbackValue,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt < maxAttempts) {
      attempt++;
      try {
        final result = await action().timeout(timeoutDuration);
        return result;
      } on SocketException catch (e) {
        debugPrint('[$actionName] SocketException (Percobaan $attempt/$maxAttempts): $e');
        if (attempt >= maxAttempts) {
          if (fallbackValue != null) return fallbackValue;
          rethrow;
        }
      } on TimeoutException catch (e) {
        debugPrint('[$actionName] TimeoutException ($timeoutDuration) (Percobaan $attempt/$maxAttempts): $e');
        if (attempt >= maxAttempts) {
          if (fallbackValue != null) return fallbackValue;
          rethrow;
        }
      } on HttpException catch (e) {
        debugPrint('[$actionName] HttpException (Percobaan $attempt/$maxAttempts): $e');
        if (attempt >= maxAttempts) {
          if (fallbackValue != null) return fallbackValue;
          rethrow;
        }
      } catch (e) {
        debugPrint('[$actionName] Error tak terduga (Percobaan $attempt/$maxAttempts): $e');
        // Do not retry on client auth errors (401/403) or known logical validations
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid login') || errStr.contains('auth') || errStr.contains('password')) {
          rethrow;
        }
        if (attempt >= maxAttempts) {
          if (fallbackValue != null) return fallbackValue;
          rethrow;
        }
      }

      // Wait with exponential backoff before next attempt
      await Future.delayed(currentDelay);
      currentDelay *= 2;
    }

    if (fallbackValue != null) return fallbackValue;
    throw TimeoutException('[$actionName] Gagal setelah $maxAttempts percobaan karena kendala koneksi.');
  }
}
