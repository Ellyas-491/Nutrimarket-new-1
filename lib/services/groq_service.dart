import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/product_repository.dart';
import '../utils/network_retry_helper.dart';
import 'offline_sync_service.dart';

enum AiMode {
  generalHealth,
  aiFoodAssistant,
  symptomChecker,
  healthAnalyzer,
}

class GroqService {
  String get _apiKey => AppConfig.groqApiKey;
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const List<String> _models = [
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'groq/compound',
  ];

  final ProductRepository _productRepository = ProductRepository();

  bool _isGreetingText(String text) {
    String query = text;
    if (query.contains('User Query:')) {
      query = query.split('User Query:').last.trim();
    }
    final lower = query.trim().toLowerCase();
    final greetingWords = [
      'hallo', 'halo', 'hi', 'hai', 'helo', 'hello', 'ping', 'tes', 'test', 'p',
      'selamat pagi', 'selamat siang', 'selamat sore', 'selamat malam', 'apa kabar', 'siapa kamu'
    ];
    return greetingWords.contains(lower) || lower == 'hallo' || lower == 'halo' || lower == 'hi' || lower == 'hai';
  }

  String _getSystemPrompt(AiMode mode, UserProfile? userProfile) {
    final verifiedProducts = _productRepository.verifiedProducts;
    final catalogContext = verifiedProducts.map((p) {
      return '''
Product ID: ${p.id}
Name: ${p.name}
Category: ${p.category}
Price: ${p.formattedPrice}
Rating: ${p.rating} (${p.reviewCount} ulasan)
Nutrition: Calories ${p.calories} kcal, Protein ${p.protein}g, Carbs ${p.carbs}g, Fat ${p.fat}g, Sugar ${p.sugar}g, Sodium ${p.sodium}mg, Fiber ${p.fiber}g
Dietary Tags: ${p.suitableFor.join(', ')}
Allergens: ${p.allergens.isEmpty ? 'Bebas Alergen' : p.allergens.join(', ')}
Ingredients: ${p.ingredients.join(', ')}
Nutritionist Verified: YES (${p.nutritionistName})
''';
    }).join('\n---\n');

    const disclaimer = 'Saran ini bersifat edukasi & nutrisi dan tidak menggantikan diagnosis medis langsung dari dokter.';

    final isPro = userProfile?.isPremium ?? false;
    final tone = userProfile?.aiResponseStyle ?? 'Medis & Edukatif';

    String toneInstruction;
    if (!isPro) {
      toneInstruction = '''
SUBSCRIPTION STATUS: FREE TIER (Standar)
- TONE INSTRUCTION: Gunakan gaya bicara umum yang sopan, ramah, dan mendasar. Sampaikan informasi nutrisi standar yang membantu tanpa personalisasi gaya respon Pro.
''';
    } else {
      if (tone == 'Ringkas & Solutif') {
        toneInstruction = '''
SUBSCRIPTION STATUS: 🌟 PRO MEMBER (NutriMarket Plus VIP)
- ACTIVE PRO STYLE: ⚡ "Ringkas & Solutif"
- TONE INSTRUCTION (STRICT):
  * Jawab dengan SANGAT RINGKAS, PADAT, CEPAT, dan LANGSUNG KE INTI SOLUSI.
  * Tanpa basa-basi pembuka yang panjang.
  * Cukup 1 kalimat singkat pembuka, lalu daftar 2-3 menu aman (**Nama Menu**) dengan alasan 1 kalimat per menu.
  * Selesai dalam waktu baca 5 detik!
''';
      } else if (tone == 'Ramah & Kasual') {
        toneInstruction = '''
SUBSCRIPTION STATUS: 🌟 PRO MEMBER (NutriMarket Plus VIP)
- ACTIVE PRO STYLE: 🥗 "Ramah & Kasual" (Sahabat Diet & Bestie)
- TONE INSTRUCTION (STRICT):
  * Gunakan gaya bicara yang SANGAT SANTAI, HANGAT, SERU, dan BERSAHABAT seperti ngobrol dengan teman dekat/bestie diet (misal: "Halo kak!", "Yuk semangat jaga pola makan sehat bareng! ✨").
  * Gunakan banyak emoji positif (🥗, 🥑, ✨, 💚, 💪).
  * Berikan motivasi ceria agar pengguna merasa nyaman dan senang makan sehat.
''';
      } else {
        // Medis & Edukatif
        toneInstruction = '''
SUBSCRIPTION STATUS: 🌟 PRO MEMBER (NutriMarket Plus VIP)
- ACTIVE PRO STYLE: 🩺 "Medis & Edukatif" (Analisis Klinis Terverifikasi)
- TONE INSTRUCTION (STRICT):
  * Berikan penjelasan klinis yang ilmiah, mendalam, dan edukatif layaknya dokter spesialis gizi klinis profesional.
  * Jelaskan korelasi metabolisme tubuh secara ilmiah sederhana (misal: pengaruh indeks glikemik terhadap sensitivitas insulin, atau pengaruh natrium terhadap retensi cairan vascular).
  * Tunjukkan analisis mendalam kenapa menu yang dipilih 100% aman untuk profil kesehatannya.
''';
      }
    }

    final profileContext = userProfile != null
        ? '''
ACTIVE USER PROFILE & HEALTH RESTRICTIONS (STRICT COMPLIANCE REQUIRED):
- Name: ${userProfile.name} (Age: ${userProfile.age} yo)
- Primary Medical Condition / Diet Focus: ${userProfile.dietaryType}
- Health Goal: ${userProfile.healthGoal}
- STRICT FOOD ALLERGIES / PANTANGAN (NEVER VIOLATE): ${userProfile.foodAllergies.isEmpty ? 'None' : userProfile.foodAllergies.join(', ')}
- Daily Nutrition Limits: Max ${userProfile.maxSugarGrams}g Sugar, Max ${userProfile.maxSodiumMg}mg Sodium, Target ${userProfile.targetCalories} kcal, Min ${userProfile.targetProteinGrams}g Protein, Min ${userProfile.targetFiberGrams}g Fiber.
- Preferred AI Tone: $tone
- Subscription Tier: ${isPro ? 'NutriMarket Plus VIP Member (PRO AKTIF ✨)' : 'Free Tier'}

$toneInstruction
'''
        : '';

    return '''
You are NutriBot AI, an intelligent, friendly, and certified AI Clinical Nutritionist for NutriMarket.
You converse naturally and fluently in Bahasa Indonesia.

$profileContext

CRITICAL RULES & MOBILE-OPTIMIZED FORMATTING:
1. STRICTLY ADHERE TO THE TONE INSTRUCTION ABOVE:
   - If user is FREE TIER: Speak politely and standard.
   - If user is PRO with "Ringkas & Solutif": BE SUPER CONCISE AND BULLET-POINTED ONLY.
   - If user is PRO with "Ramah & Kasual": BE ENERGETIC, CHEERFUL, BESTIE-LIKE WITH EMOJIS.
   - If user is PRO with "Medis & Edukatif": PROVIDE SCIENTIFIC CLINICAL INSIGHTS.

2. STRICTLY NO RAW MARKDOWN TABLES (DILARANG MEMBUAT TABEL MARKDOWN):
   - NEVER use raw table syntax (| Col 1 | Col 2 |). Tables look distorted on mobile.
   - Always structure information using clean bullet points (•), bold highlights, and short paragraphs.

3. STRICT ALLERGY & PANTANGAN COMPLIANCE:
   - Strictly avoid all ingredients on the user's pantangan list (${userProfile?.foodAllergies.join(', ') ?? 'None'}).
   - When suggesting food, clearly mention why it is safe from their allergies and suitable for their condition (${userProfile?.dietaryType ?? 'Sehat'}).

4. EXACT MENU NAMES FOR CATALOG INTEGRATION:
   - Mention the exact menu names from the catalog: **Nasi Merah Ayam Panggang**, **Salmon Panggang Saos Lemon**, **Sup Sayur Ayam Kampung**, **Tofu Protein Bowl Organik**, **Oatmeal Blueberry Almond**.
   - This allows interactive visual product cards to automatically show beneath your message.

5. DISCLAIMER:
   - Include brief disclaimer at the end: "$disclaimer"

VERIFIED FOOD CATALOG:
$catalogContext
''';
  }

    // 1. If offline, return explicit offline network error
    if (!OfflineSyncService().isOnline) {
      throw const SocketException('Koneksi internet tidak tersedia.');
    }

    String? lastError;

    try {
      final systemPrompt = _getSystemPrompt(aiMode, userProfile);
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      final recentHistory = history.length > 8 ? history.sublist(history.length - 8) : history;
      for (final msg in recentHistory) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }

      if (messages.isEmpty || messages.last['role'] != 'user' || messages.last['content'] != userPrompt) {
        messages.add({'role': 'user', 'content': userPrompt});
      }

      // Try LLM models with retry helper
      for (final model in _models) {
        try {
          final result = await NetworkRetryHelper.execute<String?>(
            () async {
              final response = await http.post(
                Uri.parse(_baseUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_apiKey',
                },
                body: jsonEncode({
                  'model': model,
                  'messages': messages,
                  'temperature': 0.6,
                  'max_tokens': 1000,
                }),
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                String content = data['choices'][0]['message']['content'] as String;
                content = content.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
                if (content.isNotEmpty) return content;
              }
              return null;
            },
            maxAttempts: 3,
            timeoutDuration: const Duration(seconds: 8),
            actionName: 'GroqModel-$model',
            fallbackValue: null,
          );

          if (result != null && result.isNotEmpty) {
            return result;
          }
        } catch (e) {
          lastError = e.toString();
          debugPrint('[GroqService] Model $model error: $e');
        }
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('[GroqService] Unhandled error: $e');
    }

    // Explicit error response if network timeout or failed
    if (lastError != null && (lastError.toLowerCase().contains('timeout') || lastError.toLowerCase().contains('socket'))) {
      throw const SocketException('Koneksi internet tidak stabil atau timeout.');
    }

    throw Exception(lastError ?? 'Gagal terhubung ke layanan AI.');
  }

  String getFallbackResponse(String userPrompt, [List<ChatMessage>? history, UserProfile? userProfile]) {
    String query = userPrompt;
    if (query.contains('User Query:')) {
      query = query.split('User Query:').last.trim();
    }
    final lower = query.toLowerCase();

    // Context detection from recent history
    String recentContext = '';
    if (history != null && history.isNotEmpty) {
      for (final m in history.reversed) {
        final contentLower = m.content.toLowerCase();
        if (contentLower.contains('nasi merah') || contentLower.contains('ayam panggang')) {
          recentContext = 'Nasi Merah Ayam Panggang';
          break;
        }
        if (contentLower.contains('salmon')) {
          recentContext = 'Salmon Panggang Saos Lemon';
          break;
        }
        if (contentLower.contains('sup sayur') || contentLower.contains('sup')) {
          recentContext = 'Sup Sayur Ayam Kampung';
          break;
        }
      }
    }

    // 1. Check Greetings
    if (_isGreetingText(query)) {
      return '''
Halo! Saya NutriBot AI Ahli Gizi NutriMarket 👋

Saya siap membantu konsultasi menu sehat sesuai profil diet ${userProfile?.dietaryType ?? 'Anda'}. Ada yang ingin Anda tanyakan hari ini?
''';
    }

    // 2. Check Symptoms / Health Questions
    if (lower.contains('sakit kepala') ||
        lower.contains('pusing') ||
        lower.contains('kepala') ||
        lower.contains('migrain') ||
        lower.contains('demam') ||
        lower.contains('maag') ||
        lower.contains('mual') ||
        lower.contains('lemas') ||
        lower.contains('sakit')) {
      if (recentContext.isNotEmpty) {
        return '''
Mengenai pertanyaan Anda apakah **$recentContext** dapat meredakan sakit kepala:

• **Secara Langsung**: $recentContext bukan obat pereda nyeri. Namun, mengonsumsinya dapat membantu jika sakit kepala Anda dipicu oleh **kelaparan atau penurunan kadar gula darah** (hipoglikemia).
• **Kandungan Protein & Serat**: Membantu menstabilkan gula darah secara bertahap sehingga tubuh mendapatkan energi berkesinambungan.

**Saran Tambahan untuk Meredakan Sakit Kepala**:
1. **Minum Air Putih Murni**: Kebanyakan sakit kepala ringan dipicu oleh dehidrasi (kekurangan cairan).
2. **Istirahat Cukup**: Hindari paparan layar gadget berlebih dan istirahatlah di tempat sejuk.
3. **Periksakan ke Dokter**: Jika sakit kepala terasa parah, terus menerus, atau disertai demam/mual hebat.

*Saran ini bersifat edukasi nutrisi & kesehatan dan tidak menggantikan diagnosis medis dokter.*
''';
      }

      return '''
Untuk membantu meredakan **sakit kepala atau pusing**, berikut penjelasan & panduan nutrisi yang tepat:

1. **Cukupi Cairan (Dehidrasi)** 💧
   Dehidrasi adalah penyebab tersering sakit kepala. Minumlah 1–2 gelas air putih secara perlahan.

2. **Jaga Keseimbangan Gula Darah** 🥗
   Gula darah yang merosot akibat terlambat makan dapat memicu pusing. Makanlah makanan bergizi seimbang secara teratur.

3. **Istirahat & Hindari Ketegangan** 😴
   Kurangi paparan layar gadget dan istirahatlah sejenak di ruangan yang tenang.

*Catatan: Jika sakit kepala berlanjut atau terasa parah, segera konsultasikan langsung ke dokter.*
''';
    }

    // 3. Check Explicit Food / Product Recommendation Requests
    if (lower.contains('makanan') ||
        lower.contains('rekomendasi') ||
        lower.contains('diet') ||
        lower.contains('protein') ||
        lower.contains('menu') ||
        lower.contains('siang') ||
        lower.contains('malam') ||
        lower.contains('pantangan') ||
        lower.contains('aman')) {
      final safeMenus = ['Nasi Merah Ayam Panggang', 'Sup Sayur Ayam Kampung'];
      final allergies = userProfile?.foodAllergies ?? [];
      final allergyNote = allergies.isNotEmpty ? ' (bebas dari ${allergies.join(", ")})' : '';

      return '''
Berdasarkan profil diet **${userProfile?.dietaryType ?? "Sehat"}** dan pantangan Anda$allergyNote, berikut rekomendasi menu aman terverifikasi: **${safeMenus.join("**, **")}**.

*Saran ini bersifat rekomendasi nutrisi dan tidak menggantikan diagnosis medis langsung dari dokter.*
''';
    }

    // 4. Default Context-aware fallback
    if (recentContext.isNotEmpty) {
      return '''
Mengenai **$recentContext** yang sedang kita bahas, makanan ini kaya akan kandungan nutrisi seimbang untuk mendukung kesehatan harian Anda.

Ada hal spesifik lain tentang kandungan gizi atau manfaat kesehatan $recentContext yang ingin Anda ketahui?

*Saran ini bersifat edukasi nutrisi & kesehatan.*
''';
    }

    return '''
Saya memahami pertanyaan Anda seputar nutrisi dan kesehatan. Untuk kondisi **${userProfile?.dietaryType ?? "Anda"}**, kami merekomendasikan pola makan seimbang dan memperhatikan batas asupan gula serta garam harian.

*Saran ini bersifat edukasi nutrisi & kesehatan.*
''';
  }
}