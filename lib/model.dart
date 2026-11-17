/// Model hierarki kendaraan dan mixin sistem parkir kampus FMIPA UNIMED.
library;

/// Kelas abstrak sebagai cetak biru seluruh jenis kendaraan.
abstract class Kendaraan {
  final String plat;
  final DateTime waktuMasuk;

  Kendaraan(this.plat, this.waktuMasuk);

  /// Jenis/kategori kendaraan (misal: 'Motor', 'Mobil', 'Truk').
  String get jenis;

  /// Tarif parkir per jam dalam satuan Rupiah.
  int get tarifPerJam;

  /// Menghitung total biaya parkir berdasarkan waktu keluar.
  /// Pembulatan ke atas per jam dengan durasi minimal 1 jam.
  int biaya(DateTime keluar) {
    final selisih = keluar.difference(waktuMasuk);
    final menit = selisih.inMinutes;

    // Pembulatan ke atas per jam (misal 1-60 menit -> 1 jam, 61-120 menit -> 2 jam)
    final jamDihitung = (menit / 60.0).ceil();

    // Durasi minimal 1 jam meskipun durasi <= 0 menit
    final durasiFinal = jamDihitung < 1 ? 1 : jamDihitung;

    return durasiFinal * tarifPerJam;
  }

  @override
  String toString() => '$jenis $plat (masuk: $waktuMasuk)';
}

/// Mixin untuk memberikan fasilitas potongan tarif bagi member berlangganan.
mixin Berlangganan on Kendaraan {
  /// Persentase diskon (default 50% = 0.5).
  double get diskon => 0.5;

  @override
  int biaya(DateTime keluar) {
    final tarifNormal = super.biaya(keluar);
    return (tarifNormal * (1.0 - diskon)).round();
  }
}

/// Subclass Kendaraan roda dua (Motor).
class Motor extends Kendaraan {
  Motor(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Motor';

  @override
  int get tarifPerJam => 2000;
}

/// Subclass Kendaraan roda empat (Mobil).
class Mobil extends Kendaraan {
  Mobil(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil';

  @override
  int get tarifPerJam => 5000;
}

/// Subclass Kendaraan muatan besar (Truk).
class Truk extends Kendaraan {
  Truk(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Truk';

  @override
  int get tarifPerJam => 8000;
}

/// Subclass Mobil dengan keanggotaan langganan (mendapatkan diskon 50%).
class MobilMember extends Mobil with Berlangganan {
  MobilMember(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Mobil (member)';
}

/// Subclass Motor dengan keanggotaan langganan (mendapatkan diskon 50%).
class MotorMember extends Motor with Berlangganan {
  MotorMember(super.plat, super.waktuMasuk);

  @override
  String get jenis => 'Motor (member)';
}
