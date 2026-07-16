# SP3A - Smart Water Management System 💧

SP3A (Sistem Pengelolaan Penyediaan Air Minum) adalah aplikasi *mobile* terintegrasi berbasis **Flutter** dan **Supabase** yang dirancang untuk mengotomatisasi seluruh siklus bisnis pengelolaan air bersih. Sistem ini melayani tiga peran utama: **Admin**, **Petugas Lapangan**, dan **Pelanggan (Warga)**.

---

## 🚀 Fitur Unggulan

* **Smart OCR Scanner (Petugas):** Membaca angka meteran air secara otomatis menggunakan Google ML Kit dengan pemrosesan gambar (*auto-crop & contrast enhancement*) di dalam memori tanpa memotong foto bukti fisik.
* **Bulk Payment Checkout (Pelanggan):** Membayar beberapa tagihan sekaligus dalam satu kali transaksi terintegrasi dengan **Midtrans Snap API**.
* **Kokpit Interaktif (Admin):** Analisis data pemakaian air dan pendapatan (Rumah Tangga vs Bisnis) menggunakan grafik interaktif (`fl_chart`) dan tabel laporan berdesain *high-density*.
* **Push Notification (FCM):** Pengingat tagihan otomatis dari petugas ke HP pelanggan menggunakan Supabase Edge Functions dan Firebase Cloud Messaging.
* **Deep Link Password Recovery:** Keamanan akun dengan alur *reset password* terenkripsi yang langsung membuka aplikasi melalui *custom URL scheme*.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart), Riverpod (State Management), fl_chart.
* **Backend & Database:** Supabase (PostgreSQL, Auth, Storage, Edge Functions / Deno).
* **AI & Vision:** Google ML Kit Text Recognition, image (Dart package).
* **Payment Gateway:** Midtrans Snap API.
* **Notification:** Firebase Cloud Messaging (FCM).

---

## 🗄️ Langkah 1: Persiapan Database Supabase

Buka [Supabase Dashboard](https://supabase.com/), buat *project* baru, lalu jalankan skrip SQL di bawah ini pada menu **SQL Editor** untuk membuat skema tabel dan relasi:

```sql
-- 1. Tabel Users (Menggabungkan Admin, Petugas, dan Pelanggan)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'petugas', 'pelanggan') NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    alamat TEXT NULL,
    tipe_pelanggan ENUM('rumah_tangga', 'bisnis') NULL COMMENT 'Hanya diisi jika role = pelanggan',
    is_first_login BOOLEAN DEFAULT TRUE COMMENT 'Untuk memaksa pelanggan ubah password di awal',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL
    fcm_token TEXT NOT NULL
);

-- 2. Tabel Tarif (Master Data agar Admin bisa mengubah harga kapan saja)
CREATE TABLE tarif (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipe_pelanggan ENUM('rumah_tangga', 'bisnis') NOT NULL UNIQUE,
    harga_per_m3 DECIMAL(10,2) NOT NULL,
    biaya_abodemen DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3. Tabel Pencatatan Meteran
CREATE TABLE pencatatan_meteran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pelanggan_id INT NOT NULL,
    dicatat_oleh INT NOT NULL COMMENT 'Bisa ID Petugas atau ID Pelanggan (self-service)',
    periode_bulan INT NOT NULL COMMENT 'Bulan pencatatan (1-12)',
    periode_tahun INT NOT NULL COMMENT 'Tahun pencatatan (YYYY)',
    angka_meteran INT NOT NULL,
    foto_bukti VARCHAR(255) NOT NULL COMMENT 'Path atau URL gambar hasil foto/scan OCR',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (pelanggan_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (dicatat_oleh) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Tabel Tagihan
CREATE TABLE tagihan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pelanggan_id INT NOT NULL,
    pencatatan_id INT NOT NULL,
    pemakaian_m3 INT NOT NULL COMMENT 'Selisih angka meteran bulan ini dan bulan sebelumnya',
    total_tagihan DECIMAL(12,2) NOT NULL COMMENT '(pemakaian_m3 * harga_per_m3) + biaya_abodemen',
    status_tagihan ENUM('belum_dibayar', 'lunas') DEFAULT 'belum_dibayar',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (pelanggan_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pencatatan_id) REFERENCES pencatatan_meteran(id) ON DELETE CASCADE
);

-- 5. Tabel Pembayaran
CREATE TABLE pembayaran (
    id VARCHAR(50) PRIMARY KEY COMMENT 'Bisa diisi Order ID dari Payment Gateway (misal: SP3A-INV-123)',
    tagihan_id INT NOT NULL,
    metode_pembayaran VARCHAR(50) NOT NULL COMMENT 'Contoh: Tunai, QRIS, BCA VA, GoPay',
    jumlah_bayar DECIMAL(12,2) NOT NULL,
    status_pembayaran ENUM('pending', 'sukses', 'gagal') DEFAULT 'pending',
    waktu_bayar DATETIME NULL,
    diterima_oleh INT NULL COMMENT 'Diisi ID Petugas jika bayar cash, dikosongkan jika via Payment Gateway',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id) ON DELETE CASCADE,
    FOREIGN KEY (diterima_oleh) REFERENCES users(id) ON DELETE SET NULL
);
```

### Konfigurasi Storage & Auth

1. **Storage Bucket:** Masuk ke menu **Storage**, buat *bucket* baru bernama `foto_bukti` dengan kebijakan *Public* (atau *Authenticated Read/Write*).
2. **URL Configuration (Deep Link):** Masuk ke **Authentication -> URL Configuration**, tambahkan `sp3a://reset-callback` pada kolom **Redirect URLs**.
3. **Email Template:** Pada **Authentication -> Email Templates -> Reset Password**, pastikan tombol/link menggunakan variabel URL standar Supabase: `{{ .ConfirmationURL }}`.

---

## ⚡ Langkah 2: Deploy Supabase Edge Functions (Backend)

Sistem ini membutuhkan 2 Edge Functions untuk mengelola *Payment Gateway* dan *Push Notification*. Pastikan Anda sudah menginstal [Supabase CLI](https://supabase.com/docs/guides/cli).

1. **Login dan Link Project via Terminal:**

```bash
supabase login
supabase link --project-ref ID_PROJECT_SUPABASE_ANDA
```

2. **Set Secret Variables (Kunci API):**

```bash
supabase secrets set MIDTRANS_SERVER_KEY="server_key_midtrans_anda"
supabase secrets set MIDTRANS_CLIENT_KEY="client_key_midtrans_anda"
supabase secrets set FIREBASE_SERVER_KEY="server_key_firebase_fcm_anda"
```

3. **Deploy Fungsi ke Server Supabase:**

```bash
# Fungsi untuk transaksi Midtrans (Bulk Payment & Webhook Handler)
supabase functions deploy midtrans-handler

# Fungsi untuk pengingat tagihan via Firebase Cloud Messaging
supabase functions deploy send-reminder
```

---

## 🔥 Langkah 3: Konfigurasi Firebase (Android/iOS)

1. Buat *project* baru di [Firebase Console](https://console.firebase.google.com/).
2. Tambahkan aplikasi Android dengan *Package Name* yang sesuai (contoh: `com.sp3a.waterapp`).
3. Unduh file `google-services.json` dan letakkan ke dalam direktori `android/app/`.
4. Buka file `android/app/src/main/AndroidManifest.xml`, pastikan konfigurasi berikut sudah ditambahkan:

```xml
<manifest ...>
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application ...>
        <activity android:name=".MainActivity" ...>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="sp3a" android:host="reset-callback" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

## 💻 Langkah 4: Instalasi & Konfigurasi Flutter

### Prasyarat

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 atau lebih baru)
* Dart SDK (v3.3.0 atau lebih baru)
* Android Studio / VS Code dengan ekstensi Flutter

### Panduan Instalasi

1. **Kloning Repositori:**

```bash
git clone https://github.com/username/sp3a_flutter.git
cd sp3a_flutter
```

2. **Unduh Dependencies:**

```bash
flutter pub get
```

3. **Konfigurasi Environment (`.env`):**

Buat file `.env` di direktori akar (*root*) proyek Anda dan isi kredensial berikut:

```env
# Supabase Credentials
SUPABASE_URL=https://idproject.supabase.co
SUPABASE_ANON_KEY=ey...

# Midtrans Credentials (Sandbox/Production)
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxx
MIDTRANS_IS_PRODUCTION=false
```

4. **Jalankan Aplikasi:**

Pastikan emulator atau perangkat fisik sudah terhubung, lalu jalankan perintah:

```bash
flutter run
```

---

## 🏗️ Arsitektur & Direktori Proyek

```text
sp3a_flutter/
├── android/                   # Konfigurasi native Android (FCM, Deep Link, Permissions)
├── lib/
│   ├── core/                  # Tema, konstan, utilitas, dan widget global (LogoutDialog, dll)
│   ├── models/                # Model data Dart (Pelanggan, Tagihan, Pembayaran)
│   ├── providers/             # State management menggunakan Riverpod / ProviderScope
│   ├── screens/
│   │   ├── admin/             # Dashboard Admin (fl_chart statistik, Laporan padat)
│   │   ├── petugas/           # Dashboard Petugas (Kamera OCR, Filter Tugas, Tombol Ingatkan)
│   │   ├── pelanggan/         # Dashboard Warga (List Tagihan, Checkbox Bulk, BottomSheet)
│   │   └── auth/              # Login, Lupa Password, dan Halaman Reset Password
│   ├── services/              # Integrasi API (SupabaseService, NotificationService, Midtrans)
│   └── main.dart              # Titik masuk aplikasi (Inisialisasi Firebase & Supabase)
├── supabase/
│   └── functions/             # Kode sumber Deno/TypeScript untuk Edge Functions
├── .env                       # Variabel lingkungan (Tidak diunggah ke Git)
└── pubspec.yaml                # Daftar dependensi package Flutter
```

---

## 🤝 Kontribusi & Pengembang

Proyek ini dikembangkan sebagai solusi transformasi digital SP3A/PAM desa. Jika Anda menemukan bug atau ingin menambahkan fitur baru, silakan buat *Issue* atau kirimkan *Pull Request*.