# Clev AI

Kalkulator pintar berbasis AI dengan tampilan seperti ChatGPT. Cukup ketik pertanyaan matematika — tidak perlu tombol angka.

**Powered by:** Flutter + Groq API (gratis)

## Fitur

- UI chat minimalis ala ChatGPT
- Kalkulator AI — tanya dalam bahasa natural
- Android & iOS dari satu codebase
- Groq API (Llama 3.3 70B) — tier gratis

## Setup

### 1. Install Flutter

Download dari [flutter.dev](https://docs.flutter.dev/get-started/install/windows) dan pastikan `flutter doctor` berhasil.

### 2. Siapkan API Key Groq

1. Daftar/login di [console.groq.com](https://console.groq.com)
2. Buat API Key di menu **API Keys**
3. Buka file `.env` di folder proyek ini
4. Ganti isinya:

```
GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxx
```

### 3. Jalankan proyek

```bash
cd clev_ai
flutter create . --org com.clevai
flutter pub get
flutter run
```

Perintah `flutter create .` melengkapi file platform (ikon launcher, dll.) tanpa menimpa kode di `lib/`.

### 4. Build APK (Android)

```bash
flutter build apk --release
```

APK ada di: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Build iOS (butuh Mac + Xcode)

```bash
flutter build ios --release
```

## Struktur proyek

```
lib/
├── main.dart              # Entry point
├── models/                # Model data chat
├── screens/               # Halaman utama
├── services/              # Groq API
├── theme/                 # Warna & tema
└── widgets/               # Input bar, bubble chat, dll.
```

## Contoh pertanyaan

- `Berapa 25% dari 840?`
- `Hitung luas lingkaran radius 7 cm`
- `1250 dibagi 16 berapa?`
- `Konversi 100 fahrenheit ke celsius`

## Catatan

- File `.env` tidak di-commit ke git (sudah ada di `.gitignore`)
- Ikon + dan mic di input bar siap untuk fitur lanjutan (lampiran, voice input)
- Untuk produksi, pertimbangkan menyimpan API key di backend, bukan di APK
