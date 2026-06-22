import 'dart:async';
import 'package:mechanix_files/core/widgets/toast/toast_view.dart';
import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class CustomAppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (_) => ToastView(message: message, type: type, onClose: dismiss),
    );

    overlay.insert(_entry!);

    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;

    _entry?.remove();
    _entry = null;
  }
}
