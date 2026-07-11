import 'package:flutter/material.dart';

enum AppNotificationType { success, error, info }

String cleanErrorMessage(Object error) {
  var message = error.toString().trim();
  message = message
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^BackendAuthException:\s*'), '')
      .replaceFirst(RegExp(r'^VodafoneApiException:\s*'), '');

  if (message.contains('SocketException') ||
      message.contains('ClientException') ||
      message.contains('Failed host lookup')) {
    return 'تعذر الاتصال بالسيرفر. راجع الإنترنت وحاول تاني.';
  }

  if (message.contains('FormatException')) {
    return 'رد السيرفر غير واضح. حاول تاني بعد لحظات.';
  }

  return message.isEmpty ? 'حصل خطأ غير متوقع' : message;
}

void showAppNotification(
  BuildContext context, {
  required String message,
  AppNotificationType type = AppNotificationType.info,
}) {
  final (color, icon) = switch (type) {
    AppNotificationType.success => (
        const Color(0xFF057A55),
        Icons.check_circle_rounded,
      ),
    AppNotificationType.error => (
        const Color(0xFFB42318),
        Icons.error_rounded,
      ),
    AppNotificationType.info => (
        const Color(0xFF344054),
        Icons.info_rounded,
      ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
