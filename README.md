# 📱 LogiLearn Mobile

> Aplikasi mobile pembelajaran logika interaktif berbasis quiz untuk pelajar.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

---

## � Deskripsi

**LogiLearn Mobile** adalah aplikasi mobile yang dirancang untuk membantu pelajar belajar logika melalui sistem quiz interaktif. Aplikasi ini mendukung berbagai jenis soal dan menyediakan pengalaman belajar yang terstruktur melalui sistem section dan level.

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 **Authentication** | Login & Register untuk pelajar |
| 📚 **Section & Level** | Materi terstruktur dalam section dan level |
| ❓ **Quiz Interaktif** | Soal Pilihan Ganda (PG) dan Esai |
| � **Progress Tracking** | Pelacakan attempt dan skor |
| 👤 **Profile Management** | Kelola profil dan ubah password |
| � **Caching** | Optimasi performa dengan local caching |
| 🔒 **Secure Storage** | Penyimpanan token yang aman |

---

## 🏗️ Struktur Proyek

```
lib/
├── main.dart              # Entry point aplikasi
├── services/              # API Service & Business Logic
│   └── api_service.dart   # HTTP requests ke backend
├── view/                  # Halaman UI
│   ├── login_view.dart    # Halaman login
│   ├── register_view.dart # Halaman registrasi
│   ├── home_view.dart     # Halaman utama
│   ├── quiz_view.dart     # Halaman quiz
│   ├── account_view.dart  # Halaman akun
│   └── ...
├── widget/                # Reusable widgets
└── widgetSoal/            # Widget khusus soal
```

---

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK ^3.9.2
- Dart SDK
- Android Studio / VS Code
- Emulator atau device fisik

### Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/username/logilearn_mobile.git
   cd logilearn_mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 📦 Dependencies

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `http` | ^1.6.0 | HTTP requests ke API |
| `flutter_secure_storage` | ^9.0.0 | Penyimpanan token yang aman |
| `shared_preferences` | ^2.2.2 | Caching data lokal |
| `google_fonts` | ^6.2.1 | Custom fonts |
| `cupertino_icons` | ^1.0.8 | iOS style icons |

---

## � Konfigurasi

### Base URL API

| Platform | URL |
|----------|-----|
| Web | `http://localhost:3030/api` |
| Android Emulator | `http://10.0.2.2:3030/api` |
| iOS/Desktop | `http://localhost:3030/api` |

---

## � Dokumentasi

Untuk dokumentasi API lengkap, lihat:

📄 **[DOKUMENTASI_API.md](./DOKUMENTASI_API.md)**

---

## 🎓 Informasi Proyek

| Item | Detail |
|------|--------|
| **Mata Kuliah** | Pemrograman Perangkat Bergerak |
| **Versi** | 1.0.0 |
| **Framework** | Flutter |
| **Bahasa** | Dart |

---

## 👥 Tim Pengembang

- **Muhammad Rakan Yusra** 
- **Muhammad Faiz Adya**
- **Raka Valrizqy Akhdansyah**
- **Naufal Fahreza**
- **Ariq Hisyam Nabil**
- **Relingga Aditya**

---

## � Lisensi

Proyek ini dibuat untuk keperluan akademik (Tugas Besar).

---

**Dibuat dengan ❤️ menggunakan Flutter**
