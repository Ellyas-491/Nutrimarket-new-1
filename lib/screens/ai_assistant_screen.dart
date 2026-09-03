import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/food_product.dart';
import '../services/groq_service.dart';
import '../services/history_service.dart';
import '../services/product_repository.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_recommendation_card.dart';
import '../widgets/app_toast.dart';
import '../widgets/delete_confirmation_sheet.dart';
import '../widgets/thinking_indicator.dart';
import 'main_navigation_screen.dart';
import 'product_detail_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  final ChatSession? initialSession;

  const AiAssistantScreen({super.key, this.initialSession});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GroqService _groqService = GroqService();
  final VoiceService _voiceService = VoiceService();
  final HistoryService _historyService = HistoryService();
  final ProductRepository _productRepository = ProductRepository();

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _sessionId;
  bool _isLoading = false;
  bool _isListening = false;

  final List<Map<String, dynamic>> _quickPrompts = [
    {'label': 'Makan siang rendah gula & karbo', 'icon': Icons.restaurant_rounded},
    {'label': 'Rekomendasi menu ramah diabetes', 'icon': Icons.favorite_rounded},
    {'label': 'Menu tinggi protein pembentukan otot', 'icon': Icons.fitness_center_rounded},
    {'label': 'Minuman segar 0 kalori & antioksidan', 'icon': Icons.local_drink_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSession != null) {
      _sessionId = widget.initialSession!.id;
    } else {
      _createNewSession();
    }
  }

  void _createNewSession() {
    final userName = _historyService.userProfile.name.split(' ')[0];

    final session = _historyService.createSession(
      title: 'Konsultasi Gizi',
      category: 'Konsultasi Nutrisi',
    );
    _sessionId = session.id;

    final now = DateTime.now();
    _historyService.addMessageToSession(
      _sessionId,
      ChatMessage(
        id: 'init_msg_${DateTime.now().millisecondsSinceEpoch}',
        content: "Halo Kak **$userName**! Saya **Konsultan Gizi NutriMarket**.\n\nSaya siap membantu Anda menyusun pola makan sehat, merekomendasikan menu yang aman sesuai kondisi tubuh (seperti diabetes, rendah garam/hipertensi, atau program diet), serta menganalisis kebutuhan nutrisi harian.\n\nAda yang ingin Anda konsultasikan hari ini?",
        isUser: false,
        timestamp: now,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isGreeting(String text) {
    final lower = text.trim().toLowerCase();
    final greetingWords = [
      'hallo', 'halo', 'hi', 'hai', 'helo', 'hello', 'ping', 'tes', 'test', 'p',
      'selamat pagi', 'selamat siang', 'selamat sore', 'selamat malam', 'apa kabar', 'siapa kamu'
    ];
    return greetingWords.contains(lower) || lower == 'hallo' || lower == 'halo' || lower == 'hi' || lower == 'hai';
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (customText == null) {
      _textController.clear();
    }

    setState(() {
      _isLoading = true;
    });

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _historyService.addMessageToSession(_sessionId, userMsg);
    setState(() {});
    _scrollToBottom();

    try {
      final userProfile = _historyService.userProfile;

      final currentSession = _historyService.sessions.firstWhere(
        (s) => s.id == _sessionId,
        orElse: () => ChatSession(
          id: _sessionId,
          title: 'Consultation',
          category: 'AI',
          messages: [],
          createdAt: DateTime.now(),
        ),
      );

      final response = await _groqService.sendMessage(
        currentSession.messages,
        text,
        aiMode: AiMode.aiFoodAssistant,
        userProfile: userProfile,
      );

      final executed = _historyService.executeAgentAction(response);
      final cleanResponse = response.replaceAll(RegExp(r'\[AGENT_ACTION:.*?\]', dotAll: true), '').trim();

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: cleanResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _historyService.addMessageToSession(_sessionId, aiMsg);

      if (executed && mounted) {
        AppToast.show(
          context,
          title: 'Profil Diperbarui',
          subtitle: 'Profil kesehatan Anda telah berhasil diperbarui.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      String errorMessage = '⚠️ Koneksi internet tidak tersedia.\n\nNutriBot AI membutuhkan koneksi internet aktif untuk menganalisis dan merekomendasikan menu sehat secara real-time. Silakan periksa jaringan Anda lalu coba lagi.';
      if (errStr.contains('timeout')) {
        errorMessage = '⚠️ Waktu permintaan habis (Timeout).\n\nKoneksi internet Anda sedang lemah atau server AI sedang sibuk. Silakan periksa koneksi Anda dan coba beberapa saat lagi.';
      }

      final errorMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _historyService.addMessageToSession(_sessionId, errorMsg);

      if (mounted) {
        AppToast.show(
          context,
          title: 'Koneksi Bermasalah',
          subtitle: 'NutriBot AI membutuhkan koneksi internet aktif',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _toggleVoiceRecording() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      final started = await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _textController.text = text;
          });
        },
        onStateChange: (listening) {
          setState(() => _isListening = listening);
        },
        onFinalSentence: (sentence) {
          if (sentence.isNotEmpty) {
            _sendMessage(sentence);
          }
        },
      );
      if (started) {
        setState(() => _isListening = true);
      }
    }
  }

  void _showDeleteDialog() {
    DeleteConfirmationSheet.show(
      context,
      onDelete: () {
        _historyService.deleteSession(_sessionId);
        AppToast.show(
          context,
          title: 'Percakapan Dihapus',
          subtitle: 'Riwayat percakapan telah dibersihkan.',
          type: ToastType.error,
        );
        setState(() {
          _createNewSession();
        });
      },
    );
  }

  List<FoodProduct> _getMatchingProducts(List<ChatMessage> messages, String lastUserMsg, String lastAiMsg) {
    if (!messages.any((m) => m.isUser)) {
      return [];
    }

    if (_isGreeting(lastUserMsg)) {
      return [];
    }

    final lowerUser = lastUserMsg.toLowerCase();
    final lowerAi = lastAiMsg.toLowerCase();

    if (lowerUser.contains('sakit kepala') ||
        lowerUser.contains('pusing') ||
        lowerUser.contains('demam') ||
        lowerUser.contains('maag') ||
        lowerUser.contains('mual') ||
        lowerUser.contains('lemas') ||
        lowerUser.contains('nyeri') ||
        lowerUser.contains('sakit')) {
      return [];
    }

    final userProfile = _historyService.userProfile;
    final condition = userProfile.dietaryType.toLowerCase();
    final allergies = userProfile.foodAllergies.map((a) => a.toLowerCase()).toList();

    bool isPassFilter(FoodProduct p) {
      // 1. Check Allergens & Pantangan
      final pAllergensLower = p.allergens.map((a) => a.toLowerCase()).toList();
      final pIngredientsLower = p.ingredients.map((i) => i.toLowerCase()).toList();

      for (final allergy in allergies) {
        if (allergy.contains('kacang') && (pAllergensLower.any((a) => a.contains('kacang') || a.contains('peanut') || a.contains('almond')) ||
            pIngredientsLower.any((i) => i.contains('kacang') || i.contains('peanut') || i.contains('almond')))) {
          return false;
        }
        if ((allergy.contains('seafood') || allergy.contains('udang') || allergy.contains('ikan')) &&
            (pAllergensLower.any((a) => a.contains('seafood') || a.contains('udang') || a.contains('ikan') || a.contains('salmon')) ||
             pIngredientsLower.any((i) => i.contains('seafood') || i.contains('udang') || i.contains('ikan') || i.contains('salmon')))) {
          return false;
        }
        if ((allergy.contains('susu') || allergy.contains('laktosa')) &&
            (pAllergensLower.any((a) => a.contains('susu') || a.contains('milk') || a.contains('laktosa') || a.contains('keju')) ||
             pIngredientsLower.any((i) => i.contains('susu') || i.contains('milk') || i.contains('keju') || i.contains('mentega')))) {
          return false;
        }
        if (allergy.contains('telur') &&
            (pAllergensLower.any((a) => a.contains('telur') || a.contains('egg')) ||
             pIngredientsLower.any((i) => i.contains('telur') || i.contains('egg') || i.contains('mayones')))) {
          return false;
        }
        if (allergy.contains('gluten') &&
            (pAllergensLower.any((a) => a.contains('gluten') || a.contains('gandum')) ||
             pIngredientsLower.any((i) => i.contains('gandum') || i.contains('terigu')))) {
          return false;
        }
        if (allergy.contains('kedelai') &&
            (pAllergensLower.any((a) => a.contains('kedelai') || a.contains('soy')) ||
             pIngredientsLower.any((i) => i.contains('kedelai') || i.contains('soy') || i.contains('tofu') || i.contains('tahu')))) {
          return false;
        }
      }

      // 2. Check Medical Condition
      if (condition.contains('diabetes') || condition.contains('gula')) {
        if (!p.suitableFor.contains('Diabetes-friendly') && !p.suitableFor.contains('Low Sugar')) {
          return false;
        }
      }
      if (condition.contains('sodium') || condition.contains('hipertensi') || condition.contains('tensi')) {
        if (!p.suitableFor.contains('Low Sodium')) {
          return false;
        }
      }
      if (condition.contains('protein') && !p.suitableFor.contains('High Protein')) {
        return false;
      }

      return true;
    }

    final products = _productRepository.verifiedProducts;
    final List<FoodProduct> matches = [];

    for (final p in products) {
      if (!isPassFilter(p)) continue;
      final nameLower = p.name.toLowerCase();
      if (lowerAi.contains(nameLower) || 
          (nameLower.split(' ').isNotEmpty && lowerAi.contains(nameLower.split(' ')[0]) && lowerAi.contains(nameLower.split(' ')[1]))) {
        matches.add(p);
      }
    }

    if (matches.isEmpty) {
      final isRecommendationIntent = lowerUser.contains('rekomendasi') ||
          lowerUser.contains('makanan') ||
          lowerUser.contains('menu') ||
          lowerUser.contains('diet') ||
          lowerUser.contains('saran makan') ||
          lowerUser.contains('pilih makan') ||
          lowerUser.contains('rekomendasikan');
          
      if (isRecommendationIntent) {
        return products.where(isPassFilter).take(2).toList();
      }
    }

    return matches;
  }

  void _startNewChat() {
    _textController.clear();
    setState(() {
      _createNewSession();
    });
    _scrollToBottom();
    AppToast.show(
      context,
      title: 'Chat Baru',
      subtitle: 'Sesi konsultasi baru telah dimulai.',
      type: ToastType.success,
    );
  }

  void _showChatHistoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sessions = _historyService.sessions;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Riwayat Konsultasi AI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startNewChat();
                          },
                          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Sesi Baru',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: isDark ? Colors.white24 : AppColors.secondary),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat percakapan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final s = sessions[index];
                              final isCurrent = s.id == _sessionId;
                              final lastMsg = s.messages.isNotEmpty ? s.messages.last.content : 'Percakapan baru';
                              final cleanPreview = lastMsg.replaceAll('*', '').replaceAll('\n', ' ');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? (isDark ? const Color(0xFF132E2B) : const Color(0xFFF0FDF4))
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppColors.primary
                                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      _sessionId = s.id;
                                    });
                                    _scrollToBottom();
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Aktif',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        cleanPreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_rounded, size: 11, color: isDark ? Colors.white38 : AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year} • ${s.messages.length} pesan',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark ? Colors.white38 : AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () {
                                      _historyService.deleteSession(s.id);
                                      setModalState(() {});
                                      if (isCurrent && sessions.isNotEmpty) {
                                        setState(() {
                                          _createNewSession();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              MainNavigationScreen.switchToTab(0);
            }
          },
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'AI Ahli Gizi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'Klinis 🩺',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'NutriBot Ahli Gizi • Siap Membantu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Riwayat Konsultasi',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
              shape: const CircleBorder(),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.history_rounded, size: 20),
            onPressed: _showChatHistoryBottomSheet,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Mulai Ulang Chat',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF132E2B) : const Color(0xFFE6F4F1),
              foregroundColor: AppColors.primary,
              shape: const CircleBorder(),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.add_comment_outlined, size: 19),
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Hapus Percakapan',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B1219) : const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFEF4444),
              shape: const CircleBorder(),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            onPressed: _showDeleteDialog,
          ),
          const SizedBox(width: 14),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _historyService,
        builder: (context, _) {
          final currentSession = _historyService.sessions.firstWhere(
            (s) => s.id == _sessionId,
            orElse: () => ChatSession(
              id: _sessionId,
              title: 'AI Consultation',
              category: 'AI',
              messages: [],
              createdAt: DateTime.now(),
            ),
          );

          final messages = currentSession.messages;
          String lastUserMsg = '';
          String lastAiMsg = '';

          for (final m in messages.reversed) {
            if (m.isUser && lastUserMsg.isEmpty) {
              lastUserMsg = m.content;
            } else if (!m.isUser && lastAiMsg.isEmpty) {
              lastAiMsg = m.content;
            }
            if (lastUserMsg.isNotEmpty && lastAiMsg.isNotEmpty) break;
          }

          final recommendedProducts = _getMatchingProducts(messages, lastUserMsg, lastAiMsg);

          return Column(
            children: [
              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return const ThinkingIndicator();
                    }
                    final msg = messages[index];
                    final isLastAiMessage = !msg.isUser && index == messages.length - 1;

                    return Column(
                      children: [
                        _buildMessageRow(msg, isDark),
                        if (isLastAiMessage && recommendedProducts.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 42, bottom: 6),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Rekomendasi Menu Terkait:',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF5EEAD4) : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ),
                          ...recommendedProducts.map((product) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 44, bottom: 8),
                              child: AiRecommendationCard(
                                product: product,
                                onTapDetail: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Quick Prompts Chips
              if (messages.length <= 2)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _quickPrompts.length,
                    itemBuilder: (context, index) {
                      final item = _quickPrompts[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _sendMessage(item['label']),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, color: AppColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Floating Modern Input Bar
              Container(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Voice Recording Button
                      GestureDetector(
                        onTap: _toggleVoiceRecording,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(0xFFFEE2E2)
                                : (isDark ? AppColors.darkBackground : AppColors.primaryLight),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: _isListening ? AppColors.error : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Tanyakan menu sehat atau gizi...',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white30 : AppColors.textHint,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Send Button
                      GestureDetector(
                        onTap: () => _sendMessage(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _cleanDisplayContent(String text) {
    final lines = text.split('\n');
    final cleanLines = <String>[];
    bool inTable = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^\s*\|?\s*[-:]+\s*\|').hasMatch(trimmed)) {
        inTable = true;
        continue;
      }
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final cells = trimmed
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        if (cells.isNotEmpty) {
          if (!inTable) {
            cleanLines.add('**${cells.join(' • ')}**');
          } else {
            cleanLines.add('• ${cells.join(': ')}');
          }
        }
        continue;
      } else {
        inTable = false;
      }
      cleanLines.add(line);
    }

    return cleanLines.join('\n');
  }

  Widget _buildMessageRow(ChatMessage msg, bool isDark) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeStr,
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.secondary,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF0D9488)),
                            const SizedBox(width: 4),
                            Text(
                              'Konsultan Gizi NutriMarket',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0D9488),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        MarkdownBody(
                          data: _cleanDisplayContent(msg.content),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                            strong: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppColors.secondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
