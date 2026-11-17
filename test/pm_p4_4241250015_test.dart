import 'package:pm_p4_4241250015/pm_p4_4241250015.dart';
import 'package:test/test.dart';

void main() {
  group('1. Pengujian Model Kendaraan & Polimorfisme', () {
    final waktuMasuk = DateTime(2026, 11, 6, 8, 0);

    test('Motor memiliki jenis dan tarif yang sesuai (Rp2.000/jam)', () {
      final motor = Motor('BK 1234 AB', waktuMasuk);
      expect(motor.jenis, equals('Motor'));
      expect(motor.tarifPerJam, equals(2000));
      expect(motor.plat, equals('BK 1234 AB'));
      expect(motor.waktuMasuk, equals(waktuMasuk));
    });

    test('Mobil memiliki jenis dan tarif yang sesuai (Rp5.000/jam)', () {
      final mobil = Mobil('BK 88 UN', waktuMasuk);
      expect(mobil.jenis, equals('Mobil'));
      expect(mobil.tarifPerJam, equals(5000));
    });

    test('Truk memiliki jenis dan tarif yang sesuai (Rp8.000/jam)', () {
      final truk = Truk('BK 9999 TR', waktuMasuk);
      expect(truk.jenis, equals('Truk'));
      expect(truk.tarifPerJam, equals(8000));
    });

    test('Durasi parkir kurang dari atau sama dengan 1 jam dihitung minimal 1 jam', () {
      final motor = Motor('BK 1111 XX', waktuMasuk);

      // Keluar setelah 10 menit
      final keluar10Menit = waktuMasuk.add(const Duration(minutes: 10));
      expect(motor.biaya(keluar10Menit), equals(2000));

      // Keluar tepat 60 menit
      final keluar60Menit = waktuMasuk.add(const Duration(minutes: 60));
      expect(motor.biaya(keluar60Menit), equals(2000));
    });

    test('Durasi parkir dibulatkan ke atas per jam berikutnya', () {
      final mobil = Mobil('BK 2222 YY', waktuMasuk);

      // Keluar setelah 61 menit (dibulatkan menjadi 2 jam)
      final keluar61Menit = waktuMasuk.add(const Duration(minutes: 61));
      expect(mobil.biaya(keluar61Menit), equals(10000));

      // Keluar setelah 3 jam
      final keluar3Jam = waktuMasuk.add(const Duration(hours: 3));
      expect(mobil.biaya(keluar3Jam), equals(15000));
    });

    test('Polimorfisme List<Kendaraan> mengeksekusi perhitungan sesuai subclass', () {
      final List<Kendaraan> armada = [
        Motor('BK 1', waktuMasuk),
        Mobil('BK 2', waktuMasuk),
        Truk('BK 3', waktuMasuk),
      ];

      final waktuKeluar = waktuMasuk.add(const Duration(hours: 2));
      final totalBiaya = armada.fold<int>(0, (total, k) => total + k.biaya(waktuKeluar));

      // Motor (2 * 2000 = 4000) + Mobil (2 * 5000 = 10000) + Truk (2 * 8000 = 16000) = 30000
      expect(totalBiaya, equals(30000));
    });
  });

  group('2. Pengujian Mixin Berlangganan', () {
    final waktuMasuk = DateTime(2026, 11, 6, 8, 0);

    test('MobilMember mendapatkan diskon 50%', () {
      final member = MobilMember('BK 7 MIPA', waktuMasuk);
      expect(member.jenis, equals('Mobil (member)'));
      expect(member.diskon, equals(0.5));

      // Parkir 3 jam normal Rp15.000 -> diskon 50% menjadi Rp7.500
      final waktuKeluar = waktuMasuk.add(const Duration(hours: 3));
      expect(member.biaya(waktuKeluar), equals(7500));
    });

    test('MotorMember mendapatkan diskon 50%', () {
      final memberMotor = MotorMember('BK 5555 MM', waktuMasuk);
      expect(memberMotor.jenis, equals('Motor (member)'));

      // Parkir 2 jam normal Rp4.000 -> diskon 50% menjadi Rp2.000
      final waktuKeluar = waktuMasuk.add(const Duration(hours: 2));
      expect(memberMotor.biaya(waktuKeluar), equals(2000));
    });
  });

  group('3. Pengujian Kelas Parkiran, Enkapsulasi, dan Logika Kapasitas', () {
    test('Inisialisasi parkiran memiliki kapasitas dan sisa yang benar', () {
      final parkiran = Parkiran(5);
      expect(parkiran.kapasitas, equals(5));
      expect(parkiran.sisa, equals(5));
      expect(parkiran.pendapatan, equals(0));
      expect(parkiran.terparkir, isEmpty);
    });

    test('Enkapsulasi menjaga keamanan daftar kendaraan terparkir', () {
      final parkiran = Parkiran(2);
      expect(
        () => (parkiran.terparkir as dynamic).add(Motor('BK 0', DateTime.now())),
        throwsUnsupportedError,
      );
    });

    test('Exception ParkirPenuh dilempar ketika melebihi kapasitas', () async {
      final parkiran = Parkiran(1);
      final k1 = Motor('BK 1', DateTime.now());
      final k2 = Mobil('BK 2', DateTime.now());

      await parkiran.masuk(k1);
      expect(parkiran.sisa, equals(0));

      expect(
        () => parkiran.masuk(k2),
        throwsA(isA<ParkirPenuh>().having(
          (e) => e.toString(),
          'toString',
          contains('Ditolak: Parkiran penuh (kapasitas 1)'),
        )),
      );

      await parkiran.tutup();
    });

    test('Exception KendaraanTidakDitemukan dilempar saat kendaraan tidak ada', () async {
      final parkiran = Parkiran(3);
      final k = Motor('BK 99', DateTime.now());

      expect(
        () => parkiran.keluar(k),
        throwsA(isA<KendaraanTidakDitemukan>()),
      );

      await parkiran.tutup();
    });
  });

  group('4. Pengujian Async Programming & Stream Broadcast', () {
    test('Stream broadcast mencatat seluruh log masuk dan keluar secara berurutan', () async {
      final parkiran = Parkiran(3);
      final logDiterima = <String>[];

      final langganan = parkiran.stream.listen((log) {
        logDiterima.add(log);
      });

      final waktuMasuk = DateTime(2026, 11, 6, 8, 0);
      final waktuKeluar = waktuMasuk.add(const Duration(hours: 3));

      final motor = Motor('BK 1234 AB', waktuMasuk);
      final mobil = Mobil('BK 88 UN', waktuMasuk);
      final member = MobilMember('BK 7 MIPA', waktuMasuk);

      await parkiran.masuk(motor);
      await parkiran.masuk(mobil);
      await parkiran.masuk(member);

      expect(parkiran.sisa, equals(0));

      await parkiran.keluar(motor, waktuKeluar: waktuKeluar);
      await parkiran.keluar(mobil, waktuKeluar: waktuKeluar);
      await parkiran.keluar(member, waktuKeluar: waktuKeluar);

      await parkiran.tutup();
      await langganan.cancel();

      expect(logDiterima, equals([
        'MASUK Motor BK 1234 AB (sisa 2)',
        'MASUK Mobil BK 88 UN (sisa 1)',
        'MASUK Mobil (member) BK 7 MIPA (sisa 0)',
        'KELUAR Motor BK 1234 AB bayar Rp6000',
        'KELUAR Mobil BK 88 UN bayar Rp15000',
        'KELUAR Mobil (member) BK 7 MIPA bayar Rp7500',
      ]));

      expect(parkiran.pendapatan, equals(28500));
    });
  });
}
