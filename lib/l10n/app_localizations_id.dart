// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Snippet Board';

  @override
  String get copied => 'Disalin';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryWork => 'Kerja';

  @override
  String get categoryAccount => 'Rekening';

  @override
  String get categoryChatTemplate => 'Template Chat';

  @override
  String get emptyState => 'Belum ada snippet';

  @override
  String get categoryAll => 'Semua';

  @override
  String get add => 'Tambah';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Hapus';

  @override
  String get pin => 'Sematkan';

  @override
  String get unpin => 'Lepas sematan';

  @override
  String get deleted => 'Snippet dihapus';

  @override
  String get undo => 'Urungkan';

  @override
  String get copyFailed => 'Gagal menyalin. Coba lagi.';

  @override
  String copiedAnnounce(String title) {
    return 'Disalin: $title';
  }

  @override
  String get tapToCopy => 'Ketuk dua kali untuk menyalin';

  @override
  String get moreOptions => 'Opsi lainnya';

  @override
  String get pinned => 'disematkan';

  @override
  String get showNumber => 'Tampilkan nomor';

  @override
  String get hideNumber => 'Sembunyikan nomor';

  @override
  String get emptyBody =>
      'Simpan teks yang sering kamu ketik, lalu salin dengan sekali ketuk.';

  @override
  String get createFirst => 'Buat snippet pertama';

  @override
  String get noResults => 'Tidak ada snippet di kategori ini';

  @override
  String get clearFilter => 'Hapus filter';

  @override
  String get newSnippet => 'Snippet baru';

  @override
  String get editSnippet => 'Edit snippet';

  @override
  String get save => 'Simpan';

  @override
  String get titleLabel => 'Judul';

  @override
  String get titleHint => 'Otomatis dari 30 karakter pertama';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get bodyLabel => 'Isi';

  @override
  String get preview => 'Pratinjau';

  @override
  String get bodyEmpty => 'Isi tidak boleh kosong';

  @override
  String get titleTooLong => 'Judul terlalu panjang';

  @override
  String get freeLimitTitle => 'Batas tercapai';

  @override
  String get freeLimitBody => 'Batas 10 snippet tercapai di versi gratis.';

  @override
  String get ok => 'OK';

  @override
  String get discardTitle => 'Buang perubahan?';

  @override
  String get discard => 'Buang';

  @override
  String get keepEditing => 'Lanjut edit';

  @override
  String get fillVariables => 'Lengkapi variabel';

  @override
  String get varNama => 'Nama';

  @override
  String get varRekening => 'Nomor rekening';

  @override
  String get cancel => 'Batal';

  @override
  String get copy => 'Salin';

  @override
  String get settings => 'Pengaturan';

  @override
  String get variablesGroup => 'Variabel';

  @override
  String get defaultNama => 'Nama default';

  @override
  String get defaultRekening => 'Nomor rekening default';

  @override
  String get notSet => 'Belum diatur — ditanya saat menyalin';

  @override
  String get quickAccessGroup => 'Akses cepat';

  @override
  String get edgePanel => 'Edge Panel';

  @override
  String get edgePanelHint => 'Tampilkan panel snippet di daftar Edge Panel';

  @override
  String get quickTile => 'Tile Quick Settings';

  @override
  String get quickTileHint => 'Buka snippet dari panel notifikasi';

  @override
  String get addTile => 'Tambah tile ke Quick Settings';

  @override
  String get tileManual =>
      'Usap panel notifikasi ke bawah, ketuk Edit, lalu seret \"Quick Snippet\" ke panel.';

  @override
  String get overlay => 'Tombol mengambang';

  @override
  String get overlayHint => 'Gelembung yang bisa diseret di atas aplikasi lain';

  @override
  String get overlayPermissionTitle => 'Izinkan tampil di atas aplikasi lain';

  @override
  String get overlayPermissionBody =>
      'Tombol mengambang butuh izin untuk tampil di atas aplikasi lain. Tombol ini hanya membuka daftar snippet; tidak ada isi layar yang dibaca.';

  @override
  String get openSettings => 'Buka pengaturan';

  @override
  String get dataGroup => 'Data';

  @override
  String get exportData => 'Ekspor data';

  @override
  String get exportHint =>
      'Disimpan sebagai JSON. Nomor rekening tidak dimasking di file.';

  @override
  String get importData => 'Impor data';

  @override
  String get exportDone => 'Data diekspor';

  @override
  String importDone(int count) {
    return '$count snippet diimpor';
  }

  @override
  String get importInvalid => 'File ini bukan backup Snippet Board';

  @override
  String get fileError => 'Gagal membaca atau menulis file';

  @override
  String get proGroup => 'Pro';

  @override
  String get proActive => 'Pro aktif — snippet tanpa batas';

  @override
  String get upgradeToPro => 'Upgrade ke Pro';

  @override
  String get restorePurchase => 'Pulihkan pembelian';

  @override
  String get restoreNone => 'Tidak ada pembelian Pro';

  @override
  String get restoreDone => 'Pro dipulihkan';

  @override
  String get proTitle => 'Snippet Pro';

  @override
  String get proUnlimited => 'Snippet tanpa batas';

  @override
  String get proLifetime => 'Sekali bayar, selamanya';

  @override
  String get proOffline => 'Tetap 100% offline';

  @override
  String buyFor(String price) {
    return 'Beli $price';
  }

  @override
  String get iapUnavailable => 'Pembelian memerlukan Galaxy Store';

  @override
  String get iapCancelled => 'Pembelian dibatalkan';

  @override
  String get iapFailed => 'Pembelian gagal, tidak ada yang berubah';

  @override
  String snippetCount(int count) {
    return '$count/10 snippet';
  }

  @override
  String get upgrade => 'Upgrade';

  @override
  String get aboutGroup => 'Tentang';

  @override
  String get privacy => 'Privasi';

  @override
  String get privacyBody => '100% offline: tanpa akses internet, tanpa pelacakan atau analitik. Snippet hanya tersimpan di perangkat ini dan tidak di-backup otomatis. Satu-satunya koneksi luar adalah alur pembelian Galaxy Store.';
}
