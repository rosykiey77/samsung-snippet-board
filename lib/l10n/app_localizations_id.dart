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
}
