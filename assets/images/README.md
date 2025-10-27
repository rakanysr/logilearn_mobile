# Assets Images

Folder ini digunakan untuk menyimpan gambar-gambar yang akan digunakan dalam aplikasi.

## Cara Menggunakan

Setelah menambahkan gambar ke folder ini, Anda dapat menggunakannya di Flutter dengan cara berikut:

```dart
Image.asset('assets/images/nama_gambar.png')
```

Atau:

```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/images/nama_gambar.png'),
      fit: BoxFit.cover,
    ),
  ),
)
```

## Catatan

- Pastikan format gambar yang didukung: PNG, JPG, JPEG, GIF, WebP
- Untuk mengoptimalkan performa, gunakan gambar dengan ukuran yang sesuai
- Setelah menambahkan gambar baru, jalankan `flutter pub get`

