import 'package:pm_p4_4241250015/pm_p4_4241250015.dart';

/// Program utama demonstrasi Tugas Rutin 4: Sistem Parkir Kampus FMIPA (Console).
///
/// Mendemonstrasikan:
/// 1. Polimorfisme melalui `List<Kendaraan>` (Motor, Mobil, MobilMember)
/// 2. Simulasi asinkron palang otomatis gerbang (Future.delayed & async/await)
/// 3. Pemancaran dan penanganan kejadian secara real-time via Stream broadcast
/// 4. Penanganan kondisi kapasitas penuh melalui custom exception ParkirPenuh
/// 5. Perhitungan biaya bertarif per jam, pembulatan, dan diskon mixin Berlangganan
Future<void> main() async {
  // Inisialisasi parkiran kampus dengan kapasitas 3 slot
  final parkiran = Parkiran(3);

  // Mendaftarkan listener pos jaga untuk mendengarkan Stream kejadian secara real-time
  final langganan = parkiran.stream.listen((kejadian) {
    print(kejadian);
  });

  // Waktu simulasi (durasi parkir: 3 jam)
  final waktuMasuk = DateTime(2026, 11, 6, 8, 0);
  final waktuKeluar = DateTime(2026, 11, 6, 11, 0);

  // Polimorfisme: List<Kendaraan> memuat berbagai objek turunan (Motor, Mobil, MobilMember)
  final List<Kendaraan> daftarKendaraan = [
    Motor('BK 1234 AB', waktuMasuk),
    Mobil('BK 88 UN', waktuMasuk),
    MobilMember('BK 7 MIPA', waktuMasuk),
  ];

  // 1. Proses kendaraan masuk satu per satu secara asinkron
  for (final kendaraan in daftarKendaraan) {
    await parkiran.masuk(kendaraan);
  }

  // 2. Simulasi kapasitas penuh: mencoba memasukkan kendaraan saat kapasitas 0
  final trukTambahan = Truk('BK 9999 TR', waktuMasuk);
  try {
    await parkiran.masuk(trukTambahan);
  } on ParkirPenuh catch (e) {
    print(e);
  }

  // 3. Proses kendaraan keluar satu per satu dan membayarkan retribusi
  for (final kendaraan in daftarKendaraan) {
    await parkiran.keluar(kendaraan, waktuKeluar: waktuKeluar);
  }

  // Membersihkan resource stream dan memastikan seluruh event telah diproses listener
  await parkiran.tutup();
  await langganan.cancel();

  // 4. Menampilkan akumulasi pendapatan parkir
  print('Pendapatan: Rp${parkiran.pendapatan}');
}
