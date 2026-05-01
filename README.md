# 🌙 MuslimNoob

> 🕌 Aplikasi islami mobile untuk Muslim pemula — panduan sholat, jadwal azan, doa harian, kiblat, dan tata cara ibadah dalam satu aplikasi.

---

## 📥 Download / Clone

👉 Klik tombol di bawah untuk membuka repository:

[![GitHub](https://img.shields.io/badge/GitHub-MuslimNoob-0D4A4A?style=for-the-badge&logo=github&logoColor=white)](https://github.com/itzfurizugg/MuslimNoob)

Atau clone via Git:

```bash
git clone https://github.com/itzfurizugg/MuslimNoob.git
cd MuslimNoob
```

---

## 📖 Pengenalan Project

**MuslimNoob** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu Muslim pemula dalam mempelajari dan menjalankan ibadah sehari-hari dengan lebih mudah dan terarah.

Dengan MuslimNoob, pengguna dapat:

- 🕐 Melihat jadwal sholat berdasarkan kota
- 🧭 Mengetahui arah kiblat secara real-time
- 📿 Membaca doa harian dan dzikir
- 📖 Mempelajari tata cara ibadah step-by-step
- 🔔 Mendapatkan notifikasi azan otomatis
- 📚 Mengakses panduan sholat lengkap dengan teks arab dan latin

Project ini menggabungkan Flutter sebagai frontend mobile, Supabase sebagai backend, dan admin web berbasis Vite + React untuk manajemen konten.

---

## 🎯 Tujuan Project

- 🕌 Membantu Muslim pemula memahami tata cara ibadah
- 📅 Menyediakan informasi waktu sholat yang akurat
- 📿 Menjadi referensi doa & dzikir sehari-hari
- 🧭 Memudahkan pencarian arah kiblat di manapun
- 💡 Menjadi platform eksplorasi teknologi Flutter + Supabase

---

## ✨ Fitur Utama

### 🕐 Jadwal Sholat
- Jadwal sholat berdasarkan kota/wilayah
- Data dari database Supabase (sumber: KEMENAG RI)
- Picker kota yang mudah digunakan

### 🔔 Notifikasi Azan
- Notifikasi lokal otomatis menggunakan `awesome_notifications`
- Dijadwalkan langsung dari device tanpa server push
- Dapat dikustomisasi per waktu sholat

### 🧭 Kompas Kiblat
- Arah kiblat real-time menggunakan sensor kompas
- Deteksi lokasi otomatis via GPS
- Visualisasi kompas yang intuitif

### 📿 Doa & Dzikir
- Kategori: Doa Harian, Dzikir, Lainnya
- Teks arab, transliterasi, dan terjemahan
- Data dikelola dari admin web

### 📖 Tata Cara Ibadah
- Panduan step-by-step dengan foto
- Teks arab dan latin per langkah
- Konten: Tata Cara Sholat, Wudhu, Memandikan Jenazah, dll

### 👤 Autentikasi
- Register & login dengan email + OTP
- Email dikirim via Gmail SMTP / Resend
- Session management dengan Supabase Auth

---

## 📸 Screenshot

| Splash | Home | Jadwal Sholat |
|--------|------|---------------|
| ![Splash](docs/splash.png) | ![Home](docs/home.png) | ![Jadwal](docs/jadwal.png) |

| Kiblat | Doa | Panduan |
|--------|-----|---------|
| ![Kiblat](docs/kiblat.png) | ![Doa](docs/doa.png) | ![Panduan](docs/panduan.png) |

> Simpan screenshot di folder `docs/` agar tampil di README

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|-------|-----------|
| **Mobile** | Flutter (Dart) |
| **Backend** | Supabase (PostgreSQL + Auth + Realtime) |
| **Admin Web** | Vite + React (JavaScript) |
| **Deploy Admin** | Vercel |
| **Email** | Gmail SMTP / Resend |
| **Notifikasi** | awesome_notifications |
| **Kompas** | flutter_compass + geolocator |

---

## ⚙️ Cara Menjalankan Project

### Prasyarat
- Flutter SDK `>=3.0.0`
- Dart `>=3.0.0`
- Akun Supabase
- Node.js (untuk admin web)

### 1. Clone & Install

```bash
git clone https://github.com/itzfurizugg/MuslimNoob.git
cd MuslimNoob
flutter pub get
```

### 2. Setup Environment

Buat file `lib/config/supabase_config.dart`:

```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Jalankan App

```bash
flutter run
```

### 4. Jalankan Admin Web

```bash
cd web-admin
npm install
npm run dev
```

---

## 📂 Struktur Project

```
MuslimNoob/
├── lib/
│   ├── screen/
│   │   ├── auth/          # Login, Register, OTP
│   │   ├── dua/           # Doa & Dzikir
│   │   ├── tutorial/      # Tata Cara & Panduan Sholat
│   │   ├── home_screen.dart
│   │   ├── prayer_schedule_screen.dart
│   │   ├── qibla_screen.dart
│   │   └── splash_screen.dart
│   ├── services/
│   │   ├── dua_service.dart
│   │   ├── prayer_service.dart
│   │   ├── qibla_service.dart
│   │   ├── tutorial_service.dart
│   │   └── azan_notification_service.dart
│   └── main.dart
├── web-admin/             # Admin web Vite + React
│   ├── src/
│   │   └── pages/
│   │       ├── ManageDua.jsx
│   │       └── ManageTutorial.jsx
│   └── .env
├── supabase/
│   └── functions/         # Edge Functions
├── docs/                  # Screenshots untuk README
└── README.md
```

---

## 🗄️ Struktur Database

```
cities              — Data kota Indonesia
jadwal_sholat       — Jadwal sholat per kota per tanggal
dua_categories      — Kategori doa (Doa Harian, Dzikir, Lainnya)
duas                — Data doa & dzikir
tutorials           — Tata cara ibadah
tutorial_steps      — Langkah-langkah per tutorial
broadcasts          — Broadcast notifikasi (Supabase Realtime)
```

---

## 📦 Flutter Packages

```yaml
supabase_flutter: ^2.3.0
shared_preferences: ^2.2.2
flutter_compass: ^0.8.0
geolocator: ^13.0.2
geocoding: ^3.0.0
permission_handler: ^11.3.1
vibration: ^2.0.0
awesome_notifications: ^0.9.3+1
```

---

## 🤝 Kontribusi

Kontribusi terbuka untuk siapa saja!

1. Fork repo ini
2. Buat branch baru (`git checkout -b fitur-baru`)
3. Commit perubahan (`git commit -m 'Tambah fitur baru'`)
4. Push ke branch (`git push origin fitur-baru`)
5. Buat Pull Request

---

## 📄 License

MIT License — bebas digunakan dan dimodifikasi.

---

## ⭐ Support

Kalau project ini bermanfaat, jangan lupa kasih ⭐ di GitHub ya!

[![GitHub stars](https://img.shields.io/github/stars/itzfurizugg/MuslimNoob?style=social)](https://github.com/itzfurizugg/MuslimNoob)
[![GitHub forks](https://img.shields.io/github/forks/itzfurizugg/MuslimNoob?style=social)](https://github.com/itzfurizugg/MuslimNoob/fork)
