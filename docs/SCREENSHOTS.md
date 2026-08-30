# Panduan Screenshot Aplikasi MJCC (Android)

Panduan ini menjelaskan cara mengambil dan menyimpan screenshot aplikasi Android
MJCC agar dapat ditampilkan di `README.md`.

## Lokasi & Format File

- Simpan semua screenshot di folder **`docs/screenshots/`** di dalam repositori
  aplikasi ini (`mjccapp`). Folder sudah dibuat melalui panduan ini.
- Format: **PNG** (disarankan) atau JPG.
- Ukuran ideal: lebar **720–1080 px**, orientasi **potret** (9:16), sesuai resolusi
  layar perangkat. Jangan diukur ulang/disaring berlebihan.
- Nama file: **kebab-case dan deskriptif**, mis. `sos-screen.png`.
- Aturan: tanpa spasi, tanpa huruf kapital, tanpa karakter khusus.

## Alur Kerja

1. Jalankan aplikasi (lihat README untuk setup). Untuk emulator tidak perlu
   konfigurasi tambahan; untuk perangkat fisik gunakan
   `--dart-define=API_BASE_URL=http://<IP-KOMPUTER>:8000`.
2. Buka layar yang ingin diabadikan dan siapkan *state*-nya (sudah login, ada data,
   status SOS tertentu, dst.).
3. Ambil screenshot:
   - **Manual:** tombol screenshot perangkat (volume bawah + power).
   - **Emulator:** tombol kamera di side panel emulator.
   - **ADB (opsional):**
     ```
     adb exec-out screencap -p > docs/screenshots/nama-file.png
     ```
   - **PowerShell (Windows) jika `>` gagal:**
     ```
     adb exec-out screencap -p | Set-Content -Encoding Byte docs/screenshots/nama-file.png
     ```
4. Salin/letakkan file tersebut ke folder `docs/screenshots/`.
5. Beri tahu asisten untuk memperbarui `README.md` — README akan menampilkan
   gambar dengan tautan relatif:
   ```markdown
   ![SOS Darurat](docs/screenshots/sos-screen.png)
   ```

## Daftar Screenshot yang Disarankan

Gunakan nama file berikut agar konsisten. Tanda `(wajib)` berarti sebaiknya ada
untuk README lengkap; lainnya opsional.

| Nama file                      | Layar / keadaan yang ditampilkan                        |
|--------------------------------|---------------------------------------------------------|
| `login-screen.png`             | Halaman login                                           |
| `dashboard-overview.png` (wajib) | Dashboard utama dengan kartu statistik 3 sektor      |
| `map-screen.png`               | Peta gabungan dengan penanda berbagai kategori          |
| `dashboard-dark.png`           | Dashboard dengan tema gelap                             |
| `sos-screen.png` (wajib)       | Halaman SOS Darurat dengan tombol "KIRIM SOS"           |
| `sos-locating.png`             | Dialog "Mencari lokasi Anda..." saat mengirim SOS        |
| `sos-active-card.png` (wajib)  | Kartu SOS aktif dengan status tracker (Aktif/Diterima/Menuju/Selesai) |
| `sos-inbox.png` (wajib)        | Inbox SOS operator (daftar permintaan)                  |
| `sos-detail.png`               | Detail SOS dengan peta dan tombol tindakan operator     |
| `sos-history.png`              | Riwayat SOS pengguna biasa                              |
| `master-data.png`              | Menu Data Master (kecamatan/kelurahan/subjek)           |
| `resource-list.png`            | Contoh daftar resource (mis. daftar sekolah)            |
| `users-screen.png`             | Manajemen pengguna (peran/status)                       |
| `audit-log.png`                | Audit log (riwayat aktivitas sistem)                    |
| `profile-screen.png`           | Halaman profil pengguna                                 |

## Tips

- Pastikan **data di backend realistis** (nama, koordinat di dalam Morowali) agar
  screenshot terlihat profesional.
- Untuk SOS aktif, buat satu permintaan sungguhan lewat aplikasi lalu tangkap
  kartu live-nya; status akan ter-update otomatis.
- Hindari menampilkan data pribadi yang sensitif.
- Setelah semua file masuk, jalankan `git add docs/screenshots/` bersama file
  `README.md` yang diperbarui, lalu commit dan push.