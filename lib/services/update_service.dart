import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
    final updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
    context.mounted) {
    await InAppUpdate.performImmediateUpdate();
    }
    } catch (e) {
    debugPrint('Update check failed: $e');
    }
  }
}
