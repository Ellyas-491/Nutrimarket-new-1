# 🥗 NutriMarket — Mobile Marketplace Makanan Sehat & AI Nutritionist

**NutriMarket** adalah aplikasi mobile modern berbasis Flutter yang dirancang khusus untuk membantu pengguna menjalani gaya hidup sehat melalui kurasi makanan bergizi, personalisasi diet (diabetes, hipertensi, rendah purin, dll.), konsultasi nutrisi berbasis AI, pelacakan pesanan makanan sehat *real-time*, dan integrasi cloud **Supabase**.

---

## 🌟 Fitur Utama

### 1. 🛒 Marketplace Makanan Sehat
- **Katalog Terverifikasi Ahli Gizi**: Menampilkan kalori, makronutrisi (karbohidrat, protein, lemak, serat, gula), serta label keamanan kesehatan.
- **Filter Berdasarkan Diet & Alergen**: Pilihan khusus untuk Diabetes, Rendah Garam (Hipertensi), Rendah Gula, Tinggi Protein, Asam Urat Rendah Purin, dan Bebas Alergen.
- **Keranjang Belanja & Checkout Real-Time**: Integrasi voucher diskon, ongkir pintar, dan multi-metode pembayaran (E-Wallet, Transfer Bank, COD).

### 2. 🤖 Asisten Konsultasi Nutrisi AI
- Chatbot cerdas dengan dukungan suara (Voice-to-Text & Text-to-Speech) untuk rekomendasi makanan harian, analisis pantangan nutrisi, dan edukasi gizi personal.

### 3. 📦 Pelacakan Pesanan & Driver Kurir
- Status pengantaran terintegrasi (*auto-sync* cloud database).
- Informasi kurir (*Bambang Wijaya*), nomor kontak aktif, dan plat kendaraan otomatis muncul saat pesanan dalam proses antar.
- Konfirmasi penyelesaian pesanan & upload bukti pengantaran.

### 4. 👤 Profil Kesehatan Personal & Keluarga
- Perhitungan indeks massa tubuh (BMI) otomatis.
- Multi-profil kesehatan untuk seluruh anggota keluarga.
- Sinkronisasi data aman (alamat pengiriman, riwayat pesanan, menu favorit) menggunakan Supabase.

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3 (Dart)
- **State Management**: Provider
- **Backend & Database**: Supabase Cloud (PostgreSQL, Auth, Realtime Database, Row Level Security)
- **AI Engine**: Groq API (Llama 3.3 70B Fast Inference)
- **Local Storage**: `shared_preferences` & `flutter_secure_storage`

---

## 🚀 Panduan Memulai (Setup)

### 1. Prasyarat
- Flutter SDK (versi >= 3.2.0)
- Android Studio / VS Code dengan Flutter Extension

### 2. Konfigurasi Environment (`.env`)
Buat file `.env` di root proyek (atau salin dari `.env.example`):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
GROQ_API_KEY=your-groq-api-key
```

### 3. Setup Database Supabase
Jalankan skrip SQL di file [`supabase_schema.sql`](supabase_schema.sql) pada Supabase SQL Editor Anda untuk membuat tabel profil, produk, keranjang, pesanan, dan alamat.

### 4. Jalankan Aplikasi
```bash
# Install dependensi
flutter pub get

# Jalankan pada emulator atau perangkat fisik
flutter run
```

### 5. Build APK Rilis (Android)
```bash
flutter build apk --release
```
Hasil file APK rilis: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📂 Struktur Direktori Proyek

```
lib/
├── models/         # Data model (UserProfile, FoodProduct, Order, CartItem, Chat)
├── screens/        # UI Screen (Home, Discover, AI Assistant, Cart, Orders, Profile, Auth)
├── services/       # Layanan data (SupabaseService, GroqService, OrderService, CartService)
├── theme/          # Palet warna, tipografi, & tema gelap/terang
└── widgets/        # Komponen modular reusable (Cards, Sheets, Header, Toasts)
```

---

## 📄 Lisensi
Hak Cipta © 2026 NutriMarket Team. Seluruh hak cipta dilindungi.
