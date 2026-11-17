import 'dart:async';
import 'model.dart';

/// Exception yang dilempar ketika kapasitas parkiran sudah penuh.
class ParkirPenuh implements Exception {
  final String pesan;
  ParkirPenuh([this.pesan = 'Parkiran penuh']);

  @override
  String toString() => 'Ditolak: $pesan';
}

/// Exception yang dilempar saat kendaraan tidak ditemukan di dalam area parkir.
class KendaraanTidakDitemukan implements Exception {
  final String plat;
  KendaraanTidakDitemukan(this.plat);

  @override
  String toString() => 'Kendaraan dengan plat $plat tidak ditemukan di parkiran.';
}

/// Pengelola sistem parkir kampus yang mengelola kapasitas, antrean,
/// tarif, serta pelaporan kejadian asinkron melalui Stream.
class Parkiran {
  final int kapasitas;
  final List<Kendaraan> _terparkir = [];
  int _pendapatan = 0;
  final StreamController<String> _streamController =
      StreamController<String>.broadcast();

  Parkiran(this.kapasitas);

  /// Sisa kapasitas tempat parkir yang masih kosong.
  int get sisa => kapasitas - _terparkir.length;

  /// Total pendapatan retribusi parkir yang telah terkumpul.
  int get pendapatan => _pendapatan;

  /// Jumlah kendaraan yang saat ini sedang terparkir.
  int get jumlahTerparkir => _terparkir.length;

  /// Salinan daftar kendaraan terparkir yang tidak dapat diubah dari luar.
  List<Kendaraan> get terparkir => List.unmodifiable(_terparkir);

  /// Stream siaran kejadian masuk/keluar untuk layar monitor pos jaga.
  Stream<String> get stream => _streamController.stream;

  /// Memasukkan kendaraan ke dalam area parkir (disimulasikan dengan palang otomatis).
  Future<void> masuk(Kendaraan kendaraan) async {
    // Simulasi palang gerbang otomatis terbuka
    await Future.delayed(const Duration(milliseconds: 300));

    if (sisa <= 0) {
      throw ParkirPenuh('Parkiran penuh (kapasitas $kapasitas)');
    }

    _terparkir.add(kendaraan);
    _streamController
        .add('MASUK ${kendaraan.jenis} ${kendaraan.plat} (sisa $sisa)');
  }

  /// Mengeluarkan kendaraan dari area parkir dan mengakumulasi pembayaran.
  Future<int> keluar(Kendaraan kendaraan, {DateTime? waktuKeluar}) async {
    // Simulasi palang gerbang otomatis terbuka
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_terparkir.contains(kendaraan)) {
      throw KendaraanTidakDitemukan(kendaraan.plat);
    }

    final waktu = waktuKeluar ?? DateTime.now();
    final biaya = kendaraan.biaya(waktu);

    _pendapatan += biaya;
    _terparkir.remove(kendaraan);
    _streamController
        .add('KELUAR ${kendaraan.jenis} ${kendaraan.plat} bayar Rp$biaya');

    return biaya;
  }

  /// Mencari kendaraan terparkir berdasarkan nomor plat.
  Kendaraan? cari(String plat) =>
      _terparkir.where((k) => k.plat == plat).firstOrNull;

  /// Mengeluarkan kendaraan berdasarkan string plat nomor.
  Future<int> keluarByPlat(String plat, {DateTime? waktuKeluar}) async {
    final kendaraan = cari(plat);
    if (kendaraan == null) {
      throw KendaraanTidakDitemukan(plat);
    }
    return keluar(kendaraan, waktuKeluar: waktuKeluar);
  }

  /// Menutup stream controller saat pos parkir berhenti beroperasi.
  Future<void> tutup() => _streamController.close();
}
