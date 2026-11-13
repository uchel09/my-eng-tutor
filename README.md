# My English Tutor

Aplikasi AI English Speaking Tutor pribadi untuk Android dengan alur latihan bertahap ala Stimuler, dibangun menggunakan Flutter, GetX, SQLite (Drift), dan Gemini Live + REST API.

## Fitur Utama

- **Kurikulum Bertahap CEFR (`A1` – `C2`)**: 6 level dengan 24 misi terstruktur (*Guided 60s Speaking* & *Live Roleplay*), sistem lock/unlock otomatis berbasis skor minimal (`70/100`), serta opsi **Quick Placement Test** dan **Free Talk Bebas**.
- **Latihan Bicara Real-Time**: Streaming mikrofon PCM16 16kHz ke Gemini Multimodal Live API dan pemutaran suara tutor PCM16 24kHz lengkap dengan live transcript & text fallback.
- **Rapor *Speech Insight***: Evaluasi otomatis pasca-sesi mencakup skor *Overall*, *Fluency*, *Grammar*, *Vocabulary*, *Pronunciation Clarity*, deteksi *filler words*, koreksi *Better Phrasing*, dan rekomendasi kosakata baru.
- **Review Offline 100%**: Tab **Review** memuat *Vocab Bank* (filter CEFR, pencarian, tambah kosakata manual, counter `Mastered`), *Mistake Log*, dan *Riwayat Sesi* yang tersimpan lokal di perangkat tanpa kuota API.
- **Privasi & Portabilitas**: API Key hanya tersimpan di database lokal perangkat dan mendukung *Export / Import Backup JSON* (tanpa mengekspor API Key).

---

## 1. Cara Mendapatkan Gemini API Key Gratis

1. Buka [Google AI Studio](https://aistudio.google.com/) dan login dengan akun Google.
2. Pilih menu **Get API key** → **Create API key**.
3. Salin API key yang dihasilkan (umumnya diawali `AIzaSy...`).

## 2. Pengaturan Awal di Tab Settings

1. Buka tab **Settings** di aplikasi.
2. Tempelkan API Key pada bagian **1. Gemini API Key (Free Tier)**, lalu ketuk **Simpan**.
3. Ketuk **Tes Koneksi** untuk memastikan API Key aktif dan dapat mengakses model evaluasi (`gemini-2.5-flash` secara default).
4. Pada bagian **3. Perangkat Audio Android**, ketuk **Tes Mic & Speaker** untuk memberikan izin mikrofon Android dan menguji pemutaran audio PCM 24kHz.
5. *(Opsional)* Sesuaikan **Dark Mode**, **Bantuan Bahasa Indonesia (Level A1–A2)**, atau aktifkan **Unlock All Misi (Mode Bebas)** jika ingin melompat langsung ke level mana pun.

## 3. Cara Belajar

- **Cek Level Awal**: Jalankan **Quick Placement Test** dari tab **Home** untuk membuka level awal sesuai kemampuanmu secara otomatis.
- **Ikuti Peta Belajar (`Roadmap`)**: Selesaikan misi *Guided 60 Detik* maupun *Live Roleplay* dari `A1` hingga `C2`. Skor `>= 70` akan menandai misi selesai dan membuka misi/level berikutnya.
- **Lihat Rapor *Speech Insight***: Setelah mengetuk **Selesai & Nilai**, AI akan merangkum skor 4 pilar, memperbaiki kalimatmu di *Better Phrasing*, dan menyimpan kosakata baru ke *Vocab Bank*.
- **Belajar Offline di Tab `Review`**:
  - **Vocab Bank**: Cari kosakata, filter per level CEFR (`A1`–`C2`), tambah kosakata manual, dan ketuk **Hafal +1** untuk mencatat penguasaan.
  - **Mistake Log**: Tinjau kembali kalimat yang perlu diperbaiki beserta penjelasannya.
  - **Riwayat**: Ketuk kartu sesi mana saja untuk membuka ulang rapor *Speech Insight* secara offline.
- **Backup & Restore JSON**: Gunakan **Export Backup JSON** dan **Import Backup JSON** di tab **Settings** untuk memindahkan riwayat belajar, skor, streak, dan kosakata antarperangkat.

## 4. Tips Hemat Kuota Gemini Free Tier

- Fokus menyelesaikan **1 misi per sesi** (durasi ~60 detik) sebelum menekan **Selesai & Nilai** agar penggunaan token audio & evaluasi tetap efisien.
- Hindari mengetuk reconnect berulang kali saat sinyal sedang tidak stabil; tunggu jaringan stabil sebelum memulai sesi Live WebSocket.
- Gunakan tab **Review** (*Vocab Bank*, *Mistake Log*, *Riwayat*) untuk mengulang materi secara **100% offline** tanpa memanggil Gemini API.
- Bila terkena limit kuota sementara (*rate limit / 429*), tunggu beberapa saat lalu ketuk **Coba Nilai Lagi** pada layar hasil tanpa perlu mengulang rekaman sesi.

---

## 5. Perintah Menjalankan, Tes & Build APK

Jalankan perintah berikut dari root folder proyek:

```bash
# Cek perangkat / emulator Android yang terhubung
flutter devices

# Menjalankan aplikasi langsung dalam mode debug
flutter run

# Menjalankan analisis statis & seluruh unit/widget test
flutter analyze
flutter test --reporter expanded

# (Opsional) Membangun APK release jika ingin meng-install permanen di HP
flutter build apk --release
```

Lokasi APK opsional:
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
