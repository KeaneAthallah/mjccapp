# MOROWALI JUARA COMMAND CENTER (MJCC) — Flutter Android Client

Aplikasi **Flutter untuk Android** dari *MOROWALI JUARA Command Center (MJCC)*. Aplikasi
ini adalah klien mobile berbahasa Indonesia untuk backend Laravel yang berada di
`../mjcc` (API pada prefix `/api/v1`). Digunakan oleh warga Kabupaten Morowali untuk
mengirim SOS darurat, dan oleh operator/petugas untuk memantau serta menangani
perkembangan data wilayah secara real-time.

## Tentang Aplikasi

MJCC menyatukan data ketiga sektor (pendidikan, kesehatan, dan ketertiban/keamanan)
dalam satu pusat kendali. Aplikasi Android ini menampilkan dashboard, peta gabungan,
data master, pengelolaan pengguna, audit log, hingga fitur darurat (SOS) yang bekerja
secara langsung (live).

## Fitur Utama

- **Dashboard Pusat Kendali** — ringkasan statistik tiga sektor (sekolah, fasilitas
  kesehatan, poskamling/pasar) beserta alert "Perlu Perhatian".
- **Peta Gabungan** — peta interaktif dengan penanda seluruh aset wilayah per kategori
  (SD/SMP, Puskesmas, Rumah Sakit, Polsek, Kelurahan, Pasar, Poskamling, Tipkamtikmas).
- **SOS Darurat (Live)** — tombol darurat satu sentuhan:
  - Mengirim lokasi GPS (geolocator) beserta akurasi dan pesan opsional ke pusat kendali.
  - Melacak status penanganan secara **otomatis setiap 15 detik** tanpa perlu refresh.
  - Operator/admin dapat menerima, menuju lokasi, menyelesaikan, atau membatalkan SOS.
  - Inbox/riwayat SOS ikut diperbarui otomatis saat berada di halaman teratas.
- **Data Pendidikan** — pengelolaan sekolah.
- **Data Kesehatan** — pengelolaan fasilitas kesehatan (Puskesmas, Pustu, Rumah Sakit, dll).
- **Data Ketertiban** — polsek, tipkamtikmas, poskamling, dan pasar.
- **Data Master** — kecamatan, kelurahan, dan subjek/mata pelajaran.
- **Manajemen Pengguna** — kelola akun (khusus admin).
- **Daftar Akun & Verifikasi Email** — registrasi mandiri via API (role selalu `viewer` dari backend) dikonfirmasi kode 6 digit dari email, ditampilkan dengan email termask, plus tombol kirim ulang kode dengan jeda 60 detik.
- **Audit Log** — jejak aktivitas sistem (khusus admin).
- **Profil** — ubah data diri, foto, dan kata sandi.
- **Tema Gelap/Terang** — pengaturan tema dalam aplikasi.
- **Dukungan peran (role)** — `viewer`, `operator`, dan `admin` dengan hak akses berbeda.

## Teknologi

- **Flutter / Dart** (SDK `^3.13.2`) — UI Material Design berbahasa Indonesia.
- **Provider** — manajemen state.
- **Dio** — HTTP client ke API backend.
- **flutter_secure_storage** — penyimpanan token autentikasi dengan aman.
- **flutter_map + latlong2** — peta berbasis OpenStreetMap (offline rendering, tanpa Google Maps).
- **geolocator** — lokasi GPS untuk SOS darurat.
- **intl** — pemformatan tanggal/angka.

## Prasyarat

- Flutter SDK terpasang dan dikonfigurasi untuk Android.
- Backend Laravel MJCC berjalan (repositori `mjcc`, serve di port `8000`):
  `php artisan serve` atau `composer run dev` di direktori `../mjcc`.

## Menjalankan

### 1. Emulator Android

Emulator Android secara default sudah mengarah ke host melalui alias `10.0.2.2`,
sehingga cukup menjalankan:

```sh
flutter pub get
flutter run
```

### 2. Perangkat fisik (HP Android)

Ganti base URL API agar menunjuk ke IP komputer di jaringan LAN yang sama, lalu build:

```sh
flutter build apk --dart-define=API_BASE_URL=http://<IP-KOMPUTER>:8000
```

Pasang file APK hasil build pada perangkat, lalu izinkan akses lokasi saat aplikasi
memintanya (dibutuhkan untuk fitur SOS).

> Base URL default adalah `http://10.0.2.2:8000` (alias host saat development di
> emulator). Path API prefix `/api/v1` ditambahkan secara otomatis oleh aplikasi.

## Struktur Proyek

```
lib/
├── core/                  # Konfigurasi, jaringan (Dio), storage, tema, util
│   ├── config/            # AppConfig (base URL API)
│   ├── location/          # LocationService (GPS untuk SOS)
│   ├── network/           # ApiClient, ApiResponse, pagination
│   ├── storage/           # Secure storage (token)
│   └── theme/             # Warna, spacing, tema terang/gelap
├── data/
│   ├── models/            # Model data (school, health, polsek, sos_alert, dll)
│   └── repositories/      # Akses API per modul
└── presentation/
    ├── providers/         # State management (Provider)
    ├── screens/           # Halaman: dashboard, map, master, sos, users, audit, dll
    └── widgets/           # Komponen UI yang dapat digunakan kembali
```

## Pengujian

```sh
flutter analyze
flutter test
```

Test mencakup parsing model (mis. `DashboardOverview`, `SosAlert`), smoke test
aplikasi, serta alur autentikasi (login, registrasi akun, verifikasi kode email,
kirim ulang kode) yang dijalankan dengan repositori tiruan tanpa koneksi jaringan.

## Informasi Tambahan

- Nama paket: `id.go.morowali.mjcc`
- Backend API: lihat repositori Laravel `mjcc` (endpoint `/api/v1`, autentikasi Sanctum).
- File ini adalah dokumentasi konfigurasi/intro; detail pengembangan Flutter umum dapat
  dilihat di [flutter.dev/docs](https://docs.flutter.dev).