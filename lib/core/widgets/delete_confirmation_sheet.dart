import 'package:flutter/material.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

class DeleteConfirmationSheet extends StatelessWidget {
  final VoidCallback onDelete;

  const DeleteConfirmationSheet({super.key, required this.onDelete});

  static void show(BuildContext context, {required VoidCallback onDelete}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DeleteConfirmationSheet(onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Red Icon Alert
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B1219) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Hapus Percakapan?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesan dan riwayat konsultasi pada sesi ini akan dibersihkan. Percakapan baru akan dimulai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : AppColors.secondary,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                      ),
                      backgroundColor: isDark ? Colors.transparent : const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 17),
                    label: const Text(
                      'Hapus Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
