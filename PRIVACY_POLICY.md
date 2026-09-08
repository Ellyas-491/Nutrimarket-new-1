# Kebijakan Privasi NutriMarket (Privacy Policy)

**Terakhir Diperbarui:** 8 September 2026  
**Aplikasi:** NutriMarket (clev_ai)  
**Pengembang:** Tim Pengembang NutriMarket (ClevAI Mobile Team)  
**Kontak Privasi:** privacy@nutrimarket.id  

---

## 1. Pendahuluan
NutriMarket ("kami", "aplikasi") menghargai dan melindungi privasi setiap pengguna ("Anda"). Kebijakan Privasi ini menjelaskan bagaimana informasi pribadi, data kesehatan/diet, dan informasi transaksi Anda dikumpulkan, digunakan, dilindungi, dan dikelola saat Anda menggunakan aplikasi mobile NutriMarket.

Aplikasi ini tunduk pada Undang-Undang Perlindungan Data Pribadi (UU No. 27 Tahun 2022) dan standar keamanan informasi internasional.

---

## 2. Informasi yang Kami Kumpulkan
Kami mengumpulkan informasi yang Anda berikan secara sukarela untuk mendukung fungsionalitas marketplace makanan sehat dan bimbingan nutrisi AI:
1. **Informasi Akun:** Nama lengkap, alamat email, kata sandi terenkripsi (via Supabase Auth), dan token OAuth Google Sign-In.
2. **Informasi Kesehatan & Gaya Hidup:** Usia, berat badan, tinggi badan, target kesehatan harian, preferensi diet (contoh: Rendah Gula, Tinggi Protein, Vegetarian), dan riwayat alergi makanan.
3. **Informasi Transaksi & Pengantaran:** Alamat pengantaran, catatan pesanan, riwayat pembelian, dan metode pembayaran pilihan (QRIS / Virtual Account).
4. **Riwayat Konsultasi AI:** Log percakapan interaktif dengan Asisten Nutrisi Cerdas untuk memberikan bimbingan menu harian yang berkelanjutan.

---

## 3. Penggunaan Informasi
Informasi yang dikumpulkan digunakan semata-mata untuk:
* Memproses pesanan makanan sehat dan memfasilitasi pengantaran oleh kurir.
* Menyesuaikan rekomendasi makanan dan perhitungan kalori harian berdasarkan profil kesehatan Anda.
* Mengirimkan notifikasi pembaruan status pesanan, konfirmasi pembayaran, dan promo langganan VIP NutriMarket Plus.
* Meningkatkan performa aplikasi, keamanan akun, dan pencegahan kecurangan transaksi.

---

## 4. Keamanan & Enkripsi Data
Kami menerapkan langkah-langkah teknis berstandar industri untuk melindungi data Anda:
* **Enkripsi Transit:** Seluruh komunikasi data antara aplikasi klien dan backend cloud dilindungi oleh enkripsi TLS 1.3 / HTTPS.
* **Enkripsi Lokal:** Kredensial otentikasi disimpan di perangkat menggunakan modul `SecureStorageService` dengan enkripsi berkunci.
* **Row Level Security (RLS):** Database PostgreSQL Supabase kami membatasi hak akses secara ketat sehingga data Anda tidak dapat diakses oleh pengguna lain.
* **Keamanan Biner:** Kode sumber aplikasi diproteksi dengan teknik *Obfuscation* (ProGuard/R8 dan Dart Symbol Stripping) untuk mencegah rekayasa balik (*reverse engineering*).

---

## 5. Berbagi Data dengan Pihak Ketiga
Kami tidak pernah menjual data pribadi Anda kepada pihak mana pun. Data hanya dibagikan secara terbatas kepada penyedia infrastruktur terpercaya:
* **Supabase Inc.:** Penyedia backend database cloud terenkripsi.
* **Groq Cloud API:** Pemrosesan inferensi bahasa alami untuk konsultasi nutrisi AI (tanpa menyimpan identitas pengguna).
* **Payment Gateway (Midtrans Sandbox Simulator):** Eksekusi otentikasi transaksi pembayaran digital.

---

## 6. Hak Pengguna & Penghapusan Akun
Anda berhak untuk:
* Mengakses, memperbarui, atau mengoreksi data profil dan preferensi diet Anda kapan saja melalui menu Pengaturan Profil.
* Menghapus seluruh riwayat pesanan, riwayat chat konsultasi AI, dan data alamat lokal.
* Mengajukan permohonan penghapusan akun permanen beserta seluruh data terkait di database cloud dengan mengirimkan permohonan ke **privacy@nutrimarket.id**.

---

## 7. Perubahan Kebijakan Privasi
Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Setiap perubahan substansial akan diumumkan melalui notifikasi dalam aplikasi. Penggunaan berkelanjutan atas aplikasi NutriMarket dianggap sebagai persetujuan Anda terhadap perubahan tersebut.
