# SP3A Projek

Aplikasi SP3A adalah aplikasi berbasis Flutter untuk pengelolaan pelanggan, tagihan, dan pembayaran (Sistem Pengelolaan Penyediaan Air Minum/Sistem Terkait).

## 🚀 Fitur Utama
- **Manajemen Pelanggan**: Melihat detail pelanggan dan riwayat.
- **Pengelolaan Tagihan**: Pembuatan dan pengecekan tagihan pelanggan.
- **Pencatatan Meteran**: Integrasi dengan OCR (Google ML Kit) dan kamera untuk membaca angka meteran secara otomatis.
- **Ekspor & Cetak PDF**: Pembuatan laporan atau struk tagihan.
- **Notifikasi Push**: Terintegrasi dengan Firebase Cloud Messaging.

## 📋 Prasyarat
Pastikan Anda sudah menginstal beberapa perangkat lunak berikut sebelum menjalankan proyek ini:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.9.2 atau lebih baru)
- IDE seperti [Visual Studio Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio)
- Konfigurasi untuk Supabase dan Firebase.

## ⚙️ Persiapan dan Instalasi

1. **Kloning Repositori**
   ```bash
   git clone <url-repositori-anda>
   cd sp3a_flutter
   ```

2. **Instalasi Dependencies**
   Jalankan perintah berikut untuk mengunduh semua package yang diperlukan:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Environment (Variabel Lingkungan)**
   Buat file `.env` di root direktori proyek Anda. File ini telah diregistrasikan di `pubspec.yaml` sebagai assets. Isi kredensial yang dibutuhkan seperti URL Supabase dan Key Supabase:
   ```env
   # Contoh isi .env
   SUPABASE_URL=url_anda_disini
   SUPABASE_ANON_KEY=key_anda_disini
   ```

4. **Jalankan Aplikasi**
   Untuk menjalankan aplikasi di emulator atau perangkat yang sudah terhubung:
   ```bash
   flutter run
   ```

## 🏗 Struktur Utama Proyek
- `lib/` - Direktori utama untuk kode Dart.
  - `lib/screens/` - Halaman-halaman UI (contoh: `pelanggan_detail_screen.dart`).
  - `lib/providers/` - Logika state management menggunakan **Riverpod** (contoh: `tagihan_provider.dart`).
  - `lib/core/` - Berisi widget reusable (contoh: `status_badge.dart`), tema, dan konfigurasi inti.

## 📚 Dokumentasi Tambahan
Jika ini adalah pertama kalinya Anda menggunakan Flutter, beberapa sumber di bawah ini dapat membantu:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Dokumentasi Resmi Flutter](https://docs.flutter.dev/)
