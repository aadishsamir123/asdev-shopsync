import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryUtils {
  static bool shouldReportError(dynamic error) {
    if (error is FirebaseAuthException) {
      // Don't report user-related auth errors
      final userErrors = [
        'wrong-password',
        'user-not-found',
        'invalid-email',
        'email-already-in-use',
        'weak-password',
      ];
      return !userErrors.contains(error.code);
    }
    return true;
  }

  static Future<void> reportError(dynamic exception, dynamic stackTrace) async {
    if (exception is Exception && !shouldReportError(exception)) {
      return;
    }
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
    );
  }
}
