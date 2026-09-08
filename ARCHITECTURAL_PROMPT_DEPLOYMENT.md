# Architectural Prompt for Automated CI/CD Deployment Pipeline

**Target Application:** NutriMarket (clev_ai)  
**Engineering Domain:** DevSecOps, Mobile CI/CD, & Automated App Store Release  
**Milestone:** CPMK 6 - Security, Automated CI/CD Pipeline, & App Store Release  

---

## 1. Konsep & Tujuan Architectural Prompt
Architectural Prompt for Deployment adalah cetak biru instruksi tingkat tinggi (*high-context system prompt*) yang dirancang khusus untuk AI Code Generator, DevSecOps Engineer, atau LLM Automation Agent agar mampu menghasilkan, memvalidasi, dan memelihara skrip otomasi pipeline CI/CD (GitHub Actions / Fastlane) tanpa kesalahan konfigurasi biner (*zero-touch deployment*).

Prompt ini mencakup:
* Standar gerbang mutu (*Quality Gate*): static analysis, zero fatal errors, dan pengujian unit otomatis.
* Keamanan biner (*Binary Security*): ProGuard/R8 rules, symbol splitting, dan obfuscation flag.
* Keamanan kredensial (*Secret Management*): Base64 keystore decoding dan compile-time injection via `--dart-define`.
* Jalur distribusi rilis (*Distribution Channels*): Google Play Console Internal Testing dan Firebase App Distribution.

---

## 2. Template Architectural Prompt (AI DevSecOps System Prompt)

```text
[SYSTEM ARCHITECTURAL PROMPT: FLUTTER DEVSECOPS & APP STORE DEPLOYMENT]

Anda adalah Senior DevSecOps Architect yang berspesialisasi dalam ekosistem Mobile Flutter, Google Play Store Release, dan Security Hardening. Tugas Anda adalah merancang dan menghasilkan pipeline CI/CD otomatis berbasis GitHub Actions dan Fastlane untuk aplikasi Flutter "NutriMarket (clev_ai)".

Spesifikasi & Konstrain Wajib:
1. QUALITY GATE & STATIC ANALYSIS:
   - Pipeline harus mengeksekusi 'flutter analyze --no-fatal-infos' dan 'flutter test --coverage'.
   - Jika terdapat error fatal, pipeline harus membatalkan (fail-fast) proses build.

2. KEAMANAN RAHASIA & ENVIROMENT INJECTION:
   - DILARANG KERAS menyimpan plain text API keys (.env) di repositori Git.
   - Gunakan GitHub Repository Secrets untuk:
     * SUPABASE_URL, SUPABASE_ANON_KEY, GROQ_API_KEY, APP_ENV.
     * ANDROID_KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD.
   - Dekode keystore dari Base64 secara dinamis ke 'android/app/upload-keystore.jks' saat runner berjalan.
   - Terapkan Compile-Time Environment Injection menggunakan flag '--dart-define' saat perintah build.

3. OBFUSCATION & HARDENING BINER:
   - Build Android App Bundle (AAB) dan APK rilis WAJIB menyertakan flag:
     * '--obfuscate'
     * '--split-debug-info=build/app/outputs/symbols'
   - Pastikan ProGuard/R8 diaktifkan pada 'android/app/build.gradle' (minifyEnabled true, shrinkResources true).

4. MULTI-CHANNEL ARTIFACT DEPLOYMENT:
   - Simpan artefak rilis (AAB, APK, dan debug symbols) menggunakan actions/upload-artifact@v4.
   - Konfigurasikan Fastlane lane (:deploy_playstore) untuk upload otomatis ke Google Play Console track 'internal'.
   - Konfigurasikan Fastlane lane (:distribute_beta) untuk distribusi file APK ke tim tester beta.

Hasil yang Diharapkan:
- File .github/workflows/deploy.yml yang siap eksekusi (production-ready).
- File android/fastlane/Fastfile yang modular dan terdokumentasi.
```

---

## 3. Hasil Realisasi dari Architectural Prompt

Berdasarkan prompt arsitektural di atas, telah dihasilkan dan diimplementasikan dua berkas otomasi CI/CD utama pada proyek NutriMarket:
1. **GitHub Actions Workflow:** `.github/workflows/deploy.yml`  
   * Pekerjaan `analyze_and_test`: Linting, static analysis, dan unit tests.
   * Pekerjaan `build_and_deploy_android`: Decoding keystore base64, kompilasi Signed Obfuscated AAB & APK, injeksi compile-time defines, serta upload artefak rilis.
2. **Fastlane Automation:** `android/fastlane/Fastfile`  
   * Lane `deploy_playstore`: Otomasi kompilasi bundle dan upload langsung ke Google Play Console track `internal`.
   * Lane `distribute_beta`: Otomasi kompilasi APK rilis untuk pengujian tim internal.
