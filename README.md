<img width="2200" height="726" alt="Frame 7" src="https://github.com/user-attachments/assets/8ae65afd-d481-4afa-8505-6af99525234c" />

# MuslimNoob - Aplikasi Pemandu Ibadah
a free, clean, and simple muslim prayer reminder and guide

![stars](https://img.shields.io/github/stars/itzfurizugg/MuslimNoob) ![forks](https://img.shields.io/github/forks/itzfurizugg/MuslimNoob) ![downloads](https://img.shields.io/github/downloads/itzfurizugg/MuslimNoob/total) ![flutter](https://img.shields.io/badge/flutter-enabled-02569B?logo=flutter&logoColor=white)
---

## Apa itu MuslimNoob?
MuslimNoob adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu Muslim pemula dalam mempelajari dan menjalankan ibadah sehari-hari dengan lebih mudah dan terarah.
Dengan MuslimNoob, pengguna dapat:

🕐 Melihat jadwal sholat berdasarkan kota
🧭 Mengetahui arah kiblat secara real-time
📿 Membaca doa harian dan dzikir
📖 Mempelajari tata cara ibadah step-by-step
🔔 Mendapatkan notifikasi azan otomatis
📚 Mengakses panduan sholat lengkap dengan teks arab dan latin

---

## Fitur Utama
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
