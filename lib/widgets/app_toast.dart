import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastType { success, info, warning, error }

class AppToast {
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    ToastType type = ToastType.success,
    VoidCallback? onTap,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    IconData iconData;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF34D399);
        break;
      case ToastType.info:
        iconData = Icons.info_rounded;
        iconColor = const Color(0xFF38BDF8);
        break;
      case ToastType.warning:
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFBBF24);
        break;
      case ToastType.error:
        iconData = Icons.error_rounded;
        iconColor = const Color(0xFFF87171);
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2600),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        padding: EdgeInsets.zero,
        content: Center(
          child: GestureDetector(
            onTap: () {
              messenger.hideCurrentSnackBar();
              if (onTap != null) onTap();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, color: iconColor, size: 18),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          subtitle.isNotEmpty ? subtitle : title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
