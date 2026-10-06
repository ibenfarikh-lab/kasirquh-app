# Checklist Validasi Final — KasirQuh v3.4.0+9 di HP

> Lakukan SETELAH: install APK final + publish `firestore.rules` (lihat bawah).
> Uninstall aplikasi lama dulu bila sudah ada.

## 0. Persiapan Firebase (sekali saja)
1. Firebase Console → Firestore Database → **Rules** → tempel isi file
   `firestore.rules` dari repo → **Publish**.
2. Pastikan ada 1 akun admin: Authentication → buat user manual,
   lalu set custom claim `admin: true` via Admin SDK (satu kali).

## 1. Gateway & Akses
- [ ] Buka aplikasi: 3 slide tampil, stempel `KasirQuh v3.4.0+9` di footer.
- [ ] Tombol Lewati → masuk Mode Pelanggan sebagai tamu.
- [ ] Hotspot kanan atas → buat PIN 6 digit → layar login admin.
- [ ] Tap logo "Warunge Mimi" 5x di Beranda pelanggan → minta PIN.
- [ ] PIN salah 5x → terkunci 60 detik.

## 2. Tamu → Daftar → Disetujui → Belanja
- [ ] Tamu: katalog terlihat (harga & stok terbuka), bisa isi keranjang.
- [ ] Tamu: tap tab Chat / Akun → prompt "Mau lanjut? Login atau daftar dulu ya..."
- [ ] Tamu: Checkout → wajib daftar → setelah daftar: "Menunggu persetujuan admin",
      aksi checkout DILANJUTKAN otomatis setelah disetujui & login.
- [ ] Admin: Inbox → tile pendaftar bisa di-tap → Setujui.
- [ ] Pelanggan: login → checkout (COD) → kode pesanan `WM-000123` (urut!).
- [ ] Stok produk BERKURANG otomatis setelah checkout.
- [ ] Admin: Kasir Online → ubah status menunggu → dikemas → selesai.
- [ ] Pelanggan: tab Akun → riwayat pesanan tampil + status berubah.

## 3. Kasir Admin
- [ ] Tab Kasir: scan barcode (izin kamera diminta) + ketik manual.
- [ ] Bayar tunai → kembalian otomatis benar → struk tampil.
- [ ] Pembukuan: jurnal "Penjualan Tunai · Kasir (KSR-...)" tercatat.
- [ ] Stok produk berkurang sesuai penjualan.

## 4. Belanja Stok & Catatan
- [ ] Menu → Belanja Stok: pilih barang → isi harga → simpan.
- [ ] Harga jual Rp0 DITOLAK (tidak bisa simpan).
- [ ] Jurnal "Kulakan · ..." = uang tunai yang dibayar (bukan hasil pembulatan).
- [ ] Kartu Modal belanja berkurang.
- [ ] Tab Catatan: kartu "Belanja Stok" muncul hari ini; Ubah/Hapus hanya arsip.

## 5. Pembukuan
- [ ] Kosong → "Belum ada transaksi" (BUKAN Rp0/Rp0/Rp0).
- [ ] Ada transaksi → ringkasan Pemasukan/Pengeluaran/Laba benar.
- [ ] Laporan: grafik 7 hari + tombol CSV.

## 6. Chat & Rumpi
- [ ] Pelanggan: Chat → 3 sub-tab (Rumpi / Toko / Komunitas).
- [ ] Rumpi: tulis postingan + foto → muncul di feed; like bertambah (tidak diam).
- [ ] Komunitas: kirim pesan → terlihat.
- [ ] Chat Toko: pelanggan kirim → admin terima di Chat; admin balas → pelanggan terima.
- [ ] Badge merah Chat berkurang setelah dibaca.

## 7. Koin
- [ ] Admin: Koin Warga → tambah koin ke pelanggan → riwayat koin tercatat.
- [ ] Penukaran (kurangi koin): jurnal "beban_promosi" tercatat di Pembukuan.

## 8. Promo
- [ ] Admin: Beranda Pelanggan → tambah promo + diskon persen → simpan.
- [ ] Pelanggan: katalog tampil harga coret + harga promo; keranjang pakai harga promo.

## 9. Notifikasi & Izin
- [ ] Izin notifikasi diminta dengan penjelasan; pesanan baru (admin) → heads-up.
- [ ] Status pesanan berubah (pelanggan) → heads-up "Status pesanan berubah".

## 10. Offline
- [ ] Matikan internet: katalog tetap tampil (cache); checkout → pesan jujur butuh internet.
- [ ] Belanja stok offline → modal tetap berkurang saat online kembali (delta antrean).

## Tanda lolos
Semua kotak tercentang + tidak ada angka/transaksi yang muncul dari ketiadaan data.
Lapor temuan apa pun (screenshot + langkah) untuk diperbaiki.
