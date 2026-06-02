# Unit Testing CampusCare

File ini menjelaskan unit test yang ditambahkan untuk fitur-fitur utama aplikasi CampusCare.

## Fokus testing

Testing dibuat untuk logic utama aplikasi, bukan 100% coverage semua file. Fokusnya:

1. **Model laporan/tiket**
   - Parsing data tiket dari format MongoDB ke `TiketModel`.
   - Default value saat data tidak lengkap.
   - Konversi `TiketModel` ke JSON untuk cache/simpan data.

2. **Model notifikasi**
   - Parsing dokumen notifikasi dari database.
   - Konversi notifikasi ke JSON.
   - Default value saat field kosong.

3. **Form pembuatan laporan**
   - Validasi step foto, lokasi, kategori/judul, dan deskripsi.
   - Reset field saat kategori berubah.
   - Reset seluruh form.
   - Validasi submit sebelum menyentuh koneksi internet/database.

4. **Dashboard admin**
   - Ringkasan total laporan, belum direview, dan selesai.
   - Jumlah kategori Sarpras/Kebersihan.
   - Persentase kategori.
   - Klasifikasi urgensi.
   - Filter tab admin: menunggu tindakan dan selesai direview.
   - Filter status approved/rejected.
   - Sort waktu terbaru, waktu terlama, dan urgensi tertinggi.

5. **Feed laporan**
   - Ambil laporan berdasarkan `idTiket` dari state lokal.
   - Deteksi apakah user sudah vote laporan tertentu.
   - Format waktu relatif di feed.

## File yang ditambahkan

- `test/helpers/ticket_fixture.dart`
- `test/models/tiket_model_test.dart`
- `test/models/notification_model_test.dart`
- `test/providers/report_form_provider_test.dart`
- `test/providers/admin_dashboard_provider_test.dart`
- `test/providers/feed_provider_test.dart`
- `test/widget_test.dart` diganti dari counter template menjadi smoke test sederhana.

## Perubahan kecil pada source agar testable

Dua provider diberi opsi `autoFetch` supaya saat unit test tidak langsung memanggil MongoDB:

- `AdminDashboardProvider({bool autoFetch = true})`
- `FeedProvider({bool autoFetch = true})`

Nilai default tetap `true`, jadi pemakaian aplikasi normal tidak berubah.

Ditambahkan juga helper khusus testing:

- `setReportsForTesting(...)`
- `setNotificationsForTesting(...)`
- `setVotedTicketIdsForTesting(...)`

## Cara menjalankan

Dari root project:

```bash
flutter pub get
flutter test
```

Kalau muncul error asset `.env`, pastikan file `.env` ada di root project karena `pubspec.yaml` memasukkan `.env` sebagai asset. Pada ZIP ini sudah ditambahkan `.env` placeholder kosong agar test/build tidak gagal karena file asset hilang. Isi nilai aslinya sesuai kebutuhan lokal masing-masing.

## Catatan penting

Test ini sengaja tidak memanggil MongoDB, Firebase, Google Sign-In, Supabase Storage, kamera, atau koneksi internet sungguhan. Bagian-bagian itu lebih cocok masuk **integration test** atau perlu refactor dependency injection supaya bisa dimock dengan rapi.
