/// Semua string UI Bahasa Indonesia — satu sumber kebenaran.
class Strings {
  // Umum
  static const appName = 'Warunge Mimi';
  static const poweredBy = 'Powered by KasirQuh';
  static const batal = 'Batal';
  static const simpan = 'Simpan';
  static const hapus = 'Hapus';
  static const ubah = 'Ubah';
  static const lewati = 'Lewati';
  static const kembali = 'Kembali';
  static const tutup = 'Tutup';
  static const cari = 'Cari';

  // Gateway — copy selaras prototipe v3.
  static const slide1Kicker = 'PROMO UTAMA';
  static const slide1Title = 'Hemat belanja, senang di rumah';
  static const slide1Sub =
      'Promo pilihan Warunge Mimi untuk kebutuhan harian keluarga.';
  static const slide2Kicker = 'SEMBAKO';
  static const slide2Title = 'Sembako lengkap, tinggal pilih';
  static const slide2Sub =
      'Minyak, gula, mi, dan kebutuhan dapur siap untuk stok rumah.';
  static const slide3Kicker = 'JAJAN & MINUMAN';
  static const slide3Title = 'Jajan dan minuman favoritmu';
  static const slide3Sub =
      'Camilan renyah dan minuman segar untuk teman santai kapan saja.';
  static const gatewayHint = 'Ketuk atau geser untuk lanjut';
  static const taglineToko = 'Belanja dekat, terasa hangat';

  // Tamu
  static const guestLockTitle = 'Mau lanjut?';
  static const guestLockBody = 'Login atau daftar dulu ya...';
  static const guestLockPending =
      'Akunmu masih menunggu persetujuan admin.';

  // Pencarian & katalog
  static const cariBarang = 'Cari barang...';
  static const semua = 'Semua';
  static const tambahKeranjang = 'Tambah ke Keranjang';
  static const jumlah = 'Jumlah';
  static const habis = 'Habis';
  static const stokMenipis = 'Stok menipis';

  // Keranjang & checkout
  static const keranjangKosong = 'Keranjang masih kosong';
  static const keranjangKosongHint = 'Yuk isi dengan barang kebutuhanmu.';
  static const checkout = 'Checkout';
  static const buatPesanan = 'Buat Pesanan';
  static const metodePembayaran = 'Metode pembayaran';
  static const bayarDiTempat = 'COD — bayar di tempat';
  static const transferBank = 'Transfer bank';
  static const catatanOpsional = 'Catatan (opsional)';
  static const pesananBerhasil = 'Pesanan berhasil dibuat!';
  static const kodePesanan = 'Kode pesanan';
  static const lihatPesanan = 'Lihat Pesanan';
  static const butuhInternet = 'Butuh koneksi internet untuk checkout.';
  static const butuhInternetUmum = 'Butuh koneksi internet.';
  static const stokTidakCukup = 'Stok tidak cukup untuk:';
  static const checkoutGagal = 'Pesanan gagal dibuat. Coba lagi ya...';

  // Beranda
  static const promoSpesial = 'Promo Spesial';
  static const infoToko = 'Info Toko';
  static const bukaSekarang = 'Buka sekarang';
  static const tutupSekarang = 'Tutup sekarang';
  static const belanjaSekarang = 'Belanja Sekarang';

  // Chat
  // (dihapus Fase 4: chat pelanggan kini nyata — Rumpi/Toko/Komunitas)

  // Akun
  static const pesananSaya = 'Pesanan Saya';
  static const koinSaya = 'Koin Saya';
  static const keluar = 'Keluar';
  static const yakinKeluar = 'Yakin mau keluar dari akun?';
  static const detailPesanan = 'Detail Pesanan';

  // Auth
  static const masuk = 'Masuk';
  static const daftar = 'Daftar';
  static const email = 'Email';
  static const kataSandi = 'Kata sandi';
  static const nama = 'Nama';
  static const fiturKhususPelanggan = 'Fitur khusus pelanggan';
  static const akunWarungJudul = 'Masuk / Daftar Akun Warung';
  static const menungguPersetujuan =
      'Pendaftaran diterima. Menunggu persetujuan admin ya...';
  static const belumDisetujui =
      'Akunmu belum disetujui admin. Coba lagi nanti ya...';
  static const masukGagal = 'Email atau kata sandi salah.';

  // PIN Admin
  static const buatPin = 'Buat PIN Admin';
  static const buatPinHint = 'PIN 6 digit untuk membuka Mode Admin.';
  static const konfirmasiPin = 'Konfirmasi PIN';
  static const pinTidakSama = 'PIN tidak sama. Coba lagi.';
  static const masukkanPin = 'Masukkan PIN Admin';
  static const pinSalah = 'PIN salah.';
  static const pinTerkunci =
      'Terlalu banyak salah. Tunggu 60 detik lalu coba lagi.';
  static const lupaPin = 'Lupa PIN?';
  static const aturUlangPin = 'PIN berhasil dibuat.';
  static const pakaiSidikJari = 'Pakai sidik jari';
  static const sidikJariGagal =
      'Sidik jari tidak cocok. Coba lagi atau pakai PIN.';
  // Pesan jujur per sebab — jangan samarkan semua jadi "tidak cocok".
  static const sidikJariBelumTerdaftar =
      'Belum ada sidik jari terdaftar di HP ini. Daftarkan dulu di Pengaturan HP, lalu coba lagi.';
  static const sidikJariTerkunciSementara =
      'Sensor sidik jari terkunci sementara. Tunggu sebentar lalu coba lagi.';
  static const sidikJariTerkunci =
      'Sensor sidik jari terkunci. Buka kunci HP pakai PIN/pola sekali, lalu coba lagi.';
  static const sidikJariButuhKunciLayar =
      'Pasang kunci layar (PIN/pola/sandi HP) dulu, lalu coba lagi.';
  static const sidikJariTidakTersedia =
      'Sidik jari tidak bisa dipakai di HP ini saat ini. Pakai PIN saja.';
  static const sidikJariDibatalkan = 'Dibatalkan.';
  // Saklar sidik jari di Pengaturan (Akun).
  static const bukaDenganSidikJari = 'Buka dengan sidik jari';
  static const bukaDenganSidikJariHint = 'Masuk Mode Admin tanpa ketik PIN';
  static const sidikJariTakDidukung =
      'Sidik jari tidak tersedia di HP ini';
  static const alasanAktifkanSidikJari =
      'Aktifkan buka sidik jari untuk Mode Admin';

  // Empty state (jujur — tanpa angka/data contoh)
  static const belumAdaPesanan = 'Belum ada pesanan';
  static const belumAdaPesananAktif = 'Belum ada pesanan aktif';
  static const belumAdaPelanggan = 'Belum ada data pelanggan';
  static const belumAdaPendaftar = 'Belum ada pendaftar';
  static const belumAdaTransaksi = 'Belum ada transaksi';
  static const belumAdaProduk = 'Belum ada produk';

  // State galat (beda dari kosong — jangan klaim "belum ada" saat gagal muat)
  static const gagalMuatProduk = 'Gagal memuat produk';
  static const gagalMuatPesanan = 'Gagal memuat pesanan';
  static const periksaKoneksi = 'Periksa koneksi internet, lalu coba lagi.';
  static const sukaGagal = 'Gagal memberi suka. Coba lagi nanti.';
  static const hargaJualNol = 'Harga jual harus lebih dari Rp0 untuk';
  static const galat = 'Galat';
  static const menyimpan = 'Menyimpan...';
  static const belumDiatur = 'Belum diatur';
  static const emailTerdaftar = 'Email ini sudah terdaftar. Masuk saja ya...';
  static const emailTidakValid = 'Format email tidak valid.';
  static const sandiTerlaluLemah = 'Kata sandi minimal 6 karakter.';
  static const daftarGagal = 'Pendaftaran gagal. Coba lagi nanti.';
  static const jenisDiskon = 'Jenis diskon';
  static const nilaiPersen = 'Nilai (mis. 10 untuk 10%)';
  static const nilaiNominal = 'Nilai (Rp)';

  // Tab pelanggan
  static const tabBeranda = 'Beranda';
  static const tabProduk = 'Produk';
  static const tabKeranjang = 'Keranjang';
  static const tabChat = 'Chat';
  static const tabAkun = 'Akun';

  // Tab admin
  static const tabKasir = 'Kasir';
  static const tabInbox = 'Inbox';
  static const tabCatatan = 'Catatan';
  static const tabMenu = 'Menu';

  // Status
  static const menunggu = 'MENUNGGU';
  static const disetujui = 'DISETUJUI';
  static const ditolak = 'DITOLAK';
  static const selesai = 'SELESAI';
  static const dibatalkan = 'DIBATALKAN';

  // Admin — umum
  static const adminMasuk = 'Masuk sebagai Admin';
  static const adminMasukHint = 'Khusus pemilik toko. Akun dibuat manual.';
  static const bukanAdmin = 'Akun ini bukan admin.';
  static const butuhInternetAdmin = 'Butuh internet untuk tindakan ini.';
  static const belumAdaData = 'Belum ada data';
  static const cobaLagi = 'Coba lagi';
  static const berhasilDisimpan = 'Berhasil disimpan.';
  static const berhasilDihapus = 'Berhasil dihapus';

  // Admin — Beranda
  static const omzetHariIni = 'Omzet hari ini';
  static const transaksiHariIni = 'Transaksi hari ini';
  static const pesananMenunggu = 'Pesanan menunggu';
  static const stokMenipisJudul = 'Stok menipis';
  static const lihatSemua = 'Lihat semua';

  // Admin — Kasir
  static const kasirKosong = 'Belum ada barang di kasir';
  static const kasirKosongHint = 'Cari barang atau pindai barcode.';
  static const cariAtauPindai = 'Cari nama / barcode...';
  static const pindaiBarcode = 'Pindai Barcode';
  static const ketikBarcode = 'Ketik barcode manual';
  static const barcodeTidakDikenal = 'Barcode tidak dikenal.';
  static const bayar = 'Bayar';
  static const totalBayar = 'Total bayar';
  static const uangDiterima = 'Uang diterima';
  static const kembalian = 'Kembalian';
  static const uangKurang = 'Uang kurang.';
  static const strukBelanja = 'Struk Belanja';
  static const terimaKasih = 'Terima kasih sudah belanja!';
  static const penjualanTersimpan = 'Penjualan tersimpan.';

  // Admin — Inbox
  static const inboxKosong = 'Inbox kosong';
  static const inboxKosongHint = 'Belum ada yang perlu perhatianmu.';
  static const persetujuanPendaftar = 'Persetujuan pendaftar';
  static const pesananBaru = 'Pesanan baru';
  static const chatBelumDibaca = 'Chat belum dibaca';
  static const setujui = 'Setujui';
  static const tolak = 'Tolak';
  static const pendaftarDisetujui = 'Pendaftar disetujui.';
  static const pendaftarDitolak = 'Pendaftar ditolak.';

  // Admin — Catatan Belanja Harian
  static const catatanHarian = 'Catatan Belanja Harian';
  static const modalBelanja = 'Modal belanja';
  static const isiModal = 'Isi modal';
  static const nominalModal = 'Nominal modal (Rp)';
  static const belumAdaModal = 'Belum ada modal';
  static const belumAdaModalHint =
      'Isi modal dulu sebelum belanja ke supplier.';
  static const tambahCatatan = 'Tambah catatan';
  static const namaSupplier = 'Nama supplier';
  static const daftarBarang = 'Daftar barang';
  static const namaBarang = 'Nama barang';
  static const hargaSatuan = 'Harga satuan (Rp)';
  static const tambahBaris = 'Tambah baris';
  static const totalBelanja = 'Total belanja';
  static const arsipSaja =
      'Ubah/hapus hanya mengubah arsip — pembukuan & stok tidak dihitung ulang.';
  static const dariBelanjaStok = 'Dari Belanja Stok';
  static const manualTeks = 'Manual';

  // Admin — Menu & modul
  static const modulProduk = 'Data Barang';
  static const modulKasirOnline = 'Kasir Online';
  static const modulLaporan = 'Laporan';
  static const modulData = 'Data';
  static const modulChat = 'Chat';
  static const modulPembukuan = 'Pembukuan';
  static const modulKalkulator = 'Kalkulator';
  static const modulBelanjaStok = 'Belanja Stok';
  static const modulCatatanToko = 'Catatan Toko';
  static const modulKoin = 'Koin Warga';
  static const modulAiAdmin = 'AI Admin';
  static const modulBuktiTransfer = 'Bukti Transfer';
  static const modulStruk = 'Struk 58mm';
  static const modulScanner = 'Scanner';
  static const modulProfilToko = 'Profil Toko';
  static const modulBerandaPelanggan = 'Beranda Pelanggan';
  static const modulPengaturan = 'Pengaturan';

  // Admin — Data Barang
  static const tambahProduk = 'Tambah produk';
  static const ubahProduk = 'Ubah produk';
  static const namaProduk = 'Nama produk';
  static const hargaJual = 'Harga jual (Rp)';
  static const hargaModal = 'Harga modal/pcs (Rp)';
  static const stok = 'Stok (pcs)';
  static const barcodeOpsional = 'Barcode (opsional)';
  static const fotoProduk = 'Foto produk';
  static const pilihDariHp = 'Pilih dari HP';
  static const hapusFoto = 'Hapus foto';
  static const fotoUrlLabel = 'Foto dari internet (URL)';
  static const fotoUrlHint = 'Tempel alamat gambar, mis. https://...';
  static const kategori = 'Kategori';
  static const tampilkanDiKatalog = 'Tampilkan di katalog';
  static const arsipkan = 'Arsipkan';
  static const aktifkanLagi = 'Aktifkan lagi';
  static const hapusProdukTanya = 'Hapus produk ini?';
  static const produkNonaktif = 'Nonaktif';

  // Admin — Kasir Online & Data
  static const semuaStatus = 'Semua status';
  static const ubahStatus = 'Ubah status';
  static const pelanggan = 'Pelanggan';
  static const pesananKosong = belumAdaPesanan; // alias
  static const pesananKosongHint =
      'Pesanan dari aplikasi pelanggan muncul di sini.';
  static const statusMenunggu = 'Menunggu';
  static const statusDikemas = 'Dikemas';
  static const statusDikirim = 'Dikirim';
  static const statusSelesai = 'Selesai';
  static const statusDibatalkan = 'Dibatalkan';
  static const daftarPelanggan = 'Daftar pelanggan';
  static const koin = 'koin';
  static const sesuaikanKoin = 'Sesuaikan koin';
  static const jumlahKoin = 'Jumlah (+/-)';
  static const alasan = 'Alasan';
  static const tambahKoin = 'Tambah koin';
  static const kurangKoin = 'Kurangi koin';
  static const koinTersimpan = 'Koin tersimpan.';

  // Admin — Pembukuan
  static const pemasukan = 'Pemasukan';
  static const pengeluaran = 'Pengeluaran';
  static const saldo = 'Saldo';
  static const tambahCatatanKeuangan = tambahCatatan; // alias
  static const jenisTransaksi = 'Jenis';
  static const penjualan = 'Penjualan';
  static const kulakan = 'Kulakan';
  static const beban = 'Beban';
  static const lainnya = 'Lainnya';
  static const modal = 'Modal';
  static const keterangan = 'Keterangan';
  static const nominal = 'Nominal (Rp)';
  static const labaBersih = 'Laba bersih';
  static const jurnalKosongHint =
      'Jual di Kasir atau catat kulakan di Belanja Stok.';

  // Admin — Laporan
  static const tujuhHariTerakhir = '7 hari terakhir';
  static const omzet = 'Omzet';
  static const laba = 'Laba';
  static const grafikOmzet = 'Omzet 7 hari';
  static const laporanKosong = 'Belum ada transaksi pada periode ini';
  static const salinCsv = 'Salin CSV';
  static const csvDisalin = 'CSV disalin.';
  static const transaksi = 'Transaksi';

  // Admin — Belanja Stok
  static const perluDikulak = 'Perlu dikulak';
  static const saranJumlah = 'Saran';
  static const isiPerKemasan = 'Isi per kemasan';
  static const hargaPerKemasan = 'Harga per kemasan (Rp)';
  static const saranJual = 'Saran jual';
  static const pakaiModalBaru = 'Pakai modal baru';
  static const rataRataModal = 'Rata-rata modal';
  static const ringkasanBelanja = 'Ringkasan belanja';
  static const simpanBelanja = 'Simpan belanja';
  static const daftarBelanja = 'Daftar belanja';
  static const totalKulakan = 'Total kulakan';
  static const belanjaTersimpan = 'Belanja tersimpan.';
  static const tanpaSaran = 'Semua stok aman untuk saat ini.';
  static const hargaJualBaru = 'Harga jual baru (Rp)';
  static const modalBaru = 'Modal baru/pcs (Rp)';
  static const produkTerkait = 'Produk terkait';

  // Admin — Koin Warga
  static const koinWargaHint =
      'Ubah saldo koin pelanggan. Tercatat di riwayat.';
  static const pilihPelanggan = 'Pilih pelanggan';
  static const cariNama = 'Cari nama...';
  // Sinkron manual dengan version di pubspec.yaml.
  static const versiApp = 'KasirQuh v3.6.7+21';

  // Admin — Profil Toko
  static const namaToko = 'Nama toko';
  static const alamat = 'Alamat';
  static const telepon = 'Telepon';
  static const jamBuka = 'Jam buka';
  static const jamTutup = 'Jam tutup';
  static const infoTokoLabel = 'Info toko';
  static const teksBerjalan = 'Teks berjalan';

  // Admin — Beranda Pelanggan
  static const promo = 'Promo';
  static const tambahPromo = 'Tambah promo';
  static const judulPromo = 'Judul promo';
  static const subjudulPromo = 'Subjudul (opsional)';
  static const tampilkanPromo = 'Tampilkan';
  static const promoAktif = 'Aktif';

  // Admin — Pengaturan
  static const grupTampilan = 'Tampilan';
  static const grupNotifikasi = 'Notifikasi';
  static const grupDeveloper = 'Developer';
  static const grupTentang = 'Tentang';
  static const grupAkun = 'Akun';
  static const infoSesi = 'Info sesi';
  static const keluarAdmin = 'Keluar dari Mode Admin';
  static const notifPesananBaru = 'Pesanan baru';
  static const notifChat = 'Chat masuk';
  static const notifStokMenipis = 'Stok menipis';

  // Admin — Catatan Toko
  static const tambahCatatanToko = 'Tambah catatan toko';
  static const isiCatatan = 'Isi catatan';
  static const belumAdaCatatanToko = 'Belum ada catatan toko';

  // Admin — Chat
  static const belumAdaPercakapan = 'Belum ada percakapan';
  static const chatKosongHint = 'Pesan dari pelanggan muncul di sini.';
  static const ketikPesan = 'Ketik pesan...';

  // Fase 4 — Chat pelanggan (Rumpi / Toko / Komunitas)
  static const tabRumpi = 'Rumpi';
  static const tabToko = 'Toko';
  static const rumpiKosong = 'Belum ada kabar';
  static const rumpiKosongHint =
      'Jadilah yang pertama berbagi kabar di warung ini.';
  static const tulisKabar = 'Tulis kabar';
  static const kirimKabar = 'Kirim kabar';
  static const mengirim = 'Mengirim...';
  static const kabarHint = 'Ada kabar apa hari ini?';
  static const tulisKabarDulu = 'Tulis kabar dulu ya.';
  static const tambahFoto = 'Tambah foto';
  static const fotoTidakTerbaca = 'Foto tidak bisa dibaca.';
  static const fotoTerlaluBesar =
      'Foto terlalu besar, pilih yang lebih kecil ya.';
  static const chatTokoKosong = 'Belum ada percakapan dengan toko';
  static const chatTokoKosongHint =
      'Toko akan menyiapkan ruang chat setelah pendaftaranmu disetujui.';
  static const chatTokoMulai = 'Sapa toko dulu, mis. "Halo, mau tanya stok."';
  static const tokoChatJudul = 'Chat dengan Warunge Mimi';
  static const grupJudul = 'Komunitas Warunge Mimi';
  static const grupKosong = 'Belum ada obrolan';
  static const grupKosongHint =
      'Mulai obrolan pertama dengan warga lainnya di sini.';
  static const warga = 'Warga';

  // Fase 4 — Koin
  static const riwayatKoin = 'Riwayat Koin';
  static const koinKosong = 'Belum ada riwayat koin';
  static const koinKosongHint =
      'Koin bertambah saat admin memberi bonus atau kamu belanja.';

  // Fase 4 — Notifikasi
  static const notifIzinJudul = 'Aktifkan notifikasi?';
  static const notifIzinIsi =
      'Agar kamu tahu saat status pesanan berubah atau ada kabar '
      'dari toko. Bisa dimatikan kapan saja di pengaturan HP.';
  static const notifAktifkan = 'Aktifkan';
  static const notifNanti = 'Nanti saja';
  static const pesananBaruJudul = 'Pesanan baru masuk';
  static const statusPesananJudul = 'Status pesanan berubah';
  static const chatBaruJudul = 'Pesan baru dari toko';
}
