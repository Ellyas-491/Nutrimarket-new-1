import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentMethodSelector extends StatelessWidget {
  final List<Map<String, dynamic>> paymentMethods;
  final String selectedPaymentMethod;
  final ValueChanged<String> onSelectPaymentMethod;

  const PaymentMethodSelector({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onSelectPaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: paymentMethods.map((method) {
              final name = method['name'] as String;
              final subtitle = method['subtitle'] as String?;
              final icon = method['icon'] as IconData;
              final isSelected = selectedPaymentMethod == name;

              return InkWell(
                onTap: () => onSelectPaymentMethod(name),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.08)
                        : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? AppColors.primary : AppColors.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: name,
                        groupValue: selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) onSelectPaymentMethod(val);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
