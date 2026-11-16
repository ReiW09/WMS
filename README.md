# WMS Gudang Kain

## Setup Supabase

1. Buat project di Supabase.
2. Buka **SQL Editor**, jalankan seluruh isi `supabase-setup.sql`, lalu pastikan skrip selesai tanpa error.
3. Pada **Authentication → Providers**, aktifkan Email. Jangan aktifkan pendaftaran publik untuk aplikasi gudang.
4. Buat user admin pertama pada **Authentication → Users**. Salin UUID user tersebut dan jalankan di SQL Editor:

   ```sql
   insert into public.wms_users (id, role)
   values ('UUID-USER-ADMIN', 'admin');
   ```

5. Salin **Project URL** dan **anon/public key** dari Project Settings → API ke `supabase-config.js`:

   ```js
   window.WMS_SUPABASE_CONFIG = {
     url: "https://zuohkxquruvxwjfjpzbd.supabase.co",
     anonKey: "nilai-anon-atau-publishable-key"
   };
   ```

   Key publik memang dipakai browser; keamanan data ditegakkan oleh Row Level Security. Jangan pernah menaruh `service_role` key atau password di file ini.
6. Di **Database → Publications/Realtime**, aktifkan Realtime untuk tabel `wms_docs`.
7. Daftarkan akun staf di Authentication → Users. Untuk setiap user, tambahkan satu baris `wms_users` dengan UUID yang sama dan role `operator` atau `viewer`. Admin dapat mengelola peran lewat SQL Editor atau Table Editor.
8. Di repository GitHub, buka **Settings → Pages** dan pilih **GitHub Actions** sebagai Build and deployment source. Workflow di `.github/workflows/pages.yml` akan deploy otomatis setiap ada push ke branch `main`.
9. URL GitHub Pages untuk repository ini adalah `https://reiw09.github.io/WMS/`. Di Supabase, buka **Authentication → URL Configuration**, atur Site URL ke URL tersebut dan tambahkan ke Redirect URLs agar reset password berfungsi.

## Peran

- `admin`: mengelola akun/peran, impor inventory, pengaturan, dan penghapusan.
- `operator`: membaca dan mencatat transaksi WMS.
- `viewer`: membaca data tanpa mengubahnya.

Row Level Security menolak akses bagi akun tanpa baris peran yang valid. Jika Supabase belum dikonfigurasi, website yang di-host menampilkan instruksi setup alih-alih menyimpan data diam-diam di browser.

## Mode lokal

File `WMS Gudang Kain.html` masih bisa dibuka langsung untuk menggunakan penyimpanan lokal browser. Data lokal tidak tersinkron dengan project Supabase.
