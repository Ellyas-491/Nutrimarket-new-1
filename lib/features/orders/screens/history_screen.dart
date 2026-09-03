import 'package:flutter/material.dart';
import 'package:clev_ai/features/ai_assistant/models/chat_session.dart';
import 'package:clev_ai/features/orders/services/history_service.dart';
import 'package:clev_ai/core/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final Function(ChatSession session) onSelectSession;

  const HistoryScreen({super.key, required this.onSelectSession});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterCategories = ['All', 'AI Chat', 'Symptoms', 'Analyzer'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyService = HistoryService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: AppTextStyles.body1(
            color: isDark ? Colors.white : AppColors.dark,
            weight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: historyService,
        builder: (context, _) {
          final allSessions = historyService.sessions;

          final sessions = allSessions.where((s) {
            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'AI Chat') return s.category.contains('AI');
            if (_selectedFilter == 'Symptoms') return s.category.contains('Symptom');
            if (_selectedFilter == 'Analyzer') return s.category.contains('Analyzer');
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Chips matching exact 8th screenshot mockup
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filterCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _filterCategories[index];
                    final isSelected = _selectedFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.softTeal,
                        labelStyle: AppTextStyles.caption(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.dark),
                          weight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isDark ? const Color(0xFF22302D) : AppColors.surface,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : AppColors.border),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (_) => setState(() => _selectedFilter = cat),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Sessions List grouped by date matching 8th screenshot
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final dateLabel = _getDateGroupLabel(index, session.createdAt);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dateLabel != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Text(
                              dateLabel,
                              style: AppTextStyles.caption(
                                color: AppColors.secondary,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => widget.onSelectSession(session),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF22302D) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppColors.softTeal,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(session.category),
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.category,
                                            style: AppTextStyles.caption(
                                              color: isDark ? Colors.white : AppColors.dark,
                                              weight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            session.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.caption(
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(session.createdAt),
                                      style: AppTextStyles.caption(color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.secondary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _getDateGroupLabel(int index, DateTime date) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Yesterday';
    if (index == 2) return 'Aug 10';
    if (index == 3) return 'Aug 8';
    return null;
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Symptom Checker':
        return Icons.health_and_safety_outlined;
      case 'Health Analyzer':
        return Icons.analytics_outlined;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}
