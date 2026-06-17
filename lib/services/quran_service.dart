import 'dart:convert';
import 'package:http/http.dart' as http;

class Surah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;
  final String deskripsi;
  final String audioUrl;

  Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
    required this.deskripsi,
    required this.audioUrl,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      nomor: json['nomor'],
      nama: json['nama'],
      namaLatin: json['namaLatin'],
      jumlahAyat: json['jumlahAyat'],
      tempatTurun: json['tempatTurun'],
      arti: json['arti'],
      deskripsi: json['deskripsi'],
      audioUrl: json['audioFull']?['05'] ?? '', // Default to Mishary Rashid
    );
  }
}

class Ayat {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final String audioUrl;

  Ayat({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audioUrl,
  });

  factory Ayat.fromJson(Map<String, dynamic> json) {
    return Ayat(
      nomorAyat: json['nomorAyat'],
      teksArab: json['teksArab'],
      teksLatin: json['teksLatin'],
      teksIndonesia: json['teksIndonesia'],
      audioUrl: json['audio']?['05'] ?? '',
    );
  }
}

class SurahDetail extends Surah {
  final List<Ayat> ayat;

  SurahDetail({
    required int nomor,
    required String nama,
    required String namaLatin,
    required int jumlahAyat,
    required String tempatTurun,
    required String arti,
    required String deskripsi,
    required String audioUrl,
    required this.ayat,
  }) : super(
          nomor: nomor,
          nama: nama,
          namaLatin: namaLatin,
          jumlahAyat: jumlahAyat,
          tempatTurun: tempatTurun,
          arti: arti,
          deskripsi: deskripsi,
          audioUrl: audioUrl,
        );

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    var ayatList = json['ayat'] as List;
    List<Ayat> ayatObjs = ayatList.map((a) => Ayat.fromJson(a)).toList();
    
    return SurahDetail(
      nomor: json['nomor'],
      nama: json['nama'],
      namaLatin: json['namaLatin'],
      jumlahAyat: json['jumlahAyat'],
      tempatTurun: json['tempatTurun'],
      arti: json['arti'],
      deskripsi: json['deskripsi'],
      audioUrl: json['audioFull']?['05'] ?? '',
      ayat: ayatObjs,
    );
  }
}

class QuranService {
  static const String _baseUrl = 'https://equran.id/api/v2';
  static List<Surah>? _surahCache;

  Future<List<Surah>> getSurahList() async {
    if (_surahCache != null) return _surahCache!;

    final response = await http.get(Uri.parse('$_baseUrl/surat'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'];
      _surahCache = list.map((e) => Surah.fromJson(e)).toList();
      return _surahCache!;
    }
    throw Exception('Gagal memuat daftar Surah');
  }

  Future<SurahDetail> getSurahDetail(int nomor) async {
    final response = await http.get(Uri.parse('$_baseUrl/surat/$nomor'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SurahDetail.fromJson(data['data']);
    }
    throw Exception('Gagal memuat detail Surah');
  }
}
